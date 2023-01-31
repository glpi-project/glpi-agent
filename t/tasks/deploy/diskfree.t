#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::More;
use File::Path qw(make_path);
use File::Temp qw(tempdir);

use GLPI::Agent::Task::Deploy::DiskFree;

my @test_paths = qw(
    folder1/
    folder1/file1
    folder2/
    folder2/file2
    folder2/folder3/
    folder2/folder3/file3
);

plan tests => 8 + scalar(@test_paths);

my $tmp = tempdir(CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);

ok(getFreeSpace(path => $tmp) > 0, "getFreeSpace()");

# Create simple folder tree
foreach my $path (@test_paths) {
    my $testpath = $tmp."/".$path;
    if ($path =~ m{/$}) {
        make_path($testpath);
        ok(-d $testpath, "Test folder created: $testpath");
    } else {
        my $fh;
        open $fh, ">", $testpath
            or die "Can't create test file: $testpath\n";
        print $fh "Some datas...\n";
        close($fh);
        ok(-s $testpath, "Test file created: $testpath");
    }
}

ok(remove_tree($tmp."/folder1"), "folder1 tree removing");
ok(! -d $tmp."/folder1", "folder1 deleted");
ok(-d $tmp."/folder2", "folder2 still exists");
ok(remove_tree($tmp."/folder2"), "folder2 tree removing");
ok(! -d $tmp."/folder2", "folder3 deleted");
ok(! -d $tmp."/folder3", "folder3 not exists");
ok(remove_tree($tmp."/folder3"), "unexisting folder3 tree removing");
