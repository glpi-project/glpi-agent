package GLPI::Agent::Task::Deploy::ActionProcessor;

use strict;
use warnings;

use Cwd;
use English qw(-no_match_vars);

use GLPI::Agent::Task::Deploy::ActionProcessor::Action::Move;
use GLPI::Agent::Task::Deploy::ActionProcessor::Action::Copy;
use GLPI::Agent::Task::Deploy::ActionProcessor::Action::Mkdir;
use GLPI::Agent::Task::Deploy::ActionProcessor::Action::Delete;
use GLPI::Agent::Task::Deploy::ActionProcessor::Action::Cmd;

sub new {
    my ($class, %params) = @_;

    die "no workdir parameter" unless $params{workdir};

    my $self = {
        workdir => $params{workdir}
    };

    bless $self, $class;

    return $self;
}

sub process {
    my ( $self, $actionName, $params, $logger ) = @_;

    my $workdir = $self->{workdir};

    if ( ( $OSNAME ne 'MSWin32' ) && ( $actionName eq 'messageBox' ) ) {
        return {
            status => 1,
            msg    => ["not Windows: action `$actionName' ignored"]
        };
    }

    my $ret;
    my $cwd = getcwd();
    chdir( $workdir->{path} );
    if ( $actionName eq 'checks' ) {
        # not an action
    } elsif ( $actionName eq 'move' ) {
        $ret =
          GLPI::Agent::Task::Deploy::ActionProcessor::Action::Move::do(
            $params, $logger);
    } elsif ( $actionName eq 'copy' ) {
        $ret =
          GLPI::Agent::Task::Deploy::ActionProcessor::Action::Copy::do(
            $params, $logger);
    } elsif ( $actionName eq 'mkdir' ) {
        $ret =
          GLPI::Agent::Task::Deploy::ActionProcessor::Action::Mkdir::do(
            $params, $logger);
    } elsif ( $actionName eq 'delete' ) {
        $ret =
          GLPI::Agent::Task::Deploy::ActionProcessor::Action::Delete::do(
            $params, $logger);
    } elsif ( $actionName eq 'cmd' ) {
        $ret =
          GLPI::Agent::Task::Deploy::ActionProcessor::Action::Cmd::do(
            $params, $logger);
   } else {
        $logger->debug("Unknown action type: `$actionName'");
        chdir($cwd);
        return {
            status => 0,
            msg    => ["unknown action `$actionName'"]
        };
    }
    chdir($cwd);

    return $ret;
}

1;
