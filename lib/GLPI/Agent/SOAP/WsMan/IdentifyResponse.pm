package GLPI::Agent::SOAP::WsMan::IdentifyResponse;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    IdentifyResponse;

use parent
    'Node';

use constant    xmlns   => 'wsmid';

use GLPI::Agent::SOAP::WsMan::Identify;

sub values {
    return [ qw(ProtocolVersion ProductVendor ProductVersion) ];
}

sub isvalid {
    my ($self) = @_;

    my ($xsd) = $self->attribute("xmlns:".xmlns);

    return $xsd eq Identify->xsd;
}

sub ProductVendor {
    my ($self) = @_;

    return $self->get('ProductVendor')->string;
}

sub ProductVersion {
    my ($self) = @_;

    return $self->get('ProductVersion')->string;
}

1;
