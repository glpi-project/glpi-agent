#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use UNIVERSAL::require;
use English qw(-no_match_vars);

plan(skip_all => 'Author test, set $ENV{TEST_AUTHOR} to a true value to run')
    if !$ENV{TEST_AUTHOR};

plan(skip_all => 'Test::Vars required')
    unless Test::Vars->require();

Test::Vars->import();

if ($OSNAME eq 'MSWin32') {
    push @INC, 't/lib/fake/unix';
} else {
    push @INC, 't/lib/fake/windows';
}

all_vars_ok(
    ignore_vars => {
        '%params'   => 1,
        '$class'    => 1,
        '$request'  => 1, # GLPI::Agent::HTTP::Server
        '$clientIp' => 1, # GLPI::Agent::HTTP::Server
        '$num'      => 1, # Task::Inventory::Input::Solaris::Networks
        '$i'        => 1, # GLPI::Agent::Tools::Solaris
        '$type'     => 1, # GLPI::Agent::Tools::Hardware
    }
);
