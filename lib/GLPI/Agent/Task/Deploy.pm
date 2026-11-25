package GLPI::Agent::Task::Deploy;

# Full protocol documentation available here:
#  http://fusioninventory.org/documentation/dev/spec/protocol/deploy.html

use strict;
use warnings;
use parent 'GLPI::Agent::Task';

use UNIVERSAL::require;
use File::Spec;

use GLPI::Agent::HTTP::Client::Fusion;
use GLPI::Agent::Storage;
use GLPI::Agent::Task::Deploy::ActionProcessor;
use GLPI::Agent::Task::Deploy::Datastore;
use GLPI::Agent::Task::Deploy::File;
use GLPI::Agent::Task::Deploy::Job;
use GLPI::Agent::Task::Deploy::Signature qw(jobDigest actionDigest payloadFiles validFilename);
use GLPI::Agent::Event;
use GLPI::Agent::Tools;
use Digest::SHA;

use GLPI::Agent::Task::Deploy::Version;

our $VERSION = GLPI::Agent::Task::Deploy::Version::VERSION;

sub isEnabled {
    my ($self) = @_;

    unless ($self->{target}->isType('server')) {
        $self->{logger}->debug("Deploy task only compatible with server target");
        return;
    }

    return 1;
}

sub _validateAnswer {
    my ($msgRef, $answer) = @_;

    $$msgRef = "";

    if (!defined($answer)) {
        $$msgRef = "No answer from server.";
        return;
    }

    if (ref($answer) ne 'HASH') {
        $$msgRef = "Bad answer from server. Not a hash reference.";
        return;
    }

    if (!defined($answer->{associatedFiles})) {
        $$msgRef = "missing associatedFiles key";
        return;
    }

    if (ref($answer->{associatedFiles}) ne 'HASH') {
        $$msgRef = "associatedFiles should be an hash";
        return;
    }
    foreach my $k (keys %{$answer->{associatedFiles}}) {
        unless (ref($answer->{associatedFiles}->{$k}) eq 'HASH') {
            $$msgRef = "File description must be a hash";
            return;
        }
        foreach (qw/mirrors multiparts name p2p-retention-duration p2p uncompress/) {
            if (!defined($answer->{associatedFiles}->{$k}->{$_})) {
                $$msgRef = "Missing key \`$_' in associatedFiles";
                return;
            }
        }
        unless ($k =~ /\A[a-f0-9]{128}\z/ &&
                ref($answer->{associatedFiles}->{$k}->{multiparts}) eq 'ARRAY' &&
                !grep { !defined($_) || ref($_) || !/\A[a-f0-9]{128}\z/ } @{$answer->{associatedFiles}->{$k}->{multiparts}}) {
            $$msgRef = "Invalid file or multipart SHA-512";
            return;
        }
        # Check name is a simple filename and doesn't include a path
        my @path = File::Spec->splitpath($answer->{associatedFiles}->{$k}->{name});
        unless ($path[2] && $path[2] eq $answer->{associatedFiles}->{$k}->{name} && validFilename($path[2])) {
            $$msgRef = "Invalid file name in associatedFiles";
            return;
        }
    }
    unless (ref($answer->{jobs}) eq 'ARRAY') {
        $$msgRef = "jobs must be an array";
        return;
    }
    foreach my $job (@{$answer->{jobs}}) {
        unless (ref($job) eq 'HASH') {
            $$msgRef = "job must be a hash";
            return;
        }
        foreach (qw/uuid associatedFiles actions checks/) {
            if (!defined($job->{$_})) {
                $$msgRef = "Missing key \`$_' in jobs";
                return;
            }
        }

        if (ref($job->{actions}) ne 'ARRAY') {
            $$msgRef = "jobs/actions must be an array";
            return;
        }
        unless (ref($job->{associatedFiles}) eq 'ARRAY') {
            $$msgRef = "jobs/associatedFiles must be an array";
            return;
        }

        # Validate uuid format as it could be used in workdir path
        unless (!ref($job->{uuid}) && $job->{uuid} =~ /\A[0-9a-f-]+\z/i) {
            $$msgRef = "job/uuid wrong format";
            return;
        }
    }

    return 1;
}

