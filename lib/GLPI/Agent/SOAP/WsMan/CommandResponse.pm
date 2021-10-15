package GLPI::Agent::SOAP::WsMan::CommandResponse;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    CommandResponse;

use parent
    'Node';

use constant    xmlns   => 'rsp';

sub support {
    return {
        CommandId   => "rsp:CommandId",
    };
}

1;
