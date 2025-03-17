#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::AntiVirus::Sentinelone;

my %av_tests = (
    'sentinelone-30.1.1.10' => {
        COMPANY         => "SentinelOne",
        NAME            => "SentinelAgent",
        ENABLED         => 1,
        UPTODATE        => 1,
        VERSION         => "30.1.1.10",
        BASE_VERSION    => "30.5.6.5",
    },
);

plan tests =>
    (2 * scalar keys %av_tests) +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %av_tests) {
    my $file = "resources/linux/antivirus/$test";
    my $antivirus = GLPI::Agent::Task::Inventory::Linux::AntiVirus::Sentinelone::_getSentineloneInfo(file => $file);
    cmp_deeply($antivirus, $av_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'ANTIVIRUS', entry => $antivirus);
    } "$test: registering";
}
