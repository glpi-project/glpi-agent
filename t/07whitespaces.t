#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use UNIVERSAL::require;

plan(skip_all => 'Author test, set $ENV{TEST_AUTHOR} to a true value to run')
    if !$ENV{TEST_AUTHOR};

plan(skip_all => 'Test::Whitespaces required')
    unless Test::Whitespaces->require();

Test::Whitespaces->use({
    dirs   => [ qw/lib bin t/],
    ignore => [ qr/~$/, qr/mock.t$/, qr/cisco.t$/ ],
});
