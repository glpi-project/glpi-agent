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

plan tests => 10;

# Mock has_file and has_folder to look in our test directory instead of the real C:/Program Files/DWAgent
my $test_base = "resources/generic/dwservice";

# Mock getRegistryKey for Win32
my $win32_module = Test::MockModule->new(
    'GLPI::Agent::Tools::Win32'
);
$win32_module->mock(
    '_getRegistryKey',
    sub {
        return loadRegistryDump("$test_base/dwservice-win32-uninstall.reg");
    }
);

# Mock tools
my $tools_module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::DWService'
);

$tools_module->mock(
    'has_folder',
    sub {
        my ($path) = @_;
        return 1 if $path eq 'C:\Program Files\DWAgent';
        return 1 if $path eq '/usr/share/dwagent';
        return 1 if $path eq '/Library/DWAgent';
        return $tools_module->original('has_folder')->($path);
    }
);

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
        # Map Linux paths
        if ($file eq '/etc/dwagent') {
            return 1;
        }
        if ($file eq '/usr/share/dwagent/config.json') {
            return 1;
        }
        if ($file eq '/usr/share/dwagent/sharedmem/status_config.shm') {
            return 1;
        }
        # Map macOS paths
        if ($file eq '/Library/LaunchDaemons/net.dwservice.agsvc.plist') {
            return 1;
        }
        if ($file eq '/Library/DWAgent/config.json') {
            return 1;
        }
        if ($file eq '/Library/DWAgent/sharedmem/status_config.shm') {
            return 1;
        }
        return $tools_module->original('has_file')->($file);
    }
);

$tools_module->mock(
    'getAllLines',
    sub {
        my (%params) = @_;
        my $file = $params{file};
        if ($file && $file eq '/etc/dwagent') {
            $params{file} = "$test_base/linux/etc-dwagent";
        }
        if ($file && ($file eq 'C:\Program Files\DWAgent/config.json' || $file eq 'C:\Program Files\DWAgent\config.json'
                || $file eq '/usr/share/dwagent/config.json' || $file eq '/Library/DWAgent/config.json')) {
            $params{file} = "$test_base/config.json";
        }
        if ($file && ($file eq 'C:\Program Files\DWAgent/sharedmem/status_config.shm' || $file eq 'C:\Program Files\DWAgent\sharedmem\status_config.shm'
                || $file eq '/usr/share/dwagent/sharedmem/status_config.shm' || $file eq '/Library/DWAgent/sharedmem/status_config.shm')) {
            $params{file} = "$test_base/sharedmem/status_config.shm";
        }
        if ($file && $file eq '/Library/LaunchDaemons/net.dwservice.agsvc.plist') {
            $params{file} = "$test_base/macos/net.dwservice.agsvc.plist";
        }
        return $tools_module->original('getAllLines')->(%params);
    }
);

# mock OSNAME correctly
my $mock_osname = 'MSWin32';
$tools_module->mock(
    'OSNAME',
    sub { return $mock_osname; }
);

# Use a test logger so debug messages don't crash the test
my $logger = GLPI::Agent::Logger->new(
    logger => [ 'Test' ]
);
my $inventory = GLPI::Agent::Inventory->new(logger => $logger);

# Test 1: isEnabled on Win32
{
    $mock_osname = 'MSWin32';
    ok(GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::DWService::isEnabled(), "DWService is enabled on Win32");
}

# Test 2 & 3: doInventory on Win32
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

# Test 4: isEnabled on Linux
{
    $mock_osname = 'linux';
    ok(GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::DWService::isEnabled(), "DWService is enabled on Linux");
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

# Test 7: isEnabled on macOS
{
    $mock_osname = 'darwin';
    ok(GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::DWService::isEnabled(), "DWService is enabled on macOS");
}

# Test 8 & 9: doInventory on macOS
{
    $mock_osname = 'darwin';
    my $inventory3 = GLPI::Agent::Inventory->new(logger => $logger);
    GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::DWService::doInventory(
        inventory => $inventory3,
        logger    => $logger
    );
    my $remotes3 = $inventory3->getSection('REMOTE_MGMT');
    is(scalar(@$remotes3), 1, "One remote mgmt entry found on macOS");
    cmp_deeply(
        $remotes3->[0],
        {
            ID   => 'TI - ANONYMOUS-188',
            TYPE => 'dwservice'
        },
        "Correct DWService data extracted on macOS"
    );
}
