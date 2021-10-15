package GLPI::Agent::Task::Inventory::Generic::Dmidecode::Bios;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;

use constant    category    => "bios";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $bios = _getBios(logger => $logger);

    $inventory->setBios($bios);
}

sub _getBios {
    my $infos = getDmidecodeInfos(@_);

    my $bios_info    = $infos->{0}->[0];
    my $system_info  = $infos->{1}->[0];
    my $base_info    = $infos->{2}->[0];
    my $chassis_info = $infos->{3}->[0];

    my $bios = {
        BMANUFACTURER => $bios_info->{'Vendor'},
        BDATE         => $bios_info->{'Release Date'},
        BVERSION      => $bios_info->{'Version'},
        ASSETTAG      => $chassis_info->{'Asset Tag'}
    };

    # Fix issue #311: system_info 'Version' is a better 'Product Name' for Lenovo systems
    if ($system_info->{'Version'} && $system_info->{'Manufacturer'} &&
            $system_info->{'Manufacturer'} =~ /^LENOVO$/i &&
            $system_info->{'Version'} =~ /^(Think|Idea|Yoga|Netfinity|Netvista|Intelli)/i) {
        my $product_name = $system_info->{'Version'};
        $system_info->{'Version'}      = $system_info->{'Product Name'};
        $system_info->{'Product Name'} = $product_name;
    }

    $bios->{SMODEL} =
        $system_info->{'Product'}      ||
        $system_info->{'Product Name'};
    $bios->{MMODEL} = $base_info->{'Product Name'};
    $bios->{SKUNUMBER} = $system_info->{'SKU Number'};

    $bios->{SMANUFACTURER} =
        $system_info->{'Manufacturer'} ||
        $system_info->{'Vendor'};
    $bios->{MMANUFACTURER} = $base_info->{'Manufacturer'};

    $bios->{SSN} = $system_info->{'Serial Number'};
    $bios->{SSN} = $chassis_info->{'Serial Number'} if (!defined($bios->{SSN}));
    $bios->{MSN} = $base_info->{'Serial Number'};

    if ($bios->{MMODEL} && $bios->{MMODEL} eq "VirtualBox" &&
        $bios->{SSN} eq "0" &&
        $bios->{MSN} eq "0") {
        $bios->{SSN} = $system_info->{'UUID'}
    }

    return $bios;
}

1;
