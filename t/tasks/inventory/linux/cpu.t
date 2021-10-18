#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::i386::CPU;
use GLPI::Agent::Task::Inventory::Linux::Alpha::CPU;
use GLPI::Agent::Task::Inventory::Linux::SPARC::CPU;
use GLPI::Agent::Task::Inventory::Linux::MIPS::CPU;
use GLPI::Agent::Task::Inventory::Linux::ARM::CPU;
use GLPI::Agent::Task::Inventory::Linux::PowerPC::CPU;

my %i386 = (
    'linux-686-1' => [
        {
            ARCH         => 'i386',
            THREAD       => 1,
            MANUFACTURER => 'Intel',
            NAME         => 'Intel(R) Pentium(R) M processor 1.73GHz',
            CORE         => 1,
            STEPPING     => '8',
            SPEED        => '1730',
            MODEL        => '13',
            FAMILYNUMBER => '6'
        }
    ],
    'rhel-5.6' => [
        {
            NAME           => 'Intel(R) Xeon(R) CPU E5620 @ 2.40GHz',
            FAMILYNUMBER   => '6',
            CORE           => '4',
            MANUFACTURER   => 'Intel',
            ARCH           => 'i386',
            MODEL          => '44',
            THREAD         => '8',
            STEPPING       => '2',
            SPEED          => '2400',
            EXTERNAL_CLOCK => 5860,
            FAMILYNAME     => 'Xeon',
            ID             => 'BFEBFBFF000206C2',
        },
        {
            NAME           => 'Intel(R) Xeon(R) CPU E5620 @ 2.40GHz',
            MANUFACTURER   => 'Intel',
            MODEL          => '44',
            SPEED          => '2400',
            THREAD         => '8',
            ARCH           => 'i386',
            CORE           => '4',
            STEPPING       => '2',
            FAMILYNUMBER   => '6',
            EXTERNAL_CLOCK => 5860,
            FAMILYNAME     => 'Xeon',
            ID             => 'BFEBFBFF000206C2',
        }
    ],
    # Physical server with 4/18 cores enabled in BIOS depending on Oracle license
    'oracle-server-6.7-oda' => [
        {
            ARCH            => 'i386',
            CORE            => '4',
            CORECOUNT       => '18',
            EXTERNAL_CLOCK  => '100',
            FAMILYNAME      => 'Xeon',
            FAMILYNUMBER    => '6',
            ID              => 'BFEBFBFF000306F2',
            MANUFACTURER    => 'Intel',
            MODEL           => '63',
            NAME            => 'Intel(R) Xeon(R) CPU E5-2699 v3 @ 2.30GHz',
            SPEED           => '2300',
            STEPPING        => '2',
            THREAD          => '8'
        },
        {
            ARCH            => 'i386',
            CORE            => '4',
            CORECOUNT       => '18',
            EXTERNAL_CLOCK  => '100',
            FAMILYNAME      => 'Xeon',
            FAMILYNUMBER    => '6',
            ID              => 'BFEBFBFF000306F2',
            MANUFACTURER    => 'Intel',
            MODEL           => '63',
            NAME            => 'Intel(R) Xeon(R) CPU E5-2699 v3 @ 2.30GHz',
            SPEED           => '2300',
            STEPPING        => '2',
            THREAD          => '8'
        }
    ],
    'rhel-6.2-vmware-2vcpus' => [
        {
            NAME           => 'Intel(R) Xeon(R) CPU E7520 @ 1.87GHz',
            MANUFACTURER   => 'Intel',
            MODEL          => '42',
            SPEED          => '1870',
            THREAD         => '1',
            ARCH           => 'i386',
            CORE           => '1',
            STEPPING       => '7',
            FAMILYNUMBER   => '6',
            ID             => '0FABFBFF000106A4',
        },
        {
            NAME           => 'Intel(R) Xeon(R) CPU E7520 @ 1.87GHz',
            MANUFACTURER   => 'Intel',
            MODEL          => '42',
            SPEED          => '1870',
            THREAD         => '1',
            ARCH           => 'i386',
            CORE           => '1',
            STEPPING       => '7',
            FAMILYNUMBER   => '6',
            ID             => '0FABFBFF000006A4',
        }
    ],
    'rhel-6.3-esx-1vcpu' => [
        {
            NAME           => 'Intel(R) Core(TM) i5-2500S CPU @ 2.70GHz',
            MANUFACTURER   => 'Intel',
            MODEL          => '42',
            SPEED          => '2700',
            THREAD         => '1',
            ARCH           => 'i386',
            CORE           => '1',
            STEPPING       => '7',
            FAMILYNUMBER   => '6',
            ID             => '0FABFBFF000206A7',
        }
    ],
    'linux-686-samsung-nc10-1' => [
        {
            ARCH         => 'i386',
            CORE         => '1',
            SPEED        => '1600',
            THREAD       => '2',
            NAME         => 'Intel(R) Atom(TM) CPU N270 @ 1.60GHz',
            MODEL        => '28',
            MANUFACTURER => 'Intel',
            FAMILYNUMBER => '6',
            STEPPING     => '2'
        }
    ],
    'linux-2.6.35-1-core-2-thread' => [
        {
            ARCH         => 'i386',
            NAME         => 'Intel(R) Atom(TM) CPU N270 @ 1.60GHz',
            THREAD       => '2',
            SPEED        => '1600',
            STEPPING     => '2',
            CORE         => '1',
            FAMILYNUMBER => '6',
            MANUFACTURER => 'Intel',
            MODEL        => '28'
        }
    ],

# IMPORTANT : this /proc/cpuinfo is _B0RKEN_, physical_id are not correct
# please see bug: #505
    'linux-hp-dl180' => [
        {
            ARCH         => 'i386',
            FAMILYNUMBER => 6,
            SPEED        => 2000,
            STEPPING     => 5,
            MANUFACTURER => 'Intel',
            CORE         => '4',
            NAME         => 'Intel(R) Xeon(R) CPU E5504 @ 2.00GHz',
            MODEL        => 26,
            THREAD       => '4',
        }
    ],
    'toshiba-r630-2-core' => [
        {
            ARCH         => 'i386',
            THREAD       => '4',
            NAME         => 'Intel(R) Core(TM) i3 CPU M 350 @ 2.27GHz',
            CORE         => '2',
            MODEL        => '37',
            STEPPING     => '5',
            SPEED        => '2270',
            MANUFACTURER => 'Intel',
            FAMILYNUMBER => '6'
        }
    ]
);

