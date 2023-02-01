#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::More;
use Test::Exception;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Cwd;

use GLPI::Agent::Logger;
use GLPI::Test::Utils;

use GLPI::Agent::Task::Deploy::ActionProcessor;

my @test_paths = qw(
    folder1/
    folder1/file1
    folder2/
    folder2/file2
    folder2/folder3/
    folder2/folder3/file3
    folder1/file4
);

plan tests => 53 + scalar(@test_paths);

# Use current dir to fix issue with GH Actions on MacOSX
my $tmp = tempdir(DIR => getcwd(), CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);

# Required on win32
$tmp =~ s{\\}{/}g;

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

my $processor;
lives_ok {
    $processor = GLPI::Agent::Task::Deploy::ActionProcessor->new(
        logger  => GLPI::Agent::Logger->new(logger => [ 'Test' ]),
        workdir => $tmp
    );
} "Create action processor";

ok(getcwd() ne $tmp, "Not in workdir");

lives_ok {
    $processor->starting;
} "Start action processor";

ok(getcwd() eq $tmp, "Changed dir in workdir: expected '$tmp' but we're in '".getcwd()."'");

my $dest = tempdir(CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);
mkdir "$dest/delete_me";
ok(-d "$dest/delete_me", "Test delete_me folder created");

my $r;

################################################################################
# Mkdir action

ok(!-d "$dest/folder4", "Test folder4 is not existing");

lives_ok {
    $r = $processor->process(
        'mkdir',
        {
            list => [ "$dest/folder4" ],
        }
    );
} "Run mkdir action #1";

ok(-d "$dest/folder4", "Test folder4 existing");
ok($r->{status} && !@{$r->{msg}}, "Successful mkdir action");

# Create folders without parent
lives_ok {
    $r = $processor->process(
        'mkdir',
        {
            list => [ "$dest/folder4/folder5/folder6", "$dest/folder4/folder5/folder7" ],
        }
    );
} "Run mkdir action #2";

ok(-d "$dest/folder4/folder5", "Test folder5 is existing");
ok(-d "$dest/folder4/folder5/folder6", "Test folder6 is existing");
ok(-d "$dest/folder4/folder5/folder7", "Test folder7 is existing");
ok($r->{status} && !@{$r->{msg}}, "Successful mkdir action");

################################################################################
# Copy action
lives_ok {
    $r = $processor->process(
        'copy',
        {
            from => "folder1",
            to   => $dest,
        }
    );
} "Run copy action #1";

ok($r->{status} && !@{$r->{msg}}, "Successful copy action");

lives_ok {
    $r = $processor->process(
        'copy',
        {
            from => "folder2",
            to   => $dest,
        }
    );
} "Run copy action #2";

ok(-d "$dest/folder1" && -d "$dest/folder2", "Test copied folder are existing");
ok($r->{status} && !@{$r->{msg}}, "Successful copy action");

lives_ok {
    $r = $processor->process(
        'copy',
        {
            from => "folder1/file1",
            to   => "$dest/folder2/folder3",
        }
    );
} "Run copy action #3";

ok(-e "$dest/folder2/folder3/file1", "Test copied file1 is existing");
ok($r->{status} && !@{$r->{msg}}, "Successful copy action");

lives_ok {
    $r = $processor->process(
        'copy',
        {
            from => "*",
            to   => "$dest/folder2",
        }
    );
} "Run copy action #4";

ok(-d "$dest/folder2/folder1" && -e "$dest/folder2/folder1/file1", "Test copied folder1 & file1 are existing");
ok(-d "$dest/folder2/folder2" && -d "$dest/folder2/folder2/folder3", "Test copied folder2 & folder3 are existing");
ok($r->{status} && !@{$r->{msg}}, "Successful copy action");

lives_ok {
    $r = $processor->process(
        'copy',
        {
            from => "folder2/*",
            to   => "$dest/folder2/folder3",
        }
    );
} "Run copy action #5";

ok(-e "$dest/folder2/folder3/file2", "Test copied file2 is existing");
ok(-d "$dest/folder2/folder3/folder3" && -e "$dest/folder2/folder3/folder3/file3", "Test copied folder3 & file3 are existing");
ok($r->{status} && !@{$r->{msg}}, "Successful copy action");

################################################################################
# Mkdir action failure

lives_ok {
    $r = $processor->process(
        'mkdir',
        {
            list => [ "$dest/folder2/folder3/file2" ],
        }
    );
} "Run mkdir action #3";

ok(! -d "$dest/folder2/folder3/file2", "Test file2 can't be a folder");
ok(!$r->{status} && @{$r->{msg}}, "Unsuccessful mkdir action");
ok(grep { /Failed to create/ } @{$r->{msg}}, "Unsuccessful mkdir action error message");

################################################################################
# Move action
lives_ok {
    $r = $processor->process(
        'move',
        {
            from => "folder1/file1",
            to   => $dest,
        }
    );
} "Run move action #1";

ok(! -e "$tmp/folder1/file1" && -e "$dest/file1", "Test file1 has been moved");
ok($r->{status} && !@{$r->{msg}}, "Successful move action");

lives_ok {
    $r = $processor->process(
        'move',
        {
            from => "folder2/*",
            to   => $dest,
        }
    );
} "Run move action #2";

ok(!-d "$tmp/folder2/folder3" && !-e "$tmp/folder2/file2", "Test file2 & folder3 was removed");
ok(-e "$dest/file2" && -d "$dest/folder3" && -e "$dest/folder3/file3", "Test file2 & folder3 & file3 was moved");
ok($r->{status} && !@{$r->{msg}}, "Successful move action");

lives_ok {
    $r = $processor->process(
        'move',
        {
            from => "*",
            to   => "$dest/a/b/c/d",
        }
    );
} "Run move action #3";

ok(!-d "$tmp/folder1" && !-d "$tmp/folder2", "Test folder1 & folder2 was removed");
# folder1 was renamed to d as a/b/c was not existing, so file4 appears in d
ok(-e "$dest/a/b/c/d/file4" && -d "$dest/a/b/c/d/folder2", "Test file4 & folder2 was moved");
ok($r->{status} && !@{$r->{msg}}, "Successful move action");

################################################################################
# Delete action
lives_ok {
    $r = $processor->process(
        'delete',
        {
            list    => [ "$dest/delete_me" ]
        }
    );
} "Run delete action #1";

ok(! -d "$dest/delete_me", "Test delete_me folder was removed");
ok($r->{status} && !@{$r->{msg}}, "Successful delete action");

lives_ok {
    $r = $processor->process(
        'delete',
        {
            list    => [ "$dest/folder1", "$dest/folder2" ]
        }
    );
} "Run delete action #2";

ok(!-d "$dest/folder1" && !-d "$dest/folder2", "Test copied folder was removed");
ok($r->{status} && !@{$r->{msg}}, "Successful delete action");

################################################################################

lives_ok {
    $processor->done;
} "Finished action processor";

ok(getcwd() ne $tmp, "No more in workdir");
