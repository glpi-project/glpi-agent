package FusionInventory::Agent::SOAP::WsMan::InputStreams;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    InputStreams;

use parent 'Node';

use constant    xmlns   => 'rsp';

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new('#text' => "stdin");

    bless $self, $class;

    return $self;
}

1;
