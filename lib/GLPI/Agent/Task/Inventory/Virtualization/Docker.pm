package FusionInventory::Agent::Task::Inventory::Virtualization::Docker;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use JSON::PP;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Virtualization;

# wanted info fields for each container
my @wantedInfos = qw/ID Image Ports Names/;

# formatting separator
my $separator = '#=#=#';

sub isEnabled {
    return canRun('docker');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # formatting with a Go template (required by docker ps command)
    my @wanted = map { '{{.' . $_ . '}}' } @wantedInfos;
    my $template = join $separator, @wanted;

    foreach my $container (_getContainers(
        logger => $logger,
        command => 'docker ps -a --format "' . $template . '"'
    )) {
        $inventory->addEntry(
            section => 'VIRTUALMACHINES', entry => $container
        );
    }
}

sub  _getContainers {
    my (%params) = @_;


    my $handle = getFileHandle(%params);

    return unless $handle;

    my @containers;
    while (my $line = <$handle>) {
        chomp $line;
        my @info = split $separator, $line;
        next unless $#info == $#wantedInfos;

        my $status = '';

        if ($params{command}) {
            $status = _getStatus(
                command => 'docker inspect '.$info[0],
            );
        }
        my $container = {
            VMTYPE     => 'docker',
            UUID       => $info[0],
            IMAGE    => $info[1],
            NAME     => $info[3],
            STATUS   => $status
        };

        push @containers, $container;

    }
    close $handle;

    return @containers;
}

sub _getStatus {
    my (%params) = @_;


    my $lines = getAllLines(%params);
    my $status = '';
    eval {
        my $coder = JSON::PP->new;
        my $containerData = $coder->decode($lines);
        $status =
            ((ref $containerData eq 'ARRAY' && $containerData->[0]->{State}->{Running})
                    || (ref $containerData eq 'HASH' && $containerData->{State}->{Running})) ?
            STATUS_RUNNING : STATUS_OFF;
    };

    return $status;
}

1;