sub processRemote {
    my ($self, $remoteUrl) = @_;

    my $logger = $self->{logger};
    unless ($remoteUrl) {
        $logger->debug("No remote URL provided for processing");
        return 0;
    }

    my $publicKey = $self->{config}->{'deploy-public-key'};
    my $signaturesEnabled = !empty($publicKey);
    my $verify;
    if ($signaturesEnabled) {
        $verify = $self->_signatureVerifier($publicKey) or return 0;
    }

    my $folder = $self->{target}->getStorage()->getDirectory();
    my $datastore = GLPI::Agent::Task::Deploy::Datastore->new(
        config => $self->{config},
        path   => $folder,
        logger => $logger
    );
    $datastore->cleanUp();

    my $jobList = [];
    my $files;

    my $answer = $self->{client}->send(
        url  => $remoteUrl,
        args => {
            action    => "getJobs",
            machineid => $self->{deviceid},
            version   => $VERSION
        }
    );

    if (ref($answer) eq 'HASH' && !keys %$answer) {
        $logger->debug("Nothing to do");
        return 0;
    }

    my $msg;
    if (!_validateAnswer(\$msg, $answer)) {
        $logger->debug("bad JSON: ".$msg);
        return 0;
    }

    foreach my $sha512 ( keys %{ $answer->{associatedFiles} } ) {
        $files->{$sha512} = GLPI::Agent::Task::Deploy::File->new(
            client    => $self->{client},
            sha512    => $sha512,
            data      => $answer->{associatedFiles}{$sha512},
            datastore => $datastore,
            prolog    => $self->{target}->getMaxDelay(),
            logger    => $logger
        );
    }

    foreach my $job ( @{ $answer->{jobs} } ) {
        my $associatedFiles = [];
        if ( $job->{associatedFiles} ) {
            foreach my $uuid ( @{ $job->{associatedFiles} } ) {
                if ( !$files->{$uuid} ) {
                    $logger->error("unknown file: '$uuid'. Not found in JSON answer!");
                    next;
                }
                push @$associatedFiles, $files->{$uuid};
            }
            if (@$associatedFiles != @{$job->{associatedFiles}}) {
                $logger->error("Bad job definition in JSON answer!");
                next;
            }
        }

        push @$jobList, GLPI::Agent::Task::Deploy::Job->new(
            remoteUrl       => $remoteUrl,
            client          => $self->{client},
            machineid       => $self->{deviceid},
            data            => $job,
            associatedFiles => $associatedFiles,
            logger          => $logger
        );

        $logger->debug2("Deploy job $job->{uuid} in the list");
    }

  JOB: foreach my $job (@$jobList) {

        $logger->debug2("Processing job $job->{uuid} from the list");

        # RECEIVED
        $job->currentStep('checking');
        $job->setStatus(
            msg => 'starting'
        );

        $logger->debug2("Checking job $job->{uuid}...");

        # CHECKING
        if (!$signaturesEnabled) {
            next if $job->skip_on_check_failure();
            $job->setStatus(status => 'ok', msg => 'all checks are ok');
            next if $job->next_on_usercheck(type => 'before');
        }

        $logger->debug2("Downloading for job $job->{uuid}...");

        # DOWNLOADING

        $job->currentStep('downloading');
        $job->setStatus(
            msg => 'downloading files'
        );

        my $retry = 5;
        my $workdir = $datastore->createWorkDir( $job->{uuid} );
        FETCHFILE: foreach my $file ( @{ $job->{associatedFiles} } ) {

            # File exists, no need to download
            if ( $file->filePartsExists() ) {
                $job->setStatus(
                    file   => $file,
                    status => 'ok',
                    msg    => $file->{name}.' already downloaded'
                );

                # Reset retention time for all still downloaded parts
                $file->resetPartFilePaths();

                $workdir->addFile($file);
                next;
            }

            # File doesn't exist, lets try or retry a download
            $job->setStatus(
                file => $file,
                msg  => 'fetching '.$file->{name}
            );

            $file->download();

            # Reset retention time for all downloaded parts
            $file->resetPartFilePaths();

            # Are all the fileparts here?
            my $downloadIsOK = $file->filePartsExists();

            if ( $downloadIsOK ) {

                $job->setStatus(
                    file   => $file,
                    status => 'ok',
                    msg    => $file->{name}.' downloaded'
                );

                $workdir->addFile($file);
                next;
            }

            # Retry the download 5 times in a row and then give up
            if ( !$downloadIsOK ) {

                if ($retry--) { # Retry
# OK, retry!
                    $job->setStatus(
                        file => $file,
                        msg  => 'retrying '.$file->{name}
                    );

                    redo FETCHFILE;
                } else { # Give up...

                    # USER INTERACTION after download failure
                    $job->next_on_usercheck(type => 'after_download_failure') unless $signaturesEnabled;

                    $job->setStatus(
                        file   => $file,
                        status => 'ko',
                        msg    => $file->{name}.' download failed'
                    );

                    next JOB;
                }
            }

        }

        $job->setStatus(
            status => 'ok',
            msg    => 'success'
        );

        # USER INTERACTION after download
        next if !$signaturesEnabled && $job->next_on_usercheck(type => 'after_download');

        $logger->debug2("Preparation for job $job->{uuid}...");

        $job->currentStep('prepare');

        my $authorizedActions;
        if (!$workdir->prepare(signed => $signaturesEnabled)) {
            # USER INTERACTION on preparation failure
            $job->next_on_usercheck(type => 'after_failure') unless $signaturesEnabled;

            $job->setStatus(
                status => 'ko',
                msg    => 'failed to prepare work dir'
            );
            next JOB;
        } else {
            # Verify signature if a public key is defined in configuration
            if ($signaturesEnabled && !($authorizedActions = $self->_verifySignature(
                    workdir => $workdir, verify => $verify, job => $job))) {
                $job->setStatus(
                    status => 'ko',
                    msg    => 'Security error: invalid signature'
                );
                next JOB;
            }

            $job->setStatus(
                status => 'ok',
                msg    => 'success'
            );
        }

        if ($signaturesEnabled) {
            $job->currentStep('checking');
            next if $job->skip_on_check_failure();
            $job->setStatus(status => 'ok', msg => 'all checks are ok');
            next if $job->next_on_usercheck(type => 'before');
            next if $job->next_on_usercheck(type => 'after_download');
        }

        $logger->debug2("Processing for job $job->{uuid}...");

        # Run partial software inventory if required and job processing has started
        $self->{_software_inventory_required} = 1
            if $job->requiresSoftwaresInventory();

        # PROCESSING
        my $actionProcessor = GLPI::Agent::Task::Deploy::ActionProcessor->new(
            logger  => $logger,
            workdir => $workdir->path()
        );
        my $actionnum = 0;

        # Essentially to change dir to workdir
        $actionProcessor->starting();

        while ( my $action = $job->getNextToProcess() ) {
            my ($actionName, $params) = %$action;
            if ( $params && (ref( $params->{checks} ) eq 'ARRAY') ) {

                $logger->debug2("Processing action check for job $job->{uuid}...");
                $job->currentStep('checking');

                # CHECKING
                next if $job->skip_on_check_failure(
                    checks => $params->{checks},
                    level  => 'action'
                );
            }

            $job->currentStep('processing');

            my $ret;
            eval {
                $ret = $actionProcessor->process($actionName, $params, $authorizedActions);
            };
            $ret->{msg} = [] unless $ret && $ret->{msg};
            push @{$ret->{msg}}, $@ if $@;

            my $name = $params->{name} || "action #".($actionnum+1);

            # Log msg lines: can be heavy while running a command with high logLineLimit parameter
            my $logLineLimit = defined($params->{logLineLimit}) ?
                $params->{logLineLimit} : 10 ;

            # Really report nothing to server if logLineLimit=0 & status is ok
            $ret->{msg} = [] if (!$logLineLimit && $ret->{status});

            # Add 7 to always output header & retCode analysis lines for cmd command, unless in nolimit (-1)
            $logLineLimit += 7 unless ($logLineLimit < 0);

            foreach my $line (@{$ret->{msg}}) {
                next unless ($line);
                $job->setStatus(
                    msg       => "$name: $line",
                    actionnum => $actionnum,
                );
                last unless --$logLineLimit;
            }

            if ( !$ret->{status} ) {

                # USER INTERACTION after action failure
                $job->next_on_usercheck(type => 'after_failure');

                $job->setStatus(
                    status    => 'ko',
                    actionnum => $actionnum,
                    msg       => "$name, processing failure"
                );

                # Mark processing as failed and leave loop
                $actionProcessor->failure();
                last;
            }
            $job->setStatus(
                status    => 'ok',
                actionnum => $actionnum,
                msg       => "$name, processing success"
            );

            $actionnum++;
        }

        # Essentially to change dir back from workdir
        $actionProcessor->done();

        # Handle next job if action processor failed
        next if $actionProcessor->failed();

        # USER INTERACTION
        $job->next_on_usercheck(type => 'after');

        $logger->debug2("Finished job $job->{uuid}...");

        # When success and finished, we can still cleanup file in private
        # cache when retention duration is not set
        foreach my $file ( @{ $job->{associatedFiles} } ) {
            $file->cleanup_private();
        }

        $job->currentStep('end');
        $job->setStatus(
            status => 'ok',
            msg    => "job successfully completed"
        );
    }

    $logger->debug2("All deploy jobs processed");

    $datastore->cleanUp();

    return @$jobList ? 1 : 0 ;
}

