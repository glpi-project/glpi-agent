#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::License::EEA;

my %lic_tests = (
    'eea-12.0.13.0' => {
        NAME      => "ESET Endpoint Antivirus",
        FULLNAME  => "ESET Endpoint Antivirus",
        PRODUCTID => "999-XXX-YYY",
    },
);

plan tests =>
    (2 * scalar keys %lic_tests) +
    1;

foreach my $test (keys %lic_tests) {
    my $inventory = GLPI::Test::Inventory->new();
    my $base_file = "resources/linux/antivirus/$test";
    my $license = GLPI::Agent::Task::Inventory::Linux::License::EEA::_getEEALicense(
        lic_status  => $base_file."-lic-status",
        logger      => $inventory->{logger}
    );
    cmp_deeply($license, $lic_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'LICENSEINFOS', entry => $license);
    } "$test: registering";
}
