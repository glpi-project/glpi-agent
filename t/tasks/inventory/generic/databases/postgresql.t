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
use GLPI::Agent::Task::Inventory::Generic::Databases::PostgreSQL;

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
    'postgresql-f33' => [
      {
        DATABASES => [
          {
            CREATION_DATE => "2021-07-23 15:06:52",
            IS_ACTIVE => 1,
            NAME => "template1",
            SIZE => 8,
            UPDATE_DATE => "2021-07-23 19:11:05"
          },
          {
            CREATION_DATE => "2021-07-23 15:06:52",
            IS_ACTIVE => 1,
            NAME => "template0",
            SIZE => 8,
            UPDATE_DATE => "2021-07-23 19:10:45"
          },
          {
            CREATION_DATE => "2021-07-23 15:06:52",
            IS_ACTIVE => 1,
            NAME => "postgres",
            SIZE => 8,
            UPDATE_DATE => "2021-07-23 19:10:25"
          }
        ],
        LAST_BOOT_DATE => "2021-07-23 19:10:05",
        MANUFACTURER => "PostgreSQL",
        IS_ACTIVE => 1,
        NAME => "PostgreSQL",
        PORT => 5432,
        SIZE => 24,
        TYPE => "postgresql",
        VERSION => "12.7"
      }
    ],
);

my %credentials = (
    # Set related credentials values when needed like port for a given test or
    # to generate the test case but don't forget to mask any sensible data after
    'postgresql-f33' => [
        {
            login       => "postgres",
            password    => "********",
            host        => "127.0.0.1",
            type        => "login_password",
        },
    ],
);

plan tests => (2 * scalar keys %db_tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %db_tests) {
    my $file  = "resources/generic/databases/$test";
    my $dbs   = GLPI::Agent::Task::Inventory::Generic::Databases::PostgreSQL::_getDatabaseService(
        file        => $file,
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
