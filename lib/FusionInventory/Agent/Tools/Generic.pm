package FusionInventory::Agent::Tools::Generic;

use strict;
use warnings;
use parent 'Exporter';

use English qw(-no_match_vars);
use Memoize;
use File::stat;
use File::Basename qw(basename);

use FusionInventory::Agent::Tools;

our @EXPORT = qw(
    getDmidecodeInfos
    getCpusFromDmidecode
    getHdparmInfo
    getPCIDevices
    getPCIDeviceVendor
    getPCIDeviceClass
    getUSBDeviceVendor
    getUSBDeviceClass
    getEDIDVendor
);

my $PCIVendors;
my $PCIClasses;
my $USBVendors;
my $USBClasses;
my $EDIDVendors;

# this trigger some errors under Win32:
# Anonymous function called in forbidden scalar context
if ($OSNAME ne 'MSWin32') {
    memoize('getDmidecodeInfos');
    memoize('getPCIDevices');
}

sub getDmidecodeInfos {
    my (%params) = (
        command => 'dmidecode',
        @_
    );

    my $handle = getFileHandle(%params);
    return unless $handle;
    my ($info, $block, $type);

    while (my $line = <$handle>) {
        chomp $line;

        if ($line =~ /DMI type (\d+)/) {
            # start of block

            # push previous block in list
            if ($block) {
                push(@{$info->{$type}}, $block);
                undef $block;
            }

            # switch type
            $type = $1;

            next;
        }

        next unless defined $type;

        next unless $line =~ /^\s+ ([^:]+) : \s (.*\S)/x;

        next if
            $2 eq 'N/A'                        ||
            $2 eq 'Not Specified'              ||
            $2 eq 'Not Present'                ||
            $2 eq 'Unknown'                    ||
            $2 eq '<BAD INDEX>'                ||
            $2 eq '<OUT OF SPEC>'              ||
            $2 eq '<OUT OF SPEC><OUT OF SPEC>' ;

        $block->{$1} = trimWhitespace($2);
    }
    close $handle;

    # push last block in list if still defined
    if ($block) {
        push(@{$info->{$type}}, $block);
    }

    # do not return anything if dmidecode output is obviously truncated
    return if keys %$info < 2;

    return $info;
}

sub getCpusFromDmidecode {
    my $infos = getDmidecodeInfos(@_);

    return unless $infos->{4};

    my @cpus;
    foreach my $info (@{$infos->{4}}) {
        next if $info->{Status} && $info->{Status} =~ /Unpopulated|Disabled/i;

        my $manufacturer = $info->{'Manufacturer'} ||
                           $info->{'Processor Manufacturer'};
        my $version      = $info->{'Version'} ||
                           $info->{'Processor Version'};

        # VMware
        next if
            ($manufacturer && $manufacturer eq '000000000000') &&
            ($version      && $version eq '00000000000000000000000000000000');

        my $cpu = {
            SERIAL       => $info->{'Serial Number'},
            ID           => $info->{ID},
            CORE         => $info->{'Core Enabled'} || $info->{'Core Count'},
            THREAD       => $info->{'Thread Count'},
            FAMILYNAME   => $info->{'Family'},
            MANUFACTURER => $manufacturer
        };
        $cpu->{NAME} =
            ($cpu->{MANUFACTURER} =~ /Intel/ ? $info->{'Family'} : undef) ||
            $info->{'Version'}                                     ||
            $info->{'Processor Family'}                            ||
            $info->{'Processor Version'};

       if ($cpu->{ID}) {

            # Split CPUID to get access to its content
            my @id = split ("",$cpu->{ID});
            # convert hexadecimal value
            $cpu->{STEPPING} = hex $id[1];
            # family number is composed of 3 hexadecimal number
            $cpu->{FAMILYNUMBER} = hex $id[9] . $id[10] . $id[4];
            $cpu->{MODEL} = hex $id[7] . $id[0];
        }

        if ($info->{Version}) {
            if ($info->{Version} =~ /([\d\.]+)MHz$/) {
                $cpu->{SPEED} = $1;
            } elsif ($info->{Version} =~ /([\d\.]+)GHz$/) {
                $cpu->{SPEED} = $1 * 1000;
            }
        }

        if (!$cpu->{SPEED} && $info->{'Current Speed'}) {
            if ($info->{'Current Speed'} =~ /^\s*(\d{3,4})\s*Mhz/i) {
                $cpu->{SPEED} = $1;
            } elsif ($info->{'Current Speed'} =~ /^\s*(\d+)\s*Ghz/i) {
                $cpu->{SPEED} = $1 * 1000;
            }
        }

        if ($info->{'External Clock'}) {
            if ($info->{'External Clock'} =~ /^\s*(\d+)\s*Mhz/i) {
                $cpu->{EXTERNAL_CLOCK} = $1;
            } elsif ($info->{'External Clock'} =~ /^\s*(\d+)\s*Ghz/i) {
                $cpu->{EXTERNAL_CLOCK} = $1 * 1000;
            }
        }

        # Add CORECOUNT if we have less enabled cores than total count
        if ($info->{'Core Enabled'} && $info->{'Core Count'}) {
            $cpu->{CORECOUNT} = $info->{'Core Count'}
                unless ($info->{'Core Enabled'} == $info->{'Core Count'});
        }

        push @cpus, $cpu;
    }

    return @cpus;
}

