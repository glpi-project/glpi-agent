package FusionInventory::Agent::SOAP::WsMan::Receive;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Receive;

use parent 'Node';

use FusionInventory::Agent::SOAP::WsMan::Attribute;
use FusionInventory::Agent::SOAP::WsMan::Shell;
use FusionInventory::Agent::SOAP::WsMan::DesiredStream;

use constant    xmlns   => 'rsp';

sub new {
    my ($class, $cid) = @_;

    my $self = $class->SUPER::new(
        Attribute->new( "xmlns:".Shell->xmlns => Shell->xsd ),
        Attribute->new( SequenceId => 0 ),
        DesiredStream->new($cid),
    );

    bless $self, $class;

    return $self;
}

1;
