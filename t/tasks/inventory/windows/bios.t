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

Test::NoWarnings->use();

GLPI::Agent::Task::Inventory::Win32::Bios->require();

my %tests = (
    "20050927******.******+***" => "09/27/2005",
    "foobar" => "foobar"
);
plan tests => (scalar keys %tests) + 1;

foreach my $input (keys %tests) {
    my $result = $tests{$input};

    ok(GLPI::Agent::Task::Inventory::Win32::Bios::_dateFromIntString($input) eq $result, "_dateFromIntString($input)");
}
