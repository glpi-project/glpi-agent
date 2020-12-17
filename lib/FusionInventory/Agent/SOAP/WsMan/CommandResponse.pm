package FusionInventory::Agent::SOAP::WsMan::CommandResponse;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    CommandResponse;

use parent 'Node';

use FusionInventory::Agent::SOAP::WsMan::CommandId;

use constant    xmlns   => 'rsp';

sub support {
    return {
        CommandId   => "rsp:CommandId",
    };
}

1;
