package FusionInventory::Agent::SOAP::WsMan::PullResponse;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::EnumerateResponse;

package
    PullResponse;

use parent 'EnumerateResponse';

sub support {
    return {
        EnumerationContext  => "n:EnumerationContext",
        Items               => "n:Items",
        EndOfSequence       => "n:EndOfSequence",
    };
}

1;
