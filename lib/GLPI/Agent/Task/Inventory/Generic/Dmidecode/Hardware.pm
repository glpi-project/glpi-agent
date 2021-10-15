package GLPI::Agent::Task::Inventory::Generic::Dmidecode::Hardware;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;

use constant    category    => "hardware";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $hardware = _getHardware(logger => $logger);

    $inventory->setHardware($hardware) if $hardware;
}

sub _getHardware {
    my $infos = getDmidecodeInfos(@_);

    return unless $infos;

    my $system_info  = $infos->{1}->[0];
    my $chassis_info = $infos->{3}->[0];

    my $hardware = {
        UUID            => $system_info->{'UUID'},
        CHASSIS_TYPE    => $chassis_info->{'Type'}
    };

    return $hardware;
}

1;
