package FusionInventory::Agent::SOAP::WsMan::Selector;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Selector;

use parent 'Node';

use constant    xmlns   => 'w';

use FusionInventory::Agent::SOAP::WsMan::Attribute;

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new(
        Attribute->new(Name => "__cimnamespace"),
        '#text' => "Win32_ComputerSystem",
    );

    bless $self, $class;
    return $self;
}

1;
