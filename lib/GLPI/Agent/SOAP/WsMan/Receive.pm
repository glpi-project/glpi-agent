package GLPI::Agent::SOAP::WsMan::Receive;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Receive;

use parent
    'Node';

use GLPI::Agent::SOAP::WsMan::Attribute;
use GLPI::Agent::SOAP::WsMan::Shell;
use GLPI::Agent::SOAP::WsMan::DesiredStream;

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
