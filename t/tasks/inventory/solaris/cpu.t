#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::MockModule;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Solaris::CPU;

my %vpcu_tests = (
    unstable9s  => [ _map(24, { speed => '1165', type => 'sparcv9' }) ],
    unstable9x  => [ _map( 4, { speed => '2333', type => 'i386'    }) ],
    unstable10s => [ _map(24, { speed => '1165', type => 'sparcv9' }) ],
    unstable10x => [ _map( 4, { speed => '2333', type => 'i386'    }) ],
    unstable11s => [ _map( 4, { speed => '1165', type => 'sparcv9' }) ],
    unstable11x => [ _map( 4, { speed => '2326', type => 'i386'    }) ],
    giration    => [ _map(16, { speed => '1350', type => 'sparcv9' }) ],
    v240        => [ _map( 2, { speed => '1280', type => 'sparcv9' }) ],
    v490        => [ _map( 8, { speed => '1350', type => 'sparcv9' }) ],
    t1          => [ _map(16, { speed => '1000', type => 'sparcv9' }) ],
    t5120       => [ _map(32, { speed => '1165', type => 'sparcv9' }) ],
    solaris11   => [ _map(32, { speed => '1000', type => 'sparcv9' }) ],
    e6900       => [
        _map(8, { speed => '1350', type => 'sparcv9' }) ,
        _map(4, { speed =>  '900', type => 'sparcv9' }) ,
        _map(8, { speed => '1350', type => 'sparcv9' }) ,
    ],
    'sparc-t5'  => [ _map(64, { speed => '3600', type => 'sparcv9' }) ],
    'oi-2021.10' => [ _map(2, { speed => '3823', type => 'i386' })    ],
);

my %pcpu_tests = (
    unstable9s => [
        _map(1, { speed => '1165', type => 'UltraSPARC-T2', count => 24 })
    ],
    unstable9x => [
        _map(4, { type => 'i386', count => 1 })
    ],
    unstable10s => [
        _map(1, { speed => '1165', type => 'UltraSPARC-T2', count => 24 })
    ],
    unstable10x => [
        _map(4, { speed => '2333', type => 'Xeon E5410', count => 1 })
    ],
    unstable11s => [
        _map(1, { speed => '1165', type => 'UltraSPARC-T2', count => 4 })
    ],
    unstable11x => [
        _map(4, { speed => '2326', type => 'Xeon E5410', count => 1 })
    ],
    giration => [
        _map(8, { speed => '1350', type => 'UltraSPARC-IV', count => 2 })
    ],
    v240 => [
        _map(2, { type => 'UltraSPARC-IIIi', count => 1 })
    ],
    v490 => [
        _map(4, { speed => '1350', type => 'UltraSPARC-IV', count => 2 })
    ],
    t1   => [
        _map(1, { speed => '1000', type => 'UltraSPARC-T1', count => 16 })
    ],
    t5120 => [
        _map(1, { speed => '1165', type => 'UltraSPARC-T2', count => 32 })
    ],
    solaris11 => [
        _map(1, { speed => '1000', type => 'UltraSPARC-T1', count => 32 })
    ],
    e6900 => [
        _map(8, { speed => '1350', type => 'UltraSPARC-IV'  , count => 2 }),
        _map(4, { speed =>  '900', type => 'UltraSPARC-III+', count => 1 }),
    ],
    'sparc-t5' => [
        _map(1, { speed => '3600', type => 'SPARC-T5', count => 64 })
    ],
    'oi-2021.10' => [
        _map(1, { speed => '3823', type => 'AMD Ryzen 9 3900X 12-Core', count => 2 })
    ],
);

