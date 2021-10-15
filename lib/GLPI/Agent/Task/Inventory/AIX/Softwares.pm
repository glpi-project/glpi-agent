package GLPI::Agent::Task::Inventory::AIX::Softwares;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "software";

sub isEnabled {
    return
        canRun('lslpp');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $softwares = _getSoftwaresList(
        command => 'lslpp -c -l',
        logger  => $logger
    );
    return unless $softwares;

    foreach my $software (@$softwares) {
        $inventory->addEntry(
            section => 'SOFTWARES',
            entry   => $software
        );
    }

}

sub _getSoftwaresList {
    my $handle = getFileHandle(@_);
    next unless $handle;

    # skip headers
    my $line = <$handle>;

    my @softwares;
    while (my $line = <$handle>) {
        my @entry = split(/:/, $line);
        next if $entry[1] =~ /^device/;

        $entry[6] =~ s/\s+$//;

        push @softwares, {
            COMMENTS => $entry[6],
            FOLDER   => $entry[0],
            NAME     => $entry[1],
            VERSION  => $entry[2],
        };
    }
    close $handle;

    return \@softwares;
}

1;
