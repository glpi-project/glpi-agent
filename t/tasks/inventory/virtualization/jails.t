#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Virtualization::Jails;
use GLPI::Agent::Tools::Virtualization;

my %tests = (
    sample1 => [
        {
            NAME      => 'xmpp-test3',
            STATUS    => STATUS_RUNNING,
            VMTYPE    => 'bsdjail',
        },
        {
            NAME      => 'xmpp-test2',
            STATUS    => STATUS_RUNNING,
            VMTYPE    => 'bsdjail',
        },
        {
            NAME      => 'xmpp-test1',
            STATUS    => STATUS_RUNNING,
            VMTYPE    => 'bsdjail',
        },
        {
            NAME      => 'noname.local',
            STATUS    => STATUS_RUNNING,
            VMTYPE    => 'bsdjail',
        },
    ]
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/virtualization/jails/$test";
    my @machines = GLPI::Agent::Task::Inventory::Virtualization::Jails::_getVirtualMachines(file => $file);
    cmp_deeply(\@machines, $tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'VIRTUALMACHINES', entry => $_)
            foreach @machines;
    } "$test: registering";
}
