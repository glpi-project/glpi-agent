package FusionInventory::Agent::SOAP::WsMan::Body;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Body;

use parent 'Node';

use constant    xmlns   => 's';

use FusionInventory::Agent::SOAP::WsMan::IdentifyResponse;
use FusionInventory::Agent::SOAP::WsMan::Fault;
use FusionInventory::Agent::SOAP::WsMan::EnumerateResponse;
use FusionInventory::Agent::SOAP::WsMan::PullResponse;

sub support {
    return {
        IdentifyResponse    => "wsmid:IdentifyResponse",
        Fault               => "s:Fault",
        EnumerateResponse   => "n:EnumerateResponse",
        PullResponse        => "n:PullResponse",
    };
}

sub fault {
    my ($self) = @_;

    my ($fault) = $self->get('Fault');

    return $fault // Fault->new();
}

sub enumeration {
    my ($self, $ispull) = @_;

    my ($enum) = $self->get($ispull ? 'PullResponse' : 'EnumerateResponse');

    return $enum // EnumerateResponse->new();
}

1;
