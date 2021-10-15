package GLPI::Agent::SOAP::WsMan::Header;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Header;

use parent
    'Node';

use constant    xmlns   => 's';

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
