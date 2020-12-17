package FusionInventory::Agent::SOAP::WsMan::SelectorSet;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    SelectorSet;

use parent 'Node';

use constant    xmlns   => 'w';

sub support {
    return {
        Selector    => "w:Selector",
    };
}

1;
