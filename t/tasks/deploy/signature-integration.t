#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Digest::SHA qw(sha512_hex);
use English qw(-no_match_vars);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use Test::MockModule;
use Test::MockObject;

use GLPI::Agent::Task::Deploy;
use GLPI::Agent::Logger;

sub write_file {
    my ($path, $content) = @_;
    open my $handle, '>', $path or die "Can't write $path: $ERRNO";
    binmode $handle;
    print {$handle} $content;
    close $handle or die "Can't close $path: $ERRNO";
}

my $logger = GLPI::Agent::Logger->new(logger => ['Stderr']);

subtest 'Invalid configured keys fail before extraction' => sub {
    my $directory = tempdir(CLEANUP => 1);
    my $empty_key = File::Spec->catfile($directory, 'empty.key');
    my $blank_key = File::Spec->catfile($directory, 'blank.key');
    write_file($empty_key, '');
    write_file($blank_key, " \n\t\n");

    foreach my $key ($empty_key, $blank_key, '0', 'g' x 64) {
        my $prepared = 0;
        my @statuses;
        my $workdir = Test::MockObject->new();
        $workdir->mock('prepare', sub { $prepared++; return 0; });
        my $datastore = Test::MockObject->new();
        $datastore->set_true('cleanUp');
        $datastore->set_always('createWorkDir', $workdir);
        my $storage = Test::MockObject->new();
        $storage->set_always('getDirectory', $directory);
        my $target = Test::MockObject->new();
        $target->set_always('getStorage', $storage);
        my $job = Test::MockObject->new();
        $job->{uuid} = 'abc-123';
        $job->{associatedFiles} = [];
        $job->set_true('currentStep');
        $job->set_false('skip_on_check_failure', 'next_on_usercheck');
        $job->mock('setStatus', sub {
            my ($self, %params) = @_;
            push @statuses, \%params;
        });
        my $client = Test::MockObject->new();
        $client->set_always('send', {
            associatedFiles => {},
            jobs => [{ uuid => 'abc-123', associatedFiles => [], actions => [], checks => [] }],
        });
        my $datastore_mock = Test::MockModule->new('GLPI::Agent::Task::Deploy::Datastore');
        $datastore_mock->redefine(new => sub { return $datastore; });
        my $job_mock = Test::MockModule->new('GLPI::Agent::Task::Deploy::Job');
        $job_mock->redefine(new => sub { return $job; });
        my $task = bless {
            config => { 'deploy-public-key' => $key },
            target => $target, client => $client, logger => $logger,
        }, 'GLPI::Agent::Task::Deploy';

        $task->processRemote('http://localhost/test');
        is($prepared, 0, 'Invalid key prevents extraction');
        is($statuses[-1]->{status}, 'ko', 'Deployment is rejected');
        is($statuses[-1]->{msg}, 'Security error: invalid public key', 'Failure is explicit');
    }
};

subtest 'Signing tool and real crypto backends interoperate' => sub {
    plan skip_all => 'Crypt::Ed25519 required for the signing tool'
        unless eval { require Crypt::Ed25519; 1 };
    my $has_cryptx = eval { require Crypt::PK::Ed25519; 1 };
    my $directory = tempdir(CLEANUP => 1);
    my $payload = File::Spec->catdir($directory, 'payload');
    mkdir $payload or die "Can't create $payload: $ERRNO";
    my $nested = File::Spec->catdir($payload, 'nested');
    mkdir $nested or die "Can't create $nested: $ERRNO";
    my $file = File::Spec->catfile($nested, 'file.txt');
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
    is($CHILD_ERROR, 0, 'Signing tool succeeds with a nested payload');

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
            ok($task->_verifySignature(workdir => $workdir), 'Real signature verifies');
            is($task->{_authorized_commands}->{sha512_hex($command)}, $command, 'Signed command is authorized');
            write_file($file, 'modified content');
            ok(!$task->_verifySignature(workdir => $workdir), 'Tampered payload is rejected');
            write_file($file, 'original content');
        };
    }
};

done_testing();
