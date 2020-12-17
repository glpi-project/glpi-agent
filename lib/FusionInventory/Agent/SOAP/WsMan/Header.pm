package FusionInventory::Agent::SOAP::WsMan::Header;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Header;

use parent 'Node';

use constant    xmlns   => 's';

use FusionInventory::Agent::SOAP::WsMan::Action;
use FusionInventory::Agent::SOAP::WsMan::RelatesTo;
use FusionInventory::Agent::SOAP::WsMan::OperationID;

sub support {
    return {
        Action      => "a:Action",
        RelatesTo   => "a:RelatesTo",
        OperationID => "p:OperationID",
    };
}

sub action {
    my ($self, $header) = @_;

    return $self->get('Action') // '';
}

1;