sub getHdparmInfo {
    my (%params) = @_;

    return unless $params{device} || $params{file};

    $params{command} = "hdparm -I $params{device}" if $params{device};

    # We need to support dump params to permit full testing when root params is set
    if ($params{root}) {
        $params{file} = "$params{root}/hdparm-".basename($params{device});
    } elsif ($params{dump}) {
        $params{dump}->{"hdparm-".basename($params{device})} = getAllLines(%params);
    }

    my $handle = getFileHandle(%params)
        or return;

    my $info;
    while (my $line = <$handle>) {
        $info->{DESCRIPTION}  = $1 if $line =~ /Transport:.+(SCSI|SATA|USB)/;
        $info->{DISKSIZE}     = $1 if $line =~ /1000:\s+(\d*)\sMBytes/;
        $info->{FIRMWARE}     = $1 if $line =~ /Firmware Revision:\s+(\w+)/;
        $info->{MODEL}        = $1 if $line =~ /Model Number:\s+(\w.+\w)/;
        $info->{SERIALNUMBER} = $1 if $line =~ /Serial Number:\s+(\w*)/;
        $info->{WWN}          = $1 if $line =~ /WWN Device Identifier:\s+(\w+)/;
    }
    close $handle;

    return $info;
}

sub getPCIDevices {
    my (%params) = (
        command => 'lspci -v -nn',
        @_
    );
    my $handle = getFileHandle(%params);

    my (@controllers, $controller);

    while (my $line = <$handle>) {
        chomp $line;

        if ($line =~ /^
            (\S+) \s                     # slot
            ([^[]+) \s                   # name
            \[([a-f\d]+)\]: \s           # class
            (\S.+) \s                   # manufacturer
            \[([a-f\d]+:[a-f\d]+)\]      # id
            (?:\s \(rev \s (\d+)\))?     # optional version
            /x) {

            $controller = {
                PCISLOT      => $1,
                NAME         => $2,
                PCICLASS     => $3,
                MANUFACTURER => $4,
                PCIID        => $5,
                REV          => $6
            };
            next;
        }

        next unless defined $controller;

        if ($line =~ /^$/) {
            push(@controllers, $controller);
            undef $controller;
        } elsif ($line =~ /^\tKernel driver in use: (\w+)/) {
            $controller->{DRIVER} = $1;
        } elsif ($line =~ /^\tSubsystem: ?.* \[?([a-f\d]{4}:[a-f\d]{4})\]?/) {
            $controller->{PCISUBSYSTEMID} = $1;
        }
    }

    close $handle;

    return @controllers;
}

sub getPCIDeviceVendor {
    my (%params) = @_;

    _loadPCIDatabase(%params) if !$PCIVendors;

    return unless $params{id};
    return $PCIVendors->{$params{id}};
}

sub getPCIDeviceClass {
    my (%params) = @_;

    _loadPCIDatabase(%params) if !$PCIClasses;

    return unless $params{id};
    return $PCIClasses->{$params{id}};
}

sub getUSBDeviceVendor {
    my (%params) = @_;

    _loadUSBDatabase(%params) if !$USBVendors;

    return unless $params{id};
    return $USBVendors->{$params{id}};
}

sub getUSBDeviceClass {
    my (%params) = @_;

    _loadUSBDatabase(%params) if !$USBClasses;

    return unless $params{id};
    return $USBClasses->{$params{id}};
}

sub getEDIDVendor {
    my (%params) = @_;

    _loadEDIDDatabase(%params) if !$EDIDVendors;

    return unless $params{id};
    return $EDIDVendors->{$params{id}};
}

my @datadirs = ($OSNAME ne 'linux') ? () : (
    "/usr/share/misc",      # debian system well-known path
    "/usr/share/hwdata",    # hwdata system well-known path including fedora
);

sub _getIdsFile {
    my (%params) = @_;

    # Initialize datadir to share if run from tests
    my $datadir = $params{datadir} || "share";

    return "$datadir/$params{idsfile}"
        unless @datadirs;

    # Try to use the most recent ids file from well-known places
    my %files = map { $_ => stat($_)->ctime() } grep { -s $_ }
        map { "$_/$params{idsfile}" } @datadirs, $datadir ;

    # Sort by creation time
    my @sorted_files = sort { $files{$a} <=> $files{$b} } keys(%files);

    return pop @sorted_files;
}

sub _loadPCIDatabase {
    my (%params) = @_;

    my $file = _getIdsFile( %params, idsfile => "pci.ids" );

    ($PCIVendors, $PCIClasses) = _loadDatabase( file => $file );
}

sub _loadUSBDatabase {
    my (%params) = @_;

    my $file = _getIdsFile( %params, idsfile => "usb.ids" );

    ($USBVendors, $USBClasses) = _loadDatabase( file => $file );
}

sub _loadDatabase {
    my $handle = getFileHandle(@_);
    return unless $handle;

    my ($vendors, $classes);
    my ($vendor_id, $device_id, $class_id);
    while (my $line = <$handle>) {

        if ($line =~ /^\t (\S{4}) \s+ (.*)/x) {
            # Device ID
            $device_id = $1;
            $vendors->{$vendor_id}->{devices}->{$device_id}->{name} = $2;
        } elsif ($line =~ /^\t\t (\S{4}) \s+ (\S{4}) \s+ (.*)/x) {
            # Subdevice ID
            my $subdevice_id = "$1:$2";
            $vendors->{$vendor_id}->{devices}->{$device_id}->{subdevices}->{$subdevice_id}->{name} = $3;
        } elsif ($line =~ /^(\S{4}) \s+ (.*)/x) {
            # Vendor ID
            $vendor_id = $1;
            $vendors->{$vendor_id}->{name} = $2;
        } elsif ($line =~ /^C \s+ (\S{2}) \s+ (.*)/x) {
            # Class ID
            $class_id = $1;
            $classes->{$class_id}->{name} = $2;
        } elsif ($line =~ /^\t (\S{2}) \s+ (.*)/x) {
            # SubClass ID
            my $subclass_id = $1;
            $classes->{$class_id}->{subclasses}->{$subclass_id}->{name} = $2;
        }
    }
    close $handle;

    return ($vendors, $classes);
}


sub _loadEDIDDatabase {
    my (%params) = @_;

    my $file = _getIdsFile( %params, idsfile => "edid.ids" );

    my $handle = getFileHandle( file => $file );
    return unless $handle;

    foreach my $line (<$handle>) {
       next unless $line =~ /^([A-Z]{3}) __ (.*)$/;
       $EDIDVendors->{$1} = $2;
   }
    close $handle;

   return;
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Tools::Generic - OS-independent generic functions

=head1 DESCRIPTION

This module provides some OS-independent generic functions.

=head1 FUNCTIONS

=head2 getDmidecodeInfos

Returns a structured view of dmidecode output. Each information block is turned
into an hashref, block with same DMI type are grouped into a list, and each
list is indexed by its DMI type into the resulting hashref.

$info = {
    0 => [
        { block }
    ],
    1 => [
        { block },
        { block },
    ],
    ...
}

=head2 getCpusFromDmidecode()

Returns a list of CPUs, from dmidecode output.

=head2 getHdparmInfo(%params)

Returns some information about a device, using hdparm.

Availables parameters:

=over

=item logger a logger object

=item device the device to use

=item file the file to use

=back

=head2 getPCIDevices(%params)

Returns a list of PCI devices as a list of hashref, by parsing lspci command
output.

=over

=item logger a logger object

=item command the exact command to use (default: lspci -vvv -nn)

=item file the file to use, as an alternative to the command

=back

=head2 getPCIDeviceVendor(%params)

Returns the PCI vendor matching this ID.

=over

=item id the vendor id

=item logger a logger object

=item datadir the directory holding the PCI database

=back

=head2 getPCIDeviceClass(%params)

Returns the PCI class matching this ID.

=over

=item id the class id

=item logger a logger object

=item datadir the directory holding the PCI database

=back

=head2 getUSBDeviceVendor(%params)

Returns the USB vendor matching this ID.

=over

=item id the vendor id

=item logger a logger object

=item datadir the directory holding the USB database

=back

=head2 getUSBDeviceClass(%params)

Returns the USB class matching this ID.

=over

=item id the class id

=item logger a logger object

=item datadir the directory holding the USB database

=back

=head2 getEDIDVendor(%params)

Returns the EDID vendor matching this ID.

=over

=item id the vendor id

=item logger a logger object

=item datadir the directory holding the edid vendors database

=back
