package GLPI::Agent::SNMP::MibSupport::CiscoUcsBoard;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    priority => 5;

# See CISCO-SMI
use constant    cisco       => '.1.3.6.1.4.1.9'  ;
use constant    ciscoMgmt   => cisco . '.9'     ;

# See CISCO-UNIFIED-COMPUTING-MIB
use constant    ciscoUnifiedComputingMIB        => ciscoMgmt . '.719' ;
use constant    ciscoUnifiedComputingMIBObjects => ciscoUnifiedComputingMIB . '.1' ;

# See CISCO-UNIFIED-COMPUTING-COMPUTE-MIB
use constant    cucsComputeObjects      => ciscoUnifiedComputingMIBObjects . '.9' ;
use constant    cucsComputeBoardTable   => cucsComputeObjects . '.6' ;
use constant    cucsComputeBoardDn      => cucsComputeBoardTable . '.1.2.1' ;
use constant    cucsComputeBoardModel   => cucsComputeBoardTable . '.1.6.1' ;
use constant    cucsComputeBoardSerial  => cucsComputeBoardTable . '.1.14.1' ;

our $mibSupport = [
    {
        name        => "cisco-ucs-board",
        privateoid  => cucsComputeBoardDn,
    }
];

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(cucsComputeBoardModel));
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(cucsComputeBoardSerial));
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::CiscoUcsBoard - Inventory module to support Cisco UCS board.

=head1 DESCRIPTION

The module enhances Cisco support.
