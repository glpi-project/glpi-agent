#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';
use File::Temp qw(tempdir);

use Test::Exception;
use Test::More;
use Test::Deep qw(cmp_deeply);
use Test::MockModule;

use GLPI::Agent::Logger;
use GLPI::Agent::Logger::Test;
use GLPI::Agent::Config;
use GLPI::Agent::Task::Collect;
use GLPI::Agent::Target::Server;

use GLPI::Test::Utils;

# Setup a target with a Fatal logger and no debug
my $logger = GLPI::Agent::Logger->new(
    logger => [ 'Fatal' ]
);

my $target = GLPI::Agent::Target::Server->new(
    url    => 'http://localhost/glpi-any',
    logger => $logger,
    basevardir => tempdir(CLEANUP => 1)
);

my $fatal_logger = $target->{logger}->{backends};
my $test_logger  = [ GLPI::Agent::Logger::Test->new() ];

my @tests = (
    {
        test => 'wrong-job-1',
        OK   => 'no',
        description => "Missing mandatory value",
        getJobs => {
            jobs => [
                {
                    uuid     => '',
                    function => 'getFromRegistry',
                    limit    => 0
                }
            ]
        },
        expected => qr/mandatory value is missing/
    },
    {
        test => 'wrong-job-2',
        OK   => 'no',
        description => "Missing mandatory function",
        getJobs => {
            jobs => [
                {
                    uuid      => '',
                    path      => '.',
                    limit     => 0
                }
            ]
        },
        expected => qr/Missing key 'function' in job/
    },
    {
        test => 'wrong-job-3',
        OK   => 'no',
        description => "Missing mandatory limit value",
        getJobs => {
            jobs => [
                {
                    uuid      => '',
                    function  => 'getFromRegistry',
                    path      => '.'
                }
            ]
        },
        expected => qr/UUID key missing/
    },
    {
        test => 'registry-value',
        OK   => 'yes',
        description => "Get simple registry value",
        getJobs => {
            token => '3124359129826ef5793832ab220ad8e7800ff1b3b89b9f21745ecc69a65a6cd7',
            jobs => [
                {
                    _sid     => '1',
                    uuid     => '5ed28c29f1d78c60dc122f597af58862',
                    function => 'getFromRegistry',
                    path     => 'HKEY_LOCAL_MACHINE/SOFTWARE\\GLPI-Agent/httpd-port'
                }
            ]
        },
        # registry sample file
        _registry => "glpi-agent-audit-test",
        _subkey   => "GLPI-Agent",
        # expected results and value count
        results => [
            {
                _cpt             => '1',
                _sid             => '1',
                uuid             => '5ed28c29f1d78c60dc122f597af58862',
                'httpd-port'     => '62354',
                action           => 'setAnswer',
                _glpi_csrf_token => '3124359129826ef5793832ab220ad8e7800ff1b3b89b9f21745ecc69a65a6cd7',
            },
        ],
        count   => 1,
    },
    {
        test => 'registry-key-exists',
        OK   => 'yes',
        description => "Check registry key exists",
        getJobs => {
            token => '3124359129826ef5793832ab220ad8e7800ff1b3b89b9f21745ecc69a65a6cd7',
            jobs => [
                {
                    _sid     => '1',
                    uuid     => '5ed28c29f1d78c60dc122f597af58862',
                    function => 'getFromRegistry',
                    exists   => '1',
                    path     => 'HKEY_LOCAL_MACHINE/SOFTWARE/GLPI-Agent'
                }
            ]
        },
        # registry sample file
        _registry => "glpi-agent-audit-test",
        _subkey   => "GLPI-Agent",
        # expected results and value count
        results => [
            {
                _cpt             => '1',
                _sid             => '1',
                uuid             => '5ed28c29f1d78c60dc122f597af58862',
                _exists          => '1',
                action           => 'setAnswer',
                _glpi_csrf_token => '3124359129826ef5793832ab220ad8e7800ff1b3b89b9f21745ecc69a65a6cd7',
            },
        ],
        count   => 1,
    },
    {
        test => 'registry-key-does-not-exist',
        OK   => 'yes',
        description => "Check registry key doesn't exist",
        getJobs => {
            token => '3124359129826ef5793832ab220ad8e7800ff1b3b89b9f21745ecc69a65a6cd7',
            jobs => [
                {
                    _sid     => '1',
                    uuid     => '5ed28c29f1d78c60dc122f597af58862',
                    function => 'getFromRegistry',
                    exists   => '1',
                    path     => 'HKEY_LOCAL_MACHINE/SOFTWARE\\GLPI-Agent/not-a-key'
                }
            ]
        },
        # registry sample file
        _registry => "glpi-agent-audit-test",
        _subkey   => "GLPI-Agent\\not-a-key",
        # expected results and value count
        results => [
            {
                _cpt             => '1',
                _sid             => '1',
                uuid             => '5ed28c29f1d78c60dc122f597af58862',
                _exists          => '0',
                action           => 'setAnswer',
                _glpi_csrf_token => '3124359129826ef5793832ab220ad8e7800ff1b3b89b9f21745ecc69a65a6cd7',
            },
        ],
        count   => 1,
    },
    {
        test => 'registry-value-defined',
        OK   => 'yes',
        description => "Check registry value is defined",
        getJobs => {
            token => '3124359129826ef5793832ab220ad8e7800ff1b3b89b9f21745ecc69a65a6cd7',
            jobs => [
                {
                    _sid     => '1',
                    uuid     => '5ed28c29f1d78c60dc122f597af58862',
                    function => 'getFromRegistry',
                    defined  => '1',
                    path     => 'HKEY_LOCAL_MACHINE/SOFTWARE\\GLPI-Agent/httpd-port'
                }
            ]
        },
        # registry sample file
        _registry => "glpi-agent-audit-test",
        _subkey   => "GLPI-Agent",
        # expected results and value count
        results => [
            {
                _cpt             => '1',
                _sid             => '1',
                uuid             => '5ed28c29f1d78c60dc122f597af58862',
                _defined         => '1',
                action           => 'setAnswer',
                _glpi_csrf_token => '3124359129826ef5793832ab220ad8e7800ff1b3b89b9f21745ecc69a65a6cd7',
            },
        ],
        count   => 1,
    },
    {
        test => 'registry-value-is-not-defined',
        OK   => 'yes',
        description => "Check registry value isn't defined",
        getJobs => {
            token => '3124359129826ef5793832ab220ad8e7800ff1b3b89b9f21745ecc69a65a6cd7',
            jobs => [
                {
                    _sid     => '1',
                    uuid     => '5ed28c29f1d78c60dc122f597af58862',
                    function => 'getFromRegistry',
                    defined  => '1',
                    path     => 'HKEY_LOCAL_MACHINE/SOFTWARE\\GLPI-Agent/not-a-value'
                }
            ]
        },
        # registry sample file
        _registry => "glpi-agent-audit-test",
        _subkey   => "GLPI-Agent",
        # expected results and value count
        results => [
            {
                _cpt             => '1',
                _sid             => '1',
                uuid             => '5ed28c29f1d78c60dc122f597af58862',
                _defined         => '0',
                action           => 'setAnswer',
                _glpi_csrf_token => '3124359129826ef5793832ab220ad8e7800ff1b3b89b9f21745ecc69a65a6cd7',
            },
        ],
        count   => 1,
    },
    {
        test => 'registry-depth-0',
        OK   => 'yes',
        description => "Recurvice registry collect",
        getJobs => {
            token => '3124359129826ef5793832ab220ad8e7800ff1b3b89b9f21745ecc69a65a6cd7',
            jobs => [
                {
                    _sid     => '1',
                    uuid     => '5ed28c29f1d78c60dc122f597af58862',
                    function => 'getFromRegistry',
                    depth    => '0',
                    path     => 'HKEY_LOCAL_MACHINE/SYSTEM\\CurrentControlSet\\Services\\SharedAccess\\Parameters/FirewallPolicy'
                }
            ]
        },
        # registry sample file
        _registry => "10-DomainProfile",
        # expected results and value count
        results => [
            {
                _cpt             => '2',
                _sid             => '1',
                uuid             => '5ed28c29f1d78c60dc122f597af58862',
                _path            => 'DisableNotifications',
                _value           => '0x00000000',
                action           => 'setAnswer',
                _glpi_csrf_token => '3124359129826ef5793832ab220ad8e7800ff1b3b89b9f21745ecc69a65a6cd7',
            },
            {
                _cpt             => '1',
                _sid             => '1',
                uuid             => '5ed28c29f1d78c60dc122f597af58862',
                _path            => 'EnableFirewall',
                _value           => '0x00000001',
                action           => 'setAnswer',
                _glpi_csrf_token => '2f20c12158d04efb4b9f1ee64c67e53b8041c680775dfeee208976cb9aa90e32',
            },
        ],
        count   => 2,
    },
    {
        test => 'registry-depth-1',
        OK   => 'yes',
        description => "Recurvice registry collect",
        getJobs => {
            token => '3124359129826ef5793832ab220ad8e7800ff1b3b89b9f21745ecc69a65a6cd7',
            jobs => [
                {
                    _sid     => '1',
                    uuid     => '5ed28c29f1d78c60dc122f597af58862',
                    function => 'getFromRegistry',
                    depth    => '1',
                    path     => 'HKEY_LOCAL_MACHINE/SYSTEM\\CurrentControlSet\\Services\\SharedAccess\\Parameters/FirewallPolicy'
                }
            ]
        },
        # registry sample file
        _registry => "10-DomainProfile",
        # expected results and value count
        results => [
            {
                _cpt             => '5',
                _sid             => '1',
                uuid             => '5ed28c29f1d78c60dc122f597af58862',
                _path            => 'DisableNotifications',
                _value           => '0x00000000',
                action           => 'setAnswer',
                _glpi_csrf_token => '3124359129826ef5793832ab220ad8e7800ff1b3b89b9f21745ecc69a65a6cd7',
            },
            {
                _cpt             => '4',
                _sid             => '1',
                uuid             => '5ed28c29f1d78c60dc122f597af58862',
                _path            => 'EnableFirewall',
                _value           => '0x00000001',
                action           => 'setAnswer',
                _glpi_csrf_token => '2f20c12158d04efb4b9f1ee64c67e53b8041c680775dfeee208976cb9aa90e32',
            },
            {
                _cpt             => '3',
                _sid             => '1',
                uuid             => '5ed28c29f1d78c60dc122f597af58862',
                _path            => 'Logging/LogDroppedPackets',
                _value           => '0x00000000',
                action           => 'setAnswer',
                _glpi_csrf_token => '2f20c12158d04efb4b9f1ee64c67e53b8041c680775dfeee208976cb9aa90e32',
            },
            {
                _cpt             => '2',
                _sid             => '1',
                uuid             => '5ed28c29f1d78c60dc122f597af58862',
                _path            => 'Logging/LogFileSize',
                _value           => '0x00001000',
                action           => 'setAnswer',
                _glpi_csrf_token => '2f20c12158d04efb4b9f1ee64c67e53b8041c680775dfeee208976cb9aa90e32',
            },
            {
                _cpt             => '1',
                _sid             => '1',
                uuid             => '5ed28c29f1d78c60dc122f597af58862',
                _path            => 'Logging/LogSuccessfulConnections',
                _value           => '0x00000000',
                action           => 'setAnswer',
                _glpi_csrf_token => '2f20c12158d04efb4b9f1ee64c67e53b8041c680775dfeee208976cb9aa90e32',
            },
        ],
        count   => 5,
    },
);

