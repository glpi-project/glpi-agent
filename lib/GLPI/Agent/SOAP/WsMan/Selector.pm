package GLPI::Agent::SOAP::WsMan::Selector;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Selector;

use parent
    'Node';

use GLPI::Agent::SOAP::WsMan::Selector;

use constant    xmlns   => 'w';

sub new {
    my ($class, @condition) = @_;

    @condition =( Attribute->new("Name" => $1), $2 )
        if @condition == 1 && $condition[0] =~ /^(\w+)=(\w+)$/;

    my $self = $class->SUPER::new(@condition);

    bless $self, $class;
    return $self;
}

1;
