package GLPI::Agent::SNMP::MibSupport::BrotherNetConfig;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    priority => 5;

# See BROTHER-MIB
use constant    brother => '.1.3.6.1.4.1.2435' ;

use constant    net_peripheral  => brother . '.2.3.9' ;
use constant    device          => net_peripheral . '.4.2.1' ;

use constant    printerinfomation   => device . '.5.5' ;
use constant    brInfoSerialNumber  => printerinfomation . '.1.0' ;

# Brother NetConfig
use constant    brnetconfig => brother . '.2.4.3.1240' ;
use constant    brconfig    => brnetconfig . '.1' ;

use constant    brpsNodeName            => brconfig . '.1.0' ;
use constant    brpsMainRevision        => brconfig . '.4.0' ;
use constant    brpsServerDescription   => brconfig . '.12.0' ;

our $mibSupport = [
    {
        name        => "brother-netconfig",
        privateoid  => brpsNodeName
    }
];

sub getFirmware {
    my ($self) = @_;

    return getCanonicalString($self->get(brpsMainRevision));
}

sub getSnmpHostname {
    my ($self) = @_;

    return getCanonicalString($self->get(brpsNodeName));
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(brInfoSerialNumber));
}

sub getManufacturer {
    my ($self) = @_;

    my $description = getCanonicalString($self->get(brpsServerDescription));
    return unless $description =~ /^Brother .*$/i;

    return "Brother";
}

sub getModel {
    my ($self) = @_;

    my $description = getCanonicalString($self->get(brpsServerDescription));
    my ($model) = $description =~ /^Brother (.*)$/i;

    return $model;
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::BrotherNetConfig - Inventory module for Brother Printers

=head1 DESCRIPTION

The module enhances Brother printers devices support.
