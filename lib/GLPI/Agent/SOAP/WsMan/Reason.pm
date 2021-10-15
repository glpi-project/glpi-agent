package GLPI::Agent::SOAP::WsMan::Reason;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Reason;

use parent
    'Node';

use constant    xmlns   => 's';

sub support {
    return {
        Text    => "s:Text",
    };
}

sub text {
    my ($self) = @_;

    my ($text) = $self->get('Text');

    return $text->string // '';
}

1;
