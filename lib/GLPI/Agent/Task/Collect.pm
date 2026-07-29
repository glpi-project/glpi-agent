package GLPI::Agent::Task::Collect;

use strict;
use warnings;
use parent 'GLPI::Agent::Task';

use English qw(-no_match_vars);
use File::Glob;
use UNIVERSAL::require;

use GLPI::Agent;
use GLPI::Agent::Logger;
use GLPI::Agent::Tools;
use GLPI::Agent::HTTP::Client::Fusion;

use GLPI::Agent::Task::Collect::Version;
use GLPI::Agent::Task::Collect::Common;

use constant    MIN_TIMEOUT         => 10;
use constant    MAX_TIMEOUT_FACTOR  => 20;
use constant    MAX_DEFAULT_TIMEOUT => 3600;

our $VERSION = GLPI::Agent::Task::Collect::Version::VERSION;

my %modules;
my %json_validation;

unless (keys(%modules)) {
    my ($_classpath) = $INC{module2file(__PACKAGE__)} =~ /^(.*)\.pm$/;
    $_classpath =~ s{\\}{/}g if $OSNAME eq 'MSWin32';
    my ($_modulepath) = module2file(__PACKAGE__) =~ /^(.*)\.pm$/;
    $_modulepath =~ s{\\}{/}g if $OSNAME eq 'MSWin32';
    my $subclass_path_re = qr/$_modulepath\/(\S+)\.pm$/;
    foreach my $file (File::Glob::bsd_glob("$_classpath/*.pm")) {
        $file =~ s{\\}{/}g if $OSNAME eq 'MSWin32';
        my ($class) = $file =~ $subclass_path_re
            or next;
        next if $class eq "Version" or $class eq "Common";
        my $module = __PACKAGE__ . "::" . $class;
        $module->require()
            or next;
        next if $module->disabled;
        next unless $module->function;
        $modules{$module->function} = $module;
        $json_validation{$module->function} = $module->json_validation;
    }
}

sub isEnabled {
    my ($self) = @_;

    unless ($self->{target}->isType('server')) {
        $self->{logger}->debug("Collect task only compatible with server target");
        return;
    }

    return 1;
}

sub run {
    my ($self) = @_;

    # Just reset event if run as an event to not trigger another one
    $self->resetEvent();

    $self->{client} = GLPI::Agent::HTTP::Client::Fusion->new(
        logger  => $self->{logger},
        config  => $self->{config},
    );

    my $globalRemoteConfig = $self->{client}->send(
        url  => $self->{target}->getUrl(),
        args => {
            action    => "getConfig",
            machineid => $self->{deviceid},
            task      => { Collect => $VERSION },
        }
    );

    my $id = $self->{target}->id();
    if (!$globalRemoteConfig) {
        $self->{logger}->info("Collect task not supported by $id");
        return;
    }
    if (!$globalRemoteConfig->{schedule}) {
        $self->{logger}->info("No job schedule returned by $id");
        return;
    }
    if (ref( $globalRemoteConfig->{schedule} ) ne 'ARRAY') {
        $self->{logger}->info("Malformed schedule from by $id");
        return;
    }
    if ( !@{$globalRemoteConfig->{schedule}} ) {
        $self->{logger}->info("No Collect job enabled or Collect support disabled server side.");
        return;
    }

    my $run_jobs = 0;
    foreach my $job ( @{ $globalRemoteConfig->{schedule} } ) {
        next unless (ref($job) eq 'HASH' && exists($job->{task})
            && $job->{task} eq "Collect");
        $self->_processRemote($job->{remote});
        $run_jobs ++;
    }

    if ( !$run_jobs ) {
        $self->{logger}->info("No Collect job found in server jobs list.");
        return;
    }

    return 1;
}