my %cpu_tests = (
    unstable9s => [
        _map(1,
            {
                NAME         => 'UltraSPARC-T2',
                MANUFACTURER => 'SPARC',
                SPEED        => '1165',
                THREAD       => 8,
                CORE         => 3
            }
        )
    ],
    unstable9x => [
        _map(4,
            {
                NAME         => 'i386',
                MANUFACTURER => undef,
                SPEED        => '2333',
                THREAD       => 1,
                CORE         => 1
            }
        )
    ],
    unstable10s => [
        _map(1,
            {
                NAME         => 'UltraSPARC-T2',
                MANUFACTURER => 'SPARC',
                SPEED        => '1165',
                THREAD       => 8,
                CORE         => 3
            }
        )
    ],
    unstable10x => [
        _map(4,
            {
                NAME         => 'Xeon E5410',
                MANUFACTURER => 'Intel',
                SPEED        => '2333',
                THREAD       => 1,
                CORE         => 1
            }
        )
    ],
    unstable11s => [
        _map(1,
            {
                NAME         => 'UltraSPARC-T2',
                MANUFACTURER => 'SPARC',
                SPEED        => '1165',
                THREAD       => 8,
                CORE         => 0.5
            }
        )
    ],
    unstable11x => [
        _map(4,
            {
                NAME         => 'Xeon E5410',
                MANUFACTURER => 'Intel',
                SPEED        => '2326',
                THREAD       => 1,
                CORE         => 1
            }
        )
    ],
    giration => [
        _map(8,
            {
                NAME         => 'UltraSPARC-IV',
                MANUFACTURER => 'SPARC',
                SPEED        => '1350',
                THREAD       => 1,
                CORE         => 2
            }
        )
    ],
    v240 => [
        _map(2,
            {
                NAME         => 'UltraSPARC-IIIi',
                MANUFACTURER => 'SPARC',
                SPEED        => '1280',
                THREAD       => 1,
                CORE         => 1
            }
        )
    ],
    v490 => [
        _map(4,
            {
                NAME         => 'UltraSPARC-IV',
                MANUFACTURER => 'SPARC',
                SPEED        => '1350',
                THREAD       => 1,
                CORE         => 2
            }
        )
    ],
    t1 => [
        _map(1,
            {
                NAME         => 'UltraSPARC-T1',
                MANUFACTURER => 'SPARC',
                SPEED        => 1000,
                THREAD       => 4,
                CORE         => 4
            }
        )
    ],
    t5120 => [
        _map(1,
            {
                NAME         => 'UltraSPARC-T2',
                MANUFACTURER => 'SPARC',
                SPEED        => 1165,
                THREAD       => 8,
                CORE         => 4
            }
        )
    ],
    solaris11 => [
        _map(1,
            {
                NAME         => 'UltraSPARC-T1',
                MANUFACTURER => 'SPARC',
                SPEED        => 1000,
                THREAD       => 4,
                CORE         => 8
            }
        )
    ],
    e6900 => [
        _map(4,
            {
                NAME         => 'UltraSPARC-III+',
                SPEED        => '900',
                MANUFACTURER => 'SPARC',
                CORE         => 1,
                THREAD       => 1
            }
        ),
        _map(8,
            {
                NAME         => 'UltraSPARC-IV',
                MANUFACTURER => 'SPARC',
                SPEED        => '1350',
                CORE         => 2,
                THREAD       => 1
            }
        ),
    ],
    'oi-2021.10' => [
        _map(1,
            {
                NAME         => 'AMD Ryzen 9 3900X',
                MANUFACTURER => 'AMD',
                SPEED        => 3823,
                THREAD       => 1,
                CORE         => 12
            }
        )
    ],
);

plan tests =>
    (scalar keys %vpcu_tests)    +
    (scalar keys %pcpu_tests)    +
    (2 * scalar keys %cpu_tests) +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %vpcu_tests) {
    my $file = "resources/solaris/psrinfo/$test-psrinfo_v";
    my @cpus = GLPI::Agent::Task::Inventory::Solaris::CPU::_getVirtualCPUs(file => $file);
    cmp_deeply(\@cpus, $vpcu_tests{$test}, "virtual cpus: $test");
}

foreach my $test (keys %pcpu_tests) {
    my $file = "resources/solaris/psrinfo/$test-psrinfo_vp";
    my @cpus = GLPI::Agent::Task::Inventory::Solaris::CPU::_getPhysicalCPUs(file => $file);
    cmp_deeply(\@cpus, $pcpu_tests{$test}, "physical cpus: $test");
}

my $module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::Solaris::CPU'
);

foreach my $test (keys %cpu_tests) {
    $module->mock(
        '_getVirtualCPUs',
        sub {
            my $original = $module->original('_getVirtualCPUs');
            return $original->(
                file => "resources/solaris/psrinfo/$test-psrinfo_v"
            );
        }
    );

    $module->mock(
        '_getPhysicalCPUs',
        sub {
            my $original = $module->original('_getPhysicalCPUs');
            return $original->(
                file => "resources/solaris/psrinfo/$test-psrinfo_vp"
            );
        }
    );

    my @cpus = GLPI::Agent::Task::Inventory::Solaris::CPU::_getCPUs();
    cmp_deeply(\@cpus, $cpu_tests{$test}, "$test: cpus values");
    lives_ok {
        $inventory->addEntry(section => 'CPUS', entry => $_) foreach @cpus;
    } "$test: registering";

}


sub _map {
    my ($count, $object) = @_;
    return map { $object } 1 .. $count;
}
