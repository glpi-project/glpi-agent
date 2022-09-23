package GLPI::Agent::Task::Inventory::Linux::Hardware;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use UNIVERSAL::require;

use GLPI::Agent::Tools;

use constant    category    => "hardware";

our $runAfterIfEnabled = ["GLPI::Agent::Task::Inventory::Generic::Dmidecode::Hardware"];

# Follow dmidecode dmi_chassis_type() API:
# See https://github.com/mirror/dmidecode/blob/master/dmidecode.c#L593
my $chassis_types = [
    "",
    "Other",
    "Unknown",
    "Desktop",
    "Low Profile Desktop",
    "Pizza Box",
    "Mini Tower",
    "Tower",
    "Portable",
    "Laptop",
    "Notebook",
    "Hand Held",
    "Docking Station",
    "All in One",
    "Sub Notebook",
    "Space-Saving",
    "Lunch Box",
    "Main Server Chassis",
    "Expansion Chassis",
    "Sub Chassis",
    "Bus Expansion Chassis",
    "Peripheral Chassis",
    "RAID Chassis",
    "Rack Mount Chassis",
    "Sealed-case PC",
    "Multi-system",
    "CompactPCI",
    "AdvancedTCA",
    "Blade",
    "Blade Enclosing",
    "Tablet",
    "Convertible",
    "Detachable",
    "IoT Gateway",
    "Embedded PC",
    "Mini PC",
    "Stick PC",
];

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $hardware = {};

    my $systemId = _getRHNSystemId('/etc/sysconfig/rhn/systemid');
    $hardware->{WINPRODID} = $systemId if $systemId;

    my $uuid = _dmi_info('product_uuid');
    $hardware->{UUID} = $uuid if $uuid;

    my $chassis_type = _dmi_info('chassis_type');
    $hardware->{CHASSIS_TYPE} = $chassis_types->[$chassis_type]
        if $chassis_type && $chassis_types->[$chassis_type];

    $inventory->setHardware($hardware) if keys(%{$hardware});
}

# Get RedHat Network SystemId
sub _getRHNSystemId {
    my ($file) = @_;

    return unless has_file($file);
    return unless GLPI::Agent::XML->require();
    my $xml = GLPI::Agent::XML->new(file => $file)
        or return;
    my $h = $xml->dump_as_hash();
    foreach (@{$h->{params}{param}{value}{struct}{member}}) {
        next unless $_->{name} eq 'system_id';
        return $_->{value}{string};
    }
}

sub _dmi_info {
    my ($info) = @_;
    my $class = '/sys/class/dmi/id/'.$info;
    return if has_folder($class);
    return unless has_file($class);
    return getFirstLine(file => $class);
}

1;
