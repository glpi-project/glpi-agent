#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;

use GLPI::Agent::Tools::Generic;

my %dmidecode_tests = (
    'freebsd-6.2' =>  {
        6 => [
            {
                'Installed Size' => '512 MB (Single-bank Connection)',
                'Socket Designation' => 'A0',
                'Type' => 'Other',
                'Error Status' => 'OK',
                'Enabled Size' => '512 MB (Single-bank Connection)',
                'Current Speed' => '37 ns',
                'Bank Connections' => '0'
            }
        ],
        32 => [
            {
                 'Status' => 'No errors detected'
            }
        ],
        3 => [
            {
                'Type' => 'Desktop',
                'OEM Information' => '0x00000000',
            }
        ],
        7 => [
            {
                'Installed Size' => '32 KB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'Internal Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'Installed SRAM Type' => 'Synchronous',
                'Associativity' => '4-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '32 KB'
            },
            {
                'Installed Size' => '0 KB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'Internal Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Installed SRAM Type' => 'Synchronous',
                'Location' => 'External',
                'Maximum Size' => '0 KB'
            }
        ],
        9 => [
            {
                ID             => '1',
                'Length' => 'Long',
                'Designation' => 'PCI0',
                'Type' => '32-bit PCI',
                'Current Usage' => 'Available'
            }
        ],
        17 => [
            {
                 'Size' => '512 MB',
                 'Bank Locator' => 'Bank0/1',
                 'Array Handle' => '0x0013',
                 'Locator' => 'A0',
                 'Error Information Handle' => 'Not Provided',
                 'Form Factor' => 'DIMM'
            }
        ],
        2 => [
            {
                'Product Name' => 'CN700-8237R'
            }
        ],
        20 => [
            {
                 'Memory Array Mapped Address Handle' => '0x0015',
                 'Range Size' => '512 MB',
                 'Physical Device Handle' => '0x0014',
                 'Partition Row Position' => '1',
                 'Starting Address' => '0x00000000000',
                 'Ending Address' => '0x0001FFFFFFF'
            }
        ],
        8 => [
            {
                'Port Type' => 'Other',
                'Internal Reference Designator' => 'PRIMARY IDE',
                'Internal Connector Type' => 'On Board IDE'
            },
            {
                'Port Type' => 'Other',
                'Internal Reference Designator' => 'SECONDARY IDE',
                'Internal Connector Type' => 'On Board IDE'
            },
            {
                'Port Type' => '8251 FIFO Compatible',
                'Internal Reference Designator' => 'FDD',
                'Internal Connector Type' => 'On Board Floppy'
            },
            {
                'Port Type' => 'Serial Port 16450 Compatible',
                'External Connector Type' => 'DB-9 male',
                'Internal Reference Designator' => 'COM1',
                'Internal Connector Type' => '9 Pin Dual Inline (pin 10 cut)'
            },
            {
                'Port Type' => 'Serial Port 16450 Compatible',
                'External Connector Type' => 'DB-9 male',
                'Internal Reference Designator' => 'COM2',
                'Internal Connector Type' => '9 Pin Dual Inline (pin 10 cut)'
            },
            {
                'Port Type' => 'Parallel Port ECP/EPP',
                'External Connector Type' => 'DB-25 female',
                'Internal Reference Designator' => 'LPT1',
                'Internal Connector Type' => 'DB-25 female'
            },
            {
                'Port Type' => 'Keyboard Port',
                'External Connector Type' => 'PS/2',
                'Internal Reference Designator' => 'Keyboard',
                'Internal Connector Type' => 'PS/2'
            },
            {
                'Port Type' => 'Mouse Port',
                'External Connector Type' => 'PS/2',
                'Internal Reference Designator' => 'PS/2 Mouse',
                'Internal Connector Type' => 'PS/2'
            },
            {
                'External Reference Designator' => 'USB0',
                'Port Type' => 'USB',
                'External Connector Type' => 'Other',
            }
        ],
        1 => [
            {
                'Wake-up Type' => 'Power Switch'
            }
        ],
        4 => [
            {
                ID             => 'A9 06 00 00 FF BB C9 A7',
                'Socket Designation' => 'NanoBGA2',
                'Status' => 'Populated, Enabled',
                'Max Speed' => '2000 MHz',
                'External Clock' => '100 MHz',
                'Family' => 'Other',
                'Current Speed' => '2000 MHz',
                'L2 Cache Handle' => '0x0007',
                'Type' => 'Central Processor',
                'Version' => 'VIA C7',
                'L1 Cache Handle' => '0x0006',
                'Voltage' => '1.1 V',
                'Manufacturer' => 'VIA',
                'L3 Cache Handle' => 'Not Provided'
            }
        ],
        19 => [
            {
                 'Range Size' => '512 MB',
                 'Partition Width' => '0',
                 'Starting Address' => '0x00000000000',
                 'Physical Array Handle' => '0x0013',
                 'Ending Address' => '0x0001FFFFFFF'
            }
        ],
        16 => [
            {
                 'Number Of Devices' => '1',
                 'Error Information Handle' => 'Not Provided',
                 'Location' => 'System Board Or Motherboard',
                 'Maximum Capacity' => '512 MB',
                 'Use' => 'System Memory'
            }
        ],
        13 => [
            {
                 'Installable Languages' => '3',
                 'Currently Installed Language' => 'n|US|iso8859-1'
            }
        ],
        5 => [
            {
                'Maximum Memory Module Size' => '1024 MB',
                'Associated Memory Slots' => '1',
                'Current Interleave' => 'Four-way Interleave',
                'Memory Module Voltage' => '2.9 V',
                'Supported Interleave' => 'Eight-way Interleave',
                'Maximum Total Memory Size' => '1024 MB'
            }
        ]
    },
    'freebsd-8.1' => {
        32 => [
            {
                'Status' => 'No errors detected'
            }
        ],
        11 => [
            {
                'String 1' => '$HP$',
                'String 3' => 'ABS 70/71 79 7A 7B 7C',
                'String 2' => 'LOC#ABF',
                'String 4' => 'CNB1 039C130000241310000020000'
            }
        ],
        21 => [
            {
                'Type' => 'Touch Pad',
                'Buttons' => '4',
                'Interface' => 'PS/2'
            }
        ],
        7 => [
            {
                'Error Correction Type' => 'Single-bit ECC',
                'Installed Size' => '3072 kB',
                'Operational Mode' => 'Write Through',
                'Socket Designation' => 'L3 Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 3',
                'Installed SRAM Type' => 'Synchronous',
                'System Type' => 'Unified',
                'Associativity' => 'Other',
                'Location' => 'Internal',
                'Maximum Size' => '3072 kB'
            },
            {
                'Error Correction Type' => 'Single-bit ECC',
                'Installed Size' => '32 kB',
                'Operational Mode' => 'Write Through',
                'Socket Designation' => 'L1 Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'Installed SRAM Type' => 'Synchronous',
                'System Type' => 'Data',
                'Associativity' => '8-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '32 kB'
            },
            {
                'Error Correction Type' => 'Single-bit ECC',
                'Installed Size' => '256 kB',
                'Operational Mode' => 'Write Through',
                'Socket Designation' => 'L2 Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Installed SRAM Type' => 'Synchronous',
                'System Type' => 'Unified',
                'Associativity' => '8-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '256 kB'
            },
            {
                'Error Correction Type' => 'Single-bit ECC',
                'Installed Size' => '32 kB',
                'Operational Mode' => 'Write Through',
                'Socket Designation' => 'L1 Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'Installed SRAM Type' => 'Synchronous',
                'System Type' => 'Instruction',
                'Associativity' => '4-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '32 kB'
            }
        ],
        17 => [
            {
                'Part Number' => 'HMT125S6BFR8C-H9',
                'Serial Number' => '1A1541FC',
                'Type Detail' => 'Synchronous',
                'Speed' => '1067 MHz',
                'Size' => '2048 MB',
                'Manufacturer' => 'Hynix',
                'Bank Locator' => 'BANK 0',
                'Array Handle' => '0x001B',
                'Data Width' => '64 bits',
                'Total Width' => '64 bits',
                'Locator' => 'Bottom - Slot 1',
                'Error Information Handle' => '0x001D',
                'Form Factor' => 'SODIMM'
            },
            {
                'Part Number' => 'HMT125S6BFR8C-H9',
                'Serial Number' => '1A554239',
                'Type Detail' => 'Synchronous',
                'Speed' => '1067 MHz',
                'Size' => '2048 MB',
                'Manufacturer' => 'Hynix',
                'Bank Locator' => 'BANK 1',
                'Array Handle' => '0x001B',
                'Data Width' => '64 bits',
                'Total Width' => '64 bits',
                'Locator' => 'Bottom - Slot 2',
                'Error Information Handle' => '0x0020',
                'Form Factor' => 'SODIMM'
            }
        ],
        2 => [
            {
                'Product Name' => '3659',
                'Chassis Handle' => '0x0003',
                'Serial Number' => 'CNF01207X6',
                'Asset Tag' => 'Base Board Asset Tag',
                'Version' => '32.25',
                'Type' => 'Motherboard',
                'Manufacturer' => 'Hewlett-Packard',
                'Location In Chassis' => 'Base Board Chassis Location',
                'Contained Object Handles' => '0'
            }
        ],
        22 => [
            {
                'Design Capacity' => '4400 mWh',
                'Maximum Error' => '1%',
                'OEM-specific Information' => '0xFFFFFFFF',
                'Chemistry' => 'Lithium Ion',
                'SBDS Manufacture Date' => '2010-01-15',
                'Design Voltage' => '10800 mV',
                'Location' => 'In the back',
                'Manufacturer' => 'LGC-LGC',
                'Name' => 'EV06047',
                'SBDS Version' => '3.1',
                'SBDS Serial Number' => '61E6'
            }
        ],
        1 => [
            {
                'Product Name' => 'HP Pavilion dv6 Notebook PC',
                'Family' => '103C_5335KV',
                'Serial Number' => 'CNF01207X6',
                'Version' => '039C130000241310000020000',
                'Wake-up Type' => 'Power Switch',
                'SKU Number' => 'WA017EA#ABF',
                'Manufacturer' => 'Hewlett-Packard',
                'UUID' => '30464E43-3231-3730-5836-C80AA93F35FA'
            }
        ],
        18 => [
            {
                'Type' => 'OK',
            },
            {
                'Type' => 'OK',
            },
            {
                'Type' => 'OK',
            }
        ],
        0 => [
            {
                'Version' => 'F.1C',
                'BIOS Revision' => '15.28',
                'Firmware Revision' => '50.37',
                'ROM Size' => '1536 kB',
                'Release Date' => '05/17/2010',
                'Vendor' => 'Hewlett-Packard'
            }
        ],
        16 => [
            {
                'Number Of Devices' => '2',
                'Error Information Handle' => 'No Error',
                'Location' => 'System Board Or Motherboard',
                'Maximum Capacity' => '8 GB',
                'Use' => 'System Memory'
            }
        ],
        3 => [
            {
                'Height' => 'Unspecified',
                'Power Supply State' => 'Safe',
                'Thermal State' => 'Safe',
                'Contained Elements' => '0',
                'Type' => 'Notebook',
                'Number Of Power Cords' => '1',
                'Manufacturer' => 'Hewlett-Packard',
                'Boot-up State' => 'Safe',
                'OEM Information' => '0x00000113'
            }
        ],
        9 => [
            {
                'Bus Address' => '0000:00:1f.7',
                'Length' => 'Other',
                'Designation' => 'J5C1',
                'Type' => 'x16 PCI Express x16',
                'Current Usage' => 'Available'
            },
            {
                'Bus Address' => '0000:00:1f.7',
                'Length' => 'Other',
                'Designation' => 'J6C1',
                'Type' => 'x1 PCI Express x1',
                'Current Usage' => 'Available'
            },
            {
                'Bus Address' => '0000:00:1f.7',
                'Length' => 'Other',
                'Designation' => 'J6C2',
                'Type' => 'x1 PCI Express x1',
                'Current Usage' => 'Available'
            },
            {
                'Bus Address' => '0000:00:1f.7',
                'Length' => 'Other',
                'Designation' => 'J6D2',
                'Type' => 'x1 PCI Express x1',
                'Current Usage' => 'Available'
            },
            {
                'Bus Address' => '0000:00:1f.7',
                'Length' => 'Other',
                'Designation' => 'J7C1',
                'Type' => 'x1 PCI Express x1',
                'Current Usage' => 'Available'
            },
            {
                'Bus Address' => '0000:00:1f.7',
                'Length' => 'Other',
                'Designation' => 'J7D2',
                'Type' => 'x1 PCI Express x1',
                'Current Usage' => 'Available'
            },
            {
                'Bus Address' => '0000:00:1f.7',
                'Length' => 'Other',
                'Designation' => 'J8C2',
                'Type' => 'x16 PCI Express x16',
                'Current Usage' => 'Available'
            },
            {
                'Bus Address' => '0000:00:1f.7',
                'Length' => 'Other',
                'Designation' => 'J8C1',
                'Type' => 'x1 PCI Express x1',
                'Current Usage' => 'Available'
            }
        ],
        12 => [
            {
                'Option 2' => 'String2 for Type12 Equipment Manufacturer',
                'Option 3' => 'String3 for Type12 Equipment Manufacturer',
                'Option 1' => 'String1 for Type12 Equipment Manufacturer',
                'Option 4' => 'String4 for Type12 Equipment Manufacturer'
            }
        ],
        41 => [
            {
                'Bus Address' => '0000:01:00.0',
                'Type' => 'Video',
                'Reference Designation' => 'nVidia Video Graphics Controller',
                'Type Instance' => '1',
                'Status' => 'Enabled'
            },
            {
                'Bus Address' => '0000:02:00.0',
                'Type' => 'Other',
                'Reference Designation' => 'Puma Peak 2x2 abgn (MA) IntelR Wi-Fi Link 6200',
                'Type Instance' => '1',
                'Status' => 'Enabled'
            }
        ],
        20 => [
            {
                'Range Size' => '2 GB',
                'Partition Row Position' => '2',
                'Starting Address' => '0x00000000000',
                'Memory Array Mapped Address Handle' => '0x0023',
                'Physical Device Handle' => '0x001C',
                'Interleaved Data Depth' => '1',
                'Interleave Position' => '1',
                'Ending Address' => '0x0007FFFFFFF'
            },
            {
                'Range Size' => '2 GB',
                'Partition Row Position' => '2',
                'Starting Address' => '0x00000000000',
                'Memory Array Mapped Address Handle' => '0x0023',
                'Physical Device Handle' => '0x001F',
                'Interleaved Data Depth' => '1',
                'Interleave Position' => '2',
                'Ending Address' => '0x0007FFFFFFF'
            }
        ],
        15 => [
            {
                'Access Address' => '0x0000',
                'Access Method' => 'General-purpose non-volatile data functions',
                'Data Start Offset' => '0x0000',
                'Status' => 'Valid, Not Full',
                'Supported Log Type Descriptors' => '3',
                'Descriptor 1' => 'POST memory resize',
                'Descriptor 3' => 'Log area reset/cleared',
                'Area Length' => '0 bytes',
                'Header Start Offset' => '0x0000',
                'Header Format' => 'OEM-specific',
                'Change Token' => '0x12345678',
                'Data Format 2' => 'POST results bitmap',
                'Descriptor 2' => 'POST error'
            }
        ],
        4 => [
            {
                ID             => '52 06 02 00 FF FB EB BF',
                'Socket Designation' => 'CPU',
                'Status' => 'Populated, Enabled',
                'Max Speed' => '2266 MHz',
                'Family' => 'Core 2 Duo',
                'Thread Count' => '4',
                'Current Speed' => '2266 MHz',
                'L2 Cache Handle' => '0x0019',
                'Type' => 'Central Processor',
                'Signature' => 'Type 0, Family 6, Model 37, Stepping 2',
                'L1 Cache Handle' => '0x001A',
                'Manufacturer' => 'Intel(R) Corporation',
                'Core Enabled' => '2',
                'External Clock' => '1066 MHz',
                'Asset Tag' => 'FFFF',
                'Version' => 'Intel(R) Core(TM) i5 CPU M 430 @ 2.27GHz',
                'Upgrade' => 'ZIF Socket',
                'Core Count' => '2',
                'Voltage' => '0.0 V',
                'L3 Cache Handle' => '0x0017'
            }
        ],
        19 => [
            {
                'Range Size' => '4 GB',
                'Partition Width' => '0',
                'Starting Address' => '0x00000000000',
                'Physical Array Handle' => '0x001B',
                'Ending Address' => '0x000FFFFFFFF'
            }
        ],
        10 => [
            {
                'Type' => 'Video',
                'Status' => 'Enabled',
                'Description' => 'Video Graphics Controller'
            },
            {
                'Type' => 'Ethernet',
                'Status' => 'Enabled',
                'Description' => 'Realtek Lan Controller'
            }
        ]
    },
    'linux-2.6' => {
     32 => [
            {
                 'Status' => 'No errors detected'
            }
        ],
        11 => [
            {
                 'String 1' => 'Dell System',
                 'String 3' => '13[PP11L]',
                 'String 2' => '5[0003]'
            }
        ],
        21 => [
            {
                 'Type' => 'Touch Pad',
                 'Buttons' => '2',
                 'Interface' => 'Bus Mouse'
            }
        ],
        7 => [
            {
                'Installed Size' => '8 KB',
                'Operational Mode' => 'Write Back',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'System Type' => 'Data',
                'Associativity' => '4-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '8 KB'
            },
            {
                'Installed Size' => '2048 KB',
                'Operational Mode' => 'Varies With Memory Address',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Installed SRAM Type' => 'Pipeline Burst',
                'System Type' => 'Unified',
                'Speed' => '15 ns',
                'Associativity' => 'Other',
                'Location' => 'Internal',
                'Maximum Size' => '2048 KB'
            }
        ],
        17 => [
            {
                 'Serial Number' => '02132010',
                 'Data Width' => '64 bits',
                 'Array Handle' => '0x1000',
                 'Type Detail' => 'Synchronous',
                 'Total Width' => '64 bits',
                 'Type' => 'DDR',
                 'Speed' => '533 MHz (1.9 ns)',
                 'Size' => '1024 MB',
                 'Error Information Handle' => 'Not Provided',
                 'Locator' => 'DIMM_A',
                 'Manufacturer' => 'C100000000000000',
                 'Form Factor' => 'DIMM'
            },
            {
                 'Serial Number' => '02132216',
                 'Data Width' => '64 bits',
                 'Array Handle' => '0x1000',
                 'Type Detail' => 'Synchronous',
                 'Total Width' => '64 bits',
                 'Type' => 'DDR',
                 'Speed' => '533 MHz (1.9 ns)',
                 'Size' => '1024 MB',
                 'Error Information Handle' => 'Not Provided',
                 'Locator' => 'DIMM_B',
                 'Manufacturer' => 'C100000000000000',
                 'Form Factor' => 'DIMM'
            }
        ],
        2 => [
            {
                'Product Name' => '0XD762',
                'Serial Number' => '.D8XD62J.CN4864363E7491.',
                'Manufacturer' => 'Dell Inc.'
            }
        ],
        22 => [
            {
                 'Design Capacity' => '48000 mWh',
                 'Maximum Error' => '3%',
                 'OEM-specific Information' => '0x00000001',
                 'Design Voltage' => '11100 mV',
                 'SBDS Manufacture Date' => '2006-03-11',
                 'SBDS Chemistry' => 'LION',
                 'Location' => 'Sys. Battery Bay',
                 'Manufacturer' => 'Samsung SDI',
                 'Name' => 'DELL C129563',
                 'SBDS Version' => '1.0',
                 'SBDS Serial Number' => '7734'
            }
        ],
        1 => [
            {
                'Wake-up Type' => 'Power Switch',
                'Product Name' => 'Latitude D610',
                'Serial Number' => 'D8XD62J',
                'Manufacturer' => 'Dell Inc.',
                'UUID' => '44454C4C-3800-1058-8044-C4C04F36324A'
            }
        ],
        0 => [
            {
                'Runtime Size' => '64 kB',
                'Version' => 'A06',
                'Address' => '0xF0000',
                'ROM Size' => '576 kB',
                'Release Date' => '10/02/2005',
                'Vendor' => 'Dell Inc.'
            }
        ],
        16 => [
            {
                 'Number Of Devices' => '2',
                 'Error Information Handle' => 'Not Provided',
                 'Location' => 'System Board Or Motherboard',
                 'Maximum Capacity' => '4 GB',
                 'Use' => 'System Memory'
            }
        ],
        13 => [
            {
                 'Installable Languages' => '1',
                 'Currently Installed Language' => 'en|US|iso8859-1'
            }
        ],
        27 => [
            {
                 'Type' => 'Fan',
                 'Status' => 'OK',
                 'OEM-specific Information' => '0x0000DD00'
            }
        ],
        28 => [
            {
                 'Status' => 'OK',
                 'OEM-specific Information' => '0x0000DC00',
                 'Maximum Value' => '127.0 deg C',
                 'Resolution' => '1.000 deg C',
                 'Location' => 'Processor',
                 'Tolerance' => '0.5 deg C',
                 'Description' => 'CPU Internal Temperature'
            }
        ],
        3 => [
            {
                'Type' => 'Portable',
                'Power Supply State' => 'Safe',
                'Serial Number' => 'D8XD62J',
                'Thermal State' => 'Safe',
                'Boot-up State' => 'Safe',
                'Manufacturer' => 'Dell Inc.'
            }
        ],
        9 => [
            {
                ID             => 'Adapter 0, Socket 0',
                'Length' => 'Other',
                'Designation' => 'PCMCIA 0',
                'Type' => '32-bit PC Card (PCMCIA)',
                'Current Usage' => 'Available'
            },
            {
                'Length' => 'Other',
                'Designation' => 'MiniPCI',
                'Type' => '32-bit Other',
                'Current Usage' => 'Available'
            }
        ],
        20 => [
            {
                 'Memory Array Mapped Address Handle' => '0x1300',
                 'Range Size' => '640 kB',
                 'Physical Device Handle' => '0x1100',
                 'Partition Row Position' => '1',
                 'Starting Address' => '0x00000000000',
                 'Ending Address' => '0x0000009FFFF'
            },
            {
                 'Memory Array Mapped Address Handle' => '0x1301',
                 'Range Size' => '1023 MB',
                 'Physical Device Handle' => '0x1100',
                 'Partition Row Position' => '1',
                 'Starting Address' => '0x00000100000',
                 'Ending Address' => '0x0003FFFFFFF'
            },
            {
                 'Memory Array Mapped Address Handle' => '0x1301',
                 'Range Size' => '1 GB',
                 'Physical Device Handle' => '0x1101',
                 'Partition Row Position' => '1',
                 'Starting Address' => '0x00040000000',
                 'Ending Address' => '0x0007FFFFFFF'
            }
        ],
        8 => [
            {
                'Port Type' => 'Parallel Port PS/2',
                'External Connector Type' => 'DB-25 female',
                'Internal Reference Designator' => 'PARALLEL',
            },
            {
                'Port Type' => 'Serial Port 16550A Compatible',
                'External Connector Type' => 'DB-9 male',
                'Internal Reference Designator' => 'SERIAL1',
            },
            {
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)',
                'Internal Reference Designator' => 'USB',
            },
            {
                'Port Type' => 'Video Port',
                'External Connector Type' => 'DB-15 female',
                'Internal Reference Designator' => 'MONITOR',
            },
            {
                'Port Type' => 'Other',
                'External Connector Type' => 'Infrared',
                'Internal Reference Designator' => 'IrDA',
            },
            {
                'Port Type' => 'Modem Port',
                'External Connector Type' => 'RJ-11',
                'Internal Reference Designator' => 'Modem',
            },
            {
                'Port Type' => 'Network Port',
                'External Connector Type' => 'RJ-45',
                'Internal Reference Designator' => 'Ethernet',
            }
        ],
        4 => [
            {
                ID             => 'D8 06 00 00 FF FB E9 AF',
                'Socket Designation' => 'Microprocessor',
                'Status' => 'Populated, Enabled',
                'Max Speed' => '1800 MHz',
                'External Clock' => '133 MHz',
                'Family' => 'Pentium M',
                'Current Speed' => '1733 MHz',
                'L2 Cache Handle' => '0x0701',
                'Type' => 'Central Processor',
                'Signature' => 'Type 0, Family 6, Model 13, Stepping 8',
                'L1 Cache Handle' => '0x0700',
                'Voltage' => '3.3 V',
                'Manufacturer' => 'Intel',
                'L3 Cache Handle' => 'Not Provided'
            }
        ],
        10 => [
            {
                 'Type' => 'Video',
                 'Status' => 'Enabled',
                 'Description' => 'Intel 915GM Graphics'
            },
            {
                 'Type' => 'Sound',
                 'Status' => 'Enabled',
                 'Description' => 'Sigmatel 9751'
            }
        ],
        19 => [
            {
                 'Range Size' => '640 kB',
                 'Partition Width' => '0',
                 'Starting Address' => '0x00000000000',
                 'Physical Array Handle' => '0x1000',
                 'Ending Address' => '0x0000009FFFF'
            },
            {
                 'Range Size' => '2047 MB',
                 'Partition Width' => '0',
                 'Starting Address' => '0x00000100000',
                 'Physical Array Handle' => '0x1000',
                 'Ending Address' => '0x0007FFFFFFF'
            }
        ]
    },
    'openbsd-3.7' => {
         6 => [
            {
                'Installed Size' => 'Not Installed',
                'Socket Designation' => 'BANK_1',
                'Error Status' => 'OK',
                'Enabled Size' => 'Not Installed',
                'Current Speed' => '70 ns',
                'Bank Connections' => '2'
            },
            {
                'Installed Size' => '64 MB (Single-bank Connection)',
                'Socket Designation' => 'BANK_2',
                'Type' => 'DIMM SDRAM',
                'Error Status' => 'OK',
                'Enabled Size' => '64 MB (Single-bank Connection)',
                'Current Speed' => '70 ns',
                'Bank Connections' => '3'
            },
            {
                'Installed Size' => 'Not Installed',
                'Socket Designation' => 'BANK_3',
                'Error Status' => 'OK',
                'Enabled Size' => 'Not Installed',
                'Current Speed' => '70 ns',
                'Bank Connections' => '4'
            },
            {
                'Installed Size' => '64 MB (Single-bank Connection)',
                'Socket Designation' => 'BANK_4',
                'Type' => 'DIMM SDRAM',
                'Error Status' => 'OK',
                'Enabled Size' => '64 MB (Single-bank Connection)',
                'Current Speed' => '70 ns',
                'Bank Connections' => '5'
            },
            {
                'Installed Size' => '64 MB (Single-bank Connection)',
                'Socket Designation' => 'BANK_5',
                'Type' => 'DIMM SDRAM',
                'Error Status' => 'OK',
                'Enabled Size' => '64 MB (Single-bank Connection)',
                'Current Speed' => '70 ns',
                'Bank Connections' => '6'
            },
            {
                'Installed Size' => 'Not Installed',
                'Socket Designation' => 'BANK_6',
                'Error Status' => 'OK',
                'Enabled Size' => 'Not Installed',
                'Current Speed' => '70 ns',
                'Bank Connections' => '7'
            },
            {
                'Installed Size' => 'Not Installed',
                'Socket Designation' => 'BANK_7',
                'Error Status' => 'OK',
                'Enabled Size' => 'Not Installed',
                'Current Speed' => '70 ns',
                'Bank Connections' => '8'
            }
        ],
        7 => [
            {
                'Installed Size' => '32 KB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'Internal Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'Installed SRAM Type' => 'Synchronous',
                'Location' => 'Internal',
                'Maximum Size' => '32 KB'
            },
            {
                'Installed Size' => '512 KB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'External Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Installed SRAM Type' => 'Synchronous',
                'Location' => 'External',
                'Maximum Size' => '2048 KB'
            }
        ],
        9 => [
            {
                ID             => '32',
                'Length' => 'Long',
                'Designation' => 'AGP',
                'Type' => '32-bit PCI',
                'Current Usage' => 'In Use'
            },
            {
                ID             => '12',
                'Length' => 'Long',
                'Designation' => 'PCI1',
                'Type' => '32-bit PCI',
                'Current Usage' => 'Available'
            },
            {
                ID             => '11',
                'Length' => 'Long',
                'Designation' => 'PCI2',
                'Type' => '32-bit PCI',
                'Current Usage' => 'Available'
            },
            {
                ID             => '10',
                'Length' => 'Long',
                'Designation' => 'PCI3',
                'Type' => '32-bit PCI',
                'Current Usage' => 'In Use'
            },
            {
                ID             => '9',
                'Length' => 'Long',
                'Designation' => 'PCI4',
                'Type' => '32-bit PCI',
                'Current Usage' => 'Available'
            },
            {
                ID             => '8',
                'Length' => 'Long',
                'Designation' => 'PCI5',
                'Type' => '32-bit PCI',
                'Current Usage' => 'Available'
            },
            {
                'Length' => 'Long',
                'Designation' => 'ISA',
                'Type' => '16-bit ISA',
            },
            {
                'Length' => 'Long',
                'Designation' => 'ISA',
                'Type' => '16-bit ISA',
            },
            {
                ID             => '0',
                'Length' => 'Long',
                'Designation' => 'PCIx',
                'Type' => '32-bit PCI',
            },
            {
                ID             => '0',
                'Length' => 'Long',
                'Designation' => 'PCIx',
                'Type' => '32-bit PCI',
            },
            {
                ID             => '0',
                'Length' => 'Long',
                'Designation' => 'PCIx',
                'Type' => '32-bit PCI',
            },
            {
                ID             => '0',
                'Length' => 'Long',
                'Designation' => 'PCIx',
                'Type' => '32-bit PCI',
            },
            {
                ID             => '0',
                'Length' => 'Long',
                'Designation' => 'PCIx',
                'Type' => '32-bit PCI',
            }
        ],
        2 => [
            {
                'Version' => 'Rev. 1.0',
                'Product Name' => 'P6PROA5',
                'Manufacturer' => 'Tekram Technology Co., Ltd.'
            }
        ],
        8 => [
            {
                'Port Type' => 'Other',
                'Internal Reference Designator' => 'PRIMARY IDE',
                'Internal Connector Type' => 'On Board IDE'
            },
            {
                'Port Type' => 'Other',
                'Internal Reference Designator' => 'SECONDARY IDE',
                'Internal Connector Type' => 'On Board IDE'
            },
            {
                'Port Type' => 'Other',
                'Internal Reference Designator' => 'FLOPPY',
                'Internal Connector Type' => 'On Board Floppy'
            },
            {
                'Port Type' => 'Serial Port 16550 Compatible',
                'External Connector Type' => 'DB-9 male',
                'Internal Reference Designator' => 'COM1',
                'Internal Connector Type' => '9 Pin Dual Inline (pin 10 cut)'
            },
            {
                'Port Type' => 'Serial Port 16550 Compatible',
                'External Connector Type' => 'DB-9 male',
                'Internal Reference Designator' => 'COM2',
                'Internal Connector Type' => '9 Pin Dual Inline (pin 10 cut)'
            },
            {
                'Port Type' => 'Parallel Port ECP/EPP',
                'External Connector Type' => 'DB-25 female',
                'Internal Reference Designator' => 'LPT1',
                'Internal Connector Type' => 'DB-25 female'
            },
            {
                'Port Type' => 'Keyboard Port',
                'External Connector Type' => 'PS/2',
                'Internal Reference Designator' => 'Keyboard',
                'Internal Connector Type' => 'Other'
            },
            {
                'Port Type' => 'Mouse Port',
                'External Connector Type' => 'PS/2',
                'Internal Reference Designator' => 'PS/2 Mouse',
                'Internal Connector Type' => 'Other'
            },
            {
                'Port Type' => 'Other',
                'External Connector Type' => 'Infrared',
                'Internal Reference Designator' => 'IR_CON',
                'Internal Connector Type' => 'Other'
            },
            {
                'Port Type' => 'Other',
                'External Connector Type' => 'Infrared',
                'Internal Reference Designator' => 'IR_CON2',
                'Internal Connector Type' => 'Other'
            },
            {
                'Port Type' => 'USB',
                'External Connector Type' => 'Other',
                'Internal Reference Designator' => 'USB',
                'Internal Connector Type' => 'Other'
            }
        ],
        1 => [
            {
                'Product Name' => 'VT82C691',
                'Manufacturer' => 'VIA Technologies, Inc.'
            }
        ],
        4 => [
            {
                ID             => '52 06 00 00 FF F9 83 01',
                'Socket Designation' => 'SLOT 1',
                'Status' => 'Populated, Enabled',
                'Max Speed' => '500 MHz',
                'External Clock' => '100 MHz',
                'Family' => 'Pentium II',
                'Current Speed' => '400 MHz',
                'Type' => 'Central Processor',
                'Signature' => 'Type 0, Family 6, Model 5, Stepping 2',
                'Version' => 'Pentium II',
                'Upgrade' => 'Slot 1',
                'Voltage' => '3.3 V',
                'Manufacturer' => 'Intel'
            }
        ],
        0 => [
            {
                'Runtime Size' => '128 kB',
                'Version' => '4.51 PG',
                'Address' => '0xE0000',
                'ROM Size' => '256 kB',
                'Release Date' => '02/11/99',
                'Vendor' => 'Award Software International, Inc.'
            }
        ],
        5 => [
            {
                'Error Detecting Method' => '64-bit ECC',
                'Maximum Total Memory Size' => '2048 MB',
                'Supported Interleave' => 'Four-way Interleave',
                'Maximum Memory Module Size' => '256 MB',
                'Associated Memory Slots' => '8',
                'Current Interleave' => 'One-way Interleave',
                'Memory Module Voltage' => '5.0 V 3.3 V'
            }
        ],
        13 => [
            {
                'Installable Languages' => '3',
                'Currently Installed Language' => 'en|US|iso8859-1'
            }
        ]
    },
    'openbsd-3.8' => {
            32 => [
            {
                 'Status' => 'No errors detected'
            }
        ],
        11 => [
            {
                 'String 1' => 'Dell System',
                 'String 2' => '5[0000]'
            }
        ],
        7 => [
            {
                'Error Correction Type' => 'Parity',
                'Installed Size' => '16 KB',
                'Operational Mode' => 'Write Through',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'System Type' => 'Data',
                'Associativity' => '8-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '16 KB'
            },
            {
                'Error Correction Type' => 'Single-bit ECC',
                'Installed Size' => '2048 KB',
                'Operational Mode' => 'Write Back',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'System Type' => 'Unified',
                'Associativity' => '8-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '2048 KB'
            },
            {
                'Error Correction Type' => 'Single-bit ECC',
                'Installed Size' => '0 KB',
                'Operational Mode' => 'Write Back',
                'Configuration' => 'Enabled, Not Socketed, Level 3',
                'System Type' => 'Unified',
                'Associativity' => '2-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '0 KB'
            },
            {
                'Error Correction Type' => 'Parity',
                'Installed Size' => '0 KB',
                'Operational Mode' => 'Write Through',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'System Type' => 'Data',
                'Associativity' => '8-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '16 KB'
            },
            {
                'Error Correction Type' => 'Single-bit ECC',
                'Installed Size' => '0 KB',
                'Operational Mode' => 'Write Back',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'System Type' => 'Unified',
                'Associativity' => '8-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '2048 KB'
            },
            {
                'Error Correction Type' => 'Single-bit ECC',
                'Installed Size' => '0 KB',
                'Operational Mode' => 'Write Back',
                'Configuration' => 'Enabled, Not Socketed, Level 3',
                'System Type' => 'Unified',
                'Associativity' => '2-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '0 KB'
            }
        ],
        17 => [
            {
                 'Part Number' => 'M3 93T6450FZ0-CCC',
                 'Serial Number' => '50075483',
                 'Data Width' => '64 bits',
                 'Array Handle' => '0x1000',
                 'Type Detail' => 'Synchronous',
                 'Set' => '1',
                 'Asset Tag' => '010552',
                 'Total Width' => '72 bits',
                 'Speed' => '400 MHz (2.5 ns)',
                 'Size' => '512 MB',
                 'Error Information Handle' => 'Not Provided',
                 'Locator' => 'DIMM1_A',
                 'Manufacturer' => 'CE00000000000000',
                 'Form Factor' => 'DIMM'
            },
            {
                 'Part Number' => 'M3 93T6450FZ0-CCC',
                 'Serial Number' => '500355A1',
                 'Data Width' => '64 bits',
                 'Array Handle' => '0x1000',
                 'Type Detail' => 'Synchronous',
                 'Set' => '1',
                 'Asset Tag' => '010552',
                 'Total Width' => '72 bits',
                 'Speed' => '400 MHz (2.5 ns)',
                 'Size' => '512 MB',
                 'Error Information Handle' => 'Not Provided',
                 'Locator' => 'DIMM1_B',
                 'Manufacturer' => 'CE00000000000000',
                 'Form Factor' => 'DIMM'
            },
            {
                 'Data Width' => '64 bits',
                 'Array Handle' => '0x1000',
                 'Type Detail' => 'Synchronous',
                 'Set' => '2',
                 'Total Width' => '72 bits',
                 'Speed' => '400 MHz (2.5 ns)',
                 'Size' => 'No Module Installed',
                 'Error Information Handle' => 'Not Provided',
                 'Locator' => 'DIMM2_A',
                 'Form Factor' => 'DIMM'
            },
            {
                 'Data Width' => '64 bits',
                 'Array Handle' => '0x1000',
                 'Type Detail' => 'Synchronous',
                 'Set' => '2',
                 'Total Width' => '72 bits',
                 'Speed' => '400 MHz (2.5 ns)',
                 'Size' => 'No Module Installed',
                 'Error Information Handle' => 'Not Provided',
                 'Locator' => 'DIMM2_B',
                 'Form Factor' => 'DIMM'
            },
            {
                 'Data Width' => '64 bits',
                 'Array Handle' => '0x1000',
                 'Type Detail' => 'Synchronous',
                 'Set' => '3',
                 'Total Width' => '72 bits',
                 'Speed' => '400 MHz (2.5 ns)',
                 'Size' => 'No Module Installed',
                 'Error Information Handle' => 'Not Provided',
                 'Locator' => 'DIMM3_A',
                 'Form Factor' => 'DIMM'
            },
            {
                 'Data Width' => '64 bits',
                 'Array Handle' => '0x1000',
                 'Type Detail' => 'Synchronous',
                 'Set' => '3',
                 'Total Width' => '72 bits',
                 'Speed' => '400 MHz (2.5 ns)',
                 'Size' => 'No Module Installed',
                 'Error Information Handle' => 'Not Provided',
                 'Locator' => 'DIMM3_B',
                 'Form Factor' => 'DIMM'
            }
        ],
        2 => [
            {
                'Version' => 'A04',
                'Product Name' => '0P8611',
                'Serial Number' => '..CN717035A80217.',
                'Manufacturer' => 'Dell Computer Corporation'
            }
        ],
        1 => [
            {
                'Wake-up Type' => 'Power Switch',
                'Product Name' => 'PowerEdge 1800',
                'Serial Number' => '2K1012J',
                'Manufacturer' => 'Dell Computer Corporation',
                'UUID' => '44454C4C-4B00-1031-8030-B2C04F31324A'
            }
        ],
        0 => [
            {
                'Runtime Size' => '64 kB',
                'Version' => 'A05',
                'Address' => '0xF0000',
                'ROM Size' => '1024 kB',
                'Release Date' => '09/21/2005',
                'Vendor' => 'Dell Computer Corporation'
            }
        ],
        16 => [
            {
                 'Number Of Devices' => '6',
                 'Error Correction Type' => 'Multi-bit ECC',
                 'Error Information Handle' => 'Not Provided',
                 'Location' => 'System Board Or Motherboard',
                 'Maximum Capacity' => '12 GB',
                 'Use' => 'System Memory'
            }
        ],
        13 => [
            {
                 'Installable Languages' => '1',
                 'Currently Installed Language' => 'en|US|iso8859-1'
            }
        ],
        3 => [
            {
                'Power Supply State' => 'Safe',
                'Serial Number' => '2K1012J',
                'Thermal State' => 'Safe',
                'Type' => 'Main Server Chassis',
                'Lock' => 'Present',
                'OEM Information' => '0x00000000',
                'Manufacturer' => 'Dell Computer Corporation',
                'Boot-up State' => 'Safe'
            }
        ],
        9 => [
            {
                ID             => '1',
                'Length' => 'Long',
                'Designation' => 'SLOT1',
                'Type' => '64-bit PCI',
                'Current Usage' => 'Available'
            },
            {
                'Length' => 'Long',
                'Designation' => 'SLOT2',
                'Current Usage' => 'Available',
            },
            {
                'Length' => 'Long',
                'Designation' => 'SLOT3',
                'Current Usage' => 'Available'
            },
            {
                ID             => '4',
                'Length' => 'Long',
                'Designation' => 'SLOT4',
                'Type' => '32-bit PCI',
                'Current Usage' => 'Available'
            },
            {
                ID             => '5',
                'Length' => 'Long',
                'Designation' => 'SLOT5',
                'Type' => '64-bit PCI-X',
                'Current Usage' => 'In Use'
            },
            {
                ID             => '6',
                'Length' => 'Long',
                'Designation' => 'SLOT6',
                'Type' => '64-bit PCI-X',
                'Current Usage' => 'Available'
            }
        ],
        12 => [
            {
                 'Option 2' => 'PASSWD: Close to enable password',
                 'Option 1' => 'NVRAM_CLR: Clear user settable NVRAM areas and set defaults'
            }
        ],
        20 => [
            {
                 'Memory Array Mapped Address Handle' => '0x1300',
                 'Range Size' => '1 GB',
                 'Physical Device Handle' => '0x1100',
                 'Partition Row Position' => '1',
                 'Starting Address' => '0x00000000000',
                 'Ending Address' => '0x0003FFFFFFF'
            },
            {
                 'Memory Array Mapped Address Handle' => '0x1300',
                 'Range Size' => '1 GB',
                 'Physical Device Handle' => '0x1101',
                 'Partition Row Position' => '2',
                 'Starting Address' => '0x00000000000',
                 'Ending Address' => '0x0003FFFFFFF'
            }
        ],
        38 => [
            {
                 'I2C Slave Address' => '0x10',
                 'Register Spacing' => '32-bit Boundaries',
                 'Specification Version' => '1.5',
                 'Base Address' => '0x0000000000000CA8 (I/O)',
                 'Interface Type' => 'KCS (Keyboard Control Style)'
            }
        ],
        8 => [
            {
                'Port Type' => 'SCSI Wide',
                'Internal Reference Designator' => 'SCSI',
                'Internal Connector Type' => '68 Pin Dual Inline'
            },
            {
                'Port Type' => 'Video Port',
                'External Connector Type' => 'DB-15 female',
            },
            {
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)',
            },
            {
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)',
            },
            {
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)',
            },
            {
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)',
            },
            {
                'Port Type' => 'Parallel Port PS/2',
                'External Connector Type' => 'DB-25 female',
            },
            {
                'Port Type' => 'Network Port',
                'External Connector Type' => 'RJ-45',
            },
            {
                'Port Type' => 'Serial Port 16550A Compatible',
                'External Connector Type' => 'DB-9 male',
            },
            {
                'Port Type' => 'Keyboard Port',
                'External Connector Type' => 'PS/2',
            },
            {
                'Port Type' => 'Mouse Port',
                'External Connector Type' => 'PS/2',
            }
        ],
        4 => [
            {
                ID             => '43 0F 00 00 FF FB EB BF',
                'Socket Designation' => 'PROC_1',
                'Status' => 'Populated, Enabled',
                'Max Speed' => '3600 MHz',
                'External Clock' => '800 MHz',
                'Family' => 'Xeon',
                'Current Speed' => '3000 MHz',
                'L2 Cache Handle' => '0x0701',
                'Type' => 'Central Processor',
                'Signature' => 'Type 0, Family 15, Model 4, Stepping 3',
                'Upgrade' => 'ZIF Socket',
                'L1 Cache Handle' => '0x0700',
                'Voltage' => '1.4 V',
                'Manufacturer' => 'Intel',
                'L3 Cache Handle' => '0x0702'
            },
            {
                ID             => '00 00 00 00 00 00 00 00',
                'Socket Designation' => 'PROC_2',
                'Status' => 'Unpopulated',
                'Max Speed' => '3600 MHz',
                'Family' => 'Xeon',
                'L2 Cache Handle' => '0x0704',
                'Type' => 'Central Processor',
                'Signature' => 'Type 0, Family 0, Model 0, Stepping 0',
                'Upgrade' => 'ZIF Socket',
                'L1 Cache Handle' => '0x0703',
                'Voltage' => '1.4 V',
                'Manufacturer' => 'Intel',
                'L3 Cache Handle' => '0x0705'
            }
        ],
        10 => [
            {
                 'Type' => 'Ethernet',
                 'Status' => 'Enabled',
                 'Description' => 'Intel 82541GI Gigabit Ethernet'
            }
        ],
        19 => [
            {
                 'Range Size' => '1 GB',
                 'Partition Width' => '0',
                 'Starting Address' => '0x00000000000',
                 'Physical Array Handle' => '0x1000',
                 'Ending Address' => '0x0003FFFFFFF'
            }
        ]
    },
    'rhel-2.1' => {
        6 => [
            {
                'Installed Size' => '256Mbyte',
                'Type' => 'ECC DIMM SDRAM',
                'Enabled Size' => '256Mbyte',
                'Banks' => '0',
                'Socket' => 'DIMM1'
            },
            {
                'Installed Size' => 'Not Installed',
                'Enabled Size' => 'Not Installed',
                'Socket' => 'DIMM2'
            }
        ],
        3 => [
            {
                'Chassis Type' => 'Mini Tower',
                'Vendor' => 'IBM'
            }
        ],
        7 => [
            {
                'L1 Cache Size' => '32K',
                'L1 socketed Internal Cache' => 'write-back',
                'L1 Cache Maximum' => '20K',
                'Socket' => 'CPU1'
            },
            {
                'L2 Cache Size' => '512K',
                'L2 socketed Internal Cache' => 'write-back',
                'L2 Cache Type' => 'Pipeline burst',
                'Socket' => 'CPU1',
                'L2 Cache Maximum' => '512K'
            }
        ],
        9 => [
            {
                'Slot' => 'AGP',
                'Slot Features' => '5v'
            },
            {
                'Type' => '32bit PCI',
                'Slot' => 'PCI1',
                'Status' => 'Available.',
                'Slot Features' => '5v'
            },
            {
                'Type' => '32bit PCI',
                'Slot' => 'PCI2',
                'Status' => 'In use.',
                'Slot Features' => '5v'
            },
            {
                'Type' => '32bit PCI',
                'Slot' => 'PCI3',
                'Status' => 'Available.',
                'Slot Features' => '5v'
            },
            {
                'Type' => '32bit PCI',
                'Slot' => 'PCI4',
                'Status' => 'Available.',
                'Slot Features' => '5v'
            },
            {
                'Type' => '32bit PCI',
                'Slot' => 'PCI5',
                'Status' => 'Available.',
                'Slot Features' => '5v'
            }
        ],
        2 => [
            {
                'Version' => '-1',
                'Serial Number' => 'NA60B7Y0S3Q',
                'Product' => '-[M51G]-',
                'Vendor' => 'IBM'
            }
        ],
        15 => [
            {
                 'Log Type' => '3.',
                 'Log Area' => '511 bytes.',
                 'Log Data At' => '16.',
                 'Log Header At' => '0.',
                 'Log Valid' => 'Yes.'
            }
        ],
        8 => [
            {
                'Port Type' => 'Serial Port 16650A Compatible',
                'External Connector Type' => 'DB-9 pin male',
                'External Designator' => 'SERIAL1'
            },
            {
                'Port Type' => 'Serial Port 16650A Compatible',
                'External Connector Type' => 'DB-9 pin male',
                'External Designator' => 'SERIAL2'
            },
            {
                'Port Type' => 'Parallel Port ECP/EPP',
                'External Connector Type' => 'DB-25 pin female',
                'External Designator' => 'PRINTER'
            },
            {
                'Port Type' => 'Keyboard Port',
                'External Connector Type' => 'PS/2',
                'External Designator' => 'KEYBOARD'
            },
            {
                'Port Type' => 'Mouse Port',
                'External Connector Type' => 'PS/2',
                'External Designator' => 'MOUSE'
            },
            {
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)',
                'External Designator' => 'USB1'
            },
            {
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)',
                'External Designator' => 'USB2'
            },
            {
                'Port Type' => 'Other',
                'Internal Designator' => 'IDE1',
                'Internal Connector Type' => 'On Board IDE'
            },
            {
                'Port Type' => 'Other',
                'Internal Designator' => 'IDE2',
                'Internal Connector Type' => 'On Board IDE'
            },
            {
                'Port Type' => 'Other',
                'Internal Designator' => 'FDD',
                'Internal Connector Type' => 'On Board Floppy'
            },
            {
                'Port Type' => 'SCSI II',
                'Internal Designator' => 'SCSI1',
                'Internal Connector Type' => 'SSA SCSI'
            }
        ],
        1 => [
            {
                'Version' => 'IBM CORPORATION',
                'Serial Number' => 'KBKGW40',
                'Product' => '-[84803AX]-',
                'Vendor' => 'IBM'
            }
        ],
        4 => [
            {
                'Socket Designation' => 'CPU1',
                'Processor Manufacturer' => 'Intel',
                'Processor Version' => 'Pentium 4',
                'Processor Type' => 'Central Processor'
            }
        ],
        0 => [
            {
                'Release' => '12/11/2002',
                'Version' => '-[JPE130AUS-1.30]-',
                'Flags' => '0x000000007FFBDE90',
                'BIOS base' => '0xF0000',
                'Vendor' => 'IBM',
                'ROM size' => '448K'
            }
        ],
        10 => [
            {
                 'Description' => 'IBM Automatic Server Restart - Machine Type 8480 : Enabled'
            }
        ]
    },
    'rhel-3.4' => {
            11 => [
            {
                 'String 1' => 'IBM Remote Supervisor Adapter -[GRET15AUS]-'
            }
        ],
        3 => [
            {
                'Power Supply State' => 'Safe',
                'Thermal State' => 'Safe',
                'Asset Tag' => '12345678901234567890123456789012',
                'Type' => 'Tower',
                'Manufacturer' => 'IBM',
                'Boot-up State' => 'Safe',
                'OEM Information' => '0x00001234'
            }
        ],
        7 => [
            {
                'Error Correction Type' => 'Single-bit ECC',
                'Installed Size' => '16 KB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'L1 Cache for CPU#1',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'Installed SRAM Type' => 'Burst Pipeline Burst',
                'System Type' => 'Data',
                'Associativity' => '4-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '16 KB'
            },
            {
                'Error Correction Type' => 'Single-bit ECC',
                'Installed Size' => '1024 KB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'L2 Cache for CPU#1',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Installed SRAM Type' => 'Burst',
                'System Type' => 'Unified',
                'Associativity' => '4-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '2048 KB'
            },
            {
                'Error Correction Type' => 'Single-bit ECC',
                'Installed Size' => '16 KB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'L1 Cache for CPU#2',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'Installed SRAM Type' => 'Burst Pipeline Burst',
                'System Type' => 'Data',
                'Associativity' => '4-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '16 KB'
            },
            {
                'Error Correction Type' => 'Single-bit ECC',
                'Installed Size' => '1024 KB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'L2 Cache for CPU#2',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Installed SRAM Type' => 'Burst',
                'System Type' => 'Unified',
                'Associativity' => '4-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '2048 KB'
            }
        ],
        9 => [
            {
                ID             => '1',
                'Length' => 'Other',
                'Designation' => 'PCIE Slot #1',
                'Type' => 'PCI',
                'Current Usage' => 'Available'
            },
            {
                ID             => '2',
                'Length' => 'Short',
                'Designation' => 'PCI/33 Slot #2',
                'Type' => '32-bit PCI',
                'Current Usage' => 'Available'
            },
            {
                ID             => '3',
                'Length' => 'Short',
                'Designation' => 'PCI/33 Slot #3',
                'Type' => '32-bit PCI',
                'Current Usage' => 'Available'
            },
            {
                ID             => '4',
                'Length' => 'Long',
                'Designation' => 'PCIX 133 Slot #4',
                'Type' => '64-bit PCI-X',
                'Current Usage' => 'Available'
            },
            {
                ID             => '5',
                'Length' => 'Long',
                'Designation' => 'PCIX100(ZCR) Slot #5',
                'Type' => '64-bit PCI-X',
                'Current Usage' => 'Available'
            },
            {
                ID             => '6',
                'Length' => 'Long',
                'Designation' => 'PCIX100 Slot #6',
                'Type' => '64-bit PCI-X',
                'Current Usage' => 'Available'
            }
        ],
        17 => [
            {
                 'Part Number' => 'M3 93T6553BZ3-CCC',
                 'Bank Locator' => 'BANK 1',
                 'Serial Number' => '460360BB',
                 'Data Width' => '64 bits',
                 'Array Handle' => '0x0022',
                 'Type Detail' => 'Synchronous',
                 'Set' => '1',
                 'Asset Tag' => '3342',
                 'Total Width' => '72 bits',
                 'Type' => 'DDR',
                 'Speed' => '400 MHz (2.5 ns)',
                 'Size' => '512 MB',
                 'Error Information Handle' => 'No Error',
                 'Locator' => 'DIMM 1',
                 'Form Factor' => 'DIMM'
            },
            {
                 'Part Number' => 'M3 93T6553BZ3-CCC',
                 'Bank Locator' => 'BANK 1',
                 'Serial Number' => '460360E8',
                 'Data Width' => '64 bits',
                 'Array Handle' => '0x0022',
                 'Type Detail' => 'Synchronous',
                 'Set' => '1',
                 'Asset Tag' => '3342',
                 'Total Width' => '72 bits',
                 'Type' => 'DDR',
                 'Speed' => '400 MHz (2.5 ns)',
                 'Size' => '512 MB',
                 'Error Information Handle' => 'No Error',
                 'Locator' => 'DIMM 2',
                 'Form Factor' => 'DIMM'
            },
            {
                'Array Handle' => '0x0022',
                'Error Information Handle' => 'No Error',
                'Total Width' => '72 bits',
                'Data Width' => '64 bits',
                'Size' => '512 MB',
                'Form Factor' => 'DIMM',
                'Set' => '2',
                'Locator' => 'DIMM 3',
                'Bank Locator' => 'BANK 2',
                'Type' => 'DDR',
                'Type Detail' => 'Synchronous',
                'Speed' => '400 MHz (2.5 ns)',
            }
        ],
        12 => [
            {
                 'Option 1' => 'JCMOS1: 1-2 Keep CMOS Data(Default), 2-3 Clear CMOS Data (make sure the AC power cord(s) is(are) removed from the system)'
            },
            {
                 'Option 1' => 'JCON1: 1-2 Normal(Default), 2-3 Configuration, No Jumper - BIOS Crisis Recovery'
            }
        ],
        2 => [
            {
                'Version' => 'Not Applicable',
                'Product Name' => 'MSI-9151 Boards',
                'Serial Number' => '#A123456789',
                'Manufacturer' => 'IBM'
            }
        ],
        15 => [
            {
                 'Access Method' => 'General-pupose non-volatile data functions',
                 'Data Start Offset' => '0x0010',
                 'Status' => 'Valid, Not Full',
                 'Supported Log Type Descriptors' => '3',
                 'Descriptor 1' => 'POST error',
                 'Area Length' => '320 bytes',
                 'Header Start Offset' => '0x0000',
                 'Header Format' => 'Type 1',
                 'Access Address' => '0x0000',
                 'Data Format 1' => 'POST results bitmap',
                 'Descriptor 3' => 'Multi-bit ECC memory error',
                 'Header Length' => '16 bytes',
                 'Change Token' => '0x00000013',
                 'Data Format 2' => 'Multiple-event',
                 'Descriptor 2' => 'Single-bit ECC memory error',
                 'Data Format 3' => 'Multiple-event'
            }
        ],
        8 => [
            {
                'External Reference Designator' => 'COM 1',
                'Port Type' => 'Serial Port 16550A Compatible',
                'External Connector Type' => 'DB-9 male',
                'Internal Reference Designator' => 'J2A1',
                'Internal Connector Type' => '9 Pin Dual Inline (pin 10 cut)'
            },
            {
                'External Reference Designator' => 'COM 2',
                'Port Type' => 'Serial Port 16550A Compatible',
                'External Connector Type' => 'DB-9 male',
                'Internal Reference Designator' => 'J2A2',
                'Internal Connector Type' => '9 Pin Dual Inline (pin 10 cut)'
            },
            {
                'External Reference Designator' => 'Parallel',
                'Port Type' => 'Parallel Port ECP/EPP',
                'External Connector Type' => 'DB-25 female',
                'Internal Reference Designator' => 'J3A1',
                'Internal Connector Type' => '25 Pin Dual Inline (pin 26 cut)'
            },
            {
                'External Reference Designator' => 'Keyboard',
                'Port Type' => 'Keyboard Port',
                'External Connector Type' => 'Circular DIN-8 male',
                'Internal Reference Designator' => 'J1A1',
            },
            {
                'External Reference Designator' => 'PS/2 Mouse',
                'Port Type' => 'Keyboard Port',
                'External Connector Type' => 'Circular DIN-8 male',
                'Internal Reference Designator' => 'J1A1',
            }
        ],
        1 => [
            {
                'Version' => 'Not Applicable',
                'Wake-up Type' => 'Power Switch',
                'Product Name' => 'IBM eServer x226-[8488PCR]-',
                'Serial Number' => 'KDXPC16',
                'Manufacturer' => 'IBM',
                'UUID' => 'A8346631-8E88-3AE3-898C-F3AC9F61C316'
            }
        ],
        4 => [
            {
                ID             => '41 0F 00 00 FF FB EB BF',
                'Socket Designation' => 'CPU#1',
                'Status' => 'Populated, Enabled',
                'Max Speed' => '3600 MHz',
                'External Clock' => '200 MHz',
                'Family' => 'Xeon MP',
                'Current Speed' => '2800 MHz',
                'L2 Cache Handle' => '0x0007',
                'Type' => 'Central Processor',
                'Signature' => 'Type 0, Family F, Model 4, Stepping 1',
                'Version' => 'Intel(R) Xeon(TM) CPU 2.80GHz',
                'Upgrade' => 'ZIF Socket',
                'L1 Cache Handle' => '0x0006',
                'Voltage' => '1.3 V',
                'Manufacturer' => 'Intel Corporation',
                'L3 Cache Handle' => 'Not Provided'
            },
            {
                ID             => '41 0F 00 00 FF FB EB BF',
                'Socket Designation' => 'CPU#2',
                'Status' => 'Populated, Enabled',
                'Max Speed' => '3600 MHz',
                'External Clock' => '200 MHz',
                'Family' => 'Xeon MP',
                'Current Speed' => '2800 MHz',
                'L2 Cache Handle' => '0x000A',
                'Type' => 'Central Processor',
                'Signature' => 'Type 0, Family F, Model 4, Stepping 1',
                'Version' => 'Intel(R) Xeon(TM) CPU 2.80GHz',
                'Upgrade' => 'ZIF Socket',
                'L1 Cache Handle' => '0x0009',
                'Voltage' => '1.3 V',
                'Manufacturer' => 'Intel Corporation',
                'L3 Cache Handle' => 'Not Provided'
            }
        ],
        0 => [
            {
                'Runtime Size' => '130064 bytes',
                'Version' => 'IBM BIOS Version 1.57-[PME157AUS-1.57]-',
                'Address' => '0xE03F0',
                'ROM Size' => '1024 kB',
                'Release Date' => '08/25/2005',
                'Vendor' => 'IBM'
            }
        ],
        16 => [
            {
                 'Number Of Devices' => '6',
                 'Error Correction Type' => 'Single-bit ECC',
                 'Error Information Handle' => 'No Error',
                 'Location' => 'System Board Or Motherboard',
                 'Maximum Capacity' => '16 GB',
                 'Use' => 'System Memory'
            }
        ],
        13 => [
            {
                 'Installable Languages' => '1',
                 'Currently Installed Language' => 'en|US|iso8859-1'
            }
        ],
        10 => [
            {
                 'Type' => 'Other',
                 'Status' => 'Enabled',
                 'Description' => 'IBM Automatic Server Restart - Machine Type 8648'
            },
            {
                 'Type' => 'Video',
                 'Status' => 'Enabled',
                 'Description' => 'ATI Rage 7000'
            },
            {
                 'Type' => 'SCSI Controller',
                 'Status' => 'Enabled',
                 'Description' => 'Adaptec AIC 7902'
            },
            {
                 'Type' => 'Ethernet',
                 'Status' => 'Enabled',
                 'Description' => 'BoardCom BCM5721'
            }
        ]
    },
    'rhel-4.3' => {
        32 => [
            {
                 'Status' => 'No errors detected'
            }
        ],
        7 => [
            {
                'Installed Size' => '20 KB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'Level 1 Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'Installed SRAM Type' => 'Synchronous',
                'Location' => 'Internal',
                'Maximum Size' => '20 KB'
            },
            {
                'Installed Size' => '20 KB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'Level 1 Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'Installed SRAM Type' => 'Synchronous',
                'Location' => 'Internal',
                'Maximum Size' => '20 KB'
            },
            {
                'Installed Size' => '512 KB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'Level 2 Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Installed SRAM Type' => 'Synchronous',
                'Location' => 'Internal',
                'Maximum Size' => '512 KB'
            },
            {
                'Installed Size' => '512 KB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'Level 2 Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Installed SRAM Type' => 'Synchronous',
                'Location' => 'Internal',
                'Maximum Size' => '512 KB'
            },
            {
                'Installed Size' => '0 KB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'Tertiary (Level 3) Cache',
                'Configuration' => 'Disabled, Not Socketed, Level 3',
                'Installed SRAM Type' => 'Synchronous',
                'Location' => 'Internal',
                'Maximum Size' => '0 KB'
            },
            {
                'Installed Size' => '0 KB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'Tertiary (Level 3) Cache',
                'Configuration' => 'Disabled, Not Socketed, Level 3',
                'Installed SRAM Type' => 'Synchronous',
                'Location' => 'Internal',
                'Maximum Size' => '0 KB'
            }
        ],
        17 => [
            {
                 'Bank Locator' => 'Bank0',
                 'Data Width' => '256 bits',
                 'Array Handle' => '0x0028',
                 'Set' => '1',
                 'Total Width' => '257 bits',
                 'Type' => 'DDR',
                 'Size' => '512 MB',
                 'Error Information Handle' => '0x002D',
                 'Locator' => 'DIMM1',
                 'Form Factor' => 'DIMM'
            },
            {
                 'Bank Locator' => 'Bank1',
                 'Data Width' => '256 bits',
                 'Array Handle' => '0x0028',
                 'Set' => '1',
                 'Total Width' => '257 bits',
                 'Type' => 'DDR',
                 'Size' => '512 MB',
                 'Error Information Handle' => '0x002E',
                 'Locator' => 'DIMM2',
                 'Form Factor' => 'DIMM'
            },
            {
                 'Bank Locator' => 'Bank2',
                 'Data Width' => '256 bits',
                 'Array Handle' => '0x0028',
                 'Set' => '2',
                 'Total Width' => '257 bits',
                 'Type' => 'DDR',
                 'Size' => '512 MB',
                 'Error Information Handle' => '0x002F',
                 'Locator' => 'DIMM3',
                 'Form Factor' => 'DIMM'
            },
            {
                 'Bank Locator' => 'Bank3',
                 'Data Width' => '256 bits',
                 'Array Handle' => '0x0028',
                 'Set' => '2',
                 'Total Width' => '257 bits',
                 'Type' => 'DDR',
                 'Size' => '512 MB',
                 'Error Information Handle' => '0x0030',
                 'Locator' => 'DIMM4',
                 'Form Factor' => 'DIMM'
            }
        ],
        2 => [
            {
                'Version' => '2.0',
                'Product Name' => 'MS-9121',
                'Serial Number' => '48Z1LX',
                'Manufacturer' => 'IBM'
            }
        ],
        1 => [
            {
                'Version' => '2.0',
                'Wake-up Type' => 'Other',
                'Product Name' => '-[86494jg]-',
                'Serial Number' => 'KDMAH1Y',
                'Manufacturer' => 'IBM',
                'UUID' => '0339D4C3-44C0-9D11-A20E-85CDC42DE79C'
            }
        ],
        18 => [
            {
                 'Granularity' => 'Other',
                 'Type' => 'Other',
                 'Operation' => 'Other'
            },
            {
                 'Granularity' => 'Other',
                 'Type' => 'Other',
                 'Operation' => 'Other'
            },
            {
                 'Granularity' => 'Other',
                 'Type' => 'Other',
                 'Operation' => 'Other'
            },
            {
                 'Granularity' => 'Other',
                 'Type' => 'Other',
                 'Operation' => 'Other'
            }
        ],
        0 => [
            {
                'Runtime Size' => '128 kB',
                'Version' => '-[OQE115A]-',
                'Address' => '0xE0000',
                'ROM Size' => '1024 kB',
                'Release Date' => '03/14/2006',
                'Vendor' => 'IBM'
            }
        ],
        16 => [
            {
                 'Number Of Devices' => '4',
                 'Error Correction Type' => 'Multi-bit ECC',
                 'Error Information Handle' => 'No Error',
                 'Location' => 'System Board Or Motherboard',
                 'Maximum Capacity' => '8 GB',
                 'Use' => 'System Memory'
            }
        ],
        13 => [
            {
                 'Installable Languages' => '3',
                 'Currently Installed Language' => 'n|US|iso8859-1'
            }
        ],
        6 => [
            {
                'Installed Size' => '512 MB (Single-bank Connection)',
                'Socket Designation' => 'DIMM1',
                'Type' => 'Other DIMM',
                'Error Status' => 'OK',
                'Enabled Size' => '512 MB (Single-bank Connection)',
                'Bank Connections' => '0'
            },
            {
                'Installed Size' => '512 MB (Single-bank Connection)',
                'Socket Designation' => 'DIMM2',
                'Type' => 'Other DIMM',
                'Error Status' => 'OK',
                'Enabled Size' => '512 MB (Single-bank Connection)',
                'Bank Connections' => '2'
            },
            {
                'Installed Size' => '512 MB (Single-bank Connection)',
                'Socket Designation' => 'DIMM3',
                'Type' => 'Other DIMM',
                'Error Status' => 'OK',
                'Enabled Size' => '512 MB (Single-bank Connection)',
                'Bank Connections' => '4'
            },
            {
                'Installed Size' => '512 MB (Single-bank Connection)',
                'Socket Designation' => 'DIMM4',
                'Type' => 'Other DIMM',
                'Error Status' => 'OK',
                'Enabled Size' => '512 MB (Single-bank Connection)',
                'Bank Connections' => '6'
            }
        ],
        3 => [
            {
                'Type' => 'Tower',
                'Lock' => 'Present',
                'Manufacturer' => 'IBM'
            }
        ],
        9 => [
            {
                ID             => '1',
                'Length' => 'Other',
                'Designation' => 'PCI1',
                'Type' => '32-bit PCI',
                'Current Usage' => 'Available'
            },
            {
                ID             => '2',
                'Length' => 'Other',
                'Designation' => 'PCI6',
                'Type' => '32-bit PCI',
                'Current Usage' => 'In Use'
            },
            {
                ID             => '8',
                'Length' => 'Long',
                'Designation' => 'AGP',
                'Type' => '32-bit AGP',
                'Current Usage' => 'Available'
            },
            {
                ID             => '2',
                'Length' => 'Long',
                'Designation' => 'PCI2',
                'Type' => '64-bit PCI-X',
                'Current Usage' => 'Available'
            },
            {
                ID             => '3',
                'Length' => 'Long',
                'Designation' => 'PCI3',
                'Type' => '64-bit PCI-X',
                'Current Usage' => 'Available'
            },
            {
                ID             => '1',
                'Length' => 'Long',
                'Designation' => 'PCI4',
                'Type' => '64-bit PCI-X',
                'Current Usage' => 'In Use'
            },
            {
                ID             => '2',
                'Length' => 'Long',
                'Designation' => 'PCI5',
                'Type' => '64-bit PCI-X',
                'Current Usage' => 'Available'
            }
        ],
        20 => [
            {
                 'Memory Array Mapped Address Handle' => '0x0031',
                 'Range Size' => '512 MB',
                 'Physical Device Handle' => '0x0029',
                 'Partition Row Position' => '1',
                 'Starting Address' => '0x00000000000',
                 'Ending Address' => '0x0001FFFFFFF'
            },
            {
                 'Memory Array Mapped Address Handle' => '0x0031',
                 'Range Size' => '512 MB',
                 'Physical Device Handle' => '0x002A',
                 'Partition Row Position' => '1',
                 'Starting Address' => '0x00020000000',
                 'Ending Address' => '0x0003FFFFFFF'
            },
            {
                 'Memory Array Mapped Address Handle' => '0x0031',
                 'Range Size' => '512 MB',
                 'Physical Device Handle' => '0x002B',
                 'Partition Row Position' => '1',
                 'Starting Address' => '0x00040000000',
                 'Ending Address' => '0x0005FFFFFFF'
            },
            {
                 'Memory Array Mapped Address Handle' => '0x0031',
                 'Range Size' => '512 MB',
                 'Physical Device Handle' => '0x002C',
                 'Partition Row Position' => '1',
                 'Starting Address' => '0x00060000000',
                 'Ending Address' => '0x0007FFFFFFF'
            }
        ],
        8 => [
            {
                'Port Type' => 'Other',
                'Internal Reference Designator' => 'IDE1',
                'Internal Connector Type' => 'On Board IDE'
            },
            {
                'Port Type' => 'Other',
                'Internal Reference Designator' => 'IDE2',
                'Internal Connector Type' => 'On Board IDE'
            },
            {
                'Port Type' => '8251 FIFO Compatible',
                'Internal Reference Designator' => 'FDD',
                'Internal Connector Type' => 'On Board Floppy'
            },
            {
                'Port Type' => 'Serial Port 16450 Compatible',
                'External Connector Type' => 'DB-9 male',
                'Internal Reference Designator' => 'COM1',
                'Internal Connector Type' => '9 Pin Dual Inline (pin 10 cut)'
            },
            {
                'Port Type' => 'Serial Port 16450 Compatible',
                'External Connector Type' => 'DB-9 male',
                'Internal Reference Designator' => 'COM2',
                'Internal Connector Type' => '9 Pin Dual Inline (pin 10 cut)'
            },
            {
                'Port Type' => 'Parallel Port ECP/EPP',
                'External Connector Type' => 'DB-25 female',
                'Internal Reference Designator' => 'LPT1',
                'Internal Connector Type' => 'DB-25 female'
            },
            {
                'Port Type' => 'Keyboard Port',
                'External Connector Type' => 'PS/2',
                'Internal Reference Designator' => 'Keyboard',
                'Internal Connector Type' => 'PS/2'
            },
            {
                'Port Type' => 'Mouse Port',
                'External Connector Type' => 'PS/2',
                'Internal Reference Designator' => 'PS/2 Mouse',
                'Internal Connector Type' => 'PS/2'
            },
            {
                'External Reference Designator' => 'JUSB1',
                'Port Type' => 'USB',
                'External Connector Type' => 'Other',
            },
            {
                'External Reference Designator' => 'JUSB2',
                'Port Type' => 'USB',
                'External Connector Type' => 'Other',
            },
            {
                'External Reference Designator' => 'AUD1',
                'Port Type' => 'Audio Port',
            },
            {
                'External Reference Designator' => 'JLAN1',
                'Port Type' => 'Network Port',
                'External Connector Type' => 'RJ-45',
            },
            {
                'External Reference Designator' => 'SCSI1',
                'Port Type' => 'SCSI Wide',
            },
            {
                'External Reference Designator' => 'SCSI2',
                'Port Type' => 'SCSI Wide',
            }
        ],
        4 => [
            {
                ID             => '29 0F 00 00 FF FB EB BF',
                'Socket Designation' => 'CPU1',
                'Status' => 'Populated, Enabled',
                'Max Speed' => '3200 MHz',
                'External Clock' => '133 MHz',
                'Family' => 'Xeon',
                'Current Speed' => '2666 MHz',
                'L2 Cache Handle' => '0x000D',
                'Type' => 'Central Processor',
                'Signature' => 'Type 0, Family F, Model 2, Stepping 9',
                'Version' => 'Intel Xeon(tm)',
                'Upgrade' => 'ZIF Socket',
                'L1 Cache Handle' => '0x000B',
                'Voltage' => '1.4 V',
                'Manufacturer' => 'Intel',
                'L3 Cache Handle' => '0x000F'
            },
            {
                ID             => '29 0F 00 00 FF FB EB BF',
                'Socket Designation' => 'CPU2',
                'Status' => 'Populated, Enabled',
                'Max Speed' => '3200 MHz',
                'External Clock' => '133 MHz',
                'Family' => 'Xeon',
                'Current Speed' => '2666 MHz',
                'L2 Cache Handle' => '0x000E',
                'Type' => 'Central Processor',
                'Signature' => 'Type 0, Family F, Model 2, Stepping 9',
                'Version' => 'Intel Xeon(tm)',
                'Upgrade' => 'ZIF Socket',
                'L1 Cache Handle' => '0x000C',
                'Voltage' => '1.4 V',
                'Manufacturer' => 'Intel',
                'L3 Cache Handle' => '0x0010'
            }
        ],
        10 => [
            {
                 'Type' => 'Sound',
                 'Status' => 'Enabled',
                 'Description' => 'SoundMax Integrated Digital Audio - AUD1'
            }
        ],
        19 => [
            {
                 'Range Size' => '2 GB',
                 'Partition Width' => '0',
                 'Starting Address' => '0x00000000000',
                 'Physical Array Handle' => '0x0028',
                 'Ending Address' => '0x0007FFFFFFF'
            }
        ],
        5 => [
            {
                'Error Detecting Method' => '8-bit Parity',
                'Maximum Total Memory Size' => '8192 MB',
                'Supported Interleave' => 'One-way Interleave',
                'Maximum Memory Module Size' => '2048 MB',
                'Associated Memory Slots' => '4',
                'Current Interleave' => 'One-way Interleave',
                'Memory Module Voltage' => '3.3 V'
            }
        ]
    },
    'rhel-5.6' => {
        11 => [
            {
                'String 2' => '5[0000]',
                'String 1' => 'Dell System'
            }
        ],
        17 => [
            {
                'Type' => 'DDR3',
                'Error Information Handle' => 'Not Provided',
                'Size' => 'No Module Installed',
                'Data Width' => '64 bits',
                'Total Width' => '72 bits',
                'Set' => '1',
                'Array Handle' => '0x1000',
                'Type Detail' => 'Synchronous',
                'Form Factor' => 'DIMM',
                'Locator' => 'DIMM_A1'
            },
            {
                'Rank' => '1',
                'Error Information Handle' => 'Not Provided',
                'Data Width' => '64 bits',
                'Serial Number' => '2AA3F87D',
                'Type' => 'DDR3',
                'Form Factor' => 'DIMM',
                'Part Number' => 'HMT325R7BFR8C-H9',
                'Set' => '1',
                'Asset Tag' => '01110228',
                'Array Handle' => '0x1000',
                'Total Width' => '72 bits',
                'Size' => '2048 MB',
                'Speed' => '1333 MHz',
                'Locator' => 'DIMM_A2',
                'Type Detail' => 'Synchronous',
                'Manufacturer' => '00AD009780AD'
            },
            {
                'Locator' => 'DIMM_A3',
                'Type Detail' => 'Synchronous',
                'Manufacturer' => '00AD009780AD',
                'Total Width' => '72 bits',
                'Speed' => '1333 MHz',
                'Size' => '2048 MB',
                'Form Factor' => 'DIMM',
                'Part Number' => 'HMT325R7BFR8C-H9',
                'Set' => '2',
                'Array Handle' => '0x1000',
                'Asset Tag' => '01110228',
                'Rank' => '1',
                'Error Information Handle' => 'Not Provided',
                'Data Width' => '64 bits',
                'Serial Number' => '2A33F897',
                'Type' => 'DDR3'
            },
            {
                'Type' => 'DDR3',
                'Error Information Handle' => 'Not Provided',
                'Size' => 'No Module Installed',
                'Data Width' => '64 bits',
                'Total Width' => '72 bits',
                'Set' => '2',
                'Array Handle' => '0x1000',
                'Type Detail' => 'Synchronous',
                'Form Factor' => 'DIMM',
                'Locator' => 'DIMM_A4'
            },
            {
                'Error Information Handle' => 'Not Provided',
                'Data Width' => '64 bits',
                'Size' => 'No Module Installed',
                'Type' => 'DDR3',
                'Total Width' => '72 bits',
                'Set' => '3',
                'Array Handle' => '0x1000',
                'Locator' => 'DIMM_A5',
                'Type Detail' => 'Synchronous',
                'Form Factor' => 'DIMM'
            },
            {
                'Total Width' => '72 bits',
                'Error Information Handle' => 'Not Provided',
                'Size' => 'No Module Installed',
                'Data Width' => '64 bits',
                'Type' => 'DDR3',
                'Locator' => 'DIMM_A6',
                'Type Detail' => 'Synchronous',
                'Form Factor' => 'DIMM',
                'Set' => '3',
                'Array Handle' => '0x1000'
            },
            {
                'Locator' => 'DIMM_A7',
                'Type Detail' => 'Synchronous',
                'Form Factor' => 'DIMM',
                'Set' => '4',
                'Array Handle' => '0x1000',
                'Total Width' => '72 bits',
                'Error Information Handle' => 'Not Provided',
                'Data Width' => '64 bits',
                'Size' => 'No Module Installed',
                'Type' => 'DDR3'
            },
            {
                'Form Factor' => 'DIMM',
                'Type Detail' => 'Synchronous',
                'Locator' => 'DIMM_A8',
                'Array Handle' => '0x1000',
                'Set' => '4',
                'Total Width' => '72 bits',
                'Type' => 'DDR3',
                'Data Width' => '64 bits',
                'Size' => 'No Module Installed',
                'Error Information Handle' => 'Not Provided'
            },
            {
                'Type' => 'DDR3',
                'Error Information Handle' => 'Not Provided',
                'Size' => 'No Module Installed',
                'Data Width' => '64 bits',
                'Total Width' => '72 bits',
                'Set' => '5',
                'Array Handle' => '0x1000',
                'Type Detail' => 'Synchronous',
                'Form Factor' => 'DIMM',
                'Locator' => 'DIMM_A9'
            },
            {
                'Total Width' => '72 bits',
                'Type' => 'DDR3',
                'Data Width' => '64 bits',
                'Size' => 'No Module Installed',
                'Error Information Handle' => 'Not Provided',
                'Form Factor' => 'DIMM',
                'Type Detail' => 'Synchronous',
                'Locator' => 'DIMM_B1',
                'Array Handle' => '0x1000',
                'Set' => '5'
            },
            {
                'Type Detail' => 'Synchronous',
                'Locator' => 'DIMM_B2',
                'Manufacturer' => '00AD009780AD',
                'Total Width' => '72 bits',
                'Speed' => '1333 MHz',
                'Size' => '2048 MB',
                'Form Factor' => 'DIMM',
                'Part Number' => 'HMT325R7BFR8C-H9',
                'Array Handle' => '0x1000',
                'Asset Tag' => '01110228',
                'Set' => '6',
                'Rank' => '1',
                'Type' => 'DDR3',
                'Serial Number' => '2A43F870',
                'Data Width' => '64 bits',
                'Error Information Handle' => 'Not Provided'
            },
            {
                'Total Width' => '72 bits',
                'Speed' => '1333 MHz',
                'Size' => '2048 MB',
                'Type Detail' => 'Synchronous',
                'Locator' => 'DIMM_B3',
                'Manufacturer' => '00AD009780AD',
                'Rank' => '1',
                'Serial Number' => '2A93F87A',
                'Type' => 'DDR3',
                'Data Width' => '64 bits',
                'Error Information Handle' => 'Not Provided',
                'Form Factor' => 'DIMM',
                'Part Number' => 'HMT325R7BFR8C-H9',
                'Asset Tag' => '01110228',
                'Array Handle' => '0x1000',
                'Set' => '6'
            },
            {
                'Size' => 'No Module Installed',
                'Data Width' => '64 bits',
                'Error Information Handle' => 'Not Provided',
                'Type' => 'DDR3',
                'Total Width' => '72 bits',
                'Array Handle' => '0x1000',
                'Set' => '4',
                'Locator' => 'DIMM_B4',
                'Form Factor' => 'DIMM',
                'Type Detail' => 'Synchronous'
            },
            {
                'Type' => 'DDR3',
                'Data Width' => '64 bits',
                'Size' => 'No Module Installed',
                'Error Information Handle' => 'Not Provided',
                'Total Width' => '72 bits',
                'Array Handle' => '0x1000',
                'Set' => '5',
                'Form Factor' => 'DIMM',
                'Type Detail' => 'Synchronous',
                'Locator' => 'DIMM_B5'
            },
            {
                'Total Width' => '72 bits',
                'Error Information Handle' => 'Not Provided',
                'Size' => 'No Module Installed',
                'Data Width' => '64 bits',
                'Type' => 'DDR3',
                'Locator' => 'DIMM_B6',
                'Type Detail' => 'Synchronous',
                'Form Factor' => 'DIMM',
                'Set' => '6',
                'Array Handle' => '0x1000'
            },
            {
                'Locator' => 'DIMM_B7',
                'Type Detail' => 'Synchronous',
                'Form Factor' => 'DIMM',
                'Set' => '4',
                'Array Handle' => '0x1000',
                'Total Width' => '72 bits',
                'Error Information Handle' => 'Not Provided',
                'Data Width' => '64 bits',
                'Size' => 'No Module Installed',
                'Type' => 'DDR3'
            },
            {
                'Array Handle' => '0x1000',
                'Set' => '5',
                'Form Factor' => 'DIMM',
                'Type Detail' => 'Synchronous',
                'Locator' => 'DIMM_B8',
                'Type' => 'DDR3',
                'Data Width' => '64 bits',
                'Size' => 'No Module Installed',
                'Error Information Handle' => 'Not Provided',
                'Total Width' => '72 bits'
            },
            {
                'Total Width' => '72 bits',
                'Data Width' => '64 bits',
                'Size' => 'No Module Installed',
                'Error Information Handle' => 'Not Provided',
                'Type' => 'DDR3',
                'Locator' => 'DIMM_B9',
                'Form Factor' => 'DIMM',
                'Type Detail' => 'Synchronous',
                'Array Handle' => '0x1000',
                'Set' => '6'
            }
        ],
        0 => [
            {
                'ROM Size' => '4096 kB',
                'Vendor' => 'Dell Inc.',
                'Runtime Size' => '64 kB',
                'Version' => '2.2.10',
                'Release Date' => '11/09/2010',
                'BIOS Revision' => '2.2',
                'Address' => '0xF0000'
            }
        ],
        4 => [
            {
                'Core Enabled' => '4',
                'Family' => 'Xeon',
                'Current Speed' => '2400 MHz',
                'Socket Designation' => 'CPU1',
                'L2 Cache Handle' => '0x0701',
                'L3 Cache Handle' => '0x0702',
                'Manufacturer' => 'Intel',
                'Status' => 'Populated, Enabled',
                'ID' => 'C2 06 02 00 FF FB EB BF',
                'Thread Count' => '8',
                'Version' => 'Intel(R) Xeon(R) CPU E5620 @ 2.40GHz',
                'Voltage' => '1.2 V',
                'Upgrade' => 'Socket LGA1366',
                'Signature' => 'Type 0, Family 6, Model 44, Stepping 2',
                'External Clock' => '5860 MHz',
                'Type' => 'Central Processor',
                'Max Speed' => '3600 MHz',
                'Core Count' => '4',
                'L1 Cache Handle' => '0x0700'
            },
            {
                'Current Speed' => '2400 MHz',
                'Socket Designation' => 'CPU2',
                'Manufacturer' => 'Intel',
                'Status' => 'Populated, Idle',
                'L3 Cache Handle' => '0x0705',
                'L2 Cache Handle' => '0x0704',
                'Thread Count' => '8',
                'ID' => 'C2 06 02 00 FF FB EB BF',
                'Family' => 'Xeon',
                'Core Enabled' => '4',
                'Core Count' => '4',
                'L1 Cache Handle' => '0x0703',
                'Version' => 'Intel(R) Xeon(R) CPU E5620 @ 2.40GHz',
                'Upgrade' => 'Socket LGA1366',
                'Voltage' => '1.2 V',
                'External Clock' => '5860 MHz',
                'Signature' => 'Type 0, Family 6, Model 44, Stepping 2',
                'Max Speed' => '3600 MHz',
                'Type' => 'Central Processor'
            }
        ],
        7 => [
            {
                'Error Correction Type' => 'Single-bit ECC',
                'System Type' => 'Data',
                'Operational Mode' => 'Write Back',
                'Associativity' => '8-way Set-associative',
                'Location' => 'Internal',
                'Installed Size' => '128 kB',
                'Maximum Size' => '128 kB',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
            },
            {
                'Error Correction Type' => 'Single-bit ECC',
                'System Type' => 'Unified',
                'Associativity' => '8-way Set-associative',
                'Operational Mode' => 'Write Back',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Installed Size' => '1024 kB',
                'Maximum Size' => '2048 kB',
                'Location' => 'Internal'
            },
            {
                'Error Correction Type' => 'Single-bit ECC',
                'System Type' => 'Unified',
                'Operational Mode' => 'Write Back',
                'Associativity' => '16-way Set-associative',
                'Location' => 'Internal',
                'Installed Size' => '12288 kB',
                'Maximum Size' => '12288 kB',
                'Configuration' => 'Enabled, Not Socketed, Level 3',
            },
            {
                'System Type' => 'Data',
                'Error Correction Type' => 'Single-bit ECC',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'Installed Size' => '128 kB',
                'Maximum Size' => '128 kB',
                'Location' => 'Internal',
                'Associativity' => '8-way Set-associative',
                'Operational Mode' => 'Write Back'
            },
            {
                'System Type' => 'Unified',
                'Error Correction Type' => 'Single-bit ECC',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Location' => 'Internal',
                'Maximum Size' => '2048 kB',
                'Installed Size' => '1024 kB',
                'Associativity' => '8-way Set-associative',
                'Operational Mode' => 'Write Back'
            },
            {
                'Configuration' => 'Enabled, Not Socketed, Level 3',
                'Location' => 'Internal',
                'Installed Size' => '12288 kB',
                'Maximum Size' => '12288 kB',
                'Associativity' => '16-way Set-associative',
                'Operational Mode' => 'Write Back',
                'System Type' => 'Unified',
                'Error Correction Type' => 'Single-bit ECC'
            }
        ],
        10 => [
            {
                'Status' => 'Enabled',
                'Type' => 'SAS Controller',
                'Description' => 'Integrated RAID Controller'
            }
        ],
        2 => [
            {
                'Version' => 'A07',
                'Serial Number' => '..CN708210BL002B.',
                'Product Name' => '0MD99X',
                'Manufacturer' => 'Dell Inc.'
            }
        ],
        13 => [
            {
                'Installable Languages' => '1',
                'Currently Installed Language' => 'en|US|iso8859-1'
            }
        ],
        12 => [
            {
                'Option 1' => 'NVRAM_CLR: Clear user settable NVRAM areas and set defaults',
                'Option 2' => 'PWRD_EN: Close to enable password'
            }
        ],
        1 => [
            {
                'Manufacturer' => 'Dell Inc.',
                'Product Name' => 'PowerEdge R710',
                'Serial Number' => '861YZ4J',
                'UUID' => '4C4C4544-0036-3110-8059-B8C04F5A344A',
                'Wake-up Type' => 'Power Switch'
            }
        ],
        16 => [
            {
                'Number Of Devices' => '18',
                'Location' => 'System Board Or Motherboard',
                'Error Information Handle' => 'Not Provided',
                'Maximum Capacity' => '288 GB',
                'Use' => 'System Memory',
                'Error Correction Type' => 'Multi-bit ECC'
            }
        ],
        3 => [
            {
                'Number Of Power Cords' => 'Unspecified',
                'Thermal State' => 'Safe',
                'Height' => '2 U',
                'Manufacturer' => 'Dell Inc.',
                'Boot-up State' => 'Safe',
                'OEM Information' => '0x00000000',
                'Type' => 'Rack Mount Chassis',
                'Serial Number' => '861YZ4J',
                'Contained Elements' => '0',
                'Power Supply State' => 'Safe',
                'Lock' => 'Present'
            }
        ],
        8 => [
            {
                'Port Type' => 'Video Port',
                'External Connector Type' => 'DB-15 female',
            },
            {
                'Port Type' => 'Video Port',
                'External Connector Type' => 'DB-15 female'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'Port Type' => 'USB',
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'Port Type' => 'USB',
            },
            {
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)'
            },
            {
                'Port Type' => 'USB',
                'Internal Reference Designator' => 'INT_USB',
                'Internal Connector Type' => 'Access Bus (USB)'
            },
            {
                'Internal Connector Type' => 'Other',
                'Port Type' => 'USB',
                'Internal Reference Designator' => 'INT_SD'
            },
            {
                'External Connector Type' => 'RJ-45',
                'Port Type' => 'Network Port',
            },
            {
                'External Connector Type' => 'RJ-45',
                'Port Type' => 'Network Port',
            },
            {
                'External Connector Type' => 'RJ-45',
                'Port Type' => 'Network Port',
            },
            {
                'External Connector Type' => 'RJ-45',
                'Port Type' => 'Network Port',
            },
            {
                'External Connector Type' => 'DB-9 male',
                'Port Type' => 'Serial Port 16550A Compatible',
            }
        ],
        19 => [
            {
                'Physical Array Handle' => '0x1000',
                'Partition Width' => '0',
                'Range Size' => '3328 MB',
                'Starting Address' => '0x00000000000',
                'Ending Address' => '0x000CFFFFFFF'
            },
            {
                'Starting Address' => '0x00100000000',
                'Partition Width' => '0',
                'Range Size' => '4864 MB',
                'Physical Array Handle' => '0x1000',
                'Ending Address' => '0x0022FFFFFFF'
            }
        ],
        9 => [
            {
                'Bus Address' => '0000:05:00.0',
                'Type' => 'x4 PCI Express Gen 2 x8',
                'Designation' => 'PCI1',
                'Length' => 'Long',
                'Current Usage' => 'In Use'
            },
            {
                'Designation' => 'PCI2',
                'Length' => 'Long',
                'Current Usage' => 'In Use',
                'Bus Address' => '0000:04:00.0',
                'Type' => 'x4 PCI Express Gen 2 x8'
            },
            {
                'Current Usage' => 'In Use',
                'Length' => 'Long',
                'Designation' => 'PCI3',
                'Bus Address' => '0000:07:00.0',
                'Type' => 'x8 PCI Express Gen 2'
            },
            {
                'Designation' => 'PCI4',
                'Length' => 'Long',
                'Current Usage' => 'In Use',
                'Bus Address' => '0000:06:00.0',
                'Type' => 'x8 PCI Express Gen 2'
            }
        ],
        41 => [
            {
                'Reference Designation' => 'Embedded NIC 1',
                'Status' => 'Enabled',
                'Type Instance' => '1',
                'Type' => 'Ethernet',
                'Bus Address' => '0000:01:00.0'
            },
            {
                'Bus Address' => '0000:01:00.1',
                'Type' => 'Ethernet',
                'Status' => 'Enabled',
                'Reference Designation' => 'Embedded NIC 2',
                'Type Instance' => '2'
            },
            {
                'Type' => 'Ethernet',
                'Bus Address' => '0000:02:00.0',
                'Type Instance' => '3',
                'Reference Designation' => 'Embedded NIC 3',
                'Status' => 'Enabled'
            },
            {
                'Bus Address' => '0000:02:00.1',
                'Type' => 'Ethernet',
                'Type Instance' => '4',
                'Reference Designation' => 'Embedded NIC 4',
                'Status' => 'Enabled'
            },
            {
                'Bus Address' => '0000:03:00.0',
                'Type' => 'SAS Controller',
                'Type Instance' => '4',
                'Reference Designation' => 'Integrated RAID',
                'Status' => 'Enabled'
            },
            {
                'Type Instance' => '4',
                'Reference Designation' => 'Embedded Video',
                'Status' => 'Enabled',
                'Type' => 'Video',
                'Bus Address' => '0000:08:03.0'
            }
        ],
        32 => [
            {
                'Status' => 'No errors detected'
            }
        ],
        38 => [
            {
                'Base Address' => '0x0000000000000CA8 (I/O)',
                'I2C Slave Address' => '0x10',
                'Specification Version' => '2.0',
                'Register Spacing' => '32-bit Boundaries',
                'Interface Type' => 'KCS (Keyboard Control Style)'
            }
        ]
    },
    'oracle-server-x5-2' => {
        2 => [
            {
                'Chassis Handle' => '0x0003',
                'Contained Object Handles' => '0',
                'Asset Tag' => '7317947',
                'Manufacturer' => 'Oracle Corporation',
                'Type' => 'Motherboard',
                'Serial Number' => '489089M+16324B2191',
                'Location In Chassis' => '/SYS/MB',
                'Version' => 'Rev 04',
                'Product Name' => 'ASM,MOTHERBOARD,1U'
            }
        ],
        9 => [
            {
                'Bus Address' => '0000:80:03.0',
                'Current Usage' => 'In Use',
                'Length' => 'Long',
                'Designation' => '/SYS/MB/RISER1/PCIE1',
                'Type' => 'x16 PCI Express 3'
            },
            {
                'Current Usage' => 'In Use',
                'Bus Address' => '0000:00:02.0',
                'Type' => 'x16 PCI Express 3',
                'Length' => 'Long',
                'Designation' => '/SYS/MB/RISER2/PCIE2'
            },
            {
                'Current Usage' => 'In Use',
                'Bus Address' => '0000:00:01.0',
                'Type' => 'x8 PCI Express 3',
                'Designation' => '/SYS/MB/RISER3/PCIE3',
                'Length' => 'Short'
            },
            {
                'Bus Address' => '0000:00:03.0',
                'Current Usage' => 'In Use',
                'Designation' => '/SYS/MB/RISER3/PCIE4',
                'Length' => 'Short',
                'Type' => 'x8 PCI Express 3'
            }
        ],
        20 => [
            {
                'Memory Array Mapped Address Handle' => '0x0036',
                'Starting Address' => '0x00000000000',
                'Ending Address' => '0x007FFFFFFFF',
                'Partition Row Position' => '1',
                'Physical Device Handle' => '0x0037',
                'Range Size' => '32 GB'
            },
            {
                'Range Size' => '32 GB',
                'Physical Device Handle' => '0x0039',
                'Partition Row Position' => '1',
                'Ending Address' => '0x00FFFFFFFFF',
                'Starting Address' => '0x00800000000',
                'Memory Array Mapped Address Handle' => '0x0036'
            },
            {
                'Memory Array Mapped Address Handle' => '0x0036',
                'Ending Address' => '0x017FFFFFFFF',
                'Starting Address' => '0x01000000000',
                'Physical Device Handle' => '0x003C',
                'Range Size' => '32 GB',
                'Partition Row Position' => '1'
            },
            {
                'Memory Array Mapped Address Handle' => '0x0036',
                'Starting Address' => '0x01800000000',
                'Ending Address' => '0x01FFFFFFFFF',
                'Partition Row Position' => '1',
                'Physical Device Handle' => '0x003E',
                'Range Size' => '32 GB'
            },
            {
                'Physical Device Handle' => '0x0043',
                'Range Size' => '32 GB',
                'Partition Row Position' => '1',
                'Memory Array Mapped Address Handle' => '0x0042',
                'Ending Address' => '0x027FFFFFFFF',
                'Starting Address' => '0x02000000000'
            },
            {
                'Memory Array Mapped Address Handle' => '0x0042',
                'Starting Address' => '0x02800000000',
                'Ending Address' => '0x02FFFFFFFFF',
                'Physical Device Handle' => '0x0045',
                'Range Size' => '32 GB',
                'Partition Row Position' => '1'
            },
            {
                'Memory Array Mapped Address Handle' => '0x0042',
                'Ending Address' => '0x037FFFFFFFF',
                'Starting Address' => '0x03000000000',
                'Partition Row Position' => '1',
                'Physical Device Handle' => '0x0048',
                'Range Size' => '32 GB'
            },
            {
                'Ending Address' => '0x03FFFFFFFFF',
                'Starting Address' => '0x03800000000',
                'Memory Array Mapped Address Handle' => '0x0042',
                'Partition Row Position' => '1',
                'Range Size' => '32 GB',
                'Physical Device Handle' => '0x004A'
            },
            {
                'Range Size' => '32 GB',
                'Physical Device Handle' => '0x004F',
                'Partition Row Position' => '1',
                'Starting Address' => '0x04000000000',
                'Ending Address' => '0x047FFFFFFFF',
                'Memory Array Mapped Address Handle' => '0x004E'
            },
            {
                'Ending Address' => '0x04FFFFFFFFF',
                'Starting Address' => '0x04800000000',
                'Memory Array Mapped Address Handle' => '0x004E',
                'Range Size' => '32 GB',
                'Physical Device Handle' => '0x0051',
                'Partition Row Position' => '1'
            },
            {
                'Physical Device Handle' => '0x0054',
                'Range Size' => '32 GB',
                'Partition Row Position' => '1',
                'Memory Array Mapped Address Handle' => '0x004E',
                'Starting Address' => '0x05000000000',
                'Ending Address' => '0x057FFFFFFFF'
            },
            {
                'Range Size' => '32 GB',
                'Physical Device Handle' => '0x0056',
                'Partition Row Position' => '1',
                'Starting Address' => '0x05800000000',
                'Ending Address' => '0x05FFFFFFFFF',
                'Memory Array Mapped Address Handle' => '0x004E'
            },
            {
                'Partition Row Position' => '1',
                'Range Size' => '32 GB',
                'Physical Device Handle' => '0x005B',
                'Starting Address' => '0x06000000000',
                'Ending Address' => '0x067FFFFFFFF',
                'Memory Array Mapped Address Handle' => '0x005A'
            },
            {
                'Starting Address' => '0x06800000000',
                'Ending Address' => '0x06FFFFFFFFF',
                'Memory Array Mapped Address Handle' => '0x005A',
                'Partition Row Position' => '1',
                'Range Size' => '32 GB',
                'Physical Device Handle' => '0x005D'
            },
            {
                'Range Size' => '32 GB',
                'Physical Device Handle' => '0x0060',
                'Partition Row Position' => '1',
                'Starting Address' => '0x07000000000',
                'Ending Address' => '0x077FFFFFFFF',
                'Memory Array Mapped Address Handle' => '0x005A'
            },
            {
                'Range Size' => '32 GB',
                'Physical Device Handle' => '0x0062',
                'Partition Row Position' => '1',
                'Starting Address' => '0x07800000000',
                'Ending Address' => '0x07FFFFFFFFF',
                'Memory Array Mapped Address Handle' => '0x005A'
            }
        ],
        41 => [
            {
                'Type Instance' => '1',
                'Status' => 'Enabled',
                'Bus Address' => '0000:3d:00.0',
                'Type' => 'Video',
                'Reference Designation' => 'Onboard Video'
            },
            {
                'Reference Designation' => 'X540 10GbE Controller',
                'Type' => 'Ethernet',
                'Bus Address' => '0000:82:00.0',
                'Status' => 'Enabled',
                'Type Instance' => '3'
            },
            {
                'Status' => 'Enabled',
                'Bus Address' => '0000:82:00.1',
                'Type Instance' => '4',
                'Reference Designation' => 'X540 10GbE Controller',
                'Type' => 'Ethernet'
            },
            {
                'Type' => 'Ethernet',
                'Reference Designation' => 'X540 10GbE Controller',
                'Type Instance' => '1',
                'Bus Address' => '0000:3a:00.0',
                'Status' => 'Enabled'
            },
            {
                'Bus Address' => '0000:3a:00.1',
                'Status' => 'Enabled',
                'Type Instance' => '2',
                'Reference Designation' => 'X540 10GbE Controller',
                'Type' => 'Ethernet'
            }
        ],
        13 => [
            {
                'Currently Installed Language' => 'en|US|iso8859-1',
                'Installable Languages' => '1',
                'Language Description Format' => 'Long'
            }
        ],
        17 => [
            {
                'Configured Clock Speed' => '2133 MHz',
                'Form Factor' => 'DIMM',
                'Speed' => '2133 MHz',
                'Array Handle' => '0x0035',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Rank' => '4',
                'Size' => '32 GB',
                'Type' => 'DDR4',
                'Data Width' => '64 bits',
                'Bank Locator' => '/SYS/MB/P0',
                'Asset Tag' => 'DIMM_A1_AssetTag',
                'Locator' => 'D11',
                'Serial Number' => '330DC586',
                'Total Width' => '72 bits',
                'Type Detail' => 'Synchronous',
                'Error Information Handle' => 'Not Provided',
                'Manufacturer' => 'Samsung'
            },
            {
                'Rank' => '4',
                'Size' => '32 GB',
                'Type' => 'DDR4',
                'Asset Tag' => 'DIMM_A2_AssetTag',
                'Bank Locator' => '/SYS/MB/P0',
                'Data Width' => '64 bits',
                'Configured Clock Speed' => '2133 MHz',
                'Form Factor' => 'DIMM',
                'Speed' => '2133 MHz',
                'Array Handle' => '0x0035',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Error Information Handle' => 'Not Provided',
                'Manufacturer' => 'Samsung',
                'Locator' => 'D10',
                'Serial Number' => '32A3A4FD',
                'Type Detail' => 'Synchronous',
                'Total Width' => '72 bits'
            },
            {
                'Locator' => 'D9',
                'Serial Number' => 'NO DIMM',
                'Form Factor' => 'DIMM',
                'Type Detail' => 'Synchronous',
                'Part Number' => 'NO DIMM',
                'Array Handle' => '0x0035',
                'Size' => 'No Module Installed',
                'Type' => 'DDR4',
                'Error Information Handle' => 'Not Provided',
                'Manufacturer' => 'NO DIMM',
                'Asset Tag' => 'NO DIMM',
                'Bank Locator' => '/SYS/MB/P0'
                },
            {
                'Serial Number' => '330DC585',
                'Locator' => 'D8',
                'Type Detail' => 'Synchronous',
                'Total Width' => '72 bits',
                'Manufacturer' => 'Samsung',
                'Error Information Handle' => 'Not Provided',
                'Form Factor' => 'DIMM',
                'Configured Clock Speed' => '2133 MHz',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Array Handle' => '0x0035',
                'Speed' => '2133 MHz',
                'Size' => '32 GB',
                'Rank' => '4',
                'Asset Tag' => 'DIMM_B1_AssetTag',
                'Bank Locator' => '/SYS/MB/P0',
                'Data Width' => '64 bits',
                'Type' => 'DDR4'
            },
            {
                'Error Information Handle' => 'Not Provided',
                'Manufacturer' => 'Samsung',
                'Locator' => 'D7',
                'Serial Number' => '32A3A500',
                'Total Width' => '72 bits',
                'Type Detail' => 'Synchronous',
                'Rank' => '4',
                'Size' => '32 GB',
                'Type' => 'DDR4',
                'Bank Locator' => '/SYS/MB/P0',
                'Data Width' => '64 bits',
                'Asset Tag' => 'DIMM_B2_AssetTag',
                'Configured Clock Speed' => '2133 MHz',
                'Form Factor' => 'DIMM',
                'Speed' => '2133 MHz',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Array Handle' => '0x0035'
            },
            {
                'Size' => 'No Module Installed',
                'Manufacturer' => 'NO DIMM',
                'Asset Tag' => 'NO DIMM',
                'Bank Locator' => '/SYS/MB/P0',
                'Type' => 'DDR4',
                'Error Information Handle' => 'Not Provided',
                'Serial Number' => 'NO DIMM',
                'Form Factor' => 'DIMM',
                'Locator' => 'D6',
                'Array Handle' => '0x0035',
                'Part Number' => 'NO DIMM',
                'Type Detail' => 'Synchronous'
            },
            {
                'Rank' => '4',
                'Size' => '32 GB',
                'Type' => 'DDR4',
                'Bank Locator' => '/SYS/MB/P0',
                'Data Width' => '64 bits',
                'Asset Tag' => 'DIMM_C1_AssetTag',
                'Configured Clock Speed' => '2133 MHz',
                'Form Factor' => 'DIMM',
                'Speed' => '2133 MHz',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Array Handle' => '0x0041',
                'Error Information Handle' => 'Not Provided',
                'Manufacturer' => 'Samsung',
                'Locator' => 'D0',
                'Serial Number' => '330DC584',
                'Total Width' => '72 bits',
                'Type Detail' => 'Synchronous'
            },
            {
                'Error Information Handle' => 'Not Provided',
                'Manufacturer' => 'Samsung',
                'Type Detail' => 'Synchronous',
                'Total Width' => '72 bits',
                'Locator' => 'D1',
                'Serial Number' => '32A3A4BD',
                'Type' => 'DDR4',
                'Asset Tag' => 'DIMM_C2_AssetTag',
                'Data Width' => '64 bits',
                'Bank Locator' => '/SYS/MB/P0',
                'Rank' => '4',
                'Size' => '32 GB',
                'Speed' => '2133 MHz',
                'Array Handle' => '0x0041',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Configured Clock Speed' => '2133 MHz',
                'Form Factor' => 'DIMM'
            },
            {
                'Locator' => 'D2',
                'Serial Number' => 'NO DIMM',
                'Form Factor' => 'DIMM',
                'Type Detail' => 'Synchronous',
                'Part Number' => 'NO DIMM',
                'Array Handle' => '0x0041',
                'Size' => 'No Module Installed',
                'Type' => 'DDR4',
                'Error Information Handle' => 'Not Provided',
                'Asset Tag' => 'NO DIMM',
                'Manufacturer' => 'NO DIMM',
                'Bank Locator' => '/SYS/MB/P0'
            },
            {
                'Manufacturer' => 'Samsung',
                'Error Information Handle' => 'Not Provided',
                'Type Detail' => 'Synchronous',
                'Total Width' => '72 bits',
                'Serial Number' => '330DC588',
                'Locator' => 'D3',
                'Asset Tag' => 'DIMM_D1_AssetTag',
                'Bank Locator' => '/SYS/MB/P0',
                'Data Width' => '64 bits',
                'Type' => 'DDR4',
                'Size' => '32 GB',
                'Rank' => '4',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Array Handle' => '0x0041',
                'Speed' => '2133 MHz',
                'Form Factor' => 'DIMM',
                'Configured Clock Speed' => '2133 MHz'
            },
            {
                'Speed' => '2133 MHz',
                'Array Handle' => '0x0041',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Configured Clock Speed' => '2133 MHz',
                'Form Factor' => 'DIMM',
                'Type' => 'DDR4',
                'Asset Tag' => 'DIMM_D2_AssetTag',
                'Bank Locator' => '/SYS/MB/P0',
                'Data Width' => '64 bits',
                'Rank' => '4',
                'Size' => '32 GB',
                'Type Detail' => 'Synchronous',
                'Total Width' => '72 bits',
                'Locator' => 'D4',
                'Serial Number' => '32A3A50E',
                'Error Information Handle' => 'Not Provided',
                'Manufacturer' => 'Samsung',
            },
            {
                'Locator' => 'D5',
                'Form Factor' => 'DIMM',
                'Serial Number' => 'NO DIMM',
                'Type Detail' => 'Synchronous',
                'Array Handle' => '0x0041',
                'Part Number' => 'NO DIMM',
                'Size' => 'No Module Installed',
                'Error Information Handle' => 'Not Provided',
                'Type' => 'DDR4',
                'Bank Locator' => '/SYS/MB/P0',
                'Manufacturer' => 'NO DIMM',
                'Asset Tag' => 'NO DIMM'
            },
            {
                'Serial Number' => '330DC582',
                'Locator' => 'D11',
                'Total Width' => '72 bits',
                'Type Detail' => 'Synchronous',
                'Manufacturer' => 'Samsung',
                'Error Information Handle' => 'Not Provided',
                'Form Factor' => 'DIMM',
                'Configured Clock Speed' => '2133 MHz',
                'Array Handle' => '0x004D',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Speed' => '2133 MHz',
                'Size' => '32 GB',
                'Rank' => '4',
                'Bank Locator' => '/SYS/MB/P1',
                'Data Width' => '64 bits',
                'Asset Tag' => 'DIMM_E1_AssetTag',
                'Type' => 'DDR4'
            },
            {
                'Type Detail' => 'Synchronous',
                'Total Width' => '72 bits',
                'Locator' => 'D10',
                'Serial Number' => '32A3A4CE',
                'Error Information Handle' => 'Not Provided',
                'Manufacturer' => 'Samsung',
                'Speed' => '2133 MHz',
                'Array Handle' => '0x004D',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Configured Clock Speed' => '2133 MHz',
                'Form Factor' => 'DIMM',
                'Type' => 'DDR4',
                'Asset Tag' => 'DIMM_E2_AssetTag',
                'Bank Locator' => '/SYS/MB/P1',
                'Data Width' => '64 bits',
                'Rank' => '4',
                'Size' => '32 GB'
            },
            {
                'Bank Locator' => '/SYS/MB/P1',
                'Asset Tag' => 'NO DIMM',
                'Manufacturer' => 'NO DIMM',
                'Error Information Handle' => 'Not Provided',
                'Type' => 'DDR4',
                'Size' => 'No Module Installed',
                'Part Number' => 'NO DIMM',
                'Array Handle' => '0x004D',
                'Type Detail' => 'Synchronous',
                'Form Factor' => 'DIMM',
                'Serial Number' => 'NO DIMM',
                'Locator' => 'D9'
            },
            {
                'Speed' => '2133 MHz',
                'Array Handle' => '0x004D',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Configured Clock Speed' => '2133 MHz',
                'Form Factor' => 'DIMM',
                'Type' => 'DDR4',
                'Asset Tag' => 'DIMM_F1_AssetTag',
                'Bank Locator' => '/SYS/MB/P1',
                'Data Width' => '64 bits',
                'Rank' => '4',
                'Size' => '32 GB',
                'Type Detail' => 'Synchronous',
                'Total Width' => '72 bits',
                'Locator' => 'D8',
                'Serial Number' => '330DCB4F',
                'Error Information Handle' => 'Not Provided',
                'Manufacturer' => 'Samsung',
            },
            {
                'Speed' => '2133 MHz',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Array Handle' => '0x004D',
                'Configured Clock Speed' => '2133 MHz',
                'Form Factor' => 'DIMM',
                'Type' => 'DDR4',
                'Bank Locator' => '/SYS/MB/P1',
                'Data Width' => '64 bits',
                'Asset Tag' => 'DIMM_F2_AssetTag',
                'Rank' => '4',
                'Size' => '32 GB',
                'Total Width' => '72 bits',
                'Type Detail' => 'Synchronous',
                'Locator' => 'D7',
                'Serial Number' => '32A3A4FC',
                'Error Information Handle' => 'Not Provided',
                'Manufacturer' => 'Samsung',
            },
            {
                'Error Information Handle' => 'Not Provided',
                'Type' => 'DDR4',
                'Bank Locator' => '/SYS/MB/P1',
                'Manufacturer' => 'NO DIMM',
                'Asset Tag' => 'NO DIMM',
                'Size' => 'No Module Installed',
                'Type Detail' => 'Synchronous',
                'Array Handle' => '0x004D',
                'Part Number' => 'NO DIMM',
                'Locator' => 'D6',
                'Form Factor' => 'DIMM',
                'Serial Number' => 'NO DIMM'
            },
            {
                'Serial Number' => '330DC543',
                'Locator' => 'D0',
                'Type Detail' => 'Synchronous',
                'Total Width' => '72 bits',
                'Manufacturer' => 'Samsung',
                'Error Information Handle' => 'Not Provided',
                'Form Factor' => 'DIMM',
                'Configured Clock Speed' => '2133 MHz',
                'Array Handle' => '0x0059',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Speed' => '2133 MHz',
                'Size' => '32 GB',
                'Rank' => '4',
                'Asset Tag' => 'DIMM_G1_AssetTag',
                'Bank Locator' => '/SYS/MB/P1',
                'Data Width' => '64 bits',
                'Type' => 'DDR4'
            },
            {
                'Size' => '32 GB',
                'Rank' => '4',
                'Bank Locator' => '/SYS/MB/P1',
                'Data Width' => '64 bits',
                'Asset Tag' => 'DIMM_G2_AssetTag',
                'Type' => 'DDR4',
                'Form Factor' => 'DIMM',
                'Configured Clock Speed' => '2133 MHz',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Array Handle' => '0x0059',
                'Speed' => '2133 MHz',
                'Manufacturer' => 'Samsung',
                'Error Information Handle' => 'Not Provided',
                'Serial Number' => '32A3A4CC',
                'Locator' => 'D1',
                'Total Width' => '72 bits',
                'Type Detail' => 'Synchronous'
            },
            {
                'Array Handle' => '0x0059',
                'Part Number' => 'NO DIMM',
                'Type Detail' => 'Synchronous',
                'Form Factor' => 'DIMM',
                'Serial Number' => 'NO DIMM',
                'Locator' => 'D2',
                'Bank Locator' => '/SYS/MB/P1',
                'Manufacturer' => 'NO DIMM',
                'Asset Tag' => 'NO DIMM',
                'Error Information Handle' => 'Not Provided',
                'Type' => 'DDR4',
                'Size' => 'No Module Installed',
            },
            {
                'Serial Number' => '330DC52C',
                'Locator' => 'D3',
                'Total Width' => '72 bits',
                'Type Detail' => 'Synchronous',
                'Manufacturer' => 'Samsung',
                'Error Information Handle' => 'Not Provided',
                'Form Factor' => 'DIMM',
                'Configured Clock Speed' => '2133 MHz',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Array Handle' => '0x0059',
                'Speed' => '2133 MHz',
                'Size' => '32 GB',
                'Rank' => '4',
                'Bank Locator' => '/SYS/MB/P1',
                'Data Width' => '64 bits',
                'Asset Tag' => 'DIMM_H1_AssetTag',
                'Type' => 'DDR4'
            },
            {
                'Configured Clock Speed' => '2133 MHz',
                'Form Factor' => 'DIMM',
                'Speed' => '2133 MHz',
                'Part Number' => 'M386A4G40DM0-CPB',
                'Array Handle' => '0x0059',
                'Rank' => '4',
                'Size' => '32 GB',
                'Type' => 'DDR4',
                'Bank Locator' => '/SYS/MB/P1',
                'Data Width' => '64 bits',
                'Asset Tag' => 'DIMM_H2_AssetTag',
                'Locator' => 'D4',
                'Serial Number' => '32A3A50D',
                'Total Width' => '72 bits',
                'Type Detail' => 'Synchronous',
                'Error Information Handle' => 'Not Provided',
                'Manufacturer' => 'Samsung'
            },
            {
                'Bank Locator' => '/SYS/MB/P1',
                'Manufacturer' => 'NO DIMM',
                'Asset Tag' => 'NO DIMM',
                'Error Information Handle' => 'Not Provided',
                'Type' => 'DDR4',
                'Size' => 'No Module Installed',
                'Array Handle' => '0x0059',
                'Part Number' => 'NO DIMM',
                'Type Detail' => 'Synchronous',
                'Form Factor' => 'DIMM',
                'Serial Number' => 'NO DIMM',
                'Locator' => 'D5'
            }
        ],
        8 => [
            {
                'External Reference Designator' => 'USB Internal Connector - Bottom',
                'Port Type' => 'USB',
                'Internal Reference Designator' => 'J2803',
                'External Connector Type' => 'Access Bus (USB)'
            },
            {
                'External Reference Designator' => 'USB Internal Connector - Top',
                'Port Type' => 'USB',
                'Internal Reference Designator' => 'J2803',
                'External Connector Type' => 'Access Bus (USB)'
            },
            {
                'Internal Reference Designator' => 'J2901',
                'External Connector Type' => 'DB-15 female',
                'External Reference Designator' => 'VGA Connector',
                'Port Type' => 'Video Port',
            },
            {
                'Internal Reference Designator' => 'J2801',
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB Rear Connector - Left',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'Internal Reference Designator' => 'J2802',
                'Port Type' => 'USB',
                'External Reference Designator' => 'USB Rear Connector - Right'
            },
            {
                'External Reference Designator' => 'USB Front Connector - Left',
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)'
            },
            {
                'Port Type' => 'USB',
                'External Reference Designator' => 'USB Front Connector - Right',
                'External Connector Type' => 'Access Bus (USB)',
            },
            {
                'Internal Reference Designator' => 'J2903',
                'External Connector Type' => 'RJ-45',
                'External Reference Designator' => 'SER MGT',
                'Port Type' => 'Serial Port 16550 Compatible',
            },
            {
                'External Reference Designator' => 'NET MGT',
                'Port Type' => 'Network Port',
                'Internal Reference Designator' => 'J2902',
                'External Connector Type' => 'RJ-45'
            },
            {
                'External Connector Type' => 'RJ-45',
                'Internal Reference Designator' => 'J3502',
                'Port Type' => 'Network Port',
                'External Reference Designator' => 'NET 0'
            },
            {
                'Internal Reference Designator' => 'J3501',
                'External Connector Type' => 'RJ-45',
                'External Reference Designator' => 'NET 1',
                'Port Type' => 'Network Port',
            },
            {
                'External Reference Designator' => 'NET 2',
                'Port Type' => 'Network Port',
                'Internal Reference Designator' => 'J3802',
                'External Connector Type' => 'RJ-45'
            },
            {
                'Internal Reference Designator' => 'J3801',
                'External Connector Type' => 'RJ-45',
                'External Reference Designator' => 'NET 3',
                'Port Type' => 'Network Port'
            },
            {
                'External Reference Designator' => 'DVD',
                'Port Type' => 'SATA',
                'Internal Reference Designator' => 'J2003',
                'External Connector Type' => 'SAS/SATA Plug Receptacle'
            }
        ],
        38 => [
            {
                'Interface Type' => 'KCS (Keyboard Control Style)',
                'Base Address' => '0x0000000000000CA2 (I/O)',
                'Specification Version' => '2.0',
                'Register Spacing' => 'Successive Byte Boundaries',
                'I2C Slave Address' => '0x10'
            }
        ],
        4 => [
            {
                'Status' => 'Populated, Enabled',
                'Voltage' => '1.8 V',
                'Manufacturer' => 'Intel',
                'Max Speed' => '4000 MHz',
                'Version' => 'Intel(R) Xeon(R) CPU E5-2699 v3 @ 2.30GHz',
                'Core Count' => '18',
                'Current Speed' => '2300 MHz',
                'Core Enabled' => '18',
                'Family' => 'Xeon',
                'Socket Designation' => 'P0',
                'Upgrade' => 'Socket LGA2011-3',
                'Type' => 'Central Processor',
                'L3 Cache Handle' => '0x0067',
                'L2 Cache Handle' => '0x0066',
                'Signature' => 'Type 0, Family 6, Model 63, Stepping 2',
                'Part Number' => '060F',
                'L1 Cache Handle' => '0x0065',
                'ID' => 'F2 06 03 00 FF FB EB BF',
                'Thread Count' => '36',
                'External Clock' => '100 MHz'
            },
            {
                'Voltage' => '1.8 V',
                'Status' => 'Populated, Enabled',
                'Manufacturer' => 'Intel',
                'Version' => 'Intel(R) Xeon(R) CPU E5-2699 v3 @ 2.30GHz',
                'Max Speed' => '4000 MHz',
                'Core Count' => '18',
                'Core Enabled' => '18',
                'Current Speed' => '2300 MHz',
                'Type' => 'Central Processor',
                'L3 Cache Handle' => '0x006B',
                'Upgrade' => 'Socket LGA2011-3',
                'Family' => 'Xeon',
                'Socket Designation' => 'P1',
                'L2 Cache Handle' => '0x006A',
                'External Clock' => '100 MHz',
                'ID' => 'F2 06 03 00 FF FB EB BF',
                'Thread Count' => '36',
                'Part Number' => '060F',
                'Signature' => 'Type 0, Family 6, Model 63, Stepping 2',
                'L1 Cache Handle' => '0x0069'
            }
        ],
        19 => [
            {
                'Starting Address' => '0x00000000000',
                'Partition Width' => '4',
                'Ending Address' => '0x01FFFFFFFFF',
                'Range Size' => '128 GB',
                'Physical Array Handle' => '0x0035'
            },
            {
                'Partition Width' => '4',
                'Ending Address' => '0x03FFFFFFFFF',
                'Starting Address' => '0x02000000000',
                'Physical Array Handle' => '0x0041',
                'Range Size' => '128 GB'
            },
            {
                'Partition Width' => '4',
                'Ending Address' => '0x05FFFFFFFFF',
                'Starting Address' => '0x04000000000',
                'Physical Array Handle' => '0x004D',
                'Range Size' => '128 GB'
            },
            {
                'Partition Width' => '4',
                'Ending Address' => '0x07FFFFFFFFF',
                'Starting Address' => '0x06000000000',
                'Range Size' => '128 GB',
                'Physical Array Handle' => '0x0059'
            }
        ],
        7 => [
            {
                'System Type' => 'Other',
                'Socket Designation' => 'CPU Internal L1',
                'Associativity' => '8-way Set-associative',
                'Maximum Size' => '1152 kB',
                'Operational Mode' => 'Write Back',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'Error Correction Type' => 'Parity',
                'Location' => 'Internal',
                'Installed Size' => '1152 kB'
            },
            {
                'Socket Designation' => 'CPU Internal L2',
                'System Type' => 'Unified',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Operational Mode' => 'Write Back',
                'Associativity' => '8-way Set-associative',
                'Maximum Size' => '4608 kB',
                'Error Correction Type' => 'Single-bit ECC',
                'Installed Size' => '4608 kB',
                'Location' => 'Internal'
            },
            {
                'Socket Designation' => 'CPU Internal L3',
                'System Type' => 'Unified',
                'Operational Mode' => 'Write Back',
                'Configuration' => 'Enabled, Not Socketed, Level 3',
                'Associativity' => '20-way Set-associative',
                'Maximum Size' => '46080 kB',
                'Error Correction Type' => 'Single-bit ECC',
                'Location' => 'Internal',
                'Installed Size' => '46080 kB'
            },
            {
                'Installed Size' => '1152 kB',
                'Location' => 'Internal',
                'Error Correction Type' => 'Parity',
                'Associativity' => '8-way Set-associative',
                'Maximum Size' => '1152 kB',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'Operational Mode' => 'Write Back',
                'System Type' => 'Other',
                'Socket Designation' => 'CPU Internal L1'
            },
            {
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Operational Mode' => 'Write Back',
                'Maximum Size' => '4608 kB',
                'Associativity' => '8-way Set-associative',
                'Socket Designation' => 'CPU Internal L2',
                'System Type' => 'Unified',
                'Installed Size' => '4608 kB',
                'Location' => 'Internal',
                'Error Correction Type' => 'Single-bit ECC'
            },
            {
                'Error Correction Type' => 'Single-bit ECC',
                'Installed Size' => '46080 kB',
                'Location' => 'Internal',
                'Socket Designation' => 'CPU Internal L3',
                'System Type' => 'Unified',
                'Configuration' => 'Enabled, Not Socketed, Level 3',
                'Operational Mode' => 'Write Back',
                'Maximum Size' => '46080 kB',
                'Associativity' => '20-way Set-associative'
            }
        ],
        11 => [
            {
                'String 3' => 'storage-variant:8dbp',
                'String 1' => 'SUNW-PRMS-1'
            }
        ],
        3 => [
            {
                'Power Supply State' => 'Safe',
                'Type' => 'Main Server Chassis',
                'Thermal State' => 'Safe',
                'Boot-up State' => 'Safe',
                'Asset Tag' => '7092459',
                'Manufacturer' => 'Oracle Corporation',
                'Height' => '1 U',
                'Contained Elements' => '0',
                'Number Of Power Cords' => '2',
                'Serial Number' => '1634NM1107',
                'Version' => 'ORACLE SERVER X5-2',
                'OEM Information' => '0x00000000'
            }
        ],
        37 => [
            {
                'Device 3 Handle' => '0x2500',
                'Device 1 Handle' => '0x0039',
                'Device 3 Load' => '0',
                'Device 1 Load' => '4',
                'Devices' => '3',
                'Type' => 'RamBus',
                'Device 2 Handle' => '0x003B',
                'Device 2 Load' => '0',
                'Maximal Load' => '8'
            },
            {
                'Device 2 Load' => '0',
                'Device 2 Handle' => '0x0040',
                'Maximal Load' => '8',
                'Type' => 'RamBus',
                'Devices' => '3',
                'Device 1 Load' => '4',
                'Device 3 Load' => '0',
                'Device 1 Handle' => '0x003E',
                'Device 3 Handle' => '0x2500'
            },
            {
                'Maximal Load' => '8',
                'Device 2 Handle' => '0x0047',
                'Device 2 Load' => '0',
                'Type' => 'RamBus',
                'Devices' => '3',
                'Device 1 Load' => '4',
                'Device 3 Load' => '0',
                'Device 1 Handle' => '0x0045',
                'Device 3 Handle' => '0x2500'
            },
            {
                'Type' => 'RamBus',
                'Device 2 Load' => '0',
                'Device 2 Handle' => '0x004C',
                'Maximal Load' => '8',
                'Devices' => '3',
                'Device 1 Handle' => '0x004A',
                'Device 3 Load' => '0',
                'Device 1 Load' => '4',
                'Device 3 Handle' => '0x2500'
            },
            {
                'Devices' => '3',
                'Device 2 Handle' => '0x0053',
                'Maximal Load' => '8',
                'Device 2 Load' => '0',
                'Type' => 'RamBus',
                'Device 3 Handle' => '0x2500',
                'Device 3 Load' => '0',
                'Device 1 Load' => '4',
                'Device 1 Handle' => '0x0051'
            },
            {
                'Type' => 'RamBus',
                'Device 2 Load' => '0',
                'Device 2 Handle' => '0x0058',
                'Maximal Load' => '8',
                'Devices' => '3',
                'Device 1 Handle' => '0x0056',
                'Device 1 Load' => '4',
                'Device 3 Load' => '0',
                'Device 3 Handle' => '0x2500'
            },
            {
                'Maximal Load' => '8',
                'Device 2 Handle' => '0x005F',
                'Device 2 Load' => '0',
                'Type' => 'RamBus',
                'Devices' => '3',
                'Device 1 Load' => '4',
                'Device 3 Load' => '0',
                'Device 1 Handle' => '0x005D',
                'Device 3 Handle' => '0x2500'
            },
            {
                'Type' => 'RamBus',
                'Device 2 Handle' => '0x0064',
                'Device 2 Load' => '0',
                'Maximal Load' => '8',
                'Devices' => '3',
                'Device 1 Handle' => '0x0062',
                'Device 1 Load' => '4',
                'Device 3 Load' => '0',
                'Device 3 Handle' => '0x9000'
            }
        ],
        32 => [
            {
                'Status' => 'No errors detected'
            }
        ],
        1 => [
            {
                'Serial Number' => '1634NM1107',
                'Product Name' => 'ORACLE SERVER X5-2',
                'UUID' => '080020FF-FFFF-FFFF-FFFF-0010E0BCCBBC',
                'Manufacturer' => 'Oracle Corporation',
                'SKU Number' => '7092459',
                'Wake-up Type' => 'Power Switch'
            }
        ],
        16 => [
            {
                'Error Information Handle' => 'Not Provided',
                'Maximum Capacity' => '192 GB',
                'Error Correction Type' => 'Multi-bit ECC',
                'Use' => 'System Memory',
                'Location' => 'System Board Or Motherboard',
                'Number Of Devices' => '6'
            },
            {
                'Error Information Handle' => 'Not Provided',
                'Error Correction Type' => 'Multi-bit ECC',
                'Maximum Capacity' => '192 GB',
                'Use' => 'System Memory',
                'Number Of Devices' => '6',
                'Location' => 'System Board Or Motherboard'
            },
            {
                'Location' => 'System Board Or Motherboard',
                'Number Of Devices' => '6',
                'Use' => 'System Memory',
                'Maximum Capacity' => '192 GB',
                'Error Correction Type' => 'Multi-bit ECC',
                'Error Information Handle' => 'Not Provided'
            },
            {
                'Location' => 'System Board Or Motherboard',
                'Number Of Devices' => '6',
                'Error Information Handle' => 'Not Provided',
                'Error Correction Type' => 'Multi-bit ECC',
                'Maximum Capacity' => '192 GB',
                'Use' => 'System Memory'
            }
        ],
        0 => [
            {
                'Vendor' => 'American Megatrends Inc.',
                'Release Date' => '05/26/2016',
                'Runtime Size' => '64 kB',
                'Firmware Revision' => '3.2',
                'Address' => '0xF0000',
                'BIOS Revision' => '8.3',
                'Version' => '30080300',
                'ROM Size' => '8192 kB'
            }
        ]
    },
    'windows' => {
        32 => [
            {
                 'Status' => 'No errors detected'
            }
        ],
        11 => [
            {
                 'String 1' => 'PS241E-5J851-FR,SS241-5J851FR+0OL'
            }
        ],
        21 => [
            {
                 'Type' => 'Touch Pad',
                 'Buttons' => '2',
                 'Interface' => 'PS/2'
            }
        ],
        7 => [
            {
                'Error Correction Type' => 'Single-bit ECC',
                'Installed Size' => '8 kB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'CPU Internal',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'Installed SRAM Type' => 'Other',
                'System Type' => 'Data',
                'Speed' => '1 ns',
                'Associativity' => '4-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '8 kB'
            },
            {
                'Installed Size' => '512 kB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'CPU Internal',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Installed SRAM Type' => 'Other',
                'Speed' => '1 ns',
                'Location' => 'Internal',
                'Maximum Size' => '512 kB'
            }
        ],
        17 => [
            {
                 'Bank Locator' => 'CSA 0 & 1',
                 'Data Width' => '64 bits',
                 'Array Handle' => '0x0081',
                 'Type Detail' => 'Synchronous',
                 'Total Width' => '64 bits',
                 'Type' => 'SDRAM',
                 'Size' => '256 MB',
                 'Error Information Handle' => 'Not Provided',
                 'Locator' => 'DIMM 0',
                 'Form Factor' => 'SODIMM'
            },
            {
                 'Bank Locator' => 'CSA 2 & 3',
                 'Data Width' => '64 bits',
                 'Array Handle' => '0x0081',
                 'Type Detail' => 'Synchronous',
                 'Total Width' => '64 bits',
                 'Type' => 'SDRAM',
                 'Size' => '512 MB',
                 'Error Information Handle' => 'Not Provided',
                 'Locator' => 'DIMM 1',
                 'Form Factor' => 'SODIMM'
            }
        ],
        2 => [
            {
                'Version' => 'Version A0',
                'Product Name' => 'Portable PC',
                'Serial Number' => '$$T02XB1K9',
                'Manufacturer' => 'TOSHIBA'
            }
        ],
        22 => [
            {
                 'Design Capacity' => '0 mWh',
                 'Serial Number' => '2000417915',
                 'OEM-specific Information' => '0x00000000',
                 'Manufacture Date' => '09/19/02',
                 'Chemistry' => 'Lithium Ion',
                 'Design Voltage' => '10800 mV',
                 'Location' => '1st Battery',
                 'Manufacturer' => 'TOSHIBA',
                 'Name' => 'L9088A'
            }
        ],
        1 => [
            {
                'Version' => 'PS241E-5J851-FR',
                'Wake-up Type' => 'Power Switch',
                'Product Name' => 'Satellite 2410',
                'Serial Number' => 'X2735244G',
                'Manufacturer' => 'TOSHIBA',
                'UUID' => '7FB4EA00-07CB-18F3-8041-CAD582735244'
            }
        ],
        0 => [
            {
                'Runtime Size' => '128 kB',
                'Version' => 'Version 1.10',
                'Address' => '0xE0000',
                'ROM Size' => '512 kB',
                'Release Date' => '08/13/2002',
                'Vendor' => 'TOSHIBA'
            }
        ],
        16 => [
            {
                 'Number Of Devices' => '2',
                 'Error Information Handle' => 'Not Provided',
                 'Location' => 'System Board Or Motherboard',
                 'Maximum Capacity' => '1 GB',
                 'Use' => 'System Memory'
            }
        ],
        6 => [
            {
                'Installed Size' => '256 MB (Single-bank Connection)',
                'Socket Designation' => 'SO-DIMM',
                'Type' => 'Other DIMM SDRAM',
                'Error Status' => 'OK',
                'Enabled Size' => '256 MB (Single-bank Connection)',
                'Current Speed' => '8 ns',
                'Bank Connections' => '0 1'
            },
            {
                'Installed Size' => '512 MB (Single-bank Connection)',
                'Socket Designation' => 'SO-DIMM',
                'Type' => 'Other DIMM SDRAM',
                'Error Status' => 'OK',
                'Enabled Size' => '512 MB (Single-bank Connection)',
                'Current Speed' => '8 ns',
                'Bank Connections' => '2'
            }
        ],
        3 => [
            {
                'Power Supply State' => 'Safe',
                'Serial Number' => '00000000',
                'Thermal State' => 'Safe',
                'Asset Tag' => '0000000000',
                'Type' => 'Notebook',
                'Version' => 'Version 1.0',
                'OEM Information' => '0x00000000',
                'Manufacturer' => 'TOSHIBA',
                'Boot-up State' => 'Safe'
            }
        ],
        9 => [
            {
                ID             => 'Adapter 1, Socket 0',
                'Length' => 'Other',
                'Designation' => 'PCMCIA0',
                'Type' => '32-bit PC Card (PCMCIA)',
                'Current Usage' => 'In Use'
            },
            {
                ID             => 'Adapter 2, Socket 0',
                'Length' => 'Other',
                'Designation' => 'PCMCIA1',
                'Type' => '32-bit PC Card (PCMCIA)',
                'Current Usage' => 'In Use'
            },
            {
                'Length' => 'Other',
                'Designation' => 'SD CARD',
                'Type' => 'Other',
                'Current Usage' => 'In Use'
            }
        ],
        12 => [
            {
                 'Option 1' => 'TOSHIBA'
            }
        ],
        20 => [
            {
                 'Memory Array Mapped Address Handle' => '0x0090',
                 'Range Size' => '641 kB',
                 'Physical Device Handle' => '0x0082',
                 'Partition Row Position' => '1',
                 'Starting Address' => '0x00000000000',
                 'Ending Address' => '0x000000A03FF'
            },
            {
                 'Memory Array Mapped Address Handle' => '0x0091',
                 'Range Size' => '262145 kB',
                 'Physical Device Handle' => '0x0082',
                 'Partition Row Position' => '1',
                 'Starting Address' => '0x00000000000',
                 'Ending Address' => '0x000100003FF'
            },
            {
                 'Memory Array Mapped Address Handle' => '0x0091',
                 'Range Size' => '524289 kB',
                 'Physical Device Handle' => '0x0083',
                 'Partition Row Position' => '1',
                 'Starting Address' => '0x00010000000',
                 'Ending Address' => '0x000300003FF'
            }
        ],
        15 => [
            {
                 'Access Address' => '0x0003',
                 'Access Method' => 'General-purpose non-volatile data functions',
                 'Data Start Offset' => '0x0000',
                 'Status' => 'Valid, Not Full',
                 'Supported Log Type Descriptors' => '0',
                 'Area Length' => '124 bytes',
                 'Header Start Offset' => '0x0000',
                 'Header Format' => 'No Header',
                 'Change Token' => '0x00000000'
            }
        ],
        8 => [
            {
                'External Reference Designator' => 'PARALLEL PORT',
                'Port Type' => 'Parallel Port ECP',
                'External Connector Type' => 'DB-25 female',
            },
            {
                'External Reference Designator' => 'EXTERNAL MONITOR PORT',
                'Port Type' => 'Other',
                'External Connector Type' => 'DB-15 female',
            },
            {
                'External Reference Designator' => 'BUILT-IN MODEM PORT',
                'Port Type' => 'Modem Port',
                'External Connector Type' => 'RJ-11',
            },
            {
                'External Reference Designator' => 'BUILT-IN LAN PORT',
                'Port Type' => 'Network Port',
                'External Connector Type' => 'RJ-45',
            },
            {
                'External Reference Designator' => 'INFRARED PORT',
                'Port Type' => 'Other',
                'External Connector Type' => 'Infrared',
            },
            {
                'External Reference Designator' => 'USB PORT',
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)',
            },
            {
                'External Reference Designator' => 'USB PORT',
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)',
            },
            {
                'External Reference Designator' => 'USB PORT',
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)',
            },
            {
                'External Reference Designator' => 'HEADPHONE JACK',
                'Port Type' => 'Other',
                'External Connector Type' => 'Mini Jack (headphones)',
            },
            {
                'External Reference Designator' => '1394 PORT',
                'Port Type' => 'Firewire (IEEE P1394)',
                'External Connector Type' => 'IEEE 1394',
            },
            {
                'External Reference Designator' => 'MICROPHONE JACK',
                'Port Type' => 'Other',
                'External Connector Type' => 'Other',
            },
            {
                'External Reference Designator' => 'VIDEO-OUT JACK',
                'Port Type' => 'Other',
                'External Connector Type' => 'Other',
            }
        ],
        4 => [
            {
                ID             => '24 0F 00 00 00 00 00 00',
                'Socket Designation' => 'uFC-PGA Socket',
                'Status' => 'Populated, Enabled',
                'Max Speed' => '1700 MHz',
                'External Clock' => '100 MHz',
                'Family' => 'Pentium 4',
                'Current Speed' => '1700 MHz',
                'L2 Cache Handle' => '0x0013',
                'Type' => 'Central Processor',
                'Signature' => 'Type 0, Family 15, Model 2, Stepping 4',
                'Upgrade' => 'ZIF Socket',
                'L1 Cache Handle' => '0x0012',
                'Voltage' => '1.3 V',
                'Manufacturer' => 'Intel Corporation',
                'L3 Cache Handle' => 'Not Provided'
            }
        ],
        24 => [
            {
                 'Front Panel Reset Status' => 'Disabled',
                 'Keyboard Password Status' => 'Disabled',
                 'Administrator Password Status' => 'Disabled',
                 'Power-On Password Status' => 'Disabled'
            }
        ],
        19 => [
            {
                 'Range Size' => '641 kB',
                 'Partition Width' => '0',
                 'Starting Address' => '0x00000000000',
                 'Physical Array Handle' => '0x0081',
                 'Ending Address' => '0x000000A03FF'
            },
            {
                  'Range Size' => '785281 kB',
                  'Partition Width' => '0',
                  'Starting Address' => '0x00000100000',
                  'Physical Array Handle' => '0x0081',
                  'Ending Address' => '0x0002FFE03FF'
            }
        ],
        10 => [
            {
                  'Type' => 'Other',
                  'Status' => 'Enabled',
                  'Description' => '1394'
            }
        ],
        5 => [
            {
                'Maximum Total Memory Size' => '1024 MB',
                'Supported Interleave' => 'Other',
                'Maximum Memory Module Size' => '512 MB',
                'Associated Memory Slots' => '2',
                'Current Interleave' => 'Other',
                'Memory Module Voltage' => '2.9 V'
            }
        ]
    },
    'windows-hyperV' => {
        '32' => [
            {
                'Status' => 'No errors detected'
            }
        ],
        '11' => [
            {
                'String 1' => '[MS_VM_CERT/SHA1/3480ca0d534061ec9344e424f434fd3496f32c22]',
                'String 3' => 'To be filed by MSFT',
                'String 2' => '00000000000000000000000000000000'
            }
        ],
        '17' => [
            {
                'Type' => 'Other',
                'Size' => '1024 MB',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M0',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M1',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M2',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M3',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M4',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M5',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M6',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M7',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M8',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M9',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M10',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M11',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M12',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M13',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M14',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M15',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M16',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M17',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M18',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M19',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M20',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M21',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M22',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M23',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M24',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M25',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M26',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M27',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M28',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M29',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M30',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M31',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M32',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M33',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M34',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M35',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M36',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M37',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M38',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M39',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M40',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M41',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M42',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M43',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M44',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M45',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M46',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M47',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M48',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M49',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M50',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M51',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M52',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M53',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M54',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M55',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M56',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M57',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M58',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M59',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M60',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M61',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M62',
                'Error Information Handle' => '0x0018',
            },
            {
                'Type' => 'Other',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Microsoft',
                'Array Handle' => '0x0019',
                'Locator' => 'M63',
                'Error Information Handle' => '0x0018',
            }
        ],
        '2' => [
            {
                'Version' => '7.0',
                'Product Name' => 'Virtual Machine',
                'Serial Number' => '2349-2347-2234-2340-2341-3240-48',
                'Manufacturer' => 'Microsoft Corporation'
            }
        ],
        '1' => [
            {
                'Version' => '7.0',
                'Wake-up Type' => 'Power Switch',
                'Product Name' => 'Virtual Machine',
                'Serial Number' => '2349-2347-2234-2340-2341-3240-48',
                'Manufacturer' => 'Microsoft Corporation',
                'UUID' => '3445DEE7-45D0-1244-95DD-34FAA067C1BE33E'
            }
        ],
        '18' => [
            {
                'Type' => 'OK',
            }
        ],
        '0' => [
            {
                'Runtime Size' => '64 kB',
                'Version' => '090004',
                'Address' => '0xF0000',
                'ROM Size' => '256 kB',
                'Release Date' => '03/19/2009',
                'Vendor' => 'American Megatrends Inc.'
            }
        ],
        '23' => [
            {
            'Status' => 'Disabled'
            }
        ],
        '16' => [
            {
                'Number Of Devices' => '64',
                'Error Information Handle' => '0x0018',
                'Maximum Capacity' => '2048 GB',
                'Use' => 'System Memory'
            }
        ],
        '13' => [
            {
                'Installable Languages' => '1',
                'Currently Installed Language' => 'enUS'
            }
        ],
        '3' => [
            {
                'Power Supply State' => 'Safe',
                'Serial Number' => '2349-2347-2234-2340-2341-3240-48',
                'Thermal State' => 'Other',
                'Asset Tag' => '4568-2345-6432-9324-3433-2346-47',
                'Type' => 'Desktop',
                'Version' => '7.0',
                'Security Status' => 'Other',
                'OEM Information' => '0x00000000',
                'Manufacturer' => 'Microsoft Corporation',
                'Boot-up State' => 'Safe'
            }
        ],
        '20' => [
            {
                'Memory Array Mapped Address Handle' => '0x001A',
                'Range Size' => '1048577 kB',
                'Physical Device Handle' => '0x001C',
                'Starting Address' => '0x00000000000',
                'Ending Address' => '0x000400003FF'
            }
        ],
        '8' => [
            {
                'External Reference Designator' => 'USB1',
                'Port Type' => 'USB',
                'External Connector Type' => 'Centronics',
                'Internal Reference Designator' => 'USB',
                'Internal Connector Type' => 'Centronics'
            },
            {
                'External Reference Designator' => 'USB2',
                'Port Type' => 'USB',
                'External Connector Type' => 'Centronics',
                'Internal Reference Designator' => 'USB',
                'Internal Connector Type' => 'Centronics'
            },
            {
                'External Reference Designator' => 'COM1',
                'Port Type' => 'Serial Port 16550A Compatible',
                'External Connector Type' => 'DB-9 female',
                'Internal Reference Designator' => 'COM1',
                'Internal Connector Type' => 'DB-9 female'
            },
            {
                'External Reference Designator' => 'COM2',
                'Port Type' => 'Serial Port 16550A Compatible',
                'External Connector Type' => 'DB-9 female',
                'Internal Reference Designator' => 'COM2',
                'Internal Connector Type' => 'DB-9 female'
            },
            {
                'External Reference Designator' => 'Lpt1',
                'Port Type' => 'Parallel Port ECP/EPP',
                'External Connector Type' => 'DB-25 male',
                'Internal Reference Designator' => 'Printer',
                'Internal Connector Type' => 'DB-25 male'
            },
            {
                'External Reference Designator' => 'Video',
                'Port Type' => 'Video Port',
                'External Connector Type' => 'DB-15 female',
                'Internal Reference Designator' => 'Video',
                'Internal Connector Type' => 'DB-15 male'
            },
            {
                'External Reference Designator' => 'Keyboard',
                'Port Type' => 'Keyboard Port',
                'External Connector Type' => 'PS/2',
                'Internal Reference Designator' => 'Keyboard',
                'Internal Connector Type' => 'PS/2'
            },
            {
                'External Reference Designator' => 'Mouse',
                'Port Type' => 'Mouse Port',
                'External Connector Type' => 'PS/2',
                'Internal Reference Designator' => 'Mouse',
                'Internal Connector Type' => 'PS/2'
            }
        ],
        '4' => [
            {
                'ID' => '7A 06 01 00 FF FB 8B 1F',
                'Status' => 'Populated, Enabled',
                'Max Speed' => '3733 MHz',
                'Family' => 'Xeon',
                'Current Speed' => '2500 MHz',
                'L2 Cache Handle' => 'Not Provided',
                'Type' => 'Central Processor',
                'Signature' => 'Type 0, Family 6, Model 23, Stepping 10',
                'L1 Cache Handle' => 'Not Provided',
                'Manufacturer' => 'GenuineIntel',
                'External Clock' => '266 MHz',
                'Version' => 'Intel Xeon',
                'Voltage' => '1.2 V',
                'L3 Cache Handle' => 'Not Provided'
            },
            {
                'ID' => '00 00 00 00 00 00 00 00',
                'Status' => 'Unpopulated',
                'L2 Cache Handle' => 'Not Provided',
                'Type' => 'Central Processor',
                'L1 Cache Handle' => 'Not Provided',
                'Voltage' => '2.9 V',
                'L3 Cache Handle' => 'Not Provided'
            },
            {
                'ID' => '00 00 00 00 00 00 00 00',
                'Status' => 'Unpopulated',
                'L2 Cache Handle' => 'Not Provided',
                'Type' => 'Central Processor',
                'L1 Cache Handle' => 'Not Provided',
                'Voltage' => '2.9 V',
                'L3 Cache Handle' => 'Not Provided'
                },
            {
                'ID' => '00 00 00 00 00 00 00 00',
                'Status' => 'Unpopulated',
                'L2 Cache Handle' => 'Not Provided',
                'Type' => 'Central Processor',
                'L1 Cache Handle' => 'Not Provided',
                'Voltage' => '2.9 V',
                'L3 Cache Handle' => 'Not Provided'
            },
            {
                'ID' => '00 00 00 00 00 00 00 00',
                'Status' => 'Unpopulated',
                'L2 Cache Handle' => 'Not Provided',
                'Type' => 'Central Processor',
                'L1 Cache Handle' => 'Not Provided',
                'Voltage' => '2.9 V',
                'L3 Cache Handle' => 'Not Provided'
            },
            {
                'ID' => '00 00 00 00 00 00 00 00',
                'Status' => 'Unpopulated',
                'L2 Cache Handle' => 'Not Provided',
                'Type' => 'Central Processor',
                'L1 Cache Handle' => 'Not Provided',
                'Voltage' => '2.9 V',
                'L3 Cache Handle' => 'Not Provided'
            },
            {
                'ID' => '00 00 00 00 00 00 00 00',
                'Status' => 'Unpopulated',
                'L2 Cache Handle' => 'Not Provided',
                'Type' => 'Central Processor',
                'L1 Cache Handle' => 'Not Provided',
                'Voltage' => '2.9 V',
                'L3 Cache Handle' => 'Not Provided'
            },
            {
                'ID' => '00 00 00 00 00 00 00 00',
                'Status' => 'Unpopulated',
                'L2 Cache Handle' => 'Not Provided',
                'Type' => 'Central Processor',
                'L1 Cache Handle' => 'Not Provided',
                'Voltage' => '2.9 V',
                'L3 Cache Handle' => 'Not Provided'
            }
        ],
        '10' => [
            {
                'Type' => 'Video',
                'Status' => 'Enabled',
            }
        ],
        '19' => [
            {
                'Range Size' => '1048577 kB',
                'Partition Width' => '0',
                'Starting Address' => '0x00000000000',
                'Physical Array Handle' => '0x0019',
                'Ending Address' => '0x000400003FF'
            }
        ]
    },
    'windows-xp' => {
        '32' => [
            {
                'Status' => 'No errors detected'
            }
        ],
        '11' => [
            {
                'String 1' => 'Dell System',
                'String 3' => '13[PP04X]',
                'String 2' => '5[0003]'
            }
        ],
        '21' => [
            {
                'Type' => 'Touch Pad',
                'Buttons' => '2',
                'Interface' => 'Bus Mouse'
            }
        ],
        '7' => [
            {
                'Installed Size' => '128 kB',
                'Operational Mode' => 'Write Back',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'System Type' => 'Data',
                'Associativity' => '4-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '128 kB'
            },
            {
                'Installed Size' => '6144 kB',
                'Operational Mode' => 'Varies With Memory Address',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Installed SRAM Type' => 'Pipeline Burst',
                'System Type' => 'Unified',
                'Speed' => '15 ns',
                'Associativity' => 'Other',
                'Location' => 'Internal',
                'Maximum Size' => '6144 kB'
            }
        ],
        '17' => [
            {
                'Part Number' => 'EBE21UE8ACUA-8G-E',
                'Serial Number' => '14FA6621',
                'Data Width' => '64 bits',
                'Array Handle' => '0x1000',
                'Type Detail' => 'Synchronous',
                'Asset Tag' => '200840',
                'Total Width' => '64 bits',
                'Type' => 'DDR2',
                'Speed' => '800 MHz',
                'Size' => '2048 MB',
                'Error Information Handle' => 'Not Provided',
                'Locator' => 'DIMM_A',
                'Manufacturer' => '7F7FFE0000000000',
                'Form Factor' => 'DIMM'
            },
            {
                'Part Number' => 'EBE21UE8ACUA-8G-E',
                'Serial Number' => 'AEF96621',
                'Data Width' => '64 bits',
                'Array Handle' => '0x1000',
                'Type Detail' => 'Synchronous',
                'Asset Tag' => '200840',
                'Total Width' => '64 bits',
                'Type' => 'DDR2',
                'Speed' => '800 MHz',
                'Size' => '2048 MB',
                'Error Information Handle' => 'Not Provided',
                'Locator' => 'DIMM_B',
                'Manufacturer' => '7F7FFE0000000000',
                'Form Factor' => 'DIMM'
            }
        ],
        '2' => [
            {
                'Product Name' => '0P019G',
                'Serial Number' => '.HLG964J.CN129618C52450.',
                'Manufacturer' => 'Dell Inc.'
            }
        ],
        '22' => [
            {
                'Design Capacity' => '84000 mWh',
                'Maximum Error' => '3%',
                'OEM-specific Information' => '0x00000001',
                'Design Voltage' => '11100 mV',
                'SBDS Manufacture Date' => '2010-08-31',
                'SBDS Chemistry' => 'LION',
                'Location' => 'Sys. Battery Bay',
                'Manufacturer' => 'SMP',
                'Name' => 'DELL HJ59008',
                'SBDS Version' => '1.0',
                'SBDS Serial Number' => '02C7'
            }
        ],
        '1' => [
            {
                'Wake-up Type' => 'Power Switch',
                'Product Name' => 'Precision M4400',
                'Serial Number' => 'HLG964J',
                'Manufacturer' => 'Dell Inc.',
                'UUID' => '44454C4C-4C00-1047-8039-C8C04F36344A'
            }
        ],
        '0' => [
            {
                'BIOS Revision' => '2.4',
                'Address' => '0xF0000',
                'Vendor' => 'Dell Inc.',
                'Version' => 'A24',
                'Runtime Size' => '64 kB',
                'Firmware Revision' => '2.4',
                'Release Date' => '08/19/2010',
                'ROM Size' => '1728 kB'
            }
        ],
        '16' => [
            {
                'Number Of Devices' => '2',
                'Error Information Handle' => 'Not Provided',
                'Location' => 'System Board Or Motherboard',
                'Maximum Capacity' => '8 GB',
                'Use' => 'System Memory'
            }
        ],
        '13' => [
            {
                'Language Description Format' => 'Long',
                'Installable Languages' => '1',
                'Currently Installed Language' => 'en|US|iso8859-1'
            }
        ],
        '27' => [
            {
                'Type' => 'Fan',
                'Status' => 'OK',
                'OEM-specific Information' => '0x0000DD00'
            }
        ],
        '28' => [
            {
                'Status' => 'OK',
                'Minimum Value' => '0.0 deg C',
                'OEM-specific Information' => '0x0000DC00',
                'Maximum Value' => '127.0 deg C',
                'Resolution' => '1.000 deg C',
                'Location' => 'Processor',
                'Tolerance' => '0.5 deg C',
                'Description' => 'CPU Internal Temperature'
            }
        ],
        '3' => [
            {
                'Type' => 'Portable',
                'Power Supply State' => 'Safe',
                'Serial Number' => 'HLG964J',
                'Thermal State' => 'Safe',
                'Boot-up State' => 'Safe',
                'Manufacturer' => 'Dell Inc.'
            }
        ],
        '9' => [
            {
                'ID' => 'Adapter 0, Socket 0',
                'Length' => 'Other',
                'Designation' => 'PCMCIA 0',
                'Type' => '32-bit PC Card (PCMCIA)',
                'Current Usage' => 'Available'
            }
        ],
        '20' => [
            {
                'Range Size' => '4 GB',
                'Partition Row Position' => '1',
                'Starting Address' => '0x00000000000',
                'Memory Array Mapped Address Handle' => '0x1301',
                'Physical Device Handle' => '0x1100',
                'Interleaved Data Depth' => '8',
                'Interleave Position' => '1',
                'Ending Address' => '0x000FFFFFFFF'
            },
            {
                'Range Size' => '4 GB',
                'Partition Row Position' => '1',
                'Starting Address' => '0x00000000000',
                'Memory Array Mapped Address Handle' => '0x1301',
                'Physical Device Handle' => '0x1101',
                'Interleaved Data Depth' => '8',
                'Interleave Position' => '2',
                'Ending Address' => '0x000FFFFFFFF'
            }
        ],
        '8' => [
            {
                'Port Type' => 'Parallel Port PS/2',
                'External Connector Type' => 'DB-25 female',
                'Internal Reference Designator' => 'PARALLEL',
            },
            {
                'Port Type' => 'Serial Port 16550A Compatible',
                'External Connector Type' => 'DB-9 male',
                'Internal Reference Designator' => 'SERIAL1',
            },
            {
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)',
                'Internal Reference Designator' => 'USB',
            },
            {
                'Port Type' => 'Video Port',
                'External Connector Type' => 'DB-15 female',
                'Internal Reference Designator' => 'MONITOR',
            },
            {
                'Port Type' => 'Firewire (IEEE P1394)',
                'External Connector Type' => 'IEEE 1394',
                'Internal Reference Designator' => 'FireWire',
            },
            {
                'Port Type' => 'Modem Port',
                'External Connector Type' => 'RJ-11',
                'Internal Reference Designator' => 'Modem',
            },
            {
                'Port Type' => 'Network Port',
                'External Connector Type' => 'RJ-45',
                'Internal Reference Designator' => 'Ethernet',
            }
        ],
        '4' => [
            {
                'ID' => '76 06 01 00 FF FB EB BF',
                'Socket Designation' => 'Microprocessor',
                'Status' => 'Populated, Enabled',
                'Max Speed' => '2534 MHz',
                'Family' => 'Core 2 Duo',
                'Thread Count' => '2',
                'Current Speed' => '2534 MHz',
                'L2 Cache Handle' => '0x0701',
                'Type' => 'Central Processor',
                'Signature' => 'Type 0, Family 6, Model 23, Stepping 6',
                'L1 Cache Handle' => '0x0700',
                'Manufacturer' => 'Intel',
                'Core Enabled' => '2',
                'External Clock' => '266 MHz',
                'Core Count' => '2',
                'Voltage' => '3.3 V',
                'L3 Cache Handle' => 'Not Provided'
            }
        ],
        '10' => [
            {
                'Type' => 'Video',
                'Status' => 'Enabled',
                'Description' => 'NVIDIA Quadro FX 1700M'
            },
            {
                'Type' => 'Sound',
                'Status' => 'Enabled',
                'Description' => 'IDT 92HD71'
            }
        ],
        '19' => [
            {
                'Range Size' => '4 GB',
                'Partition Width' => '1',
                'Starting Address' => '0x00000000000',
                'Physical Array Handle' => '0x1000',
                'Ending Address' => '0x000FFFFFFFF'
            }
        ]
    },
    'windows-7' => {
        '35' => [
            {
                'Threshold Handle' => '0x0035',
                'Management Device Handle' => '0x0034',
                'Component Handle' => '0x0034'
            },
            {
                'Threshold Handle' => '0x0038',
                'Management Device Handle' => '0x0034',
                'Component Handle' => '0x0037'
            },
            {
                'Threshold Handle' => '0x003B',
                'Management Device Handle' => '0x0034',
                'Component Handle' => '0x003A'
            },
            {
                'Threshold Handle' => '0x003E',
                'Management Device Handle' => '0x0034',
                'Component Handle' => '0x003D'
            },
            {
                'Threshold Handle' => '0x003E',
                'Management Device Handle' => '0x0034',
                'Component Handle' => '0x0040'
            },
            {
                'Threshold Handle' => '0x0046',
                'Management Device Handle' => '0x0045',
                'Component Handle' => '0x0045'
            },
            {
                'Threshold Handle' => '0x0049',
                'Management Device Handle' => '0x0045',
                'Component Handle' => '0x0048'
            },
            {
                'Threshold Handle' => '0x004C',
                'Management Device Handle' => '0x0045',
                'Component Handle' => '0x004B'
            },
            {
                'Threshold Handle' => '0x004F',
                'Management Device Handle' => '0x0045',
                'Component Handle' => '0x004E'
            },
            {
                'Threshold Handle' => '0x0052',
                'Management Device Handle' => '0x0045',
                'Component Handle' => '0x0051'
            },
            {
                'Threshold Handle' => '0x0055',
                'Management Device Handle' => '0x0045',
                'Component Handle' => '0x0054'
            },
            {
                'Threshold Handle' => '0x0055',
                'Management Device Handle' => '0x0045',
                'Component Handle' => '0x0057'
            },
            {
                'Threshold Handle' => '0x0055',
                'Management Device Handle' => '0x0045',
                'Component Handle' => '0x005A'
            }
        ],
        '32' => [
            {
            'Status' => 'No errors detected'
            }
        ],
        '7' => [
            {
                'Installed Size' => '256 kB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'L1-Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'Installed SRAM Type' => 'Other',
                'System Type' => 'Unified',
                'Associativity' => '8-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '256 kB'
            },
            {
                'Installed Size' => '1024 kB',
                'Operational Mode' => 'Varies With Memory Address',
                'Socket Designation' => 'L2-Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Installed SRAM Type' => 'Other',
                'System Type' => 'Unified',
                'Associativity' => '8-way Set-associative',
                'Location' => 'Internal',
                'Maximum Size' => '1024 kB'
            },
            {
                'Installed Size' => '6144 kB',
                'Socket Designation' => 'L3-Cache',
                'Configuration' => 'Disabled, Not Socketed, Level 3',
                'Installed SRAM Type' => 'Other',
                'System Type' => 'Unified',
                'Associativity' => 'Other',
                'Location' => 'Internal',
                'Maximum Size' => '6144 kB'
            }
        ],
        '26' => [
            {
                'OEM-specific Information' => '0x00000000',
                'Description' => 'LM78A'
            },
            {
                'OEM-specific Information' => '0x00000000',
                'Description' => 'LM78B'
            },
            {
                'OEM-specific Information' => '0x00000000',
                'Description' => 'LM78B'
            }
        ],
        '17' => [
            {
                'Part Number' => 'Array1_PartNumber0',
                'Serial Number' => 'SerNum0',
                'Type Detail' => 'Synchronous',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Manufacturer0',
                'Bank Locator' => 'BANK0',
                'Array Handle' => '0x0024',
                'Data Width' => '64 bits',
                'Total Width' => '64 bits',
                'Asset Tag' => 'AssetTagNum0',
                'Locator' => 'DIMM0',
                'Error Information Handle' => 'No Error',
                'Form Factor' => 'DIMM'
            },
            {
                'Part Number' => 'F3-12800CL9-2GBXL',
                'Serial Number' => '0000000',
                'Type Detail' => 'Synchronous',
                'Speed' => '1600 MHz',
                'Size' => '2048 MB',
                'Manufacturer' => 'Undefined',
                'Bank Locator' => 'BANK1',
                'Array Handle' => '0x0024',
                'Data Width' => '64 bits',
                'Total Width' => '64 bits',
                'Asset Tag' => 'AssetTagNum1',
                'Rank' => '2',
                'Locator' => 'DIMM1',
                'Error Information Handle' => 'No Error',
                'Form Factor' => 'DIMM'
            },
            {
                'Part Number' => 'Array1_PartNumber2',
                'Serial Number' => 'SerNum2',
                'Type Detail' => 'Synchronous',
                'Size' => 'No Module Installed',
                'Manufacturer' => 'Manufacturer2',
                'Bank Locator' => 'BANK2',
                'Array Handle' => '0x0024',
                'Data Width' => '64 bits',
                'Total Width' => '64 bits',
                'Asset Tag' => 'AssetTagNum2',
                'Locator' => 'DIMM2',
                'Error Information Handle' => 'No Error',
                'Form Factor' => 'DIMM'
            },
            {
                'Part Number' => 'F3-12800CL9-2GBXL',
                'Serial Number' => '0000000',
                'Type Detail' => 'Synchronous',
                'Speed' => '1600 MHz',
                'Size' => '2048 MB',
                'Manufacturer' => 'Undefined',
                'Bank Locator' => 'BANK3',
                'Array Handle' => '0x0024',
                'Data Width' => '64 bits',
                'Total Width' => '64 bits',
                'Asset Tag' => 'AssetTagNum3',
                'Rank' => '2',
                'Locator' => 'DIMM3',
                'Error Information Handle' => 'No Error',
                'Form Factor' => 'DIMM'
            }
        ],
        '2' => [
            {
                'Product Name' => 'P8P67',
                'Chassis Handle' => '0x0003',
                'Serial Number' => 'MT7013K30709271',
                'Version' => 'Rev 1.xx',
                'Type' => 'Motherboard',
                'Manufacturer' => 'ASUSTeK Computer INC.',
                'Contained Object Handles' => '0'
            }
        ],
        '1' => [
            {
                'Wake-up Type' => 'Power Switch',
                'UUID' => '1E00E6E0-008C-4400-9AAD-F46D04972D3E'
            }
        ],
        '18' => [
            {
                'Type' => 'OK',
            },
            {
                'Type' => 'OK',
            },
            {
                'Type' => 'OK',
            },
            {
                'Type' => 'OK',
            },
            {
                'Type' => 'OK',
            }
        ],
        '0' => [
            {
                'Runtime Size' => '64 kB',
                'Version' => '1503',
                'BIOS Revision' => '4.6',
                'Address' => '0xF0000',
                'ROM Size' => '4096 kB',
                'Release Date' => '03/10/2011',
                'Vendor' => 'American Megatrends Inc.'
            }
        ],
        '13' => [
            {
                'Installable Languages' => '6',
                'Currently Installed Language' => 'eng'
            }
        ],
        '16' => [
            {
                'Number Of Devices' => '4',
                'Error Information Handle' => 'No Error',
                'Location' => 'System Board Or Motherboard',
                'Maximum Capacity' => '32 GB',
                'Use' => 'System Memory'
            }
        ],
        '29' => [
            {
                'OEM-specific Information' => '0x00000000',
                'Description' => 'ABC'
            },
            {
                'OEM-specific Information' => '0x00000000',
                'Description' => 'DEF'
            },
            {
                'OEM-specific Information' => '0x00000000',
                'Description' => 'GHI'
            }
        ],
        '27' => [
            {
                'Temperature Probe Handle' => '0x0038',
                'OEM-specific Information' => '0x00000000',
                'Cooling Unit Group' => '1',
                'Nominal Speed' => 'Unknown Or Non-rotating'
            },
            {
                'Temperature Probe Handle' => '0x0038',
                'OEM-specific Information' => '0x00000000',
                'Cooling Unit Group' => '1',
                'Nominal Speed' => 'Unknown Or Non-rotating'
            },
            {
                'Temperature Probe Handle' => '0x004C',
                'OEM-specific Information' => '0x00000000',
                'Cooling Unit Group' => '1',
                'Nominal Speed' => 'Unknown Or Non-rotating'
            },
            {
                'Temperature Probe Handle' => '0x0052',
                'OEM-specific Information' => '0x00000000',
                'Cooling Unit Group' => '1',
                'Nominal Speed' => 'Unknown Or Non-rotating'
            }
        ],
        '39' => [
            {
                'Input Voltage Probe Handle' => '0x0035',
                'Hot Replaceable' => 'No',
                'Input Current Probe Handle' => '0x0041',
                'Cooling Device Handle' => '0x003B',
                'Plugged' => 'Yes',
                'Power Unit Group' => '1',
            },
            {
                'Input Voltage Probe Handle' => '0x0035',
                'Hot Replaceable' => 'No',
                'Input Current Probe Handle' => '0x0041',
                'Cooling Device Handle' => '0x003B',
                'Plugged' => 'Yes',
                'Power Unit Group' => '1',
            }
        ],
        '28' => [
            {
                'OEM-specific Information' => '0x00000000',
                'Description' => 'LM78A'
            },
            {
                'OEM-specific Information' => '0x00000000',
                'Description' => 'LM78B'
            },
            {
                'OEM-specific Information' => '0x00000000',
                'Description' => 'LM78B'
            }
        ],
        '36' => [
            {
                'Lower Non-critical Threshold' => '1',
                'Upper Critical Threshold' => '4',
                'Lower Critical Threshold' => '3',
                'Lower Non-recoverable Threshold' => '5',
                'Upper Non-recoverable Threshold' => '6',
                'Upper Non-critical Threshold' => '2'
            },
            {
                'Lower Non-critical Threshold' => '1',
                'Upper Critical Threshold' => '4',
                'Lower Critical Threshold' => '3',
                'Lower Non-recoverable Threshold' => '5',
                'Upper Non-recoverable Threshold' => '6',
                'Upper Non-critical Threshold' => '2'
            },
            {
                'Lower Non-critical Threshold' => '1',
                'Upper Critical Threshold' => '4',
                'Lower Critical Threshold' => '3',
                'Lower Non-recoverable Threshold' => '5',
                'Upper Non-recoverable Threshold' => '6',
                'Upper Non-critical Threshold' => '2'
            },
            {
                'Lower Non-critical Threshold' => '1',
                'Upper Critical Threshold' => '4',
                'Lower Critical Threshold' => '3',
                'Lower Non-recoverable Threshold' => '5',
                'Upper Non-recoverable Threshold' => '6',
                'Upper Non-critical Threshold' => '2'
            },
            {
                'Lower Non-critical Threshold' => '7',
                'Upper Critical Threshold' => '10',
                'Lower Critical Threshold' => '8',
                'Lower Non-recoverable Threshold' => '11',
                'Upper Non-recoverable Threshold' => '12',
                'Upper Non-critical Threshold' => '8'
            },
            {
                'Lower Non-critical Threshold' => '13',
                'Upper Critical Threshold' => '16',
                'Lower Critical Threshold' => '15',
                'Lower Non-recoverable Threshold' => '17',
                'Upper Non-recoverable Threshold' => '18',
                'Upper Non-critical Threshold' => '14'
            },
            {
                'Lower Non-critical Threshold' => '1',
                'Upper Critical Threshold' => '4',
                'Lower Critical Threshold' => '3',
                'Lower Non-recoverable Threshold' => '5',
                'Upper Non-recoverable Threshold' => '6',
                'Upper Non-critical Threshold' => '2'
            },
            {
                'Lower Non-critical Threshold' => '1',
                'Upper Critical Threshold' => '4',
                'Lower Critical Threshold' => '3',
                'Lower Non-recoverable Threshold' => '5',
                'Upper Non-recoverable Threshold' => '6',
                'Upper Non-critical Threshold' => '2'
            },
            {
                'Lower Non-critical Threshold' => '1',
                'Upper Critical Threshold' => '4',
                'Lower Critical Threshold' => '3',
                'Lower Non-recoverable Threshold' => '5',
                'Upper Non-recoverable Threshold' => '6',
                'Upper Non-critical Threshold' => '2'
            },
            {
                'Lower Non-critical Threshold' => '1',
                'Upper Critical Threshold' => '4',
                'Lower Critical Threshold' => '3',
                'Lower Non-recoverable Threshold' => '5',
                'Upper Non-recoverable Threshold' => '6',
                'Upper Non-critical Threshold' => '2'
            }
        ],
        '3' => [
            {
                'Height' => 'Unspecified',
                'Power Supply State' => 'Safe',
                'Thermal State' => 'Safe',
                'Contained Elements' => '0',
                'Asset Tag' => 'Asset-1234567890',
                'Type' => 'Desktop',
                'Number Of Power Cords' => '1',
                'OEM Information' => '0x00000000',
                'Boot-up State' => 'Safe'
            }
        ],
        '9' => [
            {
                'Bus Address' => '0000:00:01.0',
                'ID' => '1',
                'Length' => 'Short',
                'Designation' => 'PCIEX16_1',
                'Type' => '32-bit PCI Express',
                'Current Usage' => 'In Use'
            },
            {
                'Bus Address' => '0000:00:1c.3',
                'ID' => '2',
                'Length' => 'Short',
                'Designation' => 'PCIEX1_1',
                'Type' => '32-bit PCI Express',
                'Current Usage' => 'In Use'
            },
            {
                'Bus Address' => '0000:00:1c.4',
                'ID' => '3',
                'Length' => 'Short',
                'Designation' => 'PCIEX1_2',
                'Type' => '32-bit PCI Express',
                'Current Usage' => 'In Use'
            },
            {
                'Bus Address' => '0000:00:1c.6',
                'ID' => '4',
                'Length' => 'Short',
                'Designation' => 'PCI1',
                'Type' => '32-bit PCI',
                'Current Usage' => 'In Use'
            }
        ],
        '41' => [
            {
                'Bus Address' => '0000:00:02.0',
                'Type' => 'Video',
                'Reference Designation' => 'Onboard IGD',
                'Type Instance' => '1',
                'Status' => 'Enabled'
            },
            {
                'Bus Address' => '0000:00:19.0',
                'Type' => 'Ethernet',
                'Reference Designation' => 'Onboard LAN',
                'Type Instance' => '1',
                'Status' => 'Enabled'
            },
            {
                'Bus Address' => '0000:03:1c.2',
                'Type' => 'Other',
                'Reference Designation' => 'Onboard 1394',
                'Type Instance' => '1',
                'Status' => 'Enabled'
            }
        ],
        '20' => [
            {
                'Memory Array Mapped Address Handle' => '0x0026',
                'Range Size' => '2 GB',
                'Physical Device Handle' => '0x002A',
                'Partition Row Position' => '1',
                'Starting Address' => '0x00000000000',
                'Ending Address' => '0x0007FFFFFFF'
            },
            {
                'Memory Array Mapped Address Handle' => '0x0026',
                'Range Size' => '2 GB',
                'Physical Device Handle' => '0x0030',
                'Partition Row Position' => '1',
                'Starting Address' => '0x00080000000',
                'Ending Address' => '0x000FFFFFFFF'
            }
        ],
        '8' => [
            {
                'External Reference Designator' => 'PS/2 Keyboard',
                'Port Type' => 'Keyboard Port',
                'External Connector Type' => 'PS/2',
                'Internal Reference Designator' => 'PS/2 Keyboard',
            },
            {
                'External Reference Designator' => 'USB9_10',
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)',
                'Internal Reference Designator' => 'USB9_10',
            },
            {
                'External Reference Designator' => 'USB11_12',
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)',
                'Internal Reference Designator' => 'USB11_12',
            },
            {
                'External Reference Designator' => 'GbE LAN',
                'Port Type' => 'Network Port',
                'External Connector Type' => 'RJ-45',
                'Internal Reference Designator' => 'GbE LAN',
            },
            {
                'External Reference Designator' => 'AUDIO',
                'Port Type' => 'Audio Port',
                'External Connector Type' => 'Other',
                'Internal Reference Designator' => 'AUDIO',
            },
            {
                'Port Type' => 'SATA',
                'Internal Reference Designator' => 'SATA1',
                'Internal Connector Type' => 'SAS/SATA Plug Receptacle'
            },
            {
                'Port Type' => 'SATA',
                'Internal Reference Designator' => 'SATA2',
                'Internal Connector Type' => 'SAS/SATA Plug Receptacle'
            },
            {
                'Port Type' => 'SATA',
                'Internal Reference Designator' => 'SATA3',
                'Internal Connector Type' => 'SAS/SATA Plug Receptacle'
            },
            {
                'Port Type' => 'SATA',
                'Internal Reference Designator' => 'SATA4',
                'Internal Connector Type' => 'SAS/SATA Plug Receptacle'
            },
            {
                'Port Type' => 'SATA',
                'Internal Reference Designator' => 'SATA5',
                'Internal Connector Type' => 'SAS/SATA Plug Receptacle'
            },
            {
                'Port Type' => 'SATA',
                'Internal Reference Designator' => 'SATA6',
                'Internal Connector Type' => 'SAS/SATA Plug Receptacle'
            },
            {
                'Port Type' => 'USB',
                'Internal Reference Designator' => 'USB1_2',
                'Internal Connector Type' => 'Access Bus (USB)'
            },
            {
                'Port Type' => 'USB',
                'Internal Reference Designator' => 'USB3_4',
                'Internal Connector Type' => 'Access Bus (USB)'
            },
            {
                'Port Type' => 'USB',
                'Internal Reference Designator' => 'USB5_6',
                'Internal Connector Type' => 'Access Bus (USB)'
            },
            {
                'Port Type' => 'USB',
                'Internal Reference Designator' => 'USB7_8',
                'Internal Connector Type' => 'Access Bus (USB)'
            },
            {
                'Port Type' => 'Audio Port',
                'Internal Reference Designator' => 'AAFP',
                'Internal Connector Type' => 'Mini Jack (headphones)'
            },
            {
                'Port Type' => 'Other',
                'Internal Reference Designator' => 'CPU_FAN',
                'Internal Connector Type' => 'Other'
            },
            {
                'Port Type' => 'Other',
                'Internal Reference Designator' => 'CHA_FAN1',
                'Internal Connector Type' => 'Other'
            },
            {
                'Port Type' => 'Other',
                'Internal Reference Designator' => 'PWR_FAN',
                'Internal Connector Type' => 'Other'
            },
            {
                'Port Type' => 'Other',
                'Internal Reference Designator' => 'PATA_IDE',
                'Internal Connector Type' => 'On Board IDE'
            },
            {
                'Port Type' => 'SATA',
                'Internal Reference Designator' => 'F_ESATA',
                'Internal Connector Type' => 'SAS/SATA Plug Receptacle'
            }
        ],
        '4' => [
            {
                'ID' => 'A7 06 02 00 FF FB EB BF',
                'Socket Designation' => 'LGA1155',
                'Status' => 'Populated, Enabled',
                'Max Speed' => '3800 MHz',
                'Family' => 'Core 2 Duo',
                'Current Speed' => '2800 MHz',
                'L2 Cache Handle' => '0x0006',
                'Type' => 'Central Processor',
                'Signature' => 'Type 0, Family 6, Model 42, Stepping 7',
                'L1 Cache Handle' => '0x0005',
                'Manufacturer' => 'Intel',
                'Core Enabled' => '1',
                'External Clock' => '100 MHz',
                'Version' => 'Intel(R) Core(TM) i5-2300 CPU @ 2.80GHz',
                'Core Count' => '4',
                'Upgrade' => 'Other',
                'Voltage' => '1.0 V',
                'L3 Cache Handle' => '0x0007'
            }
        ],
        '34' => [
            {
                'Type' => 'LM78',
                'Address Type' => 'I/O Port',
                'Address' => '0x00000000',
                'Description' => 'LM78-1'
            },
            {
                'Type' => 'LM78',
                'Address Type' => 'I/O Port',
                'Address' => '0x00000000',
                'Description' => '2'
            }
        ],
        '10' => [
            {
                'Type' => 'Ethernet',
                'Status' => 'Enabled',
                'Description' => 'Onboard Ethernet'
            }
        ],
        '19' => [
            {
                'Range Size' => '4 GB',
                'Partition Width' => '0',
                'Starting Address' => '0x00000000000',
                'Physical Array Handle' => '0x0024',
                'Ending Address' => '0x000FFFFFFFF'
            }
        ]
    },
    'windows-7.2' => {
        '20' => [
            {
                'Physical Device Handle' => '0x003D',
                'Partition Row Position' => '1',
                'Memory Array Mapped Address Handle' => '0x003C',
                'Ending Address' => '0x0007FFFFFFF',
                'Range Size' => '2 GB',
                'Starting Address' => '0x00000000000'
            },
            {
                'Physical Device Handle' => '0x003F',
                'Memory Array Mapped Address Handle' => '0x003C',
                'Partition Row Position' => '1',
                'Range Size' => '2 GB',
                'Starting Address' => '0x00080000000',
                'Ending Address' => '0x000FFFFFFFF'
            },
            {
                'Ending Address' => '0x0013FFFFFFF',
                'Range Size' => '1 GB',
                'Starting Address' => '0x00100000000',
                'Partition Row Position' => '1',
                'Memory Array Mapped Address Handle' => '0x003C',
                'Physical Device Handle' => '0x0041'
            },
            {
                'Starting Address' => '0x00140000000',
                'Range Size' => '1 GB',
                'Ending Address' => '0x0017FFFFFFF',
                'Memory Array Mapped Address Handle' => '0x003C',
                'Partition Row Position' => '1',
                'Physical Device Handle' => '0x0043'
            }
        ],
        '16' => [
            {
                'Maximum Capacity' => '8 GB',
                'Error Information Handle' => 'Not Provided',
                'Use' => 'System Memory',
                'Number Of Devices' => '4',
                'Location' => 'System Board Or Motherboard'
            }
        ],
        '19' => [
            {
                'Ending Address' => '0x0019FFFFFFF',
                'Range Size' => '6656 MB',
                'Physical Array Handle' => '0x003B',
                'Starting Address' => '0x00000000000',
                'Partition Width' => '1'
            }
        ],
        '32' => [
            {
                'Status' => 'No errors detected'
            }
        ],
        '1' => [
            {
                'Wake-up Type' => 'Power Switch',
                'UUID' => '0002869A-8EFE-D511-868C-002618C9DFD4'
            }
        ],
        '7' => [
            {
                'Error Correction Type' => 'Single-bit ECC',
                'Associativity' => '4-way Set-associative',
                'Maximum Size' => '256 kB',
                'Operational Mode' => 'Varies With Memory Address',
                'Socket Designation' => 'L1-Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'Installed Size' => '256 kB',
                'System Type' => 'Data',
                'Installed SRAM Type' => 'Pipeline Burst',
                'Location' => 'Internal'
            },
            {
                'Operational Mode' => 'Varies With Memory Address',
                'Error Correction Type' => 'Single-bit ECC',
                'Associativity' => '4-way Set-associative',
                'Maximum Size' => '2048 kB',
                'Installed Size' => '2048 kB',
                'System Type' => 'Unified',
                'Location' => 'Internal',
                'Installed SRAM Type' => 'Pipeline Burst',
                'Socket Designation' => 'L2-Cache',
                'Configuration' => 'Enabled, Not Socketed, Level 2'
            },
            {
                'Socket Designation' => 'L3-Cache',
                'Maximum Size' => '0 kB',
                'Configuration' => 'Disabled, Not Socketed, Level 3',
                'Installed Size' => '0 kB',
                'Location' => 'Internal'
            }
        ],
        '4' => [
            {
                'Status' => 'Populated, Enabled',
                'Max Speed' => '3200 MHz',
                'Socket Designation' => 'AM2',
                'ID' => '62 0F 10 00 FF FB 8B 17',
                'Type' => 'Central Processor',
                'External Clock' => '200 MHz',
                'L2 Cache Handle' => '0x0006',
                'Current Speed' => '2900 MHz',
                'L3 Cache Handle' => '0x0007',
                'L1 Cache Handle' => '0x0005',
                'Signature' => 'Family 16, Model 6, Stepping 2',
                'Core Enabled' => '2',
                'Voltage' => '1.5 V',
                'Version' => 'AMD Athlon(tm) II X2 245 Processor',
                'Family' => 'Athlon II',
                'Core Count' => '2',
                'Manufacturer' => 'AMD',
                'Upgrade' => 'Other'
            }
        ],
        '9' => [
            {
                'Length' => 'Short',
                'Current Usage' => 'In Use',
                'Designation' => 'PCIE1X',
                'ID' => '4',
                'Type' => '32-bit PCI Express'
            },
            {
                'Current Usage' => 'Available',
                'Length' => 'Short',
                'Designation' => 'PCIE16X',
                'Type' => '32-bit PCI Express',
                'ID' => '2'
            },
            {
                'Current Usage' => 'Available',
                'Length' => 'Short',
                'Type' => '32-bit PCI',
                'ID' => '3',
                'Designation' => 'PCI1'
            },
            {
                'Current Usage' => 'Available',
                'Length' => 'Short',
                'ID' => '1',
                'Type' => '32-bit PCI',
                'Designation' => 'PCI2'
            }
        ],
        '17' => [
            {
                'Speed' => '667 MHz',
                'Serial Number' => 'SerNum0',
                'Total Width' => '64 bits',
                'Part Number' => 'PartNum0',
                'Bank Locator' => 'BANK0',
                'Type Detail' => 'Synchronous',
                'Size' => '2048 MB',
                'Form Factor' => 'DIMM',
                'Manufacturer' => 'Manufacturer0',
                'Error Information Handle' => 'Not Provided',
                'Type' => 'DDR2',
                'Asset Tag' => 'AssetTagNum0',
                'Array Handle' => '0x003B',
                'Locator' => 'DIMM0',
                'Data Width' => '64 bits'
            },
            {
                'Data Width' => '64 bits',
                'Locator' => 'DIMM1',
                'Asset Tag' => 'AssetTagNum1',
                'Array Handle' => '0x003B',
                'Error Information Handle' => 'Not Provided',
                'Type' => 'DDR2',
                'Manufacturer' => 'Manufacturer1',
                'Size' => '2048 MB',
                'Form Factor' => 'DIMM',
                'Type Detail' => 'Synchronous',
                'Bank Locator' => 'BANK1',
                'Part Number' => 'PartNum1',
                'Total Width' => '64 bits',
                'Speed' => '667 MHz',
                'Serial Number' => 'SerNum1'
            },
            {
                'Locator' => 'DIMM2',
                'Data Width' => '64 bits',
                'Error Information Handle' => 'Not Provided',
                'Type' => 'DDR2',
                'Asset Tag' => 'AssetTagNum2',
                'Array Handle' => '0x003B',
                'Bank Locator' => 'BANK2',
                'Type Detail' => 'Synchronous',
                'Size' => '1024 MB',
                'Form Factor' => 'DIMM',
                'Manufacturer' => 'Manufacturer2',
                'Speed' => '667 MHz',
                'Serial Number' => 'SerNum2',
                'Total Width' => '64 bits',
                'Part Number' => 'PartNum2'
            },
            {
                'Type Detail' => 'Synchronous',
                'Bank Locator' => 'BANK3',
                'Form Factor' => 'DIMM',
                'Size' => '1024 MB',
                'Manufacturer' => 'Manufacturer3',
                'Speed' => '667 MHz',
                'Serial Number' => 'SerNum3',
                'Total Width' => '64 bits',
                'Part Number' => 'PartNum3',
                'Locator' => 'DIMM3',
                'Data Width' => '64 bits',
                'Type' => 'DDR2',
                'Error Information Handle' => 'Not Provided',
                'Array Handle' => '0x003B',
                'Asset Tag' => 'AssetTagNum3'
            }
        ],
        '2' => [
            {
                'Product Name' => 'M3A78-CM',
                'Serial Number' => 'MF7097G05100710',
                'Type' => 'Motherboard',
                'Version' => 'Rev X.0x',
                'Manufacturer' => 'ASUSTeK Computer INC.',
                'Chassis Handle' => '0x0003',
                'Contained Object Handles' => '0'
            }
        ],
        '8' => [
            {
                'Internal Reference Designator' => 'PS/2 KeyBoard',
                'External Reference Designator' => 'Keyboard',
                'External Connector Type' => 'PS/2',
                'Port Type' => 'Keyboard Port'
            },
            {
                'Internal Reference Designator' => 'USB1',
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB1'
            },
            {
                'Internal Reference Designator' => 'USB2',
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB2',
                'Port Type' => 'USB'
            },
            {
                'Internal Reference Designator' => 'USB3',
                'Port Type' => 'USB',
                'External Reference Designator' => 'USB3',
                'External Connector Type' => 'Access Bus (USB)'
            },
            {
                'Internal Reference Designator' => 'USB4',
                'Port Type' => 'USB',
                'External Reference Designator' => 'USB4',
                'External Connector Type' => 'Access Bus (USB)'
            },
            {
                'Internal Reference Designator' => 'USB5',
                'Port Type' => 'USB',
                'External Reference Designator' => 'USB5',
                'External Connector Type' => 'Access Bus (USB)'
            },
            {
                'Port Type' => 'USB',
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB6',
                'Internal Reference Designator' => 'USB6'
            },
            {
                'External Reference Designator' => 'LPT 1',
                'External Connector Type' => 'DB-25 male',
                'Port Type' => 'Parallel Port ECP/EPP',
                'Internal Reference Designator' => 'LPT 1',
            },
            {
                'Port Type' => 'Serial Port 16550A Compatible',
                'External Reference Designator' => 'COM 1',
                'External Connector Type' => 'DB-9 male',
                'Internal Reference Designator' => 'COM 1'
            },
            {
                'Port Type' => 'Network Port',
                'External Reference Designator' => 'LAN',
                'External Connector Type' => 'RJ-45',
                'Internal Reference Designator' => 'LAN'
            },
            {
                'Internal Reference Designator' => 'Audio_Line_In',
                'External Connector Type' => 'Mini Jack (headphones)',
                'External Reference Designator' => 'Audio_Line_In',
                'Port Type' => 'Audio Port'
            },
            {
                'Internal Reference Designator' => 'Audio_Line_Out',
                'External Connector Type' => 'Mini Jack (headphones)',
                'External Reference Designator' => 'Audio_Line_Out',
                'Port Type' => 'Audio Port'
            },
            {
                'Internal Reference Designator' => 'Audio_Mic_In',
                'Port Type' => 'Audio Port',
                'External Connector Type' => 'Mini Jack (headphones)',
                'External Reference Designator' => 'Audio_Mic_In'
            },
            {
                'Internal Reference Designator' => 'Audio_Center/Sub',
                'Port Type' => 'Audio Port',
                'External Connector Type' => 'Mini Jack (headphones)',
                'External Reference Designator' => 'Audio_Center/Sub'
            },
            {
                'Internal Reference Designator' => 'Audio_Rear',
                'Port Type' => 'Audio Port',
                'External Reference Designator' => 'Audio_Rear',
                'External Connector Type' => 'Mini Jack (headphones)'
            },
            {
                'Internal Reference Designator' => 'Audio_Side',
                'External Connector Type' => 'Mini Jack (headphones)',
                'External Reference Designator' => 'Audio_Side',
                'Port Type' => 'Audio Port'
            },
            {
                'Internal Reference Designator' => 'Display_Port',
                'Port Type' => 'Other',
                'External Connector Type' => 'Other',
                'External Reference Designator' => 'Display_Port port'
            },
            {
                'Internal Reference Designator' => 'DVI',
                'External Connector Type' => 'Other',
                'External Reference Designator' => 'DVI port',
                'Port Type' => 'Other'
            },
            {
                'Port Type' => 'Other',
                'Internal Connector Type' => 'On Board IDE',
                'Internal Reference Designator' => 'PRI IDE'
            },
            {
                'Port Type' => 'Other',
                'Internal Connector Type' => 'Other',
                'Internal Reference Designator' => 'SB_SATA1'
            },
            {
                'Port Type' => 'Other',
                'Internal Connector Type' => 'Other',
                'Internal Reference Designator' => 'SB_SATA2'
            },
            {
                'Port Type' => 'Other',
                'Internal Reference Designator' => 'SB_SATA3',
                'Internal Connector Type' => 'Other'
            },
            {
                'Internal Connector Type' => 'Other',
                'Internal Reference Designator' => 'SB_SATA4',
                'Port Type' => 'Other',
            },
            {
                'Port Type' => 'Other',
                'Internal Connector Type' => 'Other',
                'Internal Reference Designator' => 'SB_SATA5'
            },
            {
                'Internal Reference Designator' => 'SB_SATA6',
                'Internal Connector Type' => 'Other',
                'Port Type' => 'Other'
            },
            {
                'Internal Reference Designator' => 'CPU FAN',
                'Internal Connector Type' => 'Other',
                'Port Type' => 'Other'
            },
            {
                'Internal Connector Type' => 'Other',
                'Internal Reference Designator' => 'PWR FAN',
                'Port Type' => 'Other',
            },
            {
                'Internal Connector Type' => 'Other',
                'Internal Reference Designator' => 'CHA FAN',
                'Port Type' => 'Other',
            },
            {
                'Port Type' => 'USB',
                'Internal Reference Designator' => 'USB7',
                'Internal Connector Type' => 'Access Bus (USB)'
            },
            {
                'Internal Connector Type' => 'Access Bus (USB)',
                'Internal Reference Designator' => 'USB8',
                'Port Type' => 'USB',
            },
            {
                'Internal Connector Type' => 'Access Bus (USB)',
                'Internal Reference Designator' => 'USB9',
                'Port Type' => 'USB',
            },
            {
                'Internal Reference Designator' => 'USB10',
                'Internal Connector Type' => 'Access Bus (USB)',
                'Port Type' => 'USB'
            },
            {
                'Port Type' => 'USB',
                'Internal Reference Designator' => 'USB11',
                'Internal Connector Type' => 'Access Bus (USB)'
            },
            {
                'Port Type' => 'USB',
                'Internal Reference Designator' => 'USB12',
                'Internal Connector Type' => 'Access Bus (USB)'
            },
            {
                'Internal Reference Designator' => 'PANEL',
                'Internal Connector Type' => '9 Pin Dual Inline (pin 10 cut)',
                'Port Type' => 'Other'
            },
            {
                'Port Type' => 'Other',
                'Internal Connector Type' => 'Other',
                'Internal Reference Designator' => 'SPDIF OUT'
            },
            {
                'Internal Connector Type' => 'Other',
                'Internal Reference Designator' => 'AAFP',
                'Port Type' => 'Other',
            },
            {
                'Internal Reference Designator' => 'CD',
                'Internal Connector Type' => 'On Board Sound Input From CD-ROM',
                'Port Type' => 'Audio Port'
            },
            {
                'Port Type' => 'Other',
                'Internal Connector Type' => 'Other',
                'Internal Reference Designator' => 'TPM'
            },
            {
                'Internal Connector Type' => 'Other',
                'Internal Reference Designator' => 'Speaker',
                'Port Type' => 'Other',
            }
        ],
        '0' => [
            {
                'BIOS Revision' => '8.14',
                'Runtime Size' => '64 kB',
                'Version' => '2003',
                'Release Date' => '06/26/2009',
                'ROM Size' => '1024 kB',
                'Address' => '0xF0000',
                'Vendor' => 'American Megatrends Inc.'
            }
        ],
        '10' => [
            {
                'Type' => 'Other',
                'Status' => 'Enabled'
            },
            {
                'Status' => 'Enabled',
                'Type' => 'Ethernet',
            },
            {
                'Status' => 'Enabled',
                'Type' => 'Sound',
            },
            {
                'Type' => 'Other',
                'Status' => 'Enabled'
            }
        ],
        '15' => [
            {
                'Header Start Offset' => '0x0000',
                'Data Format 4' => 'OEM-specific',
                'Data Format 6' => 'OEM-specific',
                'Access Address' => 'Index 0x046A, Data 0x046C',
                'Descriptor 6' => 'End of log',
                'Change Token' => '0x00000000',
                'Descriptor 5' => 'End of log',
                'Descriptor 1' => 'End of log',
                'Descriptor 2' => 'End of log',
                'Data Format 3' => 'OEM-specific',
                'Supported Log Type Descriptors' => '6',
                'Header Format' => 'No Header',
                'Descriptor 3' => 'End of log',
                'Data Format 1' => 'OEM-specific',
                'Status' => 'Invalid, Not Full',
                'Descriptor 4' => 'End of log',
                'Data Format 2' => 'OEM-specific',
                'Area Length' => '4 bytes',
                'Data Format 5' => 'OEM-specific',
                'Data Start Offset' => '0x0002',
                'Header Length' => '2 bytes',
                'Access Method' => 'Indexed I/O, one 16-bit index port, one 8-bit data port'
            }
        ],
        '13' => [
            {
                'Currently Installed Language' => 'en|US|iso8859-1',
                'Language Description Format' => 'Abbreviated',
                'Installable Languages' => '1'
            }
        ],
        '3' => [
            {
                'Type' => 'Desktop',
                'Thermal State' => 'Safe',
                'Asset Tag' => 'Asset-1234567890',
                'Number Of Power Cords' => '1',
                'OEM Information' => '0x00000001',
                'Contained Elements' => '0',
                'Power Supply State' => 'Safe',
                'Boot-up State' => 'Safe',
                'Height' => 'Unspecified'
            }
        ]
    },
    'lenovo-thinkpad' =>     {
        '0' => [
            {
                'Address' => '0xE0000',
                'BIOS Revision' => '24.216',
                'Firmware Revision' => '1.16',
                'ROM Size' => '4096 kB',
                'Release Date' => '12/01/2011',
                'Runtime Size' => '128 kB',
                'Vendor' => 'LENOVO',
                'Version' => '8NET32WW (1.16 )'
            }
        ],
        '1' => [
            {
                'Manufacturer' => 'LENOVO',
                'Product Name' => '1298A8G',
                'SKU Number' => 'ThinkPad Edge E320',
                'Serial Number' => 'LR9NKZ7',
                'UUID' => '725BA801-507B-11CB-95E6-C66052AAC597',
                'Version' => 'ThinkPad Edge E320',
                'Wake-up Type' => 'Power Switch'
            }
        ],
        '10' => [
            {
                'Description' => 'Intel(R) Extreme Graphics 3 Controller',
                'Status' => 'Enabled',
                'Type' => 'Video'
            },
            {
                'Description' => 'Intel(R) Azalia Audio Device',
                'Status' => 'Enabled',
                'Type' => 'Sound'
            }
        ],
        '11' => [
            {
                'String 1' => 'This is the Intel HuronRiver CRB Platform'
            }
        ],
        '13' => [
            {
                'Currently Installed Language' => 'en-US',
                'Installable Languages' => '4',
                'Language Description Format' => 'Abbreviated'
            }
        ],
        '15' => [
            {
                'Access Address' => '0x00F0',
                'Access Method' => 'General-purpose non-volatile data functions',
                'Area Length' => '18 bytes',
                'Change Token' => '0x00000000',
                'Data Format 1' => 'POST results bitmap',
                'Data Format 2' => 'Multiple-event',
                'Data Format 3' => 'Multiple-event',
                'Data Start Offset' => '0x0010',
                'Descriptor 1' => 'POST error',
                'Descriptor 2' => 'Single-bit ECC memory error',
                'Descriptor 3' => 'Multi-bit ECC memory error',
                'Header Format' => 'Type 1',
                'Header Length' => '16 bytes',
                'Header Start Offset' => '0x0000',
                'Status' => 'Valid, Not Full',
                'Supported Log Type Descriptors' => '3'
            }
        ],
        '16' => [
            {
                'Error Information Handle' => 'Not Provided',
                'Location' => 'System Board Or Motherboard',
                'Maximum Capacity' => '16 GB',
                'Number Of Devices' => '4',
                'Use' => 'System Memory'
            }
        ],
        '17' => [
            {
                'Array Handle' => '0x0005',
                'Asset Tag' => '9876543210',
                'Bank Locator' => 'BANK 0',
                'Data Width' => '64 bits',
                'Error Information Handle' => 'Not Provided',
                'Form Factor' => 'SODIMM',
                'Locator' => 'ChannelA-DIMM0',
                'Manufacturer' => 'Samsung',
                'Part Number' => 'M471B5273CH0-CH9',
                'Serial Number' => 'B52A5D9F',
                'Size' => '4096 MB',
                'Speed' => '1333 MHz',
                'Total Width' => '64 bits',
                'Type' => 'DDR3',
                'Type Detail' => 'Synchronous'
            },
            {
                'Array Handle' => '0x0005',
                'Asset Tag' => '9876543210',
                'Bank Locator' => 'BANK 1',
                'Error Information Handle' => 'Not Provided',
                'Form Factor' => 'DIMM',
                'Locator' => 'ChannelA-DIMM1',
                'Size' => 'No Module Installed',
            },
            {
                'Array Handle' => '0x0005',
                'Asset Tag' => '9876543210',
                'Bank Locator' => 'BANK 2',
                'Data Width' => '64 bits',
                'Error Information Handle' => 'Not Provided',
                'Form Factor' => 'SODIMM',
                'Locator' => 'ChannelB-DIMM0',
                'Manufacturer' => 'Samsung',
                'Part Number' => 'M471B5273DH0-CH9',
                'Serial Number' => '947C2F3B',
                'Size' => '4096 MB',
                'Speed' => '1333 MHz',
                'Total Width' => '64 bits',
                'Type' => 'DDR3',
                'Type Detail' => 'Synchronous'
            },
            {
                'Array Handle' => '0x0005',
                'Asset Tag' => '9876543210',
                'Bank Locator' => 'BANK 3',
                'Error Information Handle' => 'Not Provided',
                'Form Factor' => 'DIMM',
                'Locator' => 'ChannelB-DIMM1',
                'Size' => 'No Module Installed',
            }
        ],
        '18' => [
            {
                'Type' => 'OK'
            }
        ],
        '19' => [
            {
                'Ending Address' => '0x001FFFFFFFF',
                'Partition Width' => '4',
                'Physical Array Handle' => '0x0005',
                'Range Size' => '8 GB',
                'Starting Address' => '0x00000000000'
            }
        ],
        '2' => [
            {
                'Chassis Handle' => '0x0000',
                'Contained Object Handles' => '0',
                'Manufacturer' => 'LENOVO',
                'Product Name' => '1298A8G',
                'Serial Number' => '1ZJJC21G0N6',
            }
        ],
        '20' => [
            {
                'Ending Address' => '0x000FFFFFFFF',
                'Interleave Position' => '1',
                'Interleaved Data Depth' => '2',
                'Memory Array Mapped Address Handle' => '0x000C',
                'Physical Device Handle' => '0x0006',
                'Range Size' => '4 GB',
                'Starting Address' => '0x00000000000'
            },
            {
                'Ending Address' => '0x001FFFFFFFF',
                'Interleave Position' => '2',
                'Interleaved Data Depth' => '2',
                'Memory Array Mapped Address Handle' => '0x000C',
                'Physical Device Handle' => '0x0009',
                'Range Size' => '4 GB',
                'Starting Address' => '0x00100000000'
            }
        ],
        '21' => [
            {
                'Buttons' => '2',
                'Interface' => 'PS/2',
                'Type' => 'Mouse'
            }
        ],
        '22' => [
            {
                'Location' => 'Rear',
                'Manufacture Date' => '2008',
                'Manufacturer' => 'Intel Corp.',
                'Name' => 'Smart Battery',
                'OEM-specific Information' => '0x00000000',
                'SBDS Chemistry' => 'Lithium-Ion',
                'SBDS Version' => 'V1.0',
                'Serial Number' => '1.0'
            }
        ],
        '23' => [
            {
                'Boot Option' => 'Do Not Reboot',
                'Boot Option On Limit' => 'Do Not Reboot',
                'Status' => 'Disabled',
                'Watchdog Timer' => 'Present'
            }
        ],
        '27' => [
            {
                'Nominal Speed' => 'Unknown Or Non-rotating',
                'OEM-specific Information' => '0x00000090'
            }
        ],
        '3' => [
            {
                'Asset Tag' => 'No Asset Information',
                'Contained Elements' => '0',
                'Height' => 'Unspecified',
                'Manufacturer' => 'LENOVO',
                'Number Of Power Cords' => 'Unspecified',
                'OEM Information' => '0x00000000',
                'Serial Number' => 'LR9NKZ7',
                'Type' => 'Notebook',
            }
        ],
        '32' => [
            {
                'Status' => 'No errors detected'
            }
        ],
        '39' => [
            {
                'Asset Tag' => 'TBD by ODM',
                'Hot Replaceable' => 'Yes',
                'Input Voltage Range Switching' => 'Other',
                'Location' => 'TBD by ODM',
                'Manufacturer' => 'TBD by ODM',
                'Model Part Number' => 'TBD by ODM',
                'Name' => 'TBD by ODM',
                'Plugged' => 'Yes',
                'Revision' => '1.0',
                'Serial Number' => 'TBD by ODM',
                'Status' => 'Present, OK',
                'Type' => 'Battery'
            }
        ],
        '4' => [
            {
                'Asset Tag' => 'TBD By OEM',
                'Core Count' => '2',
                'Core Enabled' => '2',
                'Current Speed' => '2500 MHz',
                'External Clock' => '100 MHz',
                'Family' => 'Core i5',
                'ID' => 'A7 06 02 00 FF FB EB BF',
                'L1 Cache Handle' => '0x0002',
                'L2 Cache Handle' => '0x0003',
                'L3 Cache Handle' => '0x0004',
                'Manufacturer' => 'Intel(R) Corporation',
                'Max Speed' => '2500 MHz',
                'Part Number' => 'TBD By OEM',
                'Serial Number' => 'Not Supported by CPU',
                'Signature' => 'Type 0, Family 6, Model 42, Stepping 7',
                'Socket Designation' => 'CPU',
                'Status' => 'Populated, Enabled',
                'Thread Count' => '4',
                'Type' => 'Central Processor',
                'Upgrade' => 'ZIF Socket',
                'Version' => 'Intel(R) Core(TM) i5-2450M CPU @ 2.50GHz',
                'Voltage' => '1.2 V'
            }
        ],
        '7' => [
            {
                'Associativity' => '8-way Set-associative',
                'Configuration' => 'Enabled, Not Socketed, Level 1',
                'Error Correction Type' => 'Single-bit ECC',
                'Installed SRAM Type' => 'Synchronous',
                'Installed Size' => '64 kB',
                'Location' => 'Internal',
                'Maximum Size' => '64 kB',
                'Operational Mode' => 'Write Through',
                'Socket Designation' => 'L1-Cache',
                'System Type' => 'Data'
            },
            {
                'Associativity' => '8-way Set-associative',
                'Configuration' => 'Enabled, Not Socketed, Level 2',
                'Error Correction Type' => 'Single-bit ECC',
                'Installed SRAM Type' => 'Synchronous',
                'Installed Size' => '256 kB',
                'Location' => 'Internal',
                'Maximum Size' => '256 kB',
                'Operational Mode' => 'Write Through',
                'Socket Designation' => 'L2-Cache',
                'System Type' => 'Data'
            },
            {
                'Associativity' => '12-way Set-associative',
                'Configuration' => 'Enabled, Not Socketed, Level 3',
                'Error Correction Type' => 'Single-bit ECC',
                'Installed SRAM Type' => 'Synchronous',
                'Installed Size' => '3072 kB',
                'Location' => 'Internal',
                'Maximum Size' => '3072 kB',
                'Operational Mode' => 'Write Back',
                'Socket Designation' => 'L3-Cache',
                'System Type' => 'Unified'
            }
        ],
        '8' => [
            {
                'External Connector Type' => 'PS/2',
                'External Reference Designator' => 'Keyboard',
                'Port Type' => 'Keyboard Port'
            },
            {
                'External Connector Type' => 'PS/2',
                'External Reference Designator' => 'Mouse',
                'Port Type' => 'Mouse Port'
            },
            {
                'External Reference Designator' => 'COM 1',
                'Internal Connector Type' => 'Other',
                'Port Type' => 'Serial Port 16550A Compatible'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB2.0 - 1#',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB2.0 - 2#',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB2.0 - 3#',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB2.0 - 4#',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB2.0 - 5#',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB2.0 - 6#',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB2.0 - 7#',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB2.0 - 8#',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB2.0 - 9#',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB2.0 - 10#',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB2.0 - 11#',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB2.0 - 12#',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB2.0 - 13#',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'Access Bus (USB)',
                'External Reference Designator' => 'USB2.0 - 14#',
                'Port Type' => 'USB'
            },
            {
                'External Connector Type' => 'RJ-45',
                'External Reference Designator' => 'Ethernet',
                'Port Type' => 'Network Port'
            },
            {
                'Internal Connector Type' => 'SAS/SATA Plug Receptacle',
                'Internal Reference Designator' => 'SATA Port 1 J8J1',
                'Port Type' => 'SATA'
            },
            {
                'Internal Connector Type' => 'SAS/SATA Plug Receptacle',
                'Internal Reference Designator' => 'SATA Port 2 J7G1',
                'Port Type' => 'SATA'
            },
            {
                'Internal Connector Type' => 'SAS/SATA Plug Receptacle',
                'Internal Reference Designator' => 'SATA Port 3(ODD) J9E7',
                'Port Type' => 'SATA'
            },
            {
                'External Connector Type' => 'SAS/SATA Plug Receptacle',
                'External Reference Designator' => 'eSATA Port 1 J6J1',
                'Port Type' => 'SATA'
            },
            {
                'External Connector Type' => 'SAS/SATA Plug Receptacle',
                'External Reference Designator' => 'eSATA Port 2 J7J1',
                'Port Type' => 'SATA'
            },
            {
                'External Connector Type' => 'SAS/SATA Plug Receptacle',
                'External Reference Designator' => 'SATA Port 6(Docking)',
                'Port Type' => 'SATA'
            }
        ],
        '9' => [
            {
                'Bus Address' => '0000:00:00.0',
                'Current Usage' => 'In Use',
                'Designation' => 'PEG Gen1/Gen2 X16',
                'ID' => '0',
                'Length' => 'Long',
                'Type' => 'x16 PCI Express x16'
            },
            {
                'Bus Address' => '0000:00:00.0',
                'Current Usage' => 'Available',
                'Designation' => 'PCI-Express 1 X1',
                'ID' => '1',
                'Length' => 'Short',
                'Type' => 'x1 PCI Express'
            },
            {
                'Bus Address' => '0000:00:00.0',
                'Current Usage' => 'In Use',
                'Designation' => 'PCI-Express 2 X1',
                'ID' => '2',
                'Length' => 'Short',
                'Type' => 'x1 PCI Express'
            },
            {
                'Bus Address' => '0000:00:00.0',
                'Current Usage' => 'In Use',
                'Designation' => 'PCI-Express 3 X1',
                'ID' => '3',
                'Length' => 'Short',
                'Type' => 'x1 PCI Express'
            },
            {
                'Bus Address' => '0000:00:00.0',
                'Current Usage' => 'Available',
                'Designation' => 'PCI-Express 4 X1',
                'ID' => '4',
                'Length' => 'Short',
                'Type' => 'x1 PCI Express'
            },
            {
                'Bus Address' => '0000:00:00.0',
                'Current Usage' => 'Available',
                'Designation' => 'PCI-Express 5 X1',
                'ID' => '5',
                'Length' => 'Short',
                'Type' => 'x1 PCI Express'
            }
        ]
    }
);

