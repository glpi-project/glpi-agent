#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::AntiVirus::EEA;

my %av_tests = (
    'eea-12.0.13.0' => {
        _test_date      => "10-10-10-10-8-125", # 10/09/2025 - 10h10m10 encoded for mktime()
        COMPANY         => "ESET",
        NAME            => "ESET Endpoint Antivirus",
        ENABLED         => 1,
        VERSION         => "12.0.13.0",
        BASE_VERSION    => "31832 (20250909)",
        EXPIRATION      => "2026-06-21",
        UPTODATE        => "1",
    },
);

plan tests =>
    (2 * scalar keys %av_tests) +
    1;

foreach my $test (keys %av_tests) {
    my $inventory = GLPI::Test::Inventory->new();
    my $base_file = "resources/linux/antivirus/$test";
    my $antivirus = GLPI::Agent::Task::Inventory::Linux::AntiVirus::EEA::_getEEAInfo(
        upd_version => $base_file."-upd-version",
        upd_modules => $base_file."-upd-list-modules",
        lic_status  => $base_file."-lic-status",
        svc_status  => $base_file."-svc-status",
        test_date   => delete $av_tests{$test}->{_test_date},
        logger      => $inventory->{logger}
    );
    cmp_deeply($antivirus, $av_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'ANTIVIRUS', entry => $antivirus);
    } "$test: registering";
}
