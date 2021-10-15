package GLPI::Agent::SNMP::MibSupport::Panasas;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See PANASAS-ROOT-MIB

use constant    panasas => '.1.3.6.1.4.1.10159' ;
use constant    panHw   => panasas . '.1.2' ;
use constant    panFs   => panasas . '.1.3' ;

# See PANASAS-SYSTEM-MIB-V1

use constant    panClusterName                  => panFs . '.2.1.1.0' ;
use constant    panClusterManagementAddress     => panFs . '.2.1.2.0' ;
use constant    panClusterRepsetEntryIpAddr     => panFs . '.2.1.3.1.2' ;
use constant    panClusterRepsetEntryBladeHwSN  => panFs . '.2.1.3.1.3' ;

our $mibSupport = [
    {
        name        => "panasas-panfs",
        sysobjectid => getRegexpOidMatch(panFs.'.0')
    }
];

sub getSerial {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Get the ip from session hostname or default to cluster management address
    my $ip = $device->{snmp}->peer_address()
        || $self->get(panClusterManagementAddress);

    return unless $ip;

    # Find member ip index to select the related S/N
    my $cloudips = $self->walk(panClusterRepsetEntryIpAddr);
    foreach my $index (keys(%{$cloudips})) {
        if ($cloudips->{$index} eq $ip) {
            my $serial = $self->get(panClusterRepsetEntryBladeHwSN.'.'.$index);
            return hex2char($serial);
        }
    }
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $name = $self->get(panClusterName)
        or return;

    $device->{INFO}->{NAME} = getCanonicalString($name);
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Panasas - Inventory module for Panasas PanFS

=head1 DESCRIPTION

The module enhances Panasas PanFS device support.
