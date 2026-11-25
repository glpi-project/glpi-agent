#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Cpanel::JSON::XS;
use Digest::SHA qw(sha512_hex);
use File::Spec;
use File::Temp qw(tempdir);
use Storable qw(dclone);
use Test::More;
use Test::MockObject;
use Test::MockModule;

use GLPI::Agent::Logger;
use GLPI::Agent::Task::Deploy;
use GLPI::Agent::Task::Deploy::Signature qw(jobDigest actionDigest validFilename);
use GLPI::Agent::Task::Deploy::ActionProcessor;
use GLPI::Agent::Task::Deploy::Datastore;
use GLPI::Agent::Task::Deploy::Datastore::WorkDir;
use GLPI::Agent::Task::Deploy::Job;

my $logger = GLPI::Agent::Logger->new(logger => ['Stderr']);

sub write_file {
    my ($path, $content) = @_;
    open my $handle, '>', $path or die $!;
    binmode $handle;
    print {$handle} $content;
    close $handle or die $!;
}

subtest 'Reject unsafe transport metadata before cache access' => sub {
    my $sha = 'a' x 128;
    my $answer = {
        associatedFiles => { $sha => {
            name => 'agent.cfg', multiparts => [$sha], mirrors => [], p2p => 0,
            'p2p-retention-duration' => 60, uncompress => 0,
        } },
        jobs => [{ uuid => 'abc-123', actions => [], checks => [], associatedFiles => [$sha] }],
    };
    my $message;
    ok(GLPI::Agent::Task::Deploy::_validateAnswer(\$message, $answer), 'Valid transport metadata accepted');
    foreach my $mutate (
        sub { $_[0]->{associatedFiles}->{'../bad'} = delete $_[0]->{associatedFiles}->{$sha}; },
        sub { $_[0]->{associatedFiles}->{$sha}->{multiparts} = ['../../cache']; },
        sub { $_[0]->{associatedFiles}->{$sha}->{multiparts} = [{}]; },
        sub { $_[0]->{associatedFiles}->{$sha}->{multiparts} = [undef]; },
        sub { $_[0]->{associatedFiles}->{$sha}->{name} = 'file:stream'; },
        sub { $_[0]->{associatedFiles}->{$sha}->{name} = '..\\outside'; },
        sub { $_[0]->{associatedFiles}->{$sha} = []; },
        sub { $_[0]->{jobs} = {}; },
        sub { $_[0]->{jobs} = [[]]; },
        sub { $_[0]->{jobs}->[0]->{associatedFiles} = {}; },
        sub { $_[0]->{jobs}->[0]->{uuid} = "abc\n"; },
    ) {
        my $changed = dclone($answer);
        $mutate->($changed);
        my $result = eval { GLPI::Agent::Task::Deploy::_validateAnswer(\$message, $changed) };
        is($@, '', 'Malformed metadata does not crash validation');
        ok(!$result && length($message), 'Malformed metadata rejected explicitly');
    }
};

subtest 'Portable staging and no extraction before authentication' => sub {
    foreach my $name ('../outside', '..\\outside', 'C:config', '/etc/config',
            'file:stream', 'NUL.txt', 'CON', 'CONIN$', 'CONOUT$', 'COM' . chr(0xb9),
            'name.', 'name ', "line\nbreak", '.', '..') {
        ok(!validFilename($name), "Reject unsafe name: " . unpack('H*', $name));
    }
    ok(validFilename('payload.tar.gz'), 'Archive can be transported as an opaque file');
    my $directory = tempdir(CLEANUP => 1);
    my $datastore = GLPI::Agent::Task::Deploy::Datastore->new(
        path => $directory, config => { 'deploy-public-key' => 'a' x 64 }, logger => $logger);
    my $first = $datastore->createWorkDir('abc');
    my $second = $datastore->createWorkDir('abc');
    isnt($first->path(), $second->path(), 'Repeated job IDs have independent staging directories');
    SKIP: {
        skip 'Unix permissions only', 1 if $^O eq 'MSWin32';
        is((stat($first->path()))[2] & 0777, 0700, 'Staging directory is private');
    }
    foreach my $files (
        [{ name => 'payload.zip', uncompress => 1 }],
        [{ name => '../outside', uncompress => 0 }],
        [{ name => 'same.cfg' }, { name => 'SAME.cfg' }],
    ) {
        my $stage = $datastore->createWorkDir('abc');
        $stage->addFile($_) foreach @$files;
        my $archive_mock = Test::MockModule->new('GLPI::Agent::Tools::Archive');
        my $extracted = 0;
        $archive_mock->redefine(extract => sub { $extracted++; die 'Must not extract'; });
        my $workdir_mock = Test::MockModule->new('GLPI::Agent::Task::Deploy::Datastore::WorkDir');
        $workdir_mock->redefine(canRun => sub { $extracted++; die 'Must not launch 7z'; });
        ok(!$stage->prepare(signed => 1), 'Unsafe preparation rejected before writing');
        is($extracted, 0, 'No archive backend is used');
        opendir my $handle, $stage->path() or die $!;
        my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $handle;
        closedir $handle;
        is(scalar(@entries), 0, 'No reconstructed file is created');
    }
    write_file(File::Spec->catfile($first->path(), 'stale'), 'old');
    ok(!$first->prepare(signed => 1), 'Nonempty staging directory is rejected');
};

