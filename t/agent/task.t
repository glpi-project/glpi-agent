#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Temp qw(tempdir);
use Test::More;
use Test::Exception;

use FusionInventory::Agent::Target::Local;
use FusionInventory::Agent::Task::Inventory;
use FusionInventory::Agent::Task::Collect;
use FusionInventory::Agent::Tools;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

plan tests => 8;

my $task;
throws_ok {
    $task = FusionInventory::Agent::Task::Inventory->new();
} qr/^no target parameter/,
'instanciation: no target';

lives_ok {
    $task = FusionInventory::Agent::Task::Inventory->new(
        target => FusionInventory::Agent::Target::Local->new(
            path => tempdir(),
            basevardir => tempdir()
        ),
    );
} 'instanciation: ok';

my @modules = $task->getModules();
ok(@modules != 0, 'modules list is not empty');
ok(
    (all { $_ =~ /^FusionInventory::Agent::Task::Inventory::/ } @modules),
    'modules list only contains inventory modules'
);

@modules = $task->getModules('Inventory');
ok(@modules != 0, 'inventory modules list is not empty');
ok(
    (all { $_ =~ /^FusionInventory::Agent::Task::Inventory::/ } @modules),
    'inventory modules list only contains inventory modules'
);

@modules = $task->getModules('Collect');
ok(@modules != 0, 'collect modules list is not empty');
ok(
    (all { $_ =~ /^FusionInventory::Agent::Task::Collect::/ } @modules),
    'collect modules list only contains collect modules'
);
