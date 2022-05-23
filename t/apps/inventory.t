#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use IPC::Run qw(run);
use Test::More;

use GLPI::Agent::Task::Inventory;

plan tests => 8;

my ($out, $err, $rc);

($out, $err, $rc) = run_inventory('--help');
ok($rc == 0, '--help exit status');
like(
    $out,
    qr/^Usage:/,
    '--help stdout'
);
is($err, '', '--help stderr');

($out, $err, $rc) = run_inventory('--version');
ok($rc == 0, '--version exit status');
is($err, '', '--version stderr');
like(
    $out,
    qr/$GLPI::Agent::Task::Inventory::VERSION/,
    '--version stdout'
);

($out, $err, $rc) = run_inventory('--partial os');
ok($rc == 0, 'simple os partial inventory exit status');
like(
    $out,
    qr/\"partial\":\s+true/,
    'partial inventory has json partial property'
);

sub run_inventory {
    my ($args) = @_;
    my @args = $args ? split(/\s+/, $args) : ();
    run(
        [ $EXECUTABLE_NAME, 'bin/glpi-inventory', @args ],
        \my ($in, $out, $err)
    );
    return ($out, $err, $CHILD_ERROR >> 8);
}
