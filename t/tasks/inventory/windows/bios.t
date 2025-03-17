#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::More;
use Test::MockModule;
use Test::Deep;
use Test::Exception;
use UNIVERSAL::require;

use GLPI::Agent::Inventory;
use GLPI::Test::Utils;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

use Config;
# check thread support availability
if (!$Config{usethreads} || $Config{usethreads} ne 'define') {
    plan skip_all => 'thread support required';
}

Test::NoWarnings->use();

GLPI::Agent::Task::Inventory::Win32::Bios->require();

my %tests = (
    "proxmox"   => {
        BDATE           => '04/01/2014',
        BIOSSERIAL      => undef,
        BVERSION        => 'BOCHS  - 1',
        SSN             => undef,
        SMODEL          => 'BXPC____',
        SMANUFACTURER   => 'BOCHS_',
        BMANUFACTURER   => undef,
    },
);

my %date_tests = (
    "20050927******.******+***" => "09/27/2005",
    "foobar" => "foobar"
);

plan tests => (scalar keys %tests) +
              (scalar keys %date_tests) + 1;

my $inventory = GLPI::Agent::Inventory->new();

my $module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::Win32::Bios'
);

foreach my $test (keys %tests) {
    $module->mock(
        'getWMIObjects',
        mockGetWMIObjects($test)
    );

    GLPI::Agent::Task::Inventory::Win32::Bios::doInventory(
        inventory   => $inventory
    );
    my $bios = $inventory->getSection('BIOS');
    cmp_deeply(
        $bios,
        $tests{$test},
        "$test: BIOS parsing"
    );
}

foreach my $input (keys %date_tests) {
    my $result = $date_tests{$input};

    ok(GLPI::Agent::Task::Inventory::Win32::Bios::_dateFromIntString($input) eq $result, "_dateFromIntString($input)");
}
