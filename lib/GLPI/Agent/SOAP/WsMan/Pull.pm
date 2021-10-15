package GLPI::Agent::SOAP::WsMan::Pull;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Pull;

use parent
    'Node';

use GLPI::Agent::SOAP::WsMan::MaxElements;

use constant    xmlns   => 'n';

sub new {
    my ($class, @params) = @_;

    my $self = $class->SUPER::new(@params);

    bless $self, $class;

    $self->push( MaxElements->new(32000, 'for_pull') )
        unless grep { ref($_) eq 'MaxElements' } @params;

    return $self;
}

1;
