package GLPI::Agent::Task::Inventory::Win32::Bios;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools::Win32;
use GLPI::Agent::Tools::Generic;

use constant    category    => "bios";

# Only run this module if dmidecode has not been found
our $runMeIfTheseChecksFailed =
    ["GLPI::Agent::Task::Inventory::Generic::Dmidecode::Bios"];

sub isEnabled {
    return 1;
}

sub _dateFromIntString {
    my ($string) = @_;

    if ($string && $string =~ /^(\d{4})(\d{2})(\d{2})/) {
        return "$2/$3/$1";
    }

    return $string;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $bios = {};

    foreach my $object (getWMIObjects(
        class      => 'Win32_Bios',
        properties => [ qw/
            SerialNumber Version Manufacturer SMBIOSBIOSVersion BIOSVersion ReleaseDate
        / ]
    )) {
        $bios->{BIOSSERIAL}    = $object->{SerialNumber};
        $bios->{SSN}           = $object->{SerialNumber};
        $bios->{BMANUFACTURER} = $object->{Manufacturer};
        $bios->{BVERSION}      = $object->{SMBIOSBIOSVersion} ||
                                 $object->{BIOSVersion}       ||
                                 $object->{Version};
        $bios->{BDATE}         = _dateFromIntString($object->{ReleaseDate});
    }

    # Try to set Bios date from registry if not found via wmi
    unless ($bios->{BDATE}) {
        $bios->{BDATE} = _dateFromIntString(getRegistryValue(
            path => "HKEY_LOCAL_MACHINE/Hardware/Description/System/BIOS/BIOSReleaseDate"
        ));
    }

    foreach my $object (getWMIObjects(
        class      => 'Win32_ComputerSystem',
        properties => [ qw/
            Manufacturer Model
        / ]
    )) {
        $bios->{SMANUFACTURER} = $object->{Manufacturer};
        $bios->{SMODEL}        = $object->{Model};
    }

    foreach my $object (getWMIObjects(
            class      => 'Win32_SystemEnclosure',
            properties => [ qw/
                SerialNumber SMBIOSAssetTag
            / ]
    )) {
        $bios->{ENCLOSURESERIAL} = $object->{SerialNumber} ;
        $bios->{SSN}             = $object->{SerialNumber} unless $bios->{SSN};
        $bios->{ASSETTAG}        = $object->{SMBIOSAssetTag};
    }

    foreach my $object (getWMIObjects(
            class => 'Win32_BaseBoard',
            properties => [ qw/
                SerialNumber Product Manufacturer
            / ]
    )) {
        $bios->{MSN}             = $object->{SerialNumber};
        $bios->{MMODEL}          = $object->{Product};
        $bios->{SSN}             = $object->{SerialNumber}
            unless $bios->{SSN};
        $bios->{SMANUFACTURER}   = $object->{Manufacturer}
            unless $bios->{SMANUFACTURER};

    }

    foreach (keys %$bios) {
        $bios->{$_} =~ s/\s+$// if $bios->{$_};
        delete $bios->{$_} if isInvalidBiosValue($bios->{$_});
    }

    $inventory->setBios($bios);
}

1;
