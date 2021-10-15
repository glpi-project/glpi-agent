#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::More;

use GLPI::Agent::Task::WakeOnLan;
use GLPI::Test::Utils;

plan tests => 6;

my ($out, $err, $rc);

($out, $err, $rc) = run_executable('glpi-wakeonlan', '--help');
ok($rc == 0, '--help exit status');
like(
    $out,
    qr/^Usage:/,
    '--help stdout'
);
is($err, '', '--help stderr');

($out, $err, $rc) = run_executable('glpi-wakeonlan', '--version');
ok($rc == 0, '--version exit status');
is($err, '', '--version stderr');
like(
    $out,
    qr/$GLPI::Agent::Task::WakeOnLan::VERSION/,
    '--version stdout'
);
