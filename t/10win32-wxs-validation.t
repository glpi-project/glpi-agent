#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
#~ use Test::Warnings;

use English qw(-no_match_vars);

use IPC::Run qw(run);

plan(skip_all => 'Author test, set $ENV{TEST_AUTHOR} to a true value to run')
    if !$ENV{TEST_AUTHOR};

plan skip_all => 'Only tested on linux'
    unless $OSNAME =~ /^linux$/i;

plan tests => 1;

run(
    [ $EXECUTABLE_NAME, "tools/validate-msi-wxs.sh" ],
    \my ($in, $out, $err)
);

diag "\n", map { "$_\n" } grep { /(?:INFO|WARNING|ERROR):/ } split("\n", $err);

ok($CHILD_ERROR >> 8 == 0, 'msi wxs is valid');

#~ ok($rc == 0, 'msi wxs is not valid');
