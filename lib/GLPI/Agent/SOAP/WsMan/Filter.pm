package GLPI::Agent::SOAP::WsMan::Filter;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Filter;

use parent
    'Node';

use constant    xmlns   => 'w';

use GLPI::Agent::SOAP::WsMan::Attribute;

sub new {
    my ($class, $query) = @_;

    my $self = $class->SUPER::new(
        Attribute->new(
            Dialect => "http://schemas.microsoft.com/wbem/wsman/1/WQL"
        ),
        $query
    );

    bless $self, $class;
    return $self;
}

1;
