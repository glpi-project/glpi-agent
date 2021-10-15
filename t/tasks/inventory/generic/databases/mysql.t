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
use GLPI::Agent::Task::Inventory::Generic::Databases::MySQL;

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
    'mariadb-10.4.19' => [
      {
        DATABASES => [
          {
            CREATION_DATE => "2014-09-07 21:50:35",
            IS_ACTIVE => 1,
            NAME => "asteriskcdrdb",
            SIZE => 1,
            UPDATE_DATE => "2014-09-07 21:50:35"
          },
          {
            CREATION_DATE => "2015-09-29 20:15:36",
            IS_ACTIVE => 1,
            NAME => "beacon",
            SIZE => 0
          },
          {
            CREATION_DATE => "2015-05-19 15:39:23",
            IS_ACTIVE => 1,
            NAME => "glpi",
            SIZE => 52,
            UPDATE_DATE => "2015-10-01 17:03:02"
          },
          {
            CREATION_DATE => "2021-07-01 18:50:43",
            IS_ACTIVE => 1,
            NAME => "information_schema",
            SIZE => 0,
            UPDATE_DATE => "2021-07-01 18:50:43"
          },
          {
            CREATION_DATE => "2014-09-07 21:49:47",
            IS_ACTIVE => 1,
            NAME => "mysql",
            SIZE => 0,
            UPDATE_DATE => "2015-09-29 20:13:04"
          },
          {
            IS_ACTIVE => 1,
            NAME => "performance_schema",
            SIZE => 0
          },
          {
            IS_ACTIVE => 1,
            NAME => "test"
          }
        ],
        MANUFACTURER => "MariaDB",
        NAME => "MariaDB",
        IS_ACTIVE => 1,
        SIZE => 55,
        PORT => 3306,
        LAST_BOOT_DATE => "2021-07-26 10:34:13",
        TYPE => "mysql",
        VERSION => "10.4.19"
      }
    ],
);

my %credentials = (
    # Set related credentials values when needed like port for a given test or
    # to generate the test case but don't forget to mask any sensible data after
);

plan tests => (2 * scalar keys %db_tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %db_tests) {
    my $file  = "resources/generic/databases/$test";
    my $dbs   = GLPI::Agent::Task::Inventory::Generic::Databases::MySQL::_getDatabaseService(
        file        => $file,
        credentials => $credentials{$test} // [{}],
        istest      => $db_tests{$test} ? 1 : 0,
    );
    my $entries = [ map { $_->entry() } @$dbs ];
    print STDERR "\n$test: ", Dumper($entries) unless defined($db_tests{$test});
    cmp_deeply($entries, $db_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'DATABASES_SERVICES', entry => $_) foreach @$entries;
    } "$test: registering";
}
