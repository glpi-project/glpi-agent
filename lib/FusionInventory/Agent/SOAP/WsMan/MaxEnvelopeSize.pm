package FusionInventory::Agent::SOAP::WsMan::MaxEnvelopeSize;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    MaxEnvelopeSize;

use parent 'Node';

use constant    xmlns   => 'w';

use FusionInventory::Agent::SOAP::WsMan::Attribute;

sub new {
    my ($class, $size) = @_;

    my @nodes = (
        Attribute->must_understand(),
        '#text' => $size,
    );

    my $self = $class->SUPER::new(@nodes);

    bless $self, $class;
    return $self;
}

1;
