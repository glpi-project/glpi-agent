#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::Linux::OS;

my %rpmbasesysteminstalldate = (
    'fedora-35' => "2022-01-26 07:51:32",
);

my %debianinstalldate = (
    'debian-11'     => "2022-02-04 12:18:02",
);

plan tests =>
    (scalar keys %rpmbasesysteminstalldate) +
    (scalar keys %debianinstalldate)        +
    1;

foreach my $test (keys %rpmbasesysteminstalldate) {
    my $file = "resources/linux/packaging/$test";
    my $installdate = GLPI::Agent::Task::Inventory::Linux::OS::_rpmBasesystemInstallDate(file => $file);
    is($installdate, $rpmbasesysteminstalldate{$test}, "$test installdate");
}

foreach my $test (keys %debianinstalldate) {
    my $file = "resources/generic/stat/$test";
    my $installdate = GLPI::Agent::Task::Inventory::Linux::OS::_debianInstallDate(file => $file);
    is($installdate, $debianinstalldate{$test}, "$test installdate");
}
