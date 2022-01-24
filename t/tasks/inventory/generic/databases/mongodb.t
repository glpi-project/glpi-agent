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
use GLPI::Agent::Logger;
use GLPI::Agent::Task::Inventory::Generic::Databases::MongoDB;

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
    'mongodb-5.0.1' => [
      {
        DATABASES => [
          {
            IS_ACTIVE => 1,
            NAME => "admin",
            SIZE => 0
          },
          {
            IS_ACTIVE => 1,
            NAME => "config",
            SIZE => 0
          },
          {
            IS_ACTIVE => 1,
            NAME => "local",
            SIZE => 0
          }
        ],
        LAST_BOOT_DATE => "2021-07-26 09:42:13",
        MANUFACTURER => "MongoDB",
        IS_ACTIVE => 1,
        NAME => "MongoDB",
        PORT => 27017,
        SIZE => 0,
        TYPE => "mongodb",
        VERSION => "5.0.1"
      }
    ],
    'mongodb-3.6.3' => [
      {
        DATABASES => [
          {
            IS_ACTIVE => 1,
            NAME => "admin",
            SIZE => 0
          },
          {
            IS_ACTIVE => 1,
            NAME => "config",
            SIZE => 0
          },
          {
            IS_ACTIVE => 1,
            NAME => "local",
            SIZE => 0
          }
        ],
        IS_ACTIVE => 1,
        LAST_BOOT_DATE => "2021-12-10 13:14:35",
        MANUFACTURER => "MongoDB",
        NAME => "MongoDB",
        PORT => 27017,
        SIZE => 0,
        TYPE => "mongodb",
        VERSION => "3.6.3"
      }
    ],
);

my %credentials = (
    # Set related credentials values when needed like port for a given test or
    # to generate the test case but don't forget to mask any sensible data after
);

plan tests => (2 * scalar keys %db_tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

my $logger = GLPI::Agent::Logger->new(
    config => GLPI::Agent::Config->new(
        options => {
            config => 'none',
            logger => 'Test'
        }
    )
);

foreach my $test (keys %db_tests) {
    my $file  = "resources/generic/databases/$test";
    my ($version) = $test =~ /^mongodb-(\d+)\./;
    my $dbs   = GLPI::Agent::Task::Inventory::Generic::Databases::MongoDB::_getDatabaseService(
        logger      => $logger,
        file        => $file,
        credentials => $credentials{$test} // [{}],
        istest      => $db_tests{$test} ? 1 : 0,
        # Since mongodb 5.0, "mongosh" command replaces "mongo" one
        mongosh     => $version && $version > 4 ? 1 : 0,
    );
    my $entries = [ map { $_->entry() } @$dbs ];
    print STDERR "\n$test: ", Dumper($entries) unless defined($db_tests{$test});
    cmp_deeply($entries, $db_tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'DATABASES_SERVICES', entry => $_) foreach @$entries;
    } "$test: registering";
}
