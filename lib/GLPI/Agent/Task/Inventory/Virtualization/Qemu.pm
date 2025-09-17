package GLPI::Agent::Task::Inventory::Virtualization::Qemu;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use UNIVERSAL::require;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Unix;
use GLPI::Agent::Tools::Virtualization;

sub isEnabled {
    # On win32, we have to search for any existing qemu process
    if (OSNAME eq 'MSWin32') {
        GLPI::Agent::Tools::Win32->use();
        my $running_qemu = first { $_->{Name} =~ /^qemu-system-/ } getWMIObjects(
            class      => "Win32_Process",
            properties => [ qw/Name/ ]
        );
        return $running_qemu ? 1 : 0;
    }

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
        } elsif ($option =~ m/^m (?:size=)?(\S+)/) {
            my ($mem) = split(/,/,$1);
            $mem .= "b" unless $mem =~ /^\d+$/;
            $values->{mem} = getCanonicalSize($mem, 1024);
        } elsif ($option =~ m/^m (\S+)/) {
            $values->{mem} = getCanonicalSize($1);
        } elsif ($option =~ m/^uuid (\S+)/) {
            $values->{uuid} = $1;
        } elsif ($option =~ m/^enable-kvm|accel=kvm/) {
            $values->{vmtype} = "kvm";
        } elsif ($option =~ m/^smp (\S+)$/) {
            my @cpu_args = split(/,/, $1);
            my ($cpus) = grep { /^(?:cpus=)?\d+$/ } @cpu_args;
            if ($cpus && $cpus =~ /(\d+)$/) {
                $values->{vcpu} = int($1);
            } else {
                my ($cores) = grep { /^(?:cores=)?\d+$/ } @cpu_args;
                my ($threads) = grep { /^(?:threads=)?\d+$/ } @cpu_args;
                my ($sockets) = grep { /^(?:sockets=)?\d+$/ } @cpu_args;
                $values->{vcpu} = int($1 || 1) if $cores && $cores =~ /(\d+)$/;
                $values->{vcpu} *= int($1 || 1) if $threads && $threads =~ /(\d+)$/;
                $values->{vcpu} *= int($1 || 1) if $sockets && $sockets =~ /(\d+)$/;
            }
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

sub _win32ProcessList {
    GLPI::Agent::Tools::Win32->use();

    return map {
        {
            CMD => $_->{CommandLine}
        }
    } grep { $_->{Name} =~ /^qemu-system-/ && !empty($_->{CommandLine}) } getWMIObjects(
        class      => "Win32_Process",
        properties => [ qw/Name CommandLine/ ]
    );
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # check only qemu instances
    foreach my $process (OSNAME eq 'MSWin32' ? _win32ProcessList() : getProcesses(
        filter    => qr/(qemu|kvm|qemu-kvm|qemu-system\S+) .*\S/x,
        namespace => "same",
        logger    => $logger,
    )) {

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
                VCPU      => $values->{vcpu} || 1,
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
