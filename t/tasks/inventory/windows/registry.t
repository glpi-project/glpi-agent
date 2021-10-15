#!/usr/bin/perl

use strict;
use warnings;
use utf8;
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

GLPI::Agent::Task::Inventory::Win32::Registry->require();

if ($OSNAME ne 'MSWin32') {
    plan skip_all => 'Windows-specific test';
} else {
    Test::NoWarnings->use();
    plan tests => 9;
}

my @data;

@data = GLPI::Agent::Task::Inventory::Win32::Registry::_getRegistryData(
    registry => {
        NAME => 'REGISTRY',
        PARAM => {
            NAME    => 'CurrentVersion',
            content => 'Identifier',
            REGTREE => '2',
            REGKEY  => 'HARDWARE\\DESCRIPTION\\System'
        }
    }
);
ok(@data == 1, "unique entry");
ok($data[0]->{entry}{REGVALUE}, "unique entry: REGVALUE");
ok($data[0]->{entry}{NAME} eq 'CurrentVersion', "unique entry: NAME");

@data = GLPI::Agent::Task::Inventory::Win32::Registry::_getRegistryData(
    registry => {
        NAME => 'REGISTRY',
        PARAM => [
            {
                NAME    => 'ProductID',
                content => 'Identifier',
                REGTREE => '2',
                REGKEY  => 'HARDWARE\\DESCRIPTION\\System'
            },
            {
                 NAME    => 'CurrentVersion',
                 content => '*',
                 REGTREE => '2',
                 REGKEY  => 'HARDWARE\\DESCRIPTION\\System'
            }
        ]
    }
);

ok(@data > 4, "Wildcard test");
ok($data[0]->{entry}{REGVALUE}, "Wildcard test: REGVALUE");
ok($data[0]->{entry}{NAME} eq 'ProductID', "Wildcard test NAME (1/3)");
ok($data[1]->{entry}{NAME} eq 'CurrentVersion', "Wildcard test NAME (2/3)");
ok($data[2]->{entry}{NAME} eq 'CurrentVersion', "Wildcard test NAME (3/3)");
