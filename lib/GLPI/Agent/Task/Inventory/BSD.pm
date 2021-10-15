package GLPI::Agent::Task::Inventory::BSD;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

our $runAfter = ["GLPI::Agent::Task::Inventory::Generic"];

sub isEnabled {
    return OSNAME =~ /freebsd|openbsd|netbsd|gnukfreebsd|gnuknetbsd|dragonfly/;
}

sub doInventory {}

1;
