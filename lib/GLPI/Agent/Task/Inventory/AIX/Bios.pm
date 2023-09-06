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

    my $bios = _getInfos(logger => $logger);

    $inventory->setBios($bios);
}

sub _getInfos {
    my (%params) = @_;

    my @infos = getLsvpdInfos(%params);

    my $bios ={
        BMANUFACTURER => 'IBM',
        SMANUFACTURER => 'IBM',
    };

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
        $bios->{BVERSION} = $firmwares[0];
    }

    my $vpd = first { $_->{DS} eq 'System VPD' } @infos;
    if ($vpd) {
        $bios->{SSN}    = $vpd->{SE} || "";
        $bios->{SMODEL} = $vpd->{TM} || "";
    }

    # Use lsconf if lsvpd is not usable
    unless ($bios->{SSN} && $bios->{SMODEL} && $bios->{BVERSION}) {
        my $lsconf = getLsconfInfos(%params);
        if ($lsconf) {
            $bios->{SSN}      = $lsconf->{"Machine Serial Number"} || "";
            $bios->{BVERSION} = $lsconf->{"Platform Firmware level"} || "";
            ($bios->{SMANUFACTURER}, $bios->{SMODEL}) = split(",", $lsconf->{"System Model"} || "");
        }
    }

    my $unameL = Uname("-L");
    # LPAR partition can access the serial number of the host computer
    if ($bios->{SSN} && $unameL && $unameL =~ /^(\d+)\s+\S+/) {
        my $name = $1;
        my $lparname = getFirstMatch(
            logger  => $params{logger},
            command => "lparstat -i",
            pattern => qr/Partition\s+Name.*:\s+(.*)$/
        );
        # But an lpar can be migrated between hosts then we don't use to not have
        # a SSN change during such migration. Anyway there's still a risk a given
        # lparname is also used on another AIX system, administrators should avoid
        # such usage as they won't be able to migrate the 2 LPARs on the same server
        if ($lparname) {
            $bios->{SSN} = "aixlpar-$bios->{SSN}-$lparname";
        } else {
            $bios->{SSN} = "aixlpar-$bios->{SSN}-$name";
        }
    }

    return $bios;
}

1;
