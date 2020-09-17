package FusionInventory::Agent::SOAP::WsMan::OperationTimeout;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    OperationTimeout;

use parent 'Node';

use English qw(-no_match_vars);
use UNIVERSAL::require;

use constant    xmlns   => 'w';

sub new {
    my ($class, $timeout) = @_;

    my $self = $class->SUPER::new('#text' => sprintf("PT%.3fS", $timeout));

    bless $self, $class;
    return $self;
}

1;
