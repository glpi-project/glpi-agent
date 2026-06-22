#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';
use File::Temp qw(tempdir);
use Data::Dumper;

use Test::Exception;
use Test::More;
use Test::Deep qw(cmp_deeply);
use Test::MockModule;

use GLPI::Agent::Logger;
use GLPI::Agent::Task::Collect;
use GLPI::Agent::Target::Server;

use GLPI::Agent::Task::Collect::File;

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

my @regex_compilation_tests;
foreach my $line (<DATA>) {
    chomp($line);

    # Ignore empty or comment lines
    next if $line =~ /^\s*$/ || $line =~ /^\s*#/;

    if ($line =~ /\s*(.+\S)\s*\<=>\s*(.+)\s*$/) {
        my ($regex, $expected) = ($1, $2);
        $expected =~ s/\s*#.*$//;
        $expected = eval($expected)
            or die "Wrong expected \@regex_compilation_tests result for '$regex': $@\n";
        push @regex_compilation_tests, [ $regex, $expected ];
    }
}
close(DATA);

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

plan tests => 1 +
    scalar(keys(%tests)) +
    2 * scalar(grep { $_->{OK} eq 'yes' } values(%tests)) +
    scalar(@regex_compilation_tests);

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

# Test GLPI::Agent::Task::Collect::File API
foreach my $test (@regex_compilation_tests) {
    my ($regex, $expected) = @{$test};
    # Use a clean logger on each test for errors test
    my $logger = GLPI::Agent::Logger->new(
        logger  => [ 'Test' ],
        debug   => 1
    );
    my $debug = [ "DEBUG:" ];
    my $search = GLPI::Agent::Task::Collect::File->new(logger => $logger);
    my $compiled = $search->_compiled_regex($regex, $debug);
    my $message = $logger->{backends}[0]->{message};
    my $level = $logger->{backends}[0]->{level};
    if (ref($expected) || ((!$level || $level eq "debug") && $expected ne '1')) {
        push @{$debug}, "$level: $message" if $level;
        is($compiled, $expected, "Regex '$regex' compilation unexpected error, ".(@{$debug} == 1 ? "" : Dumper($debug)));
    } else {
        my $test = "error[1]: $expected";
        is(
            substr($level."[".$compiled."]: ".$message, 0, length($test) > 11 ? length($test) : 10 + length($message)),
            $test,
            "Regex '$regex' compilation error didn't match expected one"
        );
    }
}

1

__DATA__

azertyuiop                              <=> qr/azertyuiop/
azert(?=t)yuiop                         <=> qr/azert(?=t)yuiop/
^(a+)+$                                 <=> qr/^(?>a+)+$/
^(a+)+b$                                <=> qr/^(?>a+)+b$/
(?>a+(b+)+)+b                           <=> qr/(?>a+(?>b+)+)+b/
(*atomic:a+(b+)+)+b                     <=> qr/(?>a+(?>b+)+)+b/
(a)(?:b|c)12(d)xx                       <=> qr/(?>a)(?>b|c)12(?>d)xx/
(a)(b|c){12}(d)xx                       <=> qr/(?>a)(?>b|c){12}(?>d)xx/
^(a+(b*))+(x+(x+(x+)))+$                <=> qr/^(?>a+(?>b*))+(?>x+(?>x+(?>x+)))+$/
A(a(b))C(c(d))E(e(f))G(g(h))            <=> qr/A(?>a(?>b))C(?>c(?>d))E(?>e(?>f))G(?>g(?>h))/
^(a+(b*)z)+-(x+(x+(x+))z)               <=> qr/^(?>a+(?>b*)z)+-(?>x+(?>x+(?>x+))z)/
(begin)end                              <=> qr/(?>begin)end/
begin(end)                              <=> qr/begin(?>end)/
(begin)(end)                            <=> qr/(?>begin)(?>end)/
(begin)middle(end)                      <=> qr/(?>begin)middle(?>end)/
(begin)(middle)(end)                    <=> qr/(?>begin)(?>middle)(?>end)/
begin(middle)end                        <=> qr/begin(?>middle)end/
(begin)(middle)(end(inside))            <=> qr/(?>begin)(?>middle)(?>end(?>inside))/
(begin)(middle)((inside)end)            <=> qr/(?>begin)(?>middle)(?>(?>inside)end)/
((inside)begin)(middle)(end)            <=> qr/(?>(?>inside)begin)(?>middle)(?>end)/
(begin(inside))(middle)(end)            <=> qr/(?>begin(?>inside))(?>middle)(?>end)/
(begin)(mid(inside)dle)(end)            <=> qr/(?>begin)(?>mid(?>inside)dle)(?>end)/
^/tmp/(a+)+b$                           <=> qr{^/tmp/(?>a+)+b$}

^C:\\Program Files( \(x86\))?\\Internet Explorer\\.* <=> qr/^C:\\Program Files(?> \(x86\))?\\Internet Explorer\\.*/

# Possible errors
(somepath                               <=> "Aborting File Collect job on regex compilation error: Unmatched ("
('inside)                               <=> qr/(?>'inside)/
\('inside)                              <=> "Aborting File Collect job on regex compilation error: Unmatched )"
\\('inside)                             <=> qr/\\(?>'inside)/
perl(?{ delete file })script            <=> "Aborting File Collect job on regex compilation error: Eval-group not allowed at runtime"
perl(*{ delete file })script            <=> "Aborting File Collect job on regex compilation error: Eval-group not allowed at runtime"
perl(??{ delete file })script           <=> "Aborting File Collect job on regex compilation error: Eval-group not allowed at runtime"
\(a+)+b$                                <=> "Aborting File Collect job on regex compilation error: Unmatched )"
\\(a+)+b$                               <=> qr/\\(?>a+)+b$/
\\\(a+)+b$                              <=> "Aborting File Collect job on regex compilation error: Unmatched )"
\\\\(a+)+b$                             <=> qr/\\\\(?>a+)+b$/
(begin)/\1/(end)                        <=> "Aborting File Collect job on regex compilation error: Reference to nonexistent group in regex"
^(a+\)+b$                               <=> "Aborting File Collect job on regex compilation error: Unmatched ("
^(a+\\)+b$                              <=> qr/^(?>a+\\)+b$/
^(a+\\\)+b$                             <=> "Aborting File Collect job on regex compilation error: Unmatched ("
^(a+\\\\)+b$                            <=> qr/^(?>a+\\\\)+b$/
^(a+\\\(c+\\\)+)+b$                     <=> qr/^(?>a+\\\(?>c+\\\)+)+b$/

(begin|start)/((?<=begin/)begin|(?<=start/)start)/(end) <=> qr{(?>begin|start)/(?>(?<=begin/)begin|(?<=start/)start)/(?>end)}
