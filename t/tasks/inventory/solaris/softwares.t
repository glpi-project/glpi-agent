#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Solaris::Softwares;

my %pkg_tests = (
    'sample' => [
        {
            COMMENTS   => 'GNU version of the tar archiving utility',
            NAME       => 'archiver/gnu-tar',
            PUBLISHER  => 'solaris',
            VERSION    => '1.26,5.11-0.175.1.0.0.24.0:20120904T170545Z',
        },
        {
            COMMENTS   => 'Audio Applications',
            NAME       => 'audio/audio-utilities',
            PUBLISHER  => 'solaris',
            VERSION    => '0.5.11,5.11-0.175.1.0.0.24.2:20120919T184117Z',
        },
        {
            COMMENTS   => 'iperf - tool for measuring maximum TCP and UDP bandwidth performance',
            NAME       => 'benchmark/iperf',
            PUBLISHER  => 'solaris',
            VERSION    => '2.0.4,5.11-0.175.1.0.0.24.0:20120904T170601Z',
        },
        {
            COMMENTS   => 'entire incorporation including Support Repository Update (Oracle Solaris 11.1 SRU 4.5).',
            NAME       => 'entire',
            PUBLISHER  => 'solaris',
            VERSION    => '0.5.11,5.11-0.175.1.4.0.5.0:20130212T161754Z',
        }
    ]
);
my %pkginfo_tests = (
    'sample-sol10' => [
        {
            COMMENTS   => 'GNU tar - A utility used to store, backup, and transport files (gtar) 1.25',
            NAME       => 'SUNWgtar',
            PUBLISHER  => 'Oracle Corporation',
            VERSION    => '11.10.0,REV=2005.01.08.01.09',
        },
        {
            COMMENTS   => 'SunOS audio applications',
            NAME       => 'SUNWauda',
            PUBLISHER  => 'Oracle Corporation',
            VERSION    => '11.10.0,REV=2005.01.21.16.34',
        },
        {
            COMMENTS   => 'Basic IP commands (/usr/sbin/ping, /bin/ftp)',
            NAME       => 'SUNWbip',
            PUBLISHER  => 'Oracle Corporation',
            VERSION    => '11.10.0,REV=2005.01.21.16.34',
        }
    ]

);

plan tests => 2 * (scalar keys %pkg_tests) + 2 * (scalar keys %pkginfo_tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %pkg_tests) {
    my $file = "resources/solaris/pkg-info/$test";
    my $softwares = GLPI::Agent::Task::Inventory::Solaris::Softwares::_parse_pkgs(file => $file, command => 'pkg info');
    cmp_deeply($softwares, $pkg_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'SOFTWARES', entry => $_)
            foreach @$softwares;
    } "$test: registering";
}

foreach my $test (keys %pkginfo_tests) {
    my $file = "resources/solaris/pkg-info/$test";
    my $softwares = GLPI::Agent::Task::Inventory::Solaris::Softwares::_parse_pkgs(file => $file, command => 'pkginfo -l');
    cmp_deeply($softwares, $pkginfo_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'SOFTWARES', entry => $_)
            foreach @$softwares;
    } "$test: registering";
}
