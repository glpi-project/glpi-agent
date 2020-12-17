package FusionInventory::Agent::SOAP::WsMan::IdentifyResponse;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    IdentifyResponse;

use parent 'Node';

use constant    xmlns   => 'wsmid';

use FusionInventory::Agent::SOAP::WsMan::Identify;

sub values {
    return [ qw(ProtocolVersion ProductVendor ProductVersion) ];
}

sub isvalid {
    my ($self) = @_;

    my ($xsd) = $self->attributes("xmlns:".xmlns);

    return $xsd eq Identify->xsd;
}

1;
