package GLPI::Agent::SOAP::WsMan::To;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    To;

use parent
    'Node';

use constant    xmlns   => 'a';
use constant    xsd     => "http://schemas.xmlsoap.org/ws/2004/08/addressing";

sub anonymous {
    my ($class) = @_;

    return $class->new("http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous");
}

1;
