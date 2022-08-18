#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use UNIVERSAL::require;
use File::Temp qw(tempdir);

use Test::Exception;
use Test::More;
use Test::MockModule;
use Test::Deep qw(cmp_deeply);
use Test::NoWarnings;

use GLPI::Agent;;
use GLPI::Agent::Logger;
use GLPI::Agent::Config;
use GLPI::Agent::Target;

GLPI::Agent::Task::RemoteInventory->use();

my $vardir = tempdir(CLEANUP => 1);

# Base config for a Test logger and debug
my %baseconfig = (
    logger  => 'Test',
    logfile => '', # Required when testing locally with registry set for an installed agent on win32
    debug   => 1,
    vardir  => $vardir,
);

my $agent = GLPI::Agent->new(
    datadir => tempdir(CLEANUP => 1),
    vardir  => $vardir,
    libdir  => 'blib/lib',
);

my $runs;

my $inventory_module = Test::MockModule->new('GLPI::Agent::Task::Inventory');
$inventory_module->mock('run', sub {});

# Store API is called while a remote has been processed
my $remotes_module = Test::MockModule->new('GLPI::Agent::Task::RemoteInventory::Remotes');
$remotes_module->mock('store', sub { $runs++ });

# Modify Ssh remote to do nothing
my $ssh_remote_module = Test::MockModule->new('GLPI::Agent::Task::RemoteInventory::Remote::Ssh');
$ssh_remote_module->mock('checking_error', sub { 0 });

my %test_cases = (
    notarget => {
        config  => {
            listen  => 1,
        },
        enabled => 0,
        runs    => 0,
    },
    "local-one-remote-in-config" => {
        config  => {
            local   => ".",
            remote  => "ssh://remote-1",
        },
        enabled => 1,
        runs    => 1,
    },
    "local-4-remotes-in-config" => {
        config  => {
            local   => ".",
            remote  => "ssh://remote-2,ssh://remote-3,ssh://remote-4,ssh://remote-5",
        },
        enabled => 1,
        runs    => 4,
    },
    "local-20-remotes-in-config-with-5-workers" => {
        config  => {
            local               => ".",
            remote              => join(",", map { "ssh://remote-$_"} 6..25),
            'remote-workers'    => 5,
        },
        enabled => 1,
        runs    => 20,
    },
);

plan tests => 3 * (scalar keys %test_cases) + 2;

foreach my $test_case (sort keys(%test_cases)) {

    my $test = $test_cases{$test_case};
    $runs = 0;

    # Forget agent configuration
    delete $agent->{config};

    $agent->init(
        options => {
            %baseconfig,
            %{$test->{config}}
        }
    );

    my $task;
    lives_ok {
        $task = GLPI::Agent::Task::RemoteInventory->new(
            config       => $agent->{config},
            datadir      => $agent->{datadir},
            logger       => $agent->{logger},
            target       => $agent->{targets}->[0],
            deviceid     => $agent->{deviceid},
        );
    } "$test_case: create remoteinventory task";

    my $enabled = $task->isEnabled();

    is($enabled, $test->{enabled}, "$test_case: ".($test->{enabled} ? "enabled" : "disabled")." test");

    $runs = 0;
    $task->run();

    is($runs, $test->{runs}, "$test_case: runs count test");
}

# No remote has been stored in local storage
my $remotes = $agent->{vardir}."/__LOCAL__/remotes.dump";
ok(! -e $remotes, "No remotes.dump file in local target");
