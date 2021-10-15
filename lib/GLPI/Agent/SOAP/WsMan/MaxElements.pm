package GLPI::Agent::SOAP::WsMan::MaxElements;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    MaxElements;

use parent
    'Node';

sub new {
    my ($class, $max, $for_pull) = @_;

    my $self = $class->SUPER::new($max || 32000);

    $self->{_for_pull} = $for_pull;

    bless $self, $class;
    return $self;
}

sub xmlns {
    my ($self) = @_;
    return $self->{_for_pull} ? 'n' : 'w';
}

1;
