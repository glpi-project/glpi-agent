#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::More;
use File::Temp qw(tempdir);
use File::Copy;
use File::Basename qw(dirname);
use File::Path qw(make_path);

plan tests => 6;

use GLPI::Agent::Tools;
use GLPI::Agent::Task::Deploy::File;

# Temp dir
my $datastoredir = tempdir(CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);
my $filedir = tempdir(CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);

open TOTO, ">$filedir/toto";
print TOTO "foobar\n";
close TOTO;
my $sha = Digest::SHA->new('512');
$sha->addfile( "$filedir/toto", 'b' );
my $sha512 = $sha->hexdigest();

# Create File object
my $file = GLPI::Agent::Task::Deploy::File->new(
   datastore => { path => $datastoredir },
   sha512 => "void",
   data => {multiparts => [ $sha512 ]}
);

################
ok($file, "GLPI::Agent::Task::Deploy::File object created");
my $partFilePath = $file->getPartFilePath($sha512);
ok($partFilePath, "getPartFilePath()");
ok(! -f $partFilePath, "file does not exist yet");
ok(!$file->filePartsExists(), "filePartsExists() fails");
make_path(dirname($partFilePath));
copy("$filedir/toto", $partFilePath);
ok(-f $file->getPartFilePath($sha512), "file exists");
ok($file->filePartsExists(), "filePartsExists() success");
