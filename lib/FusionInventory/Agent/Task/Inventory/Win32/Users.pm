package FusionInventory::Agent::Task::Inventory::Win32::Users;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Win32;

use constant    other_categories
                            => qw(local_user local_group);
use constant    category    => "user";

sub isEnabled {
    return 1;
}

sub isEnabledForRemote {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    if (!$params{no_category}->{local_user}) {
        foreach my $user (_getLocalUsers(logger => $logger)) {
            $inventory->addEntry(
                section => 'LOCAL_USERS',
                entry   => $user
            );
        }
    }

    if (!$params{no_category}->{local_group}) {
        foreach my $group (_getLocalGroups(logger => $logger)) {
            $inventory->addEntry(
                section => 'LOCAL_GROUPS',
                entry   => $group
            );
        }
    }

    # Handles seen users without being case sensitive
    my %seen = ();

    foreach my $user (_getLoggedUsers(logger => $logger)) {
        my $fullname = lc($user->{LOGIN}).'@'.lc($user->{DOMAIN});
        $inventory->addEntry(
            section => 'USERS',
            entry   => $user
        ) unless $seen{$fullname}++;
    }

    my $lastLoggedUser = _getLastUser(logger => $logger);
    if ($lastLoggedUser) {
        # Include last logged user as usual computer user
        if (ref($lastLoggedUser) eq 'HASH') {
            my $fullname = lc($lastLoggedUser->{LOGIN}).'@'.lc($lastLoggedUser->{DOMAIN});
            $inventory->addEntry(
                section => 'USERS',
                entry   => $lastLoggedUser
            ) unless $seen{$fullname}++;

            # Obsolete in specs, to be removed with 3.0
            $inventory->setHardware({
                LASTLOGGEDUSER => $lastLoggedUser->{LOGIN}
            });
        } else {
            # Obsolete in specs, to be removed with 3.0
            $inventory->setHardware({
                LASTLOGGEDUSER => $lastLoggedUser
            });
        }
    }
}

sub _getLocalUsers {

    my $query =
        "SELECT * FROM Win32_UserAccount " .
        "WHERE LocalAccount='True' AND Disabled='False' AND Lockout='False'";

    my @users;

    foreach my $object (getWMIObjects(
        moniker    => 'winmgmts:\\\\.\\root\\CIMV2',
        query      => $query,
        properties => [ qw/Name SID/ ])
    ) {
        my $user = {
            NAME => $object->{Name},
            ID   => $object->{SID},
        };
        push @users, $user;
    }

    return @users;
}

sub _getLocalGroups {

    my $query =
        "SELECT * FROM Win32_Group " .
        "WHERE LocalAccount='True'";

    my @groups;

    foreach my $object (getWMIObjects(
        moniker    => 'winmgmts:\\\\.\\root\\CIMV2',
        query      => $query,
        properties => [ qw/Name SID/ ])
    ) {
        # Replace "right single quotation mark" by "simple quote" to avoid "Wide character in print" error
        $object->{Name} =~ s/\x{2019}/'/g;

        my $group = {
            NAME => $object->{Name},
            ID   => $object->{SID},
        };
        push @groups, $group;
    }

    return @groups;
}

sub _getLoggedUsers {

    my $query =
        "SELECT * FROM Win32_Process".
        " WHERE ExecutablePath IS NOT NULL" .
        " AND ExecutablePath LIKE '%\\\\Explorer\.exe'";

    my @users;
    my $seen;

    foreach my $user (getWMIObjects(
        moniker    => 'winmgmts:\\\\.\\root\\CIMV2',
        query      => $query,
        method     => 'GetOwner',
        params     => [ 'User', 'Domain' ],
        name       => [ 'string', '' ],
        domain     => [ 'string', '' ],
        selector   => 'Handle', # For winrm support
        binds      => {
            User    => 'LOGIN',
            Domain  => 'DOMAIN'
        })
    ) {
        next if $seen->{$user->{LOGIN}}++;

        push @users, $user;
    }

    return @users;
}

sub _getLastUser {

    my $user;

    return unless any {
        $user = getRegistryValue(path => "HKEY_LOCAL_MACHINE/$_")
    } (
        'SOFTWARE/Microsoft/Windows/CurrentVersion/Authentication/LogonUI/LastLoggedOnSAMUser',
        'SOFTWARE/Microsoft/Windows/CurrentVersion/Authentication/LogonUI/LastLoggedOnUser',
        'SOFTWARE/Microsoft/Windows NT/CurrentVersion/Winlogon/DefaultUserName'
    );

    # LastLoggedOnSAMUser becomes the mandatory value to detect last logged on user
    my @user = $user =~ /^([^\\]*)\\(.*)$/;
    if ( @user == 2 ) {
        # Try to get local user from user part if domain is just a dot
        return $user[0] eq '.' ? _getLocalUser($user[1]) :
            {
                LOGIN   => $user[1],
                DOMAIN  => $user[0]
            };
    }

    # Backward compatibility, to be removed for 3.0
    $user =~ s,.*\\,,;
    return $user;
}

sub _getLocalUser {
    my ($name) = @_;

    my $query = "SELECT * FROM Win32_UserAccount WHERE LocalAccount = True";

    my @local_users = getWMIObjects(
        moniker    => 'winmgmts:\\\\.\\root\\CIMV2',
        query      => $query,
        properties => [ qw/Name Domain/ ]
    );

    my $user = first { $_->{Name} eq $name } @local_users;

    return unless $user;

    return {
        LOGIN   => $user->{Name},
        DOMAIN  => $user->{Domain}
    };
}

1;
