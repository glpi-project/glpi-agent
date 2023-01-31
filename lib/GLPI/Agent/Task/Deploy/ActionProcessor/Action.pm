package GLPI::Agent::Task::Deploy::ActionProcessor::Action;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

sub new {
    my ($class, %params) = @_;

    my $self = {
        _logger => $params{logger},
    };

    if ($params{action}) {
        $class .= "::" . ucfirst($params{action});
        $class->require();
    }

    bless $self, $class;

    return $self;
}

sub do {}

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

1;
