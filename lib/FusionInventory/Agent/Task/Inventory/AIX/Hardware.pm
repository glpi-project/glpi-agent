package FusionInventory::Agent::Task::Inventory::AIX::Hardware;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

use constant    category    => "hardware";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # Operating system informations
    my $kernelName = getFirstLine(
        logger  => $logger,
        command => 'uname -s'
    );

    my $version = getFirstLine(
        logger  => $logger,
        command => 'oslevel'
    );
    $version =~ s/(.0)*$//;

    my $OSLevel = getFirstLine(
        logger  => $logger,
        command => 'oslevel -s'
    );
    my @OSLevelParts = split(/-/, $OSLevel);

    $version = "$version TL$OSLevelParts[1]"
        unless $OSLevelParts[1] eq "00";

    my $hardware = {
        OSNAME     => "$kernelName $version",
        OSVERSION  => "$OSLevelParts[0]-$OSLevelParts[1]",
        OSCOMMENTS => "Maintenance Level: $OSLevelParts[1]",
    };

    my $unameL = getFirstLine(
        logger  => $logger,
        command => 'uname -L'
    );
    # LPAR partition can access the serial number of the host computer
    $hardware->{VMSYSTEM} = "AIX_LPAR"
        if $unameL && $unameL =~ /^(\d+)\s+(\S+)/;

    $inventory->setHardware($hardware);
}

1;
