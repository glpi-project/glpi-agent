#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Test::Deep;
use Test::More;

use GLPI::Agent;
use GLPI::Agent::Config;
use GLPI::Agent::Logger;

plan tests => 22;

my $libdir = tempdir(CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);
push @INC, $libdir;
my $agent = GLPI::Agent->new(libdir => $libdir);

# No agentid set by default
ok(!exists($agent->{agentid}));

create_file("$libdir/GLPI/Agent/Task/Task1", "Version.pm", <<'EOF');
package GLPI::Agent::Task::Task1::Version;
use constant VERSION => 42;
1;
EOF
cmp_deeply (
    $agent->getAvailableTasks(),
    { 'Task1' => 42 },
    "single task"
);

create_file("$libdir/GLPI/Agent/Task/Task2", "Version.pm", <<'EOF');
package GLPI::Agent::Task::Task2::Version;
use constant VERSION => 42;
1;
EOF
cmp_deeply (
    $agent->getAvailableTasks(),
    {
        'Task1' => 42,
        'Task2' => 42
    },
    "multiple tasks"
);

create_file("$libdir/GLPI/Agent/Task/Task3", "Version.pm", <<'EOF');
package GLPI::Agent::Task::Task3::Version;
use Does::Not::Exists;
use constant VERSION => 42;
1;
EOF
cmp_deeply (
    $agent->getAvailableTasks(),
    {
        'Task1' => 42,
        'Task2' => 42
    },
    "wrong syntax"
);

create_file("$libdir/GLPI/Agent/Task/Task5", "Version.pm", <<'EOF');
package GLPI::Agent::Task::Task5::Version;
use constant VERSION => 42;
1;
EOF
cmp_deeply (
    $agent->getAvailableTasks(),
    {
        'Task1' => 42,
        'Task2' => 42,
        'Task5' => 42
    },
    "multiple tasks"
);

# Setup agent
$agent->{config} = GLPI::Agent::Config->new(
    options => {
        config  => 'none',
        debug   => 1,
        logger  => 'Test'
    }
);
$agent->{config}->{'no-task'} = ['Task5'];
$agent->{config}->{'tasks'} = [ qw(Task1 Task5 Task1 Task5 Task5 Task2 Task1)];
my $availableTasks = $agent->getAvailableTasks();
$agent->{logger} = GLPI::Agent::Logger->new(config => $agent->{config});
my @plan = $agent->computeTaskExecutionPlan($availableTasks);
cmp_deeply(
    \@plan,
    [ qw(Task1 Task1 Task2 Task1) ],
    "simply filtered execution plan A"
);

$agent->{config}->{'no-task'} = ['Task5'];
$agent->{config}->{'tasks'} = [ qw(Task1 Task5 Task1 Task5 ...)];
@plan = $agent->computeTaskExecutionPlan($availableTasks);
cmp_deeply(
    \@plan,
    [ qw(Task1 Task1 Task2) ],
    "simply filtered execution plan A"
);

sub create_file {
    my ($directory, $file, $content) = @_;

    make_path($directory);

    open (my $fh, '>', "$directory/$file")
        or die "can't create $directory/$file: $!";
    print $fh $content;
    close $fh;
}

sub checktasksplan {
    my ($taskconf, $length, $expected, $comment) = @_;
    my @taskinconf = split(/,+/, $taskconf);
    my @tasksExecutionPlan = GLPI::Agent::_makeExecutionPlan(\@taskinconf, $availableTasks);
    ok(@tasksExecutionPlan == $length, "$comment, plan length: ".@tasksExecutionPlan);
    if (ref($expected) eq 'ARRAY') {
        cmp_deeply(
            \@tasksExecutionPlan,
            $expected,
            $comment
        );
    } else {
        foreach my $range (sort keys(%{$expected})) {
            my $part;
            eval '$part = [ @tasksExecutionPlan['.$range.'] ];';
            if ($range =~ /^0\.\./) {
                cmp_deeply(
                    $part,
                    $expected->{$range},
                    "$comment, $range part"
                );
            } else {
                cmp_deeply(
                    [ sort @{$part} ],
                    [ sort @{$expected->{$range}} ],
                    "$comment, $range part"
                );
            }
        }
    }
}

# Define new available tasks
$availableTasks->{TaskX} = "X.0";
$availableTasks->{Task345} = "345.0";

# Remember Task5 is disabled and Task3 is invalid
checktasksplan(
    "task1,task2,task1,task3,task3",
    3,
    [ qw(Task1 Task2 Task1) ],
    "filtered execution plan B"
);

checktasksplan(
    "task1,task2,task1,task3,Task3,task3,task5,Task1,task2,task2",
    6,
    [ qw(Task1 Task2 Task1 Task1 Task2 Task2) ],
    "filtered execution plan C"
);

checktasksplan(
    "task1,tasK2,task1,Task3,task3,task3,task5,Task1,task2,Task2,...",
    8,
    {
        '0..5'  => [ qw(Task1 Task2 Task1 Task1 Task2 Task2) ],
        '6..7'  => [ qw(Task345 TaskX) ],
    },
    "filtered execution plan D, with dots"
);

$agent->{datadir} = './share';
$agent->{vardir}  = './var',

# Reset config to be able to run init() method with mandatory options
delete $agent->{config};
my $options = {
    'local' => '.',
    # Keep Test backend on logger as call to init() will reset logger
    'logger' => 'Test',
    # we force config to be loaded from file
    'conf-file' => 'resources/config/sample1',
    'config' => 'file'
};
$agent->init(options => $options);
# after init call, the member 'config' is defined and well blessed
ok (ref($agent->{config}) eq 'GLPI::Agent::Config');
ok (defined($agent->{config}->{'conf-file'}));
ok (defined($agent->{config}->{'no-task'}));
ok (scalar(@{$agent->{config}->{'no-task'}}) == 2);
ok (
    ($agent->{config}->{'no-task'}->[0] eq 'snmpquery' && $agent->{config}->{'no-task'}->[1] eq 'wakeonlan')
        || ($agent->{config}->{'no-task'}->[1] eq 'snmpquery' && $agent->{config}->{'no-task'}->[0] eq 'wakeonlan')
);
ok (scalar(@{$agent->{config}->{'server'}}) == 0);

checktasksplan(
    "task1,task2,task1,task3,Task3,task3,task5,Task1,task2,task2",
    6,
    [ qw(Task1 Task2 Task1 Task1 Task2 Task2) ],
    "filtered execution plan still good"
);
