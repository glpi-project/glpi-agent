#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use English qw(-no_match_vars);
use Test::Deep qw(cmp_deeply);
use Test::More;
use Test::MockModule;
use Test::NoWarnings;

use GLPI::Agent::Logger;
use GLPI::Agent::Inventory;
use GLPI::Test::Utils;
use GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::DWService;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

plan tests => 7;

# Mock getRegistryKey for Win32
my $win32_module = Test::MockModule->new(
    'GLPI::Agent::Tools::Win32'
);
$win32_module->mock(
    '_getRegistryKey',
    sub {
        return loadRegistryDump("t/resources/generic/dwservice/dwservice-win32-uninstall.reg");
    }
);

# Mock tools
my $tools_module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::DWService'
);
# Mock has_file and has_folder to look in our test directory instead of the real C:/Program Files/DWAgent
my $test_base = "t/resources/generic/dwservice";

$tools_module->mock(
    'has_folder',
    sub {
        my ($path) = @_;
        return 1 if $path eq 'C:\Program Files\DWAgent';
        return 1 if $path eq '/usr/share/dwagent';
        return $tools_module->original('has_folder')->($path);
    }
);

my $original_has_file = \&GLPI::Agent::Tools::has_file;
$tools_module->mock(
    'has_file',
    sub {
        my ($file) = @_;
        # Map Windows path
        if ($file eq 'C:\Program Files\DWAgent/config.json' || $file eq 'C:\Program Files\DWAgent\config.json') {
            return 1;
        }
        if ($file eq 'C:\Program Files\DWAgent/sharedmem/status_config.shm' || $file eq 'C:\Program Files\DWAgent\sharedmem\status_config.shm') {
            return 1;
        }
        # Map Unix path
        if ($file eq '/usr/share/dwagent/config.json') {
            return 1;
        }
        if ($file eq '/usr/share/dwagent/sharedmem/status_config.shm') {
            return 1;
        }
        return $tools_module->original('has_file')->($file);
    }
);

my $original_getAllLines = \&GLPI::Agent::Tools::getAllLines;
$tools_module->mock(
    'getAllLines',
    sub {
        my (%params) = @_;
        my $file = $params{file};
        if ($file && ($file eq 'C:\Program Files\DWAgent/config.json' || $file eq 'C:\Program Files\DWAgent\config.json' || $file eq '/usr/share/dwagent/config.json')) {
            $params{file} = "$test_base/config.json";
        }
        if ($file && ($file eq 'C:\Program Files\DWAgent/sharedmem/status_config.shm' || $file eq 'C:\Program Files\DWAgent\sharedmem\status_config.shm' || $file eq '/usr/share/dwagent/sharedmem/status_config.shm')) {
            $params{file} = "$test_base/sharedmem/status_config.shm";
        }
        return $tools_module->original('getAllLines')->(%params);
    }
);

# mock getProcesses for unix
my $unix_module = Test::MockModule->new(
    'GLPI::Agent::Tools::Unix'
);
$unix_module->mock(
    'getProcesses',
    sub {
        return (
            { CMD => '/usr/share/dwagent/native/dwagsvc' }
        );
    }
);

# mock OSNAME correctly
my $mock_osname = 'MSWin32';
$tools_module->mock(
    'OSNAME',
    sub { return $mock_osname; }
);

# Use a standard logger with Stderr backend so debug messages don't crash the test
my $logger = GLPI::Agent::Logger->new(
    config => {
        debug  => 2,
        logger => ['Stderr']
    }
);
my $inventory = GLPI::Agent::Inventory->new(logger => $logger);

# Test 1: isEnabled on Win32
{
    $mock_osname = 'MSWin32';
    ok(GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::DWService::isEnabled(), "DWService is enabled on Win32");
}

# Test 2: isEnabled on Linux
{
    $mock_osname = 'linux';
    ok(GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::DWService::isEnabled(), "DWService is enabled on Linux");
}

# Test 3 & 4: doInventory on Win32
{
    $mock_osname = 'MSWin32';
    GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::DWService::doInventory(
        inventory => $inventory,
        logger    => $logger
    );
    my $remotes = $inventory->getSection('REMOTE_MGMT');
    is(scalar(@$remotes), 1, "One remote mgmt entry found on Win32");
    cmp_deeply(
        $remotes->[0],
        {
            ID   => 'TI - ANONYMOUS-188',
            TYPE => 'dwservice'
        },
        "Correct DWService data extracted on Win32"
    );
}

# Test 5 & 6: doInventory on Linux
{
    $mock_osname = 'linux';
    my $inventory2 = GLPI::Agent::Inventory->new(logger => $logger);
    GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::DWService::doInventory(
        inventory => $inventory2,
        logger    => $logger
    );
    my $remotes2 = $inventory2->getSection('REMOTE_MGMT');
    is(scalar(@$remotes2), 1, "One remote mgmt entry found on Linux");
    cmp_deeply(
        $remotes2->[0],
        {
            ID   => 'TI - ANONYMOUS-188',
            TYPE => 'dwservice'
        },
        "Correct DWService data extracted on Linux"
    );
}
