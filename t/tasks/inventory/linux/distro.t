#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::Linux::Distro::OSRelease;

my %osrelease = (
    'fedora-35' => {
        FULL_NAME   => 'Fedora Linux 35 (Thirty Five)',
        NAME        => 'Fedora Linux',
        VERSION     => '35 (Thirty Five)',
    },
    'centos-7.9' => {
        FULL_NAME   => 'CentOS Linux 7 (Core)',
        NAME        => 'CentOS Linux',
        VERSION     => '7.9.2009 (Core)',
    },
    'debian-11.2' => {
        FULL_NAME   => 'Debian GNU/Linux 11 (bullseye)',
        NAME        => 'Debian GNU/Linux',
        VERSION     => '11.2',
    },
);

plan tests => (scalar keys %osrelease) + 1;

foreach my $test (keys %osrelease) {
    my $file = "resources/linux/distro/os-release-$test";
    my $os = GLPI::Agent::Task::Inventory::Linux::Distro::OSRelease::_getOSRelease(file => $file);
    $file = "resources/linux/distro/debian_version-$test";
    GLPI::Agent::Task::Inventory::Linux::Distro::OSRelease::_fixDebianOS(file => $file, os => $os) if -e $file;
    $file = "resources/linux/distro/centos-release-$test";
    GLPI::Agent::Task::Inventory::Linux::Distro::OSRelease::_fixCentOS(file => $file, os => $os) if -e $file;
    cmp_deeply($os, $osrelease{$test}, '$test os-release: parsing');
}
