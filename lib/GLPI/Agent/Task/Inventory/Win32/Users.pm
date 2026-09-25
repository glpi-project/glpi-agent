package GLPI::Agent::Task::Inventory::Win32::Users;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Win32;
use GLPI::Agent::Tools::Win32::Users;

use constant    other_categories
                            => qw(local_user local_group);
use constant    category    => "user";

our $WINDOWS_UPN_AS_LOGIN;

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # Handle features
    $WINDOWS_UPN_AS_LOGIN = $params{features}->{WINDOWS_UPN_AS_LOGIN} ? 1 : 0;

    unless ($params{no_category}->{local_user}) {
        foreach my $user (getUsers(
            localusers  => 1,
            logger      => $logger
        )) {
            $inventory->addEntry(
                section => 'LOCAL_USERS',
                entry   => { map { $_ => $user->{$_} } qw/NAME ID/ }
            );
        }
    }

    unless ($params{no_category}->{local_group}) {
        foreach my $group (_getLocalGroups(logger => $logger)) {
            $inventory->addEntry(
                section => 'LOCAL_GROUPS',
                entry   => $group
            );
        }
    }

    # Handles seen users without being case sensitive
    my %seen = ();

    my $lastLoggedUser = _getLastUser(logger => $logger);
    if ($lastLoggedUser) {
        # Include last logged user as usual computer user
        if (ref($lastLoggedUser) eq 'HASH') {
            my $fullname = delete $lastLoggedUser->{_fullname};
            $fullname = $fullname ? lc($fullname) : lc($lastLoggedUser->{LOGIN}).'@'.lc($lastLoggedUser->{DOMAIN});
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

    foreach my $user (_getLoggedUsers(logger => $logger)) {
        my $fullname = lc($user->{LOGIN}).'@'.lc($user->{DOMAIN});
        $inventory->addEntry(
            section => 'USERS',
            entry   => $user
        ) unless $seen{$fullname}++;
    }
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
        User       => [ 'string', '' ],
        Domain     => [ 'string', '' ],
        selector   => 'Handle', # For winrm support
        binds      => {
            User    => 'LOGIN',
            Domain  => 'DOMAIN'
        })
    ) {
        next if !defined($user->{LOGIN}) || $seen->{$user->{LOGIN}}++;

        push @users, $user;
    }

    return @users;
}

sub _getFallbackLastUser {
    my %params = @_;

    my $user;

    my ($system) = getWMIObjects(
        class      => 'Win32_ComputerSystem',
        properties => [ qw/Name UserName/ ],
        %params
    );
    if ($system && $system->{Name} && $system->{UserName}) {
        if ($system->{UserName} =~ /^([^\\]*)\\(.*)$/) {
            $user->{DOMAIN} = $1 unless $1 eq '.';
            $user->{LOGIN}  = $2;
            # Handle AzureAD case
            if ($user->{DOMAIN} && $user->{DOMAIN} eq 'AzureAD') {
                my $upn = _getLastLoggedAzureADUserUPN(name => $user->{LOGIN}, %params);
                if ($upn && $upn =~ /^([^@]+)\@(.+)$/) {
                    $user->{_fullname} = $user->{LOGIN}.'@AzureAD';
                    $user->{LOGIN}     = $1;
                    $user->{DOMAIN}    = $2;
                }
            }
        }
    }

    return $user;
}

sub _getLastUser {
    my %params = @_;

    my $user;

    unless ($WINDOWS_UPN_AS_LOGIN) {
        $user = _getFallbackLastUser(%params);
        return $user if ref($user);
    }

    my @registry_tries = (
        'SOFTWARE/Microsoft/Windows/CurrentVersion/Authentication/LogonUI/LastLoggedOnSAMUser'
    );
    my $LastLoggedOnUser = 'SOFTWARE/Microsoft/Windows/CurrentVersion/Authentication/LogonUI/LastLoggedOnUser';
    if ($WINDOWS_UPN_AS_LOGIN) {
        # Try first $LastLoggedOnUser when feature is set
        unshift @registry_tries, $LastLoggedOnUser;
    } else {
        push @registry_tries, $LastLoggedOnUser;
    }
    push @registry_tries,
        'SOFTWARE/Microsoft/Windows NT/CurrentVersion/Winlogon/DefaultUserName',
        'SOFTWARE/Microsoft/Windows NT/CurrentVersion/Winlogon/LastUsedUsername';

    return _getFallbackLastUser(%params) unless any {
        $user = getRegistryValue(path => "HKEY_LOCAL_MACHINE/$_", %params)
    } @registry_tries;

    # LastLoggedOnSAMUser becomes the mandatory value to detect last logged on user
    # unless WINDOWS_UPN_AS_LOGIN feature is set
    if ($user =~ /^([^\\]*)\\(.*)$/) {
        $user = {
            DOMAIN  => $1,
            LOGIN   => $2
        };
        # Update domain if just a dot
        if ($user->{DOMAIN} eq '.') {
            my ($system) = getWMIObjects(
                class      => 'Win32_ComputerSystem',
                properties => [ qw/Name/ ],
                %params
            );
            $user->{DOMAIN} = $system->{Name} if $system && $system->{Name};
        }
        if ($user->{DOMAIN} eq '.') {
            my ($useraccount) = getUsers(
                login => $user->{LOGIN},
                %params
            );
            $user->{DOMAIN} = $useraccount->{DOMAIN}
                if $useraccount;
        } elsif ($user->{DOMAIN} eq 'AzureAD') {
            # Handle AzureAD case
            my $upn = _getLastLoggedAzureADUserUPN(name => $user->{LOGIN}, %params);
            if ($upn && $upn =~ /^([^@]+)\@(.+)$/) {
                $user->{_fullname} = $user->{LOGIN}.'@AzureAD';
                $user->{LOGIN}     = $1;
                $user->{DOMAIN}    = $2;
            }
        }
    } elsif ($user =~ /^[^@]+\@.+$/) {
        # Set domain and use UPN as login
        $user = {
            LOGIN   => $user
        };
        # Try to set _fullname from fallback to avoid duplicating the user after
        # _getLoggedUsers() call
        my $fallback = _getFallbackLastUser(%params);
        if (ref($fallback) && $fallback->{LOGIN} && $fallback->{DOMAIN}) {
            $user->{_fullname} = $fallback->{LOGIN}.'@'.$fallback->{DOMAIN};
        }
    }

    return _getFallbackLastUser(%params) unless ref($user);

    return $user;
}

sub _getLastLoggedAzureADUserUPN {
    my %params = @_;

    my $sid = getRegistryValue(
        path => "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows/CurrentVersion/Authentication/LogonUI/LastLoggedOnUserSID",
        %params
    );
    return unless $sid;

    my $samname = getRegistryValue(
        path => "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/IdentityStore/Cache/$sid/IdentityCache/$sid/SAMName",
        %params
    );
    return unless $samname && $params{name} && $samname eq $params{name};

    return getRegistryValue(
        path => "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/IdentityStore/Cache/$sid/IdentityCache/$sid/UserName",
        %params
    );
}

1;
