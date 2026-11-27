#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Compress::Zlib;
use Digest::SHA qw(sha512_hex);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Storable qw(dclone);
use Test::More;
use Test::MockObject;
use Test::MockModule;

use GLPI::Agent::Logger;
use GLPI::Agent::Task::Deploy;
use GLPI::Agent::Task::Deploy::Datastore;
use GLPI::Agent::Task::Deploy::File;
use GLPI::Agent::Task::Deploy::Signature;

my $signing = GLPI::Agent::Task::Deploy::Signature->new();

plan skip_all => 'Crypt::Ed25519 needed for real deployment verification'
    unless eval { require Crypt::Ed25519; 1 };

sub write_file {
    my ($path, $content) = @_;
    open my $handle, '>', $path or die $!;
    print {$handle} $content;
    close $handle or die $!;
}

foreach my $case ('valid', 'changed destination', 'unsigned file', 'auto extraction',
        'invalid signature', 'wrong public key', 'legacy manifest') {
    subtest $case => sub {
        my $directory = tempdir(CLEANUP => 1);
        my $destination = File::Spec->catfile($directory, 'host.cfg');
        my $other = File::Spec->catfile($directory, 'unauthorized.cfg');
        write_file($destination, 'original configuration');
        my $logger = GLPI::Agent::Logger->new(logger => ['Stderr']);
        my ($public, $private) = Crypt::Ed25519::generate_keypair(chr(5) x 32);
        my $job = {
            uuid => 'abc-123', associatedFiles => [], checks => [],
            actions => [{ copy => {
                from => 'agent.cfg', to => $destination,
                checks => [{ type => 'fileExists', path => 'agent.cfg' }],
            } }],
        };
        my $content = 'approved configuration';
        my $manifest = "GLPI-DEPLOY-SIGNATURE 2\nJOB " . $signing->jobDigest($job) . "\n";
        $manifest = '' if $case eq 'legacy manifest';
        $manifest .= sha512_hex($content) . " agent.cfg\n";
        my $signature = unpack('H*', Crypt::Ed25519::sign($manifest, $public, $private));
        $signature = '0' x 128 if $case eq 'invalid signature';
        my %payload = ( 'agent.cfg' => $content, 'signature.sig' => "$signature\n$manifest" );
        $payload{'unsigned.cfg'} = 'injected' if $case eq 'unsigned file';
        $job->{actions}->[0]->{copy}->{to} = $other if $case eq 'changed destination';
        ($public) = Crypt::Ed25519::generate_keypair(chr(6) x 32) if $case eq 'wrong public key';
        my $config = { 'deploy-public-key' => unpack('H*', $public) };
        my $datastore = GLPI::Agent::Task::Deploy::Datastore->new(
            path => $directory, config => $config, logger => $logger);
        my %associated;
        foreach my $name (sort keys %payload) {
            my $sha = sha512_hex($payload{$name});
            my $data = {
                name => $name, multiparts => [$sha], mirrors => [], p2p => 0,
                'p2p-retention-duration' => 60,
                uncompress => ($case eq 'auto extraction' && $name eq 'agent.cfg') ? 1 : 0,
            };
            $associated{$sha} = $data;
            push @{$job->{associatedFiles}}, $sha;
            my $file = GLPI::Agent::Task::Deploy::File->new(
                datastore => $datastore, data => $data, sha512 => $sha, logger => $logger);
            my $part = $file->normalizedPartFilePath($sha);
            make_path(dirname($part));
            my $gzip = gzopen($part, 'wb') or die $!;
            $gzip->gzwrite($payload{$name});
            $gzip->gzclose();
        }
        my @statuses;
        my $client = Test::MockObject->new();
        $client->mock(send => sub {
            my ($self, %params) = @_;
            return { associatedFiles => \%associated, jobs => [dclone($job)] }
                if $params{args}->{action} eq 'getJobs';
            push @statuses, $params{args} if $params{args}->{action} eq 'setStatus';
            return {};
        });
        my $storage = Test::MockObject->new();
        $storage->set_always('getDirectory', $directory);
        my $target = Test::MockObject->new();
        $target->set_always('getStorage', $storage);
        $target->set_always('getMaxDelay', 3600);
        my $task = bless {
            target => $target, config => $config, client => $client, logger => $logger,
            deviceid => 'test-agent',
        }, 'GLPI::Agent::Task::Deploy';
        my ($checked, $interacted) = (0, 0);
        my $check = GLPI::Agent::Task::Deploy::Job->can('skip_on_check_failure');
        my $interact = GLPI::Agent::Task::Deploy::Job->can('next_on_usercheck');
        my $job_mock = Test::MockModule->new('GLPI::Agent::Task::Deploy::Job');
        $job_mock->redefine(skip_on_check_failure => sub { $checked++; return $check->(@_); });
        $job_mock->redefine(next_on_usercheck => sub { $interacted++; return $interact->(@_); });
        ok($task->processRemote('http://localhost/deploy'), 'Job received and processed');
        open my $handle, '<', $destination or die $!;
        my $actual = do { local $/; <$handle> };
        close $handle;
        if ($case eq 'valid') {
            is($actual, $content, 'Signed copy installs the approved configuration');
            is($statuses[-1]->{msg}, 'job successfully completed', 'Job completes successfully');
            is($checked, 2, 'Job and action checks execute after successful authentication');
        } else {
            is($actual, 'original configuration', 'Rejected job leaves host configuration untouched');
            ok(!-e $other, 'No unsigned destination is created');
            is($statuses[-1]->{status}, 'ko', 'Rejection is reported to the server');
            is($checked, 0, 'Unauthenticated job checks are not executed');
            is($interacted, 0, 'Unauthenticated interactions are not executed');
        }
    };
}

done_testing();