sub _signatureVerifier {
    my ($self, $publicKey) = @_;
    my $logger = $self->{logger};

    # Interpret an exact hex key as a key, never as a path.
    if ($publicKey !~ /\A[0-9a-fA-F]{64}\z/ && -f $publicKey) {
        my @stat = stat($publicKey);
        if ($^O ne 'MSWin32' && (!@stat || ($stat[2] & 022))) {
            $logger->error("Security error: public key file $publicKey is group/world-writable or inaccessible");
            return;
        }
        $publicKey = getAllLines(file => $publicKey, local => 1, logger => $logger);
        $publicKey =~ s/\s+//g if defined($publicKey);
    }
    unless (defined($publicKey) && $publicKey =~ /\A[0-9a-fA-F]{64}\z/) {
        $logger->error('Security error: invalid public key (expected 32 bytes hex-encoded)');
        return;
    }
    my $pubKeyBin = pack('H*', $publicKey);
    if (Crypt::Ed25519->require()) {
        return sub { Crypt::Ed25519::verify($_[0], $pubKeyBin, $_[1]) };
    }
    if (Crypt::PK::Ed25519->require()) {
        my $key = eval {
            my $public_key = Crypt::PK::Ed25519->new();
            $public_key->import_key_raw($pubKeyBin, 'public');
            $public_key;
        };
        return sub { $key->verify_message($_[1], $_[0]) } if $key;
        $logger->error('Security error: could not import Ed25519 public key');
        return;
    }
    $logger->error('Security error: Crypt::Ed25519 or Crypt::PK::Ed25519 is required');
    return;
}

