package FusionInventory::Agent::SOAP::WsMan::Header;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Header;

use parent 'Node';

sub get {
    my ($self) = @_;

    return "s:Header" => $self->SUPER::get();
}

1;
