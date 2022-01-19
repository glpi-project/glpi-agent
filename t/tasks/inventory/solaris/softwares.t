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
            FILESIZE   => '1',
        },
        {
            COMMENTS   => 'Audio Applications',
            NAME       => 'audio/audio-utilities',
            PUBLISHER  => 'solaris',
            VERSION    => '0.5.11,5.11-0.175.1.0.0.24.2:20120919T184117Z',
            FILESIZE   => '0',
        },
        {
            COMMENTS   => 'iperf - tool for measuring maximum TCP and UDP bandwidth performance',
            NAME       => 'benchmark/iperf',
            PUBLISHER  => 'solaris',
            VERSION    => '2.0.4,5.11-0.175.1.0.0.24.0:20120904T170601Z',
            FILESIZE   => '0',
        },
        {
            COMMENTS   => 'entire incorporation including Support Repository Update (Oracle Solaris 11.1 SRU 4.5).',
            NAME       => 'entire',
            PUBLISHER  => 'solaris',
            VERSION    => '0.5.11,5.11-0.175.1.4.0.5.0:20130212T161754Z',
            FILESIZE   => '0',
        }
    ],
    'sample-oi-2021.10' => [
        {
            PUBLISHER   => 'openindiana.org',
            COMMENTS    => 'Core Solaris',
            NAME        => 'SUNWcs',
            VERSION     => '0.5.11-2020.0.1.20752:20211031T013102Z',
            INSTALLDATE => '31/10/2021',
            FILESIZE    => '26',
        },
        {
            COMMENTS    => 'Core Solaris Devices',
            PUBLISHER   => 'openindiana.org',
            VERSION     => '0.5.11-2020.0.1.20752:20211031T013121Z',
            NAME        => 'SUNWcsd',
            INSTALLDATE => '31/10/2021',
            FILESIZE    => '0',
        },
        {
            COMMENTS    => 'high-quality block-sorting file compressor - utilities',
            PUBLISHER   => 'openindiana.org',
            VERSION     => '1.0.8-2020.0.1.0:20200330T113433Z',
            NAME        => 'compress/bzip2',
            INSTALLDATE => '31/10/2021',
            FILESIZE    => '0',
        },
        {
            COMMENTS    => 'GNU Zip (gzip)',
            PUBLISHER   => 'openindiana.org',
            VERSION     => '1.11-2020.0.1.0:20210903T182240Z',
            NAME        => 'compress/gzip',
            INSTALLDATE => '31/10/2021',
            FILESIZE    => '0',
        },
        {
            COMMENTS    => '\'XZ Utils - loss-less file compression application and',
            PUBLISHER   => 'openindiana.org',
            VERSION     => '5.2.5-2020.0.1.0:20200925T212250Z',
            NAME        => 'compress/xz',
            INSTALLDATE => '31/10/2021',
            FILESIZE    => '1',
        },
        {
            COMMENTS    => 'Zstandard, or zstd for short, is a fast lossless compression',
            PUBLISHER   => 'openindiana.org',
            VERSION     => '1.5.0-2020.0.1.0:20210518T153618Z',
            NAME        => 'compress/zstd',
            INSTALLDATE => '31/10/2021',
            FILESIZE    => '6',
        },
        {
            COMMENTS    => 'install consolidation incorporation',
            PUBLISHER   => 'openindiana.org',
            VERSION     => '0.5.11-2020.0.1.1053:20210907T210638Z',
            NAME        => 'consolidation/install/install-incorporation',
            INSTALLDATE => '31/10/2021',
        },
        {
            PUBLISHER   => 'openindiana.org',
            COMMENTS    => 'This incorporation constrains packages from the nspg',
            NAME        => 'consolidation/nspg/nspg-incorporation',
            VERSION     => '0.5.11-2014.1.0.0:20200330T151748Z',
            INSTALLDATE => '31/10/2021',
        },
        {
            VERSION     => '0.5.11-2020.0.1.20752:20211031T011214Z',
            NAME        => 'consolidation/osnet/osnet-incorporation',
            COMMENTS    => 'OS/Net consolidation incorporation',
            PUBLISHER   => 'openindiana.org',
            INSTALLDATE => '31/10/2021',
        },
        {
            NAME        => 'consolidation/sunpro/sunpro-incorporation',
            VERSION     => '0.5.11-2020.0.1.20752:20211031T011224Z',
            PUBLISHER   => 'openindiana.org',
            INSTALLDATE => '31/10/2021',
        },
        {
            PUBLISHER   => 'openindiana.org',
            COMMENTS    => 'userland consolidation incorporation',
            NAME        => 'consolidation/userland/userland-incorporation',
            VERSION     => '0.5.11-2020.0.1.14595:20211031T181230Z',
            INSTALLDATE => '31/10/2021',
        },
        {
            PUBLISHER   => 'openindiana.org',
            COMMENTS    => 'Common CA certificates',
            NAME        => 'crypto/ca-certificates',
            VERSION     => '3.71-2020.0.1.1:20211030T151528Z',
            INSTALLDATE => '31/10/2021',
            FILESIZE    => '0',
        },
        {
            PUBLISHER   => 'openindiana.org',
            COMMENTS    => 'ISO code lists and translations',
            NAME        => 'data/iso-codes',
            VERSION     => '4.7.0-2020.0.1.0:20210915T125436Z',
            INSTALLDATE => '31/10/2021',
            FILESIZE    => '18',
        },
        {
            PUBLISHER   => 'openindiana.org',
            COMMENTS    => 'Oracle Berkeley DB',
            NAME        => 'database/berkeleydb-5',
            VERSION     => '5.3.28-2020.0.1.0:20200330T113744Z',
            INSTALLDATE => '31/10/2021',
            FILESIZE    => '101',
        },
        {
            VERSION     => '3.36.0-2020.0.1.0:20210703T221041Z',
            NAME        => 'database/sqlite-3',
            COMMENTS    => 'in-process SQL database engine library',
            PUBLISHER   => 'openindiana.org',
            INSTALLDATE => '31/10/2021',
            FILESIZE    => '6',
        },
        {
            PUBLISHER   => 'openindiana.org',
            COMMENTS    => 'ACPI utilities',
            NAME        => 'developer/acpi',
            VERSION     => '0.5.11-2020.0.1.20752:20211031T011227Z',
            INSTALLDATE => '31/10/2021',
            FILESIZE    => '1',
        },
        {
            COMMENTS    => 'Parallel make(1) build tool',
            PUBLISHER   => 'openindiana.org',
            VERSION     => '0.5.11-2020.0.1.20752:20211031T011242Z',
            NAME        => 'developer/build/make',
            INSTALLDATE => '31/10/2021',
            FILESIZE    => '0',
        },
        {
            NAME        => 'developer/debug/mdb',
            VERSION     => '0.5.11-2020.0.1.20752:20211031T011251Z',
            PUBLISHER   => 'openindiana.org',
            COMMENTS    => 'Modular Debugger',
            INSTALLDATE => '31/10/2021',
            FILESIZE    => '11',
        },
        {
            NAME        => 'developer/debug/mdb/module/module-ce',
            VERSION     => '0.5.11-2013.0.0.0:20151027T061512Z',
            PUBLISHER   => 'openindiana.org',
            COMMENTS    => 'Sun GigaSwift Ethernet Adapter Driver adb Macros',
            INSTALLDATE => '31/10/2021',
            FILESIZE    => '0',
        },
        {
            NAME        => 'developer/debug/mdb/module/module-fibre-channel',
            VERSION     => '0.5.11-2020.0.1.20752:20211031T011259Z',
            PUBLISHER   => 'openindiana.org',
            COMMENTS    => 'Fibre Channel adb macros and mdb modules',
            INSTALLDATE => '31/10/2021',
            FILESIZE    => '0',
        },
        {
            NAME        => 'system/man',
            VERSION     => '0.5.11-2020.0.1.20752:20211031T013805Z',
            PUBLISHER   => 'openindiana.org',
            COMMENTS    => 'Reference Manual Pages Tools',
            INSTALLDATE => '19/01/2022',
            FILESIZE    => '0',
        },
        {
            NAME        => 'text/less',
            VERSION     => '590-2020.0.1.0:20210926T110626Z',
            PUBLISHER   => 'openindiana.org',
            COMMENTS    => 'Pager program similar to more',
            INSTALLDATE => '19/01/2022',
            FILESIZE    => '0',
        },
    ],
);
my %pkginfo_tests = (
    'sample-sol10' => [
        {
            COMMENTS    => 'GNU tar - A utility used to store, backup, and transport files (gtar) 1.25',
            NAME        => 'SUNWgtar',
            PUBLISHER   => 'Oracle Corporation',
            VERSION     => '11.10.0,REV=2005.01.08.01.09',
            INSTALLDATE => '31/07/2013',
        },
        {
            COMMENTS    => 'SunOS audio applications',
            NAME        => 'SUNWauda',
            PUBLISHER   => 'Oracle Corporation',
            VERSION     => '11.10.0,REV=2005.01.21.16.34',
            INSTALLDATE => '31/07/2013',
        },
        {
            COMMENTS    => 'Basic IP commands (/usr/sbin/ping, /bin/ftp)',
            NAME        => 'SUNWbip',
            PUBLISHER   => 'Oracle Corporation',
            VERSION     => '11.10.0,REV=2005.01.21.16.34',
            INSTALLDATE => '31/07/2013',
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
