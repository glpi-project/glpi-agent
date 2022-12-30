package GLPI::Agent::Tools::Generic;

use strict;
use warnings;
use parent 'Exporter';

use English qw(-no_match_vars);
use File::stat;
use File::Basename qw(basename);

use GLPI::Agent::Tools;

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
    isInvalidBiosValue
);

my $PCIVendors;
my $PCIClasses;
my $USBVendors;
my $USBClasses;
my $EDIDVendors;

sub getDmidecodeInfos {
    my (%params) = (
        command => 'dmidecode',
        @_
    );

    my @lines = getAllLines(%params)
        or return;
    my ($info, $block, $type);

    foreach my $line (@lines) {

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

        next if isInvalidBiosValue($2);

        $block->{$1} = trimWhitespace($2);
    }

    # push last block in list if still defined
    if ($block) {
        push(@{$info->{$type}}, $block);
    }

    # do not return anything if dmidecode output is obviously truncated, but that's
    # okay during tests
    return if keys %$info < 2 && !$params{file};

    return $info;
}

sub isInvalidBiosValue {
    my ($value) = @_;
    return unless defined($value);
    return $value =~ m{
        ^(?:
            N/A                                |
            None                               |
            Unknown                            |
            Not \s* Specified                  |
            Not \s* Present                    |
            Not \s* Available                  |
            Default \s* string                 |
            System \s* Product \s* Name        |
            System \s* manufacturer            |
            System \s* Serial \s* Number       |
            System \s* Version                 |
            Chassis \s* Serial \s* Number      |
            Chassis \s* manufacturer?          |
            Chassis \s* Version                |
            No \s* Asset \s* Tag               |
            <BAD \s* INDEX>                    |
            (?:<OUT \s* OF \s* SPEC>){1,2}     |
            \s* To \s* Be \s* Filled \s* By \s* O\.E\.M\.
        )$
    }xi ;
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

        my $corecount = $info->{'Core Enabled'} || $info->{'Core Count'};

        my $cpu = {
            SERIAL       => $info->{'Serial Number'},
            ID           => $info->{ID},
            CORE         => $corecount,
            FAMILYNAME   => $info->{'Family'},
            MANUFACTURER => $manufacturer
        };

        if ($info->{'Thread Count'} && $corecount) {
            $cpu->{THREAD} = int($info->{'Thread Count'} / $corecount);
        }

        $cpu->{NAME} =
            $info->{'Version'}                                     ||
            $info->{'Family'}                                      ||
            $info->{'Processor Family'}                            ||
            $info->{'Processor Version'};
        # Cleanup cpu NAME
        $cpu->{NAME} =~ s/\((R|TM)\)//gi if $cpu->{NAME};

       if ($cpu->{ID}) {

            # Split CPUID to get access to its content
            my @id = split ("",$cpu->{ID});
            # convert hexadecimal value
            $cpu->{STEPPING} = hex $id[1];
            # family number is composed of 3 hexadecimal number
            $cpu->{FAMILYNUMBER} = hex $id[9] . $id[10] . $id[4];
            $cpu->{MODEL} = hex $id[7] . $id[0];

            # Re-assemble ID bytes in reversed order as done in WMI
            $cpu->{ID} = "";
            while (@id) {
                my $L = pop(@id);
                next unless defined($L);
                my $H = pop(@id);
                next unless defined($H);
                $cpu->{ID} .= "$H$L";
                pop @id;
            }
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

    my @lines = getAllLines(%params)
        or return;

    my $info;

    foreach my $line (@lines) {
        if ($line =~ /Integrity word not set/) {
            $info = {};
            last;
        }

        $info->{DESCRIPTION}  = $1 if $line =~ /Transport:.+(SATA|SAS|SCSI|USB)/;
        $info->{DISKSIZE}     = $1 if $line =~ /1000:\s+(\d*)\sMBytes/;
        $info->{FIRMWARE}     = $1 if $line =~ /Firmware Revision:\s+([\w.]+)/;
        $info->{INTERFACE}    = $1 if $line =~ /Transport:.+(SATA|SAS|SCSI|USB)/;
        $info->{MODEL}        = $1 if $line =~ /Model Number:\s+(\w.+\w)/;
        $info->{SERIALNUMBER} = $1 if $line =~ /Serial Number:\s+([\w-]*)/;
        $info->{WWN}          = $1 if $line =~ /WWN Device Identifier:\s+(\w+)/;
    }

    return $info;
}

sub getPCIDevices {
    my (%params) = (
        command => 'lspci -v -nn',
        @_
    );
    my @lines = getAllLines(%params)
        or return;

    my (@controllers, $controller, $mem);

    foreach my $line (@lines) {

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
            $controller->{MEMORY} = $mem if $mem;
            push(@controllers, $controller);
            undef $controller;
            undef $mem;
        } elsif ($line =~ /^\tKernel driver in use: (\w+)/) {
            $controller->{DRIVER} = $1;
        } elsif ($line =~ /^\tSubsystem: ?.* \[?([a-f\d]{4}:[a-f\d]{4})\]?/) {
            $controller->{PCISUBSYSTEMID} = $1;
        } elsif ($line =~ /^\s+Memory.*\sprefetchable.*\[size=(.*)\]/) {
            $mem += getCanonicalSize($1."B", 1024) // 0;
        }
    }

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

    unless (@sorted_files) {
        $params{logger}->error("$params{idsfile} not found") if $params{logger};
        return;
    }

    return pop @sorted_files;
}

sub _loadPCIDatabase {
    my (%params) = @_;

    my $file = _getIdsFile( %params, idsfile => "pci.ids" )
        or return;

    ($PCIVendors, $PCIClasses) = _loadDatabase( file => $file );
}

sub _loadUSBDatabase {
    my (%params) = @_;

    my $file = _getIdsFile( %params, idsfile => "usb.ids" )
        or return;

    ($USBVendors, $USBClasses) = _loadDatabase( file => $file );
}

sub _loadDatabase {
    my @lines = getAllLines(@_, local => 1)
        or return;

    my ($vendors, $classes);
    my ($vendor_id, $device_id, $class_id);
    foreach my $line (@lines) {
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

    return ($vendors, $classes);
}


sub _loadEDIDDatabase {
    my (%params) = @_;

    my $file = _getIdsFile( %params, idsfile => "edid.ids" )
        or return;

    my @lines = getAllLines(file => $file, local => 1)
        or return;

    foreach my $line (@lines) {
       next unless $line =~ /^([A-Z]{3}) __ (.*)$/;
       $EDIDVendors->{$1} = $2;
    }

   return;
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::Generic - OS-independent generic functions

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
