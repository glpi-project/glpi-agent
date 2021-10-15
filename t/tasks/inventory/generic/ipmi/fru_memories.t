#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Generic::Dmidecode::Memory;
use GLPI::Agent::Task::Inventory::Generic::Ipmi::Fru::Memory;

my %tests = (
    'dell-r630' => [
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'A1',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 1,
            'SERIALNUMBER'     => '425BB5D0',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'A2',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 2,
            'SERIALNUMBER'     => '425BB5BC',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'A3',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 3,
            'SERIALNUMBER'     => '425BB618',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'A4',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 4,
            'SERIALNUMBER'     => '425BB619',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'A5',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 5,
            'SERIALNUMBER'     => '425BB644',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'A6',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 6,
            'SERIALNUMBER'     => '425BB643',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'A7',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 7,
            'SERIALNUMBER'     => '425BB561',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'A8',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 8,
            'SERIALNUMBER'     => '425BB566',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPTION'          => 'A9',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 9
        },
        {
            'CAPTION'          => 'A10',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 10
        },
        {
            'CAPTION'          => 'A11',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 11
        },
        {
            'CAPTION'          => 'A12',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 12
        },
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'B1',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 13,
            'SERIALNUMBER'     => '425BB5CF',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'B2',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 14,
            'SERIALNUMBER'     => '425BB5CE',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'B3',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 15,
            'SERIALNUMBER'     => '425BB5CD',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'B4',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 16,
            'SERIALNUMBER'     => '425BB5CC',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'B5',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 17,
            'SERIALNUMBER'     => '425BB64A',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'B6',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 18,
            'SERIALNUMBER'     => '425BB649',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'B7',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 19,
            'SERIALNUMBER'     => '425BB669',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => '4096',
            'CAPTION'          => 'B8',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 20,
            'SERIALNUMBER'     => '425BB5AE',
            'SPEED'            => '2400',
            'MODEL'            => 'HMA451R7AFR8N-UH',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPTION'          => 'B9',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 21
        },
        {
            'CAPTION'          => 'B10',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 22
        },
        {
            'CAPTION'          => 'B11',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 23
        },
        {
            'CAPTION'          => 'B12',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 24
        }
    ],
    'dell-r640' => [
        {
            'CAPACITY'         => 32768,
            'CAPTION'          => 'A1',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 1,
            'SERIALNUMBER'     => '3780385B',
            'SPEED'            => '2933',
            'MODEL'            => 'M393A4K40CB2-CVF',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => 32768,
            'CAPTION'          => 'A2',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 2,
            'SERIALNUMBER'     => '3780485D',
            'SPEED'            => '2933',
            'MODEL'            => 'M393A4K40CB2-CVF',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPTION'          => 'A3',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 3
        },
        {
            'CAPACITY'         => 32768,
            'CAPTION'          => 'A4',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 4,
            'SERIALNUMBER'     => '37803837',
            'SPEED'            => '2933',
            'MODEL'            => 'M393A4K40CB2-CVF',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => 32768,
            'CAPTION'          => 'A5',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 5,
            'SERIALNUMBER'     => '378037F8',
            'SPEED'            => '2933',
            'MODEL'            => 'M393A4K40CB2-CVF',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPTION'          => 'A6',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 6
        },
        {
            'CAPTION'          => 'A7',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 7
        },
        {
            'CAPTION'          => 'A8',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 8
        },
        {
            'CAPTION'          => 'A9',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 9
        },
        {
            'CAPTION'          => 'A10',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 10
        },
        {
            'CAPTION'          => 'A11',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 11
        },
        {
            'CAPTION'          => 'A12',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 12
        },
        {
            'CAPACITY'         => 32768,
            'CAPTION'          => 'B1',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 13,
            'SERIALNUMBER'     => '378037F2',
            'SPEED'            => '2933',
            'MODEL'            => 'M393A4K40CB2-CVF',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => 32768,
            'CAPTION'          => 'B2',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 14,
            'SERIALNUMBER'     => '3780063C',
            'SPEED'            => '2933',
            'MODEL'            => 'M393A4K40CB2-CVF',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPTION'          => 'B3',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 15
        },
        {
            'CAPACITY'         => 32768,
            'CAPTION'          => 'B4',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 16,
            'SERIALNUMBER'     => '37804A39',
            'SPEED'            => '2933',
            'MODEL'            => 'M393A4K40CB2-CVF',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => 32768,
            'CAPTION'          => 'B5',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 17,
            'SERIALNUMBER'     => '37800533',
            'SPEED'            => '2933',
            'MODEL'            => 'M393A4K40CB2-CVF',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPTION'          => 'B6',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 18
        },
        {
            'CAPTION'          => 'B7',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 19
        },
        {
            'CAPTION'          => 'B8',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 20
        },
        {
            'CAPTION'          => 'B9',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 21
        },
        {
            'CAPTION'          => 'B10',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 22
        },
        {
            'CAPTION'          => 'B11',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 23
        },
        {
            'CAPTION'          => 'B12',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 24
        }
    ],
    'dell-r720' => [
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'DIMM_A1',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 1,
            'SERIALNUMBER'     => '16B8328C',
            'SPEED'            => '1866',
            'MODEL'            => 'M393B1G73QH0-CMA',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'DIMM_A2',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 2,
            'SERIALNUMBER'     => '16B8325E',
            'SPEED'            => '1866',
            'MODEL'            => 'M393B1G73QH0-CMA',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'DIMM_A3',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 3,
            'SERIALNUMBER'     => '16B83620',
            'SPEED'            => '1866',
            'MODEL'            => 'M393B1G73QH0-CMA',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'DIMM_A4',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 4,
            'SERIALNUMBER'     => '16B835C8',
            'SPEED'            => '1866',
            'MODEL'            => 'M393B1G73QH0-CMA',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_A5',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 5,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_A6',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 6,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_A7',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 7,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_A8',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 8,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_A9',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 9,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_A10',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 10,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_A11',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 11,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_A12',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 12,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'DIMM_B1',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 13,
            'SERIALNUMBER'     => '16B86AC8',
            'SPEED'            => '1866',
            'MODEL'            => 'M393B1G73QH0-CMA',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'DIMM_B2',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 14,
            'SERIALNUMBER'     => '16B833DA',
            'SPEED'            => '1866',
            'MODEL'            => 'M393B1G73QH0-CMA',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'DIMM_B3',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 15,
            'SERIALNUMBER'     => '16B8328D',
            'SPEED'            => '1866',
            'MODEL'            => 'M393B1G73QH0-CMA',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'DIMM_B4',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 16,
            'SERIALNUMBER'     => '16B83B0E',
            'SPEED'            => '1866',
            'MODEL'            => 'M393B1G73QH0-CMA',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_B5',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 17,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_B6',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 18,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_B7',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 19,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_B8',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 20,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_B9',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 21,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_B10',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 22,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_B11',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 23,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'DIMM_B12',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 24,
            'TYPE'             => 'DDR3'
        }
    ],
    'hp-dl360-gen7' => [
        {
            'CAPTION'          => 'PROC 1 DIMM 1G',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 1,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 1 DIMM 2D',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Nanya Technology',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 2,
            'SERIALNUMBER'     => 'e9372e64',
            'SPEED'            => '1333',
            'MODEL'            => 'NT8GC72B4NB1NK-CG',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 1 DIMM 3A',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Nanya Technology',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 3,
            'SERIALNUMBER'     => '284a2e65',
            'SPEED'            => '1333',
            'MODEL'            => 'NT8GC72B4NB1NK-CG',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 4H',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 4,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 5E',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 5,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 1 DIMM 6B',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Nanya Technology',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 6,
            'SERIALNUMBER'     => '6a4a2e61',
            'SPEED'            => '1333',
            'MODEL'            => 'NT8GC72B4NB1NK-CG',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 7I',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 7,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 8F',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 8,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 1 DIMM 9C',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Nanya Technology',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 9,
            'SERIALNUMBER'     => 'cb372e64',
            'SPEED'            => '1333',
            'MODEL'            => 'NT8GC72B4NB1NK-CG',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 1G',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 10,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 2 DIMM 2D',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Nanya Technology',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 11,
            'SERIALNUMBER'     => '77512e69',
            'SPEED'            => '1333',
            'MODEL'            => 'NT8GC72B4NB1NK-CG',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 2 DIMM 3A',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Nanya Technology',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 12,
            'SERIALNUMBER'     => '253e2e63',
            'SPEED'            => '1333',
            'MODEL'            => 'NT8GC72B4NB1NK-CG',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 4H',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 13,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 5E',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 14,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 2 DIMM 6B',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Nanya Technology',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 15,
            'SERIALNUMBER'     => '5b462e69',
            'SPEED'            => '1333',
            'MODEL'            => 'NT8GC72B4NB1NK-CG',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 7I',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 16,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 8F',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 17,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 2 DIMM 9C',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Nanya Technology',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 18,
            'SERIALNUMBER'     => 'c54a2e66',
            'SPEED'            => '1333',
            'MODEL'            => 'NT8GC72B4NB1NK-CG',
            'TYPE'             => 'DDR3'
        }
    ],
    'hp-dl360-gen7_2' => [
        {
            'CAPTION'          => 'PROC 1 DIMM 1G',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 1,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '16384',
            'CAPTION'          => 'PROC 1 DIMM 2D',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 2,
            'SERIALNUMBER'     => '185e62c7',
            'SPEED'            => '1600',
            'MODEL'            => 'M393B2G70EB0-CMA',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '16384',
            'CAPTION'          => 'PROC 1 DIMM 3A',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 3,
            'SERIALNUMBER'     => '185e7605',
            'SPEED'            => '1600',
            'MODEL'            => 'M393B2G70EB0-CMA',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 4H',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 4,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 5E',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 5,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '16384',
            'CAPTION'          => 'PROC 1 DIMM 6B',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 6,
            'SERIALNUMBER'     => '185e782f',
            'SPEED'            => '1600',
            'MODEL'            => 'M393B2G70EB0-CMA',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 7I',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 7,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 8F',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 8,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '16384',
            'CAPTION'          => 'PROC 1 DIMM 9C',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 9,
            'SERIALNUMBER'     => '185ee93c',
            'SPEED'            => '1600',
            'MODEL'            => 'M393B2G70EB0-CMA',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 1G',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 10,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '16384',
            'CAPTION'          => 'PROC 2 DIMM 2D',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 11,
            'SERIALNUMBER'     => '185ee82f',
            'SPEED'            => '1600',
            'MODEL'            => 'M393B2G70EB0-CMA',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '16384',
            'CAPTION'          => 'PROC 2 DIMM 3A',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 12,
            'SERIALNUMBER'     => '185e5374',
            'SPEED'            => '1600',
            'MODEL'            => 'M393B2G70EB0-CMA',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 4H',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 13,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 5E',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 14,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '16384',
            'CAPTION'          => 'PROC 2 DIMM 6B',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 15,
            'SERIALNUMBER'     => '185e5c9d',
            'SPEED'            => '1600',
            'MODEL'            => 'M393B2G70EB0-CMA',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 7I',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 16,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 8F',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 17,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '16384',
            'CAPTION'          => 'PROC 2 DIMM 9C',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Samsung',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 18,
            'SERIALNUMBER'     => '185e3526',
            'SPEED'            => '1600',
            'MODEL'            => 'M393B2G70EB0-CMA',
            'TYPE'             => 'DDR3'
        }
    ],
    'hp-dl360-gen8' => [
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 1 DIMM 1',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'HP',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 1,
            'SPEED'            => '1333',
            'MODEL'            => '647650-071',
            'SERIALNUMBER'     => 'e08f54c1',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 2',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 2,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 3',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 3,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 1 DIMM 4',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'HP',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 4,
            'SPEED'            => '1333',
            'MODEL'            => '647650-071',
            'SERIALNUMBER'     => 'e08f54b3',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 5',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 5,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 6',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 6,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 7',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 7,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 8',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 8,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 1 DIMM 9',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'HP',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 9,
            'SPEED'            => '1333',
            'TYPE'             => 'DDR3',
            'MODEL'            => '647650-071',
            'SERIALNUMBER'     => 'db7b94dd',
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 10',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 10,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 11',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 11,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 1 DIMM 12',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'HP',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 12,
            'SPEED'            => '1333',
            'MODEL'            => '647650-071',
            'SERIALNUMBER'     => 'db7b94cf',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 2 DIMM 1',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'HP',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 13,
            'SPEED'            => '1333',
            'MODEL'            => '647650-071',
            'SERIALNUMBER'     => 'db7b9459',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 2',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 14,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 3',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 15,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 2 DIMM 4',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'HP',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 16,
            'SPEED'            => '1333',
            'MODEL'            => '647650-071',
            'SERIALNUMBER'     => 'db7b94ac',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 5',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 17,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 6',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 18,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 7',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 19,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 8',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 20,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 2 DIMM 9',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'HP',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 21,
            'SPEED'            => '1333',
            'MODEL'            => '647650-071',
            'SERIALNUMBER'     => 'db7b94a3',
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 10',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 22,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 11',
            'DESCRIPTION'      => 'DIMM',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 23,
            'TYPE'             => 'DDR3'
        },
        {
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 2 DIMM 12',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'HP',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 24,
            'SPEED'            => '1333',
            'MODEL'            => '647650-071',
            'SERIALNUMBER'     => 'db7b949f',
            'TYPE'             => 'DDR3'
        }
    ],
    'sun-x2200-m2' => [
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU0_DIMM0',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 1,
            'SERIALNUMBER'     => '04008093',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU0_DIMM1',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 2,
            'SERIALNUMBER'     => '04004090',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU0_DIMM2',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 3,
            'SERIALNUMBER'     => '00003097',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU0_DIMM3',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 4,
            'SERIALNUMBER'     => '00002120',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU0_DIMM4',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 5,
            'SERIALNUMBER'     => '00002124',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU0_DIMM5',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 6,
            'SERIALNUMBER'     => '04008121',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU0_DIMM6',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 7,
            'SERIALNUMBER'     => '00005086',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU0_DIMM7',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 8,
            'SERIALNUMBER'     => '00005005',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU1_DIMM0',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 9,
            'SERIALNUMBER'     => '04004004',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU1_DIMM1',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 10,
            'SERIALNUMBER'     => '04004122',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU1_DIMM2',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 11,
            'SERIALNUMBER'     => '00007090',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU1_DIMM3',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 12,
            'SERIALNUMBER'     => '00002009',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU1_DIMM4',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 13,
            'SERIALNUMBER'     => '00006009',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU1_DIMM5',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 14,
            'SERIALNUMBER'     => '00007010',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU1_DIMM6',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 15,
            'SERIALNUMBER'     => '00001067',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
        {
            'CAPACITY'         => '2048',
            'CAPTION'          => 'CPU1_DIMM7',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MODEL'            => 'HYMP525P72CP4-Y5',
            'NUMSLOTS'         => 16,
            'SERIALNUMBER'     => '04008004',
            'SPEED'            => '533',
            'TYPE'             => 'DDR2'
        },
    ]
);

plan tests => 2 * (scalar keys %tests) + 1;

foreach my $test (keys %tests) {
    my $dmidecode = "resources/generic/dmidecode/$test";
    my $fru = "resources/generic/ipmitool/fru/$test";
    my $inventory = GLPI::Test::Inventory->new();

    my $memories = GLPI::Agent::Task::Inventory::Generic::Dmidecode::Memory::_getMemories(file => $dmidecode);
    foreach my $memory (@$memories) {
        $inventory->addEntry(
            section => 'MEMORIES',
            entry   => $memory
        );
    }

    lives_ok {
        GLPI::Agent::Task::Inventory::Generic::Ipmi::Fru::Memory::doInventory(
            inventory => $inventory,
            file      => $fru
        );
    } "test $test: fru/memory doInventory()";

    my $mem = $inventory->getSection('MEMORIES') || [];

    # produce more sensible error if the test fails
    my %result = map { $_->{CAPTION} => $_ } @$mem;
    my %expected = map { $_->{CAPTION} => $_ } @{$tests{$test}};

    cmp_deeply(
        \%result,
        \%expected,
        "test $test: final"
    );
}
