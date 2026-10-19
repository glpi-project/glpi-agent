#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::BSD::i386;

my %tests_i386 = (
    'openbsd79-vmware' => {
        # See https://github.com/glpi-project/glpi-agent/pull/1257
        dmesg   => 'dmesg.boot-openbsd79-vmware.txt',
        hw      => {
            model       => 'Intel(R) Xeon(R) Gold 6448Y',
            cpuspeed    => '2100',
        },
        expect  => [
            {
                NAME         => 'Intel(R) Xeon(R) Gold 6448Y',
                MANUFACTURER => 'Intel',
                CORE         => '2',
                THREAD       => '1',
                SPEED        => '2100'
            },
        ],
    }
);

plan tests => (2 * scalar keys %tests_i386) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests_i386) {
    my $file = "resources/bsd/dmesg/$tests_i386{$test}->{dmesg}";
    my $cpu = {
        NAME            => $tests_i386{$test}->{hw}->{model},
        SPEED           => GLPI::Agent::Tools::getCanonicalSpeed($tests_i386{$test}->{hw}->{cpuspeed}),
        MANUFACTURER    => GLPI::Agent::Tools::getCanonicalManufacturer($tests_i386{$test}->{hw}->{model}),
    };
    my @cpus = GLPI::Agent::Task::Inventory::BSD::i386::_getOpenBSDCpuPackages(file => $file, cpu => $cpu);
    cmp_deeply(\@cpus, $tests_i386{$test}->{expect}, $test);
    lives_ok {
        $inventory->addEntry(section => 'CPUS', entry => $_) foreach @cpus;
    } "$test: registering";
}
