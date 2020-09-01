package FusionInventory::Agent::SOAP::WsMan::Fault;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Fault;

use parent 'Node';

sub get {
    my ($self, $object) = @_;

    if ($object) {
        my $supported = $self->support;

        return unless $supported->{$object};

        return $self->SUPER::get($object);
    }

    return "s:Fault" => $self->SUPER::get();
}

sub support {
    return {
        Reason  => "s:Reason",
        Code    => "s:Code",
    };
}

sub reason {
    my ($self) = @_;

    my ($reason) = $self->get('Reason');

    return $reason // Reason->new();
}

1;
