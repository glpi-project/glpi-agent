package FusionInventory::Agent::Task::Inventory::Virtualization::Wsl;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use Encode qw(decode);

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Virtualization;

our $runAfter = [ qw(
    FusionInventory::Agent::Task::Inventory::Win32::OS
    FusionInventory::Agent::Task::Inventory::Win32::CPU
)];

sub isEnabled {
    return $OSNAME eq "MSWin32" && canRun('wsl');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my @machines = _getVirtualMachines(%params);

    foreach my $machine (@machines) {
        $inventory->addEntry(
            section => 'VIRTUALMACHINES', entry => $machine
        );
    }
}

sub  _getVirtualMachines {
    my (%params) = @_;

    my $handle = getFileHandle(
        command => 'wsl -l -v',
        %params
    );
    return unless $handle;

    my @machines;
    my $header;

    # Prepare vcpu & memory from still inventoried CPUS & HARDWARE
    my $cpus = $params{inventory}->getSection('CPUS');
    my $vcpu = 0;
    map { $vcpu += $_->{THREAD} // $_->{CORE} // 0 } @{$cpus};
    my $memory = $params{inventory}->getField('HARDWARE', 'MEMORY');

    foreach my $line (<$handle>) {
        # wsl command output seems to be UTF-16 but we can't decode it as expected
        # so we just need to clean it up
        $line = getSanitizedString($line)
            or next;
        next unless length($line);

        my ($select, $name, $state, $version) = $line =~ /^(.)\s+(\w+)\s+(\w+)\s+(\w+)/
            or next;

        # Handle header
        unless ($header) {
            last unless $name && $name eq 'NAME';
            $header++;
            next;
        }

        my $wsl = {
            NAME    => $name,
            VMTYPE  => 'WSL',
            VCPU    => $vcpu,
            MEMORY  => $memory,
            STATUS  => $state eq 'Running' ? STATUS_RUNNING :
                       $state eq 'Stopped' ? STATUS_OFF     :
                                             STATUS_OFF
        };

        # Get UUID from inventory-uuid file or kernel boot_id only when it is
        # running. This will permit to connect the vitual computer if the agent
        # is also run into WSL. We don't run wsl while it is 'Stopped'
        # otherwize this will change its status to 'Running'
        if ($wsl->{STATUS} eq STATUS_RUNNING) {
            my $uuidfile = "/etc/inventory-uuid";
            my $command = "wsl -d $name cat $uuidfile";
            my $uuid = getFirstLine(command => $command, logger => $params{logger});
            unless ($uuid) {
                $command = "wsl -d $name sysctl -n kernel.random.boot_id";
                $uuid = getFirstLine(command => $command, logger => $params{logger});
            }
            $wsl->{UUID} = $uuid if $uuid;
        }

        push @machines, $wsl;
    }
    close $handle;

    return @machines;
}

1;
