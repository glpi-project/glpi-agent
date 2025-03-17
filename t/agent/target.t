#!/usr/bin/perl

use strict;
use warnings;

use Config;
use English qw(-no_match_vars);
use File::Temp qw(tempdir);
use Test::More;
use Test::Exception;
use URI;

use GLPI::Agent::Target::Server;

plan tests => 24;

my $target;
throws_ok {
    $target = GLPI::Agent::Target::Server->new();
} qr/^no url parameter/,
'instanciation: no url';

throws_ok {
    $target = GLPI::Agent::Target::Server->new(
        url => 'http://foo/bar'
    );
} qr/^no basevardir parameter/,
'instanciation: no base directory';

my $basevardir = tempdir(CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);

lives_ok {
    $target = GLPI::Agent::Target::Server->new(
        url        => 'http://my.domain.tld/',
        basevardir => $basevardir
    );
} 'instanciation: ok';

my $storage_dir = $OSNAME eq 'MSWin32' ?
    "$basevardir/http..__my.domain.tld" :
    "$basevardir/http:__my.domain.tld" ;
ok(-d $storage_dir, "storage directory creation");
is($target->{id}, 'server0', "identifier");

$target = GLPI::Agent::Target::Server->new(
    url        => 'http://my.domain.tld',
    basevardir => $basevardir
);
is($target->getUrl(), 'http://my.domain.tld', 'missing path is okay');

$target = GLPI::Agent::Target::Server->new(
    url        => 'my.domain.tld',
    basevardir => $basevardir
);
is($target->getUrl(), 'http://my.domain.tld', 'bare hostname');

is($target->getMaxDelay(), 3600, 'default value');
my $nextRunDate = $target->getNextRunDate();

ok(-f "$storage_dir/target.dump", "state file existence");
$target = GLPI::Agent::Target::Server->new(
    url        => 'http://my.domain.tld',
    basevardir => $basevardir
);
is($target->getNextRunDate(), $nextRunDate, 'state persistence');

# Check target rundate apis
$target = GLPI::Agent::Target::Server->new(
    url        => 'http://my-2.domain.tld',
    basevardir => $basevardir
);

ok($target->getNextRunDate() >= time, 'next run date validity (inf)');
ok($target->getNextRunDate() <= time+$target->getMaxDelay(), 'next run date validity (sup)');
$target->resetNextRunDate();
ok($target->getNextRunDate() >= time+$target->getMaxDelay(), 'next run date validity after reset (inf)');
ok($target->getNextRunDate() <= time+2*$target->getMaxDelay(), 'next run date validity after reset (sup)');

$target->resetNextRunDate();
ok($target->getNextRunDate() >= time, 'next run date validity after reset on very later date (inf)');
ok($target->getNextRunDate() <= time+$target->getMaxDelay(), 'next run date validity after reset on very later date (sup)');

# Set baseRunDate in the past
$target->{baseRunDate} = time - 86400;
$target->resetNextRunDate();
ok($target->getNextRunDate() >= time, 'next run date validity with base in the past (inf)');
ok($target->getNextRunDate() <= time+$target->getMaxDelay(), 'next run date validity with base in the past (sup)');

# Set baseRunDate & nextRunDate in the past to be outdated on loading
$target->{nextRunDate} -= 86400;
$target->{baseRunDate} -= 86400;
$target->setMaxDelay(3600); # This also saves state
$target = GLPI::Agent::Target::Server->new(
    url        => 'http://my-2.domain.tld',
    basevardir => $basevardir
);
ok($target->getNextRunDate() >= time, 'next run date validity after outdated rundate (inf)');
ok($target->getNextRunDate() <= time+$target->getMaxDelay(), 'next run date validity after outdated rundate (sup)');

# Set baseRunDate & nextRunDate in the past near to be outdated on loading
$target->{nextRunDate} -= 3600;
$target->{baseRunDate} -= 3600;
$target->setMaxDelay(3600); # This also saves state
$target = GLPI::Agent::Target::Server->new(
    url        => 'http://my-2.domain.tld',
    basevardir => $basevardir
);
ok($target->getNextRunDate() >= time-$target->getMaxDelay(), 'next run date validity after outdated rundate (inf)');
ok($target->getNextRunDate() <= time, 'next run date validity after outdated rundate (sup)');
$target->resetNextRunDate();
ok($target->getNextRunDate() >= time, 'next run date validity (inf)');
ok($target->getNextRunDate() <= time+$target->getMaxDelay(), 'next run date validity (sup)');
