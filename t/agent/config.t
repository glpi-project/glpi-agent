#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::Deep;
use Test::More;
use Storable;
use UNIVERSAL;

use FusionInventory::Agent::Config;
use lib 't/lib';
use FusionInventory::Test::Utils;

my %config = (
    sample1 => {
        'no-task'     => ['snmpquery', 'wakeonlan'],
        'no-category' => [],
        'httpd-trust' => [],
        'tasks'       => ['inventory', 'deploy', 'inventory'],
        'conf-reload-interval' => 0
    },
    sample2 => {
        'no-task'     => [],
        'no-category' => ['printer'],
        'httpd-trust' => ['example', '127.0.0.1', 'foobar', '123.0.0.0/10'],
        'conf-reload-interval' => 0
    },
    sample3 => {
        'no-task'     => [],
        'no-category' => [],
        'httpd-trust' => [],
        'conf-reload-interval' => 3600
    },
    sample4 => {
        'no-task'     => ['snmpquery','wakeonlan','inventory'],
        'no-category' => [],
        'httpd-trust' => [],
        'tasks'       => ['inventory', 'deploy', 'inventory'],
        'conf-reload-interval' => 60
    },
    include7 => {
        'tag'         => "include7",
        'logfile'     => $OSNAME eq 'MSWin32' ? "C:\\tmp\\logfile.txt" : "/tmp/logfile.txt",
        'timeout'     => 16,
        'no-task'     => [],
        'no-category' => [],
        'httpd-trust' => [],
        'conf-reload-interval' => 0
    },
    include8 => {
        'tag'     => "include8",
        'logfile' => "",
        'timeout' => 16,
        'no-task'     => [],
        'no-category' => [],
        'httpd-trust' => [],
        'conf-reload-interval' => 0
    }
);

my %include = (
    include1 => {
        'tag'       => 'include2',
        'timeout'   => 12
    },
    include2 => {
        'tag'       => 'txt-include',
        'timeout'   => 99
    },
    include3 => {
        'tag'       => 'include3',
        'timeout'   => 15
    },
    include4 => {
        'tag'       => 'loop',
        'timeout'   => 77
    },
    include5 => {
        'tag'       => 'include5',
        'timeout'   => 1
    },
    include6 => {
        'tag'       => 'include2',
        'timeout'   => 16
    }
);

plan tests => (scalar keys %config) * 4 + (scalar keys %include) * 2 + 40;

foreach my $test (keys %config) {
    my $c = FusionInventory::Agent::Config->new(options => {
        'conf-file' => "resources/config/$test"
    });

    foreach my $k (qw/ no-task no-category httpd-trust conf-reload-interval logfile /) {
        cmp_deeply($c->{$k}, $config{$test}->{$k}, $test." ".$k);
    }

    if ($test eq 'sample1') {
        ok ($c->isParamArrayAndFilled('no-task'));
        ok (! $c->isParamArrayAndFilled('no-category'));
        ok (! $c->isParamArrayAndFilled('httpd-trust'));
        ok ($c->isParamArrayAndFilled('tasks'));
    } elsif ($test eq 'sample2') {
        ok (! $c->isParamArrayAndFilled('no-task'));
        ok ($c->isParamArrayAndFilled('no-category'));
        ok ($c->isParamArrayAndFilled('httpd-trust'));
        ok (! $c->isParamArrayAndFilled('tasks'));
    } elsif ($test eq 'sample3') {
        ok (! $c->isParamArrayAndFilled('no-task'));
        ok (! $c->isParamArrayAndFilled('no-category'));
        ok (! $c->isParamArrayAndFilled('httpd-trust'));
        ok (! $c->isParamArrayAndFilled('tasks'));
    } elsif ($test eq 'sample4') {
        ok ($c->isParamArrayAndFilled('no-task'));
        ok (! $c->isParamArrayAndFilled('no-category'));
        ok (! $c->isParamArrayAndFilled('httpd-trust'));
        ok ($c->isParamArrayAndFilled('tasks'));
    }
}

foreach my $test (keys %include) {
    my $cfg = FusionInventory::Agent::Config->new(
        options => {
            'conf-file' => "resources/config/$test"
        }
    );
    # Reload cfg to validate loadedConfs has been reset between loads
    $cfg->reload();

    foreach my $k (qw/ tag timeout /) {
        is($cfg->{$k}, $include{$test}->{$k}, $test." ".$k);
    }
}

my $c = FusionInventory::Agent::Config->new(options => {
        'conf-file' => "resources/config/sample1"
    });
ok (ref($c->{'no-task'}) eq 'ARRAY');
ok (scalar(@{$c->{'no-task'}}) == 2);

$c->reload();
ok (ref($c->{'no-task'}) eq 'ARRAY');
ok (scalar(@{$c->{'no-task'}}) == 2);

$c->{'conf-file'} = "resources/config/sample2";
$c->reload();
my %cNoCategory = map {$_ => 1} @{$c->{'no-category'}};
ok (defined($cNoCategory{'printer'}));
ok (scalar(@{$c->{'no-category'}}) == 1, 'structure size is ' . scalar(@{$c->{'no-category'}}));
#httpd-trust=example,127.0.0.1,foobar,123.0.0.0/10
my %cHttpdTrust = map {$_ => 1} @{$c->{'httpd-trust'}};
ok (defined($cHttpdTrust{'example'}));
ok (defined($cHttpdTrust{'127.0.0.1'}));
ok (defined($cHttpdTrust{'foobar'}));
ok (defined($cHttpdTrust{'123.0.0.0/10'}));
ok (scalar(@{$c->{'httpd-trust'}}) == 4);

SKIP: {
    skip ('test for Windows only', 7) if ($OSNAME ne 'MSWin32');
    my $settings = FusionInventory::Test::Utils::openWin32Registry();
    ok (defined $settings);
    my $testValue = time;
    $settings->{'TEST_KEY'} = $testValue;

    my $settingsRead = FusionInventory::Test::Utils::openWin32Registry();
    ok (defined $settingsRead);
    ok (defined $settingsRead->{'TEST_KEY'});
    ok ($settingsRead->{'TEST_KEY'} eq $testValue);

    # reset conf in registry
    my $deleted;
    if (defined $settings && defined $settings->{'TEST_KEY'}) {
        $deleted = delete $settings->{'TEST_KEY'};
    }
    ok (!(defined($settings->{'TEST_KEY'})));

    $settingsRead = undef;
    $settingsRead = FusionInventory::Test::Utils::openWin32Registry();
    ok (defined $settingsRead);
    ok (!(defined $settingsRead->{'TEST_KEY'}));
}
