#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);

use Test::NoWarnings;
use Test::More;

use GLPI::Agent::Event;

my $in_the_future = time + 60;

my %tests = (
    _invalid => {
        params  => {},
        ok_test => sub { !defined($_[0]); },
        ko_test => sub { defined($_[0]); },
    },
    init => {
        params  => {
            init    => 1,
        },
        ok_test => sub { $_[0]->init && !$_[0]->task && !$_[0]->delay; },
        ko_test => sub { $_[0]->job || $_[0]->partial || $_[0]->maintenance || $_[0]->taskrun || $_[0]->runnow ? 1 : 0; },
    },
    real_init => {
        params  => {
            init    => 1,
            task    => "inventory",
            rundate => $in_the_future,
        },
        ok_test => sub { $_[0]->init && $_[0]->task eq "inventory" && $_[0]->rundate == $in_the_future; },
        ko_test => sub { $_[0]->job || $_[0]->partial || $_[0]->maintenance || $_[0]->taskrun || $_[0]->runnow ? 1 : 0; },
    },
    runnow => {
        params  => {
            runnow  => 1,
        },
        ok_test => sub { $_[0]->runnow && $_[0]->task eq "all" && !$_[0]->delay; },
        ko_test => sub { $_[0]->job || $_[0]->partial || $_[0]->maintenance || $_[0]->taskrun || $_[0]->init ? 1 : 0; },
    },
    delayed_runnow => {
        params  => {
            runnow  => "yes",
            task    => "inventory",
            delay   => 10,
        },
        ok_test => sub { $_[0]->runnow && $_[0]->task eq "inventory" && $_[0]->delay == 10; },
        ko_test => sub { $_[0]->job || $_[0]->partial || $_[0]->maintenance || $_[0]->taskrun || $_[0]->init ? 1 : 0; },
    },
    partial_runnow => {
        params  => {
            runnow  => "yes",
            task    => "inventory",
            partial => "database",
        },
        ok_test => sub { $_[0]->runnow &&  $_[0]->task eq "inventory" && $_[0]->get("partial") eq "database" && !$_[0]->delay; },
        ko_test => sub { $_[0]->job || $_[0]->partial || $_[0]->maintenance || $_[0]->taskrun || $_[0]->init ? 1 : 0; },
    },
    taskrun => {
        params  => {
            taskrun => 1,
            task    => "test",
        },
        ok_test => sub { $_[0]->taskrun && $_[0]->task eq "test" && !$_[0]->delay; },
        ko_test => sub { $_[0]->job || $_[0]->partial || $_[0]->maintenance || $_[0]->runnow || $_[0]->init ? 1 : 0; },
    },
    notask_taskrun => {
        params  => {
            taskrun => 1,
        },
        ok_test => sub { !defined($_[0]); },
        ko_test => sub { defined($_[0]); },
    },
    delayed_taskrun => {
        params  => {
            taskrun => "yes",
            task    => "inventory",
            delay   => 10,
        },
        ok_test => sub { $_[0]->taskrun && $_[0]->task eq "inventory" && $_[0]->delay == 10; },
        ko_test => sub { $_[0]->job || $_[0]->partial || $_[0]->maintenance || $_[0]->runnow || $_[0]->init ? 1 : 0; },
    },
    reschedule_taskrun => {
        params  => {
            taskrun     => "yes",
            task        => "inventory",
            reschedule  => 1,
        },
        ok_test => sub { $_[0]->taskrun && $_[0]->task eq "inventory" && !$_[0]->delay && $_[0]->get("reschedule") ; },
        ko_test => sub { $_[0]->job || $_[0]->partial || $_[0]->maintenance || $_[0]->runnow || $_[0]->init ? 1 : 0; },
    },
    partial => {
        params  => {
            name        => "partial inventory",
            partial     => "yes",
            category    => "bios,hardware",
        },
        ok_test => sub { $_[0]->partial; },
        ko_test => sub { $_[0]->job || $_[0]->init || $_[0]->maintenance || $_[0]->taskrun || $_[0]->runnow ; },
    },
    maintenance => {
        params  => {
            maintenance => 1,
        },
        ok_test => sub { $_[0]->maintenance && $_[0]->task eq "" && !$_[0]->delay; },
        ko_test => sub { $_[0]->job || $_[0]->partial || $_[0]->runnow || $_[0]->taskrun || $_[0]->init ? 1 : 0; },
    },
    deploy_maintenance => {
        params  => {
            maintenance => "yes",
            name        => "storage maintenance",
            task        => "deploy",
            delay       => 120,
            target      => "server0",
        },
        ok_test => sub { $_[0]->maintenance && $_[0]->task eq "deploy" && $_[0]->delay == 120 && $_[0]->name eq "storage maintenance" && $_[0]->target eq "server0"; },
        ko_test => sub { $_[0]->job || $_[0]->partial || $_[0]->runnow || $_[0]->taskrun || $_[0]->init ? 1 : 0; },
    },
    job => {
        params  => {
            job     => 1,
            name    => "job name",
        },
        ok_test => sub { $_[0]->job && $_[0]->name eq "job name" && !$_[0]->rundate; },
        ko_test => sub { $_[0]->maintenance || $_[0]->partial || $_[0]->runnow || $_[0]->taskrun || $_[0]->init ? 1 : 0; },
    },
    noname_job => {
        params  => {
            job => 1,
        },
        ok_test => sub { !defined($_[0]); },
        ko_test => sub { defined($_[0]); },
    },
    planned_job => {
        params  => {
            job     => "yes",
            name    => "local inventory",
            task    => "inventory",
            rundate => $in_the_future,
        },
        ok_test => sub { $_[0]->job && $_[0]->name eq "local inventory" && $_[0]->task eq "inventory" && $_[0]->rundate == $in_the_future; },
        ko_test => sub { $_[0]->maintenance || $_[0]->partial || $_[0]->runnow || $_[0]->taskrun || $_[0]->init ? 1 : 0; },
    },
);

plan tests => scalar keys(%tests) * 3 + 1;

foreach my $test (sort keys(%tests)) {
    my $event = GLPI::Agent::Event->new(%{$tests{$test}->{params}});
    ok(!defined($event) || length($event->name), "event name for $test");
    ok(&{$tests{$test}->{ok_test}}($event) == 1, "ok test for $test");
    ok(&{$tests{$test}->{ko_test}}($event) == 0, "ko test for $test");
}
