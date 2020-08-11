package FusionInventory::Agent::Task::Inventory::Virtualization::VirtualBox;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use User::pwent;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Virtualization;

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

    my $command = "VBoxManage -nologo list --long vms";

    foreach my $machine (_parseVBoxManage(
        logger => $logger, command => $command
    )) {
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
    while (my $user = getpwent()) { # TODO REMOTE
        push @users, $user->name()
            if has_folder($user->dir()."/$user_vbox_folder") ;
    }

    foreach my $user (@users) {
        my $command = "su '$user' -c 'VBoxManage -nologo list --long vms'";
        foreach my $machine (_parseVBoxManage(
            logger => $logger, command => $command
        )) {
            $machine->{OWNER} = $user;
            $inventory->addEntry(
                section => 'VIRTUALMACHINES', entry => $machine
            );
        }
    }
}

sub _parseVBoxManage {
    my $handle = getFileHandle(@_);

    return unless $handle;

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
    while (my $line = <$handle>) {
        chomp $line;

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
                VMTYPE    => 'VirtualBox'
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
    close $handle;

    # push last remaining machine
    push @machines, $machine if $machine;

    return @machines;
}

1;
