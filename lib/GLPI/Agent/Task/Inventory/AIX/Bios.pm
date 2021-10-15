package GLPI::Agent::Task::Inventory::AIX::Bios;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::AIX;

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

    my $unameL = Uname("-L");
    # LPAR partition can access the serial number of the host computer
    $ssn = $vpd->{SE};
    if ($unameL && $unameL =~ /^(\d+)\s+\S+/) {
        my $name = $1;
        my $lparname = getFirstMatch(
            logger  => $logger,
            command => "lparstat -i",
            pattern => qr/Partition Name.*:\s+(.*)$/
        );
        # But an lpar can be migrated between hosts then we don't use to not have
        # a SSN change during such migration. Anyway there's still a risk a given
        # lparname is also used on another AIX system, administrators should avoid
        # such usage as they won't be able to migrate the 2 LPARs on the same server
        if ($lparname) {
            $ssn = "aixlpar-$lparname";
        } else {
            $ssn = "aixlpar-$vpd->{SE}-$name";
        }
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
