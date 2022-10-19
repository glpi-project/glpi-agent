package GLPI::Agent::Tools::Win32::Users;

use strict;
use warnings;
use parent 'Exporter';

use Encode qw(encode);

use GLPI::Agent::Tools::Win32;

our @EXPORT = qw(
    getSystemUserProfiles
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

1;