sub _verifySignature {
    my ($self, %params) = @_;
    my $workdirPath = $params{workdir}->path();
    my $logger = $self->{logger};

    my @files = eval { payloadFiles($workdirPath) };
    if ($@) {
        $logger->error('Security error: unsafe payload entry');
        return 0;
    }
    my @signatures = grep { $_ eq 'signature.sig' || $_ eq 'manifest.sig' } @files;
    my $sigFile = @signatures == 1 ? File::Spec->catfile($workdirPath, $signatures[0]) : undef;

    if (!$sigFile) {
        $logger->error("Security error: signature file missing in $workdirPath");
        return 0;
    }

    my $handle = getFileHandle(file => $sigFile, local => 1, logger => $logger);
    return 0 unless $handle;
    binmode $handle;
    my $content = do { local $/; <$handle> };
    close $handle;
    return 0 unless defined($content);
    # Support format: <signature_hex>\n<manifest_content>
    # or manifest with signature at the end: <manifest_content>\n# Signature: <signature_hex>
    my ($sigHex, $manifestContent);
    if ($content =~ /^([a-f0-9]{128})\r?\n(.*)/s) {
        $sigHex = $1;
        $manifestContent = $2;
    } elsif ($content =~ /^(.*)\r?\n# Signature: ([a-f0-9]{128})\s*$/s) {
        $manifestContent = $1;
        $sigHex = $2;
    } else {
        $logger->error("Security error: unknown signature file format in $sigFile");
        return 0;
    }

    my $signature = pack("H*", $sigHex);
    my $verified = eval { $params{verify}->($manifestContent, $signature) };
    if (!$verified) {
        $logger->error("Security error: invalid signature for $sigFile");
        return 0;
    }

    my @lines = split /\r?\n/, $manifestContent;
    my $version = shift @lines;
    my $job_line = shift @lines;
    my ($expected_job) = defined($job_line) ? $job_line =~ /\AJOB ([a-f0-9]{128})\z/ : ();
    my $actual_job = eval { jobDigest($params{job}) };
    unless (defined($version) && $version eq 'GLPI-DEPLOY-SIGNATURE 2' &&
            $expected_job && $actual_job && $actual_job eq $expected_job) {
        $logger->error('Security error: missing or mismatched signed deployment plan (version 2 required)');
        return 0;
    }

    my %expected_files;
    foreach my $line (@lines) {
        my ($expectedHash, $fileName) = $line =~ /\A([a-f0-9]{128}) (.+)\z/;
        if (!$expectedHash || !validFilename($fileName) ||
                $fileName eq 'signature.sig' || $fileName eq 'manifest.sig' || exists($expected_files{$fileName})) {
            $logger->error('Security error: invalid or duplicate manifest entry');
            return 0;
        }
        $expected_files{$fileName} = $expectedHash;
        my $filePath = File::Spec->catfile($workdirPath, $fileName);
        if (!-f $filePath) {
            $logger->error("Security error: file '$fileName' missing from workdir");
            return 0;
        }

        my $actualHash = $self->_getSha512ByFile($filePath) // '';
        if ($actualHash ne $expectedHash) {
            $logger->error("Security error: hash mismatch for $fileName");
            return 0;
        }
        $logger->debug("Integrity OK for $fileName");
    }

    foreach my $file (@files) {
        next if $file eq $signatures[0];
        unless (exists($expected_files{$file})) {
            $logger->error('Security error: unsigned payload file');
            return 0;
        }
    }

    my %authorized;
    foreach my $action (@{$params{job}->{actions}}) {
        my ($name) = keys %$action;
        $authorized{actionDigest($name, $action->{$name})} = 1;
    }
    $logger->info("Signature verified for deployment package and plan in $workdirPath");

    return \%authorized;
}

