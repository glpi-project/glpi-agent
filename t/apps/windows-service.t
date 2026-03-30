#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::More;

use GLPI::Test::Utils;

plan skip_all => 'Windows-only test'
    if $OSNAME ne 'MSWin32';

plan tests => 9;

my ($out, $err, $rc);

($out, $err, $rc) = run_executable('glpi-win32-service', '--help');
ok($rc == 0, '--help exit status');
like(
    $out,
    qr/^Usage:/,
    '--help stdout'
);
is($err, '', '--help stderr');

($out, $err, $rc) = run_executable('glpi-win32-service', '--register -n glpi-agent-test -d "GLPI-Agent TEST"');
ok($rc == 0, '--register exit status');
is($err, '', '--register stderr');
like(
    $out,
    qr/registred as glpi-agent-test service/,
    '--register stdout'
);

($out, $err, $rc) = run_executable('glpi-win32-service', '--delete -n glpi-agent-test', );
ok($rc == 0, '--delete exit status');
is($err, '', '--delete stderr');
like(
    $out,
    qr/glpi-agent-test service deleted/,
    '--delete stdout'
);
