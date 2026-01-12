package GLPI::Agent::Task::Inventory::Generic::Users;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use UNIVERSAL::require;

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
    # Use loginctl if available as more accurate than who when users has more than
    # 32 chars in length. This can happen when computer is connected to an AD
    if (canRun("loginctl")) {
        my $json_content = getAllLines(
            command => "loginctl --output json list-users",
            @_
        );
        unless (empty($json_content)) {
            Cpanel::JSON::XS->require();
            Cpanel::JSON::XS->import("decode_json");
            my $json;
            eval {
                $json = decode_json($json_content);
            };
            if (ref($json) eq "ARRAY") {
                my @users;
                my %seen;
                foreach my $logged (@{$json}) {
                    next if empty($logged->{user});
                    # Only keep users with uid >= 1000, others are root or system
                    # users and may be "logged" as service
                    next unless $logged->{uid} && $logged->{uid} >= 1000;
                    next if $seen{$logged->{user}}++;
                    push @users, { LOGIN => $logged->{user} };
                }
                return @users;
            }
        }
    }

    # if we cannot use loginctl, then we get login PIDs, then user UIDs, then full names via `id`
    my @pids = getAllLines(
            command => "who --users",
            @_
        );
    foreach (@pids) {
        my @pid_string = split(/\s+/, $_);
        $_ = $pid_string[6];
    }

    my $pids_comma = join(",", @pids);
    my @uids_raw = getAllLines(
            command => "ps -o user:128 -p $pids_comma",
            @_
        );

    my @uids;
    foreach (@uids_raw) {
        # https://programming-idioms.org/idiom/22/convert-string-to-integer/294/perl
        my $uid = $_ + 0;
        if ($uid > 0) {
            push @uids, $uid;
        }
    }

    # https://stackoverflow.com/a/7829
    my %uid_hash   = map { $_, 1 } @uids;
    @uids = keys %uid_hash;

    my @users;

    my $uids_space = join " ", @uids;
    my @users_raw = getAllLines(
            command => "id -un $uids_space",
            @_
        );
    foreach (@users_raw) {
        push @users, { LOGIN => $_ };
    }

    return @users;
}

sub _getLastUser {
    my (%params) = (
        command => 'last -w',
        @_
    );

    my ($lastuser, $lastlogged);

    my @lines = getAllLines(%params);
    unless (@lines) {
        $params{command} = 'last';
        @lines = getAllLines(%params)
            or return;
    }

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
