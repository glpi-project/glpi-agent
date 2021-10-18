#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Virtualization::Parallels;
use GLPI::Agent::Tools::Virtualization;

my %tests = (
    sample1 => [
        {
            VMTYPE    => 'parallels',
            NAME      => 'Ubuntu Linux',
            SUBSYSTEM => 'Parallels',
            STATUS    => STATUS_OFF,
            UUID      => 'bc993872-c70f-40bf-b2e2-94d9f080eb55'
        }
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/virtualization/prlctl/$test";
    my @machines = GLPI::Agent::Task::Inventory::Virtualization::Parallels::_parsePrlctlA(file => $file);
    cmp_deeply(\@machines, $tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'VIRTUALMACHINES', entry => $_)
            foreach @machines;
    } "$test: registering";
}
