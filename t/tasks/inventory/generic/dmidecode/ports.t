#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use FusionInventory::Test::Inventory;
use FusionInventory::Agent::Task::Inventory::Generic::Dmidecode::Ports;

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
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Other'
        }
    ],
    'freebsd-8.1' => undef,
    'linux-2.6' => [
         {
            NAME        => 'PARALLEL',
            DESCRIPTION => undef,
            TYPE        => 'Parallel Port PS/2',
            CAPTION     => 'DB-25 female'
        },
        {
            NAME        => 'SERIAL1',
            DESCRIPTION => undef,
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => 'USB',
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'MONITOR',
            DESCRIPTION => undef,
            TYPE        => 'Video Port',
            CAPTION     => 'DB-15 female'
        },
        {
            NAME        => 'IrDA',
            DESCRIPTION => undef,
            TYPE        => 'Other',
            CAPTION     => 'Infrared'
        },
        {
            NAME        => 'Modem',
            DESCRIPTION => undef,
            TYPE        => 'Modem Port',
            CAPTION     => 'RJ-11'
        },
        {
            NAME        => 'Ethernet',
            DESCRIPTION => undef,
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
            DESCRIPTION => undef,
            TYPE        => 'Video Port',
            CAPTION     => 'DB-15 female'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Parallel Port PS/2',
            CAPTION     => 'DB-25 female'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Mouse Port',
            CAPTION     => 'PS/2'
        }
    ],
    'rhel-2.1' => [
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Serial Port 16650A Compatible',
            CAPTION     => 'DB-9 pin male'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Serial Port 16650A Compatible',
            CAPTION     => 'DB-9 pin male'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Parallel Port ECP/EPP',
            CAPTION     => 'DB-25 pin female'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Mouse Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => undef,
            DESCRIPTION => 'On Board IDE',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => undef,
            DESCRIPTION => 'On Board Floppy',
            TYPE        => 'Other',
            CAPTION     => undef
        },
        {
            NAME        => undef,
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
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => 'J2A2',
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => 'J3A1',
            DESCRIPTION => '25 Pin Dual Inline (pin 26 cut)',
            TYPE        => 'Parallel Port ECP/EPP',
            CAPTION     => 'DB-25 female'
        },
        {
            NAME        => 'J1A1',
            DESCRIPTION => undef,
            TYPE        => 'Keyboard Port',
            CAPTION     => 'Circular DIN-8 male'
        },
        {
            NAME        => 'J1A1',
            DESCRIPTION => undef,
            TYPE        => 'Keyboard Port',
            CAPTION     => 'Circular DIN-8 male'
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
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Other'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Other'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Audio Port',
            CAPTION     => undef
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'SCSI Wide',
            CAPTION     => undef
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'SCSI Wide',
            CAPTION     => undef
        }
    ],
    'rhel-4.6' => [
        {
            NAME        => 'J16',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'J19',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'J69',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'J69',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'J02',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'J03',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        }
    ],
    'hp-dl180' => [
        {
            NAME        => 'J1',
            DESCRIPTION => undef,
            TYPE        => 'Video Port',
            CAPTION     => 'DB-15 female'
        },
        {
            NAME        => 'J2',
            DESCRIPTION => undef,
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => 'J3',
            DESCRIPTION => undef,
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45'
        },
        {
            NAME        => 'J3',
            DESCRIPTION => undef,
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45'
        },
        {
            NAME        => 'J53',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'J53',
            DESCRIPTION => 'Access Bus (USB)',
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'J12',
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'J12',
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
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
            DESCRIPTION => undef,
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => 'USB12',
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'USB34',
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'USB56',
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'USB78',
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'USB910',
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'USB1112',
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'GbE LAN',
            DESCRIPTION => undef,
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45'
        },
        {
            NAME        => 'COM 1',
            DESCRIPTION => undef,
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => 'Audio Line Out1',
            DESCRIPTION => undef,
            TYPE        => 'Audio Port',
            CAPTION     => 'Mini Jack (headphones)'
        },
        {
            NAME        => 'Audio Line Out2',
            DESCRIPTION => undef,
            TYPE        => 'Audio Port',
            CAPTION     => 'Mini Jack (headphones)'
        },
        {
            NAME        => 'Audio Line Out3',
            DESCRIPTION => undef,
            TYPE        => 'Audio Port',
            CAPTION     => 'Mini Jack (headphones)'
        },
        {
            NAME        => 'Audio Line Out4',
            DESCRIPTION => undef,
            TYPE        => 'Audio Port',
            CAPTION     => 'Mini Jack (headphones)'
        },
        {
            NAME        => 'Audio Line Out5',
            DESCRIPTION => undef,
            TYPE        => 'Audio Port',
            CAPTION     => 'Mini Jack (headphones)'
        },
        {
            NAME        => 'Audio Line Out6',
            DESCRIPTION => undef,
            TYPE        => 'Audio Port',
            CAPTION     => 'Mini Jack (headphones)'
        },
        {
            NAME        => 'SPDIF_OUT',
            DESCRIPTION => undef,
            TYPE        => 'Audio Port',
            CAPTION     => 'On Board Sound Input From CD-ROM'
        },
        {
            NAME        => 'IE1394_1',
            DESCRIPTION => undef,
            TYPE        => 'Firewire (IEEE P1394)',
            CAPTION     => 'IEEE 1394'
        },
        {
            NAME        => 'IE1394_2',
            DESCRIPTION => undef,
            TYPE        => 'Firewire (IEEE P1394)',
            CAPTION     => 'IEEE 1394'
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
        }
    ],
    'openbsd-4.5' => [
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Parallel Port PS/2',
            CAPTION     => 'DB-25 female'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Mouse Port',
            CAPTION     => 'Mini DIN'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
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
            'CAPTION' => 'Access Bus (USB)',
            'NAME' => 'J2803',
            'TYPE' => 'USB',
            'DESCRIPTION' => undef
        },
        {
            'CAPTION' => 'Access Bus (USB)',
            'NAME' => 'J2803',
            'TYPE' => 'USB',
            'DESCRIPTION' => undef
        },
        {
            'CAPTION' => 'DB-15 female',
            'NAME' => 'J2901',
            'DESCRIPTION' => undef,
            'TYPE' => 'Video Port'
        },
        {
            'TYPE' => 'USB',
            'DESCRIPTION' => undef,
            'NAME' => 'J2801',
            'CAPTION' => 'Access Bus (USB)'
        },
        {
            'NAME' => 'J2802',
            'DESCRIPTION' => undef,
            'TYPE' => 'USB',
            'CAPTION' => 'Access Bus (USB)'
        },
        {
            'CAPTION' => 'Access Bus (USB)',
            'NAME' => undef,
            'DESCRIPTION' => undef,
            'TYPE' => 'USB'
        },
        {
            'NAME' => undef,
            'DESCRIPTION' => undef,
            'TYPE' => 'USB',
            'CAPTION' => 'Access Bus (USB)'
        },
        {
            'NAME' => 'J2903',
            'DESCRIPTION' => undef,
            'TYPE' => 'Serial Port 16550 Compatible',
            'CAPTION' => 'RJ-45'
        },
        {
            'CAPTION' => 'RJ-45',
            'NAME' => 'J2902',
            'DESCRIPTION' => undef,
            'TYPE' => 'Network Port'
        },
        {
            'CAPTION' => 'RJ-45',
            'NAME' => 'J3502',
            'DESCRIPTION' => undef,
            'TYPE' => 'Network Port'
        },
        {
            'TYPE' => 'Network Port',
            'DESCRIPTION' => undef,
            'NAME' => 'J3501',
            'CAPTION' => 'RJ-45'
        },
        {
            'NAME' => 'J3802',
            'TYPE' => 'Network Port',
            'DESCRIPTION' => undef,
            'CAPTION' => 'RJ-45'
        },
        {
            'DESCRIPTION' => undef,
            'TYPE' => 'Network Port',
            'NAME' => 'J3801',
            'CAPTION' => 'RJ-45'
        },
        {
            'CAPTION' => 'SAS/SATA Plug Receptacle',
            'TYPE' => 'SATA',
            'DESCRIPTION' => undef,
            'NAME' => 'J2003'
        }
    ],
    'S3000AHLX' => [
        {
            NAME        => 'J9A1',
            DESCRIPTION => undef,
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => 'J9A1',
            DESCRIPTION => undef,
            TYPE        => 'Mouse Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => 'J8A1',
            DESCRIPTION => 'Other',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => undef
        },
        {
            NAME        => 'JA5A1',
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'JA5A1',
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'J1F2',
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'J1F2',
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => 'JA5A1',
            DESCRIPTION => undef,
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45'
        },
        {
            NAME        => 'JA6A1',
            DESCRIPTION => undef,
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45'
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
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Mouse Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => 'J1B1 - SERIAL B (EMP)',
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => undef
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Video Port',
            CAPTION     => 'DB-15 female'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
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
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45'
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
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => 'J23',
            DESCRIPTION => '25 Pin Dual Inline (pin 26 cut)',
            TYPE        => 'Parallel Port ECP/EPP',
            CAPTION     => 'DB-25 female'
        },
        {
            NAME        => 'J11',
            DESCRIPTION => undef,
            TYPE        => 'Keyboard Port',
            CAPTION     => 'Circular DIN-8 male'
        },
        {
            NAME        => 'J12',
            DESCRIPTION => undef,
            TYPE        => 'Keyboard Port',
            CAPTION     => 'Circular DIN-8 male'
        }
    ],
    'vmware-esx' => [
        {
            NAME        => 'J19',
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'DB-9 male'
        },
        {
            NAME        => 'J23',
            DESCRIPTION => '25 Pin Dual Inline (pin 26 cut)',
            TYPE        => 'Parallel Port ECP/EPP',
            CAPTION     => 'DB-25 female'
        },
        {
            NAME        => 'J11',
            DESCRIPTION => undef,
            TYPE        => 'Keyboard Port',
            CAPTION     => 'Circular DIN-8 male'
        },
        {
            NAME        => 'J12',
            DESCRIPTION => undef,
            TYPE        => 'Keyboard Port',
            CAPTION     => 'Circular DIN-8 male'
        }
    ],
    'vmware-esx-2.5' => [
        {
            NAME        => undef,
            DESCRIPTION => '9 Pin Dual Inline (pin 10 cut)',
            TYPE        => 'Serial Port 16650A Compatible',
            CAPTION     => 'DB-9 pin male'
        },
        {
            NAME        => undef,
            DESCRIPTION => '25 Pin Dual Inline (pin 26 cut)',
            TYPE        => 'Parallel Port ECP/EPP',
            CAPTION     => 'DB-25 pin female'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Keyboard Port',
            CAPTION     => 'Circular DIN-8 male'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Keyboard Port',
            CAPTION     => 'Circular DIN-8 male'
        }
    ],
    'windows' => [
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Parallel Port ECP',
            CAPTION     => 'DB-25 female'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Other',
            CAPTION     => 'DB-15 female'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Modem Port',
            CAPTION     => 'RJ-11'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Network Port',
            CAPTION     => 'RJ-45'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Other',
            CAPTION     => 'Infrared'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'USB',
            CAPTION     => 'Access Bus (USB)'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Other',
            CAPTION     => 'Mini Jack (headphones)'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Firewire (IEEE P1394)',
            CAPTION     => 'IEEE 1394'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Other',
            CAPTION     => 'Other'
        },
        {
            NAME        => undef,
            DESCRIPTION => undef,
            TYPE        => 'Other',
            CAPTION     => 'Other'
        }
    ],
    'windows-hyperV' => [
        {
            NAME        => 'USB',
            DESCRIPTION => 'Centronics',
            TYPE        => 'USB',
            CAPTION     => 'Centronics'
        },
        {
            NAME        => 'USB',
            DESCRIPTION => 'Centronics',
            TYPE        => 'USB',
            CAPTION     => 'Centronics'
        },
        {
            NAME        => 'COM1',
            DESCRIPTION => 'DB-9 female',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'DB-9 female'
        },
        {
            NAME        => 'COM2',
            DESCRIPTION => 'DB-9 female',
            TYPE        => 'Serial Port 16550A Compatible',
            CAPTION     => 'DB-9 female'
        },
        {
            NAME        => 'Printer',
            DESCRIPTION => 'DB-25 male',
            TYPE        => 'Parallel Port ECP/EPP',
            CAPTION     => 'DB-25 male'
        },
        {
            NAME        => 'Video',
            DESCRIPTION => 'DB-15 male',
            TYPE        => 'Video Port',
            CAPTION     => 'DB-15 female'
        },
        {
            NAME        => 'Keyboard',
            DESCRIPTION => 'PS/2',
            TYPE        => 'Keyboard Port',
            CAPTION     => 'PS/2'
        },
        {
            NAME        => 'Mouse',
            DESCRIPTION => 'PS/2',
            TYPE        => 'Mouse Port',
            CAPTION     => 'PS/2'
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = FusionInventory::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/generic/dmidecode/$test";
    my $ports = FusionInventory::Agent::Task::Inventory::Generic::Dmidecode::Ports::_getPorts(file => $file);
    cmp_deeply($ports, $tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'PORTS', entry => $_)
            foreach @$ports;
    } "$test: registering";
}
