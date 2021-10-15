#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Generic::Dmidecode::Ports;

my %tests = (
    'freebsd-6.2' => [
        {
            NAME        => 'PRIMARY IDE',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'SECONDARY IDE',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'FDD',
            DESCRIPTION => 'On Board Floppy',
            TYPE        => '8251 FIFO Compatible',
            CAPTION     => undef
        },
        {
            NAME        => 'COM1',
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16450 Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => 'COM2',
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16450 Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => 'LPT1',
            DESCRIPTION => 'DB-25 female',
            TYPE        => 'Parallel Port ECP/EPP',
            CAPTION     => 'DB-25 female'
        },
        {
            NAME        => 'Keyboard',
            DESCRIPTION => 'PS/2',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => 'PS/2 Mouse',
            DESCRIPTION => 'PS/2',
            TYPE        => 'Mouse Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => 'USB0',
            DESCRIPTION => 'Other',
            TYPE        => 'USB',
            CAPTION     => 'USB0'
        }
    ],
    'freebsd-8.1' => undef,
    'linux-2.6' => [
         {
            NAME        => 'PARALLEL',
            DESCRIPTION => 'DB-25 female',
            TYPE        => 'Parallel Port PS/2',
            CAPTION     => 'DB-25 female'
        },
        {
            NAME        => 'SERIAL1',
            DESCRIPTION => 'DB-9 male',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => 'USB',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'MONITOR',
            DESCRIPTION => 'DB-15 female',
            TYPE        => 'Video Port',
            CAPTION     => 'DB-15 female'
        },
        {
            NAME        => 'IrDA',
            DESCRIPTION => 'Infrared',
            TYPE        => 'Other',
            CAPTION     => 'Infrared'
        },
        {
            NAME        => 'Modem',
            DESCRIPTION => 'RJ-11',
            TYPE        => 'Modem Port',
            CAPTION     => 'RJ-11'
        },
        {
            NAME        => 'Ethernet',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45'
        }
    ],
    'openbsd-3.7' => [
         {
            NAME        => 'PRIMARY IDE',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'SECONDARY IDE',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'FLOPPY',
            DESCRIPTION => 'On Board Floppy',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'COM1',
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16550 Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => 'COM2',
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16550 Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => 'LPT1',
            DESCRIPTION => 'DB-25 female',
            TYPE        => 'Parallel Port ECP/EPP',
            CAPTION     => 'DB-25 female'
        },
        {
            NAME        => 'Keyboard',
            DESCRIPTION => 'Other',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => 'PS/2 Mouse',
            DESCRIPTION => 'Other',
            TYPE        => 'Mouse Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => 'IR_CON',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => 'Infrared'
        },
        {
            NAME        => 'IR_CON2',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => 'Infrared'
        },
        {
            NAME        => 'USB',
            DESCRIPTION => 'Other',
            TYPE        => 'USB',
            CAPTION     => 'Other'
        }
    ],
    'openbsd-3.8' => [
        {
            NAME        => 'SCSI',
            DESCRIPTION => '68 Pin Dual Inline',
            TYPE        => 'SCSI Wide',
            CAPTION     => undef
        },
        {
            NAME        => undef,
            DESCRIPTION => 'DB-15 female',
            TYPE        => 'Video Port',
            CAPTION     => 'DB-15 female'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'DB-25 female',
            TYPE        => 'Parallel Port PS/2',
            CAPTION     => 'DB-25 female'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'DB-9 male',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'PS/2',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'PS/2',
            TYPE        => 'Mouse Port',
            CAPTION     => 'PS/2'
        }
    ],
    'rhel-2.1' => [
        {
            NAME        => 'SERIAL1',
            DESCRIPTION => 'SERIAL1',
            TYPE        => 'Serial Port 16650A Compatible',
            CAPTION     => 'DB-9 pin male'
        },
        {
            NAME        => 'SERIAL2',
            DESCRIPTION => 'SERIAL2',
            TYPE        => 'Serial Port 16650A Compatible',
            CAPTION     => 'DB-9 pin male'
        },
        {
            NAME        => 'PRINTER',
            DESCRIPTION => 'PRINTER',
            TYPE        => 'Parallel Port ECP/EPP',
            CAPTION     => 'DB-25 pin female'
        },
        {
            NAME        => 'KEYBOARD',
            DESCRIPTION => 'KEYBOARD',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => 'MOUSE',
            DESCRIPTION => 'MOUSE',
            TYPE        => 'Mouse Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => 'USB1',
            DESCRIPTION => 'USB1',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'USB2',
            DESCRIPTION => 'USB2',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'IDE1',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'IDE2',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'FDD',
            DESCRIPTION => 'On Board Floppy',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'SCSI1',
            DESCRIPTION => 'SSA SCSI',
            TYPE        => 'SCSI II',
            CAPTION     => undef
        }
    ],
    'rhel-3.4' => [
        {
            NAME        => 'J2A1',
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'COM 1'
        },
        {
            NAME        => 'J2A2',
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'COM 2'
        },
        {
            NAME        => 'J3A1',
            DESCRIPTION => '25 Pin Dual Inline (pin 26 cut)',
            TYPE        => 'Parallel Port ECP/EPP',
            CAPTION     => 'Parallel'
        },
        {
            NAME        => 'J1A1',
            DESCRIPTION => 'Circular DIN-8 male',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'Keyboard'
        },
        {
            NAME        => 'J1A1',
            DESCRIPTION => 'Circular DIN-8 male',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2 Mouse'
        }
    ],
    'rhel-4.3' => [
        {
            NAME        => 'IDE1',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'IDE2',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'FDD',
            DESCRIPTION => 'On Board Floppy',
            TYPE        => '8251 FIFO Compatible',
            CAPTION     => undef
        },
        {
            NAME        => 'COM1',
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16450 Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => 'COM2',
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16450 Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => 'LPT1',
            DESCRIPTION => 'DB-25 female',
            TYPE        => 'Parallel Port ECP/EPP',
            CAPTION     => 'DB-25 female'
        },
        {
            NAME        => 'Keyboard',
            DESCRIPTION => 'PS/2',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => 'PS/2 Mouse',
            DESCRIPTION => 'PS/2',
            TYPE        => 'Mouse Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => 'JUSB1',
            DESCRIPTION => 'Other',
            TYPE        => 'USB',
            CAPTION     => 'JUSB1'
        },
        {
            NAME        => 'JUSB2',
            DESCRIPTION => 'Other',
            TYPE        => 'USB',
            CAPTION     => 'JUSB2',
        },
        {
            NAME        => 'AUD1',
            DESCRIPTION => undef,
            TYPE        => 'Audio Port',
            CAPTION     => 'AUD1'
        },
        {
            NAME        => 'JLAN1',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'JLAN1'
        },
        {
            NAME        => 'SCSI1',
            DESCRIPTION => undef,
            TYPE        => 'SCSI Wide',
            CAPTION     => 'SCSI1'
        },
        {
            NAME        => 'SCSI2',
            DESCRIPTION => undef,
            TYPE        => 'SCSI Wide',
            CAPTION     => 'SCSI2'
        }
    ],
    'rhel-4.6' => [
        {
            NAME        => 'J16',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Port 1'
        },
        {
            NAME        => 'J19',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Port 2'
        },
        {
            NAME        => 'J69',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Port 3'
        },
        {
            NAME        => 'J69',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Port 4'
        },
        {
            NAME        => 'J02',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Port 5'
        },
        {
            NAME        => 'J03',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Port 6'
        }
    ],
    'hp-dl180' => [
        {
            NAME        => 'J1',
            DESCRIPTION => 'DB-15 female',
            TYPE        => 'Video Port',
            CAPTION     => 'VGA Port'
        },
        {
            NAME        => 'J2',
            DESCRIPTION => 'DB-9 male',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'COM Port'
        },
        {
            NAME        => 'J3',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'NIC Port 1'
        },
        {
            NAME        => 'J3',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'NIC Port 2'
        },
        {
            NAME        => 'J53',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Port 0'
        },
        {
            NAME        => 'J53',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Port 1'
        },
        {
            NAME        => 'J12',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Port 2'
        },
        {
            NAME        => 'J12',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Port 3'
        },
        {
            NAME        => 'J41 - SATA Port 1',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => undef
        },
        {
            NAME        => 'J49 - SATA Port 2',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => undef
        },
        {
            NAME        => 'J52 - SATA Port 3',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => undef
        },
        {
            NAME        => 'J55 - SATA Port 4',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => undef
        },
        {
            NAME        => 'J57 - SATA Port 5',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => undef
        },
        {
            NAME        => 'J58 - SATA Port 6',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => undef
        },
        {
            NAME        => 'J69 - USB Port 4',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => undef
        }
    ],
    'linux-1' => [
        {
            NAME        => 'PS/2 Keyboard',
            DESCRIPTION => 'PS/2',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2 Keyboard'
        },
        {
            NAME        => 'USB12',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB12'
        },
        {
            NAME        => 'USB34',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB34'
        },
        {
            NAME        => 'USB56',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB56'
        },
        {
            NAME        => 'USB78',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB78'
        },
        {
            NAME        => 'USB910',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB910'
        },
        {
            NAME        => 'USB1112',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB1112'
        },
        {
            NAME        => 'GbE LAN',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'GbE LAN'
        },
        {
            NAME        => 'COM 1',
            DESCRIPTION => 'DB-9 male',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'COM 1'
        },
        {
            NAME        => 'Audio Line Out1',
            DESCRIPTION => 'Mini Jack (headphones)',
            TYPE        => 'Audio Port',
            CAPTION     => 'Audio Line Out1'
        },
        {
            NAME        => 'Audio Line Out2',
            DESCRIPTION => 'Mini Jack (headphones)',
            TYPE        => 'Audio Port',
            CAPTION     => 'Audio Line Out2'
        },
        {
            NAME        => 'Audio Line Out3',
            DESCRIPTION => 'Mini Jack (headphones)',
            TYPE        => 'Audio Port',
            CAPTION     => 'Audio Line Out3'
        },
        {
            NAME        => 'Audio Line Out4',
            DESCRIPTION => 'Mini Jack (headphones)',
            TYPE        => 'Audio Port',
            CAPTION     => 'Audio Line Out4'
        },
        {
            NAME        => 'Audio Line Out5',
            DESCRIPTION => 'Mini Jack (headphones)',
            TYPE        => 'Audio Port',
            CAPTION     => 'Audio Line Out5'
        },
        {
            NAME        => 'Audio Line Out6',
            DESCRIPTION => 'Mini Jack (headphones)',
            TYPE        => 'Audio Port',
            CAPTION     => 'Audio Line Out6'
        },
        {
            NAME        => 'SPDIF_OUT',
            DESCRIPTION => 'On Board Sound Input From CD-ROM',
            TYPE        => 'Audio Port',
            CAPTION     => 'SPDIF_OUT'
        },
        {
            NAME        => 'IE1394_1',
            DESCRIPTION => 'IEEE 1394',
            TYPE        => 'Firewire (IEEE P1394)',
            CAPTION     => 'IE1394_1'
        },
        {
            NAME        => 'IE1394_2',
            DESCRIPTION => 'IEEE 1394',
            TYPE        => 'Firewire (IEEE P1394)',
            CAPTION     => 'IE1394_2'
        },
        {
            NAME        => 'SATA1',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => undef
        },
        {
            NAME        => 'SATA2',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => undef
        },
        {
            NAME        => 'SATA3',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => undef
        },
        {
            NAME        => 'SATA4',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => undef
        },
        {
            NAME        => 'SATA5',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => undef
        },
        {
            NAME        => 'SATA6',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => undef
        },
        {
            NAME        => 'PRI_EIDE',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => undef
        },
        {
            NAME        => 'SATAE1',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => undef
        },
        {
            NAME        => 'SATAE2',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => undef
        },
        {
            NAME        => 'FLOPPY',
            DESCRIPTION => 'On Board Floppy',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'CD',
            DESCRIPTION => 'On Board Sound Input From CD-ROM',
            TYPE        => 'Audio Port',
            CAPTION     => undef
        },
        {
            NAME        => 'AAFP',
            DESCRIPTION => 'Mini Jack (headphones)',
            TYPE        => 'Audio Port',
            CAPTION     => undef
        },
        {
            NAME        => 'CPU_FAN',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'PWR_FAN',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'CHA_FAN1',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'CHA_FAN2',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'JSD1',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => 'Cardreader'
        }
    ],
    'openbsd-4.5' => [
        {
            NAME        => undef,
            DESCRIPTION => 'DB-25 female',
            TYPE        => 'Parallel Port PS/2',
            CAPTION     => 'DB-25 female'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'DB-9 male',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'PS/2',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'Mini DIN',
            TYPE        => 'Mouse Port',
            CAPTION     => 'Mini DIN'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'DB-15 female',
            TYPE        => 'Video Port',
            CAPTION     => 'DB-15 female'
        },
        {
            NAME        => 'PRIMARY SCSI CHANNEL',
            DESCRIPTION => '68 Pin Dual Inline',
            TYPE        => 'SCSI Wide',
            CAPTION     => undef
        }
    ],
    'oracle-server-x5-2' => [
        {
            NAME        => 'J2803',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Internal Connector - Bottom'
        },
        {
            NAME        => 'J2803',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Internal Connector - Top'
        },
        {
            NAME        => 'J2901',
            DESCRIPTION => 'DB-15 female',
            TYPE        => 'Video Port',
            CAPTION     => 'VGA Connector'
        },
        {
            NAME        => 'J2801',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Rear Connector - Left'
        },
        {
            NAME        => 'J2802',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Rear Connector - Right'
        },
        {
            NAME        => 'USB Front Connector - Left',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Front Connector - Left'
        },
        {
            NAME        => 'USB Front Connector - Right',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB Front Connector - Right'
        },
        {
            NAME        => 'J2903',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Serial Port 16550 Compatible',
            CAPTION     => 'SER MGT'
        },
        {
            NAME        => 'J2902',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'NET MGT'
        },
        {
            NAME        => 'J3502',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'NET 0'
        },
        {
            NAME        => 'J3501',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'NET 1'
        },
        {
            NAME        => 'J3802',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'NET 2'
        },
        {
            NAME        => 'J3801',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'NET 3'
        },
        {
            NAME        => 'J2003',
            DESCRIPTION => 'SAS/SATA Plug Receptacle',
            TYPE        => 'SATA',
            CAPTION     => 'DVD'
        }
    ],
    'S3000AHLX' => [
        {
            NAME        => 'J9A1',
            DESCRIPTION => 'PS/2',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS2 Keyboard'
        },
        {
            NAME        => 'J9A1',
            DESCRIPTION => 'PS/2',
            TYPE        => 'Mouse Port',
            CAPTION     => 'PS2 Mouse'
        },
        {
            NAME        => 'J8A1',
            DESCRIPTION => 'Other',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'Serial Port'
        },
        {
            NAME        => 'JA5A1',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB'
        },
        {
            NAME        => 'JA5A1',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB'
        },
        {
            NAME        => 'J1F2',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB'
        },
        {
            NAME        => 'J1F2',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB'
        },
        {
            NAME        => 'JA5A1',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45 Type'
        },
        {
            NAME        => 'JA6A1',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45 Type'
        },
        {
            NAME        => 'J3J3 - FLOPPY',
            DESCRIPTION => 'On Board Floppy',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J3J2 - IDE',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1G2 - SATA0',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1H1 - SATA1',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1J2 - SATA2',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J2J1 - SATA3',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J3J4 - SATA4',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J2J2 - SATA5',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        }
    ],
    'S5000VSA' => [
        {
            NAME        => 'PS/2 Keyboard',
            DESCRIPTION => 'PS/2',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2 Keyboard'
        },
        {
            NAME        => 'PS/2 Mouse',
            DESCRIPTION => 'PS/2',
            TYPE        => 'Mouse Port',
            CAPTION     => 'PS/2 Mouse'
        },
        {
            NAME        => 'SERIAL A',
            DESCRIPTION => 'DB-9 male',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'SERIAL A'
        },
        {
            NAME        => 'J1B1 - SERIAL B (EMP)',
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => undef
        },
        {
            NAME        => 'VGA',
            DESCRIPTION => 'DB-15 female',
            TYPE        => 'Video Port',
            CAPTION     => 'VGA'
        },
        {
            NAME        => 'USB',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB'
        },
        {
            NAME        => 'USB',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB'
        },
        {
            NAME        => 'USB',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB'
        },
        {
            NAME        => 'USB',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB'
        },
        {
            NAME        => 'J1J8 - 10 PIN (Pin 9 Cut) USB',
            DESCRIPTION => 'Other',
            TYPE        => 'USB',
            CAPTION     => undef
        },
        {
            NAME        => 'J1J8 - 10 PIN (Pin 9 Cut) USB',
            DESCRIPTION => 'Other',
            TYPE        => 'USB',
            CAPTION     => undef
        },
        {
            NAME        => 'J1E2 - USB',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => undef
        },
        {
            NAME        => 'NIC 1',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'NIC 1'
        },
        {
            NAME        => 'NIC 2',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'NIC 2'
        },
        {
            NAME        => 'J2K4 - IDE Connector',
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1K3 - 1x7 Pin SATA 0',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1J7 - 1x7 Pin SATA 1',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1J4 - 1x7 Pin SATA 2',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1H3 - 1x7 Pin SATA 3',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1H1 - 1x7 Pin SATA 4',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1G6 - 1x7 Pin SATA 5',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1F1 - 24-Pin Male Front Panel',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1G3 4-Pin Male HSBP A',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1G5 4-Pin Male HSBP B',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1J6 4-Pin Male LCP IPMB',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1J5 3-Pin Male IPMB',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1A1 2-Pin Male Chassis Intrusion',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => 'J1D1 3-Pin Male SATA RAID Key',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => undef
        }
    ],
    'vmware' => [
        {
            NAME        => 'J19',
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'COM 1'
        },
        {
            NAME        => 'J23',
            DESCRIPTION => '25 Pin Dual Inline (pin 26 cut)',
            TYPE        => 'Parallel Port ECP/EPP',
            CAPTION     => 'Parallel'
        },
        {
            NAME        => 'J11',
            DESCRIPTION => 'Circular DIN-8 male',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'Keyboard'
        },
        {
            NAME        => 'J12',
            DESCRIPTION => 'Circular DIN-8 male',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2 Mouse'
        }
    ],
    'vmware-esx' => [
        {
            NAME        => 'J19',
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'COM 1'
        },
        {
            NAME        => 'J23',
            DESCRIPTION => '25 Pin Dual Inline (pin 26 cut)',
            TYPE        => 'Parallel Port ECP/EPP',
            CAPTION     => 'Parallel'
        },
        {
            NAME        => 'J11',
            DESCRIPTION => 'Circular DIN-8 male',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'Keyboard'
        },
        {
            NAME        => 'J12',
            DESCRIPTION => 'Circular DIN-8 male',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2 Mouse'
        }
    ],
    'vmware-esx-2.5' => [
        {
            NAME        => 'J19',
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16650A Compatible',
            CAPTION     => 'DB-9 pin male'
        },
        {
            NAME        => 'J23',
            DESCRIPTION => '25 Pin Dual Inline (pin 26 cut)',
            TYPE        => 'Parallel Port ECP/EPP',
            CAPTION     => 'DB-25 pin female'
        },
        {
            NAME        => 'J11',
            DESCRIPTION => 'Keyboard',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'Circular DIN-8 male'
        },
        {
            NAME        => 'J12',
            DESCRIPTION => 'PS/2 Mouse',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'Circular DIN-8 male'
        }
    ],
    'windows' => [
        {
            NAME        => 'PARALLEL PORT',
            DESCRIPTION => 'DB-25 female',
            TYPE        => 'Parallel Port ECP',
            CAPTION     => 'PARALLEL PORT'
        },
        {
            NAME        => 'EXTERNAL MONITOR PORT',
            DESCRIPTION => 'DB-15 female',
            TYPE        => 'Other',
            CAPTION     => 'EXTERNAL MONITOR PORT'
        },
        {
            NAME        => 'BUILT-IN MODEM PORT',
            DESCRIPTION => 'RJ-11',
            TYPE        => 'Modem Port',
            CAPTION     => 'BUILT-IN MODEM PORT'
        },
        {
            NAME        => 'BUILT-IN LAN PORT',
            DESCRIPTION => 'RJ-45',
            TYPE        => 'Network Port',
            CAPTION     => 'BUILT-IN LAN PORT'
        },
        {
            NAME        => 'INFRARED PORT',
            DESCRIPTION => 'Infrared',
            TYPE        => 'Other',
            CAPTION     => 'INFRARED PORT'
        },
        {
            NAME        => 'USB PORT',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB PORT'
        },
        {
            NAME        => 'USB PORT',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB PORT'
        },
        {
            NAME        => 'USB PORT',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'USB PORT'
        },
        {
            NAME        => 'HEADPHONE JACK',
            DESCRIPTION => 'Mini Jack (headphones)',
            TYPE        => 'Other',
            CAPTION     => 'HEADPHONE JACK'
        },
        {
            NAME        => '1394 PORT',
            DESCRIPTION => 'IEEE 1394',
            TYPE        => 'Firewire (IEEE P1394)',
            CAPTION     => '1394 PORT'
        },
        {
            NAME        => 'MICROPHONE JACK',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => 'MICROPHONE JACK'
        },
        {
            NAME        => 'VIDEO-OUT JACK',
            DESCRIPTION => 'Other',
            TYPE        => 'Other',
            CAPTION     => 'VIDEO-OUT JACK'
        }
    ],
    'windows-hyperV' => [
        {
            NAME        => 'USB',
            DESCRIPTION => 'Centronics',
            TYPE        => 'USB',
            CAPTION     => 'USB1'
        },
        {
            NAME        => 'USB',
            DESCRIPTION => 'Centronics',
            TYPE        => 'USB',
            CAPTION     => 'USB2'
        },
        {
            NAME        => 'COM1',
            DESCRIPTION => 'DB-9 female',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'COM1'
        },
        {
            NAME        => 'COM2',
            DESCRIPTION => 'DB-9 female',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'COM2'
        },
        {
            NAME        => 'Printer',
            DESCRIPTION => 'DB-25 male',
            TYPE        => 'Parallel Port ECP/EPP',
            CAPTION     => 'Lpt1'
        },
        {
            NAME        => 'Video',
            DESCRIPTION => 'DB-15 male',
            TYPE        => 'Video Port',
            CAPTION     => 'Video'
        },
        {
            NAME        => 'Keyboard',
            DESCRIPTION => 'PS/2',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'Keyboard'
        },
        {
            NAME        => 'Mouse',
            DESCRIPTION => 'PS/2',
            TYPE        => 'Mouse Port',
            CAPTION     => 'Mouse'
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/generic/dmidecode/$test";
    my $ports = GLPI::Agent::Task::Inventory::Generic::Dmidecode::Ports::_getPorts(file => $file);
    cmp_deeply($ports, $tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'PORTS', entry => $_)
            foreach @$ports;
    } "$test: registering";
}
