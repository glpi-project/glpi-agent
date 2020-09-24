package FusionInventory::Agent::SOAP::WsMan::ResourceCreated;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    ResourceCreated;

use parent 'Node';

use constant xmlns  => 'x';

sub support {
    return {
        ReferenceParameters => "a:ReferenceParameters",
    };
}

1;
