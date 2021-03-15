package FusionInventory::Agent::SOAP::WsMan::SelectorSet;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    SelectorSet;

use parent 'Node';

use FusionInventory::Agent::SOAP::WsMan::Selector;

use constant    xmlns   => 'w';

sub support {
    return {
        Selector    => "w:Selector",
    };
}

sub new {
    my ($class, @where) = @_;

    my @conditions = @where && ref($where[0]) eq 'ARRAY' ?
        map { Selector->new($_) } @{$where[0]} : @where;

    my $self = $class->SUPER::new(@conditions);

    bless $self, $class;
    return $self;
}

1;