my %tests;
map { $tests{$_->{test}} = $_ } @tests;

# Redefine send API for testing to simulate server answer without really sending
# 'user' task config is used to define the current test and simulate the expected answer
sub _send {
    my ($self, %params) = @_;
    my $test = $self->{user} || '' ;
    die "communication error\n" if $test eq 'nocomm';
    die "no arg to send\n" unless exists($params{args});
    die "no such test\n" unless exists($tests{$test});
    if ($params{args}->{action} eq 'getConfig') {
        return {
            schedule => [
                {
                    task   => 'Collect',
                    remote => 'http://somewhere/glpi/plugins/glpiinventory/b/collect/'
                }
            ]
        };
    } elsif ($params{args}->{action} eq 'getJobs') {
        return $tests{$test}->{getJobs} ;
    } elsif ($params{args}->{action} eq 'setAnswer') {
        $tests{$test}->{setAnswer} = []
            unless exists($tests{$test}->{setAnswer});
        push @{$tests{$test}->{setAnswer}}, $params{args};
        return {
            token => '2f20c12158d04efb4b9f1ee64c67e53b8041c680775dfeee208976cb9aa90e32',
        };
    } elsif ($params{args}->{action} eq 'jobsDone') {
        return {} ;
    }
    die "no expected test case\n";
}

