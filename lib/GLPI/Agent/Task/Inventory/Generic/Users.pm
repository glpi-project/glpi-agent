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
    my (%params) = @_;

    my $logger = $params{logger};

    # Use loginctl if available as more accurate than who when users has more than
    # 32 chars in length. This can happen when computer is connected to an AD
    if (canRun("loginctl")) {
        my $json_content = getAllLines(
            command => "loginctl --output json list-users",
            logger  => $logger
        );
        # --output argument may not output expected result depending on loginctl version
        if (empty($json_content) || $json_content !~ /^\[/) {
            $json_content = getAllLines(
                command => "loginctl --json=short list-users",
                logger  => $logger
            );
        }
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
                my $uid_min = 1000;
                if (has_file("/etc/login.defs")) {
                    my $uid = getFirstMatch(
                        file    => "/etc/login.defs",
                        pattern => qr/^UID_MIN\s+(\d+)/,
                        logger  => $logger
                    );
                    $uid_min = int($uid) unless empty($uid);
                }
                foreach my $logged (@{$json}) {
                    next if empty($logged->{user});
                    # Only keep users with uid >= UID_MIN, others are root or system
                    # users and may be "logged" as service
                    next unless $logged->{uid} && $logged->{uid} >= $uid_min;
                    next if $seen{$logged->{user}}++;
                    push @users, { LOGIN => $logged->{user} };
                }
                return @users;
            }
        }
    }

    # if we cannot use loginctl, then we get login PIDs, then user UIDs, then full names via `id`
    my @ppids;
    foreach (getAllLines(
        command => "who --users",
        logger  => $logger
    )) {
        my @fields = split(/\s+/, $_);
        next unless $fields[6] =~ /^\d+$/;
        push @ppids, $fields[6];
    }

    return _legacyGetLoggedUsers(%params)
        unless @ppids;

    my @logged_uids = getAllLines(
        command => "ps --no-headers -o uid --ppid " . join(",", @ppids),
        logger  => $logger
    );

    return _legacyGetLoggedUsers(%params)
        unless @logged_uids;

    my %uids;
    my @uids;
    foreach my $uid (@logged_uids) {
        next unless $uid =~ /(\d+)/;
        next if int($1) == 0 || $uids{$1};
        $uids{$1} = 1;
        push @uids, $1;
    }

    return _legacyGetLoggedUsers(%params)
        unless @uids;

    my @users = getAllLines(
        command => "id -un @uids",
        logger  => $logger
    );

    return _legacyGetLoggedUsers(%params)
        unless @users;

    return map { { LOGIN => $_ } } @users;
}

sub _legacyGetLoggedUsers {
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
