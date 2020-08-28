package FusionInventory::Agent::SOAP::WsMan::Body;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Body;

use parent 'Node';

sub get {
    my ($self, $object) = @_;

    if ($object) {
        my $supported = $self->support;

        return unless $supported->{$object};

        return $self->SUPER::get($object);
    }

    return "s:Body" => $self->SUPER::get();
}

sub support {
    return {
        Identify    => "wsmid:IdentifyResponse",
    };
}

1;
