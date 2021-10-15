package GLPI::Agent::SOAP::WsMan::Address;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Address;

use parent
    'Node';

use constant    xmlns   => 'a';

use GLPI::Agent::SOAP::WsMan::Attribute;

sub new {
    my ($class, $url) = @_;

    my $self = $class->SUPER::new(
        Attribute->must_understand(),
        $url,
    );

    bless $self, $class;
    return $self;
}

sub anonymous {
    my ($class) = @_;

    return $class->new("http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous");
}

1;
