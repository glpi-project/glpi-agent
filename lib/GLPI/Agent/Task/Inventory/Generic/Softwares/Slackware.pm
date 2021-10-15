package GLPI::Agent::Task::Inventory::Generic::Softwares::Slackware;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

sub isEnabled {
    return canRun('pkgtool');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $handle = getDirectoryHandle(
        directory => '/var/log/packages', logger => $logger
    );
    return unless $handle;

    while (my $file = readdir($handle)) {
        next unless $file =~ /^(.+)-(.+)-(i[0-9]86|noarch|x86_64|x86|fw|npmjs)-(.*)$/;
        my $name = $1;
        my $version = $2;
        my $arch = $3;

        $inventory->addEntry(
            section => 'SOFTWARES',
            entry   => {
                NAME    => $name,
                VERSION => $version,
                ARCH    => $arch
            }
        );
    }
    closedir $handle;
}

1;
