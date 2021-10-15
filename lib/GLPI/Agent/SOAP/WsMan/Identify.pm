package GLPI::Agent::SOAP::WsMan::Identify;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Identify;

use parent
    'Node';

# Constants needed in parent class
use constant    xmlns   => 'wsmid';
use constant    xsd     => "http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd";

sub request {
    return xmlns.":Identify" => "";
}

1;
