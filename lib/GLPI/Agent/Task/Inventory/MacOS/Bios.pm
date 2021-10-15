package GLPI::Agent::Task::Inventory::MacOS::Bios;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::MacOS;

use constant    category    => "bios";

sub isEnabled {
    return canRun('/usr/sbin/system_profiler');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $infos = getSystemProfilerInfos(type => 'SPHardwareDataType', logger => $logger);
    my $info = $infos->{'Hardware'}->{'Hardware Overview'};

    my ($device) = getIODevices(
        class   => 'IOPlatformExpertDevice',
        options => '-r -l -w0 -d1',
        logger  => $logger,
    );

    # set the bios informaiton from the apple system profiler
    $inventory->setBios({
        SMANUFACTURER => $device->{'manufacturer'} || 'Apple Inc', # duh
        SMODEL        => $info->{'Model Identifier'} ||
                         $info->{'Machine Model'} ||
                         $device->{'model'},
        # New method to get the SSN, because of MacOS 10.5.7 update
        # system_profiler gives 'Serial Number (system): XXXXX' where 10.5.6
        # and lower give 'Serial Number: XXXXX'
        SSN           => $info->{'Serial Number'}          ||
                         $info->{'Serial Number (system)'} ||
                         $device->{'IOPlatformSerialNumber'},
        BVERSION      => $info->{'Boot ROM Version'},
    });
}

1;
