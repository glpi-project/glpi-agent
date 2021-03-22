package FusionInventory::Agent::Tools::Win32::Users;

use strict;
use warnings;
use parent 'Exporter';

use Encode;
use FusionInventory::Agent::Tools::Win32;

our @EXPORT = qw(
    getSystemUsers  getUserProfile
);

sub getSystemUsers {

    my @users;

    foreach my $object (getWMIObjects(
        moniker    => 'winmgmts:\\\\.\\root\\CIMV2',
        class      => 'Win32_SystemUsers',
        properties => [ qw/PartComponent/ ])
    ) {
        my ($name) = $object->{PartComponent} =~ /Win32_UserAccount.Name="([^"]*)"/
            or next;

        my $query =
            "SELECT * FROM Win32_UserAccount " .
            "WHERE Name='$name' AND Disabled='False' and Lockout='False'";

        ($object) = getWMIObjects(
            moniker    => 'winmgmts:\\\\.\\root\\CIMV2',
            query      => $query,
            properties => [ qw/Name SID/ ]
        );

        next unless $object;

        push @users, {
            NAME => $object->{Name},
            SID  => $object->{SID},
        };
    }

    return @users;
}

sub getUserProfile {
    my ($sid) = @_;

    return unless $sid;

    my $query = "SELECT * FROM Win32_UserProfile WHERE SID='$sid'";

    my ($profile) = getWMIObjects(
        moniker    => 'winmgmts:\\\\.\\root\\CIMV2',
        query      => $query,
        properties => [ qw/Loaded LocalPath/ ],
    );

    return unless $profile && defined($profile->{Loaded}) && defined($profile->{LocalPath});

    $profile->{LocalPath} =~ s{\\}{/}g;

    return {
        LOADED => $profile->{Loaded} =~ /^1|true$/ ? 1 : 0,
        PATH   => $profile->{LocalPath},
    };
}

1;
