#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Generic::Dmidecode::Psu;

my %tests = (
    'dell-fx160' => undef,
    'hp-dl180' => [
        {
            PARTNUM        => '511777-001',
            SERIALNUMBER   => '5ANLE0BLLZ225W',
            MANUFACTURER   => 'Hewlett-Packard',
            POWER_MAX      => '460',
            HOTREPLACEABLE => 'No',
            LOCATION       => 'Bottom PS Bay',
            NAME           => 'Power Supply 1',
            PLUGGED        => 'Yes',
            STATUS         => 'Present, <OUT OF SPEC>',
        }
    ],
    'lenovo-thinkpad' => [
        # Type 39 entry is a battery
    ],
    'windows-7' => [
        # 2 powersupplies, but no serial number, no partnum and no name
    ],
    'psu/Dedibox_SC_SATA_2016' => [
        # no serial number, no partnum and no name
    ],
    'psu/Dedibox_XC_SSD_SATA_2016' => [
        # no serial number, no partnum and no name
    ],
    'psu/Dell_DL380p_Gen8_2' => [
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Hewlett-Packard',
            NAME            => 'Power Supply 1',
            PARTNUM         => '503296-B21',
            PLUGGED         => 'Yes',
            POWER_MAX       => '460',
            SERIALNUMBER    => '5ANLD0C4D2T481',
            STATUS          => 'Present, Unknown'
        },
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Hewlett-Packard',
            NAME            => 'Power Supply 2',
            PARTNUM         => '503296-B21',
            PLUGGED         => 'Yes',
            POWER_MAX       => '460',
            SERIALNUMBER    => '5ANLD0C4D2T459',
            STATUS          => 'Present, Unknown'
        }
    ],
    'psu/Dell_DSS_1500' => [
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Dell',
            NAME            => 'PWR SPLY,550W,RDNT,DELTA',
            PARTNUM         => '0X185V',
            PLUGGED         => 'Yes',
            POWER_MAX       => '550',
            SERIALNUMBER    => 'CN1797263T13QD',
            STATUS          => 'Present, Unknown'
        },
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Dell',
            NAME            => 'PWR SPLY,550W,RDNT,DELTA',
            PARTNUM         => '0X185V',
            PLUGGED         => 'Yes',
            POWER_MAX       => '550',
            SERIALNUMBER    => 'CN1797263T13QE',
            STATUS          => 'Present, Unknown'
        }
    ],
    'psu/Dell_Latitude_3550' => [
        # no serial number, no partnum and no name
    ],
    'psu/Dell_PowerEdge_R330' => [
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Dell',
            NAME            => 'PWR SPLY,350W,RDNT,LTON',
            PARTNUM         => '09WR03',
            PLUGGED         => 'Yes',
            POWER_MAX       => '350',
            SERIALNUMBER    => 'CN7161561F0D94',
            STATUS          => 'Present, Unknown'
        },
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Dell',
            NAME            => 'PWR SPLY,350W,RDNT,LTON',
            PARTNUM         => '09WR03',
            PLUGGED         => 'Yes',
            POWER_MAX       => '350',
            SERIALNUMBER    => 'CN7161561F0C36',
            STATUS          => 'Present, Unknown'
        }
    ],
    'psu/Dell_PowerEdge_R330_2' => [
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Dell',
            NAME            => 'PWR SPLY,350W,RDNT,LTON',
            PARTNUM         => '09WR03',
            PLUGGED         => 'Yes',
            POWER_MAX       => '350',
            SERIALNUMBER    => 'CN7161561F0D94',
            STATUS          => 'Present, Unknown'
        },
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Dell',
            NAME            => 'PWR SPLY,350W,RDNT,LTON',
            PARTNUM         => '09WR03',
            PLUGGED         => 'Yes',
            POWER_MAX       => '350',
            SERIALNUMBER    => 'CN7161561F0C36',
            STATUS          => 'Present, Unknown'
        }
    ],
    'psu/Dell_R630' => [
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Dell',
            NAME            => 'PWR SPLY,750W,RDNT,EMSN',
            PARTNUM         => '00XW8W',
            PLUGGED         => 'Yes',
            POWER_MAX       => '750',
            SERIALNUMBER    => 'PH1629862600EB',
            STATUS          => 'Present, Unknown'
        },
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Dell',
            NAME            => 'PWR SPLY,750W,RDNT,EMSN',
            PARTNUM         => '00XW8W',
            PLUGGED         => 'Yes',
            POWER_MAX       => '750',
            SERIALNUMBER    => 'PH16298624018E',
            STATUS          => 'Present, Unknown'
        }
    ],
    'psu/Fujitsu_ESPRIMO_P5730' => [
        {
            HOTREPLACEABLE  => 'No',
            NAME            => 'S26113-E524-V50',
            PLUGGED         => 'Yes',
            POWER_MAX       => '300',
            SERIALNUMBER    => '256732',
            STATUS          => 'Present, Unknown'
        }
    ],
    'psu/HP_1' => [
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Hewlett-Packard',
            NAME            => 'Power Supply 1',
            PARTNUM         => '503296-B21',
            PLUGGED         => 'Yes',
            POWER_MAX       => '460',
            SERIALNUMBER    => '5ANLE0CLL1BCY9',
            STATUS          => 'Present, Unknown'
        },
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Hewlett-Packard',
            NAME            => 'Power Supply 2',
            PARTNUM         => '503296-B21',
            PLUGGED         => 'Yes',
            POWER_MAX       => '460',
            SERIALNUMBER    => '5ANLE0CLLZK668',
            STATUS          => 'Present, Unknown'
        }
    ],
    'psu/HP_Proliant_Microserver_Gen_8' => [
        {
            HOTREPLACEABLE  => 'No',
            MANUFACTURER    => 'Hewlett-Packard',
            NAME            => 'Power Supply 1',
            PLUGGED         => 'Yes',
            STATUS          => 'Present, Unknown'
        }
    ],
    'psu/Kimsufi_OVH' => [
        # no serial number, no partnum and no name
    ],
    'psu/MSI_MS-7817' => [
        # no serial number, no partnum and no name
    ],
    'psu/MSI_MS-7A72' => [
        # no serial number, no partnum and no name
    ],
    'psu/nucIntel' => [
        # no serial number, no partnum and no name
    ],
    'psu/ProLiant_DL360p_Gen8_2' => [
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Hewlett-Packard',
            NAME            => 'Power Supply 1',
            PARTNUM         => '656362-B21',
            PLUGGED         => 'Yes',
            POWER_MAX       => '460',
            SERIALNUMBER    => '5BXRD0DLL3U1UJ',
            STATUS          => 'Present, Unknown'
        },
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Hewlett-Packard',
            NAME            => 'Power Supply 2',
            PARTNUM         => '656362-B21',
            PLUGGED         => 'Yes',
            POWER_MAX       => '460',
            SERIALNUMBER    => '5BXRD0BLL2Y1IC',
            STATUS          => 'Present, Unknown'
        }
    ],
    'psu/ProLiant_DL380_Gen10' => [
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Hewlett-Packard',
            NAME            => 'Power Supply 1',
            PARTNUM         => '865414-B21',
            PLUGGED         => 'Yes',
            POWER_MAX       => '800',
            SERIALNUMBER    => '5WBXU0ALL875XW',
            STATUS          => 'Present, OK'
        },
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Hewlett-Packard',
            NAME            => 'Power Supply 2',
            PARTNUM         => '865414-B21',
            PLUGGED         => 'Yes',
            POWER_MAX       => '800',
            SERIALNUMBER    => '5WBXU0ALL873NT',
            STATUS          => 'Present, OK'
        }
    ],
    'psu/ProLiant_DL380_Gen9' => [
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Hewlett-Packard',
            NAME            => 'Power Supply 1',
            PARTNUM         => '720479-B21',
            PLUGGED         => 'Yes',
            POWER_MAX       => '800',
            SERIALNUMBER    => '5DLVA0C4D9Y0T2',
            STATUS          => 'Present, OK'
        },
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Hewlett-Packard',
            NAME            => 'Power Supply 2',
            PARTNUM         => '720479-B21',
            PLUGGED         => 'Yes',
            POWER_MAX       => '800',
            SERIALNUMBER    => '5DLVA0C4D9Y480',
            STATUS          => 'Present, OK'
        }

    ],
    'psu/ProLiant_DL380p_Gen8' => [
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Hewlett-Packard',
            NAME            => 'Power Supply 1',
            PARTNUM         => '656362-B21',
            PLUGGED         => 'Yes',
            POWER_MAX       => '460',
            SERIALNUMBER    => '5BXRD0DLL5N7HT',
            STATUS          => 'Present, Unknown'
        },
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Hewlett-Packard',
            NAME            => 'Power Supply 2',
            PARTNUM         => '656362-B21',
            PLUGGED         => 'Yes',
            POWER_MAX       => '460',
            SERIALNUMBER    => '5BXRD0DLL5N7GV',
            STATUS          => 'Present, Unknown'
        }
    ],
    'psu/ProLiant_DL560_Gen8' => [
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Hewlett-Packard',
            NAME            => 'Power Supply 1',
            PARTNUM         => '656364-B21',
            PLUGGED         => 'Yes',
            POWER_MAX       => '1200',
            SERIALNUMBER    => '5BXRK0DLL4V1B6',
            STATUS          => 'Present, Unknown'
        },
        {
            HOTREPLACEABLE  => 'Yes',
            MANUFACTURER    => 'Hewlett-Packard',
            NAME            => 'Power Supply 2',
            PARTNUM         => '656364-B21',
            PLUGGED         => 'Yes',
            POWER_MAX       => '1200',
            SERIALNUMBER    => '5BXRK0DLL4T36H',
            STATUS          => 'Present, Unknown'
        }
    ],
    'psu/Supermicro_1' => [
        {
            HOTREPLACEABLE  => 'No',
            LOCATION        => 'PSU1',
            MANUFACTURER    => 'Supermicro',
            NAME            => 'PWS-406P-1R',
            PARTNUM         => 'PWS-406P-1R',
            PLUGGED         => 'Yes',
            POWER_MAX       => '400',
            SERIALNUMBER    => 'P406PCG17LT2411',
            STATUS          => 'Present, OK'
        },
        {
            HOTREPLACEABLE  => 'No',
            LOCATION        => 'PSU2',
            MANUFACTURER    => 'Supermicro',
            NAME            => 'PWS-406P-1R',
            PARTNUM         => 'PWS-406P-1R',
            PLUGGED         => 'Yes',
            POWER_MAX       => '400',
            SERIALNUMBER    => 'P406PCG17LT2410',
            STATUS          => 'Present, OK'
        }
    ],
    'psu/Supermicro_2' => [
        {
            HOTREPLACEABLE  => 'No',
            LOCATION        => 'PSU1',
            MANUFACTURER    => 'Supermicro',
            NAME            => 'PWS-407P-1R',
            PARTNUM         => 'PWS-407P-1R',
            PLUGGED         => 'Yes',
            POWER_MAX       => '400',
            SERIALNUMBER    => 'P407PCH05GT0342',
            STATUS          => 'Present, OK'
        },
        {
            HOTREPLACEABLE  => 'No',
            LOCATION        => 'PSU2',
            MANUFACTURER    => 'Supermicro',
            NAME            => 'PWS-407P-1R',
            PARTNUM         => 'PWS-407P-1R',
            PLUGGED         => 'Yes',
            POWER_MAX       => '400',
            SERIALNUMBER    => 'P407PCH05GT0343',
            STATUS          => 'Present, OK'
        }
    ],
    'psu/Supermicro_3' => [
        {
            HOTREPLACEABLE  => 'No',
            MANUFACTURER    => 'Supermicro',
            NAME            => 'PWS-703P-1R',
            PARTNUM         => 'PWS-703P-1R',
            PLUGGED         => 'Yes',
            POWER_MAX       => '700',
            SERIALNUMBER    => 'P7031CC16UT9413',
            STATUS          => 'Present, OK'
        }
    ],
    'psu/Supermicro_4' => [
        # no serial number, no partnum and no name
    ],
    'psu/Supermicro_SYS-2028TP-HC1R' => [
        {
            HOTREPLACEABLE  => 'Yes',
            LOCATION        => 'PSU1',
            MANUFACTURER    => 'Supermicro',
            NAME            => 'PWS-2K04A-1R',
            PARTNUM         => 'PWS-2K04A-1R',
            PLUGGED         => 'Yes',
            POWER_MAX       => '2000',
            SERIALNUMBER    => 'P2K4ACG46ST2836',
            STATUS          => 'Present, OK'
        },
        {
            HOTREPLACEABLE  => 'Yes',
            LOCATION        => 'PSU2',
            MANUFACTURER    => 'Supermicro',
            NAME            => 'PWS-2K04A-1R',
            PARTNUM         => 'PWS-2K04A-1R',
            PLUGGED         => 'Yes',
            POWER_MAX       => '2000',
            SERIALNUMBER    => 'P2K4ACG46ST2835',
            STATUS          => 'Present, OK'
        }
    ],
    'psu/Supermicro_SYS-2028TP-HC1R_2' => [
        {
            HOTREPLACEABLE  => 'Yes',
            LOCATION        => 'PSU1',
            MANUFACTURER    => 'Supermicro',
            NAME            => 'PWS-2K04A-1R',
            PARTNUM         => 'PWS-2K04A-1R',
            PLUGGED         => 'Yes',
            POWER_MAX       => '2000',
            SERIALNUMBER    => 'P2K4ACG52ST0413',
            STATUS          => 'Present, OK'
        },
        {
            HOTREPLACEABLE  => 'Yes',
            LOCATION        => 'PSU2',
            MANUFACTURER    => 'Supermicro',
            NAME            => 'PWS-2K04A-1R',
            PARTNUM         => 'PWS-2K04A-1R',
            PLUGGED         => 'Yes',
            POWER_MAX       => '2000',
            SERIALNUMBER    => 'P2K4ACG52ST0414',
            STATUS          => 'Present, OK'
        }
    ],
    'psu/supermicro_SYS-5038ML-H8TRF' => [
        # no serial number, no partnum and no name
    ],
    'psu/Supermicro_X11DPU' => [
        {
            HOTREPLACEABLE  => 'No',
            LOCATION        => 'PSU1',
            MANUFACTURER    => 'Supermicro',
            NAME            => 'PWS-751P-1R',
            PARTNUM         => 'PWS-751P-1R',
            PLUGGED         => 'Yes',
            POWER_MAX       => '750',
            SERIALNUMBER    => 'P751PCH10A00840',
            STATUS          => 'Present, OK'
        },
        {
            HOTREPLACEABLE  => 'No',
            LOCATION        => 'PSU2',
            MANUFACTURER    => 'Supermicro',
            NAME            => 'PWS-751P-1R',
            PARTNUM         => 'PWS-751P-1R',
            PLUGGED         => 'Yes',
            POWER_MAX       => '750',
            SERIALNUMBER    => 'P751PCH10A00839',
            STATUS          => 'Present, OK'
        }
    ],
    'psu/Supermicro_X11SSL-CF' => [
        # no serial number, no partnum and no name
    ],
    'psu/Unknown_1' => [
        # no serial number, no partnum and no name
    ],
    'psu/Workstation_Lenovo_10A9004TFR' => [
        # no serial number, no partnum and no name
    ],
);

plan tests => 2 *(scalar keys %tests) + 1;

foreach my $test (keys %tests) {
    my $file = "resources/generic/dmidecode/$test";
    my $inventory = GLPI::Test::Inventory->new();

    lives_ok {
        GLPI::Agent::Task::Inventory::Generic::Dmidecode::Psu::doInventory(
            inventory   => $inventory,
            file        => $file
        );
    } "$test: runInventory()";

    my $psu = $inventory->getSection('POWERSUPPLIES') || [];
    cmp_deeply(
        $psu,
        $tests{$test} || [],
        "$test: parsing"
    );
}
