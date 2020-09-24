package FusionInventory::Agent::SOAP::WsMan::Option;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Option;

use parent 'Node';

use constant    xmlns   => 'w';

use FusionInventory::Agent::SOAP::WsMan::Attribute;

sub new {
    my ($class, $name, $text) = @_;

    my $self = $class->SUPER::new(
        Attribute->new("Name" => $name),
        '#text' => $text,
    );

    bless $self, $class;
    return $self;
}

1;
