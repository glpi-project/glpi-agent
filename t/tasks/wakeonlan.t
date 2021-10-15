#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Config;

use English qw(-no_match_vars);
use Test::More;
use Test::MockModule;

use GLPI::Test::Utils;
use GLPI::Agent::Task::WakeOnLan;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

my @payload_tests = (
    '0024D66F813A',
    'A4BADBA5F5FA'
);

my %interfaceid_tests = (
    7 => {
        'PCI\VEN_10EC&DEV_8168&SUBSYS_84321043&REV_06\4&87D54EE&0&00E5'
            => '\Device\NPF_{442CDFAD-10E9-45B6-8CF9-C829034793B0}',
        'BTH\\MS_BTHPAN\7&42D85A8&0&2'
            => '\Device\NPF_{DDE01862-B0C0-4715-AF6C-51D31172EBF9}'
    }
);

my $plan = scalar @payload_tests * 2;
my $plan_with_threads = 0;
foreach my $test (keys %interfaceid_tests) {
    $plan_with_threads += scalar (keys %{$interfaceid_tests{$test}});
}
plan tests => $plan + $plan_with_threads;

foreach my $test (@payload_tests) {
    my $payload = GLPI::Agent::Task::WakeOnLan->_getPayload($test);
    my ($header, $values) = unpack('H12H192', $payload);
    is($header, 'ffffffffffff', "payload header for $test");
    is($values, lc($test) x 16, "payload values for $test");
}

SKIP: {
    skip 'thread support required', $plan_with_threads
        if (!$Config{usethreads} || $Config{usethreads} ne 'define');

    my $module = Test::MockModule->new(
        'GLPI::Agent::Tools::Win32'
    );

    foreach my $sample (keys %interfaceid_tests) {
        $module->mock(
            'getRegistryKey',
            mockGetRegistryKey($sample)
        );

        foreach my $pnpid (keys %{$interfaceid_tests{$sample}}) {
            is(
                GLPI::Agent::Task::WakeOnLan->_getWin32InterfaceId(
                    $pnpid
                ),
                $interfaceid_tests{$sample}->{$pnpid},
                "sample $sample, device $pnpid"
            );
        }
    }
}
