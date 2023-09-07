#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::AntiVirus::Bitdefender;

my %av_tests = (
    'bduitool-7.0.3.2239' => {
        COMPANY         => "Bitdefender",
        NAME            => "Bitdefender Endpoint Security Tools (BEST) for Linux",
        ENABLED         => 1,
        UPTODATE        => 1,
        VERSION         => "7.0.3.2239",
        BASE_VERSION    => "7.95171",
        BASE_CREATION   => "2023-08-24",
    },
);

plan tests =>
    (2 * scalar keys %av_tests) +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %av_tests) {
    my $file = "resources/linux/antivirus/$test";
    my $antivirus = GLPI::Agent::Task::Inventory::Linux::AntiVirus::Bitdefender::_getBitdefenderInfo(file => $file);
    cmp_deeply($antivirus, $av_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'ANTIVIRUS', entry => $antivirus);
    } "$test: registering";
}
