package GLPI::Agent::SOAP::WsMan::ResourceCreated;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    ResourceCreated;

use parent
    'Node';

use constant xmlns  => 'x';

sub support {
    return {
        ReferenceParameters => "a:ReferenceParameters",
    };
}

1;
