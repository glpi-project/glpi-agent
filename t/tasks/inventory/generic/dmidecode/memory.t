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

my %tests = (
    'freebsd-6.2' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            SPEED            => undef,
            TYPE             => undef,
            CAPTION          => 'A0',
            CAPACITY         => '512',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef

        }
    ],
    'freebsd-8.1' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => '1A1541FC',
            DESCRIPTION      => 'SODIMM',
            TYPE             => 'DDR3',
            SPEED            => '1067',
            CAPACITY         => '2048',
            CAPTION          => 'Bottom - Slot 1',
            MANUFACTURER     => 'Hynix',
            MODEL            => 'HMT125S6BFR8C-H9',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => '1A554239',
            DESCRIPTION      => 'SODIMM',
            TYPE             => 'DDR3',
            SPEED            => '1067',
            CAPACITY         => '2048',
            CAPTION          => 'Bottom - Slot 2',
            MANUFACTURER     => 'Hynix',
            MODEL            => 'HMT125S6BFR8C-H9',
            MEMORYCORRECTION => undef

        }
    ],
    'linux-1' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => 'SerNum00',
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '1066',
            CAPACITY         => '1024',
            CAPTION          => 'DIMM0',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => 'SerNum01',
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '1066',
            CAPACITY         => '1024',
            CAPTION          => 'DIMM1',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef

        },
        {
            NUMSLOTS         => 3,
            SERIALNUMBER     => 'SerNum02',
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '1066',
            CAPACITY         => '1024',
            CAPTION          => 'DIMM2',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef

        },
        {
            NUMSLOTS         => 4,
            SERIALNUMBER     => 'SerNum03',
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '1066',
            CAPACITY         => '1024',
            CAPTION          => 'DIMM3',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef

        }
    ],
    'linux-2.6' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => '02132010',
            DESCRIPTION      => 'DIMM',
            SPEED            => '533',
            TYPE             => 'DDR',
            CAPTION          => 'DIMM_A',
            CAPACITY         => '1024',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => '02132216',
            DESCRIPTION      => 'DIMM',
            SPEED            => '533',
            TYPE             => 'DDR',
            CAPTION          => 'DIMM_B',
            CAPACITY         => '1024',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        }
    ],
    'openbsd-3.7' => [
        {
            NUMSLOTS         => 1,
            TYPE             => undef,
        },
        {
            NUMSLOTS         => 2,
            TYPE             => 'DIMM SDRAM',
            CAPACITY         => '64'
        },
        {
            NUMSLOTS         => 3,
            TYPE             => undef,
        },
        {
            NUMSLOTS         => 4,
            TYPE             => 'DIMM SDRAM',
            CAPACITY         => '64'
        },
        {
            NUMSLOTS         => 5,
            TYPE             => 'DIMM SDRAM',
            CAPACITY         => '64'
        },
        {
            NUMSLOTS         => 6,
            TYPE             => undef,
        },
        {
            NUMSLOTS         => 7,
            TYPE             => undef,
        }
    ],
    'openbsd-3.8' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => '50075483',
            DESCRIPTION      => 'DIMM',
            SPEED            => '400',
            TYPE             => undef,
            CAPTION          => 'DIMM1_A',
            CAPACITY         => '512',
            MANUFACTURER     => undef,
            MODEL            => 'M3 93T6450FZ0-CCC',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => '500355A1',
            DESCRIPTION      => 'DIMM',
            SPEED            => '400',
            TYPE             => undef,
            CAPTION          => 'DIMM1_B',
            CAPACITY         => '512',
            MANUFACTURER     => undef,
            MODEL            => 'M3 93T6450FZ0-CCC',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 3,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            SPEED            => '400',
            TYPE             => undef,
            CAPTION          => 'DIMM2_A',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 4,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            SPEED            => '400',
            TYPE             => undef,
            CAPTION          => 'DIMM2_B',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'

        },
        {
            NUMSLOTS         => 5,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            SPEED            => '400',
            TYPE             => undef,
            CAPTION          => 'DIMM3_A',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 6,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            SPEED            => '400',
            TYPE             => undef,
            CAPTION          => 'DIMM3_B',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        }
    ],
    'openbsd-4.5' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR',
            SPEED            => '266',
            CAPACITY         => '512',
            CAPTION          => 'DIMM A',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'

        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR',
            SPEED            => '266',
            CAPTION          => 'DIMM B',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'

        },
        {
            NUMSLOTS         => 3,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR',
            SPEED            => '266',
            CAPTION          => 'DIMM C',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'

        },
        {
            NUMSLOTS         => 4,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR',
            SPEED            => '266',
            CAPTION          => 'DIMM D',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'

        }
    ],
    'oracle-server-x5-2' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => '330DC586',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D11',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => '32A3A4FD',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D10',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 3,
            SERIALNUMBER     => 'NO DIMM',
            DESCRIPTION      => 'DIMM',
            SPEED            => undef,
            TYPE             => 'DDR4',
            CAPTION          => 'D9',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 4,
            SERIALNUMBER     => '330DC585',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D8',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 5,
            SERIALNUMBER     => '32A3A500',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D7',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 6,
            SERIALNUMBER     => 'NO DIMM',
            DESCRIPTION      => 'DIMM',
            SPEED            => undef,
            TYPE             => 'DDR4',
            CAPTION          => 'D6',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 7,
            SERIALNUMBER     => '330DC584',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D0',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 8,
            SERIALNUMBER     => '32A3A4BD',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D1',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 9,
            SERIALNUMBER     => 'NO DIMM',
            DESCRIPTION      => 'DIMM',
            SPEED            => undef,
            TYPE             => 'DDR4',
            CAPTION          => 'D2',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 10,
            SERIALNUMBER     => '330DC588',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D3',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 11,
            SERIALNUMBER     => '32A3A50E',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D4',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 12,
            SERIALNUMBER     => 'NO DIMM',
            DESCRIPTION      => 'DIMM',
            SPEED            => undef,
            TYPE             => 'DDR4',
            CAPTION          => 'D5',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 13,
            SERIALNUMBER     => '330DC582',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D11',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 14,
            SERIALNUMBER     => '32A3A4CE',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D10',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 15,
            SERIALNUMBER     => 'NO DIMM',
            DESCRIPTION      => 'DIMM',
            SPEED            => undef,
            TYPE             => 'DDR4',
            CAPTION          => 'D9',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 16,
            SERIALNUMBER     => '330DCB4F',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D8',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 17,
            SERIALNUMBER     => '32A3A4FC',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D7',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 18,
            SERIALNUMBER     => 'NO DIMM',
            DESCRIPTION      => 'DIMM',
            SPEED            => undef,
            TYPE             => 'DDR4',
            CAPTION          => 'D6',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 19,
            SERIALNUMBER     => '330DC543',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D0',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 20,
            SERIALNUMBER     => '32A3A4CC',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D1',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 21,
            SERIALNUMBER     => 'NO DIMM',
            DESCRIPTION      => 'DIMM',
            SPEED            => undef,
            TYPE             => 'DDR4',
            CAPTION          => 'D2',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 22,
            SERIALNUMBER     => '330DC52C',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D3',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 23,
            SERIALNUMBER     => '32A3A50D',
            DESCRIPTION      => 'DIMM',
            SPEED            => '2133',
            TYPE             => 'DDR4',
            CAPTION          => 'D4',
            CAPACITY         => '32768',
            MANUFACTURER     => 'Samsung',
            MODEL            => 'M386A4G40DM0-CPB',
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 24,
            SERIALNUMBER     => 'NO DIMM',
            DESCRIPTION      => 'DIMM',
            SPEED            => undef,
            TYPE             => 'DDR4',
            CAPTION          => 'D5',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        }
    ],
    'rhel-2.1' => [
        {
            NUMSLOTS         => 1,
            TYPE             => 'ECC DIMM SDRAM',
            CAPACITY         => '256'
        },
        {
            NUMSLOTS         => 2,
            TYPE             => undef
        }
    ],
    'rhel-3.4' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => '460360BB',
            DESCRIPTION      => 'DIMM',
            SPEED            => '400',
            TYPE             => 'DDR',
            CAPTION          => 'DIMM 1',
            CAPACITY         => '512',
            MANUFACTURER     => undef,
            MODEL            => 'M3 93T6553BZ3-CCC',
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => '460360E8',
            DESCRIPTION      => 'DIMM',
            SPEED            => '400',
            TYPE             => 'DDR',
            CAPTION          => 'DIMM 2',
            CAPACITY         => '512',
            MANUFACTURER     => undef,
            MODEL            => 'M3 93T6553BZ3-CCC',
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 3,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            SPEED            => '400',
            TYPE             => 'DDR',
            CAPTION          => 'DIMM 3',
            CAPACITY         => '512',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        }
    ],
    'rhel-4.3' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            SPEED            => undef,
            TYPE             => 'DDR',
            CAPTION          => 'DIMM1',
            CAPACITY         => '512',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            SPEED            => undef,
            TYPE             => 'DDR',
            CAPTION          => 'DIMM2',
            CAPACITY         => '512',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 3,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            SPEED            => undef,
            TYPE             => 'DDR',
            CAPTION          => 'DIMM3',
            CAPACITY         => '512',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 4,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            SPEED            => undef,
            TYPE             => 'DDR',
            CAPTION          => 'DIMM4',
            CAPACITY         => '512',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        }
    ],
    'rhel-4.6' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            SPEED            => '667',
            TYPE             => undef,
            CAPTION          => 'DIMM 1A',
            CAPACITY         => '512',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'

        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            SPEED            => '667',
            TYPE             => undef,
            CAPTION          => 'DIMM 2B',
            CAPACITY         => '1024',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 3,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            SPEED            => '667',
            TYPE             => undef,
            CAPTION          => 'DIMM 3C',
            CAPACITY         => '1024',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 4,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            SPEED            => undef,
            TYPE             => undef,
            CAPTION          => 'DIMM 4D',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 5,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            SPEED            => '667',
            TYPE             => undef,
            CAPTION          => 'DIMM 5A',
            CAPACITY         => '512',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 6,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            SPEED            => '667',
            TYPE             => undef,
            CAPTION          => 'DIMM 6B',
            CAPACITY         => '1024',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 7,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            SPEED            => '667',
            TYPE             => undef,
            CAPTION          => 'DIMM 7C',
            CAPACITY         => '1024',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 8,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            SPEED            => undef,
            TYPE             => undef,
            CAPTION          => 'DIMM 8D',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        }
    ],
    'hp-dl180' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => '94D657D7',
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => '1333',
            CAPACITY         => '2048',
            CAPTION          => 'PROC 1 DIMM 2A',
            MANUFACTURER     => 'Micron',
            MODEL            => '18JSF25672AZ-1G4F1',
            MEMORYCORRECTION => 'Single-bit ECC',
            TYPE             => 'DDR3',
        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => 'SerNum01',
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => undef,
            CAPTION          => 'PROC 1 DIMM 1D',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 3,
            SERIALNUMBER     => '93D657D7',
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => '1333',
            CAPACITY         => '2048',
            CAPTION          => 'PROC 1 DIMM 4B',
            MANUFACTURER     => 'Micron',
            MODEL            => '18JSF25672AZ-1G4F1',
            MEMORYCORRECTION => 'Single-bit ECC',
            TYPE             => 'DDR3',
        },
        {
            NUMSLOTS         => 4,
            SERIALNUMBER     => 'SerNum03',
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => undef,
            CAPTION          => 'PROC 1 DIMM 3E',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 5,
            SERIALNUMBER     => 'SerNum04',
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => undef,
            CAPTION          => 'PROC 1 DIMM 6C',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 6,
            SERIALNUMBER     => 'SerNum05',
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => undef,
            CAPTION          => 'PROC 1 DIMM 5F',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 7,
            SERIALNUMBER     => 'SerNum06',
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => undef,
            CAPTION          => 'PROC 2 DIMM 2A',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 8,
            SERIALNUMBER     => 'SerNum07',
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => undef,
            CAPTION          => 'PROC 2 DIMM 1D',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 9,
            SERIALNUMBER     => 'SerNum08',
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => undef,
            CAPTION          => 'PROC 2 DIMM 4B',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 10,
            SERIALNUMBER     => 'SerNum09',
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => undef,
            CAPTION          => 'PROC 2 DIMM 3E',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 11,
            SERIALNUMBER     => 'SerNum10',
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => undef,
            CAPTION          => 'PROC 2 DIMM 6C',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        },
        {
            NUMSLOTS         => 12,
            SERIALNUMBER     => 'SerNum11',
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => undef,
            CAPTION          => 'PROC 2 DIMM 5F',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Single-bit ECC'
        }
    ],
    'S3000AHLX' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => '0x750174F7',
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '533',
            CAPACITY         => '1024',
            CAPTION          => 'J8J1',
            MANUFACTURER     => undef,
            MODEL            => 'M3 78T2953EZ3-CE6',
            MEMORYCORRECTION => undef

        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => '0x9DCCE4ED',
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '533',
            CAPACITY         => '2048',
            CAPTION          => 'J8J2',
            MANUFACTURER     => undef,
            MODEL            => 'K',
            MEMORYCORRECTION => undef

        },
        {
            NUMSLOTS         => 3,
            SERIALNUMBER     => '0x750174FF',
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '533',
            CAPACITY         => '1024',
            CAPTION          => 'J9J1',
            MANUFACTURER     => undef,
            MODEL            => 'M3 78T2953EZ3-CE6',
            MEMORYCORRECTION => undef

        },
        {
            NUMSLOTS         => 4,
            SERIALNUMBER     => 'NO DIMM',
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => undef,
            CAPTION          => 'J9J2',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef

        }
    ],
    'S5000VSA' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '667',
            CAPACITY         => '1024',
            CAPTION          => 'ONBOARD DIMM_A1',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '667',
            CAPACITY         => '1024',
            CAPTION          => 'ONBOARD DIMM_A2',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 3,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '667',
            CAPACITY         => '1024',
            CAPTION          => 'ONBOARD DIMM_A3',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 4,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '667',
            CAPACITY         => '1024',
            CAPTION          => 'ONBOARD DIMM_A4',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 5,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '667',
            CAPACITY         => '1024',
            CAPTION          => 'ONBOARD DIMM_B1',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 6,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '667',
            CAPACITY         => '1024',
            CAPTION          => 'ONBOARD DIMM_B2',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 7,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '667',
            CAPACITY         => '1024',
            CAPTION          => 'ONBOARD DIMM_B3',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        },
        {
            NUMSLOTS         => 8,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '667',
            CAPACITY         => '1024',
            CAPTION          => 'ONBOARD DIMM_B4',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => 'Multi-bit ECC'
        }
    ],
    'vmware' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPACITY         => '2048',
            CAPTION          => 'RAM slot #0',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef

        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #1',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef

        },
        {
            NUMSLOTS         => 3,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #2',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef

        },
        {
            NUMSLOTS         => 4,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #3',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef

        }
    ],
    'vmware-esx' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPACITY         => '2048',
            CAPTION          => 'RAM slot #0',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #1',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 3,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #2',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 4,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #3',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 5,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #4',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 6,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #5',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 7,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #6',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 8,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #7',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 9,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #8',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 10,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #9',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 11,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #10',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 12,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #11',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 13,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #12',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 14,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #13',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 15,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DRAM',
            SPEED            => undef,
            CAPTION          => 'RAM slot #14',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        }
    ],
    'vmware-esx-2.5' => [
        {
            NUMSLOTS         => 1,
            TYPE             => 'EDO DIMM',
            CAPACITY         => '1024',
        },
        {
            NUMSLOTS         => 2,
            TYPE             => 'DIMM'
        },
        {
            NUMSLOTS         => 3,
            TYPE             => 'DIMM'
        },
        {
            NUMSLOTS         => 4,
            TYPE             => 'DIMM'
        },
        {
            NUMSLOTS         => 5,
            TYPE             => 'DIMM'
        },
        {
            NUMSLOTS         => 6,
            TYPE             => 'DIMM'
        },
        {
            NUMSLOTS         => 7,
            TYPE             => 'DIMM'
        },
        {
            NUMSLOTS         => 8,
            TYPE             => 'DIMM'
        },
        {
            NUMSLOTS         => 9,
            TYPE             => 'DIMM'
        },
        {
            NUMSLOTS         => 10,
            TYPE             => 'DIMM'
        },
        {
            NUMSLOTS         => 11,
            TYPE             => 'DIMM'
        },
        {
            NUMSLOTS         => 12,
            TYPE             => 'DIMM'
        },
        {
            NUMSLOTS         => 13,
            TYPE             => 'DIMM'
        },
        {
            NUMSLOTS         => 14,
            TYPE             => 'DIMM'
        },
        {
            NUMSLOTS         => 15,
            TYPE             => 'DIMM'
        }
    ],
    'windows' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'SODIMM',
            SPEED            => undef,
            TYPE             => 'SDRAM',
            CAPTION          => 'DIMM 0',
            CAPACITY         => '256',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'SODIMM',
            SPEED            => undef,
            TYPE             => 'SDRAM',
            CAPTION          => 'DIMM 1',
            CAPACITY         => '512',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        }
    ],
    'windows-xp' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => '14FA6621',
            TYPE             => 'DDR2',
            SPEED            => '800',
            CAPTION          => 'DIMM_A',
            MEMORYCORRECTION => undef,
            DESCRIPTION      => 'DIMM',
            MANUFACTURER     => 'Elpida',
            MODEL            => 'EBE21UE8ACUA-8G-E',
            CAPACITY         => '2048'
        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => 'AEF96621',
            TYPE             => 'DDR2',
            SPEED            => '800',
            CAPTION          => 'DIMM_B',
            MEMORYCORRECTION => undef,
            DESCRIPTION      => 'DIMM',
            MANUFACTURER     => 'Elpida',
            MODEL            => 'EBE21UE8ACUA-8G-E',
            CAPACITY         => '2048'
        }
    ],
    'windows-7' => [
        {
            NUMSLOTS         => 1,
            MEMORYCORRECTION => undef,
            SERIALNUMBER     => 'SerNum0',
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => undef,
            MANUFACTURER     => undef,
            CAPTION          => 'DIMM0'
        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => '0000000',
            TYPE             => undef,
            SPEED            => '1600',
            CAPTION          => 'DIMM1',
            MEMORYCORRECTION => undef,
            DESCRIPTION      => 'DIMM',
            MANUFACTURER     => undef,
            MODEL            => 'F3-12800CL9-2GBXL',
            CAPACITY         => '2048'
        },
        {
            NUMSLOTS         => 3,
            MEMORYCORRECTION => undef,
            SERIALNUMBER     => 'SerNum2',
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => undef,
            MANUFACTURER     => undef,
            CAPTION          => 'DIMM2'
        },
        {
            NUMSLOTS         => 4,
            SERIALNUMBER     => '0000000',
            TYPE             => undef,
            SPEED            => '1600',
            CAPTION          => 'DIMM3',
            MEMORYCORRECTION => undef,
            DESCRIPTION      => 'DIMM',
            MANUFACTURER     => undef,
            MODEL            => 'F3-12800CL9-2GBXL',
            CAPACITY         => '2048'
        }
    ],
    'dell-fx160' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => '3B085E1E',
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => '800',
            CAPACITY         => '1024',
            CAPTION          => 'DIMM_1',
            MANUFACTURER     => 'Nanya',
            MODEL            => 'NT1GT64U88D0BY-AD',
            MEMORYCORRECTION => undef
        },{
            NUMSLOTS         => 2,
            SERIALNUMBER     => 'SerNum01',
            DESCRIPTION      => 'Other',
            TYPE             => undef,
            SPEED            => undef,
            CAPTION          => 'DIMM_2',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        }
    ],
    'dell-fx170' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => 'DDR2',
            SPEED            => undef,
            CAPACITY         => '2048',
            CAPTION          => 'A0',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },{
            NUMSLOTS         => 2,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => undef,
            CAPTION          => 'A1',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },{
            NUMSLOTS         => 3,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => undef,
            CAPTION          => 'A2',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        },{
            NUMSLOTS         => 4,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'DIMM',
            TYPE             => undef,
            SPEED            => undef,
            CAPTION          => 'A3',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef
        }
    ],
    'windows-hyperV' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPACITY         => '1024',
            CAPTION          => 'M0',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M1',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 3,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M2',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 4,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M3',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 5,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M4',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 6,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M5',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 7,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M6',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 8,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M7',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 9,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M8',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 10,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M9',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 11,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M10',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 12,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M11',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 13,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M12',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 14,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M13',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 15,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M14',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 16,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M15',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 17,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M16',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 18,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M17',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 19,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M18',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 20,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M19',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 21,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M20',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 22,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M21',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 23,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M22',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 24,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M23',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 25,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M24',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 26,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M25',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 27,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M26',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 28,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M27',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 29,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M28',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 30,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M29',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 31,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M30',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 32,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M31',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 33,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M32',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 34,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M33',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 35,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M34',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 36,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M35',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 37,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M36',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 38,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M37',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 39,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M38',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 40,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M39',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 41,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M40',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 42,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M41',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 43,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M42',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 44,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M43',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 45,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M44',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 46,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M45',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 47,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M46',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 48,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M47',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 49,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M48',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 50,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M49',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 51,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M50',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 52,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M51',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 53,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M52',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 54,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M53',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 55,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M54',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 56,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M55',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 57,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M56',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 58,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M57',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 59,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M58',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 60,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M59',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 61,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M60',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 62,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M61',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 63,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M62',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 64,
            SERIALNUMBER     => undef,
            DESCRIPTION      => undef,
            TYPE             => 'Other',
            SPEED            => undef,
            CAPTION          => 'M63',
            MANUFACTURER     => 'Microsoft',
            MEMORYCORRECTION => undef
        }
    ],
    'windows-hyperV-2019' => [
        {
            NUMSLOTS         => 1,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'Hyper-V Memory',
            TYPE             => undef,
            SPEED            => undef,
            CAPACITY         => '3968',
            CAPTION          => 'M0001',
            MANUFACTURER     => 'Microsoft Corporation',
            MEMORYCORRECTION => undef
        },
        {
            NUMSLOTS         => 2,
            SERIALNUMBER     => undef,
            DESCRIPTION      => 'Hyper-V Memory',
            TYPE             => undef,
            SPEED            => undef,
            CAPACITY         => '128',
            CAPTION          => 'M0002',
            MANUFACTURER     => 'Microsoft Corporation',
            MEMORYCORRECTION => undef
        }
    ],
    'dell-r620' => [
        {
            'MANUFACTURER'     => 'Hynix',
            'TYPE'             => 'DDR3',
            'CAPTION'          => 'DIMM_A1',
            'MODEL'            => 'HMT42GR7AFR4A-PB',
            'CAPACITY'         => '16384',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'SPEED'            => '1600',
            'SERIALNUMBER'     => '1E60FA92',
            'DESCRIPTION'      => 'DIMM',
            'NUMSLOTS'         => 1
        },
        {
            'CAPTION'          => 'DIMM_A2',
            'MANUFACTURER'     => 'Hynix',
            'TYPE'             => 'DDR3',
            'SERIALNUMBER'     => '1E50FA98',
            'SPEED'            => '1600',
            'NUMSLOTS'         => 2,
            'DESCRIPTION'      => 'DIMM',
            'MODEL'            => 'HMT42GR7AFR4A-PB',
            'CAPACITY'         => '16384',
            'MEMORYCORRECTION' => 'Multi-bit ECC'
        },
        {
            'MODEL'            => 'HMT42GR7AFR4A-PB',
            'CAPACITY'         => '16384',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'SERIALNUMBER'     => '1E10FA91',
            'SPEED'            => '1600',
            'DESCRIPTION'      => 'DIMM',
            'NUMSLOTS'         => 3,
            'MANUFACTURER'     => 'Hynix',
            'TYPE'             => 'DDR3',
            'CAPTION'          => 'DIMM_A3'
        },
        {
            'MODEL'            => 'HMT42GR7AFR4A-PB',
            'CAPACITY'         => '16384',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'SPEED'            => '1600',
            'SERIALNUMBER'     => '1E20FA5F',
            'NUMSLOTS'         => 4,
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'TYPE'             => 'DDR3',
            'CAPTION'          => 'DIMM_A4'
        },
        {
            'CAPTION'          => 'DIMM_A5',
            'TYPE'             => 'DDR3',
            'MANUFACTURER'     => 'Hynix',
            'NUMSLOTS'         => 5,
            'DESCRIPTION'      => 'DIMM',
            'SERIALNUMBER'     => '0D7A9A0A',
            'SPEED'            => '1600',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'CAPACITY'         => '16384',
            'MODEL'            => 'HMT42GR7AFR4A-PB'
        },
        {
            'TYPE'             => 'DDR3',
            'MANUFACTURER'     => 'Hynix',
            'CAPTION'          => 'DIMM_A6',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'CAPACITY'         => '16384',
            'MODEL'            => 'HMT42GR7AFR4A-PB',
            'NUMSLOTS'         => 6,
            'DESCRIPTION'      => 'DIMM',
            'SPEED'            => '1600',
            'SERIALNUMBER'     => '1E30FA5D'
        },
        {
            'SPEED'            => '1600',
            'SERIALNUMBER'     => '3561867A',
            'DESCRIPTION'      => 'DIMM',
            'NUMSLOTS'         => 7,
            'MODEL'            => 'HMT42GR7AFR4A-PB',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'CAPACITY'         => '16384',
            'CAPTION'          => 'DIMM_A7',
            'MANUFACTURER'     => 'Hynix',
            'TYPE'             => 'DDR3'
        },
        {
            'MODEL'            => 'HMT42GR7AFR4A-PB',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'CAPACITY'         => '16384',
            'SERIALNUMBER'     => '1E30FA7F',
            'SPEED'            => '1600',
            'DESCRIPTION'      => 'DIMM',
            'NUMSLOTS'         => 8,
            'MANUFACTURER'     => 'Hynix',
            'TYPE'             => 'DDR3',
            'CAPTION'          => 'DIMM_A8'
        },
        {
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'DESCRIPTION'      => 'DIMM',
            'NUMSLOTS'         => 9,
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'TYPE'             => 'DDR3',
            'MANUFACTURER'     => undef,
            'CAPTION'          => 'DIMM_A9'
        },
        {
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 10,
            'DESCRIPTION'      => 'DIMM',
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'TYPE'             => 'DDR3',
            'MANUFACTURER'     => undef,
            'CAPTION'          => 'DIMM_A10'
        },
        {
            'CAPTION'          => 'DIMM_A11',
            'TYPE'             => 'DDR3',
            'MANUFACTURER'     => undef,
            'DESCRIPTION'      => 'DIMM',
            'NUMSLOTS'         => 11,
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'MEMORYCORRECTION' => 'Multi-bit ECC'
        },
        {
            'TYPE'             => 'DDR3',
            'MANUFACTURER'     => undef,
            'CAPTION'          => 'DIMM_A12',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'DESCRIPTION'      => 'DIMM',
            'NUMSLOTS'         => 12,
            'SPEED'            => undef,
            'SERIALNUMBER'     => undef
        },
        {
            'TYPE'             => 'DDR3',
            'MANUFACTURER'     => 'Hynix',
            'CAPTION'          => 'DIMM_B1',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'CAPACITY'         => '16384',
            'MODEL'            => 'HMT42GR7AFR4A-PB',
            'DESCRIPTION'      => 'DIMM',
            'NUMSLOTS'         => 13,
            'SPEED'            => '1600',
            'SERIALNUMBER'     => '0B2B0D87'
        },
        {
            'SPEED'            => '1600',
            'SERIALNUMBER'     => '1660EDAB',
            'DESCRIPTION'      => 'DIMM',
            'NUMSLOTS'         => 14,
            'MODEL'            => 'HMT42GR7AFR4A-PB',
            'CAPACITY'         => '16384',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'CAPTION'          => 'DIMM_B2',
            'MANUFACTURER'     => 'Hynix',
            'TYPE'             => 'DDR3'
        },
        {
            'TYPE'             => 'DDR3',
            'MANUFACTURER'     => 'Hynix',
            'CAPTION'          => 'DIMM_B3',
            'CAPACITY'         => '16384',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'MODEL'            => 'HMT42GR7AFR4A-PB',
            'NUMSLOTS'         => 15,
            'DESCRIPTION'      => 'DIMM',
            'SPEED'            => '1600',
            'SERIALNUMBER'     => '0D6A9A06'
        },
        {
            'MODEL'            => 'HMT42GR7AFR4A-PB',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'CAPACITY'         => '16384',
            'SPEED'            => '1600',
            'SERIALNUMBER'     => '1E40FA91',
            'NUMSLOTS'         => 16,
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Hynix',
            'TYPE'             => 'DDR3',
            'CAPTION'          => 'DIMM_B4'
        },
        {
            'TYPE'             => 'DDR3',
            'MANUFACTURER'     => 'Hynix',
            'CAPTION'          => 'DIMM_B5',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'CAPACITY'         => '16384',
            'MODEL'            => 'HMT42GR7AFR4A-PB',
            'NUMSLOTS'         => 17,
            'DESCRIPTION'      => 'DIMM',
            'SPEED'            => '1600',
            'SERIALNUMBER'     => '0B3B100A'
        },
        {
            'CAPTION'          => 'DIMM_B6',
            'MANUFACTURER'     => 'Hynix',
            'TYPE'             => 'DDR3',
            'SERIALNUMBER'     => '0B6B0D9E',
            'SPEED'            => '1600',
            'NUMSLOTS'         => 18,
            'DESCRIPTION'      => 'DIMM',
            'MODEL'            => 'HMT42GR7AFR4A-PB',
            'CAPACITY'         => '16384',
            'MEMORYCORRECTION' => 'Multi-bit ECC'
        },
        {
            'CAPTION'          => 'DIMM_B7',
            'TYPE'             => 'DDR3',
            'MANUFACTURER'     => 'Hynix',
            'NUMSLOTS'         => 19,
            'DESCRIPTION'      => 'DIMM',
            'SERIALNUMBER'     => '1E70FA94',
            'SPEED'            => '1600',
            'CAPACITY'         => '16384',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'MODEL'            => 'HMT42GR7AFR4A-PB'
        },
        {
            'TYPE'             => 'DDR3',
            'MANUFACTURER'     => 'Hynix',
            'CAPTION'          => 'DIMM_B8',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'CAPACITY'         => '16384',
            'MODEL'            => 'HMT42GR7AFR4A-PB',
            'DESCRIPTION'      => 'DIMM',
            'NUMSLOTS'         => 20,
            'SERIALNUMBER'     => '1680EDBD',
            'SPEED'            => '1600'
        },
        {
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'NUMSLOTS'         => 21,
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => undef,
            'TYPE'             => 'DDR3',
            'CAPTION'          => 'DIMM_B9'
        },
        {
            'SPEED'            => undef,
            'SERIALNUMBER'     => undef,
            'DESCRIPTION'      => 'DIMM',
            'NUMSLOTS'         => 22,
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'CAPTION'          => 'DIMM_B10',
            'MANUFACTURER'     => undef,
            'TYPE'             => 'DDR3'
        },
        {
            'MANUFACTURER'     => undef,
            'TYPE'             => 'DDR3',
            'CAPTION'          => 'DIMM_B11',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'DESCRIPTION'      => 'DIMM',
            'NUMSLOTS'         => 23
        },
        {
            'CAPTION'          => 'DIMM_B12',
            'MANUFACTURER'     => undef,
            'TYPE'             => 'DDR3',
            'SPEED'            => undef,
            'SERIALNUMBER'     => undef,
            'DESCRIPTION'      => 'DIMM',
            'NUMSLOTS'         => 24,
            'MEMORYCORRECTION' => 'Multi-bit ECC'
        }
    ],
    'hp-dl360-gen7' => [
        {
            'SPEED'            => undef,
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MANUFACTURER'     => undef,
            'SERIALNUMBER'     => undef,
            'TYPE'             => 'DDR3',
            'NUMSLOTS'         => 1,
            'CAPTION'          => 'PROC 1 DIMM 1G',
            'DESCRIPTION'      => 'DIMM'
        },
        {
            'DESCRIPTION'      => 'DIMM',
            'CAPTION'          => 'PROC 1 DIMM 2D',
            'CAPACITY'         => '8192',
            'SERIALNUMBER'     => undef,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 2,
            'TYPE'             => 'DDR3',
            'SPEED'            => '1333'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 3A',
            'DESCRIPTION'      => 'DIMM',
            'SPEED'            => '1333',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MANUFACTURER'     => undef,
            'TYPE'             => 'DDR3',
            'NUMSLOTS'         => 3,
            'SERIALNUMBER'     => undef,
            'CAPACITY'         => '8192'
        },
        {
            'SPEED'            => undef,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 4,
            'TYPE'             => 'DDR3',
            'SERIALNUMBER'     => undef,
            'CAPTION'          => 'PROC 1 DIMM 4H',
            'DESCRIPTION'      => 'DIMM'
        },
        {
            'CAPTION'          => 'PROC 1 DIMM 5E',
            'DESCRIPTION'      => 'DIMM',
            'SPEED'            => undef,
            'NUMSLOTS'         => 5,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'TYPE'             => 'DDR3',
            'SERIALNUMBER'     => undef
        },
        {
            'SPEED'            => '1333',
            'CAPACITY'         => '8192',
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'SERIALNUMBER'     => undef,
            'TYPE'             => 'DDR3',
            'NUMSLOTS'         => 6,
            'CAPTION'          => 'PROC 1 DIMM 6B',
            'DESCRIPTION'      => 'DIMM'
        },
        {
            'MANUFACTURER'     => undef,
            'TYPE'             => 'DDR3',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'SERIALNUMBER'     => undef,
            'NUMSLOTS'         => 7,
            'SPEED'            => undef,
            'DESCRIPTION'      => 'DIMM',
            'CAPTION'          => 'PROC 1 DIMM 7I'
        },
        {
            'DESCRIPTION'      => 'DIMM',
            'CAPTION'          => 'PROC 1 DIMM 8F',
            'MANUFACTURER'     => undef,
            'NUMSLOTS'         => 8,
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'SERIALNUMBER'     => undef,
            'TYPE'             => 'DDR3',
            'SPEED'            => undef
        },
        {
            'CAPACITY'         => '8192',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MANUFACTURER'     => undef,
            'TYPE'             => 'DDR3',
            'NUMSLOTS'         => 9,
            'SERIALNUMBER'     => undef,
            'SPEED'            => '1333',
            'DESCRIPTION'      => 'DIMM',
            'CAPTION'          => 'PROC 1 DIMM 9C'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 1G',
            'DESCRIPTION'      => 'DIMM',
            'SPEED'            => undef,
            'MANUFACTURER'     => undef,
            'NUMSLOTS'         => 10,
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'SERIALNUMBER'     => undef,
            'TYPE'             => 'DDR3'
        },
        {
            'SPEED'            => '1333',
            'SERIALNUMBER'     => undef,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 11,
            'TYPE'             => 'DDR3',
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 2 DIMM 2D',
            'DESCRIPTION'      => 'DIMM'
        },
        {
            'DESCRIPTION'      => 'DIMM',
            'CAPTION'          => 'PROC 2 DIMM 3A',
            'CAPACITY'         => '8192',
            'TYPE'             => 'DDR3',
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'SERIALNUMBER'     => undef,
            'NUMSLOTS'         => 12,
            'SPEED'            => '1333'
        },
        {
            'CAPTION'          => 'PROC 2 DIMM 4H',
            'DESCRIPTION'      => 'DIMM',
            'SPEED'            => undef,
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MANUFACTURER'     => undef,
            'TYPE'             => 'DDR3',
            'SERIALNUMBER'     => undef,
            'NUMSLOTS'         => 13
        },
        {
            'MANUFACTURER'     => undef,
            'TYPE'             => 'DDR3',
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 14,
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'DESCRIPTION'      => 'DIMM',
            'CAPTION'          => 'PROC 2 DIMM 5E'
        },
        {
            'CAPACITY'         => '8192',
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'TYPE'             => 'DDR3',
            'NUMSLOTS'         => 15,
            'SERIALNUMBER'     => undef,
            'SPEED'            => '1333',
            'DESCRIPTION'      => 'DIMM',
            'CAPTION'          => 'PROC 2 DIMM 6B'
        },
        {
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'MANUFACTURER'     => undef,
            'SERIALNUMBER'     => undef,
            'NUMSLOTS'         => 16,
            'TYPE'             => 'DDR3',
            'SPEED'            => undef,
            'DESCRIPTION'      => 'DIMM',
            'CAPTION'          => 'PROC 2 DIMM 7I'
        },
        {
            'SPEED'            => undef,
            'TYPE'             => 'DDR3',
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'NUMSLOTS'         => 17,
            'SERIALNUMBER'     => undef,
            'CAPTION'          => 'PROC 2 DIMM 8F',
            'DESCRIPTION'      => 'DIMM'
        },
        {
            'SPEED'            => '1333',
            'MANUFACTURER'     => undef,
            'NUMSLOTS'         => 18,
            'MEMORYCORRECTION' => 'Single-bit ECC',
            'TYPE'             => 'DDR3',
            'SERIALNUMBER'     => undef,
            'CAPACITY'         => '8192',
            'CAPTION'          => 'PROC 2 DIMM 9C',
            'DESCRIPTION'      => 'DIMM'
        }
    ],
    'dell-r640-1' => [
        {
            'CAPACITY'         => 8192,
            'CAPTION'          => 'A1',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Micron',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'MODEL'            => '9ASF1G72PZ-3G2E2',
            'NUMSLOTS'         => 1,
            'SERIALNUMBER'     => 'F16A7647',
            'SPEED'            => '3200',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => 8192,
            'CAPTION'          => 'A2',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Micron',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'MODEL'            => '9ASF1G72PZ-3G2E2',
            'NUMSLOTS'         => 2,
            'SERIALNUMBER'     => 'F16A798E',
            'SPEED'            => '3200',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => 8192,
            'CAPTION'          => 'A3',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Micron',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'MODEL'            => '9ASF1G72PZ-3G2E2',
            'NUMSLOTS'         => 3,
            'SERIALNUMBER'     => 'F16A808F',
            'SPEED'            => '3200',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => 8192,
            'CAPTION'          => 'A4',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Micron',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'MODEL'            => '9ASF1G72PZ-3G2E2',
            'NUMSLOTS'         => 4,
            'SERIALNUMBER'     => 'F16A7991',
            'SPEED'            => '3200',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => 8192,
            'CAPTION'          => 'A5',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Micron',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'MODEL'            => '9ASF1G72PZ-3G2E2',
            'NUMSLOTS'         => 5,
            'SERIALNUMBER'     => 'F16A7966',
            'SPEED'            => '3200',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => 8192,
            'CAPTION'          => 'A6',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Micron',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'MODEL'            => '9ASF1G72PZ-3G2E2',
            'NUMSLOTS'         => 6,
            'SERIALNUMBER'     => 'F16A7965',
            'SPEED'            => '3200',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPTION'          => 'A7',
            'DESCRIPTION'      => undef,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 7,
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'TYPE'             => undef
        },
        {
            'CAPTION'          => 'A8',
            'DESCRIPTION'      => undef,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 8,
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'TYPE'             => undef
        },
        {
            'CAPTION'          => 'A9',
            'DESCRIPTION'      => undef,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 9,
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'TYPE'             => undef
        },
        {
            'CAPTION'          => 'A10',
            'DESCRIPTION'      => undef,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 10,
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'TYPE'             => undef
        },
        {
            'CAPTION'          => 'A11',
            'DESCRIPTION'      => undef,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 11,
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'TYPE'             => undef
        },
        {
            'CAPTION'          => 'A12',
            'DESCRIPTION'      => undef,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 12,
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'TYPE'             => undef
        },
        {
            'CAPACITY'         => 8192,
            'CAPTION'          => 'B1',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Micron',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'MODEL'            => '9ASF1G72PZ-3G2E2',
            'NUMSLOTS'         => 13,
            'SERIALNUMBER'     => 'F16A7982',
            'SPEED'            => '3200',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => 8192,
            'CAPTION'          => 'B2',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Micron',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'MODEL'            => '9ASF1G72PZ-3G2E2',
            'NUMSLOTS'         => 14,
            'SERIALNUMBER'     => 'F16A7ADB',
            'SPEED'            => '3200',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => 8192,
            'CAPTION'          => 'B3',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Micron',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'MODEL'            => '9ASF1G72PZ-3G2E2',
            'NUMSLOTS'         => 15,
            'SERIALNUMBER'     => 'F16A798C',
            'SPEED'            => '3200',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => 8192,
            'CAPTION'          => 'B4',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Micron',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'MODEL'            => '9ASF1G72PZ-3G2E2',
            'NUMSLOTS'         => 16,
            'SERIALNUMBER'     => 'F16A7984',
            'SPEED'            => '3200',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => 8192,
            'CAPTION'          => 'B5',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Micron',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'MODEL'            => '9ASF1G72PZ-3G2E2',
            'NUMSLOTS'         => 17,
            'SERIALNUMBER'     => 'F16A7AD9',
            'SPEED'            => '3200',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPACITY'         => 8192,
            'CAPTION'          => 'B6',
            'DESCRIPTION'      => 'DIMM',
            'MANUFACTURER'     => 'Micron',
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'MODEL'            => '9ASF1G72PZ-3G2E2',
            'NUMSLOTS'         => 18,
            'SERIALNUMBER'     => 'F16A796C',
            'SPEED'            => '3200',
            'TYPE'             => 'DDR4'
        },
        {
            'CAPTION'          => 'B7',
            'DESCRIPTION'      => undef,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 19,
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'TYPE'             => undef
        },
        {
            'CAPTION'          => 'B8',
            'DESCRIPTION'      => undef,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 20,
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'TYPE'             => undef
        },
        {
            'CAPTION'          => 'B9',
            'DESCRIPTION'      => undef,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 21,
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'TYPE'             => undef
        },
        {
            'CAPTION'          => 'B10',
            'DESCRIPTION'      => undef,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 22,
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'TYPE'             => undef
        },
        {
            'CAPTION'          => 'B11',
            'DESCRIPTION'      => undef,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 23,
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'TYPE'             => undef
        },
        {
            'CAPTION'          => 'B12',
            'DESCRIPTION'      => undef,
            'MANUFACTURER'     => undef,
            'MEMORYCORRECTION' => 'Multi-bit ECC',
            'NUMSLOTS'         => 24,
            'SERIALNUMBER'     => undef,
            'SPEED'            => undef,
            'TYPE'             => undef
        },
    ],
    'memory/hynix-kingmax' => [
        {
            CAPACITY         => 8192,
            CAPTION          => 'DIMM A',
            DESCRIPTION      => 'SODIMM',
            MANUFACTURER     => 'Hynix',
            MEMORYCORRECTION => undef,
            MODEL            => 'HMAA1GS6CJR6N-XN',
            NUMSLOTS         => 1,
            SERIALNUMBER     => '25477B84',
            SPEED            => '3200',
            TYPE             => 'DDR4'
        },
        {
            CAPACITY         => 8192,
            CAPTION          => 'DIMM B',
            DESCRIPTION      => 'SODIMM',
            MANUFACTURER     => 'KingMax',
            MEMORYCORRECTION => undef,
            MODEL            => 'GSOG42F-18',
            NUMSLOTS         => 2,
            SERIALNUMBER     => '190020CB',
            SPEED            => '3200',
            TYPE             => 'DDR4'
        }
    ],
    'memory/positivo-informatica' => [
        {
            CAPTION          => 'ChannelA-DIMM0',
            DESCRIPTION      => 'DIMM',
            MANUFACTURER     => undef,
            MEMORYCORRECTION => undef,
            NUMSLOTS         => 1,
            SERIALNUMBER     => undef,
            SPEED            => undef,
            TYPE             => undef
        },
        {
            CAPACITY         => 8192,
            CAPTION          => 'ChannelB-DIMM0',
            DESCRIPTION      => 'SODIMM',
            MANUFACTURER     => 'Positivo Informática',
            MEMORYCORRECTION => undef,
            MODEL            => 'P48808GSHCRN-VK',
            NUMSLOTS         => 2,
            SERIALNUMBER     => '0000065D',
            SPEED            => '2667',
            TYPE             => 'DDR4'
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/generic/dmidecode/$test";
    my $memories = GLPI::Agent::Task::Inventory::Generic::Dmidecode::Memory::_getMemories(file => $file);
    cmp_deeply($memories, $tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'MEMORIES', entry => $_)
            foreach @$memories;
    } "$test: registering";
}
