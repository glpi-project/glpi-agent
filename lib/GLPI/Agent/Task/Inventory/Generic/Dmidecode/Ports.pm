package GLPI::Agent::Task::Inventory::Generic::Dmidecode::Ports;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;

use constant    category    => "port";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $ports = _getPorts(logger => $logger);

    return unless $ports;

    foreach my $port (@$ports) {
        $inventory->addEntry(
            section => 'PORTS',
            entry   => $port
        );
    }
}

sub _getPorts {
    my $infos = getDmidecodeInfos(@_);

    return unless $infos->{8};

    my $ports;
    foreach my $info (@{$infos->{8}}) {
        my $port = {
            CAPTION     => $info->{'External Reference Designator'} // $info->{'External Connector Type'} // $info->{'External Designator'},
            DESCRIPTION => $info->{'Internal Connector Type'} // $info->{'External Designator'} // $info->{'Internal Designator'} // $info->{'External Connector Type'},
            NAME        => $info->{'Internal Reference Designator'} // $info->{'External Reference Designator'} // $info->{'Internal Designator'} // $info->{'External Designator'},
            TYPE        => $info->{'Port Type'} // $info->{'External Connector Type'},
        };

        push @$ports, $port;
    }

    return $ports;
}

1;
