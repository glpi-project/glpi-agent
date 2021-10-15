#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';
use utf8;

use English qw(-no_match_vars);
use Test::More;
use Test::MockModule;
use UNIVERSAL::require;

use GLPI::Test::Utils;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

use Config;
# check thread support availability
if (!$Config{usethreads} || $Config{usethreads} ne 'define') {
    plan skip_all => 'thread support required';
}

Test::NoWarnings->use();

GLPI::Agent::Task::Inventory::Win32::License->require();

my %tests = (
    office_2010_1 => {
        NAME       => 'Microsoft Office',
        FULLNAME   => 'Microsoft Office Professional 2010',
        PRODUCTID  => '82503-242-8447354-11013',
        KEY        => 'W7227-979WY-QQB79-3Q6MR-JVB9D',
        OEM        => 1,
        UPDATE     => 'SP2',
        TRIAL      => '0',
        COMPONENTS => 'Access/AccessRuntime/Excel/ExcelConsumer/Groove/InfoPath/OneNote/Outlook/OutlookStandard/PowerPoint/Project/Publisher/SharePointDesigner/Visio/VisioSDK/Word/WordConsumer'
    },
    office_2010_2 => {
        NAME       => 'Microsoft Office',
        FULLNAME   => 'Microsoft Office 2010 dla Użytkowników Domowych i Małych Firm',
        PRODUCTID  => '82503-OEM-1170032-70636',
        KEY        => 'YKP6Y-3MDM7-J8FY4-B49VP-FPR27',
        OEM        => 1,
        UPDATE     => 'SP2',
        TRIAL      => '0',
        COMPONENTS => 'Access/AccessRuntime/Excel/ExcelConsumer/Groove/InfoPath/OneNote/Outlook/OutlookStandard/PowerPoint/Project/Publisher/SharePointDesigner/Visio/VisioSDK/Word/WordConsumer'
    },
);

my %licensing_tests = (
    office_2016_01 =>   {
        NAME       => 'Office 16, Office16ProPlusVL_KMS_Client edition',
        FULLNAME   => 'Office 16, VOLUME_KMSCLIENT channel',
        PRODUCTID  => '00339-10000-00000-AA680',
        KEY        => 'XXXXX-XXXXX-XXXXX-XXXXX-WE9H9',
        OEM        => 0,
    },
);
plan tests => scalar (keys %tests) + scalar (keys %licensing_tests) + 11 ;

foreach my $test (keys %tests) {
    my $key = loadRegistryDump("resources/win32/registry/$test.reg");
    my $license =
        GLPI::Agent::Task::Inventory::Win32::License::_getOfficeLicense($key);

    is_deeply(
        $license,
        $tests{$test},
        "$test sample"
    );
}

my $module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::Win32::License'
);

foreach my $test (keys %licensing_tests) {
    $module->mock(
        'getWMIObjects',
        mockGetWMIObjects($test)
    );
    GLPI::Agent::Task::Inventory::Win32::License::_resetSeenProducts();
    GLPI::Agent::Task::Inventory::Win32::License::_scanWmiSoftwareLicensingProducts();
    my @licenses = GLPI::Agent::Task::Inventory::Win32::License::_getSeenProducts();

    is_deeply(
        @licenses,
        $licensing_tests{$test},
        "$test licensing"
    );
}

$module->mock( 'getWMIObjects', mockGetWMIObjects('office_2016_01') );
my $key = loadRegistryDump("resources/win32/registry/office_2016_02.reg");
GLPI::Agent::Task::Inventory::Win32::License::_resetSeenProducts();
GLPI::Agent::Task::Inventory::Win32::License::_scanOfficeLicences($key);
my @licenses = GLPI::Agent::Task::Inventory::Win32::License::_getSeenProducts();

ok( @licenses == 0 );

GLPI::Agent::Task::Inventory::Win32::License::_scanWmiSoftwareLicensingProducts();
@licenses = GLPI::Agent::Task::Inventory::Win32::License::_getSeenProducts();

ok( @licenses == 1 );
ok( $licenses[0]->{'KEY'} eq 'XXXXX-XXXXX-XXXXX-XXXXX-WE9H9' );
ok( $licenses[0]->{'PRODUCTID'} eq '00339-10000-00000-AA680' );
# ProductCode has been seen in _scanOfficeLicences() so FULLNAME is read from registry
ok( $licenses[0]->{'FULLNAME'} eq 'Microsoft Office Professional Plus 2016' );

$key = loadRegistryDump("resources/win32/registry/office_2016_01.reg");
GLPI::Agent::Task::Inventory::Win32::License::_resetSeenProducts();
GLPI::Agent::Task::Inventory::Win32::License::_scanOfficeLicences($key);
@licenses = GLPI::Agent::Task::Inventory::Win32::License::_getSeenProducts();

ok( @licenses == 1 );
ok( $licenses[0]->{'KEY'} eq 'YKP6Y-3MDM7-J8F3Q-9297J-3TF27' );
ok( $licenses[0]->{'PRODUCTID'} eq '00339-10000-00000-AA310' );

GLPI::Agent::Task::Inventory::Win32::License::_scanWmiSoftwareLicensingProducts();
@licenses = GLPI::Agent::Task::Inventory::Win32::License::_getSeenProducts();

# License was still read from registry, no license added, but replaced by WMI Information
ok( @licenses == 1 );
ok( $licenses[0]->{'KEY'} eq 'XXXXX-XXXXX-XXXXX-XXXXX-WE9H9' );
