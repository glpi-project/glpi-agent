package GLPI::Agent::SNMP::MibSupport::Qnap;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    priority => 5;

# See NAS-MIB
use constant    qnap_storage        => '.1.3.6.1.4.1.24681'  ;
use constant    es_storageSystem    => qnap_storage.'.2'     ;
use constant    es_SystemInfo       => es_storageSystem.'.2' ;
use constant    es_ModelName        => es_SystemInfo.'.12.0' ;
use constant    es_HostName         => es_SystemInfo.'.13.0' ;

our $mibSupport = [
    {
        name        => "qnap-storage",
        sysobjectid => qnap_storage,
    },
    {
        name        => "qnap-model",
        privateoid  => es_ModelName,
    }
];

sub getType {
    return 'STORAGE';
}

sub getModel {
    my ($self) = @_;

    return $self->get(es_ModelName);
}

sub getManufacturer {
    return 'Qnap';
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::QNAP - Inventory module for QNAP NAS

=head1 DESCRIPTION

The module enhances QNAP NAS support.
