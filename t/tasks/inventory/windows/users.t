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
    '11-AzureAD' => {
        LOGIN     => 'johndoe',
        DOMAIN    => 'nowhere.org',
        _fullname => 'JohnDoe@AzureAD'
    },
    '11-test-WINDOWS_UPN_AS_LOGIN' => {
        LOGIN     => 'test@example.com',
        _fullname => 'TEST@EXAMPLE'
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

    # Set features
    $GLPI::Agent::Task::Inventory::Win32::Users::WINDOWS_UPN_AS_LOGIN = $test =~ /WINDOWS_UPN_AS_LOGIN$/ ? 1 : 0;

    my $user = GLPI::Agent::Task::Inventory::Win32::Users::_getLastUser();

    cmp_deeply(
        $user,
        $tests{$test},
        "$test: _getLastUser()".
        ($GLPI::Agent::Task::Inventory::Win32::Users::WINDOWS_UPN_AS_LOGIN ? ' - WINDOWS_UPN_AS_LOGIN enabled' : '')
    );
}
