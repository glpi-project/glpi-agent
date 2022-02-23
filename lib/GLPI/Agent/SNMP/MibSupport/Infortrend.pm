package GLPI::Agent::SNMP::MibSupport::Infortrend;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See IFT-SNMP-MIB
use constant    infortrend  => '.1.3.6.1.4.1.1714' ;

use constant    extInterface        => infortrend . '.1.1' ;
use constant    ctlrConfiguration   => extInterface . '.1' ;

use constant    sysInformation      => ctlrConfiguration . '.1' ;
use constant    fwMajorVersion      => sysInformation . '.4.0' ;
use constant    fwMinorVersion      => sysInformation . '.5.0' ;
use constant    serialNum           => sysInformation . '.10.0' ;
use constant    privateLogoModel    => sysInformation . '.15.0' ;

use constant    hddTable        => extInterface . '.6' ;
use constant    hddSize         => hddTable . '.1.7' ;
use constant    hddBlkSizeIdx   => hddTable . '.1.8' ;
use constant    hddStatus       => hddTable . '.1.11' ;
use constant    hddModelStr     => hddTable . '.1.15' ;
use constant    hddFwRevStr     => hddTable . '.1.16' ;
use constant    hddSerialNum    => hddTable . '.1.17' ;

our $mibSupport = [
    {
        name        => 'infortrend',
        sysobjectid => getRegexpOidMatch(extInterface)
    }
];

sub getSerial {
    my ($self) = @_;

    return $self->get(serialNum);
}

sub getModel {
    my ($self) = @_;

    return $self->get(privateLogoModel);
}

sub getFirmware {
    my ($self) = @_;

    return $self->get(fwMajorVersion).".".$self->get(fwMinorVersion);
}

sub getType {
    return 'STORAGE';
}

sub getManufacturer {
    return "Infortrend Technology, Inc.";
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Scan storages
    my $hddStatus = $self->walk(hddStatus)
        or return;

    return unless ref($hddStatus) eq 'HASH';

    my $hddSize       = $self->walk(hddSize);
    my $hddBlkSizeIdx = $self->walk(hddBlkSizeIdx);

    my $hddModelStr   = $self->walk(hddModelStr);
    my $hddFwRevStr   = $self->walk(hddFwRevStr);
    my $hddSerialNum  = $self->walk(hddSerialNum);

    foreach my $key (sort keys(%{$hddStatus})) {
        my $status = $hddStatus->{$key};
        next unless defined($status);

        # Do not inventory missing disks
        next if $status == 0x3f || $status == 0xfc || $status == 0xfd || $status == 0xfe || $status == 0xff;

        my $storage = {
            TYPE    => 'disk',
        };

        # Handle size
        if ($hddSize->{$key} && $hddBlkSizeIdx->{$key}) {
            my $blockcount = $hddSize->{$key};
            # Fix signed values as 32 bits encoded values
            $blockcount = (1 << 32) + $blockcount + 1 if $blockcount < 0;
            my $blocksize = 1 << $hddBlkSizeIdx->{$key};
            my $bytes = $blocksize * $blockcount;
            $storage->{DISKSIZE} = getCanonicalSize("$bytes bytes");
        }

        # Handle model and manufacturer
        if ($hddModelStr->{$key}) {
            my $string = trimWhitespace(getCanonicalString($hddModelStr->{$key}));
            $storage->{NAME} = $string;
            my ($manufacturer, $model) = $string =~ /(\S+)[ _]+(.*)\s*$/;
            $storage->{MODEL} = $model if $model;
            $storage->{MANUFACTURER} = getCanonicalManufacturer($manufacturer)
                if $manufacturer;
        }

        # Handle firmware
        if ($hddFwRevStr->{$key}) {
            $storage->{FIRMWARE} = getCanonicalString($hddFwRevStr->{$key});
        }

        # Handle serial
        if ($hddSerialNum->{$key}) {
            $storage->{SERIAL} = getCanonicalSerialNumber($hddSerialNum->{$key});
        }

        # Only keep storage if we got model and serial
        push @{$device->{STORAGES}}, $storage
            if $storage->{MODEL} && $storage->{SERIAL};
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Infortrend - Inventory module for Infortrend SAN

=head1 DESCRIPTION

The module enhances Infortrend SAN support.
