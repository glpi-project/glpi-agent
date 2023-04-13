package GLPI::Agent::Tools::Win32::Users;

use strict;
use warnings;
use parent 'Exporter';

use Encode qw(decode encode);

use GLPI::Agent::Tools::Win32;

our @EXPORT = qw(
    getSystemUserProfiles
    getProfileUsername
    getUsers
);

sub getSystemUserProfiles {

    my @profiles;

    foreach my $userprofile (getWMIObjects(
        query      => "SELECT * FROM Win32_UserProfile WHERE LocalPath IS NOT NULL AND Special=FALSE",
        properties => [ qw/Sid Loaded LocalPath/ ],
    )) {
        next unless $userprofile->{Sid} && $userprofile->{Sid} =~ /^S-\d+-5-21-/;

        next unless defined($userprofile->{Loaded}) && defined($userprofile->{LocalPath});

        $userprofile->{LocalPath} =~ s{\\}{/}g;
        $userprofile->{LocalPath} = encode(getLocalCodepage(), $userprofile->{LocalPath});

        push @profiles, {
            SID    => $userprofile->{Sid},
            PATH   => $userprofile->{LocalPath},
            LOADED => $userprofile->{Loaded} =~ /^1|true$/ ? 1 : 0
        };
    }

    return @profiles;
}

sub getProfileUsername {
    my ($user) = @_;

    # First try to get username from volatile environment
    my $userenvkey = getRegistryKey(
        path        => "HKEY_USERS/$user->{SID}/Volatile Environment/",
        # Important for remote inventory optimization
        required    => [ qw/USERNAME/ ],
    );
    return $userenvkey->{'/USERNAME'}
        if $userenvkey && defined($userenvkey->{'/USERNAME'}) && length($userenvkey->{'/USERNAME'});

    # Then try to get it from Group Policy Caching
    my $cacheentry = getRegistryKey(
        path        => "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows/CurrentVersion/Group Policy/DataStore/$user->{SID}/0",
        # Important for remote inventory optimization
        required    => [ qw/szTargetName/ ],
    );
    return decode(getLocalCodepage(), $cacheentry->{'/szTargetName'})
        if $cacheentry && defined($cacheentry->{'/szTargetName'}) && length($cacheentry->{'/szTargetName'});

    # Eventually look up in LogonUI session datas
    my $sessiondata = getRegistryKey(
        path        => "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows/CurrentVersion/Authentication/LogonUI/SessionData",
        # Important for remote inventory optimization
        required    => [ qw/LoggedOnUserSID LoggedOnUser/ ],
    );
    if ($sessiondata) {
        foreach my $key (keys(%{$sessiondata})) {
            next unless $key =~ m{/$};
            my $usersid = $sessiondata->{$key}->{'/LoggedOnUserSID'};
            next unless defined($usersid) && $user->{SID} eq $usersid;
            my $account = $sessiondata->{$key}->{'/LoggedOnUser'};
            next unless defined($account);
            my ($username) = $account =~ /^[^\\]*\\(.*)$/;
            return decode(getLocalCodepage(), $username) if defined($username) && length($username);
        }
    }

    # Finally try WMI request
    my ($account) = getUsers(sid => $user->{SID});
    return $account->{NAME} if $account && $account->{NAME};

    # Finally fall-back on user extraction from profile path, but this is not reliable
    # as the username may have been changed after the account has been created
    my ($username) = $user->{PATH} =~ m{/([^/]+)$};
    return decode(getLocalCodepage(), $username);
}

sub getUsers {
    my (%params) = @_;

    my @conditions = qw(
        Disabled='False'
        Lockout='False'
    );
    push @conditions, "LocalAccount='True'" if $params{localusers};
    push @conditions, "SID='$params{sid}'" if $params{sid};
    if ($params{login}) {
        $params{login} =~ s/'/\\'/g;
        push @conditions, "Name='$params{login}'";
    }

    my $query = "SELECT * FROM Win32_UserAccount WHERE ".join(" AND ", @conditions);

    my @users;

    # Warning ! On a large network, this WMI call can negatively affect
    # performance and fails with a timeout
    foreach my $object (getWMIObjects(
        moniker    => 'winmgmts:\\\\.\\root\\CIMV2',
        query      => $query,
        properties => [ qw/Domain Name SID/ ],
        logger     => $params{logger}
    )) {
        push @users, {
            DOMAIN  => $object->{Domain},
            NAME    => $object->{Name},
            ID      => $object->{SID},
        };
    }

    return @users;
}

1;
