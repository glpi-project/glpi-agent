package GLPI::Agent::Task::Inventory::Virtualization::Qemu;
# With Qemu 0.10.X, some option will be added to get more and easly information (UUID, memory, ...)

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Unix;
use GLPI::Agent::Tools::Virtualization;

sub isEnabled {
    # Avoid duplicated entry with libvirt
    return if canRun('virsh');

    return
        canRun('qemu') ||
        canRun('kvm')  ||
        canRun('qemu-kvm');
}

sub _parseProcessList {
    my ($process) = @_;


    my $values = {};

    my @options = split (/ -/, $process->{CMD});

    my $cmd = shift @options;
    if ($cmd =~ m/^(?:\/usr\/(s?)bin\/)?(\S+)/) {
        $values->{vmtype} = $2 =~ /kvm/ ? "kvm" : "qemu";
    }

    foreach my $option (@options) {
        if ($option =~ m/^(?:[fhsv]d[a-d]|cdrom) (\S+)/) {
            $values->{name} = $1 if !$values->{name};
        } elsif ($option =~ m/^name ([^\s,]+)/) {
            $values->{name} = $1;
        } elsif ($option =~ m/^m .*size=(\S+)/) {
            my ($mem) = split(/,/,$1);
            $values->{mem} = getCanonicalSize($mem);
        } elsif ($option =~ m/^m (\S+)/) {
            $values->{mem} = getCanonicalSize($1);
        } elsif ($option =~ m/^uuid (\S+)/) {
            $values->{uuid} = $1;
        } elsif ($option =~ m/^enable-kvm/) {
            $values->{vmtype} = "kvm";
        }

        if ($option =~ /smbios/) {
            if ($option =~ m/smbios.*uuid=([a-zA-Z0-9-]+)/) {
                $values->{uuid} = $1;
            }
            if ($option =~ m/smbios.*serial=([a-zA-Z0-9-]+)/) {
                $values->{serial} = $1;
            }
        }
    }

    if (defined($values->{mem}) && $values->{mem} =~ /^0+$/) {
        # Default value
        $values->{mem} = 128;
    }

    return $values;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $process (getProcesses(logger => $logger)) {
        # match only if an qemu instance
        next if $process->{CMD} =~ /^\[/;
        next if $process->{CMD} !~ /(qemu|kvm|qemu-kvm|qemu-system\S+) .*\S/x;

        # Don't inventory qemu guest agent as a virtualmachine
        next if $process->{CMD} =~ /qemu-ga/;

        my $values = _parseProcessList($process);
        next unless $values;

        # Name is mandatory, if we don't see it, the process is probably not related to a VM
        next unless defined($values->{name}) && length($values->{name});

        $inventory->addEntry(
            section => 'VIRTUALMACHINES',
            entry => {
                NAME      => $values->{name},
                UUID      => $values->{uuid},
                VCPU      => 1,
                MEMORY    => $values->{mem},
                STATUS    => STATUS_RUNNING,
                SUBSYSTEM => $values->{vmtype},
                VMTYPE    => $values->{vmtype},
                SERIAL    => $values->{serial},
            }
        );
    }
}

1;
