#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::MacOS::AntiVirus::ESET;

my %av_tests = (
    'eset-ees' => {
        _test_date      => "126-7-26-12-0-0", # 2026-07-26 - encoded for mktime(sec,min,hour,mday,mon-1,year-1900)
        COMPANY         => "ESET",
        NAME            => "ESET Endpoint Security for macOS",
        ENABLED         => 1,
        VERSION         => "9.1.3100.0",
        BASE_VERSION    => "33566 (20260726)",
        EXPIRATION      => "2027-07-24",
        UPTODATE        => "1",
    },
);

plan tests =>
    (2 * scalar keys %av_tests) +
    1;

foreach my $test (keys %av_tests) {
    my $inventory = GLPI::Test::Inventory->new();
    my $base_file = "resources/macos/antivirus/$test";
    my $antivirus = GLPI::Agent::Task::Inventory::MacOS::AntiVirus::ESET::_getESETInfo(
        upd_version   => $base_file."-upd-version",
        upd_modules   => $base_file."-upd-list-modules",
        lic_status     => $base_file."-lic-status",
        launchctl_list => $base_file."-launchctl-list",
        daemon_plist   => $base_file."-daemon.plist",
        ps_status     => $base_file."-ps-status",
        settings_file => $base_file."-settings.json",
        test_date     => delete $av_tests{$test}->{_test_date},
        logger        => $inventory->{logger}
    );
    cmp_deeply($antivirus, $av_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'ANTIVIRUS', entry => $antivirus);
    } "$test: registering";
}
