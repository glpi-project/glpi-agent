#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::AIX::Drives;

my %types_tests = (
    'aix-4.3.1' => {
        '/'                      => 'jfs',
        '/usr'                   => 'jfs',
        '/tmp'                   => 'jfs',
    },
    'aix-5.3' => {
        '/'                      => 'jfs2',
        '/usr'                   => 'jfs2',
        '/tmp'                   => 'jfs2',
    },
    'aix-6.1' => {
        '/'                      => 'jfs2',
        '/home'                  => 'jfs2',
        '/usr'                   => 'jfs2',
        '/var'                   => 'jfs2',
        '/tmp'                   => 'jfs2',
        '/admin'                 => 'jfs2',
        '/proc'                  => 'procfs',
        '/opt'                   => 'jfs2',
        '/var/adm/ras/livedump'  => 'jfs2',
        '/opt/DoOnceAIX'         => 'jfs2',
        '/var/adm/perfmgr'       => 'jfs2',
        '/var/log/eprise'        => 'jfs2',
        '/usr/WebSphere'         => 'jfs2',
        '/opt/IHS'               => 'jfs2',
        '/home/apps'             => 'jfs2',
        '/home/apps/deployments' => 'jfs2',
        '/opt/oracle'            => 'jfs2',
        '/opt/pvcs'              => 'jfs2',
        '/opt/IBM/TPC'           => 'jfs2',
        '/home/apps/glvmt'       => 'jfs2',
        '/home/apps/glvpack'     => 'jfs2',
        '/home/apps/glvsc'       => 'jfs2',
        '/home/apps/glvlfw'      => 'jfs2',
        '/opt/best1'             => 'jfs2',
    }
);

plan tests =>
    (scalar keys %types_tests) +
    1;

foreach my $test (keys %types_tests) {
    my $file = "resources/aix/lsfs/$test";
    my $types = GLPI::Agent::Task::Inventory::AIX::Drives::_getFilesystemTypes(file => $file);
    cmp_deeply($types, $types_tests{$test}, "$test: lsfs parsing");
}
