package GLPI::Agent::Task::Inventory::Module;

use strict;
use warnings;

our $runAfter                 = [];
our $runAfterIfEnabled        = [];
our $runMeIfTheseChecksFailed = [];

use constant    category    => "";

sub isEnabled {
    return 0;
}

sub doInventory {
}

1;

__END__

=head1 NAME

GLPI::Agent::Task::Inventory::Module - Inventory task module for GLPI

=head1 DESCRIPTION

This module is the base class for all inventory task modules.

=head1 MODULE CONFIGURATION PARAMETERS

=head2 $runAfter = []

Array ref of module string list.

List of modules to always be run before this one. If any module of this list is
disabled, the module won't be run: this is a hard dependency.

Example: see GLPI::Agent::Task::Inventory::Linux module

=head2 $runAfterIfEnabled = []

Array ref of module string list.

List of enabled modules to be run before this one: this is a soft dependency.

Example: see GLPI::Agent::Task::Inventory::Generic::Dmidecode::Memory module

=head2 $runMeIfTheseChecksFailed = []

Array ref of module string list.

If a module in that list is enabled, this one will be disabled.

Example: see GLPI::Agent::Task::Inventory::Win32::Bios module

=head1 FUNCTIONS

=head2 isEnabled (%params)

Provided parameters:
    datadir    : resources folder
    logger     : agent logger
    registry   : registry option passed by server
    scan_homedirs: scan-homedirs configuration parameter
    scan_profiles: scan-profiles configuration parameter

Returns true is the module should be used for local inventory.

=head2 doInventory (%params)

Provided parameters:
    inventory  : inventory object to populate with dedicated API
    no_category: ref to hash indexed from no_category parameter
    datadir    : resources folder
    logger     : agent logger
    registry   : registry option passed by server
    scan_homedirs: scan-homedirs configuration parameter
    scan_profiles: scan-profiles configuration parameter

Updates passed inventory with found inventory values.
