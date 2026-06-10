#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib "t/lib";

use English qw(-no_match_vars);
use Test::Deep;
use Test::Exception;
use Test::MockModule;
use Test::More;
use Test::NoWarnings;
use UNIVERSAL::require;

use GLPI::Agent::Inventory;
use GLPI::Test::Utils;

BEGIN {
    # use mock modules for non-available ones
    push @INC, "t/lib/fake/windows" if $OSNAME ne "MSWin32";
}

GLPI::Agent::Task::Inventory::Win32::Controllers->require();

my %tests = (
    "microsoft-basic-display" => [
        {
            CAPTION        => "GeminiLake [UHD Graphics 600]",
            MANUFACTURER   => "Intel Corporation",
            NAME           => "GeminiLake [UHD Graphics 600]",
            PCISUBSYSTEMID => "0000:0000",
            PRODUCTID      => "3185",
            TYPE           => "Adaptador de Vídeo Básico da Microsoft",
            VENDORID       => "8086",
            PCISLOT        => "00:02.0",
        }
    ],
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Agent::Inventory->new();

my $module = Test::MockModule->new(
    "GLPI::Agent::Task::Inventory::Win32::Controllers"
);

my $tools_module = Test::MockModule->new(
    "GLPI::Agent::Tools::Win32"
);

foreach my $test (keys %tests) {
    $module->mock(
        "getWMIObjects",
        mockGetWMIObjects($test)
    );

    $tools_module->mock(
        "_getRegistryKey",
        mockGetRegistryKey($test)
    );

    my @controllers = GLPI::Agent::Task::Inventory::Win32::Controllers::_getControllers(
        datadir => "share",
    );
    cmp_deeply(
        \@controllers,
        $tests{$test},
        "$test: parsing"
    );
    lives_ok {
        $inventory->addEntry(section => "CONTROLLERS", entry => $_)
            foreach @controllers;
    } "$test: registering";
}
