package GLPI::Agent::Task::Deploy::ActionProcessor::Action::Cmd;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Deploy::ActionProcessor::Action';

use Fcntl qw(SEEK_SET);
use UNIVERSAL::require;

use English qw(-no_match_vars);

sub _evaluateRet {
    my ($retChecks, $buf, $exitStatus) = @_;

    if (ref($retChecks) ne 'ARRAY') {
        return [ 1, 'ok, no check to evaluate.' ];
    }

    foreach my $retCheck (@$retChecks) {

        if ($retCheck->{type} eq 'okCode') {
            foreach (@{$retCheck->{values}}) {
                if ($exitStatus == $_) {
                    return [ 1, "exit status is ok: $_" ];
                }
            }
        } elsif ($retCheck->{type} eq 'okPattern') {
            foreach (@{$retCheck->{values}}) {
                next unless length($_);
                if ($$buf =~ /$_/) {
                    return [ 1, "ok pattern found in log: /$_/" ];
                }
            }
        } elsif ($retCheck->{type} eq 'errorCode') {
            foreach (@{$retCheck->{values}}) {
                if ($exitStatus == $_) {
                    return [ 0, "exit status is not ok: `$_'" ];
                }
            }
        } elsif ($retCheck->{type} eq 'errorPattern') {
            foreach (@{$retCheck->{values}}) {
                next unless length($_);
                if ($$buf =~ /$_/) {
                    return [ 0, "error pattern found in log: /$_/" ];
                }
            }
        }
    }
    return [ 0, '' ];
}

sub _runOnUnix {
    my ($self, $params) = @_;

    my $buf = `$params->{exec} 2>&1` || '';
    my $errMsg = "$ERRNO";

    # CHILD_ERROR could be negative if exec command is not found, in that case
    # We shoudl report exitStatus as if it was started from shell
    my $exitStatus = $CHILD_ERROR < 0 ? 127 : $CHILD_ERROR >> 8;

    $self->debug2("Run: ".$buf);

    return ($buf, $errMsg, $exitStatus);
}

sub _runOnWindows {
    my ($self, $params) = @_;

    GLPI::Agent::Tools::Win32->require;

    my ($exitcode, $fd) = GLPI::Agent::Tools::Win32::runCommand(
        command => $params->{exec}
    );

    $fd->seek(0, SEEK_SET);

    my $buf;
    while(my $line = readline($fd)) {
        $buf .= $line;
    }
    close $fd;
    $self->debug2("Run: ".$buf);

    my $errMsg = '';
    if ($exitcode eq '293') {
        $errMsg = "timeout";
    }

    return ($buf, $errMsg, $exitcode);
}


sub do {
    my ($self, $params) = @_;

    return { 0, ["Internal agent error"]} unless $params->{exec};

    my %envsSaved;

    if ($params->{envs}) {
        foreach my $key (keys %{$params->{envs}}) {
            $envsSaved{$key} = $ENV{$key};
            $ENV{$key} = $params->{envs}{$key};
        }
    }

    my $buf;
    my $errMsg;
    my $exitStatus;

    if ($OSNAME eq 'MSWin32') {
        ($buf, $errMsg, $exitStatus) = $self->_runOnWindows($params);
    } else {
        ($buf, $errMsg, $exitStatus) = $self->_runOnUnix($params);
    }

    my $logLineLimit = defined($params->{logLineLimit}) ?
        $params->{logLineLimit} : 10 ;

    my @msg;
    if($buf) {
        my @lines = split('\n', $buf);
        foreach my $line (reverse @lines) {
            chomp($line);
            unshift @msg, $line;
            # Empty lines are kept for local debugging but without updating logLineLimit
            next unless $line;
            last unless --$logLineLimit;
        }
    }

    # Use the retChecks key to know if the command exec is successful
    my $t = _evaluateRet ($params->{retChecks}, \$buf, $exitStatus);

    my $status = $t->[0];
    push @msg, "--------------------------------";
    push @msg, "error msg: `$errMsg'" if $errMsg;
    push @msg, "exit status: `$exitStatus'";
    push @msg, $t->[1];

    # Finally insert header showing started command
    unshift @msg, "================================";
    unshift @msg,  "Started cmd: ".$params->{exec};
    unshift @msg, "================================";

    foreach (@msg) {
        $self->debug($_);
    }
    $self->debug("final status: ".$status);

    if ($params->{envs}) {
        foreach my $key (keys %envsSaved) {
            $ENV{$key} = $envsSaved{$key};
        }
    }

    return {
        status => $status,
        msg => \@msg,
    }
}

1;
