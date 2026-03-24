package GLPI::Agent::SNMP::MibSupport::Akcp;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See AKCP

use constant    akcp    => '.1.3.6.1.4.1.3854';

use constant    sensorProbeMAC  => akcp . '.1.2.2.1.3.0';

use constant    plusSeries  => akcp . '.3';
use constant    device      => plusSeries . '.2';
use constant    config      => device . '.1';

use constant    cfgSystemDescription    => config . '.8.0';
use constant    cfgSystemName           => config . '.9.0';
use constant    cfgIPAddress            => config . '.14.0';

our $mibSupport = [
    {
        name        => "akcp",
        sysobjectid => getRegexpOidMatch(akcp)
    }
];

sub getMacAddress {
    my ($self) = @_;

    return getCanonicalMacAddress(getCanonicalString($self->get(sensorProbeMAC)));
}

sub getSerial {
    my ($self) = @_;

    my $macaddress = $self->getMacAddress()
        or return;

    # Replace any colon by dash
    $macaddress =~ s/:/-/g;

    return $macaddress;
}

sub getModel {
    my ($self) = @_;

    my $cfgSystemDescription = getCanonicalString($self->get(cfgSystemDescription))
        or return;

    my ($model) = $cfgSystemDescription =~ /^(\S+\s+\S+)/;

    return $model;
}

sub getFirmware {
    my ($self) = @_;

    my $cfgSystemDescription = getCanonicalString($self->get(cfgSystemDescription))
        or return;

    my ($version) = $cfgSystemDescription =~ /^\S+\s+\S+\s+([1-9][0-9.]+)/;

    return $version;
}

sub getIp {
    my ($self) = @_;

    return getCanonicalString($self->get(cfgIPAddress));
}

sub getManufacturer {
    return "AKCP";
}

sub getSnmpHostname {
    my ($self) = @_;

    return getCanonicalString($self->get(cfgSystemName));
}

sub getType {
    return 'NETWORKING';
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Akcp - Inventory module for Akcp based devices

=head1 DESCRIPTION

The module enhances Akcp devices support.
