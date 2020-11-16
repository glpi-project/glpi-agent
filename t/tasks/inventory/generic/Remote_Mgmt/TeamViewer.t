#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';

use English qw(-no_match_vars);
use Test::Deep qw(cmp_deeply);
use Test::More;

use FusionInventory::Agent::Task::Inventory::Generic::Remote_Mgmt::TeamViewer;

plan(skip_all => 'test not supported on win32')
    if $OSNAME eq 'MSWin32';

plan(skip_all => 'test not supported on macosx')
    if $OSNAME eq 'darwin';

Test::NoWarnings->use();

my %teamviewer_tests = (
    '15.11.6-RPM' => "999"
);

plan tests => scalar(keys %teamviewer_tests) + 1;

foreach my $test (sort keys %teamviewer_tests) {
    my $file = "resources/generic/teamviewer/teamviewer-$test";
    my $teamViewerID = FusionInventory::Agent::Task::Inventory::Generic::Remote_Mgmt::TeamViewer::_getID(file => $file);
    cmp_deeply($teamViewerID, $teamviewer_tests{$test}, "TeamViewer $test");
}