sub _getSha512ByFile {
    my ($self, $filePath) = @_;

    my $sha = Digest::SHA->new('512');
    my $sha512;
    eval {
        $sha->addfile($filePath, 'b');
        $sha512 = $sha->hexdigest;
    };
    if ($@) {
        $self->{logger}->debug("SHA512 failure for $filePath: $@");
    }
    return $sha512;
}

sub run {
    my ($self) = @_;

    # Turn off localised output for commands
    $ENV{LC_ALL} = 'C';
    $ENV{LANG} = 'C';

    my $logger = $self->{logger};

    my $event = $self->resetEvent();
    if ($event) {
        my $name = $event->name;
        if ($name && $event->maintenance && GLPI::Agent::Task::Deploy::Maintenance->require()) {
            my $nextEvent;
            my $targetid = $self->{target}->id;
            $logger->debug("Deploy task $name event for $targetid target");
            my $maintenance = GLPI::Agent::Task::Deploy::Maintenance->new(
                target  => $self->{target},
                config  => $self->{config},
                logger  => $self->{logger},
            );
            if ($maintenance->doMaintenance()) {
                $nextEvent = $self->newEvent();
                $logger->debug("Planning another $name event for $targetid target in ".$event->delay()."s");
            } else {
                # Don't restart event if datastore has been fully cleaned up
                $logger->debug("No need to plan another $name event for $targetid target");
            }
            $self->resetEvent($nextEvent);
            return;
        }
    }

    $self->{client} = GLPI::Agent::HTTP::Client::Fusion->new(
        logger  => $logger,
        config  => $self->{config},
        oauth   => $self->{target}->getOAuthCredentials(),
    );

    my $globalRemoteConfig = $self->{client}->send(
        url  => $self->{target}->getUrl(),
        args => {
            action    => "getConfig",
            machineid => $self->{deviceid},
            task      => { Deploy => $VERSION },
        }
    );

    my $id = $self->{target}->id();
    if (!$globalRemoteConfig) {
        $self->{logger}->info("Deploy task not supported by $id");
        return;
    }
    if (!$globalRemoteConfig->{schedule}) {
        $logger->info("No job schedule returned by $id");
        return;
    }
    if (ref( $globalRemoteConfig->{schedule} ) ne 'ARRAY') {
        $logger->info("Malformed schedule returned by $id");
        return;
    }
    if ( !@{$globalRemoteConfig->{schedule}} ) {
        $logger->info("No Deploy job enabled or Deploy support disabled server side.");
        return;
    }

    my $run_jobs = 0;
    foreach my $job ( @{ $globalRemoteConfig->{schedule} } ) {
        next unless $job->{task} eq "Deploy";
        $run_jobs += $self->processRemote($job->{remote});
    }

    if ( !$run_jobs ) {
        $logger->info("No Deploy job found in server jobs list.");
        return;
    }

    # Always plan a maintenance event when a job has been run
    $self->resetEvent($self->newEvent());

    # Also plan a partial software inventory if this has been required in a job
    if ($self->{_software_inventory_required}) {
        $self->addEvent(GLPI::Agent::Event->new(
            name        => "software inventory",
            task        => "inventory",
            partial     => "software",
            target      => $self->{target}->id(),
            delay       => 0,
        ));
    }

    return 1;
}

