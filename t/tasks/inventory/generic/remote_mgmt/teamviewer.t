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

use GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::TeamViewer;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

my %teamviewer_win32 = (
    '14.1.3399' => "660666566",
    '15.27.3'   => "881955027",
);

my %teamviewer_info = (
    '15.11.6-RPM' => "999"
);

plan tests => scalar(keys %teamviewer_win32) + scalar(keys %teamviewer_info) + 1;

my $module = Test::MockModule->new(
    'GLPI::Agent::Tools::Win32'
);

foreach my $test (keys %teamviewer_win32) {
    $module->mock(
        '_getRegistryKey',
        _mockGetRegistryKey($test)
    );
    my $teamViewerID = GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::TeamViewer::_getID(osname => "MSWin32");
    is($teamViewerID, $teamviewer_win32{$test}, "TeamViewer win32 getID - $test");
}

foreach my $test (sort keys %teamviewer_info) {
    my $file = "resources/generic/teamviewer/teamviewer-info-$test";
    my $teamViewerID = GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::TeamViewer::_getID(file => $file, osname => "linux");
    is($teamViewerID, $teamviewer_info{$test}, "TeamViewer info getID - $test");
}

# Adapted from GLPI::Test::Utils mockGetRegistryKey()
sub _mockGetRegistryKey {
    my ($test) = @_;

    return sub {
        my (%params) = @_;

        # We can mock getRegistryKey or better _getRegistryKey to cover getRegistryValue
        my $path = $params{path} || $params{keyName};
        my $file = "resources/generic/teamviewer/teamviewer-$test-$path.reg";
        return loadRegistryDump($file);
    };
}
