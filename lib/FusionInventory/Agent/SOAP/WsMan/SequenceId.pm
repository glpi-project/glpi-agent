package FusionInventory::Agent::SOAP::WsMan::SequenceId;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    SequenceId;

use parent 'Node';

use English qw(-no_match_vars);
use UNIVERSAL::require;

use constant    xmlns   => 'p';

use FusionInventory::Agent::SOAP::WsMan::Attribute;

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new(
        Attribute->must_understand("false"),
        '#text' => 1,
    );

    $self->{_index} = 1;

    bless $self, $class;
    return $self;
}

sub index {
    my ($self) = @_;

    return $self->{_index};
}

1;
