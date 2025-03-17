#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::AntiVirus::Cortex;

my %av_tests = (
    'cortex-xdr-8.2.1.120305' => {
        COMPANY         => "Palo Alto Networks",
        NAME            => "Cortex XDR",
        ENABLED         => 1,
        VERSION         => "8.2.1.120305",
        BASE_VERSION    => "1270-120305",
    },
);

plan tests =>
    (2 * scalar keys %av_tests) +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %av_tests) {
    my $base_file = "resources/linux/antivirus/$test";
    my $antivirus = GLPI::Agent::Task::Inventory::Linux::AntiVirus::Cortex::_getCortex(basefile => $base_file);
    cmp_deeply($antivirus, $av_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'ANTIVIRUS', entry => $antivirus);
    } "$test: registering";
}