my %cpu_tests = (
    'freebsd-6.2' => [
        {
            ID             => 'A7C9BBFF000006A9',
            NAME           => 'VIA C7',
            EXTERNAL_CLOCK => '100',
            SPEED          => '2000',
            SERIAL         => undef,
            MANUFACTURER   => 'VIA',
            STEPPING       => '9',
            FAMILYNUMBER   => '6',
            MODEL          => '10',
            FAMILYNAME     => 'Other',
            CORE           => undef
        }
    ],
    'freebsd-8.1' => [
        {
            ID             => 'BFEBFBFF00020652',
            NAME           => 'Intel Core i5 CPU M 430 @ 2.27GHz',
            EXTERNAL_CLOCK => '1066',
            SPEED          => '2270',
            THREAD         => '2',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel(R) Corporation',
            STEPPING       => '2',
            FAMILYNUMBER   => '6',
            MODEL          => '37',
            FAMILYNAME     => 'Core 2 Duo',
            CORE           => '2'
        }
    ],
    'hp-dl180' => [
        {
            ID             => 'BFEBFBFF000106A5',
            NAME           => 'Intel Xeon CPU E5504 @ 2.00GHz',
            EXTERNAL_CLOCK => '532',
            SPEED          => '2000',
            THREAD         => '1',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel',
            STEPPING       => '5',
            FAMILYNUMBER   => '6',
            MODEL          => '26',
            CORE           => '4',
            FAMILYNAME     => 'Xeon'
        }
    ],
    'rhel-2.1' => [
        {
            ID             => undef,
            NAME           => 'Pentium 4',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel',
            FAMILYNAME     => undef,
            CORE           => undef
        }
    ],
    'rhel-3.4' => [
        {
            ID             => 'BFEBFBFF00000F41',
            NAME           => 'Intel Xeon CPU 2.80GHz',
            EXTERNAL_CLOCK => '200',
            SPEED          => '2800',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel Corporation',
            STEPPING       => '1',
            FAMILYNUMBER   => '15',
            MODEL          => '4',,
            FAMILYNAME     => 'Xeon MP',
            CORE           => undef
        },
        {
            ID             => 'BFEBFBFF00000F41',
            NAME           => 'Intel Xeon CPU 2.80GHz',
            EXTERNAL_CLOCK => '200',
            SPEED          => '2800',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel Corporation',
            STEPPING       => '1',
            FAMILYNUMBER   => '15',
            MODEL          => '4',
            FAMILYNAME     => 'Xeon MP',
            CORE           => undef
        }
    ],
    'rhel-3.9' => [
    ],
    'rhel-4.3' => [
        {
            ID             => 'BFEBFBFF00000F29',
            NAME           => 'Intel Xeon',
            EXTERNAL_CLOCK => '133',
            SPEED          => '2666',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel',
            STEPPING       => '9',
            FAMILYNUMBER   => '15',
            MODEL          => '2',
            FAMILYNAME     => 'Xeon',
            CORE           => undef
        },
        {
            ID             => 'BFEBFBFF00000F29',
            NAME           => 'Intel Xeon',
            EXTERNAL_CLOCK => '133',
            SPEED          => '2666',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel',
            STEPPING       => '9',
            FAMILYNUMBER   => '15',
            MODEL          => '2',
            FAMILYNAME     => 'Xeon',
            CORE           => undef
        }
    ],
    'rhel-4.6' => [
        {
            ID             => 'BFEBFBFF00010676',
            NAME           => 'Xeon',
            EXTERNAL_CLOCK => '1333',
            SPEED          => '2333',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel',
            STEPPING       => '6',
            FAMILYNUMBER   => '6',
            MODEL          => '23',
            FAMILYNAME     => 'Xeon',
            CORE           => undef
        }
    ],
    'rhel-5.6' => [
        {
            ID             => 'BFEBFBFF000206C2',
            NAME           => 'Intel Xeon CPU E5620 @ 2.40GHz',
            EXTERNAL_CLOCK => '5860',
            SPEED          => '2400',
            THREAD         => '2',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel',
            STEPPING       => '2',
            FAMILYNUMBER   => '6',
            MODEL          => '44',
            FAMILYNAME     => 'Xeon',
            CORE           => '4',
        },
        {
            ID             => 'BFEBFBFF000206C2',
            NAME           => 'Intel Xeon CPU E5620 @ 2.40GHz',
            EXTERNAL_CLOCK => '5860',
            SPEED          => '2400',
            THREAD         => '2',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel',
            STEPPING       => '2',
            FAMILYNUMBER   => '6',
            MODEL          => '44',
            FAMILYNAME     => 'Xeon',
            CORE           => '4',
        }
    ],
    'rhel-6.3-esx-1vcpu' => [
        {
            ID             => '0FABFBFF000206A7',
            NAME           => 'Intel Core i5-2500S CPU @ 2.70GHz',
           SPEED          => '2700',
            SERIAL         => undef,
            MANUFACTURER   => 'GenuineIntel',
            STEPPING       => '7',
            FAMILYNUMBER   => '6',
            MODEL          => '42',
            FAMILYNAME     => undef,
            CORE           => undef,
        }
    ],
    'openbsd-3.7' => [
        {
            ID             => '0183F9FF00000652',
            NAME           => 'Pentium II',
            EXTERNAL_CLOCK => '100',
            SPEED          => '400',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel',
            STEPPING       => '2',
            FAMILYNUMBER   => '6',
            MODEL          => '5',
            FAMILYNAME     => 'Pentium II',
            CORE           => undef
        }
    ],
    'openbsd-3.8' => [
        {
            ID             => 'BFEBFBFF00000F43',
            NAME           => 'Xeon',
            EXTERNAL_CLOCK => '800',
            SPEED          => '3000',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel',
            STEPPING       => '3',
            FAMILYNUMBER   => '15',
            MODEL          => '4',
            FAMILYNAME     => 'Xeon',
            CORE           => undef
        }
    ],
    'openbsd-4.5' => [
        {
            ID             => 'BFEBFBFF00000F29',
            NAME           => 'Pentium 4',
            EXTERNAL_CLOCK => '533',
            SPEED          => '2400',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel',
            STEPPING       => '9',
            FAMILYNUMBER   => '15',
            MODEL          => '2',,
            FAMILYNAME     => 'Pentium 4',
            CORE           => undef
        }
    ],
    'oracle-server-x5-2' => [
        {
            THREAD          => '2',
            EXTERNAL_CLOCK  => '100',
            CORE            => '18',
            SPEED           => '2300',
            MODEL           => 63,
            MANUFACTURER    => 'Intel',
            ID              => 'BFEBFBFF000306F2',
            NAME            => 'Intel Xeon CPU E5-2699 v3 @ 2.30GHz',
            FAMILYNUMBER    => 6,
            STEPPING        => 2,
            SERIAL          => undef,
            FAMILYNAME      => 'Xeon'
        },
        {
            MANUFACTURER    => 'Intel',
            MODEL           => 63,
            ID              => 'BFEBFBFF000306F2',
            STEPPING        => 2,
            FAMILYNUMBER    => 6,
            NAME            => 'Intel Xeon CPU E5-2699 v3 @ 2.30GHz',
            SERIAL          => undef,
            FAMILYNAME      => 'Xeon',
            THREAD          => '2',
            CORE            => '18',
            EXTERNAL_CLOCK  => '100',
            SPEED           => '2300'
        }
    ],
    'S3000AHLX' => [
        {
            ID             => 'BFEBFBFF000006F6',
            NAME           => 'Intel Core2 CPU 6600 @ 2.40GHz',
            EXTERNAL_CLOCK => '266',
            SPEED          => '2400',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel(R) Corporation',
            STEPPING       => '6',
            FAMILYNUMBER   => '6',
            MODEL          => '15',
            FAMILYNAME     => undef,
            CORE           => undef
        }
    ],
    'S5000VSA' => [
        {
            ID             => 'BFEBFBFF000006F6',
            NAME           => 'Intel Xeon CPU 5120 @ 1.86GHz',
            EXTERNAL_CLOCK => '1066',
            SPEED          => '1860',
            THREAD         => '1',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel(R) Corporation',
            STEPPING       => '6',
            FAMILYNUMBER   => '6',
            MODEL          => '15',
            FAMILYNAME     => 'Xeon',
            CORE           => '2'
        },
        {
            ID             => 'BFEBFBFF000006F6',
            NAME           => 'Intel Xeon CPU 5120 @ 1.86GHz',
            EXTERNAL_CLOCK => '1066',
            SPEED          => '1860',
            THREAD         => '1',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel(R) Corporation',
            STEPPING       => '6',
            FAMILYNUMBER   => '6',
            MODEL          => '15',
            FAMILYNAME     => 'Xeon',
            CORE           => '2'
        }
    ],
    'linux-1' => [
        {
            ID             => 'BFEBFBFF0001067A',
            NAME           => 'Intel Core2 Duo CPU E8400 @ 3.00GHz',
            EXTERNAL_CLOCK => '333',
            SPEED          => '3000',
            THREAD         => '1',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel',
            STEPPING       => '10',
            FAMILYNUMBER   => '6',
            MODEL          => '23',
            FAMILYNAME     => 'Core 2 Duo',
            CORE           => '2'
        }
    ],
    'linux-2.6' => [
        {
            ID             => 'AFE9FBFF000006D8',
            NAME           => 'Pentium M',
            EXTERNAL_CLOCK => '133',
            SPEED          => '1733',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel',
            STEPPING       => '8',
            FAMILYNUMBER   => '6',
            MODEL          => '13',
            FAMILYNAME     => 'Pentium M',
            CORE           => undef
        }
    ],
    'vmware' => [
        {
            ID             => '078BFBFF00040F12',
            NAME           => undef,
            SPEED          => '2133',
            SERIAL         => undef,
            MANUFACTURER   => 'AuthenticAMD',
            STEPPING       => '2',
            FAMILYNUMBER   => '15',
            MODEL          => '65',
            FAMILYNAME     => undef,
            CORE           => undef
        },
        {
            ID             => '078BFBFF00000F12',
            NAME           => undef,
            FAMILYNAME     => undef,
            SPEED          => '2133',
            SERIAL         => undef,
            MANUFACTURER   => 'GenuineIntel',
            STEPPING       => '2',
            FAMILYNUMBER   => '15',
            MODEL          => '1',
            FAMILYNAME     => undef,
            CORE           => undef
        }
    ],
    'vmware-esx' => [
        {
            ID             => '078BFBFF00100F42',
            NAME           => undef,
            SPEED          => '2300',
            SERIAL         => undef,
            MANUFACTURER   => 'AuthenticAMD',
            STEPPING       => '2',
            FAMILYNUMBER   => '15',
            MODEL          => '4',
            FAMILYNAME     => undef,
            CORE           => undef
        }
    ],
    'vmware-esx-2.5' => [
        {
            ID             => undef,
            NAME           => 'Pentium III processor',
            SERIAL         => undef,
            MANUFACTURER   => 'GenuineIntel',
            FAMILYNAME     => undef,
            CORE           => undef
        }
    ],
    'windows' => [
        {
            ID             => '0000000000000F24',
            NAME           => 'Pentium 4',
            EXTERNAL_CLOCK => '100',
            SPEED          => '1700',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel Corporation',
            STEPPING       => '4',
            FAMILYNUMBER   => '15',
            MODEL          => '2',
            FAMILYNAME     => 'Pentium 4',
            CORE           => undef
        }
    ],
    'windows-hyperV' => [
        {
            ID             => '1F8BFBFF0001067A',
            NAME           => 'Intel Xeon',
            EXTERNAL_CLOCK => '266',
            SPEED          => '2500',
            SERIAL         => undef,
            MANUFACTURER   => 'GenuineIntel',
            STEPPING       => '10',
            FAMILYNUMBER   => '6',
            MODEL          => '23',
            FAMILYNAME     => 'Xeon',
            CORE           => undef
        }
    ],
    'windows-xp' => [
        {
            ID             => 'BFEBFBFF00010676',
            NAME           => 'Core 2 Duo',
            EXTERNAL_CLOCK => '266',
            SPEED          => '2534',
            THREAD         => '1',
            SERIAL         => undef,
            MANUFACTURER   => 'Intel',
            STEPPING       => '6',
            FAMILYNUMBER   => '6',
            MODEL          => '23',
            FAMILYNAME     => 'Core 2 Duo',
            CORE           => '2'
        }
    ],
    'windows-7' => [
        {
            ID             => 'BFEBFBFF000206A7',
            NAME           => 'Intel Core i5-2300 CPU @ 2.80GHz',
            EXTERNAL_CLOCK => '100',
            SPEED          => '2800',
            SERIAL         => undef,
            STEPPING       => '7',
            FAMILYNUMBER   => '6',
            MODEL          => '42',
            MANUFACTURER   => 'Intel',
            FAMILYNAME     => 'Core 2 Duo',
            CORE           => '1',
            CORECOUNT      => '4'
        }
    ],
    'windows-7.2' => [
        {
            ID             => '178BFBFF00100F62',
            NAME           => 'AMD Athlon II X2 245 Processor',
            EXTERNAL_CLOCK => '200',
            SPEED          => '2900',
            SERIAL         => undef,
            STEPPING       => '2',
            FAMILYNUMBER   => '15',
            MODEL          => '6',
            MANUFACTURER   => 'AMD',
            FAMILYNAME     => 'Athlon II',
            CORE           => '2'
        }
    ],
    'lenovo-thinkpad' => [
        {
            CORE            => '2',
            EXTERNAL_CLOCK  => '100',
            FAMILYNAME      => 'Core i5',
            FAMILYNUMBER    => '6',
            ID              => 'BFEBFBFF000206A7',
            MANUFACTURER    => 'Intel(R) Corporation',
            MODEL           => '42',
            NAME            => 'Intel Core i5-2450M CPU @ 2.50GHz',
            SERIAL          => 'Not Supported by CPU',
            SPEED           => '2500',
            STEPPING        => '7',
            THREAD          => '2'
        }
    ]
);

