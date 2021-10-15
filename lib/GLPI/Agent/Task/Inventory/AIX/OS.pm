package GLPI::Agent::Task::Inventory::AIX::OS;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "os";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # Operating system informations
    my $kernelName = Uname("-s");

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
        unless ($OSLevelParts[1] eq "00");

    $inventory->setOperatingSystem({
        NAME         => 'AIX',
        FULL_NAME    => "$kernelName $version",
        VERSION      => $version,
        SERVICE_PACK => "$OSLevelParts[2]-$OSLevelParts[3]",
    });
}

1;
