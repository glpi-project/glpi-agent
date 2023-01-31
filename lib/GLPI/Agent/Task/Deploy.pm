package GLPI::Agent::Task::Deploy;

# Full protocol documentation available here:
#  http://fusioninventory.org/documentation/dev/spec/protocol/deploy.html

use strict;
use warnings;
use parent 'GLPI::Agent::Task';

use UNIVERSAL::require;

use GLPI::Agent::HTTP::Client::Fusion;
use GLPI::Agent::Storage;
use GLPI::Agent::Task::Deploy::ActionProcessor;
use GLPI::Agent::Task::Deploy::Datastore;
use GLPI::Agent::Task::Deploy::File;
use GLPI::Agent::Task::Deploy::Job;

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
        foreach (qw/mirrors multiparts name p2p-retention-duration p2p uncompress/) {
            if (!defined($answer->{associatedFiles}->{$k}->{$_})) {
                $$msgRef = "Missing key `$_' in associatedFiles";
                return;
            }
        }
    }
    foreach my $job (@{$answer->{jobs}}) {
        foreach (qw/uuid associatedFiles actions checks/) {
            if (!defined($job->{$_})) {
                $$msgRef = "Missing key `$_' in jobs";
                return;
            }

            if (ref($job->{actions}) ne 'ARRAY') {
                $$msgRef = "jobs/actions must be an array";
                return;
            }
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
        next if $job->skip_on_check_failure();

        $job->setStatus(
            status => 'ok',
            msg    => 'all checks are ok'
        );

        # USER INTERACTION
        next if $job->next_on_usercheck(type => 'before');

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
                    $job->next_on_usercheck(type => 'after_download_failure');

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
        next if $job->next_on_usercheck(type => 'after_download');

        $logger->debug2("Preparation for job $job->{uuid}...");

        $job->currentStep('prepare');
        if (!$workdir->prepare()) {
            # USER INTERACTION on preparation failure
            $job->next_on_usercheck(type => 'after_failure');

            $job->setStatus(
                status => 'ko',
                msg    => 'failed to prepare work dir'
            );
            next JOB;
        } else {
            $job->setStatus(
                status => 'ok',
                msg    => 'success'
            );
        }

        $logger->debug2("Processing for job $job->{uuid}...");

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
                $ret = $actionProcessor->process($actionName, $params);
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

sub run {
    my ($self) = @_;

    # Turn off localised output for commands
    $ENV{LC_ALL} = 'C'; # Turn off localised output for commands
    $ENV{LANG} = 'C'; # Turn off localised output for commands

    my $logger = $self->{logger};

    my $event = $self->event;
    if ($event) {
        if ($event->{maintenance} && GLPI::Agent::Task::Deploy::Maintenance->require()) {
            $logger->debug("Deploy task $event->{name} event for ".$self->{target}->id(). " target");
            my $maintenance = GLPI::Agent::Task::Deploy::Maintenance->new(
                target  => $self->{target},
                config  => $self->{config},
                logger  => $self->{logger},
            );
            if ($maintenance->doMaintenance()) {
                $event = $self->newEvent();
                $logger->debug("Planning another $event->{name} event for ".$self->{target}->id(). " target in $event->{delay}s");
            } else {
                # Don't restart event if datastore has been fully cleaned up
                $logger->debug("No need to plan another $event->{name} event for ".$self->{target}->id(). " target");
                undef $event;
            }
            $self->resetEvent($event);
        }
        return;
    }

    $self->{client} = GLPI::Agent::HTTP::Client::Fusion->new(
        logger  => $logger,
        config  => $self->{config},
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

    return 1;
}

sub newEvent {
    my ($self) = @_;

    return {
        name        => "storage maintenance",
        task        => "deploy",
        maintenance => "yes",
        target      => $self->{target}->id(),
        delay       => 120,
    };
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

=head1 FUNCTIONS

=head2 isEnabled ( $self )

Returns true if the task is enabled.

=head2 processRemote ( $self, $remoteUrl )

Process orders from a remote server.

=head2 run ( $self )

Run the task.
