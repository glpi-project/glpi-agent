package GLPI::Agent::SOAP::WsMan::InputStreams;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    InputStreams;

use parent
    'Node';

use constant    xmlns   => 'rsp';

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new("stdin");

    bless $self, $class;

    return $self;
}

1;
