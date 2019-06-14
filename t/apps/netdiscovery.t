#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::More;
use UNIVERSAL::require;
use Config;

use FusionInventory::Agent::Tools;
use FusionInventory::Test::Utils;

# check thread support availability
if (!$Config{usethreads} || $Config{usethreads} ne 'define') {
    plan skip_all => 'thread support required';
}

FusionInventory::Agent::Task::NetDiscovery->use();

plan tests => 12;

my ($out, $err, $rc);

($out, $err, $rc) = run_executable('glpi-netdiscovery', '--help');
ok($rc == 0, '--help exit status');
like(
    $out,
    qr/^Usage:/,
    '--help stdout'
);
is($err, '', '--help stderr');

($out, $err, $rc) = run_executable('glpi-netdiscovery', '--version');
ok($rc == 0, '--version exit status');
is($err, '', '--version stderr');
like(
    $out,
    qr/$FusionInventory::Agent::Task::NetDiscovery::VERSION/,
    '--version stdout'
);

($out, $err, $rc) = run_executable('glpi-netdiscovery', );
ok($rc == 2, 'no first address exit status');
like(
    $err,
    qr/no first address/,
    'no target stderr'
);
is($out, '', 'no target stdout');

($out, $err, $rc) = run_executable('glpi-netdiscovery', '--first 192.168.0.1');
ok($rc == 2, 'no last address exit status');
like(
    $err,
    qr/no last address/,
    'no target stderr'
);
is($out, '', 'no target stdout');
