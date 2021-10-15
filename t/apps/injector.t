#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::More;

use GLPI::Test::Utils;

plan tests => 3;

my ($out, $err, $rc);

($out, $err, $rc) = run_executable('glpi-injector', '--help');
ok($rc == 0, '--help exit status');
is($err, '', '--help stderr');
like(
    $out,
    qr/^Usage:/,
    '--help stdout'
);
