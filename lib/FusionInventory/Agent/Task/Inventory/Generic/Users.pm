package FusionInventory::Agent::Task::Inventory::Generic::Users;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

use constant    other_categories
                            => qw(local_user local_group);
use constant    category    => "user";

sub isEnabled {
    my (%params) = @_;

    # Not working under win32
    return 0 if $OSNAME eq 'MSWin32';

    return
        canRun('who')  ||
        canRun('last') ||
        -r '/etc/passwd';
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

    my $handle = getFileHandle(%params);
    return unless $handle;

    my @users;

    while (my $line = <$handle>) {
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
    close $handle;

    return @users;
}

sub _getLocalGroups {
    my (%params) = (
        file => '/etc/group',
        @_
    );

    my $handle = getFileHandle(%params);
    return unless $handle;

    my @groups;

    while (my $line = <$handle>) {
        next if $line =~ /^#/;
        chomp $line;
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
    close $handle;

    return @groups;
}

sub _getLoggedUsers {
    my (%params) = (
        command => 'who',
        @_
    );

    my $handle = getFileHandle(%params);
    return unless $handle;

    my @users;
    my $seen;

    while (my $line = <$handle>) {
        next unless $line =~ /^(\S+)/;
        next if $seen->{$1}++;
        push @users, { LOGIN => $1 };
    }
    close $handle;

    return @users;
}

sub _getLastUser {
    my (%params) = (
        command => 'last',
        @_
    );

    my ($lastuser,$lastlogged);

    my $handle = getFileHandle(%params);
    return unless $handle;

    while (my $last = <$handle>) {
        chomp $last;
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
    close $handle;

    return unless $lastuser;

    return {
        LASTLOGGEDUSER     => $lastuser,
        DATELASTLOGGEDUSER => $lastlogged
    };
}

1;
