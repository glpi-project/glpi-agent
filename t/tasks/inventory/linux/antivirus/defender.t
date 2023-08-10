#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::AntiVirus::Defender;

my %av_tests = (
    'defender-101.23062.0010' => {
        COMPANY         => "Microsoft",
        NAME            => "Microsoft Defender",
        ENABLED         => 0,
        UPTODATE        => 1,
        VERSION         => "101.23062.0010",
        BASE_VERSION    => "1.395.30.0",
        EXPIRATION      => "2024-04-10",
        BASE_CREATION   => "2023-08-09",
    },
    'not-expected-output' => undef,
);

plan tests =>
    (2 * scalar keys %av_tests) +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %av_tests) {
    my $file = "resources/linux/antivirus/$test.json";
    my $antivirus = GLPI::Agent::Task::Inventory::Linux::AntiVirus::Defender::_getMSDefender(file => $file);
    cmp_deeply($antivirus, $av_tests{$test}, "$test: parsing");
    SKIP: {
        skip ('no need to test if not defined', 1) unless defined($antivirus);
        lives_ok {
            $inventory->addEntry(section => 'ANTIVIRUS', entry => $antivirus);
        } "$test: registering";
    }
}
