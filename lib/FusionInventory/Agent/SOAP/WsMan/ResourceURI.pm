package FusionInventory::Agent::SOAP::WsMan::ResourceURI;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    ResourceURI;

use parent 'Node';

use constant    xmlns   => 'w';

use FusionInventory::Agent::SOAP::WsMan::Attribute;

sub new {
    my ($class, $url) = @_;

    my @nodes = (
        Attribute->must_understand(),
        '#text' => $url,
    );

    my $self = $class->SUPER::new(@nodes);

    bless $self, $class;
    return $self;
}

1;