my %alpha = (
    'linux-alpha-1' => [
        {
            SERIAL => 'JA30502089',
            ARCH   => 'alpha',
            SPEED  => '1250',
            NAME   => undef
        }
    ]
);

my %sparc = (
    'linux-sparc-1' => [
        {
            ARCH => 'sparc',
            NAME => 'TI UltraSparc IIIi (Jalapeno)'
        },
        {
            ARCH => 'sparc',
            NAME => 'TI UltraSparc IIIi (Jalapeno)'
        }
    ]
);

my %arm = (
    'linux-armel-1' => [
        {
            ARCH  => 'arm',
            NAME  => 'XScale-80219 rev 0 (v5l)'
        }
    ],
    'linux-armel-2' => [
        {
            ARCH  => 'arm',
            NAME  => 'Feroceon 88FR131 rev 1 (v5l)'
        }
    ],
    'linux-armel-3' => [
        {
            ARCH  => 'arm',
            NAME  => 'ARMv6-compatible processor rev 7 (v6l)'
        }
    ],
    'linux-raspberry-pi-3-model-b' => [
        {
            ARCH  => 'arm',
            NAME  => 'ARMv7 Processor rev 4 (v7l)'
        },
        {
            ARCH  => 'arm',
            NAME  => 'ARMv7 Processor rev 4 (v7l)'
        },
        {
            ARCH  => 'arm',
            NAME  => 'ARMv7 Processor rev 4 (v7l)'
        },
        {
            ARCH  => 'arm',
            NAME  => 'ARMv7 Processor rev 4 (v7l)'
        }
    ],
);

my %mips = (
    'linux-mips-1' => [
        {
            NAME => 'R4400SC V5.0 FPU V0.0',
            ARCH => 'mips'
        }
    ]
);

