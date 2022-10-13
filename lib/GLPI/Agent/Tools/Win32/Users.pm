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

    foreach my $userprofile (getWMIObjects(
        query      => "SELECT * FROM Win32_UserProfile WHERE LocalPath IS NOT NULL AND Special=FALSE",
        properties => [ qw/Sid Loaded LocalPath/ ],
    )) {
        next unless $userprofile->{Sid} && $userprofile->{Sid} =~ /^S-\d+-5-21-/;

        next unless defined($userprofile->{Loaded}) && defined($userprofile->{LocalPath});

        $userprofile->{LocalPath} =~ s{\\}{/}g;

        my $user = {
            SID    => $userprofile->{Sid},
            PATH   => $userprofile->{LocalPath},
            LOADED => $userprofile->{Loaded} =~ /^1|true$/ ? 1 : 0
        };

        my ($account) = getWMIObjects(
            query      => "SELECT * FROM Win32_Account WHERE Sid='$userprofile->{Sid}' AND SIDType=1",
            properties => [ qw/Name/ ]
        );
        if ($account && $account->{Name}) {
            $user->{NAME} = $account->{Name};
        } elsif ($user->{PATH} =~ m{/([^/]+)$}) {
            $user->{NAME} = $1;
        }

        push @users, $user;
    }

    return @users;
}

1;
