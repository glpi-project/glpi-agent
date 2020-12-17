package FusionInventory::Agent::SOAP::WsMan::ReplyTo;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    ReplyTo;

use parent 'Node';

use constant    xmlns   => 'a';

use FusionInventory::Agent::SOAP::WsMan::Address;

sub anonymous {
    my ($class) = @_;

    return $class->new(Address->anonymous);
}

1;
