#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Temp qw(tempdir);
use Test::Deep;
use Test::Exception;
use Test::More;

use GLPI::Agent::Storage;

plan tests => 16;

my $storage;
throws_ok {
    $storage = GLPI::Agent::Storage->new();
} qr/^no directory parameter/,
'instanciation: no directory';

my $basedir = tempdir(CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);
my $readdir = "$basedir/read";
mkdir $readdir;
chmod 0555, $readdir;

SKIP: {
    skip "chmod doesn't work on Windows", 2 if $OSNAME eq 'MSWin32';
    skip ", not applicable: test runned by root", 2 if $UID == 0;
    throws_ok {
        $storage = GLPI::Agent::Storage->new(
            directory => $readdir
        );
    } qr/^Can't write in/,
    'instanciation: non-writable directory';

    throws_ok {
        $storage = GLPI::Agent::Storage->new(
            directory => "$readdir/subdir"
        );
    } qr/^Can't create/,
    'instanciation: non-creatable subdirectory';
}

my $writedir = "$basedir/write";
mkdir $writedir;
chmod 0755, $writedir;

lives_ok {
    $storage = GLPI::Agent::Storage->new(
        directory => $writedir
    );
} 'instanciation: writable directory';

lives_ok {
    $storage = GLPI::Agent::Storage->new(
        directory => "$writedir/subdir"
    );
} 'instanciation: creatable subdirectory';

ok(-d "$writedir/subdir", "subdirectory creation");

throws_ok {
    $storage->has();
} qr/^no name parameter/,
'has: no name';

ok(!$storage->has(name => 'test'), "content existence");

throws_ok {
    $storage->restore();
} qr/^no name parameter/,
'restore: no name';

ok(!defined $storage->restore(name => 'test'), "content retrieval");

throws_ok {
    $storage->save(data => { foo => "bar" });
} qr/^no name parameter/,
'save: no name';

$storage->save(name => 'test', data => { foo => "bar" });

ok($storage->has(name => 'test'), "content existence");
cmp_deeply(
    $storage->restore(name => 'test'),
    { foo => "bar" },
    "content retrieval"
);

ok(-f "$writedir/subdir/test.dump", "file presence");

throws_ok {
    $storage->remove();
} qr/^no name parameter/,
'remove: no name';

$storage->remove(name => 'test');

ok(!-f "$writedir/subdir/test.dump", "file removal");