my %lspci_tests = (
    'dell-xt2' => [
        {
            PCICLASS       => '0600',
            NAME           => 'Host bridge',
            MANUFACTURER   => 'Intel Corporation Mobile 4 Series Chipset Memory Controller Hub',
            REV            => '07',
            PCIID          => '8086:2a40',
            DRIVER         => 'agpgart',
            PCISLOT        => '00:00.0',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS       => '0300',
            NAME           => 'VGA compatible controller',
            MANUFACTURER   => 'Intel Corporation Mobile 4 Series Chipset Integrated Graphics Controller',
            REV            => '07',
            PCIID          => '8086:2a42',
            DRIVER         => 'i915',
            PCISLOT        => '00:02.0',
            PCISUBSYSTEMID => '1028:0252',
            MEMORY         => '256',
        },
        {
            PCICLASS       => '0380',
            NAME           => 'Display controller',
            MANUFACTURER   => 'Intel Corporation Mobile 4 Series Chipset Integrated Graphics Controller',
            REV            => '07',
            PCIID          => '8086:2a43',
            PCISLOT        => '00:02.1',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS       => '0200',
            NAME           => 'Ethernet controller',
            MANUFACTURER   => 'Intel Corporation 82567LM Gigabit Network Connection',
            REV            => '03',
            PCIID          => '8086:10f5',
            DRIVER         => 'e1000e',
            PCISLOT        => '00:19.0',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS       => '0c03',
            NAME           => 'USB controller',
            MANUFACTURER   => 'Intel Corporation 82801I (ICH9 Family) USB UHCI Controller #4',
            REV            => '03',
            PCIID          => '8086:2937',
            DRIVER         => 'uhci_hcd',
            PCISLOT        => '00:1a.0',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS       => '0c03',
            NAME           => 'USB controller',
            MANUFACTURER   => 'Intel Corporation 82801I (ICH9 Family) USB UHCI Controller #5',
            REV            => '03',
            PCIID          => '8086:2938',
            DRIVER         => 'uhci_hcd',
            PCISLOT        => '00:1a.1',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS       => '0c03',
            NAME           => 'USB controller',
            MANUFACTURER   => 'Intel Corporation 82801I (ICH9 Family) USB UHCI Controller #6',
            REV            => '03',
            PCIID          => '8086:2939',
            DRIVER         => 'uhci_hcd',
            PCISLOT        => '00:1a.2',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS       => '0c03',
            NAME           => 'USB controller',
            MANUFACTURER   => 'Intel Corporation 82801I (ICH9 Family) USB2 EHCI Controller #2',
            REV            => '03',
            PCIID          => '8086:293c',
            DRIVER         => 'ehci_hcd',
            PCISLOT        => '00:1a.7',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS       => '0403',
            NAME           => 'Audio device',
            MANUFACTURER   => 'Intel Corporation 82801I (ICH9 Family) HD Audio Controller',
            REV            => '03',
            PCIID          => '8086:293e',
            DRIVER         => 'snd_hda_intel',
            PCISLOT        => '00:1b.0',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS     => '0604',
            NAME         => 'PCI bridge',
            MANUFACTURER => 'Intel Corporation 82801I (ICH9 Family) PCI Express Port 1',
            REV          => '03',
            PCIID        => '8086:2940',
            DRIVER       => 'pcieport',
            PCISLOT      => '00:1c.0'
        },
        {
            PCICLASS     => '0604',
            NAME         => 'PCI bridge',
            MANUFACTURER => 'Intel Corporation 82801I (ICH9 Family) PCI Express Port 2',
            REV          => '03',
            PCIID        => '8086:2942',
            DRIVER       => 'pcieport',
            PCISLOT      => '00:1c.1'
        },
        {
            PCICLASS     => '0604',
            NAME         => 'PCI bridge',
            MANUFACTURER => 'Intel Corporation 82801I (ICH9 Family) PCI Express Port 4',
            REV          => '03',
            PCIID        => '8086:2946',
            DRIVER       => 'pcieport',
            PCISLOT      => '00:1c.3'
        },
        {
            PCICLASS       => '0c03',
            NAME           => 'USB controller',
            MANUFACTURER   => 'Intel Corporation 82801I (ICH9 Family) USB UHCI Controller #1',
            REV            => '03',
            PCIID          => '8086:2934',
            DRIVER         => 'uhci_hcd',
            PCISLOT        => '00:1d.0',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS       => '0c03',
            NAME           => 'USB controller',
            MANUFACTURER   => 'Intel Corporation 82801I (ICH9 Family) USB UHCI Controller #2',
            REV            => '03',
            PCIID          => '8086:2935',
            DRIVER         => 'uhci_hcd',
            PCISLOT        => '00:1d.1',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS       => '0c03',
            NAME           => 'USB controller',
            MANUFACTURER   => 'Intel Corporation 82801I (ICH9 Family) USB UHCI Controller #3',
            REV            => '03',
            PCIID          => '8086:2936',
            DRIVER         => 'uhci_hcd',
            PCISLOT        => '00:1d.2',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS       => '0c03',
            NAME           => 'USB controller',
            MANUFACTURER   => 'Intel Corporation 82801I (ICH9 Family) USB2 EHCI Controller #1',
            REV            => '03',
            PCIID          => '8086:293a',
            DRIVER         => 'ehci_hcd',
            PCISLOT        => '00:1d.7',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS     => '0604',
            NAME         => 'PCI bridge',
            MANUFACTURER => 'Intel Corporation 82801 Mobile PCI Bridge',
            REV          => '93',
            PCIID        => '8086:2448',
            PCISLOT      => '00:1e.0'
        },
        {
            PCICLASS       => '0601',
            NAME           => 'ISA bridge',
            MANUFACTURER   => 'Intel Corporation ICH9M-E LPC Interface Controller',
            REV            => '03',
            PCIID          => '8086:2917',
            PCISLOT        => '00:1f.0',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCIID          => '8086:282a',
            PCICLASS       => '0104',
            REV            => '03',
            MANUFACTURER   => 'Intel Corporation 82801 Mobile SATA Controller [RAID mode]',
            DRIVER         => 'ahci',
            NAME           => 'RAID bus controller',
            PCISLOT        => '00:1f.2',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS       => '0c05',
            NAME           => 'SMBus',
            MANUFACTURER   => 'Intel Corporation 82801I (ICH9 Family) SMBus Controller',
            REV            => '03',
            PCIID          => '8086:2930',
            DRIVER         => 'i801_smbus',
            PCISLOT        => '00:1f.3',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS       => '0607',
            NAME           => 'CardBus bridge',
            MANUFACTURER   => 'Texas Instruments PCIxx12 Cardbus Controller',
            REV            => undef,
            PCIID          => '104c:8039',
            DRIVER         => 'yenta_cardbus',
            PCISLOT        => '02:01.0',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS       => '0c00',
            NAME           => 'FireWire (IEEE 1394)',
            MANUFACTURER   => 'Texas Instruments PCIxx12 OHCI Compliant IEEE 1394 Host Controller',
            REV            => undef,
            PCIID          => '104c:803a',
            DRIVER         => 'firewire_ohci',
            PCISLOT        => '02:01.1',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS       => '0805',
            NAME           => 'SD Host controller',
            MANUFACTURER   => 'Texas Instruments PCIxx12 SDA Standard Compliant SD Host Controller',
            REV            => undef,
            PCIID          => '104c:803c',
            DRIVER         => 'sdhci',
            PCISLOT        => '02:01.3',
            PCISUBSYSTEMID => '1028:0252',
        },
        {
            PCICLASS       => '0280',
            NAME           => 'Network controller',
            MANUFACTURER   => 'Intel Corporation WiFi Link 5100',
            REV            => undef,
            PCIID          => '8086:4232',
            DRIVER         => 'iwlwifi',
            PCISLOT        => '0c:00.0',
            PCISUBSYSTEMID => '8086:1321',
        }
    ],
    'linux-2' => [
        {
            REV            => undef,
            NAME           => 'Host bridge',
            DRIVER         => 'i82975x_edac',
            PCICLASS       => '0600',
            PCISLOT        => '00:00.0',
            MANUFACTURER   => 'Intel Corporation 82975X Memory Controller Hub',
            PCIID          => '8086:277c',
            PCISUBSYSTEMID => '1028:01de',
        },
        {
            REV          => undef,
            NAME         => 'PCI bridge',
            DRIVER       => 'pcieport',
            PCICLASS     => '0604',
            PCISLOT      => '00:01.0',
            MANUFACTURER => 'Intel Corporation 82975X PCI Express Root Port',
            PCIID        => '8086:277d'
        },
        {
            NAME           => 'Audio device',
            REV            => '01',
            PCICLASS       => '0403',
            DRIVER         => 'snd_hda_intel',
            MANUFACTURER   => 'Intel Corporation NM10/ICH7 Family High Definition Audio Controller',
            PCISLOT        => '00:1b.0',
            PCIID          => '8086:27d8',
            PCISUBSYSTEMID => '1028:01de',
        },
        {
            REV          => '01',
            NAME         => 'PCI bridge',
            DRIVER       => 'pcieport',
            PCICLASS     => '0604',
            PCISLOT      => '00:1c.0',
            MANUFACTURER => 'Intel Corporation NM10/ICH7 Family PCI Express Port 1',
            PCIID        => '8086:27d0'
        },
        {
            NAME         => 'PCI bridge',
            REV          => '01',
            PCICLASS     => '0604',
            DRIVER       => 'pcieport',
            MANUFACTURER => 'Intel Corporation 82801GR/GH/GHM (ICH7 Family) PCI Express Port 5',
            PCISLOT      => '00:1c.4',
            PCIID        => '8086:27e0'
        },
        {
            MANUFACTURER => 'Intel Corporation 82801GR/GH/GHM (ICH7 Family) PCI Express Port 6',
            PCISLOT      => '00:1c.5',
            PCIID        => '8086:27e2',
            NAME         => 'PCI bridge',
            REV          => '01',
            PCICLASS     => '0604',
            DRIVER       => 'pcieport'
        },
        {
            DRIVER         => 'uhci_hcd',
            PCICLASS       => '0c03',
            REV            => '01',
            NAME           => 'USB controller',
            PCIID          => '8086:27c8',
            PCISLOT        => '00:1d.0',
            MANUFACTURER   => 'Intel Corporation NM10/ICH7 Family USB UHCI Controller #1',
            PCISUBSYSTEMID => '1028:01de',
        },
        {
            NAME           => 'USB controller',
            REV            => '01',
            PCICLASS       => '0c03',
            DRIVER         => 'uhci_hcd',
            MANUFACTURER   => 'Intel Corporation NM10/ICH7 Family USB UHCI Controller #2',
            PCISLOT        => '00:1d.1',
            PCIID          => '8086:27c9',
            PCISUBSYSTEMID => '1028:01de',
        },
        {
            DRIVER         => 'uhci_hcd',
            PCICLASS       => '0c03',
            REV            => '01',
            NAME           => 'USB controller',
            PCIID          => '8086:27ca',
            PCISLOT        => '00:1d.2',
            MANUFACTURER   => 'Intel Corporation NM10/ICH7 Family USB UHCI Controller #3',
            PCISUBSYSTEMID => '1028:01de',
        },
        {
            PCIID          => '8086:27cb',
            PCISLOT        => '00:1d.3',
            MANUFACTURER   => 'Intel Corporation NM10/ICH7 Family USB UHCI Controller #4',
            DRIVER         => 'uhci_hcd',
            PCICLASS       => '0c03',
            REV            => '01',
            NAME           => 'USB controller',
            PCISUBSYSTEMID => '1028:01de',
        },
        {
            PCICLASS       => '0c03',
            DRIVER         => 'ehci',
            NAME           => 'USB controller',
            REV            => '01',
            PCIID          => '8086:27cc',
            MANUFACTURER   => 'Intel Corporation NM10/ICH7 Family USB2 EHCI Controller',
            PCISLOT        => '00:1d.7',
            PCISUBSYSTEMID => '1028:01de',
        },
        {
            PCISLOT      => '00:1e.0',
            MANUFACTURER => 'Intel Corporation 82801 PCI Bridge',
            PCIID        => '8086:244e',
            REV          => undef,
            NAME         => 'PCI bridge',
            PCICLASS     => '0604'
        },
        {
            REV          => '01',
            NAME         => 'ISA bridge',
            DRIVER       => 'lpc_ich',
            PCICLASS     => '0601',
            PCISLOT      => '00:1f.0',
            MANUFACTURER => 'Intel Corporation 82801GB/GR (ICH7 Family) LPC Interface Bridge',
            PCIID        => '8086:27b8'
        },
        {
            MANUFACTURER   => 'Intel Corporation 82801G (ICH7 Family) IDE Controller',
            PCISLOT        => '00:1f.1',
            PCIID          => '8086:27df',
            NAME           => 'IDE interface',
            REV            => '01',
            PCICLASS       => '0101',
            DRIVER         => 'ata_piix',
            PCISUBSYSTEMID => '1028:01de',
        },
        {
            MANUFACTURER   => 'Intel Corporation NM10/ICH7 Family SATA Controller [AHCI mode]',
            DRIVER         => 'ahci',
            REV            => '01',
            PCISLOT        => '00:1f.2',
            PCICLASS       => '0106',
            PCIID          => '8086:27c1',
            NAME           => 'SATA controller',
            PCISUBSYSTEMID => '1028:01de',
        },
        {
            PCICLASS       => '0c05',
            DRIVER         => 'i801_smbus',
            NAME           => 'SMBus',
            REV            => '01',
            PCIID          => '8086:27da',
            MANUFACTURER   => 'Intel Corporation NM10/ICH7 Family SMBus Controller',
            PCISLOT        => '00:1f.3',
            PCISUBSYSTEMID => '1028:01de',
        },
        {
            DRIVER         => 'nvidia',
            PCISLOT        => '01:00.0',
            PCICLASS       => '0300',
            REV            => undef,
            PCIID          => '10de:014d',
            NAME           => 'VGA compatible controller',
            MANUFACTURER   => 'NVIDIA Corporation NV43GL [Quadro FX 550]',
            PCISUBSYSTEMID => '10de:0349',
            MEMORY         => '128'
        },
        {
            NAME           => 'Ethernet controller',
            REV            => '02',
            PCICLASS       => '0200',
            DRIVER         => 'tg3',
            MANUFACTURER   => 'Broadcom Corporation NetXtreme BCM5754 Gigabit Ethernet PCI Express',
            PCISLOT        => '04:00.0',
            PCIID          => '14e4:167a',
            PCISUBSYSTEMID => '1028:01de',
        },
        {
            PCISLOT        => '05:02.0',
            DRIVER         => 'firewire_ohci',
            REV            => '61',
            PCIID          => '11c1:5811',
            MANUFACTURER   => 'LSI Corporation FW322/323 [TrueFire] 1394a Controller',
            NAME           => 'FireWire (IEEE 1394)',
            PCICLASS       => '0c00',
            PCISUBSYSTEMID => '1028:8010',
        }
    ],
    'nvidia-1' => [
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse Root Complex',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1480',
            PCISLOT        => '00:00.0',
            PCISUBSYSTEMID => '1043:87c0',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse IOMMU',
            NAME           => 'IOMMU',
            PCICLASS       => '0806',
            PCIID          => '1022:1481',
            PCISLOT        => '00:00.2',
            PCISUBSYSTEMID => '1043:87c0',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse PCIe Dummy Host Bridge',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1482',
            PCISLOT        => '00:01.0',
            REV            => undef,
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse GPP Bridge',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '1022:1483',
            PCISLOT        => '00:01.1',
            REV            => undef,
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse GPP Bridge',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '1022:1483',
            PCISLOT        => '00:01.2',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse PCIe Dummy Host Bridge',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1482',
            PCISLOT        => '00:02.0',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse PCIe Dummy Host Bridge',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1482',
            PCISLOT        => '00:03.0',
            REV            => undef,
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse GPP Bridge',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '1022:1483',
            PCISLOT        => '00:03.1',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse PCIe Dummy Host Bridge',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1482',
            PCISLOT        => '00:04.0',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse PCIe Dummy Host Bridge',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1482',
            PCISLOT        => '00:05.0',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse PCIe Dummy Host Bridge',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1482',
            PCISLOT        => '00:07.0',
            REV            => undef,
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse Internal PCIe GPP Bridge 0 to bus[E:B]',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '1022:1484',
            PCISLOT        => '00:07.1',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse PCIe Dummy Host Bridge',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1482',
            PCISLOT        => '00:08.0',
            REV            => undef,
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse Internal PCIe GPP Bridge 0 to bus[E:B]',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '1022:1484',
            PCISLOT        => '00:08.1',
            REV            => undef,
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse Internal PCIe GPP Bridge 0 to bus[E:B]',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '1022:1484',
            PCISLOT        => '00:08.2',
            REV            => undef,
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse Internal PCIe GPP Bridge 0 to bus[E:B]',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '1022:1484',
            PCISLOT        => '00:08.3',
            REV            => undef,
        },
        {
            DRIVER         => 'piix4_smbus',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] FCH SMBus Controller',
            NAME           => 'SMBus',
            PCICLASS       => '0c05',
            PCIID          => '1022:790b',
            PCISLOT        => '00:14.0',
            PCISUBSYSTEMID => '1043:87c0',
            REV            => '61',
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] FCH LPC Bridge',
            NAME           => 'ISA bridge',
            PCICLASS       => '0601',
            PCIID          => '1022:790e',
            PCISLOT        => '00:14.3',
            PCISUBSYSTEMID => '1043:87c0',
            REV            => '51',
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse/Vermeer Data Fabric: Device 18h; Function 0',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1440',
            PCISLOT        => '00:18.0',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse/Vermeer Data Fabric: Device 18h; Function 1',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1441',
            PCISLOT        => '00:18.1',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse/Vermeer Data Fabric: Device 18h; Function 2',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1442',
            PCISLOT        => '00:18.2',
            REV            => undef,
        },
        {
            DRIVER         => 'k10temp',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse/Vermeer Data Fabric: Device 18h; Function 3',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1443',
            PCISLOT        => '00:18.3',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse/Vermeer Data Fabric: Device 18h; Function 4',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1444',
            PCISLOT        => '00:18.4',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse/Vermeer Data Fabric: Device 18h; Function 5',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1445',
            PCISLOT        => '00:18.5',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse/Vermeer Data Fabric: Device 18h; Function 6',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1446',
            PCISLOT        => '00:18.6',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse/Vermeer Data Fabric: Device 18h; Function 7',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '1022:1447',
            PCISLOT        => '00:18.7',
            REV            => undef,
        },
        {
            DRIVER         => 'nvme',
            MANUFACTURER   => 'Phison Electronics Corporation E12 NVMe Controller',
            NAME           => 'Non-Volatile memory controller',
            PCICLASS       => '0108',
            PCIID          => '1987:5012',
            PCISLOT        => '01:00.0',
            PCISUBSYSTEMID => '1987:5012',
            REV            => '01',
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse Switch Upstream',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '1022:57ad',
            PCISLOT        => '02:00.0',
            REV            => undef,
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse PCIe GPP Bridge',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '1022:57a3',
            PCISLOT        => '03:01.0',
            REV            => undef,
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse PCIe GPP Bridge',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '1022:57a3',
            PCISLOT        => '03:05.0',
            REV            => undef,
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse PCIe GPP Bridge',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '1022:57a4',
            PCISLOT        => '03:08.0',
            REV            => undef,
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse PCIe GPP Bridge',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '1022:57a4',
            PCISLOT        => '03:09.0',
            REV            => undef,
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse PCIe GPP Bridge',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '1022:57a4',
            PCISLOT        => '03:0a.0',
            REV            => undef,
        },
        {
            DRIVER         => 'nvme',
            MANUFACTURER   => 'Micron/Crucial Technology P1 NVMe PCIe SSD',
            NAME           => 'Non-Volatile memory controller',
            PCICLASS       => '0108',
            PCIID          => 'c0a9:2263',
            PCISLOT        => '04:00.0',
            PCISUBSYSTEMID => 'c0a9:2263',
            REV            => '03',
        },
        {
            DRIVER         => 'r8169',
            MANUFACTURER   => 'Realtek Semiconductor Co., Ltd. RTL8111/8168/8411 PCI Express Gigabit Ethernet Controller',
            NAME           => 'Ethernet controller',
            PCICLASS       => '0200',
            PCIID          => '10ec:8168',
            PCISLOT        => '05:00.0',
            PCISUBSYSTEMID => '1043:8677',
            REV            => '15',
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse Reserved SPP',
            NAME           => 'Non-Essential Instrumentation',
            PCICLASS       => '1300',
            PCIID          => '1022:1485',
            PCISLOT        => '06:00.0',
            PCISUBSYSTEMID => '1043:87c0',
            REV            => undef,
        },
        {
            DRIVER         => 'xhci_hcd',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse USB 3.0 Host Controller',
            NAME           => 'USB controller',
            PCICLASS       => '0c03',
            PCIID          => '1022:149c',
            PCISLOT        => '06:00.1',
            PCISUBSYSTEMID => '1043:87c0',
            REV            => undef,

        },
        {
            DRIVER         => 'xhci_hcd',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse USB 3.0 Host Controller',
            NAME           => 'USB controller',
            PCICLASS       => '0c03',
            PCIID          => '1022:149c',
            PCISLOT        => '06:00.3',
            PCISUBSYSTEMID => '1022:148c',
            REV            => undef,
        },
        {
            DRIVER         => 'ahci',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] FCH SATA Controller [AHCI mode]',
            NAME           => 'SATA controller',
            PCICLASS       => '0106',
            PCIID          => '1022:7901',
            PCISLOT        => '07:00.0',
            PCISUBSYSTEMID => '1022:7901',
            REV            => '51',
        },
        {
            DRIVER         => 'ahci',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] FCH SATA Controller [AHCI mode]',
            NAME           => 'SATA controller',
            PCICLASS       => '0106',
            PCIID          => '1022:7901',
            PCISLOT        => '08:00.0',
            PCISUBSYSTEMID => '1022:7901',
            REV            => '51',
        },
        {
            DRIVER         => 'nvidia',
            MANUFACTURER   => 'NVIDIA Corporation TU106 [GeForce RTX 2060 SUPER]',
            MEMORY         => '288',
            NAME           => 'VGA compatible controller',
            PCICLASS       => '0300',
            PCIID          => '10de:1f06',
            PCISLOT        => '09:00.0',
            PCISUBSYSTEMID => '196e:1339',
            REV            => undef,
        },
        {
            DRIVER         => 'snd_hda_intel',
            MANUFACTURER   => 'NVIDIA Corporation TU106 High Definition Audio Controller',
            NAME           => 'Audio device',
            PCICLASS       => '0403',
            PCIID          => '10de:10f9',
            PCISLOT        => '09:00.1',
            PCISUBSYSTEMID => '196e:1339',
            REV            => undef,
        },
        {
            DRIVER         => 'xhci_hcd',
            MANUFACTURER   => 'NVIDIA Corporation TU106 USB 3.1 Host Controller',
            NAME           => 'USB controller',
            PCICLASS       => '0c03',
            PCIID          => '10de:1ada',
            PCISLOT        => '09:00.2',
            PCISUBSYSTEMID => '196e:1339',
            REV            => undef,
        },
        {
            DRIVER         => 'nvidia',
            MANUFACTURER   => 'NVIDIA Corporation TU106 USB Type-C UCSI Controller',
            NAME           => 'Serial bus controller',
            PCICLASS       => '0c80',
            PCIID          => '10de:1adb',
            PCISLOT        => '09:00.3',
            PCISUBSYSTEMID => '196e:1339',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse PCIe Dummy Function',
            NAME           => 'Non-Essential Instrumentation',
            PCICLASS       => '1300',
            PCIID          => '1022:148a',
            PCISLOT        => '0a:00.0',
            PCISUBSYSTEMID => '1043:87c0',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse Reserved SPP',
            NAME           => 'Non-Essential Instrumentation',
            PCICLASS       => '1300',
            PCIID          => '1022:1485',
            PCISLOT        => '0b:00.0',
            PCISUBSYSTEMID => '1043:87c0',
            REV            => undef,
        },
        {
            DRIVER         => 'ccp',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse Cryptographic Coprocessor PSPCPP',
            NAME           => 'Encryption controller',
            PCICLASS       => '1080',
            PCIID          => '1022:1486',
            PCISLOT        => '0b:00.1',
            PCISUBSYSTEMID => '1043:87c0',
            REV            => undef,
        },
        {
            DRIVER         => 'xhci_hcd',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Matisse USB 3.0 Host Controller',
            NAME           => 'USB controller',
            PCICLASS       => '0c03',
            PCIID          => '1022:149c',
            PCISLOT        => '0b:00.3',
            PCISUBSYSTEMID => '1043:87c0',
            REV            => undef,
        },
        {
            DRIVER         => 'snd_hda_intel',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] Starship/Matisse HD Audio Controller',
            NAME           => 'Audio device',
            PCICLASS       => '0403',
            PCIID          => '1022:1487',
            PCISLOT        => '0b:00.4',
            PCISUBSYSTEMID => '1043:87bb',
            REV            => undef,
        },
        {
            DRIVER         => 'ahci',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] FCH SATA Controller [AHCI mode]',
            NAME           => 'SATA controller',
            PCICLASS       => '0106',
            PCIID          => '1022:7901',
            PCISLOT        => '0c:00.0',
            PCISUBSYSTEMID => '1043:87c0',
            REV            => '51',
        },
        {
            DRIVER         => 'ahci',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD] FCH SATA Controller [AHCI mode]',
            NAME           => 'SATA controller',
            PCICLASS       => '0106',
            PCIID          => '1022:7901',
            PCISLOT        => '0d:00.0',
            PCISUBSYSTEMID => '1043:87c0',
            REV            => '51',
        }
    ],
    'linux-imac' => [
        {
            MANUFACTURER   => 'Intel Corporation Core Processor DRAM Controller',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '8086:0040',
            PCISLOT        => '00:00.0',
            REV            => '18',
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Intel Corporation Core Processor PCI Express x16 Root Port',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '8086:0041',
            PCISLOT        => '00:01.0',
            REV            => '18',
        },
        {
            MANUFACTURER   => 'Intel Corporation 5 Series/3400 Series Chipset USB Universal Host Controller',
            NAME           => 'USB controller',
            PCICLASS       => '0c03',
            PCIID          => '8086:3b3b',
            PCISLOT        => '00:1a.0',
            PCISUBSYSTEMID => '8086:7270',
            REV            => '06',
        },
        {
            DRIVER         => 'ehci',
            MANUFACTURER   => 'Intel Corporation 5 Series/3400 Series Chipset USB2 Enhanced Host Controller',
            NAME           => 'USB controller',
            PCICLASS       => '0c03',
            PCIID          => '8086:3b3c',
            PCISLOT        => '00:1a.7',
            PCISUBSYSTEMID => '8086:7270',
            REV            => '06',
        },
        {
            DRIVER         => 'snd_hda_intel',
            MANUFACTURER   => 'Intel Corporation 5 Series/3400 Series Chipset High Definition Audio',
            NAME           => 'Audio device',
            PCICLASS       => '0403',
            PCIID          => '8086:3b56',
            PCISLOT        => '00:1b.0',
            PCISUBSYSTEMID => '8086:7270',
            REV            => '06',
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Intel Corporation 5 Series/3400 Series Chipset PCI Express Root Port 1',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '8086:3b42',
            PCISLOT        => '00:1c.0',
            REV            => '06',
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Intel Corporation 5 Series/3400 Series Chipset PCI Express Root Port 2',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '8086:3b44',
            PCISLOT        => '00:1c.1',
            REV            => '06',
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Intel Corporation 5 Series/3400 Series Chipset PCI Express Root Port 3',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '8086:3b46',
            PCISLOT        => '00:1c.2',
            REV            => '06',
        },
        {
            MANUFACTURER   => 'Intel Corporation 5 Series/3400 Series Chipset USB Universal Host Controller',
            NAME           => 'USB controller',
            PCICLASS       => '0c03',
            PCIID          => '8086:3b36',
            PCISLOT        => '00:1d.0',
            PCISUBSYSTEMID => '8086:7270',
            REV            => '06',
        },
        {
            DRIVER         => 'ehci',
            MANUFACTURER   => 'Intel Corporation 5 Series/3400 Series Chipset USB2 Enhanced Host Controller',
            NAME           => 'USB controller',
            PCICLASS       => '0c03',
            PCIID          => '8086:3b34',
            PCISLOT        => '00:1d.7',
            PCISUBSYSTEMID => '8086:7270',
            REV            => '06',
        },
        {
            MANUFACTURER   => 'Intel Corporation 82801 PCI Bridge',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '8086:244e',
            PCISLOT        => '00:1e.0',
            REV            => undef,
        },
        {
            DRIVER         => 'lpc_ich',
            MANUFACTURER   => 'Intel Corporation P55 Chipset LPC Interface Controller',
            NAME           => 'ISA bridge',
            PCICLASS       => '0601',
            PCIID          => '8086:3b02',
            PCISLOT        => '00:1f.0',
            PCISUBSYSTEMID => '8086:7270',
            REV            => '06',
        },
        {
            DRIVER         => 'ahci',
            MANUFACTURER   => 'Intel Corporation 5 Series/3400 Series Chipset 6 port SATA AHCI Controller',
            NAME           => 'SATA controller',
            PCICLASS       => '0106',
            PCIID          => '8086:3b22',
            PCISLOT        => '00:1f.2',
            PCISUBSYSTEMID => '8086:7270',
            REV            => '06',
        },
        {
            DRIVER         => 'i801_smbus',
            MANUFACTURER   => 'Intel Corporation 5 Series/3400 Series Chipset SMBus Controller',
            NAME           => 'SMBus',
            PCICLASS       => '0c05',
            PCIID          => '8086:3b30',
            PCISLOT        => '00:1f.3',
            PCISUBSYSTEMID => '8086:7270',
            REV            => '06',
        },
        {
            MANUFACTURER   => 'Intel Corporation 5 Series/3400 Series Chipset Thermal Subsystem',
            NAME           => 'Signal processing controller',
            PCICLASS       => '1180',
            PCIID          => '8086:3b32',
            PCISLOT        => '00:1f.6',
            PCISUBSYSTEMID => '8086:0000',
            REV            => '06',
        },
        {
            DRIVER         => 'radeon',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD/ATI] RV730/M96-XT [Mobility Radeon HD 4670]',
            MEMORY         => '256',
            NAME           => 'VGA compatible controller',
            PCICLASS       => '0300',
            PCIID          => '1002:9488',
            PCISLOT        => '01:00.0',
            PCISUBSYSTEMID => '106b:00b6',
            REV            => undef,
        },
        {
            DRIVER         => 'snd_hda_intel',
            MANUFACTURER   => 'Advanced Micro Devices, Inc. [AMD/ATI] RV710/730 HDMI Audio [Radeon HD 4000 series]',
            NAME           => 'Audio device',
            PCICLASS       => '0403',
            PCIID          => '1002:aa38',
            PCISLOT        => '01:00.1',
            PCISUBSYSTEMID => '106b:aa38',
            REV            => undef,
        },
        {
            DRIVER         => 'tg3',
            MANUFACTURER   => 'Broadcom Inc. and subsidiaries NetXtreme BCM5764M Gigabit Ethernet PCIe',
            NAME           => 'Ethernet controller',
            PCICLASS       => '0200',
            PCIID          => '14e4:1684',
            PCISLOT        => '02:00.0',
            PCISUBSYSTEMID => '14e4:1684',
            REV            => '10',
        },
        {
            DRIVER         => 'ath9k',
            MANUFACTURER   => 'Qualcomm Atheros AR928X Wireless Network Adapter (PCI-Express)',
            NAME           => 'Network controller',
            PCICLASS       => '0280',
            PCIID          => '168c:002a',
            PCISLOT        => '03:00.0',
            PCISUBSYSTEMID => '106b:008f',
            REV            => '01',
        },
        {
            MANUFACTURER   => 'Texas Instruments XIO2213A/B/XIO2221 PCI Express to PCI Bridge [Cheetah Express]',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '104c:823e',
            PCISLOT        => '04:00.0',
            REV            => '01',
        },
        {
            DRIVER         => 'firewire_ohci',
            MANUFACTURER   => 'Texas Instruments XIO2213A/B/XIO2221 IEEE-1394b OHCI Controller [Cheetah Express]',
            NAME           => 'FireWire (IEEE 1394)',
            PCICLASS       => '0c00',
            PCIID          => '104c:823f',
            PCISLOT        => '05:00.0',
            REV            => '01',
        },
        {
            MANUFACTURER   => 'Intel Corporation Core Processor QuickPath Architecture Generic Non-core Registers',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '8086:2c61',
            PCISLOT        => 'ff:00.0',
            PCISUBSYSTEMID => '8086:8086',
            REV            => '05',
        },
        {
            MANUFACTURER   => 'Intel Corporation Core Processor QuickPath Architecture System Address Decoder',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '8086:2d01',
            PCISLOT        => 'ff:00.1',
            PCISUBSYSTEMID => '8086:8086',
            REV            => '05',
        },
        {
            MANUFACTURER   => 'Intel Corporation Core Processor QPI Link 0',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '8086:2d10',
            PCISLOT        => 'ff:02.0',
            PCISUBSYSTEMID => '8086:8086',
            REV            => '05',
        },
        {
            MANUFACTURER   => 'Intel Corporation 1st Generation Core i3/5/7 Processor QPI Physical 0',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '8086:2d11',
            PCISLOT        => 'ff:02.1',
            PCISUBSYSTEMID => '8086:8086',
            REV            => '05',
        },
        {
            MANUFACTURER   => 'Intel Corporation 1st Generation Core i3/5/7 Processor Reserved',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '8086:2d12',
            PCISLOT        => 'ff:02.2',
            PCISUBSYSTEMID => '8086:8086',
            REV            => '05',
        },
        {
            MANUFACTURER   => 'Intel Corporation 1st Generation Core i3/5/7 Processor Reserved',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '8086:2d13',
            PCISLOT        => 'ff:02.3',
            PCISUBSYSTEMID => '8086:8086',
            REV            => '05',
        },
    ],
    'linux-xps' => [
        {
            DRIVER         => 'skl_uncore',
            MANUFACTURER   => 'Intel Corporation Xeon E3-1200 v5/E3-1500 v5/6th Gen Core Processor Host Bridge/DRAM Registers',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '8086:1904',
            PCISLOT        => '00:00.0',
            PCISUBSYSTEMID => '1028:0704',
            REV            => '08',
        },
        {
            DRIVER         => 'i915',
            MANUFACTURER   => 'Intel Corporation Skylake GT2 [HD Graphics 520]',
            MEMORY         => '256',
            NAME           => 'VGA compatible controller',
            PCICLASS       => '0300',
            PCIID          => '8086:1916',
            PCISLOT        => '00:02.0',
            PCISUBSYSTEMID => '1028:0704',
            REV            => '07',
        },
        {
            DRIVER         => 'proc_thermal',
            MANUFACTURER   => 'Intel Corporation Xeon E3-1200 v5/E3-1500 v5/6th Gen Core Processor Thermal Subsystem',
            NAME           => 'Signal processing controller',
            PCICLASS       => '1180',
            PCIID          => '8086:1903',
            PCISLOT        => '00:04.0',
            PCISUBSYSTEMID => '1028:0704',
            REV            => '08',
        },
        {
            DRIVER         => 'xhci_hcd',
            MANUFACTURER   => 'Intel Corporation Sunrise Point-LP USB 3.0 xHCI Controller',
            NAME           => 'USB controller',
            PCICLASS       => '0c03',
            PCIID          => '8086:9d2f',
            PCISLOT        => '00:14.0',
            PCISUBSYSTEMID => '1028:0704',
            REV            => '21',
        },
        {
            DRIVER         => 'intel_pch_thermal',
            MANUFACTURER   => 'Intel Corporation Sunrise Point-LP Thermal subsystem',
            NAME           => 'Signal processing controller',
            PCICLASS       => '1180',
            PCIID          => '8086:9d31',
            PCISLOT        => '00:14.2',
            PCISUBSYSTEMID => '1028:0704',
            REV            => '21',
        },
        {
            DRIVER         => 'intel',
            MANUFACTURER   => 'Intel Corporation Sunrise Point-LP Serial IO I2C Controller #0',
            NAME           => 'Signal processing controller',
            PCICLASS       => '1180',
            PCIID          => '8086:9d60',
            PCISLOT        => '00:15.0',
            PCISUBSYSTEMID => '1028:0704',
            REV            => '21',
        },
        {
            DRIVER         => 'intel',
            MANUFACTURER   => 'Intel Corporation Sunrise Point-LP Serial IO I2C Controller #1',
            NAME           => 'Signal processing controller',
            PCICLASS       => '1180',
            PCIID          => '8086:9d61',
            PCISLOT        => '00:15.1',
            PCISUBSYSTEMID => '1028:0704',
            REV            => '21',
        },
        {
            DRIVER         => 'mei_me',
            MANUFACTURER   => 'Intel Corporation Sunrise Point-LP CSME HECI #1',
            NAME           => 'Communication controller',
            PCICLASS       => '0780',
            PCIID          => '8086:9d3a',
            PCISLOT        => '00:16.0',
            PCISUBSYSTEMID => '1028:0704',
            REV            => '21',
        },
        {
            DRIVER         => 'ahci',
            MANUFACTURER   => 'Intel Corporation Sunrise Point-LP SATA Controller [AHCI mode]',
            NAME           => 'SATA controller',
            PCICLASS       => '0106',
            PCIID          => '8086:9d03',
            PCISLOT        => '00:17.0',
            PCISUBSYSTEMID => '1028:0704',
            REV            => '21',
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Intel Corporation Sunrise Point-LP PCI Express Root Port #1',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '8086:9d10',
            PCISLOT        => '00:1c.0',
            REV            => undef,
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Intel Corporation Sunrise Point-LP PCI Express Root Port #5',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '8086:9d14',
            PCISLOT        => '00:1c.4',
            REV            => undef,
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Intel Corporation Sunrise Point-LP PCI Express Root Port #6',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '8086:9d15',
            PCISLOT        => '00:1c.5',
            REV            => undef,
        },
        {
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Intel Corporation Sunrise Point-LP PCI Express Root Port #9',
            NAME           => 'PCI bridge',
            PCICLASS       => '0604',
            PCIID          => '8086:9d18',
            PCISLOT        => '00:1d.0',
            REV            => undef,
        },
        {
            MANUFACTURER   => 'Intel Corporation Sunrise Point-LP LPC Controller',
            NAME           => 'ISA bridge',
            PCICLASS       => '0601',
            PCIID          => '8086:9d48',
            PCISLOT        => '00:1f.0',
            PCISUBSYSTEMID => '1028:0704',
            REV            => '21',
        },
        {
            MANUFACTURER   => 'Intel Corporation Sunrise Point-LP PMC',
            NAME           => 'Memory controller',
            PCICLASS       => '0580',
            PCIID          => '8086:9d21',
            PCISLOT        => '00:1f.2',
            PCISUBSYSTEMID => '1028:0704',
            REV            => '21',
        },
        {
            DRIVER         => 'snd_hda_intel',
            MANUFACTURER   => 'Intel Corporation Sunrise Point-LP HD Audio',
            NAME           => 'Audio device',
            PCICLASS       => '0403',
            PCIID          => '8086:9d70',
            PCISLOT        => '00:1f.3',
            PCISUBSYSTEMID => '1028:0704',
            REV            => '21',
        },
        {
            MANUFACTURER   => 'Intel Corporation Sunrise Point-LP SMBus',
            NAME           => 'SMBus',
            PCICLASS       => '0c05',
            PCIID          => '8086:9d23',
            PCISLOT        => '00:1f.4',
            PCISUBSYSTEMID => '1028:0704',
            REV            => '21',
        },
        {
            DRIVER         => 'iwlwifi',
            MANUFACTURER   => 'Intel Corporation Wireless 8260',
            NAME           => 'Network controller',
            PCICLASS       => '0280',
            PCIID          => '8086:24f3',
            PCISLOT        => '3a:00.0',
            PCISUBSYSTEMID => '8086:0050',
            REV            => undef,
        },
        {
            DRIVER         => 'rtsx_pci',
            MANUFACTURER   => 'Realtek Semiconductor Co., Ltd. RTS525A PCI Express Card Reader',
            NAME           => 'Unassigned class',
            PCICLASS       => 'ff00',
            PCIID          => '10ec:525a',
            PCISLOT        => '3b:00.0',
            PCISUBSYSTEMID => '1028:0704',
            REV            => '01',
        },
        {
            DRIVER         => 'nvme',
            MANUFACTURER   => 'Samsung Electronics Co Ltd NVMe SSD Controller SM951/PM951',
            NAME           => 'Non-Volatile memory controller',
            PCICLASS       => '0108',
            PCIID          => '144d:a802',
            PCISLOT        => '3c:00.0',
            PCISUBSYSTEMID => '144d:a801',
            REV            => '01',
        },
    ],
    'linux-asus-portable' => [        {
            MANUFACTURER   => 'Intel Corporation 11th Gen Core Processor Host Bridge/DRAM Registers',
            NAME           => 'Host bridge',
            PCICLASS       => '0600',
            PCIID          => '8086:9a14',
            PCISLOT        => '0000:00:00.0',
            PCISUBSYSTEMID => '1043:1a52',
            REV            => '01',
        },
        {
            DRIVER         => 'i915',
            MANUFACTURER   => 'Intel Corporation TigerLake-LP GT2 [Iris Xe Graphics]',
            MEMORY         => '256',
            NAME           => 'VGA compatible controller',
            PCICLASS       => '0300',
            PCIID          => '8086:9a49',
            PCISLOT        => '0000:00:02.0',
            PCISUBSYSTEMID => '1043:189c',
            REV            => '01',
        },
        {
            DRIVER         => 'proc_thermal',
            MANUFACTURER   => 'Intel Corporation TigerLake-LP Dynamic Tuning Processor Participant',
            NAME           => 'Signal processing controller',
            PCICLASS       => '1180',
            PCIID          => '8086:9a03',
            PCISLOT        => '0000:00:04.0',
            PCISUBSYSTEMID => '1043:1a52',
            REV            => '01',
        },
        {
            DRIVER       => 'pcieport',
            MANUFACTURER => 'Intel Corporation 11th Gen Core Processor PCIe Controller',
            NAME         => 'PCI bridge',
            PCICLASS     => '0604',
            PCIID        => '8086:9a09',
            PCISLOT      => '0000:00:06.0',
            REV          => '01',
        },
        {
            DRIVER       => 'pcieport',
            MANUFACTURER => 'Intel Corporation Tiger Lake-LP Thunderbolt 4 PCI Express Root Port #0',
            NAME         => 'PCI bridge',
            PCICLASS     => '0604',
            PCIID        => '8086:9a23',
            PCISLOT      => '0000:00:07.0',
            REV          => '01',
        },
        {
            MANUFACTURER   => 'Intel Corporation GNA Scoring Accelerator module',
            NAME           => 'System peripheral',
            PCICLASS       => '0880',
            PCIID          => '8086:9a11',
            PCISLOT        => '0000:00:08.0',
            PCISUBSYSTEMID => '1043:1a52',
            REV            => '01',
        },
        {
            DRIVER       => 'intel_vsec',
            MANUFACTURER => 'Intel Corporation Tigerlake Telemetry Aggregator Driver',
            NAME         => 'Signal processing controller',
            PCICLASS     => '1180',
            PCIID        => '8086:9a0d',
            PCISLOT      => '0000:00:0a.0',
            REV          => '01',
        },
        {
            DRIVER       => 'xhci_hcd',
            MANUFACTURER => 'Intel Corporation Tiger Lake-LP Thunderbolt 4 USB Controller',
            NAME         => 'USB controller',
            PCICLASS     => '0c03',
            PCIID        => '8086:9a13',
            PCISLOT      => '0000:00:0d.0',
            REV          => '01',
        },
        {
            DRIVER         => 'thunderbolt',
            MANUFACTURER   => 'Intel Corporation Tiger Lake-LP Thunderbolt 4 NHI #0',
            NAME           => 'USB controller',
            PCICLASS       => '0c03',
            PCIID          => '8086:9a1b',
            PCISLOT        => '0000:00:0d.2',
            PCISUBSYSTEMID => '2222:1111',
            REV            => '01',
        },
        {
            DRIVER         => 'vmd',
            MANUFACTURER   => 'Intel Corporation Volume Management Device NVMe RAID Controller',
            NAME           => 'RAID bus controller',
            PCICLASS       => '0104',
            PCIID          => '8086:9a0b',
            PCISLOT        => '0000:00:0e.0',
            PCISUBSYSTEMID => '8086:0000',
            REV            => undef
        },
        {
            DRIVER         => 'xhci_hcd',
            MANUFACTURER   => 'Intel Corporation Tiger Lake-LP USB 3.2 Gen 2x1 xHCI Host Controller',
            NAME           => 'USB controller',
            PCICLASS       => '0c03',
            PCIID          => '8086:a0ed',
            PCISLOT        => '0000:00:14.0',
            PCISUBSYSTEMID => '1043:201f',
            REV            => '20',
        },
        {
            MANUFACTURER   => 'Intel Corporation Tiger Lake-LP Shared SRAM',
            NAME           => 'RAM memory',
            PCICLASS       => '0500',
            PCIID          => '8086:a0ef',
            PCISLOT        => '0000:00:14.2',
            PCISUBSYSTEMID => '1043:1a52',
            REV            => '20',
        },
        {
            DRIVER         => 'iwlwifi',
            MANUFACTURER   => 'Intel Corporation Wi-Fi 6 AX201',
            NAME           => 'Network controller',
            PCICLASS       => '0280',
            PCIID          => '8086:a0f0',
            PCISLOT        => '0000:00:14.3',
            PCISUBSYSTEMID => '8086:0074',
            REV            => '20',
        },
        {
            DRIVER         => 'intel',
            MANUFACTURER   => 'Intel Corporation Tiger Lake-LP Serial IO I2C Controller #0',
            NAME           => 'Serial bus controller',
            PCICLASS       => '0c80',
            PCIID          => '8086:a0e8',
            PCISLOT        => '0000:00:15.0',
            PCISUBSYSTEMID => '1043:1a52',
            REV            => '20',
        },
        {
            DRIVER         => 'intel',
            MANUFACTURER   => 'Intel Corporation Tiger Lake-LP Serial IO I2C Controller #1',
            NAME           => 'Serial bus controller',
            PCICLASS       => '0c80',
            PCIID          => '8086:a0e9',
            PCISLOT        => '0000:00:15.1',
            PCISUBSYSTEMID => '1043:1a52',
            REV            => '20',
        },
        {
            DRIVER         => 'mei_me',
            MANUFACTURER   => 'Intel Corporation Tiger Lake-LP Management Engine Interface',
            NAME           => 'Communication controller',
            PCICLASS       => '0780',
            PCIID          => '8086:a0e0',
            PCISLOT        => '0000:00:16.0',
            PCISUBSYSTEMID => '1043:1a52',
            REV            => '20',
        },
        {
            MANUFACTURER   => 'Intel Corporation RST VMD Managed Controller',
            NAME           => 'System peripheral',
            PCICLASS       => '0880',
            PCIID          => '8086:09ab',
            PCISLOT        => '0000:00:1d.0',
            PCISUBSYSTEMID => '1043:1a52',
            REV            => undef
        },
        {
            MANUFACTURER   => 'Intel Corporation Tiger Lake-LP LPC Controller',
            NAME           => 'ISA bridge',
            PCICLASS       => '0601',
            PCIID          => '8086:a082',
            PCISLOT        => '0000:00:1f.0',
            PCISUBSYSTEMID => '1043:1a52',
            REV            => '20',
        },
        {
            DRIVER         => 'snd_hda_intel',
            MANUFACTURER   => 'Intel Corporation Tiger Lake-LP Smart Sound Technology Audio Controller',
            NAME           => 'Audio device',
            PCICLASS       => '0403',
            PCIID          => '8086:a0c8',
            PCISLOT        => '0000:00:1f.3',
            PCISUBSYSTEMID => '1043:1a52',
            REV            => '20',
        },
        {
            DRIVER         => 'i801_smbus',
            MANUFACTURER   => 'Intel Corporation Tiger Lake-LP SMBus Controller',
            NAME           => 'SMBus',
            PCICLASS       => '0c05',
            PCIID          => '8086:a0a3',
            PCISLOT        => '0000:00:1f.4',
            PCISUBSYSTEMID => '1043:1a52',
            REV            => '20',
        },
        {
            MANUFACTURER   => 'Intel Corporation Tiger Lake-LP SPI Controller',
            NAME           => 'Serial bus controller',
            PCICLASS       => '0c80',
            PCIID          => '8086:a0a4',
            PCISLOT        => '0000:00:1f.5',
            PCISUBSYSTEMID => '1043:1a52',
            REV            => '20',
        },
        {
            DRIVER         => 'nvidia',
            MANUFACTURER   => 'NVIDIA Corporation TU117M [GeForce GTX 1650 Mobile / Max-Q]',
            MEMORY         => '288',
            NAME           => '3D controller',
            PCICLASS       => '0302',
            PCIID          => '10de:1f9d',
            PCISLOT        => '0000:01:00.0',
            PCISUBSYSTEMID => '1043:189c',
            REV            => undef
        },
        {
            DRIVER       => 'pcieport',
            MANUFACTURER => 'Intel Corporation Tiger Lake-LP PCI Express Root Port #9',
            NAME         => 'PCI bridge',
            PCICLASS     => '0604',
            PCIID        => '8086:a0b0',
            PCISLOT      => '10000:e0:1d.0',
            REV          => '20',
        },
        {
            DRIVER         => 'nvme',
            MANUFACTURER   => 'Intel Corporation Device',
            NAME           => 'Non-Volatile memory controller',
            PCICLASS       => '0108',
            PCIID          => '8086:f1aa',
            PCISLOT        => '10000:e1:00.0',
            PCISUBSYSTEMID => '8086:390f',
            REV            => '03',
        },
    ],
);

