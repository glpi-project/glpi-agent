#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Data::Dumper;

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Generic::Databases::Oracle;

$Data::Dumper::Indent    = 1;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys  = 1;
$Data::Dumper::Useqq     = 1;
$Data::Dumper::Pad       = "    ";

# To add a test case:
# 1. Add a uniq key as test case name pointing to undef:
#     'new-test-case' => undef,
# 2. Run the test
# 3. From the test output copy the dumped array ref in place of undef
# All run command will be saved as files under resources/generic/databases so use
# a still not use test case name

my %db_tests = (
    'nodb'            => [],
    'oracle-19c-ORCLCDB-connect-failure' => [],
    'oracle-19c-ORCLCDB' => [
      {
        DATABASES => [
          {
            CREATION_DATE => "2021-07-27 06:35:22",
            IS_ACTIVE => 1,
            NAME => "ORCLCDB",
            SIZE => 1815,
            UPDATE_DATE => "2021-07-30 09:32:54"
          }
        ],
        LAST_BOOT_DATE => "2021-07-30 05:21:15",
        MANUFACTURER => "Oracle",
        IS_ACTIVE => 1,
        NAME => "ORCLCDB",
        PORT => 1521,
        SIZE => 1815,
        TYPE => "oracle",
        VERSION => "19.3.0.0.0"
      }
    ],
);

my %credentials = (
    # Set related credentials values when needed like port for a given test or
    # to generate the test case but don't forget to mask any sensible data after
    'oracle-19c-ORCLCDB-connect-failure' => [
        {
            login       => "SYS",
            password    => "******",
            host        => "192.168.5.2",
            type        => "login_password",
        },
    ],
    'oracle-19c-ORCLCDB' => [
        {
            login       => "SYS",
            password    => "******",
            socket      => "connect:192.168.5.2/ORCLCDB",
            type        => "login_password",
        },
    ],
);

my %oracle_home = (
    'ora1910-ora195-aix' => [ qw{
        /oracle/base/ora195
        /oracle/base/ora1910
    }],
    'ora195' => [ qw{
        /oracle/db/ora
    }],
);

plan tests => (2 * scalar keys %db_tests) + (scalar keys %oracle_home) +1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %oracle_home) {
    my $orahome = GLPI::Agent::Task::Inventory::Generic::Databases::Oracle::_oracleHome(
        file => "resources/generic/databases/$test-oraInst.loc",
    );
    cmp_deeply($orahome, $oracle_home{$test}, "$test: _oracleHome() parsing");
}

foreach my $test (keys %db_tests) {
    my $file  = "resources/generic/databases/$test";
    my $dbs   = GLPI::Agent::Task::Inventory::Generic::Databases::Oracle::_getDatabaseService(
        filebase    => $file,
        credentials => $credentials{$test} // [{}],
        istest      => defined($db_tests{$test}) ? 1 : 0,
    );
    my $entries = [ map { $_->entry() } @$dbs ];
    print STDERR "\n$test: ", Dumper($entries) unless defined($db_tests{$test});
    cmp_deeply($entries, $db_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'DATABASES_SERVICES', entry => $_) foreach @$entries;
    } "$test: registering";
}
