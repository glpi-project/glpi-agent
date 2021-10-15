#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;

use GLPI::Agent::Tools::HPUX;

my %machinfo_tests = (
    'hpux_11.23.ia64' => {
        '@(#) $Revision' => 'vmunix:    B11.23_LR FLAVOR=perf Fri Aug 29 22:35:38 PDT 2003 $',
        'OS info' => {
            'version ' => 'U (unlimited-user license)',
            'machine ' => 'ia64',
            'nodename' => 'basahpux',
            'idnumber' => '2834472062',
            'release ' => 'B.11.23',
            'sysname ' => 'HP-UX'
        },
        'CPU info' => {
            'processor capabilities'  => '0x0000000000000001',
            'processor revision'      => '2   Stepping A2',
            'processor version info'  => '0x000000001f020204',
            'vendor information'      => '"GenuineIntel"',
            'selected   '             => '0x0000000040000000',
            'implemented'             => '0xbdf0000060000000',
            'largest cpuid reg'       => '4',
            'architecture revision'   => '0',
            'processor family'        => '31   Intel(R) Itanium 2 Family Processors',
            'bus speed  '             => '400 MT/s',
            'processor serial number' => '0x0000000000000000',
            'number of cpus'          => '2',
            'implements long branch'  => '1',
            'clock speed'             => '1600 MHz',
            'processor model'         => '2   Intel(R) Itanium 2 processor'
        },
        'Cache info' => {
            'l2 unified'     => 'size =  256 KB, associativity = 8',
            'l1 instruction' => 'size =   16 KB, associativity = 4',
            'l1 data'        => 'size =   16 KB, associativity = 4',
            'l3 unified'     => 'size = 3072 KB, associativity = 6'
        },
        'Firmware info' => {
            'firmware revision'      => '04.29',
            'bmc version'            => '4.04',
            'fp swa driver revision' => '1.18'
        },
        'Platform info' => {
            'machine id number'     => 'a8f29c7e-b86e-11da-9b3a-01e2c9b6095d',
            'model string'          => '"ia64 hp server rx2620"',
            'machine serial number' => 'DEH460642W'
        }
    },
    'hpux_11.31-1' => {
        'CPU info' => '3 Intel(R) Itanium 2 processors (1.6 GHz, 9 MB) 400 MT/s bus, CPU version A2',
        '@(#) $Revision' => 'vmunix:    B.11.31_LR FLAVOR=perf',
        'OS info' => {
            'version'   => 'U (unlimited-user license)',
            'release'   => 'HP-UX B.11.31',
            'machine'   => 'ia64',
            'id number' => '1055760970',
            'nodename'  => 'SUSOTP4'
        },
        'Memory' => '8180 MB (7.99 GB)',
        'Firmware info' => {
            'firmware revision'      => '03.17',
            'fp swa driver revision' => '1.18',
            'bmc firmware revision'  => '3.49'
        },
        'Platform info' => {
            'machine id number'     => '3eeda24a-5ca0-11da-9b03-a7647c3c8ad0',
            'machine serial number' => 'DEH45429DX',
            'model'                 => '"ia64 hp server rx4640"'
        }
    },
    'hpux_11.31-2' => {
        'CPU info' => '2 Intel(R)  Itanium(R)  Processor 9350s (1.73 GHz, 24 MB) 4.79 GT/s QPI, CPU version E0 8 logical processors (4 per socket)',
        '@(#) $Revision' => 'vmunix:    B.11.31_LR FLAVOR=perf',
        'OS info' => {
            'version'   => 'U (unlimited-user license)',
            'release'   => 'HP-UX B.11.31',
            'machine'   => 'ia64',
            'id number' => '3607005965',
            'nodename'  => 'fresno'
        },
        'Memory' => '98135 MB (95.83 GB)',
        'Firmware info' => {
            'firmware revision'      => '01.08',
            'fp swa driver revision' => '1.18',
            'bmc firmware revision'  => '1.01'
        },
        'Platform info' => {
            'machine id number'     => 'd6fe8b0c-90b3-508c-9655-d815a5c650d0',
            'machine serial number' => 'VCX0000209',
            'model'                 => '"ia64 hp Integrity BL870c i2"'
        },
    },
    'hpux_11.31-3' => {
        'CPU info' => '2 Intel(R) Itanium 2 9100 series processors (1.6 GHz, 12 MB) 533 MT/s bus, CPU version A1',
        '@(#) $Revision' => 'vmunix:    B.11.31_LR FLAVOR=perf',
        'OS info' => {
            'version'   => 'U (unlimited-user license)',
            'release'   => 'HP-UX B.11.31',
            'machine'   => 'ia64',
            'id number' => '0037871059',
            'nodename'  => 'SUD9801'
        },
        'Memory' => '24013 MB (23.45 GB)',
        'Firmware info' => {
            'firmware revision'      => '9.22',
            'fp swa driver revision' => '1.18'
        },
        'Platform info' => {
            'machine id number'     => '0241ddd3-2788-11dd-badd-fcbd1949d758',
            'machine serial number' => 'DEH481567L',
            'model'                 => '"ia64 hp superdome server SD32B"'
        }
    },
    'hpux_11.31_3xia64' =>  {
        'CPU info' => '3 Intel(R) Itanium 2 processors (1.6 GHz, 9 MB) 400 MT/s bus, CPU version A2',
        '@(#) $Revision' => 'vmunix:    B.11.31_LR FLAVOR=perf',
        'OS info' => {
            'version'   => 'U (unlimited-user license)',
            'release'   => 'HP-UX B.11.31',
            'machine'   => 'ia64',
            'id number' => '1055760970',
            'nodename'  => 'SUSOTP4'
        },
        'Memory' => '8180 MB (7.99 GB)',
        'Firmware info' => {
            'firmware revision'      => '03.17',
            'fp swa driver revision' => '1.18',
            'bmc firmware revision'  => '3.49'
        },
        'Platform info' => {
            'machine id number'     => '3eeda24a-5ca0-11da-9b03-a7647c3c8ad0',
            'machine serial number' => 'DEH45429DX',
            'model'                 => '"ia64 hp server rx4640"'
        }
    },
    'hpux_11.31-superdome' => {
        'CPU info' => '1 Intel(R) Itanium 2 9100 series processor (1.6 GHz, 24 MB) 533 MT/s bus, CPU version A1 2 logical processors (2 per socket)',
        '@(#) $Revision' => 'vmunix:    B.11.31_LR FLAVOR=perf',
        'OS info' => {
            'version'   => 'U (unlimited-user license)',
            'release'   => 'HP-UX B.11.31',
            'machine'   => 'ia64',
            'id number' => '1057509435',
            'nodename'  => 'SUP0677'
        },
        'Memory' => '12749 MB (12.45 GB)',
        'Firmware info' => {
            'firmware revision'      => '9.48',
            'fp swa driver revision' => '1.18',
            'bmc firmware revision'  => '26.03'
        },
        'Platform info' => {
            'machine id number'     => '3f08503b-261f-11dd-aaaa-d2b7371bbb3d',
            'machine serial number' => 'DEH481567K',
            'model'                 => '"ia64 hp superdome server SD32B"'
        },
    }
);

plan tests =>
    (scalar keys %machinfo_tests);

foreach my $test (keys %machinfo_tests) {
    my $file = "resources/hpux/machinfo/$test";
    my $info = getInfoFromMachinfo(file => $file);
    cmp_deeply($info, $machinfo_tests{$test}, "machinfo parsing: $test");
}
