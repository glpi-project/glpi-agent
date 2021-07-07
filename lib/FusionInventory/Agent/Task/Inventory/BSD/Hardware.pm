package FusionInventory::Agent::Task::Inventory::BSD::Hardware;

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

    # basic operating system informations
    my $kernelVersion = getFirstLine(
        logger  => $logger,
        command => 'uname -v'
    );
    my $kernelRelease = getFirstLine(
        logger  => $logger,
        command => 'uname -r'
    );

    my $name = canRun('lsb_release') ?
        getFirstMatch(
            logger  => $logger,
            command => 'lsb_release -d',
            pattern => qr/Description:\s+(.+)/
        ) : $OSNAME;

    $inventory->setHardware({
        OSNAME     => $name,
        OSVERSION  => $kernelRelease,
        OSCOMMENTS => $kernelVersion,
    });
}

1;
