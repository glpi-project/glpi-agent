#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::AIX::Memory;

my %tests = (
    'aix-5.3a' => [
        {
            NUMSLOTS    => 0,
            SERIALNUMBER=> 'YH10MS5CH923',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U787A.001.DPM2CW2-P1-C9',
            CAPACITY    => '512'
        },
        {
            NUMSLOTS    => 1,
            SERIALNUMBER=> 'YH10MS5CH8ED',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U787A.001.DPM2CW2-P1-C11',
            CAPACITY    => '512'
        },
        {
            NUMSLOTS    => 2,
            SERIALNUMBER=> 'YH10MS5CH8F0',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U787A.001.DPM2CW2-P1-C14',
            CAPACITY    => '512'
        },
        {
            NUMSLOTS    => 3,
            SERIALNUMBER=> 'YH10MS5CH92C',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U787A.001.DPM2CW2-P1-C16',
            CAPACITY    => '512'
        }
    ],
    'aix-5.3b' => [
        {
            NUMSLOTS    => 0,
            SERIALNUMBER=> '00005055',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U788D.001.99DXY4Y-P1-C1',
            CAPACITY    => '1024'
        },
        {
            NUMSLOTS    => 1,
            SERIALNUMBER=> '04008030',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U788D.001.99DXY4Y-P1-C2',
            CAPACITY    => '1024'
        },
        {
            NUMSLOTS    => 2,
            SERIALNUMBER=> '00007033',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U788D.001.99DXY4Y-P1-C3',
            CAPACITY    => '1024'
        },
        {
            NUMSLOTS    => 3,
            SERIALNUMBER=> '00005031',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U788D.001.99DXY4Y-P1-C4',
            CAPACITY    => '1024'
        }
    ],
    'aix-5.3c' => [
        {
            NUMSLOTS    => 0,
            SERIALNUMBER=> 'YLD001110C29',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P1-C1',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 1,
            SERIALNUMBER=> 'YLD005346272',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P1-C2',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 2,
            SERIALNUMBER=> 'YLD000110C0C',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P1-C3',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 3,
            SERIALNUMBER=> 'YLD004930776',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P1-C4',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 4,
            SERIALNUMBER=> 'YLD00793074C',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P1-C5',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 5,
            SERIALNUMBER=> 'YLD003810961',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P1-C6',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 6,
            SERIALNUMBER=> 'YLD006346270',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P1-C7',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 7,
            SERIALNUMBER=> 'YLD00281096F',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P1-C8',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 8,
            SERIALNUMBER=> 'YLD009710956',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P2-C1',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 9,
            SERIALNUMBER=> 'YLD00D346271',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P2-C2',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 10,
            SERIALNUMBER=> 'YLD00851096F',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P2-C3',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 11,
            SERIALNUMBER=> 'YLD00C930661',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P2-C4',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 12,
            SERIALNUMBER=> 'YLD00F930748',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P2-C5',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 13,
            SERIALNUMBER=> 'YLD00B410C26',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P2-C6',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 14,
            SERIALNUMBER=> 'YLD00E34627B',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P2-C7',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 15,
            SERIALNUMBER=> 'YLD00A610973',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH5D66-P2-C8',
            CAPACITY    => '4096'
        }
    ],
    'aix-6.1b' => [
        {
            NUMSLOTS    => 0,
            SERIALNUMBER=> 'YLD0014403BC',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH55B2-P1-C1',
            CAPACITY    => '2048'
        },
        {
            NUMSLOTS    => 1,
            SERIALNUMBER=> 'YLD0004403BB',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A5.001.WIH55B2-P1-C3',
            CAPACITY    => '2048'
        }
    ],
    'aix-6.1a' => [
        {
            NUMSLOTS    => 0,
            SERIALNUMBER=> 'YLD00030486D',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A0.001.DNWHPLG-P1-C13-C2',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 1,
            SERIALNUMBER=> 'YLD003304853',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A0.001.DNWHPLG-P1-C13-C3',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 2,
            SERIALNUMBER=> 'YLD0013047DE',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A0.001.DNWHPLG-P1-C13-C4',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 3,
            SERIALNUMBER=> 'YLD002304855',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A0.001.DNWHPLG-P1-C13-C5',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 4,
            SERIALNUMBER=> 'YLD006304856',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A0.001.DNWHPLG-P1-C13-C6',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 5,
            SERIALNUMBER=> 'YLD00530483B',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A0.001.DNWHPLG-P1-C13-C7',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 6,
            SERIALNUMBER=> 'YLD007304859',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A0.001.DNWHPLG-P1-C13-C8',
            CAPACITY    => '4096'
        },
        {
            NUMSLOTS    => 7,
            SERIALNUMBER=> 'YLD00430481E',
            DESCRIPTION => 'Memory DIMM',
            CAPTION     => 'Slot U78A0.001.DNWHPLG-P1-C13-C9',
            CAPACITY    => '4096'
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/aix/lsvpd/$test";
    my @memories = GLPI::Agent::Task::Inventory::AIX::Memory::_getMemories(file => $file);
    cmp_deeply(\@memories, $tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'MEMORIES', entry => $_) foreach @memories;
    } "$test: registering";
}
