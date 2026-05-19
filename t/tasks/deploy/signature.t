#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Digest::SHA;

use GLPI::Agent::Task::Deploy;
use GLPI::Agent::Config;
use GLPI::Agent::Logger;

my $logger = GLPI::Agent::Logger->new(logger => ['Stderr']);
my $config = GLPI::Agent::Config->new();

# Mock target
package MockTarget;
sub new { bless {}, shift }
sub isType { 1 }

package main;
my $target_obj = MockTarget->new();

my $task = GLPI::Agent::Task::Deploy->new(
    target => $target_obj,
    config => $config,
    logger => $logger,
);

# Mock workdir object
{
    package MockWorkDir;
    sub new {
        my ($class, $path) = @_;
        bless { path => $path }, $class;
    }
    sub path { shift->{path} }
}

# Mock Crypt::Ed25519
our $ed_available = 1;
{
    package Crypt::Ed25519;
    sub require { return $main::ed_available }
    sub verify {
        my ($msg, $pub_bin, $sig_bin) = @_;
        # For testing, we consider it valid if signature hex ends with '01'
        return unpack("H*", $sig_bin) =~ /01$/;
    }
}
$INC{'Crypt/Ed25519.pm'} = 1;

# Helper to create a workdir with files
sub create_workdir {
    my ($files) = @_;
    my $dir = tempdir(CLEANUP => 1);
    foreach my $name (keys %$files) {
        my $path = File::Spec->catfile($dir, $name);
        open my $fh, '>', $path or die $!;
        print $fh $files->{$name};
        close $fh;
    }
    return MockWorkDir->new($dir);
}

sub get_sha512 {
    my ($content) = @_;
    my $sha = Digest::SHA->new(512);
    $sha->add($content);
    return $sha->hexdigest;
}

# 1. No public key in config
$task->{config}->{'deploy-public-key'} = undef;
is($task->_verifySignature(workdir => MockWorkDir->new('/tmp')), 1, "Skip if no public key");

# 2. Public key defined but signature file missing
$task->{config}->{'deploy-public-key'} = '0' x 64;
my $wd2 = create_workdir({ 'file1.txt' => 'content1' });
is($task->_verifySignature(workdir => $wd2), 0, "Fail if signature file missing");

# 3. Crypt::Ed25519 missing
$ed_available = 0;
my $wd3 = create_workdir({ 'signature.sig' => 'foo' });
is($task->_verifySignature(workdir => $wd3), 0, "Fail if Crypt::Ed25519 missing");
$ed_available = 1;

# 4. Invalid public key length
$task->{config}->{'deploy-public-key'} = 'abc'; # too short
my $wd4 = create_workdir({ 'signature.sig' => 'foo' });
is($task->_verifySignature(workdir => $wd4), 0, "Fail if public key length invalid");
$task->{config}->{'deploy-public-key'} = '0' x 64;

# 5. Unknown signature file format
my $wd5 = create_workdir({ 'signature.sig' => 'not_a_hex_signature_of_128_chars' });
is($task->_verifySignature(workdir => $wd5), 0, "Fail if signature file format unknown");

# 6. Invalid signature
my $bad_sig = '0' x 128; # doesn't end with 01
my $manifest = get_sha512('content1') . " file1.txt\n";
my $wd6 = create_workdir({
    'signature.sig' => $bad_sig . "\n" . $manifest,
    'file1.txt'     => 'content1'
});
is($task->_verifySignature(workdir => $wd6), 0, "Fail if signature invalid");

# 7. Valid signature but file missing from manifest
my $good_sig = ('0' x 126) . '01';
my $wd7 = create_workdir({
    'signature.sig' => $good_sig . "\n" . $manifest,
    # file1.txt is missing
});
is($task->_verifySignature(workdir => $wd7), 0, "Fail if file missing from manifest");

# 8. Valid signature but hash mismatch
my $wd8 = create_workdir({
    'signature.sig' => $good_sig . "\n" . $manifest,
    'file1.txt'     => 'WRONG CONTENT'
});
is($task->_verifySignature(workdir => $wd8), 0, "Fail if hash mismatch");

