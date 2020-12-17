package FusionInventory::Agent::SOAP::WsMan::ReceiveResponse;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    ReceiveResponse;

use parent 'Node';

use FusionInventory::Agent::SOAP::WsMan::Stream;
use FusionInventory::Agent::SOAP::WsMan::CommandState;

use constant    xmlns   => 'rsp';

sub support {
    return {
        Stream          => "rsp:Stream",
        CommandState    => "rsp:CommandState",
    };
}

1;
