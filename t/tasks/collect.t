#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';
use File::Temp qw(tempdir);

use Test::Exception;
use Test::More;
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

my $task = undef ;

my %params = ();

my $plan = 16;

plan tests => $plan;

# Redefine send API for testing to simulate server answer without really sending
# 'user' task config is used to define the current test and simulate the expected answer
sub _send {
    my ($self, %params) = @_;
    my ($test, $remtest) = $self->{user} =~ /^([^:]+):?([^:]+)?$/;
    die 'communication error' if !$test || $test eq 'nocomm';
    die 'no arg to send' unless exists($params{args});

    my %response = (
        getConfig   => {
            emptyresponse       =>  {},
            malformedschedule   =>  {
                                        schedule => {}
                                    },
            emptyschedule       =>  {
                                        schedule => []
                                    },
            badschedule         =>  {
                                        schedule => [{}]
                                    },
            normalschedule      =>  {
                                        schedule => [
                                            {
                                                task => 'Collect'
                                            }
                                        ]
                                    },
            normalschedulewithremoteurl =>  {
                                        schedule => [
                                            {
                                                task => 'Collect',
                                                remote => 'xxx'
                                            }
                                        ]
                                    },
        },
        getJobs     => {
            nojob               =>  {},
            'badjson-1'         =>  'bad',
            'badjson-2'         =>  {
                                        bad => ''
                                    },
            'badjson-3'         =>  {
                                        jobs => ''
                                    },
            'badjson-4'         =>  {
                                        jobs => [ {} ]
                                    },
            'badjson-5'         =>  {
                                        jobs => [
                                            {
                                                uuid => ''
                                            }
                                        ]
                                    },
            'badjson-6'         =>  {
                                        jobs => [
                                            {
                                                uuid     => '',
                                                function => ''
                                            }
                                        ]
                                    },
            'unexpected-nojob'  =>  {
                                        jobs => []
                                    }
        }
    );
    return $response{$params{args}->{action}}->{
        $params{args}->{action} eq 'getJobs' ? $remtest : $test
    };
}

my $module = Test::MockModule->new('GLPI::Agent::HTTP::Client::Fusion');
$module->mock('send',\&_send);

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
is( $target->getUrl(), 'http://localhost/glpi-any' );

# We will directly update client config before run() to configure test to run
my $test_config = $task->{config};

throws_ok {
    $test_config->{user} = 'nocomm';
    $task->run();
} qr/communication error/, "Normal error if target is unavailable" ;

throws_ok {
    $test_config->{user} = 'emptyresponse';
    $task->run();
} qr/No job schedule returned/, "Info returned on empty response" ;

throws_ok {
    $test_config->{user} = 'malformedschedule';
    $task->run();
} qr/Malformed schedule/, "Info returned on malformed schedule" ;

throws_ok {
    $test_config->{user} = 'emptyschedule';
    $task->run();
} qr/No Collect job enabled/, "Info returned on empty schedule" ;

throws_ok {
    $test_config->{user} = 'badschedule';
    $task->run();
} qr/No Collect job found/, "Info returned with bad job schedule" ;

lives_ok {
    $test_config->{user} = 'normalschedule';
    $task->run();
} "Normal schedule" ;

throws_ok {
    $test_config->{user}     = 'normalschedulewithremoteurl:nojob';
    $task->run();
} qr/Nothing to do/, "No job scheduled" ;

throws_ok {
    $test_config->{user}     = 'normalschedulewithremoteurl:badjson-1';
    $task->run();
} qr/Bad JSON.*Bad answer/, "Badly formatted job - case 1" ;

throws_ok {
    $test_config->{user}     = 'normalschedulewithremoteurl:badjson-2';
    $task->run();
} qr/Bad JSON.*Missing jobs/, "Badly formatted job - case 2" ;

throws_ok {
    $test_config->{user}     = 'normalschedulewithremoteurl:badjson-3';
    $task->run();
} qr/Bad JSON.*Missing jobs/, "Badly formatted job - case 3" ;

throws_ok {
    $test_config->{user}     = 'normalschedulewithremoteurl:badjson-4';
    $task->run();
} qr/Bad JSON.*Missing key/, "Badly formatted job - case 4" ;

throws_ok {
    $test_config->{user}     = 'normalschedulewithremoteurl:badjson-5';
    $task->run();
} qr/Bad JSON.*Missing key/, "Badly formatted job - case 5" ;

throws_ok {
    $test_config->{user}     = 'normalschedulewithremoteurl:badjson-6';
    $task->run();
} qr/Bad JSON.*not supported 'function' key/, "Badly formatted job - case 6" ;

throws_ok {
    $test_config->{user}     = 'normalschedulewithremoteurl:unexpected-nojob';
    $task->run();
} qr/no jobs provided/, "No job included in jobs key" ;