subtest 'Real signatures bind the entire deployment plan' => sub {
    plan skip_all => 'Crypt::Ed25519 needed for real crypto tests'
        unless eval { require Crypt::Ed25519; 1 };
    my $directory = tempdir(CLEANUP => 1);
    my $payload = File::Spec->catdir($directory, 'payload');
    mkdir $payload or die $!;
    write_file(File::Spec->catfile($payload, 'source.cfg'), 'approved configuration');
    write_file(File::Spec->catfile($payload, 'moved.cfg'), 'approved move');
    my $destination = File::Spec->catfile($directory, 'host.cfg');
    my $victim = File::Spec->catfile($directory, 'delete-me');
    write_file($victim, 'temporary fixture');
    my $job = {
        actions => [
            { mkdir => { list => [File::Spec->catdir($directory, 'created')] } },
            { copy => { from => 'source.cfg', to => $destination, checks => [] } },
            { move => { from => 'moved.cfg', to => File::Spec->catfile($directory, 'moved-target') } },
            { delete => { list => [$victim] } },
            { cmd => { exec => 'echo signed', envs => { GLPI_AUDIT_VALUE => 'approved' } } },
        ],
        checks => [{ type => 'fileExists', path => File::Spec->catfile($payload, 'source.cfg') }],
        requires => { 'softwares-inventory' => 0 },
        userinteractions => [],
    };
    my $seed = chr(3) x 32;
    my ($public, $private) = Crypt::Ed25519::generate_keypair($seed);
    my $key = File::Spec->catfile($directory, 'private.key');
    my $plan = File::Spec->catfile($directory, 'job.json');
    write_file($key, unpack('H*', $seed));
    write_file($plan, Cpanel::JSON::XS->new->utf8->canonical->encode($job));
    system($^X, 'tools/glpi-sign-package.pl', '--dir', $payload, '--key', $key, '--job', $plan);
    is($?, 0, 'Signing tool signs the complete JSON plan');
    my $workdir = Test::MockObject->new();
    $workdir->set_always('path', $payload);
    my $task = bless {
        config => { 'deploy-public-key' => unpack('H*', $public) }, logger => $logger,
    }, 'GLPI::Agent::Task::Deploy';
    my $verifier = $task->_signatureVerifier(unpack('H*', $public));
    my $verify = sub {
        $task->_verifySignature(workdir => $workdir, verify => $verifier, job => $_[0] // $job);
    };
    my $processor = GLPI::Agent::Task::Deploy::ActionProcessor->new(workdir => $payload, logger => $logger);
    ok($verify->(), 'Original signed plan accepted');

    my @mutations = (
        ['copy destination', sub { $_[0]->{actions}->[1]->{copy}->{to} .= '.other'; }],
        ['copy source', sub { $_[0]->{actions}->[1]->{copy}->{from} = 'unsigned.cfg'; }],
        ['move destination', sub { $_[0]->{actions}->[2]->{move}->{to} .= '.other'; }],
        ['delete target', sub { push @{$_[0]->{actions}->[3]->{delete}->{list}}, $destination; }],
        ['mkdir target', sub { push @{$_[0]->{actions}->[0]->{mkdir}->{list}}, $destination; }],
        ['environment', sub { $_[0]->{actions}->[4]->{cmd}->{envs}->{PATH} = '/untrusted'; }],
        ['command', sub { $_[0]->{actions}->[4]->{cmd}->{exec} = 'echo altered'; }],
        ['action order', sub { @{$_[0]->{actions}} = reverse @{$_[0]->{actions}}; }],
        ['action removal', sub { pop @{$_[0]->{actions}}; }],
        ['action insertion', sub { push @{$_[0]->{actions}}, { cmd => { exec => 'echo altered' } }; }],
        ['job check', sub { $_[0]->{checks}->[0]->{path} = '/other'; }],
        ['action check', sub { push @{$_[0]->{actions}->[1]->{copy}->{checks}}, { type => 'fileExists', path => '/other' }; }],
        ['requirements', sub { $_[0]->{requires}->{'softwares-inventory'} = 1; }],
        ['user interaction', sub { push @{$_[0]->{userinteractions}}, { type => 'before', title => 'altered' }; }],
    );
    foreach my $mutation (@mutations) {
        my $changed = dclone($job);
        $mutation->[1]->($changed);
        ok(!$verify->($changed), "Reject modified $mutation->[0]");

    }
    ok(!-e $destination, 'Rejected plans never modified the simulated host configuration');

    my $authorized = $verify->();
    ok($authorized, 'Restore original plan');
    foreach my $action (@{$job->{actions}}) {
        my $changed = dclone($action);
        my ($name) = keys %$changed;
        $changed->{$name}->{unsigned_parameter} = 1;
        ok(!$processor->process($name, $changed->{$name}, $authorized)->{status},
            "Central dispatcher rejects changed $name parameters");
    }

    write_file(File::Spec->catfile($payload, 'unsigned.cfg'), 'injected');
    ok(!$verify->(), 'Extra unsigned file rejected');
    unlink File::Spec->catfile($payload, 'unsigned.cfg');
    mkdir File::Spec->catdir($payload, 'extra-directory') or die $!;
    ok(!$verify->(), 'Extra directory rejected');
    rmdir File::Spec->catdir($payload, 'extra-directory');
    SKIP: {
        skip 'Symlink support required', 1 if $^O eq 'MSWin32';
        my $link = File::Spec->catfile($payload, 'link.cfg');
        symlink($victim, $link) or die $!;
        ok(!$verify->(), 'Symlink entry rejected');
        unlink $link;
    }
    SKIP: {
        my $link = File::Spec->catfile($payload, 'hardlink.cfg');
        skip 'Hard links unavailable', 1 unless link(File::Spec->catfile($payload, 'source.cfg'), $link);
        ok(!$verify->(), 'Hard-linked entry rejected');
        unlink $link;
    }
    my $signature = File::Spec->catfile($payload, 'signature.sig');
    open my $handle, '<', $signature or die $!;
    my $original = do { local $/; <$handle> };
    close $handle;
    write_file(File::Spec->catfile($payload, 'manifest.sig'), $original);
    ok(!$verify->(), 'Two competing signature files are rejected');
    unlink File::Spec->catfile($payload, 'manifest.sig');
    my $manifest = 'GLPI-DEPLOY-SIGNATURE 2' . "\nJOB " . jobDigest($job) . "\n";
    my $sign_manifest = sub {
        my ($content) = @_;
        write_file($signature, unpack('H*', Crypt::Ed25519::sign($content, $public, $private)) . "\n" . $content);
    };
    foreach my $invalid (
        sha512_hex('approved configuration') . " source.cfg\n",
        $manifest . "UNKNOWN entry\n",
        $manifest . (sha512_hex('approved configuration') . " source.cfg\n") x 2,
        $manifest . sha512_hex('approved configuration') . " ../outside\n",
    ) {
        $sign_manifest->($invalid);
        ok(!$verify->(), 'Reject legacy, malformed, duplicate or escaping signed manifest');
    }
    write_file($signature, $original);

    my $checked = GLPI::Agent::Task::Deploy::Job->new(data => dclone($job), logger => $logger);
    my $before = jobDigest($checked);
    ok(!$checked->skip_on_check_failure(), 'Signed check can execute');
    is(jobDigest($checked), $before, 'Check execution does not mutate the signed plan');
    $authorized = $verify->();
    ok($authorized, 'Original plan restored');
    $processor->starting();
    foreach my $action (@{$job->{actions}}) {
        my ($name) = keys %$action;
        ok($processor->process($name, $action->{$name}, $authorized)->{status}, "Authorized $name succeeds");
    }
    $processor->done();
    ok(-f $destination && !-e $victim, 'Only explicitly signed copy/delete effects occur');

    my $legacy_target = File::Spec->catdir($directory, 'unsigned-mode');
    ok($processor->process('mkdir', { list => [$legacy_target] })->{status},
        'Unconfigured legacy mode remains available');
};

done_testing();
