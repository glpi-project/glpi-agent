package GLPI::Agent::SOAP::WsMan::EnumerationContext;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    EnumerationContext;

use parent
    'Node';

use constant    xmlns   => 'n';
use constant    xsd     => "http://schemas.xmlsoap.org/ws/2004/09/enumeration";

1;
