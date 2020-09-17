package FusionInventory::Agent::SOAP::WsMan::Enumerate;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Enumerate;

use parent 'Node';

use FusionInventory::Agent::SOAP::WsMan::OptimizeEnumeration;
use FusionInventory::Agent::SOAP::WsMan::MaxElements;

use constant    xmlns   => 'n';

sub new {
    my ($class, @params) = @_;

    my $self = $class->SUPER::new(@params);

    bless $self, $class;

    $self->push(
        OptimizeEnumeration->new(),
        MaxElements->new(32000),
    )
        unless @params;

    return $self;
}

1;
