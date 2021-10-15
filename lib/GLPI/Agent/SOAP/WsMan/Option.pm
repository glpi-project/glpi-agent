package GLPI::Agent::SOAP::WsMan::Option;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Option;

use parent
    'Node';

use constant    xmlns   => 'w';

use GLPI::Agent::SOAP::WsMan::Attribute;

sub new {
    my ($class, $name, $text) = @_;

    my $self = $class->SUPER::new(
        Attribute->new("Name" => $name),
        $text,
    );

    bless $self, $class;
    return $self;
}

1;
