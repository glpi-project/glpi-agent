package GLPI::Agent::SOAP::WsMan::PullResponse;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::EnumerateResponse;

## no critic (ProhibitMultiplePackages)
package
    PullResponse;

use parent
    'EnumerateResponse';

sub support {
    return {
        EnumerationContext  => "n:EnumerationContext",
        Items               => "n:Items",
        EndOfSequence       => "n:EndOfSequence",
    };
}

1;
