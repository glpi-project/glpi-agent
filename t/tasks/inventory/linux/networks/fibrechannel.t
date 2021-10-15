#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::Networks::FibreChannel;

my %tests = (
    'sample1' => [
        {
            STATUS      => 'Up',
            SPEED       => '4000',
            TYPE        => 'fibrechannel',
            DESCRIPTION => 'host5',
            WWN         => '10:00:00:00:c9:af:df:c6',
        },
        {
            STATUS      => 'Up',
            SPEED       => '4000',
            TYPE        => 'fibrechannel',
            DESCRIPTION => 'host6',
            WWN         => '10:00:00:00:c9:af:df:c7',
        },
    ],
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/linux/systool/$test";
    my @interfaces = GLPI::Agent::Task::Inventory::Linux::Networks::FibreChannel::_getInterfacesFromFcHost(file => $file);
    cmp_deeply(\@interfaces, $tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'NETWORKS', entry => $_) foreach @interfaces;
    } "$test: registering";
}
