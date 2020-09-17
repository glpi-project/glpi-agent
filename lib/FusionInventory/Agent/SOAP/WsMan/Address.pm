package FusionInventory::Agent::SOAP::WsMan::Address;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Address;

use parent 'Node';

use constant    xmlns   => 'a';

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

sub anonymous {
    my ($class) = @_;

    return $class->new("http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous");
}

1;
