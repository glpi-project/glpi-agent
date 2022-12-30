package GLPI::Agent::Task::Inventory::Generic::Users;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

use constant    other_categories
                            => qw(local_user local_group);
use constant    category    => "user";

sub isEnabled {
    # Not working under win32
    return 0 if OSNAME eq 'MSWin32';

    return
        canRun('who')  ||
        canRun('last') ||
        canRead('/etc/passwd');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my %users;

    if (!$params{no_category}->{local_user}) {
        foreach my $user (_getLocalUsers(logger => $logger)) {
            # record user -> primary group relationship
            push @{$users{$user->{gid}}}, $user->{LOGIN};
            delete $user->{gid};

            $inventory->addEntry(
                section => 'LOCAL_USERS',
                entry   => $user
            );
        }
    }

    if (!$params{no_category}->{local_group}) {
        foreach my $group (_getLocalGroups(logger => $logger)) {
            # add users having this group as primary group, if any
            push @{$group->{MEMBER}}, @{$users{$group->{ID}}}
                if $users{$group->{ID}};

            $inventory->addEntry(
                section => 'LOCAL_GROUPS',
                entry   => $group
            );
        }
    }

    foreach my $user (_getLoggedUsers(logger => $logger)) {
        $inventory->addEntry(
            section => 'USERS',
            entry   => $user
        );
    }

    my $last = _getLastUser(logger => $logger);
    $inventory->setHardware($last);
}

sub _getLocalUsers {
    my (%params) = (
        file => '/etc/passwd',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my @users;

    foreach my $line (@lines) {
        next if $line =~ /^#/;
        next if $line =~ /^[+-]/; # old format for external inclusion, see #2460
        my ($login, undef, $uid, $gid, $gecos, $home, $shell) =
            split(/:/, $line);

        push @users, {
            LOGIN => $login,
            ID    => $uid,
            gid   => $gid,
            NAME  => $gecos,
            HOME  => $home,
            SHELL => $shell
        };
    }

    return @users;
}

sub _getLocalGroups {
    my (%params) = (
        file => '/etc/group',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my @groups;

    foreach my $line (@lines) {
        next if $line =~ /^#/;
        my ($name, undef, $gid, $members) = split(/:/, $line);

        # prevent warning for malformed group file (#2384)
        next unless $members;
        my @members = split(/,/, $members);

        push @groups, {
            ID     => $gid,
            NAME   => $name,
            MEMBER => \@members,
        };
    }

    return @groups;
}

sub _getLoggedUsers {
    my (%params) = (
        command => 'who',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my @users;
    my $seen;

    foreach my $line (@lines) {
        next unless $line =~ /^(\S+)/;
        next if $seen->{$1}++;
        push @users, { LOGIN => $1 };
    }

    return @users;
}

sub _getLastUser {
    my (%params) = (
        command => 'last',
        @_
    );

    my ($lastuser, $lastlogged);

    my @lines = getAllLines(%params)
        or return;

    foreach my $last (@lines) {
        next if $last =~ /^(reboot|shutdown)/;

        my @last = split(/\s+/, $last);
        next unless (@last);

        $lastuser = shift @last
            or next;

        # Found time on column starting as week day
        shift @last while ( @last > 3 && $last[0] !~ /^mon|tue|wed|thu|fri|sat|sun/i );
        $lastlogged = @last > 3 ? "@last[0..3]" : undef;
        last;
    }

    return unless $lastuser;

    return {
        LASTLOGGEDUSER     => $lastuser,
        DATELASTLOGGEDUSER => $lastlogged
    };
}

1;
