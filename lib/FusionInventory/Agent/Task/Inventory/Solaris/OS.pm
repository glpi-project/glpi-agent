package FusionInventory::Agent::Task::Inventory::Solaris::OS;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Solaris;

use constant    category    => "os";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # Operating system informations
    my $info          = getReleaseInfo();
    my $kernelVersion = getFirstLine(
        logger  => $logger,
        command => 'uname -v'
    );
    my $hostid        = getFirstLine(
        logger  => $logger,
        command => 'hostid'
    );

    my $os = {
        NAME           => "Solaris",
        HOSTID         => $hostid,
        FULL_NAME      => $info->{fullname},
        VERSION        => $info->{version},
        SERVICE_PACK   => $info->{subversion},
        KERNEL_VERSION => $kernelVersion
    };

    $inventory->setOperatingSystem($os);
}

1;