sub newEvent {
    my ($self) = @_;

    return GLPI::Agent::Event->new(
        name        => "storage maintenance",
        task        => "deploy",
        maintenance => "yes",
        target      => $self->{target}->id(),
        delay       => 120,
    );
}

1;

__END__

=head1 NAME

GLPI::Agent::Task::Deploy - Software deployment support for GLPI Agent

=head1 DESCRIPTION

With this module, the agent can accept software deployment
request from an GLPI server with a FusionInventory compatible plugin.

This module uses SSL certificat to authentificat the server. You may have
to point F<--ca-cert-file> or F<--ca-cert-dir> to your public certificat.

If the P2P option is turned on, the agent will looks for peer in its network. The network size will be limited at 255 machines.

=head2 Signed packages support

The agent can verify the authenticity and integrity of deployment packages if a
public key is configured via the C<deploy-public-key> option.

When this option is set, the agent expects a C<signature.sig> or C<manifest.sig>
file at the root of the deployment package. This file must contain an Ed25519
signature followed by a manifest listing all files in the package and their
SHA-512 hashes, and a digest of the complete deployment plan. The version 2
format is required; legacy file-only or COMMAND manifests are rejected.

The B<glpi-sign-package.pl> tool, located in the C<tools/> directory of the
agent repository, can be used to generate these signatures.

B<Compressed archives:> Automatic C<uncompress> is forbidden when a public key
is configured. Sign the archive itself, deliver it alongside C<signature.sig>
with C<uncompress> disabled, and authorize an explicit extraction command in
the signed plan. This prevents unauthenticated extraction, including via 7z.

Format of the signature file:
  <64-bytes-hex-signature>
  GLPI-DEPLOY-SIGNATURE 2
  JOB <sha512-of-canonical-plan>
  <sha512> <filename1>
  <sha512> <filename2>

The verification process:
1. Lazily loads C<Crypt::Ed25519> or C<Crypt::PK::Ed25519>.
2. Verifies the Ed25519 signature of the manifest using the configured public key.
3. Matches the ordered actions, all action parameters (including paths,
environment, checks and return handling), job checks, userinteractions and
requires against the signed plan before running checks or actions.
4. Checks every payload hash and rejects extra files, duplicate or malformed
entries, directories, symlinks, hard links and ambiguous or nonportable names.
5. Authorizes every action centrally, including copy, move, delete and mkdir.

If the verification fails at any step, the deployment task is aborted with a
security error.

The payload is reconstructed in a fresh private staging directory. Deliver only
regular files at its root; put directory trees inside a signed archive. Keep
the signing key separate from the GLPI server. A signature authorizes the exact
plan but is not a sandbox: signed commands can intentionally fetch mutable
content or operate on existing host files. Replaying an unchanged signed plan
is allowed; this format does not provide expiry or anti-rollback guarantees.
The agent's storage and configuration must be protected against unprivileged
local writes using filesystem permissions (and Windows ACLs).
Without C<deploy-public-key>, unsigned deployments are still supported.

=head1 FUNCTIONS

=head2 isEnabled ( $self )

Returns true if the task is enabled.

=head2 processRemote ( $self, $remoteUrl )

Process orders from a remote server.

=head2 run ( $self )

Run the task.
