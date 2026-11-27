package GLPI::Agent::Task::Deploy::ActionProcessor::Action;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use GLPI::Agent::Task::Deploy::Signature;

sub new {
    my ($class, %params) = @_;

    my $self = {
        _logger             => $params{logger},
        authorized_actions  => $params{authorized_actions},
    };

    if ($params{action}) {
        $class .= "::" . ucfirst($params{action});
        $class->require();
    }

    bless $self, $class;

    return $self;
}

sub do {}

sub isAuthorized {
    my ($self, $name, $params) = @_;
    my $authorized = $self->{authorized_actions};
    # No policy means unsigned mode; an empty policy authorizes nothing.
    return 1 unless defined($authorized);
    my $signing = GLPI::Agent::Task::Deploy::Signature->new(logger => $self->{_logger});
    my $digest = $signing->actionDigest($name, $params);
    return $digest && $authorized->{$digest} ? 1 : 0;
}

sub sources {
    my ($self, $from) = @_;
    if ($OSNAME eq 'MSWin32') {
        # Work-around while running as a service in win32 after a chdir in a thread
        File::DosGlob->require();
        return File::DosGlob::glob($from);
    } else {
        File::Glob->require();
        return File::Glob::bsd_glob($from);
    }
}

sub debug {
    my ($self, $message) = @_;
    $self->{_logger}->debug($message);
}

sub debug2 {
    my ($self, $message) = @_;
    $self->{_logger}->debug2($message);
}

sub error {
    my ($self, $message) = @_;
    $self->{_logger}->error($message);
}

1;
