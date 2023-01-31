package GLPI::Agent::Task::Deploy::ActionProcessor;

use strict;
use warnings;

use Cwd;
use English qw(-no_match_vars);

use GLPI::Agent::Task::Deploy::ActionProcessor::Action;

sub new {
    my ($class, %params) = @_;

    die "no workdir parameter" unless $params{workdir};

    my $self = {
        _logger  => $params{logger},
        _workdir => $params{workdir},
        _curdir  => getcwd(),
        _failed  => 0,
    };

    bless $self, $class;

    return $self;
}

sub starting {
    my ($self) = @_;
    chdir($self->{_workdir}) if $self->{_workdir};
}

sub done {
    my ($self) = @_;
    chdir($self->{_curdir}) if $self->{_curdir};
}

sub failure {
    my ($self) = @_;
    $self->{_failed} = 1;
}

sub failed {
    my ($self) = @_;
    return $self->{_failed} ? 1 : 0;
}

sub process {
    my ($self, $actionName, $params) = @_;

    my $ret;

    if ($actionName eq 'checks') {
        # not an action
    } elsif ( $actionName =~ /^cmd|copy|delete|mkdir|move$/i ) {
        $self->{_logger}->debug2("Processing $actionName action...");
        my $action = GLPI::Agent::Task::Deploy::ActionProcessor::Action->new(
            logger  => $self->{_logger},
            action  => $actionName
        );
        $ret = $action->do($params);
    } else {
        $self->{_logger}->debug("Unknown action type: '$actionName'");
        return {
            status => 0,
            msg    => ["unknown action `$actionName'"]
        };
    }

    return $ret;
}

1;
