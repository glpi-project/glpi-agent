package GLPI::Agent::SOAP::WsMan::SequenceId;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    SequenceId;

use parent
    'Node';

use constant    xmlns   => 'p';

use GLPI::Agent::SOAP::WsMan::Attribute;

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new(
        Attribute->must_understand("false"),
        1,
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
