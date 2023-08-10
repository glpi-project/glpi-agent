#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::MacOS::AntiVirus;

my %av_tests = (
    'defender-101.98.30' => {
        COMPANY         => "Microsoft",
        NAME            => "Microsoft Defender",
        ENABLED         => 1,
        UPTODATE        => 1,
        VERSION         => "101.98.30",
        BASE_VERSION    => "1.389.10.0",
        EXPIRATION      => "2023-09-06",
        BASE_CREATION   => "2023-05-03",
    },
);

plan tests =>
    (2 * scalar keys %av_tests) +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %av_tests) {
    my $file = "resources/macos/antivirus/$test.json";
    my $antivirus = GLPI::Agent::Task::Inventory::MacOS::AntiVirus::_getMSDefender(file => $file);
    cmp_deeply($antivirus, $av_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'ANTIVIRUS', entry => $antivirus);
    } "$test: registering";
}