my %ppc = (
    'linux-ppc-1' => [
        {
            ARCH         => 'powerpc',
            NAME         => '604r',
            MANUFACTURER => undef,
            SPEED        => undef
        }
    ],
    'linux-ppc-2' => [
        {
            ARCH         => 'powerpc',
            NAME         => 'POWER4+ (gq)',
            MANUFACTURER => undef,
            SPEED        => '1452'
        },
        {
            ARCH         => 'powerpc',
            NAME         => 'POWER4+ (gq)',
            MANUFACTURER => undef,
            SPEED        => '1452'
        }
    ],
    'linux-ppc-3' => [
        {
            ARCH         => 'powerpc',
            NAME         => 'PPC970FX, altivec supported',
            MANUFACTURER => undef,
            SPEED        => '2700'
        },
        {
            ARCH         => 'powerpc',
            NAME         => 'PPC970FX, altivec supported',
            MANUFACTURER => undef,
            SPEED        => '2700'
        }
    ]
);

plan tests =>
    (2 * scalar keys %alpha) +
    (2 * scalar keys %sparc) +
    (2 * scalar keys %arm)   +
    (2 * scalar keys %mips)  +
    (2 * scalar keys %ppc)   +
    (2 * scalar keys %i386)  +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %i386) {
    my $cpuinfo   = "resources/linux/proc/cpuinfo/$test";
    my $dmidecode = "resources/generic/dmidecode/$test";
    my @cpus = GLPI::Agent::Task::Inventory::Linux::i386::CPU::_getCPUs(file => $cpuinfo, dmidecode => $dmidecode);
    cmp_deeply(\@cpus, $i386{$test}, "cpus: ".$test);
    lives_ok {
        $inventory->addEntry(section => 'CPUS', entry => $_) foreach @cpus;
    } 'no unknown fields';
}

foreach my $test (keys %alpha) {
    my $file = "resources/linux/proc/cpuinfo/$test";
    my @cpus = GLPI::Agent::Task::Inventory::Linux::Alpha::CPU::_getCPUsFromProc(file => $file);
    cmp_deeply(\@cpus, $alpha{$test}, $test);
    lives_ok {
        $inventory->addEntry(section => 'CPUS', entry => $_) foreach @cpus;
    } 'no unknown fields';
}

foreach my $test (keys %sparc) {
    my $file = "resources/linux/proc/cpuinfo/$test";
    my @cpus = GLPI::Agent::Task::Inventory::Linux::SPARC::CPU::_getCPUsFromProc(file => $file);
    cmp_deeply(\@cpus, $sparc{$test}, $test);
    lives_ok {
        $inventory->addEntry(section => 'CPUS', entry => $_) foreach @cpus;
    } 'no unknown fields';
}

foreach my $test (keys %mips) {
    my $file = "resources/linux/proc/cpuinfo/$test";
    my @cpus = GLPI::Agent::Task::Inventory::Linux::MIPS::CPU::_getCPUsFromProc(file => $file);
    cmp_deeply(\@cpus, $mips{$test}, $test);
    lives_ok {
        $inventory->addEntry(section => 'CPUS', entry => $_) foreach @cpus;
    } 'no unknown fields';
}

foreach my $test (keys %arm) {
    my $file = "resources/linux/proc/cpuinfo/$test";
    my @cpus = GLPI::Agent::Task::Inventory::Linux::ARM::CPU::_getCPUsFromProc(file => $file);
    cmp_deeply(\@cpus, $arm{$test}, $test);
    lives_ok {
        $inventory->addEntry(section => 'CPUS', entry => $_) foreach @cpus;
    } 'no unknown fields';
}

foreach my $test (keys %ppc) {
    my $file = "resources/linux/proc/cpuinfo/$test";
    my @cpus = GLPI::Agent::Task::Inventory::Linux::PowerPC::CPU::_getCPUsFromProc(file => $file);
    cmp_deeply(\@cpus, $ppc{$test}, $test);
    lives_ok {
        $inventory->addEntry(section => 'CPUS', entry => $_) foreach @cpus;
    } 'no unknown fields';
}
