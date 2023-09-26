#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use English qw(-no_match_vars);
use Test::Deep qw(cmp_deeply);
use Test::More;
use Test::MockModule;
use Test::NoWarnings;

use GLPI::Test::Utils;

use GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::RMS;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

my $module = Test::MockModule->new(
    'GLPI::Agent::Tools::Win32'
);

my %win32_tests = (
    yes1n => "<expected id>",
);

plan tests => (scalar keys %win32_tests) + 1;

foreach my $test (keys(%win32_tests)) {
    $module->mock(
        '_getRegistryKey',
        _mockGetRegistryKey($test)
    );
    my $internetID = GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::RMS::_getID_MSWin32();
    is($internetID, "RMS win32 getID - $test");
}

# Adapted from GLPI::Test::Utils mockGetRegistryKey()
sub _mockGetRegistryKey {
    my ($test) = @_;

    return sub {
        my (%params) = @_;

        # We can mock getRegistryKey or better _getRegistryKey to cover getRegistryValue
        my $path = $params{path} || $params{keyName};
        my $file = "resources/generic/rms/rms-$test-$path.reg";
        return loadRegistryDump($file);
    };
}