my %hdparm_tests = (
    linux1 => {
        FIRMWARE     => 'CXM13D1Q',
        MODEL        => 'SAMSUNG SSD PM830 mSATA 256GB',
        SERIALNUMBER => 'S0XPNYAD412339',
        DISKSIZE     => '256060',
        DESCRIPTION  => 'SATA',
        INTERFACE    => 'SATA',
        WWN          => '5002538043584d30'
    },
    linux2 => {},
    linux3 => {
        FIRMWARE     => 'GKAOAC5A',
        MODEL        => 'HITACHI HUA7210SASUN1.0T 0812G2959E',
        SERIALNUMBER => 'GTE000PAJ2959E',
        DISKSIZE     => '1000204',
        WWN          => '5000cca216dd3a2d'
    },
    linux4 => {},
);

my %edid_vendor_tests = (
    NVD => 'Nvidia',
    XQU => 'SHANGHAI SVA-DAV ELECTRONICS CO., LTD',
);

plan tests =>
    (scalar keys %dmidecode_tests) +
    (scalar keys %cpu_tests)       +
    (scalar keys %lspci_tests)     +
    (scalar keys %hdparm_tests)    +
    (scalar keys %edid_vendor_tests);

foreach my $test (keys %dmidecode_tests) {
    my $file = "resources/generic/dmidecode/$test";
    my $infos = getDmidecodeInfos(file => $file);
    cmp_deeply($infos, $dmidecode_tests{$test}, "$test dmidecode parsing");
}

