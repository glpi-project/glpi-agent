package GLPI::Agent::Tools::Constants;

use strict;
use warnings;

use parent 'Exporter';

use constant STATUS_ON => 'on';
use constant STATUS_OFF => 'off';

our @EXPORT = qw(
    STATUS_OFF
    STATUS_ON
);

1;
