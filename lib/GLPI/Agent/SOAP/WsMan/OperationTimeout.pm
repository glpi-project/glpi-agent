package GLPI::Agent::SOAP::WsMan::OperationTimeout;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    OperationTimeout;

use parent
    'Node';

use constant    xmlns   => 'w';

sub new {
    my ($class, $timeout) = @_;

    my $self = $class->SUPER::new(sprintf("PT%.3fS", $timeout));

    bless $self, $class;
    return $self;
}

1;
