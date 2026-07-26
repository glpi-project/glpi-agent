#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::MacOS::License;

my %license_tests = (
    'eset-ees-lic-status' => {
        NAME      => "ESET Endpoint Security",
        FULLNAME  => "ESET Endpoint Security",
        PRODUCTID => "3EA-ABC-DEF",
    },
);

plan tests =>
    (2 * scalar keys %license_tests) +
    1;

foreach my $test (keys %license_tests) {
    my $inventory = GLPI::Test::Inventory->new();
    my $file = "resources/macos/license/$test";
    my $license = GLPI::Agent::Task::Inventory::MacOS::License::_getESETLicenses(
        file   => $file,
        logger => $inventory->{logger}
    );
    cmp_deeply($license, $license_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'LICENSEINFOS', entry => $license);
    } "$test: registering";
}
