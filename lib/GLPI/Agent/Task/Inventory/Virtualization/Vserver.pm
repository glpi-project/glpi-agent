package GLPI::Agent::Task::Inventory::Virtualization::Vserver;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Virtualization;

sub isEnabled {
    return canRun('vserver');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $machine (_getMachines(
        command => 'vserver-info', logger => $logger
    )) {
        $inventory->addEntry(section => 'VIRTUALMACHINES', entry => $machine);
    }
}

sub _getMachines {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my $utilVserver;
    my $cfgDir;
    foreach my $line (@lines) {
        $cfgDir = $1 if $line =~ /^\s+cfg-Directory:\s+(.*)$/;
        $utilVserver = $1 if $line =~ /^\s+util-vserver:\s+(.*)$/;
    }

    return unless has_folder($cfgDir);

    my $handle = getDirectoryHandle(directory => $cfgDir, logger => $params{logger});
    return unless $handle;

    my @machines;
    while (my $name = readdir($handle)) {
        next if $name =~ /^\./;
        next unless $name =~ /\S/;

        my $line = getFirstLine(command => "vserver $name status");
        my $status =
            $line =~ /is stopped/ ? STATUS_OFF     :
            $line =~ /is running/ ? STATUS_RUNNING :
                                    undef ;

        my $machine = {
            NAME      => $name,
            STATUS    => $status,
            SUBSYSTEM => $utilVserver,
            VMTYPE    => "vserver",
        };

        push @machines, $machine;
    }
    close $handle;

    return @machines;
}

1;
