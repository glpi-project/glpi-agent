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
use GLPI::Agent::Task::Collect;
use GLPI::Agent::Target::Server;

# Setup a target with a Fatal logger and no debug
my $logger = GLPI::Agent::Logger->new(
    logger => [ 'Fatal' ]
);

my $target = GLPI::Agent::Target::Server->new(
    url    => 'http://localhost/glpi-any',
    logger => $logger,
    basevardir => tempdir(CLEANUP => 1)
);

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
);

my %tests;
map { $tests{$_->{test}} = $_ } @tests;

# Redefine send API for testing to simulate server answer without really sending
# 'user' task config is used to define the current test and simulate the expected answer
sub _send {
    my ($self, %params) = @_;
    my $test = $self->{user} || '' ;
    die 'communication error' if $test eq 'nocomm';
    die 'no arg to send' unless exists($params{args});
    die 'no such test' unless exists($tests{$test});
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
            unless exists($tests{$test}->{setAnswer}) ;
        delete $params{args}->{uuid};
        delete $params{args}->{action};
        push @{$tests{$test}->{setAnswer}}, $params{args};
        return {} ;
    }
    die 'no expected test case';
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
        config => {
            jobs => []
        }
    );
} "Collect object instanciation" ;

foreach my $test (@tests) {
    my $name = $test->{test};
    if ($test->{OK} eq 'yes') {
        lives_ok {
            $task->{config}->{user} = $name;
            $task->run();
        } "Test $name: ".$test->{description} ;
        cmp_deeply( $test->{setAnswer}, $test->{results}, "$name results")
            || diag explain $test->{setAnswer};
        is( scalar(@{$test->{setAnswer}}), $test->{count}, "$name results count");
    } else {
        throws_ok {
            $task->{config}->{user} = $name;
            $task->run();
        } $test->{expected},
            "Test $name: ".$test->{description} ;
    }
}

1
