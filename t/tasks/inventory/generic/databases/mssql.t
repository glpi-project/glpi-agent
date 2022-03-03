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
use GLPI::Agent::Task::Inventory::Generic::Databases::MSSQL;

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
    'sql-server-2019' => [
      {
        DATABASES => [
          {
            CREATION_DATE => "2003-04-08 09:13:36",
            IS_ACTIVE => 1,
            NAME => "master",
            SIZE => 7,
            UPDATE_DATE => "2021-07-12 18:01:50"
          },
          {
            CREATION_DATE => "2021-07-12 20:35:59",
            IS_ACTIVE => 1,
            NAME => "tempdb",
            SIZE => 40,
            UPDATE_DATE => "2021-07-13 16:37:37"
          },
          {
            CREATION_DATE => "2003-04-08 09:13:36",
            IS_ACTIVE => 1,
            NAME => "model",
            SIZE => 16,
            UPDATE_DATE => "2021-07-12 18:01:50"
          },
          {
            CREATION_DATE => "2019-09-24 14:21:42",
            IS_ACTIVE => 1,
            NAME => "msdb",
            SIZE => 44,
            UPDATE_DATE => "2021-07-12 20:35:51"
          },
          {
            CREATION_DATE => "2021-07-12 18:37:22",
            IS_ACTIVE => 1,
            NAME => "AdventureWorks2019",
            SIZE => 336,
            UPDATE_DATE => "2020-06-15 10:36:59"
          }
        ],
        MANUFACTURER => "Microsoft",
        NAME => "SQL Server 2019",
        IS_ACTIVE => 1,
        SIZE => 443,
        PORT => 1433,
        LAST_BOOT_DATE => "2021-07-12 20:35:57",
        TYPE => "mssql",
        VERSION => "15.0.2080.9"
      }
    ],
    'sql-server-2017-on-linux' => [
      {
        DATABASES => [
          {
            CREATION_DATE => "2003-04-08 09:13:36",
            IS_ACTIVE => 1,
            NAME => "master",
            SIZE => 7,
            UPDATE_DATE => "2021-07-15 14:44:50"
          },
          {
            CREATION_DATE => "2021-07-16 08:56:37",
            IS_ACTIVE => 1,
            NAME => "tempdb",
            SIZE => 16,
            UPDATE_DATE => "2021-07-16 09:15:02"
          },
          {
            CREATION_DATE => "2003-04-08 09:13:36",
            IS_ACTIVE => 1,
            NAME => "model",
            SIZE => 16,
            UPDATE_DATE => "2021-07-15 14:44:50"
          },
          {
            CREATION_DATE => "2021-06-25 16:01:11",
            IS_ACTIVE => 1,
            NAME => "msdb",
            SIZE => 21,
            UPDATE_DATE => "2021-07-15 14:44:55"
          }
        ],
        MANUFACTURER => "Microsoft",
        NAME => "SQL Server 2017",
        IS_ACTIVE => 1,
        SIZE => 60,
        PORT => 1433,
        LAST_BOOT_DATE => "2021-07-16 08:56:37",
        TYPE => "mssql",
        VERSION => "14.0.3401.7"
      }
    ],
    'sql-server-2012-express' => [
      {
        DATABASES => [
          {
            CREATION_DATE => "2003-04-08 09:13:36",
            IS_ACTIVE => 1,
            NAME => "master",
            SIZE => 6,
            UPDATE_DATE => "2012-02-10 21:14:52"
          },
          {
            CREATION_DATE => "2022-03-03 11:28:07",
            IS_ACTIVE => 1,
            NAME => "tempdb",
            SIZE => 4,
            UPDATE_DATE => "2022-03-03 11:28:07"
          },
          {
            CREATION_DATE => "2003-04-08 09:13:36",
            IS_ACTIVE => 1,
            NAME => "model",
            SIZE => 5,
            UPDATE_DATE => "2012-02-10 20:16:02"
          },
          {
            CREATION_DATE => "2012-02-10 21:02:17",
            IS_ACTIVE => 1,
            NAME => "msdb",
            SIZE => 21,
            UPDATE_DATE => "2022-03-03 11:28:02"
          }
        ],
        IS_ACTIVE => 1,
        LAST_BOOT_DATE => "2022-03-03 11:28:07",
        MANUFACTURER => "Microsoft",
        NAME => "SQL Server 2012",
        PORT => 1433,
        SIZE => 37,
        TYPE => "mssql",
        VERSION => "11.0.2100.60"
      }
    ]);

my %credentials = (
    # Set related credentials values when needed like port for a given test or
    # to generate the test case but don't forget to mask any sensible data after

    # Define a credential for sql-server-2019 to avoid a duplicate inventory during test
    'sql-server-2019' => [
        {
            login       => "SA",
            password    => "********",
            type    => "login_password",
        },
    ],
    'sql-server-2017-on-linux' => [
        {
            login       => "SA",
            password    => "********",
            type        => "login_password",
        },
    ],
    'sql-server-2012-express' => [
        {
            socket  => "localhost\\SQLExpress",
            type    => "login_password",
        },
    ],
);

plan tests => (2 * scalar keys %db_tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %db_tests) {
    my $file  = "resources/generic/databases/$test";
    my $dbs   = GLPI::Agent::Task::Inventory::Generic::Databases::MSSQL::_getDatabaseService(
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
