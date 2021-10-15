package GLPI::Agent::SOAP::WsMan::ReferenceParameters;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    ReferenceParameters;

use parent
    'Node';

use constant xmlns  => 'a';

sub support {
    return {
        ResourceURI => "w:ResourceURI",
        SelectorSet => "w:SelectorSet",
    };
}

1;
