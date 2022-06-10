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

my %tests = (
    FF1 => {
        OK   => 'no',
        description => "Missing mandatory recursive value",
        getJobs => {
            jobs => [
                {
                    uuid     => '',
                    function => 'findFile',
                    dir      => '',
                    limit    => 0,
                    filter   => {
                        is_file => 0,
                        is_dir  => 0
                    }
                }
            ]
        },
        expected => qr/mandatory value is missing/
    },
    FF2 => {
        OK   => 'no',
        description => "Missing mandatory dir value",
        getJobs => {
            jobs => [
                {
                    uuid      => '',
                    function  => 'findFile',
                    recursive => '',
                    limit     => 0,
                    filter    => {
                        is_file => 0,
                        is_dir  => 0
                    }
                }
            ]
        },
        expected => qr/mandatory value is missing/
    },
    FF3 => {
        OK   => 'no',
        description => "Missing mandatory limit value",
        getJobs => {
            jobs => [
                {
                    uuid      => '',
                    function  => 'findFile',
                    recursive => '',
                    dir       => '.',
                    filter    => {
                        is_file => 0,
                        is_dir  => 0
                    }
                }
            ]
        },
        expected => qr/mandatory value is missing/
    },
    FF4 => {
        OK   => 'no',
        description => "Missing mandatory filter value",
        getJobs => {
            jobs => [
                {
                    uuid      => '',
                    function  => 'findFile',
                    recursive => '',
                    dir       => '.',
                    limit     => 0
                }
            ]
        },
        expected => qr/mandatory values are missing/
    },
    FF5 => {
        OK   => 'no',
        description => "Missing mandatory is_dir value",
        getJobs => {
            jobs => [
                {
                    uuid      => '',
                    function  => 'findFile',
                    recursive => '',
                    dir       => '.',
                    limit     => 0,
                    filter    => {
                        is_file => 0
                    }
                }
            ]
        },
        expected => qr/mandatory value is missing/
    },
    FF6 => {
        OK   => 'no',
        description => "Missing mandatory is_file value",
        getJobs => {
            jobs => [
                {
                    uuid      => '',
                    function  => 'findFile',
                    recursive => '',
                    dir       => '.',
                    limit     => 0,
                    filter    => {
                        is_dir  => 0
                    }
                }
            ]
        },
        expected => qr/mandatory value is missing/
    },
    FF7 => {
        OK   => 'no',
        description => "Missing mandatory job UUID value",
        getJobs => {
            jobs => [
                {
                    uuid      => '',
                    function  => 'findFile',
                    recursive => '',
                    dir       => '.',
                    limit     => 0,
                    filter    => {
                        is_file => 0,
                        is_dir  => 0
                    }
                }
            ]
        },
        expected => qr/UUID key missing/
    }
);

# Redefine send API for testing to simulate server answer without really sending
# 'user' task config is used to define the current test and simulate the expected answer
sub _send {
    my ($self, %params) = @_;
    my $test = $self->{user} || '' ;
    die 'communication error' if ($test eq 'nocomm');
    die 'no arg to send' unless exists($params{args});
    die 'no such test' unless exists($tests{$test});
    if ($params{args}->{action} eq 'getConfig') {
        return {
            schedule => [
                {
                    task   => 'Collect',
                    remote => 'http://somewhere/glpi/plugins/fusioninventory/b/collect/'
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

plan tests => 1 + scalar(keys(%tests)) + 2*scalar(grep { $_->{OK} eq 'yes' } values(%tests));

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

foreach my $test (sort keys %tests) {
    if ($tests{$test}->{OK} eq 'yes') {
        lives_ok {
            $task->{config}->{user} = $test;
            $task->run();
        } "Test $test: ".$tests{$test}->{description} ;
        cmp_deeply( $tests{$test}->{setAnswer}, $tests{$test}->{results}, "$test results")
            || diag explain $tests{$test}->{setAnswer};
        is( scalar(@{$tests{$test}->{setAnswer}}), $tests{$test}->{count}, "$test results count");
    } else {
        throws_ok {
            $task->{config}->{user} = $test;
            $task->run();
        } $tests{$test}->{expected},
            "Test $test: ".$tests{$test}->{description} ;
    }
}

1
