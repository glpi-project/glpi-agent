package GLPI::Agent::Task::Inventory::Linux::Bios;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;

use constant    category    => "bios";

# Only run this module if dmidecode has not been found
our $runMeIfTheseChecksFailed =
    ["GLPI::Agent::Task::Inventory::Generic::Dmidecode::Bios"];

sub isEnabled {
    return has_folder('/sys/class/dmi/id');
}

sub _dmi_info {
    my ($info) = @_;
    my $class = '/sys/class/dmi/id/'.$info;
    return if has_folder($class);
    return unless canRead($class);
    return getFirstLine(file => $class);
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $bios = {};

    my %bios_map = qw(
        BMANUFACTURER   bios_vendor
        BDATE           bios_date
        BVERSION        bios_version
        ASSETTAG        chassis_asset_tag
        SMODEL          product_name
        SMANUFACTURER   sys_vendor
        SSN             product_serial
        MMODEL          board_name
        MMANUFACTURER   board_vendor
        MSN             board_serial
    );

    foreach my $key (keys(%bios_map)) {
        my $value = _dmi_info($bios_map{$key});
        next unless defined($value);
        next if isInvalidBiosValue($value);
        $bios->{$key} = $value;
    }

    # Fix issue #311: 'product_version' is a better 'SMODEL' for Lenovo systems
    my $system_version = _dmi_info('product_version');
    if ($system_version && $bios->{'SMANUFACTURER'} &&
            $bios->{'SMANUFACTURER'} =~ /^LENOVO$/i &&
            $system_version =~ /^(Think|Idea|Yoga|Netfinity|Netvista|Intelli)/i)
    {
        $bios->{'SMODEL'} = $system_version;
    }

    # Set Virtualbox VM S/N to UUID if found serial is '0'
    my $uuid = _dmi_info('product_uuid');
    if ($uuid && $bios->{MMODEL} && $bios->{MMODEL} eq "VirtualBox" &&
            $bios->{SSN} eq "0" && $bios->{MSN} eq "0")
    {
        $bios->{SSN} = $uuid;
    }

    $inventory->setBios($bios);
}

1;
