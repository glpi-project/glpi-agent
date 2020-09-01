package FusionInventory::Agent::SOAP::WsMan::Code;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Code;

use parent 'Node';

sub get {
    my ($self, $object) = @_;

    if ($object) {
        my $supported = $self->support;

        return unless $supported->{$object};

        return $self->SUPER::get($object);
    }

    return "s:Code" => $self->SUPER::get();
}

sub support {
    return {
        Value   => "s:Value",
    };
}

1;
