#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use UNIVERSAL::require;

use English qw(-no_match_vars);

plan(skip_all => 'Author test, set $ENV{TEST_AUTHOR} to a true value to run')
    if !$ENV{TEST_AUTHOR};

plan(skip_all => 'Test::Pod::Coverage required')
    unless Test::Pod::Coverage->require();

Test::Pod::Coverage->import();

if ($OSNAME eq 'MSWin32') {
    push @INC, 't/lib/fake/unix';
} else {
    push @INC, 't/lib/fake/windows';
}

my @modules = grep { filter($_) } all_modules('lib');
plan tests => scalar @modules;
foreach my $module (@modules) {
    pod_coverage_ok(
        $module,
        {
            coverage_class => 'Pod::Coverage::CountParents',
            also_private => [ qw/doInventory isEnabled/ ],
        }
    );
}

# namespace-based filter
sub filter {
    # no need to document multiple task-specific modules
    return 0 if $_ =~ m{GLPI::Agent::Task::\w+::};
    return 1;
}
