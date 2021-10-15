package FusionInventory::Agent::Task::Inventory::Linux::Networks::FibreChannel;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;

sub isEnabled {
    return canRun('systool');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my @interfaces = _getInterfacesFromFcHost(logger => $logger);

    foreach my $interface (@interfaces) {
        $inventory->addEntry(
            section => 'NETWORKS',
            entry   => $interface
        );
    }
}

sub _getInterfacesFromFcHost {
    my (%params) = (
        command => 'systool -c fc_host -v',
        @_
    );
    my $handle = getFileHandle(%params);
    return unless $handle;

    my @interfaces;
    my $interface;

    while (my $line = <$handle>) {
        if ($line =~ /Class Device = "(.+)"/) {
            $interface = {
                DESCRIPTION => $1,
                TYPE        => 'fibrechannel'
            };
        } elsif ($line =~ /port_name\s+= "0x(\w+)"/) {
            $interface->{'WWN'} = join(':', unpack '(A2)*', $1);
        } elsif ($line =~ /port_state\s+= "(\w+)"/) {
            if ($1 eq 'Online') {
                $interface->{'STATUS'} = 'Up';
            } elsif ($1 eq 'Linkdown') {
                $interface->{'STATUS'} = 'Down';
            }
        } elsif ($line =~ /speed\s+= "(.+)"/) {
            $interface->{'SPEED'} = getCanonicalInterfaceSpeed($1)
                if ($1 ne 'unknown');

            push @interfaces, $interface;
        }
    }

    close $handle;

    return @interfaces;
}

1;
