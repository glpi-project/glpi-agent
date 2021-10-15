package GLPI::Agent::Task::Inventory::MacOS::Sound;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::MacOS;

use constant    category    => "sound";

sub isEnabled {
    return canRun('/usr/sbin/system_profiler');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $infos = getSystemProfilerInfos(type => 'SPAudioDataType', logger => $logger);
    my $info = $infos->{'Audio (Built In)'};

    foreach my $sound (keys %$info){
        $inventory->addEntry(
            section => 'SOUNDS',
            entry   => {
                NAME         => $sound,
                MANUFACTURER => $sound,
                DESCRIPTION  => $sound,
            }
        );
    }
}

1;
