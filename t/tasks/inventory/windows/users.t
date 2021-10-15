#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';
#use utf8;
use Encode;

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

$module->mock(
    'encodeFromRegistry',
    sub {
        return undef unless $_[0];
        return encode("UTF-8", decode('cp1252', $_[0]));
    }
);

my $tools_module = Test::MockModule->new(
    'GLPI::Agent::Tools::Win32'
);

# Variant of sub mockGetRegistryKey fo
sub mock_GetRegistryKey {
    my ($test) = @_;

    return sub {
        my (%params) = @_;

        my $last_elt = (split(/\//, $params{keyName}))[-1];
        my $file = "resources/win32/registry/$test-$last_elt.reg";
        return loadRegistryDump($file);
    };
}

foreach my $test (keys %tests) {

    $tools_module->mock(
        '_getRegistryKey',
        mockGetRegistryKey($test)
    );

    $module->mock(
        'getWMIObjects',
        mockGetWMIObjects($test)
    );

    #my $preloaded_hkey = loadRegistryDump("resources/win32/registry/$test.reg");
#use Data::Dumper ; print STDERR "HKEY: ",Dumper($preloaded_hkey);
    my $user = GLPI::Agent::Task::Inventory::Win32::Users::_getLastUser();

    cmp_deeply(
        $user,
        $tests{$test},
        "$test: _getLastUser()"
    );
}
