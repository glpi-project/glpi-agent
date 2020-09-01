package FusionInventory::Agent::SOAP::WsMan::Reason;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Reason;

use parent 'Node';

sub get {
    my ($self, $object) = @_;

    if ($object) {
        my $supported = $self->support;

        return unless $supported->{$object};

        return $self->SUPER::get($object);
    }

    return "s:Reason" => $self->SUPER::get();
}

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
