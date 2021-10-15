#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::More;
use Test::MockModule;
use UNIVERSAL::require;

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

GLPI::Agent::Task::Inventory::Win32::Printers->require();

my %tests = (
    xppro1 => {
        USB001 => '49R8Ka',
        USB002 => undef,
        USB003 => undef
    },
    xppro2 => {
        USB001 => 'J5J126789',
        USB003 => 'JV40VNJ',
        USB004 => undef,
    },
    7 => {
        USB001 => 'MY26K1K34C2L'
    },
    '7bis' => {
        USB001 => 'S163EJM'
    },
    '7ter' => {
        USB001 => '55PKB5Z11418880717'
    }
);

my $plan = 1;
foreach my $test (keys %tests) {
    $plan += scalar (keys %{$tests{$test}});
}
plan tests => $plan;

my $module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::Win32::Printers'
);

foreach my $test (keys %tests) {
    $module->mock(
        'getRegistryKey',
        mockGetRegistryKey($test)
    );

    foreach my $port (keys %{$tests{$test}}) {
        is(
            GLPI::Agent::Task::Inventory::Win32::Printers::_getUSBPrinterSerial($port),
            $tests{$test}->{$port},
            "$test sample, $port printer"
        );
    }
}
