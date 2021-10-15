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
use GLPI::Agent::Task::Inventory::Generic::Databases::DB2;

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
    'db2-connect-failure' => [
      {
        IS_ACTIVE       => 1,
        MANUFACTURER    => "IBM",
        NAME            => "db2inst1",
        PORT            => 50000,
        SIZE            => 0,
        TYPE            => "db2",
        VERSION         => "11.5.6.0"
      }
    ],
    'db2-linux-11.5.6.0' => [
      {
        DATABASES => [
          {
            CREATION_DATE   => "2021-08-11 06:52:10",
            IS_ACTIVE       => 1,
            NAME            => "TESTDB",
            SIZE            => 119,
            UPDATE_DATE     => "2021-09-02 10:45:08"
          }
        ],
        IS_ACTIVE       => 1,
        LAST_BOOT_DATE  => "2021-02-09 07:00:05",
        MANUFACTURER    => "IBM",
        NAME            => "db2inst1",
        PORT            => 50000,
        SIZE            => 119,
        TYPE            => "db2",
        VERSION         => "11.5.6.0"
      }
    ],
);

my %credentials = (
    # Set related credentials values when needed like port for a given test or
    # to generate the test case but don't forget to mask any sensible data after
    'db2-connect-failure' => [
        {
            login       => "SYS",
            password    => "******",
            socket      => "192.168.5.2:50000/testdb",
            type        => "login_password",
        },
    ],
    'db2-linux-11.5.6.0' => [
        {
            login       => "SYS",
            password    => "**********",
            socket      => "192.168.5.2:50000/testdb",
            type        => "login_password",
        },
    ],
);

plan tests => (2 * scalar keys %db_tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %db_tests) {
    my $file  = "resources/generic/databases/$test";
    my $dbs   = GLPI::Agent::Task::Inventory::Generic::Databases::DB2::_getDatabaseService(
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
