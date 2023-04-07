package GLPI::Agent::SNMP::MibSupport::CiscoPortSecurity;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    priority => 5;

# See CISCO-SMI
use constant    cisco       => '.1.3.6.1.4.1.9'  ;
use constant    ciscoMgmt   => cisco . '.9'     ;

# See CISCO-PORT-SECURITY-MIB
use constant    ciscoPortSecurityMIB        => ciscoMgmt . '.315' ;
use constant    cpsGlobalPortSecurityEnable => ciscoPortSecurityMIB .'.1.1.3.0' ;
use constant    cpsIfConfigEntry            => ciscoPortSecurityMIB .'.1.2.1.1' ;
use constant    cpsIfSecureLastMacAddress   => cpsIfConfigEntry . '.10' ;

our $mibSupport = [
    {
        name        => "cisco-port-security",
        privateoid  => cpsGlobalPortSecurityEnable,
    }
];

sub run {
    my ($self) = @_;

    # Don't analyse anything if the feature is not enabled
    return unless $self->get(cpsGlobalPortSecurityEnable);

    my $cpsIfSecureLastMacAddress = $self->walk(cpsIfSecureLastMacAddress)
        or return;

    my $device = $self->device
        or return;

    foreach my $port (keys(%{$cpsIfSecureLastMacAddress})) {
        my $mac = getCanonicalMacAddress($cpsIfSecureLastMacAddress->{$port})
            or next;
        next unless $device->{PORTS} && $device->{PORTS}->{PORT} && $device->{PORTS}->{PORT}->{$port};
        $device->{PORTS}->{PORT}->{$port}->{CONNECTIONS}->{CONNECTION}->{MAC} = [ $mac ];
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::CiscoPortSecurity - Inventory module to add connections
detected via Cisco Port Security feature.

=head1 DESCRIPTION

The module enhances Cisco support.
