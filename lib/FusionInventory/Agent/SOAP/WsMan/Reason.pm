package FusionInventory::Agent::SOAP::WsMan::Reason;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Reason;

use parent 'Node';

use constant    xmlns   => 's';

use FusionInventory::Agent::SOAP::WsMan::Text;

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
