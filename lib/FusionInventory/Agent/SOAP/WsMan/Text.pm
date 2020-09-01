package FusionInventory::Agent::SOAP::WsMan::Text;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Text;

use parent 'Node';

sub get {
    my ($self, $object) = @_;

    if ($object) {
        my $supported = $self->support;

        return unless $supported->{$object};

        return $self->SUPER::get($object);
    }

    return "s:Text" => $self->SUPER::get();
}

sub string {
    my ($self) = @_;

    return '' unless $self->{_hash};

    return $self->{_hash}->{'#text'} // '';
}

sub support {}

1;
