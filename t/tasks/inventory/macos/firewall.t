#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::MacOS::Firewall;


my $tests = [
    {
        launchctl    => {
            value => 8116,
            file  => 'launctl_list.txt'
        },
        procinfo     => {
            value => 1,
            file  => 'procinfo.txt'
        },
        defaultsRead => {
            value => 'on',
            file => 'defaults_read_preferences_com_alf_globalstate.txt'
        }
    },
    {
        launchctl    => {
            value => undef,
            file  => 'launctl_list_unloaded.txt'
        },
        procinfo     => {
            value => undef,
            file  => ''
        },
        defaultsRead => {
            value => 'off',
            file => 'defaults_read_preferences_com_alf_globalstate.txt'
        }
    }
];

plan tests => 1
        + (scalar (@$tests)) * 3;

my $pathToFiles = 'resources/macos/firewall/';
my $index = 0;
for my $test (@$tests) {
    my $pid = GLPI::Agent::Task::Inventory::MacOS::Firewall::_getFirewallServicePID(
        file => $pathToFiles . $test->{launchctl}->{file}
    );
    ok (
        (defined $pid && $pid == $test->{launchctl}->{value})
            || (not defined $pid && not defined $test->{launchctl}->{value}),
        'test '.$index.' : extracted pid'
    );

    my $runningState = GLPI::Agent::Task::Inventory::MacOS::Firewall::_checkRunning(
        file => $pathToFiles . $test->{procinfo}->{file},
        pid => $pid || undef
    );
    ok (
        (defined $runningState && $runningState == $test->{procinfo}->{value})
            || (not defined $runningState && not defined $test->{procinfo}->{value}),
        'test '.$index.' : extracted running state'
    );

    my $firewallStatus = GLPI::Agent::Task::Inventory::MacOS::Firewall::_getFirewallStatus(
        file => $pathToFiles . $test->{defaultsRead}->{file},
        pidFile => $pathToFiles . $test->{launchctl}->{file},
        runningFile => $pathToFiles . $test->{procinfo}->{file}
    );
    ok (defined $firewallStatus && $firewallStatus eq $test->{defaultsRead}->{value}, 'test ' . $index . ' : firewallStatus');
    $index++;
}