# 9. Security check: invalid file path in manifest (attempting to go out of workdir)
my $bad_manifest = get_sha512('content') . " ../etc/passwd\n";
my $wd9 = create_workdir({
    'signature.sig' => $good_sig . "\n" . $bad_manifest,
});
is($task->_verifySignature(workdir => $wd9), 0, "Fail if manifest contains invalid paths");

# 10. Valid signature and manifest (format 1: signature then manifest)
my $wd10 = create_workdir({
    'signature.sig' => $good_sig . "\n" . $manifest,
    'file1.txt'     => 'content1'
});
is($task->_verifySignature(workdir => $wd10), 1, "Success with valid signature and manifest");

# 11. Valid signature and manifest (format 2: manifest then signature at end)
my $manifest2 = get_sha512('content1') . " file1.txt";
my $content2 = $manifest2 . "\n# Signature: " . $good_sig;
my $wd11 = create_workdir({
    'signature.sig' => $content2,
    'file1.txt'     => 'content1'
});
is($task->_verifySignature(workdir => $wd11), 1, "Success with valid signature at end of manifest");

# 12. Multiple files
my $manifest3 = get_sha512('c1') . " f1.txt\n" . get_sha512('c2') . " f2.txt\n";
my $wd12 = create_workdir({
    'signature.sig' => $good_sig . "\n" . $manifest3,
    'f1.txt'        => 'c1',
    'f2.txt'        => 'c2'
});
is($task->_verifySignature(workdir => $wd12), 1, "Success with multiple files");

# 13. Public key in a file
my $pk_dir = tempdir(CLEANUP => 1);
my $pk_file = File::Spec->catfile($pk_dir, 'public.key');
open my $pkfh, '>', $pk_file or die $!;
print $pkfh "0" x 64;
close $pkfh;
$task->{config}->{'deploy-public-key'} = $pk_file;
my $wd13 = create_workdir({
    'signature.sig' => $good_sig . "\n" . $manifest,
    'file1.txt'     => 'content1'
});
is($task->_verifySignature(workdir => $wd13), 1, "Success with public key in file");


# 14. Public key file is world-writable (security check)
SKIP: {
    skip "World-writable check not reliable on MSWin32", 1 if $^O eq 'MSWin32';
    my $pk_dir_bad = tempdir(CLEANUP => 1);
    my $pk_file_bad = File::Spec->catfile($pk_dir_bad, 'public_bad.key');
    open my $pkfh_bad, '>', $pk_file_bad or die $!;
    print $pkfh_bad "0" x 64;
    close $pkfh_bad;
    chmod 0666, $pk_file_bad;
    $task->{config}->{'deploy-public-key'} = $pk_file_bad;
    is($task->_verifySignature(workdir => $wd13), 0, "Fail if public key file is world-writable");
}


# 15. Security check: Zip Slip / Path Traversal protection in Archive.pm
{
    my $zip_slip_dir = tempdir(CLEANUP => 1);
    my $archive_path = File::Spec->catfile($zip_slip_dir, 'malicious.tar.gz');
    
    # We can't easily create a real malicious tar.gz with .. here without external tools
    # but we can mock the files() method of Archive object to simulate one.
    my $archive = GLPI::Agent::Tools::Archive->new(
        archive => $archive_path,
        secure  => 1,
    );
    if ($archive) {
        # Force a malicious file list
        $archive->files(['valid.txt', '../../../../etc/passwd']);
        # Mock a backend success
        no warnings 'redefine';
        local *GLPI::Agent::Tools::Archive::_untar_at = sub { 1 };
        
        ok(!$archive->extract(to => $zip_slip_dir), "Archive extraction fails if traversal detected (hardened)");
    }
    
    # Verify it succeeds if secure is off (default/backward compatibility)
    my $archive2 = GLPI::Agent::Tools::Archive->new(
        archive => $archive_path,
        secure  => 0,
    );
    if ($archive2) {
        $archive2->files(['valid.txt', '../../../../etc/passwd']);
        no warnings 'redefine';
        local *GLPI::Agent::Tools::Archive::_untar_at = sub { 1 };
        ok($archive2->extract(to => $zip_slip_dir), "Archive extraction succeeds if traversal detected but secure is off");
    }
}

done_testing();
