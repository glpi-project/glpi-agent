package GLPI::Agent::SOAP::WsMan::Command;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Command;

use parent
    'Node';

use constant    xmlns   => 'rsp';

1;
