package GLPI::Agent::Task::Inventory::Virtualization::VirtualBox;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Virtualization;

sub isEnabled {
    return unless canRun('VBoxManage');

    my ($major, $minor) = getFirstMatch(
        command => 'VBoxManage --version',
        pattern => qr/^(\d)\.(\d)/
    );

    return compareVersion($major, $minor, 2, 1);
}

sub doInventory {
    my (%params) = @_;

    my $inventory    = $params{inventory};
    my $logger       = $params{logger};

    my $vmscommand = "VBoxManage -nologo list vms";

    foreach my $vm (_parseVBoxManageVms(
        logger  => $logger,
        command => $vmscommand
    )) {
        my $command = "VBoxManage -nologo showvminfo $vm";
        my ($machine) = _parseVBoxManage(
            logger  => $logger,
            command => $command
        );
        next unless $machine;
        $inventory->addEntry(
            section => 'VIRTUALMACHINES', entry => $machine
        );
    }

    if (!$params{scan_homedirs}) {
        $logger->info(
            "'scan-homedirs' configuration parameters disabled, " .
            "ignoring virtualbox virtual machines in user directories"
        );
        return;
    }

    if (OSNAME eq 'MSWin32') {
        $logger->info(
            "scanning of virtualbox virtual machines in user directories not supported under win32"
        );
        return;
    }

    my @users = ();
    my $user_vbox_folder = OSNAME eq 'darwin' ?
        "Library/VirtualBox" : ".config/VirtualBox" ;

    # Prepare to lookup only for users using VirtualBox
    while (my $user = GetNextUser()) {
        next if $user->{uid} == $REAL_USER_ID;
        push @users, $user->{name}
            if has_folder($user->{dir}."/$user_vbox_folder") ;
    }

    foreach my $user (@users) {
        my $vmscommand = "su '$user' -c 'VBoxManage -nologo list vms'";
        foreach my $vm (_parseVBoxManageVms(
            logger  => $logger,
            command => $vmscommand
        )) {
            my $command = "su '$user' -c 'VBoxManage -nologo showvminfo $vm'";
            my ($machine) = _parseVBoxManage(
                logger  => $logger,
                command => $command
            );
            next unless $machine;
            $machine->{OWNER} = $user;
            $inventory->addEntry(
                section => 'VIRTUALMACHINES', entry => $machine
            );
        }
    }
}

sub _parseVBoxManageVms {
    my @vms;
    foreach my $line (getAllLines(@_)) {
        next unless $line =~ /^"[^"]+"\s+{([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})}$/;
        push @vms, $1;
    }
    return @vms;
}

sub _parseVBoxManage {
    my @lines = getAllLines(@_)
        or return;

    my (@machines, $machine, $index);

    my %status_list = (
        'powered off'       => STATUS_OFF,
        'saved'             => STATUS_OFF,
        'teleported'        => STATUS_OFF,
        'aborted'           => STATUS_CRASHED,
        'stuck'             => STATUS_BLOCKED,
        'teleporting'       => STATUS_PAUSED,
        'live snapshotting' => STATUS_RUNNING,
        'starting'          => STATUS_RUNNING,
        'stopping'          => STATUS_DYING,
        'saving'            => STATUS_DYING,
        'restoring'         => STATUS_RUNNING,
        'running'           => STATUS_RUNNING,
        'paused'            => STATUS_PAUSED
    );
    foreach my $line (@lines) {
        if ($line =~ m/^Name:\s+(.*)$/) {
            # this is a little tricky, because USB devices also have a 'name'
            # field, so let's use the 'index' field to disambiguate
            if (defined $index) {
                $index = undef;
                next;
            }
            push @machines, $machine if $machine;
            $machine = {
                NAME      => $1,
                VCPU      => 1,
                SUBSYSTEM => 'Oracle VM VirtualBox',
                VMTYPE    => 'virtualbox'
            };
        } elsif ($line =~ m/^UUID:\s+(.+)/) {
            $machine->{UUID} = $1;
        } elsif ($line =~ m/^Memory size:\s+(.+)/ ) {
            $machine->{MEMORY} = getCanonicalSize($1);
        } elsif ($line =~ m/^State:\s+(.+) \(/) {
            $machine->{STATUS} = $status_list{$1};
        } elsif ($line =~ m/^Index:\s+(\d+)$/) {
            $index = $1;
        }
    }

    # push last remaining machine
    push @machines, $machine if $machine;

    return @machines;
}

1;