my $module = Test::MockModule->new('GLPI::Agent::HTTP::Client::Fusion');
$module->mock('send',\&_send);

plan tests => 1 + scalar(grep { defined } @tests) + 2*scalar(grep { $_->{OK} eq 'yes' } @tests);

my $task = undef ;
lives_ok {
    $task = GLPI::Agent::Task::Collect->new(
        target => $target,
        # Still use Collect logger with Fatal logger, but now using debug level
        logger => GLPI::Agent::Logger->new( 'debug' => 1 ),
        config => GLPI::Agent::Config->new(),
    );
} "Collect object instanciation" ;

my $tools_module = Test::MockModule->new(
    "GLPI::Agent::Tools::Win32"
);

foreach my $test (@tests) {
    my $name = $test->{test};

    if ($test->{OK} eq 'yes') {
        # We no more expect a fatal error on sending so use test logger backend
        $task->{logger}->{backends} = $test_logger;
        $tools_module->mock(
            "_getRegistryKey",
            sub {
                my $key = loadRegistryDump("resources/win32/registry/$test->{_registry}.reg")
                    or die "Failed to load: resources/win32/registry/$test->{_registry}.reg\n";
                return $key unless $test->{_subkey};
                return $key->{"$test->{_subkey}/"};
            }
        );
        lives_ok {
            $task->{config}->{user} = $name;
            $task->run();
        } "Test $name: ".$test->{description} ;
        cmp_deeply( $test->{setAnswer}, $test->{results}, "$name results")
            || diag explain $test->{setAnswer};
        is( scalar(@{$test->{setAnswer}}), $test->{count}, "$name results count");
    } else {
        # Expect a log from send api so catch it with fatal logger
        $task->{logger}->{backends} = $fatal_logger;
        throws_ok {
            $task->{config}->{user} = $name;
            $task->run();
        } $test->{expected},
            "Test $name: ".$test->{description} ;
    }
}

1
