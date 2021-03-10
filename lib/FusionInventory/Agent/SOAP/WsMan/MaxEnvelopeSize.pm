package FusionInventory::Agent::SOAP::WsMan::MaxEnvelopeSize;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    MaxEnvelopeSize;

use parent 'Node';

use constant    xmlns   => 'w';

use FusionInventory::Agent::SOAP::WsMan::Attribute;

sub new {
    my ($class, $size) = @_;

    my $self = $class->SUPER::new(
        Attribute->must_understand(),
        $size,
    );

    bless $self, $class;
    return $self;
}

1;