foreach my $test (keys %cpu_tests) {
    my $file = "resources/generic/dmidecode/$test";
    my @cpus = getCpusFromDmidecode(file => $file);
    cmp_deeply(\@cpus, $cpu_tests{$test}, "$test dmidecode cpu extraction");
}

foreach my $test (keys %lspci_tests) {
    my $file = "resources/generic/lspci/$test";
    my @devices = getPCIDevices(file => $file);
    #~ print STDERR _dumpLspci($test, @devices) if $test eq 'linux-asus-portable';
    cmp_deeply(\@devices, $lspci_tests{$test}, "$test lspci parsing");
}

foreach my $test (keys %hdparm_tests) {
    my $file = "resources/generic/hdparm/$test";
    my $info = getHdparmInfo(file => $file);
    cmp_deeply($info, $hdparm_tests{$test}, "$test hdparm parsing");
}

foreach my $test (keys %edid_vendor_tests) {
    is(
        getEDIDVendor(id => $test, datadir => './share'),
        $edid_vendor_tests{$test},
        "edid vendor identification: $test"
    );
}

# Use it to format new lspci test entry
sub _dumpLspci {
    my $name = shift @_;
    print STDERR "\n    '$name' => [\n";
    foreach my $device (@_) {
        print STDERR "        {\n";
        my ($len) = sort { $b <=> $a } map { length($_) } keys(%{$device});
        foreach my $key (sort(keys(%{$device}))) {
            print STDERR sprintf("            %-".$len."s => ", $key);
            if (defined($device->{$key})) {
                print STDERR "'$device->{$key}',\n";
            } else {
                print STDERR "undef\n";
            }
        }
        print STDERR "        },\n";
    }
    print STDERR "    ],\n";
}
