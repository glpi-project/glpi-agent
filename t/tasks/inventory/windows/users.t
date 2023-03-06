#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';
use Encode qw(decode encode);

use English qw(-no_match_vars);
use Test::Deep;
use Test::Exception;
use Test::MockModule;
use Test::More;
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

GLPI::Agent::Task::Inventory::Win32::Users->require();

my %tests = (
    '7-AD' => {
       LOGIN  => 'teclib',
       DOMAIN => 'AD'
    },
    '10-StandAlone' => {
       LOGIN  => 'teclib',
       DOMAIN => 'XPS-FUSIONINVEN'
    },
);

plan tests => scalar (keys %tests) + 1;

my $module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::Win32::Users'
);

my $tools_module = Test::MockModule->new(
    'GLPI::Agent::Tools::Win32'
);

my $users_module = Test::MockModule->new(
    'GLPI::Agent::Tools::Win32::Users'
);

foreach my $test (keys %tests) {

    $tools_module->mock(
        '_getRegistryKey',
        mockGetRegistryKey($test)
    );

    $module->mock(
        'getWMIObjects',
        mockGetWMIObjects($test)
    );

    $users_module->mock(
        'getWMIObjects',
        mockGetWMIObjects($test)
    );

    my $user = GLPI::Agent::Task::Inventory::Win32::Users::_getLastUser();

    cmp_deeply(
        $user,
        $tests{$test},
        "$test: _getLastUser()"
    );
}
