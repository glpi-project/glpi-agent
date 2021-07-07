package FusionInventory::Agent::Task::Inventory::HPUX::Hardware;

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
    my $kernelVersion = getFirstLine(
        logger => $logger,
        command => 'uname -v'
    );
    my $kernelRelease = getFirstLine(
        logger => $logger,
        command => 'uname -r'
    );
    my $OSLicense     = getFirstLine(
        logger => $logger,
        command => 'uname -l'
    );

    my $hardware = {
        OSNAME     => 'HP-UX',
        OSVERSION  => $kernelVersion . ' ' . $OSLicense,
        OSCOMMENTS => $kernelRelease,
    };

    if (canRun('/usr/contrib/bin/machinfo')) {
        my $info = getInfoFromMachinfo(logger => $logger);
        $hardware->{UUID} = uc($info->{'Platform info'}->{'machine id number'});
    }

    $inventory->setHardware($hardware);
}

1;
