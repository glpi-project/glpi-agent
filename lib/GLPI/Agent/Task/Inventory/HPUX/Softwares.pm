package GLPI::Agent::Task::Inventory::HPUX::Softwares;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "software";

sub isEnabled  {
    return
        canRun('swlist');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $list = _getSoftwaresList(
        command => 'swlist',
        logger => $logger
    );

    return unless $list;

    foreach my $software (@$list) {
        $inventory->addEntry(
            section => 'SOFTWARES',
            entry   => $software
        );
    }
}

sub _getSoftwaresList {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @softwares;
    foreach my $line (@lines) {
        next unless $line =~ /^
            \s\s     # two spaces
            (\S+)    # name
            \s+
            (\S+)    # version
            \s+
            (\S.*\S) # comment
        /x;
        next if $1 =~ /^PH/;
        push @softwares, {
            NAME      => $1,
            VERSION   => $2,
            COMMENTS  => $3,
            PUBLISHER => 'HP'
        };
    }

    return \@softwares;
}

1;
