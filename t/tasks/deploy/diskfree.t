#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::More;
use File::Temp qw(tempdir);

plan tests => 1;

use GLPI::Agent::Task::Deploy::DiskFree;


my $tmp = tempdir(CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);

ok(getFreeSpace(path => $tmp) > 0, "getFreeSpace()");
