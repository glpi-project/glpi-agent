#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::Generic::Dmidecode::Hardware;

my %tests = (
    'freebsd-6.2' => {
        UUID     => undef,
        CHASSIS_TYPE => 'Desktop'
    },
    'freebsd-8.1' => {
        UUID => '30464E43-3231-3730-5836-C80AA93F35FA',
        CHASSIS_TYPE => 'Notebook'
    },
    'linux-1' => {
        UUID => '40EB001E-8C00-01CE-8E2C-00248C590A84',
        CHASSIS_TYPE => 'Desktop'
    },
    'linux-2.6' => {
        UUID     => '44454C4C-3800-1058-8044-C4C04F36324A',
        CHASSIS_TYPE => 'Portable'
    },
    'openbsd-3.7' => {
        UUID         => undef,
        CHASSIS_TYPE => undef,
    },
    'openbsd-3.8' => {
        UUID         => '44454C4C-4B00-1031-8030-B2C04F31324A',
        CHASSIS_TYPE => 'Main Server Chassis'
    },
    'openbsd-4.5' => {
        UUID          => '44454C4C-5600-1032-8056-B4C04F57304A',
        CHASSIS_TYPE  => 'Mini Tower'
    },
    'rhel-2.1' => {
        UUID         => undef,
        CHASSIS_TYPE => undef
    },
    'rhel-3.4' => {
        UUID     => 'A8346631-8E88-3AE3-898C-F3AC9F61C316',
        CHASSIS_TYPE => 'Tower'
    },
    'rhel-3.9' => {
        UUID     => 'AE698CFC-492A-4C7B-848F-8C17D24BC76E',
        CHASSIS_TYPE => undef
    },
    'rhel-4.3' => {
        UUID => '0339D4C3-44C0-9D11-A20E-85CDC42DE79C',
        CHASSIS_TYPE => 'Tower'
    },
    'rhel-4.6' => {
        UUID => '34313236-3435-4742-3838-313448453753',
        CHASSIS_TYPE => 'Tower'
    },
    'hp-dl180' => {
        UUID          => '00D3F681-FE8E-11D5-B656-1CC1DE0905AE',
        CHASSIS_TYPE  => 'Rack Mount Chassis'
    },
    'oracle-server-x5-2' => {
        UUID          => '080020FF-FFFF-FFFF-FFFF-0010E0BCCBBC',
        CHASSIS_TYPE  => 'Main Server Chassis'
    },
    'S3000AHLX' => {
        UUID          => 'D7AFF990-4871-11DB-A6C6-0007E994F7C3',
        CHASSIS_TYPE  => 'Desktop'
    },
    'S5000VSA' => {
        UUID          => 'CCF82081-7966-11DB-BDB3-00151716FBAC',
        CHASSIS_TYPE  => 'Rack Mount Chassis'
    },
    'vmware' => {
        UUID          => '500C2394-0127-D13C-0CC4-F537A6AAF1A6',
        CHASSIS_TYPE  => 'Other'
    },
    'vmware-esx' => {
        UUID          => '4230BF6A-CE71-E168-6C2D-176E66D04A0D',
        CHASSIS_TYPE  => 'Other'
    },
    'vmware-esx-2.5' => {
        UUID          => undef,
        CHASSIS_TYPE  => undef
    },
    'windows' => {
        UUID     => '7FB4EA00-07CB-18F3-8041-CAD582735244',
        CHASSIS_TYPE  => 'Notebook'
    },
    'hp-proLiant-DL120-G6' => {
        CHASSIS_TYPE  => 'Rack Mount Chassis',
        UUID          => 'EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE'
    },
    'windows-hyperV' => {
        CHASSIS_TYPE  => 'Desktop',
        UUID          => '3445DEE7-45D0-1244-95DD-34FAA067C1BE33E',
    },
    'windows-hyperV-2019' => {
        CHASSIS_TYPE  => 'Desktop',
        UUID          => 'f78a0579-5bf5-4de9-a5c7-b5ad2023449b',
    },
    'dell-fx160' => {
        CHASSIS_TYPE  => 'Desktop',
        UUID          => '44454C4C-3800-1033-8054-C3C04F35344A'
    },
    'dell-fx170' => {
        CHASSIS_TYPE  => 'Desktop',
        UUID          => '000C7406-053F-1710-8E47-E3AE95ED8CF9'
    },
    'lenovo-thinkpad' => {
        CHASSIS_TYPE  => 'Notebook',
        UUID          => '725BA801-507B-11CB-95E6-C66052AAC597'
    },
    'surface-go-2' => {
        CHASSIS_TYPE  => 'Laptop',
        UUID          => '0e985de7-da00-4662-a18c-a957308c3ad7'
    }
);

plan tests => keys(%tests) + 1;

foreach my $test (keys %tests) {
    my $file = "resources/generic/dmidecode/$test";
    my $hardware = GLPI::Agent::Task::Inventory::Generic::Dmidecode::Hardware::_getHardware(file => $file);
    cmp_deeply($hardware, $tests{$test}, "hardware: $test");
}
