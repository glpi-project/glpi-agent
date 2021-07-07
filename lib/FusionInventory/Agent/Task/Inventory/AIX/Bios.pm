package FusionInventory::Agent::Task::Inventory::AIX::Bios;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::AIX;

use constant    category    => "bios";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger = $params{logger};

    my ($ssn, $bios_version);

    my @infos = getLsvpdInfos(logger => $logger);

    # Get the BIOS version from the System Microcode Image (MI) version, in
    # 'System Firmware' section of VPD, containing three space separated values:
    # - the microcode image the system currently runs
    # - the 'permanent' microcode image
    # - the 'temporary' microcode image
    # See http://www.systemscanaix.com/sample_reports/aix61/hardware_configuration.html

    my $system = first { $_->{DS} eq 'System Firmware' } @infos;
    if ($system) {
        # we only return the currently booted firmware
        my @firmwares = split(' ', $system->{MI});
        $bios_version = $firmwares[0];
    }

    my $vpd = first { $_->{DS} eq 'System VPD' } @infos;

    my $unameL = getFirstLine(
        logger  => $logger,
        command => 'uname -L'
    );
    # LPAR partition can access the serial number of the host computer
    if ($unameL && $unameL =~ /^(\d+)\s+\S+/) {
        $ssn = "aixlpar-$vpd->{SE}-$1";
    } else {
        $ssn = $vpd->{SE};
    }

    $inventory->setBios({
        BMANUFACTURER => 'IBM',
        SMANUFACTURER => 'IBM',
        SMODEL        => $vpd->{TM},
        SSN           => $ssn,
        BVERSION      => $bios_version,
    });
}

1;
