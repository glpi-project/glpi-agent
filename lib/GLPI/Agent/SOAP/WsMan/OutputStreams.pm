package GLPI::Agent::SOAP::WsMan::OutputStreams;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    OutputStreams;

use parent
    'Node';

use constant    xmlns   => 'rsp';

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new("stdout stderr");

    bless $self, $class;

    return $self;
}

1;
