#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;
use Test::NoWarnings;

use FusionInventory::Agent::Task::Inventory::Generic::Dmidecode::Bios;

my %tests = (
    'freebsd-6.2' => {
        bios => {
            MMANUFACTURER => undef,
            SSN           => undef,
            SKUNUMBER     => undef,
            ASSETTAG      => undef,
            BMANUFACTURER => undef,
            MSN           => undef,
            SMODEL        => undef,
            SMANUFACTURER => undef,
            BDATE         => undef,
            MMODEL        => 'CN700-8237R',
            BVERSION      => undef
        },
        hardware => {
            UUID     => undef,
            CHASSIS_TYPE => 'Desktop'
        }
    },
    'freebsd-8.1' => {
        bios => {
            MMANUFACTURER => 'Hewlett-Packard',
            SSN           => 'CNF01207X6',
            SKUNUMBER     => 'WA017EA#ABF',
            ASSETTAG      => undef,
            BMANUFACTURER => 'Hewlett-Packard',
            MSN           => 'CNF01207X6',
            SMODEL        => 'HP Pavilion dv6 Notebook PC',
            SMANUFACTURER => 'Hewlett-Packard',
            BDATE         => '05/17/2010',
            MMODEL        => '3659',
            BVERSION      => 'F.1C'
        },
        hardware => {
            UUID => '30464E43-3231-3730-5836-C80AA93F35FA',
            CHASSIS_TYPE => 'Notebook'
        },
    },
    'linux-1' => {
        bios => {
            MMANUFACTURER => 'ASUSTeK Computer INC.',
            SSN           => 'System Serial Number',
            SKUNUMBER     => 'To Be Filled By O.E.M.',
            ASSETTAG      => 'Asset-1234567890',
            BMANUFACTURER => 'American Megatrends Inc.',
            MSN           => 'MS1C93BB0H00980',
            SMODEL        => 'System Product Name',
            SMANUFACTURER => 'System manufacturer',
            BDATE         => '04/07/2009',
            MMODEL        => 'P5Q',
            BVERSION      => '2102'
        },
        hardware => {
            UUID => '40EB001E-8C00-01CE-8E2C-00248C590A84',
            CHASSIS_TYPE => 'Desktop'
        },
    },
    'linux-2.6' => {
        bios => {
            MMANUFACTURER => 'Dell Inc.',
            SSN           => 'D8XD62J',
            SKUNUMBER     => undef,
            ASSETTAG      => undef,
            BMANUFACTURER => 'Dell Inc.',
            MSN           => '.D8XD62J.CN4864363E7491.',
            SMODEL        => 'Latitude D610',
            SMANUFACTURER => 'Dell Inc.',
            BDATE         => '10/02/2005',
            MMODEL        => '0XD762',
            BVERSION      => 'A06'
        },
        hardware => {
            UUID     => '44454C4C-3800-1058-8044-C4C04F36324A',
            CHASSIS_TYPE => 'Portable'
        }
    },
    'openbsd-3.7' => {
        bios => {
            MMANUFACTURER => 'Tekram Technology Co., Ltd.',
            SSN           => undef,
            SKUNUMBER     => undef,
            ASSETTAG      => undef,
            BMANUFACTURER => 'Award Software International, Inc.',
            MSN           => undef,
            SMODEL        => 'VT82C691',
            SMANUFACTURER => 'VIA Technologies, Inc.',
            BDATE         => '02/11/99',
            MMODEL        => 'P6PROA5',
            BVERSION      => '4.51 PG'
        },
        hardware => {
            UUID         => undef,
            CHASSIS_TYPE => undef,
        }
    },
    'openbsd-3.8' => {
        bios => {
            MMANUFACTURER => 'Dell Computer Corporation',
            SSN           => '2K1012J',
            SKUNUMBER     => undef,
            ASSETTAG      => undef,
            BMANUFACTURER => 'Dell Computer Corporation',
            MSN           => '..CN717035A80217.',
            SMODEL        => 'PowerEdge 1800',
            SMANUFACTURER => 'Dell Computer Corporation',
            BDATE         => '09/21/2005',
            MMODEL        => '0P8611',
            BVERSION      => 'A05'
        },
        hardware => {
            UUID         => '44454C4C-4B00-1031-8030-B2C04F31324A',
            CHASSIS_TYPE => 'Main Server Chassis'
        }
    },
    'openbsd-4.5' => {
        bios => {
            MMANUFACTURER => 'Dell Computer Corporation',
            SSN           => '4V2VW0J',
            SKUNUMBER     => undef,
            ASSETTAG      => undef,
            BMANUFACTURER => 'Dell Computer Corporation',
            MSN           => '..TW128003952967.',
            SMODEL        => 'PowerEdge 1600SC',
            SMANUFACTURER => 'Dell Computer Corporation',
            BDATE         => '06/24/2003',
            MMODEL        => '0Y1861',
            BVERSION      => 'A08'
        },
        hardware => {
            UUID          => '44454C4C-5600-1032-8056-B4C04F57304A',
            CHASSIS_TYPE  => 'Mini Tower'
        },
    },
    'rhel-2.1' => {
        bios => {
            MMANUFACTURER => undef,
            SSN           => 'KBKGW40',
            SKUNUMBER     => undef,
            ASSETTAG      => undef,
            BMANUFACTURER => 'IBM',
            MSN           => 'NA60B7Y0S3Q',
            SMODEL        => '-[84803AX]-',
            SMANUFACTURER => 'IBM',
            BDATE         => undef,
            MMODEL        => undef,
            BVERSION      => '-[JPE130AUS-1.30]-'
        },
        hardware => {
            UUID         => undef,
            CHASSIS_TYPE => undef
        }
    },
    'rhel-3.4' => {
        bios => {
            MMANUFACTURER => 'IBM',
            SSN           => 'KDXPC16',
            SKUNUMBER     => undef,
            ASSETTAG      => '12345678901234567890123456789012',
            BMANUFACTURER => 'IBM',
            MSN           => '#A123456789',
            SMODEL        => 'IBM eServer x226-[8488PCR]-',
            SMANUFACTURER => 'IBM',
            BDATE         => '08/25/2005',
            MMODEL        => 'MSI-9151 Boards',
            BVERSION      => 'IBM BIOS Version 1.57-[PME157AUS-1.57]-'
        },
        hardware => {
            UUID     => 'A8346631-8E88-3AE3-898C-F3AC9F61C316',
            CHASSIS_TYPE => 'Tower'
        }
    },
    'rhel-3.9' => {
        bios => {
            MMANUFACTURER => undef,
            SSN           => 0,
            SKUNUMBER     => undef,
            ASSETTAG      => undef,
            BMANUFACTURER => 'innotek GmbH',
            MSN           => undef,
            SMODEL        => 'VirtualBox',
            SMANUFACTURER => 'innotek GmbH',
            BDATE         => '12/01/2006',
            MMODEL        => undef,
            BVERSION      => 'VirtualBox'
        },
        hardware => {
            UUID     => 'AE698CFC-492A-4C7B-848F-8C17D24BC76E',
            CHASSIS_TYPE => undef
        }
    },
    'rhel-4.3' => {
        bios => {
            MMANUFACTURER => 'IBM',
            SSN           => 'KDMAH1Y',
            SKUNUMBER     => undef,
            ASSETTAG      => undef,
            BMANUFACTURER => 'IBM',
            MSN           => '48Z1LX',
            SMODEL        => '-[86494jg]-',
            SMANUFACTURER => 'IBM',
            BDATE         => '03/14/2006',
            MMODEL        => 'MS-9121',
            BVERSION      => '-[OQE115A]-'
        },
        hardware => {
            UUID => '0339D4C3-44C0-9D11-A20E-85CDC42DE79C',
            CHASSIS_TYPE => 'Tower'
        }
    },
    'rhel-4.6' => {
        bios => {
            MMANUFACTURER => undef,
            SSN           => 'GB8814HE7S',
            SKUNUMBER     => undef,
            ASSETTAG      => undef,
            BMANUFACTURER => 'HP',
            MSN           => undef,
            SMODEL        => 'ProLiant ML350 G5',
            SMANUFACTURER => 'HP',
            BDATE         => '01/24/2008',
            MMODEL        => undef,
            BVERSION      => 'D21'
        },
        hardware => {
            UUID => '34313236-3435-4742-3838-313448453753',
            CHASSIS_TYPE => 'Tower'
        }
    },
    'hp-dl180' => {
        bios => {
            MMANUFACTURER => undef,
            SSN           => 'CZJ02901TG',
            SKUNUMBER     => '470065-124',
            ASSETTAG      => undef,
            BMANUFACTURER => 'HP',
            MSN           => undef,
            SMODEL        => 'ProLiant DL180 G6',
            SMANUFACTURER => 'HP',
            BDATE         => '05/19/2010',
            MMODEL        => undef,
            BVERSION      => 'O20'
        },
        hardware => {
            UUID          => '00D3F681-FE8E-11D5-B656-1CC1DE0905AE',
            CHASSIS_TYPE  => 'Rack Mount Chassis'
        },
    },
    'oracle-server-x5-2' => {
        bios => {
            MMANUFACTURER => 'Oracle Corporation',
            SSN           => '1634NM1107',
            SKUNUMBER     => '7092459',
            ASSETTAG      => '7092459',
            BMANUFACTURER => 'American Megatrends Inc.',
            MSN           => '489089M+16324B2191',
            SMODEL        => 'ORACLE SERVER X5-2',
            SMANUFACTURER => 'Oracle Corporation',
            BDATE         => '05/26/2016',
            MMODEL        => 'ASM,MOTHERBOARD,1U',
            BVERSION      => '30080300'
        },
        hardware => {
            UUID          => '080020FF-FFFF-FFFF-FFFF-0010E0BCCBBC',
            CHASSIS_TYPE  => 'Main Server Chassis'
        },
    },
    'S3000AHLX' => {
        bios => {
            MMANUFACTURER => 'Intel Corporation',
            SSN           => undef,
            SKUNUMBER     => undef,
            ASSETTAG      => undef,
            BMANUFACTURER => 'Intel Corporation',
            MSN           => 'AZAX63801455',
            SMODEL        => undef,
            SMANUFACTURER => undef,
            BDATE         => '09/01/2006',
            MMODEL        => 'S3000AHLX',
            BVERSION      => 'S3000.86B.02.00.0031.090120061242'
        },
        hardware => {
            UUID          => 'D7AFF990-4871-11DB-A6C6-0007E994F7C3',
            CHASSIS_TYPE  => 'Desktop'
        },
    },
    'S5000VSA' => {
        bios => {
            MMANUFACTURER => 'Intel',
            SSN           => '.........',
            SKUNUMBER     => undef,
            ASSETTAG      => undef,
            BMANUFACTURER => 'Intel Corporation',
            MSN           => 'QSSA64700622',
            SMODEL        => 'MP Server',
            SMANUFACTURER => 'Intel',
            BDATE         => '10/12/2006',
            MMODEL        => 'S5000VSA',
            BVERSION      => 'S5000.86B.04.00.0066.101220061333'
        },
        hardware => {
            UUID          => 'CCF82081-7966-11DB-BDB3-00151716FBAC',
            CHASSIS_TYPE  => 'Rack Mount Chassis'
        },
    },
    'vmware' => {
        bios => {
            MMANUFACTURER => 'Intel Corporation',
            SSN           => 'VMware-50 0c 23 94 04 63 a1 3c-0d d4 f5 37 a6 bb f0 a6',
            SKUNUMBER     => undef,
            ASSETTAG      => 'No Asset Tag',
            BMANUFACTURER => 'Phoenix Technologies LTD',
            MSN           => 'None',
            SMODEL        => 'VMware Virtual Platform',
            SMANUFACTURER => 'VMware, Inc.',
            BDATE         => '07/22/2008',
            MMODEL        => '440BX Desktop Reference Platform',
            BVERSION      => '6.00'
        },
        hardware => {
            UUID          => '500C2394-0127-D13C-0CC4-F537A6AAF1A6',
            CHASSIS_TYPE  => 'Other'
        }
    },
    'vmware-esx' => {
        bios => {
            MMANUFACTURER => 'Intel Corporation',
            SSN           => 'VMware-42 30 bf 6a ce 71 e1 68-6c 2d 17 6e 66 d0 4a 0d',
            SKUNUMBER     => undef,
            ASSETTAG      => 'No Asset Tag',
            BMANUFACTURER => 'Phoenix Technologies LTD',
            MSN           => 'None',
            SMODEL        => 'VMware Virtual Platform',
            SMANUFACTURER => 'VMware, Inc.',
            BDATE         => '10/13/2009',
            MMODEL        => '440BX Desktop Reference Platform',
            BVERSION      => '6.00'
        },
        hardware => {
            UUID          => '4230BF6A-CE71-E168-6C2D-176E66D04A0D',
            CHASSIS_TYPE  => 'Other'
        }
    },
    'vmware-esx-2.5' => {
        bios => {
            MMANUFACTURER => undef,
            SSN           => 'VMware-56 4d db dd 11 e3 8d 66-84 9e 15 8e 49 23 7c 97',
            SKUNUMBER     => undef,
            ASSETTAG      => 'No Asset Tag',
            BMANUFACTURER => 'Phoenix Technologies LTD',
            MSN           => 'None',
            SMODEL        => 'VMware Virtual Platform',
            SMANUFACTURER => 'VMware, Inc.',
            BDATE         => undef,
            MMODEL        => undef,
            BVERSION      => '6.00'
        },
        hardware => {
            UUID          => undef,
            CHASSIS_TYPE  => undef
        },
    },
    'windows' => {
        bios => {
            MMANUFACTURER => 'TOSHIBA',
            SSN           => 'X2735244G',
            SKUNUMBER     => undef,
            ASSETTAG      => '0000000000',
            BMANUFACTURER => 'TOSHIBA',
            MSN           => '$$T02XB1K9',
            SMODEL        => 'Satellite 2410',
            SMANUFACTURER => 'TOSHIBA',
            BDATE         => '08/13/2002',
            MMODEL        => 'Portable PC',
            BVERSION      => 'Version 1.10'
        },
        hardware => {
            UUID     => '7FB4EA00-07CB-18F3-8041-CAD582735244',
            CHASSIS_TYPE  => 'Notebook'
        }
    },
    'hp-proLiant-DL120-G6' => {
        bios => {
            MMANUFACTURER => 'Wistron Corporation',
            SSN           => 'XXXXXXXXXX',
            SKUNUMBER     => '000000-000',
            ASSETTAG      => 'No Asset Tag',
            BMANUFACTURER => 'HP',
            MSN           => '0123456789',
            SMODEL        => 'ProLiant DL120 G6',
            SMANUFACTURER => 'HP',
            BDATE         => '01/26/2010',
            MMODEL        => 'ProLiant DL120 G6',
            BVERSION      => 'O26'
        },
        hardware => {
            CHASSIS_TYPE  => 'Rack Mount Chassis',
            UUID          => 'EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE'
        }
    },
    'windows-hyperV' => {
        bios => {
            MMANUFACTURER => 'Microsoft Corporation',
            SSN           => '2349-2347-2234-2340-2341-3240-48',
            SKUNUMBER     => undef,
            ASSETTAG      => '4568-2345-6432-9324-3433-2346-47',
            BMANUFACTURER => 'American Megatrends Inc.',
            MSN           => '2349-2347-2234-2340-2341-3240-48',
            SMODEL        => 'Virtual Machine',
            SMANUFACTURER => 'Microsoft Corporation',
            BDATE         => '03/19/2009',
            MMODEL        => 'Virtual Machine',
            BVERSION      => '090004'
        },
        hardware => {
            CHASSIS_TYPE  => 'Desktop',
            UUID          => '3445DEE7-45D0-1244-95DD-34FAA067C1BE33E',
        }
    },
    'dell-fx160' => {
        bios => {
            BMANUFACTURER => 'Dell Inc.',
            MSN           => '..CN701638BM00EW.',
            BDATE         => '01/19/2012',
            SMODEL        => 'OptiPlex FX160',
            MMANUFACTURER => 'Dell Inc.',
            SMANUFACTURER => 'Dell Inc.',
            SKUNUMBER     => undef,
            BVERSION      => 'A13',
            MMODEL        => '0F259F',
            SSN           => 'C83T54J',
            ASSETTAG      => undef
        },
        hardware => {
            CHASSIS_TYPE  => 'Desktop',
            UUID          => '44454C4C-3800-1033-8054-C3C04F35344A'
        }
    },
    'dell-fx170' => {
        bios => {
            BMANUFACTURER => 'Phoenix Technologies, LTD',
            MSN           => undef,
            BDATE         => '12/13/2011',
            SMODEL        => 'OptiPlex FX170',
            MMANUFACTURER => 'Dell Inc.',
            SMANUFACTURER => 'Dell Inc.',
            SKUNUMBER     => undef,
            BVERSION      => '6.00 PG',
            MMODEL        => undef,
            SSN           => 'DHN39Q1',
            ASSETTAG      => undef
        },
        hardware => {
            CHASSIS_TYPE  => 'Desktop',
            UUID          => '000C7406-053F-1710-8E47-E3AE95ED8CF9'
        }
    },
    'lenovo-thinkpad' => {
        bios => {
            BMANUFACTURER => 'LENOVO',
            MSN           => '1ZJJC21G0N6',
            BDATE         => '12/01/2011',
            SMODEL        => 'ThinkPad Edge E320',
            SMANUFACTURER => 'LENOVO',
            SKUNUMBER     => 'ThinkPad Edge E320',
            MMANUFACTURER => 'LENOVO',
            BVERSION      => '8NET32WW (1.16 )',
            MMODEL        => '1298A8G',
            SSN           => 'LR9NKZ7',
            ASSETTAG      => 'No Asset Information'
        },
        hardware => {
            CHASSIS_TYPE  => 'Notebook',
            UUID          => '725BA801-507B-11CB-95E6-C66052AAC597'
        }
    },
    'surface-go-2' => {
        bios => {
            BMANUFACTURER => 'Microsoft Corporation',
            MSN           => '002460202151',
            BDATE         => '02/07/2020',
            SMODEL        => 'Surface Go 2',
            SMANUFACTURER => 'Microsoft Corporation',
            SKUNUMBER     => 'Surface_Go_2_1926',
            MMANUFACTURER => 'Microsoft Corporation',
            BVERSION      => '1.0.05',
            MMODEL        => 'Surface Go 2',
            SSN           => '48368130c2f8',
            ASSETTAG      => undef
        },
        hardware => {
            CHASSIS_TYPE  => 'Laptop',
            UUID          => '0e985de7-da00-4662-a18c-a957308c3ad7'
        }
    }
);

plan tests => (2 * keys %tests) + 1;

foreach my $test (keys %tests) {
    my $file = "resources/generic/dmidecode/$test";
    my ($bios, $hardware) = FusionInventory::Agent::Task::Inventory::Generic::Dmidecode::Bios::_getBiosHardware(file => $file);
    cmp_deeply($bios, $tests{$test}->{bios}, "bios: $test");
    cmp_deeply($hardware, $tests{$test}->{hardware}, "hardware: $test");
}
