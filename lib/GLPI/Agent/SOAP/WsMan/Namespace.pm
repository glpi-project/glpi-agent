package GLPI::Agent::SOAP::WsMan::Namespace;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Namespace;

use parent
    'Node';

use GLPI::Agent::SOAP::WsMan::Attribute;

my %ns = qw(
    s       http://www.w3.org/2003/05/soap-envelope
    a       http://schemas.xmlsoap.org/ws/2004/08/addressing
    n       http://schemas.xmlsoap.org/ws/2004/09/enumeration
    w       http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd
    p       http://schemas.microsoft.com/wbem/wsman/1/wsman.xsd
    b       http://schemas.dmtf.org/wbem/wsman/1/cimbinding.xsd
    wsmid   http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd
);

sub new {
    my ($class, @namespaces) = @_;

    my $self;

    my %attributes;

    while (@namespaces) {
        my $ns = shift @namespaces;
        if ($ns{$ns}) {
            $attributes{"xmlns:$ns"} = $ns{$ns};
        } else {
            $attributes{"xmlns:$ns"} = shift @namespaces;
        }
    }

    $self = $class->SUPER::new(Attribute->new(%attributes));

    bless $self, $class;

    return $self;
}

1;
