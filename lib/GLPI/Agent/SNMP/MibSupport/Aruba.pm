package GLPI::Agent::SNMP::MibSupport::Aruba;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    aruba   => '.1.3.6.1.4.1.14823' ;

our $mibSupport = [
    {
        name        => "aruba",
        sysobjectid => getRegexpOidMatch(aruba)
    }
];

sub getModel {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $model;

    # Extract model from device description for ArubaOS based systems
    ( $model ) = $device->{DESCRIPTION} =~ /^ArubaOS\s+\(MODEL:\s*(.*)\)/
        if $device->{DESCRIPTION};

    return unless $model;

    return "AP $model";
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Aruba - Inventory module for Aruba AP

=head1 DESCRIPTION

The module enhances Aruba wifi access point devices support.
