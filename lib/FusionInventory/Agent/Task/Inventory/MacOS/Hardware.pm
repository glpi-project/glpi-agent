package FusionInventory::Agent::Task::Inventory::MacOS::Hardware;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;

use constant    category    => "hardware";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $kernelVersion = getFirstLine(
        logger  => $logger,
        command => 'uname -v'
    );

    my $hardware = {
        NAME       => "Mac OS X",
        OSCOMMENTS => $kernelVersion,
    };

    my $infos = getSystemProfilerInfos(
        logger  => $logger,
        type    => 'SPSoftwareDataType',
    );
    my $SystemVersion = $infos->{'Software'}->{'System Software Overview'}->{'System Version'};
    if ($SystemVersion =~ /^(.*?)\s+(\d+.*)/) {
        $hardware->{NAME}      = $1;
        $hardware->{OSVERSION} = $2;
    }

    my $hwinfos = getSystemProfilerInfos(
        logger  => $logger,
        type    => 'SPHardwareDataType',
    );
    my $hwoverview;
    $hwoverview = $hwinfos->{'Hardware'}->{'Hardware Overview'}
        if $hwinfos->{'Hardware'};
    if ($hwoverview && $hwoverview->{'Hardware UUID'}) {
        $hardware->{UUID} = $hwoverview->{'Hardware UUID'};
    } else {
        my ($device) = getIODevices(
            class   => 'IOPlatformExpertDevice',
            options => '-r -l -w0 -d1',
            logger  => $logger,
        );
        $hardware->{UUID} = $device->{'IOPlatformUUID'};
    }

    $inventory->setHardware($hardware);
}

1;
