package GLPI::Agent::SNMP::MibSupport::IEEE802dot11;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# Set lower priority to only update empty values
use constant    priority    => 50;

# See IEEE802dot11-MIB

use constant ieee802dot11   => '.1.2.840.10036';

use constant dot11ResourceInfoEntry => ieee802dot11 . '.3.1.2.1';

use constant dot11manufacturerName              => dot11ResourceInfoEntry . '.2';
use constant dot11manufacturerProductName       => dot11ResourceInfoEntry . '.3';
use constant dot11manufacturerProductVersion    => dot11ResourceInfoEntry . '.4';

our $mibSupport = [
    {
        name    => "ieee802dot11",
        oid     => ieee802dot11
    }
];

sub _getFirstKey {
    my ($self, $walk) = @_;

    return unless ref($walk) eq 'HASH';

    return $self->{_firstKey} if exists($self->{_firstKey});

    my @suffix = map { [ split(/[.]/, $_) ] } keys(%{$walk});
    my ($first) = sort { _sortSuffix($a, $b) } @suffix;

    return $self->{_firstKey} = join('.', @{$first});
}

sub _sortSuffix {
    my ($a, $b) = @_;

    my @ak = @{$a};
    my @bk = @{$b};

    while (@ak) {
        my $c = shift(@ak) <=> shift(@bk);
        return $c unless $c == 0;
    }

    return @bk ? 1 : 0;
}

sub getFirmware {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return unless empty($device->{FIRMWARE});

    my $productversion = $self->walk(dot11manufacturerProductVersion)
        or return;

    my $suffix = $self->_getFirstKey($productversion);

    my $version = getCanonicalString($productversion->{$suffix});

    # Extract version for Ubnt
    return $version =~ /^WA\.\w+\.(v\d+\.\d+\.\d+)/ ? "$1 (WA)" : $version;
}

sub getManufacturer {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return unless empty($device->{MANUFACTURER});

    my $manufacturername = $self->walk(dot11manufacturerName)
        or return;

    my $suffix = $self->_getFirstKey($manufacturername);

    return getCanonicalString($manufacturername->{$suffix});
}

sub getModel {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return unless empty($device->{MODEL});

    my $productname = $self->walk(dot11manufacturerProductName)
        or return;

    my $suffix = $self->_getFirstKey($productname);

    return getCanonicalString($productname->{$suffix});
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::IEEE802dot11 - Inventory module for devices supporting IEEE802.11

=head1 DESCRIPTION

This module enhances devices supporting IEEE802.11.
