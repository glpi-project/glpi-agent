#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use Test::MockObject;

use GLPI::Agent::Task::Deploy;
use GLPI::Agent::Logger;
use GLPI::Agent::Task::Deploy::Signature qw(actionDigest);

sub write_file {
    my ($path, $content) = @_;
    open my $handle, '>', $path or die "Can't write $path: $ERRNO";
    binmode $handle;
    print {$handle} $content;
    close $handle or die "Can't close $path: $ERRNO";
}

my $logger = GLPI::Agent::Logger->new(logger => ['Stderr']);

subtest 'Invalid configured keys fail before requesting jobs' => sub {
    my $directory = tempdir(CLEANUP => 1);
    my $empty_key = File::Spec->catfile($directory, 'empty.key');
    my $blank_key = File::Spec->catfile($directory, 'blank.key');
    write_file($empty_key, '');
    write_file($blank_key, " \n\t\n");

    foreach my $key ($empty_key, $blank_key, '0', 'g' x 64) {
        my $client = Test::MockObject->new();
        $client->mock('send', sub { die 'Invalid key must not request jobs'; });
        my $task = bless {
            config => { 'deploy-public-key' => $key },
            client => $client, logger => $logger,
        }, 'GLPI::Agent::Task::Deploy';

        is($task->processRemote('http://localhost/test'), 0, 'Invalid key stops Deploy before fetching jobs');
    }
};

subtest 'Signing tool and real crypto backends interoperate' => sub {
    plan skip_all => 'Crypt::Ed25519 required for the signing tool'
        unless eval { require Crypt::Ed25519; 1 };
    my $has_cryptx = eval { require Crypt::PK::Ed25519; 1 };
    my $directory = tempdir(CLEANUP => 1);
    my $payload = File::Spec->catdir($directory, 'payload');
    mkdir $payload or die "Can't create $payload: $ERRNO";
    my $file = File::Spec->catfile($payload, 'file.txt');
    write_file($file, 'original content');
    my $seed = chr(1) x 32;
    my ($public_key) = Crypt::Ed25519::generate_keypair($seed);
    my $key = File::Spec->catfile($directory, 'private.key');
    write_file($key, unpack('H*', $seed));
    my $command = 'echo signed-command';
    my $sign_directory = $payload;
    my $alias = File::Spec->catdir($directory, 'payload-alias');
    $sign_directory = $alias if $OSNAME ne 'MSWin32' && symlink($payload, $alias);
    system($EXECUTABLE_NAME, 'tools/glpi-sign-package.pl', '--dir', $sign_directory,
        '--key', $key, '--command', $command);
    is($CHILD_ERROR, 0, 'Signing tool succeeds through a directory alias');
    my $job = { actions => [{ cmd => { exec => $command } }] };

    foreach my $backend ('Crypt::Ed25519', 'CryptX') {
        subtest $backend => sub {
            plan skip_all => 'CryptX not installed' if $backend eq 'CryptX' && !$has_cryptx;
            no warnings 'redefine';
            no warnings 'once';
            local *Crypt::Ed25519::require = sub { return $backend eq 'Crypt::Ed25519'; };
            my $workdir = Test::MockObject->new();
            $workdir->set_always('path', $payload);
            my $task = bless {
                config => { 'deploy-public-key' => unpack('H*', $public_key) },
                logger => $logger,
            }, 'GLPI::Agent::Task::Deploy';
            my $verify = $task->_signatureVerifier(unpack('H*', $public_key));
            ok($verify, 'Loaded public key and verifier');
            my $authorized = $task->_verifySignature(workdir => $workdir, verify => $verify, job => $job);
            ok($authorized, 'Real signature verifies');
            ok($authorized->{actionDigest('cmd', { exec => $command })}, 'Complete signed action is authorized');
            {
                local *GLPI::Agent::Task::Deploy::_getSha512ByFile = sub { return; };
                ok(!$task->_verifySignature(workdir => $workdir, verify => $verify, job => $job),
                    'An unreadable payload digest rejects the job');
            }
            write_file($file, 'modified content');
            ok(!$task->_verifySignature(workdir => $workdir, verify => $verify, job => $job), 'Tampered payload is rejected');
            write_file($file, 'original content');
        };
    }
};

done_testing();
