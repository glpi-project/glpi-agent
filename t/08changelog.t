#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);

use GLPI::Agent;

plan(skip_all => 'Author test, set $ENV{TEST_AUTHOR} to a true value to run')
    if !$ENV{TEST_AUTHOR};

plan tests => 1;

open (my $handle, '<', 'Changes') or die "unable to open Change file: $ERRNO";

# skip the 2 first lines;
<$handle>;
<$handle>;

# read third line
my $line = <$handle>;
close $handle;
like(
    $line,
    qr/$GLPI::Agent::VERSION \w{3}, \d{1,2} \w{3} \d{4}$/,
    'changelog entry matches expected format'
);
