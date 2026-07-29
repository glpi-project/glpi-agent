#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::Deep;
use Test::Exception;
use Test::MockModule;
use Test::More;
use Test::NoWarnings;
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

GLPI::Agent::Task::Inventory::Win32::Sounds->require();

my %tests = (
    'logitech-h390' => [
        {
            CAPTION      => 'USB Audio Device',
            DESCRIPTION  => 'USB Audio Device',
            MANUFACTURER => 'Logitech, Inc.',
            NAME         => 'H390 headset with microphone',
        }
    ],
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Agent::Inventory->new();

my $sounds_module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::Win32::Sounds'
);

foreach my $test (keys %tests) {

    $sounds_module->mock('getWMIObjects', mockGetWMIObjects($test));

    my @sounds = GLPI::Agent::Task::Inventory::Win32::Sounds::_getSoundDevices();

    # Check SOUNDS — NAME and MANUFACTURER resolved from usb.ids
    cmp_deeply(
        \@sounds,
        $tests{$test},
        "$test: SOUNDS parsing"
    );

    lives_ok {
        $inventory->addEntry(section => 'SOUNDS', entry => $_)
            foreach @sounds;
    } "$test: SOUNDS registering";
}
