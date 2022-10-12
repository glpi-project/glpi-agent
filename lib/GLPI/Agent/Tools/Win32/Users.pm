package GLPI::Agent::Tools::Win32::Users;

use strict;
use warnings;
use parent 'Exporter';

use GLPI::Agent::Tools::Win32;

our @EXPORT = qw(
    getSystemUsers
);

sub getSystemUsers {

    my @users;

    foreach my $profile (_getUserProfiles()) {

        my $query =
            "SELECT * FROM Win32_UserAccount " .
            "WHERE Sid='$profile->{SID}' AND Disabled='False' AND Lockout='False' AND SIDType=1";

        my ($object) = getWMIObjects(
            moniker    => 'winmgmts:\\\\.\\root\\CIMV2',
            query      => $query,
            properties => [ qw/Name/ ]
        );

        next unless $object;

        push @users, {
            NAME   => $object->{Name},
            SID    => $profile->{SID},
            PATH   => $profile->{PATH},
            LOADED => $profile->{LOADED},
        };
    }

    return @users;
}

sub _getUserProfiles {

    my $query = "SELECT * FROM Win32_UserProfile WHERE LocalPath IS NOT NULL AND Special=FALSE";

    my @profiles;

    foreach my $profile (getWMIObjects(
        moniker    => 'winmgmts:\\\\.\\root\\CIMV2',
        query      => $query,
        properties => [ qw/Sid Loaded LocalPath/ ],
    )) {
        next unless $profile->{Sid} && defined($profile->{Loaded}) && defined($profile->{LocalPath});

        $profile->{LocalPath} =~ s{\\}{/}g;

        push @profiles, {
            SID    => $profile->{Sid},
            PATH   => $profile->{LocalPath},
            LOADED => $profile->{Loaded} =~ /^1|true$/ ? 1 : 0
        };
    }

    return @profiles;
}

1;
