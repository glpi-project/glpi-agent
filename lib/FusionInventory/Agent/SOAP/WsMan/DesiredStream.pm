package FusionInventory::Agent::SOAP::WsMan::DesiredStream;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    DesiredStream;

use parent 'Node';

use FusionInventory::Agent::SOAP::WsMan::Attribute;

use constant    xmlns   => 'rsp';

sub new {
    my ($class, $cid) = @_;

    my $self = $class->SUPER::new(
        Attribute->new( CommandId => $cid ),
        "stdout stderr",
    );

    bless $self, $class;

    return $self;
}

1;
