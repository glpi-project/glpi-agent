#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Temp qw(tempdir);
use Test::More;
use Test::Exception;

use GLPI::Agent::Target::Local;
use GLPI::Agent::Task::Inventory;
use GLPI::Agent::Task::Collect;
use GLPI::Agent::Tools;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

plan tests => 8;

my $task;
throws_ok {
    $task = GLPI::Agent::Task::Inventory->new();
} qr/^no target parameter/,
'instanciation: no target';

lives_ok {
    $task = GLPI::Agent::Task::Inventory->new(
        target => GLPI::Agent::Target::Local->new(
            path => tempdir(),
            basevardir => tempdir()
        ),
    );
} 'instanciation: ok';

my @modules = $task->getModules();
ok(@modules != 0, 'modules list is not empty');
ok(
    (all { $_ =~ /^GLPI::Agent::Task::Inventory::/ } @modules),
    'modules list only contains inventory modules'
);

@modules = $task->getModules('Inventory');
ok(@modules != 0, 'inventory modules list is not empty');
ok(
    (all { $_ =~ /^GLPI::Agent::Task::Inventory::/ } @modules),
    'inventory modules list only contains inventory modules'
);

@modules = $task->getModules('Collect');
ok(@modules != 0, 'collect modules list is not empty');
ok(
    (all { $_ =~ /^GLPI::Agent::Task::Collect::/ } @modules),
    'collect modules list only contains collect modules'
);
