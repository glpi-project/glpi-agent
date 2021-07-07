#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;
use Test::NoWarnings;

use FusionInventory::Agent::Tools::Solaris;
use FusionInventory::Agent::Task::Inventory::Solaris::Bios;

my %showrev_tests = (
    'SPARC-1' => {
        'Release' => '5.10',
        'Hostname' => '157501s021plc',
        'Kernel version' => 'SunOS',
        'Kernel architecture' => 'sun4u',
        'Hardware provider' => 'Sun_Microsystem',
        'Domain' => 'be.cnamts.fr',
        'Application architecture' => 'sparc',
        'Hostid' => '83249bbf',
    },
    'SPARC-2' => {
        'Kernel version' => 'SunOS',
        'Release' => '5.10',
        'Hostname' => 'mysunserver',
        'Hardware provider' => 'Sun_Microsystems',
        'Kernel architecture' => 'sun4v',
        'Application architecture' => 'sparc',
        'Hostid' => 'mabox'
    },
    'x86-1' => {
        'Kernel version' => 'SunOS',
        'Hostname' => 'stlaurent',
        'Kernel architecture' => 'i86pc',
        'Application architecture' => 'i386',
        'Hostid' => '403100b',
        'Release' => '5.10',
    },
    'x86-2' => {
        'Kernel version' => 'SunOS',
        'Release' => '5.10',
        'Hostname' => 'mamachine',
        'Kernel architecture' => 'i86pc',
        'Application architecture' => 'i386',
        'Hostid' => '7c31a88'
    },
    'x86-3' => {
        'Kernel version' => 'SunOS',
        'Release' => '5.10',
        'Hostname' => 'plop',
        'Kernel architecture' => 'i86pc',
        'Application architecture' => 'i386',
        'Hostid' => '7c31a36'
    }
);

my %smbios_tests = (
    'x86-1' => {
        'SMB_TYPE_SYSTEM' => {
            'Version' => '00',
            'SKU Number' => ' ',
            'Serial Number' => 'R00T34E0009',
            'Product' => 'Sun Fire V40z',
            'Manufacturer' => 'Sun Microsystems, Inc.',
            'UUID' => 'be1630df-d130-41a4-be32-fd28bb4bd1ac',
            'Wake-Up Event' => '0x6 (power switch)'
        }
    },
    'x86-3' => {
        SMB_TYPE_CHASSIS => {
            'Chassis Height' => '1u',
            'Power Supply State' => '0x3 (safe)',
            'Element Records' => '0',
            'Serial Number' => 'QSDH1234567',
            'Thermal State' => '0x3 (safe)',
            'Lock Present' => 'N',
            'Asset Tag' => '6I012345TF',
            'Chassis Type' => '0x17 (rack mount chassis)',
            'Power Cords' => '1',
            'Version' => 'E10476-011',
            'OEM Data' => '0x81581cf8',
            'Boot-Up State' => '0x3 (safe)',
            'Manufacturer' => 'TRANSTEC'
        },
        SMB_TYPE_BIOS => {
            'Characteristics' => '0x15c099a80',
            'Version Number' => '0.0',
            'Vendor' => 'Intel Corporation',
            'Image Size' => '98304 bytes',
            'Characteristics Extension Byte 2' => '0x7',
            'Characteristics Extension Byte 1' => '0x33',
            'Address Segment' => '0xe800',
            'Version String' => 'SFC4UR.86B.01.00.0029.071220092126',
            'Embedded Ctlr Firmware Version Number' => '0.0',
            'Release Date' => '07/12/2009',
            'ROM Size' => '8388608 bytes'
        },
        SMB_TYPE_IPMIDEV => {
            'Flags' => '0x9',
            'NV Storage Device Bus ID' => '0xffffffff',
            'BMC IPMI Version' => '2.0',
            'Register Spacing' => '1',
            'Interrupt Number' => '0',
            'Type' => '1 (KCS: Keyboard Controller Style)',
            'i2c Bus Slave Address' => '0x20',
            'BMC Base Address' => '0xca2'
        },
        SMB_TYPE_BASEBOARD => {
            'Board Type' => '0xa (motherboard)',
            'Flags' => '0x9',
            'Serial Number' => 'QSFX12345678',
            'Product' => 'S7000FC4UR',
            'Manufacturer' => 'Intel',
            'Chassis' => '0',
            'Asset Tag' => '6I012345TF'
        },
        SMB_TYPE_SYSTEM => {
            'Family' => ' ',
            'SKU Number' => '6I012345TF',
            'Product' => 'MP Server',
            'Manufacturer' => 'Intel',
            'UUID' => '4b713db6-6d40-11dd-b32c-000123456789',
            'Wake-Up Event' => '0x6 (power switch)'
        }
    }
);

plan tests =>
    (scalar keys %showrev_tests) +
    (scalar keys %smbios_tests)  +
    1;

foreach my $test (keys %showrev_tests) {
    my $file   = "resources/solaris/showrev/$test";
    my $result = FusionInventory::Agent::Task::Inventory::Solaris::Bios::_parseShowRev(file => $file);
    cmp_deeply($result, $showrev_tests{$test}, "showrev parsing: $test");
}

foreach my $test (keys %smbios_tests) {
    my $file   = "resources/solaris/smbios/$test";
    my $result = FusionInventory::Agent::Tools::Solaris::getSmbios(file => $file);
    cmp_deeply($result, $smbios_tests{$test}, "smbios parsing: $test");
}
