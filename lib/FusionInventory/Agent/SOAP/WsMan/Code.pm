package FusionInventory::Agent::SOAP::WsMan::Code;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Code;

use parent 'Node';

use constant    xmlns   => 's';

sub support {
    return {
        Value   => "s:Value",
    };
}

1;