sub _processRemote {
    my ($self, $remoteUrl) = @_;

    if ( !$remoteUrl ) {
        return;
    }

    my $answer = $self->{client}->send(
        url  => $remoteUrl,
        args => {
            action    => "getJobs",
            machineid => $self->{deviceid},
        }
    );

    if (ref($answer) eq 'HASH' && !keys %$answer) {
        $self->{logger}->debug("Nothing to do");
        return;
    }

    my $check = GLPI::Agent::Task::Collect::Common->new(logger => $self->{logger});
    return unless $check->validateAnswer(
        answer          => $answer,
        modules         => \%modules,
        json_validation => \%json_validation,
    );

    my @jobs = @{$answer->{jobs}}
        or die "no jobs provided, aborting";

    my $method  = exists($answer->{postmethod}) && $answer->{postmethod} eq 'POST' ? 'POST' : 'GET' ;
    my $token = exists($answer->{token}) ? $answer->{token} : '';
    my $has_csrf_token = empty($token) ? 0 : 1;
    my %jobsdone = ();

JOB:
    foreach my $job (@jobs) {

        $self->{logger}->debug2("Starting a collect job...");

        if ( !$job->{uuid} ) {
            $self->{logger}->error("UUID key missing");
            next;
        }

        $self->{logger}->debug2("Collect job has uuid: ".$job->{uuid});

        my $function = $job->{function};
        unless ($function) {
            $self->{logger}->error("function key missing");
            next;
        }

        unless (defined($modules{$function})) {
             $self->{logger}->error("Bad function '$function'");
            next;
        }

        my $module = $modules{$function};
        my $collect = $module->new(
            logger  => $self->{logger},
            job     => $job
        );

        my $maxtimeout = MAX_TIMEOUT_FACTOR * int($self->{config}->{'backend-collect-timeout'})
            || MAX_DEFAULT_TIMEOUT;
        my $timeout = int( !$self->{timeout} || $self->{timeout} !~ /^\d+$/ ?
            $self->{config}->{'backend-collect-timeout'} : $self->{timeout}
        );
        # Keep a minimum timeout or a maximun one
        $timeout = $timeout < MIN_TIMEOUT ? MIN_TIMEOUT : $timeout > $maxtimeout ? $maxtimeout : $timeout;

        my $results = runFunction(
            module      => $module,
            function    => "results",
            logger      => $self->{logger},
            timeout     => $timeout,
            params      => $collect,
        );

        $results = [] unless ref($results) eq 'ARRAY';

        my $count = int(@{$results});

        # Add an empty hash ref so send an answer with _cpt=0
        push @{$results}, {} unless $count ;

        foreach my $result (@{$results}) {
            next unless ref($result) eq 'HASH';
            next unless ( !$count || keys %$result );
            $result->{uuid}   = $job->{uuid};
            $result->{action} = "setAnswer";
            $result->{_cpt}   = $count;
            $result->{_glpi_csrf_token} = $token
                if $token ;
            $result->{_sid}   = $job->{_sid}
                if (exists($job->{_sid}));
            $answer = $self->{client}->send(
               url      => $remoteUrl,
               method   => $method,
               filename => sprintf('collect_%s_%s.js', $job->{uuid}, $count),
               args     => $result
            );
            $token = $answer && exists($answer->{token}) ? $answer->{token} : '';
            $count--;

            # Handle CSRF access denied
            if ($has_csrf_token && empty($token)) {
                $self->{logger}->error("Bad answer: CSRF checking is failing");
                # Send an empty answer to force an error on server job
                $self->{client}->send(
                    url  => $remoteUrl,
                    args => {
                        uuid   => $job->{uuid},
                        action => "setAnswer",
                    }
                );
                # Send a last message for server job log
                $self->{client}->send(
                    url  => $remoteUrl,
                    args => {
                        uuid         => $job->{uuid},
                        action       => "setAnswer",
                        csrf_failure => 1,
                    }
                );
                # No need to send job done message
                delete $jobsdone{$job->{uuid}};
                last JOB;
            }
        }

        # Set this job is done by uuid
        $jobsdone{$job->{uuid}} = 1;
    }

    # Finally send jobsDone for each seen jobs uuid
    foreach my $uuid (keys(%jobsdone)) {
        my $answer = $self->{client}->send(
            url  => $remoteUrl,
            args => {
                action => "jobsDone",
                uuid   => $uuid
            }
        );

        $self->{logger}->debug2("Got no response on $uuid jobsDone action")
            unless $answer;
    }

    return $self;
}

1;
