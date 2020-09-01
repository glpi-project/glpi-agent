package FusionInventory::Agent::SOAP::WsMan::Value;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Value;

use parent 'Node';

sub get {
    my ($self, $object) = @_;

    if ($object) {
        my $supported = $self->support;

        return unless $supported->{$object};

        return $self->SUPER::get($object);
    }

    return "s:Value" => $self->SUPER::get();
}

sub support {
    return {};
}

1;
