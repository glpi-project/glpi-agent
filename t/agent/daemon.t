#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use File::Path;
use File::Temp qw(tempdir);
use Test::Deep;
use Test::More;

use FusionInventory::Agent;
use FusionInventory::Agent::Config;
use FusionInventory::Agent::Logger;
use FusionInventory::Agent::Daemon;

plan tests => 11;

my $agent = FusionInventory::Agent::Daemon->new(
    libdir  => './lib'
);
$agent->{datadir} = './share';
$agent->{vardir}  = './var',

# Reset config to be able to run init() method with mandatory options
delete $agent->{config};
my $options = {
    'local'     => '.',
    # Keep Test backend on logger as call to init() will reset logger
    'logger'    => 'Test',
    # we force config to be loaded from file
    'conf-file' => 'resources/config/sample1',
    'config'    => 'file',
    # avoid to daemonize and avoid httpd interface
    'service'   => 1,
    'no-httpd'  => 1,
};

$agent->init(options => $options);

# But emulate this is a real conf by removing options backup
delete $agent->{config}->{_options};

# after init call, the member 'config' is defined and well blessed
ok (ref($agent->{config}) eq 'FusionInventory::Agent::Config');
ok (defined($agent->{config}->{'conf-file'}));
ok (scalar(@{$agent->{config}->{'no-task'}}) == 2);

# changing conf-file
$agent->{config}->{'conf-file'} = 'resources/config/daemon1';

# Test agent daemon reinit
$agent->reinit();

ok (defined($agent->{config}->{'no-task'}));
ok (scalar(@{$agent->{config}->{'no-task'}}) == 2);
ok (
    ($agent->{config}->{'no-task'}->[0] eq 'snmpquery' && $agent->{config}->{'no-task'}->[1] eq 'wakeonlan')
        || ($agent->{config}->{'no-task'}->[1] eq 'snmpquery' && $agent->{config}->{'no-task'}->[0] eq 'wakeonlan')
);
# Targets are Server target + associated Scheduler target
ok (scalar($agent->getTargets()) == 2);

SKIP: {
    skip ('test for Windows only and with config in registry', 4)
        if ($OSNAME ne 'MSWin32' || $agent->{config}->{config} ne 'registry');

    my $testKey = 'tag';
    my $testValue = 'TEST_REGISTRY_VALUE';
    # change value in registry
    my $settingsInRegistry = FusionInventory::Test::Utils::openWin32Registry();
    $settingsInRegistry->{$testKey} = $testValue;

    my $keyInitialValue = $agent->{config}->{$testKey};
    $agent->{config}->{config} = 'registry';
    $agent->{config}->{'conf-file'} = '';
    ok ($agent->{config}->{config} eq 'registry');
    $agent->reinit();
    # key config must be set
    ok (defined $agent->{config}->{$testKey});
    # and must be the value set in registry
    ok ($agent->{config}->{$testKey} eq $testValue);

    # delete value in registry
    delete $settingsInRegistry->{$testKey};
    $agent->reinit();
    # must have default value which is initial value
    ok ($agent->{config}->{$testKey} eq $keyInitialValue);
}
