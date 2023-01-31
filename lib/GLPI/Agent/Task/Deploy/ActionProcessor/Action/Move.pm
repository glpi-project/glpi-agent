package GLPI::Agent::Task::Deploy::ActionProcessor::Action::Move;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Deploy::ActionProcessor::Action';

use English qw(-no_match_vars);
use Encode;
use File::Copy::Recursive qw(rcopy);
use UNIVERSAL::require;

use GLPI::Agent::Task::Deploy::DiskFree;

$File::Copy::Recursive::CPRFComp = 1;

sub do {
    my ($self, $params) = @_;

    my $to = $params->{to};
    return {
        status => 0,
        msg => [ "No destination for move action" ]
    } unless $to;

    my $msg = [];
    my $status = 1;
    my @sources = $self->sources($params->{from});
    $self->debug2("Nothing to move with: ".$params->{from}) unless @sources;
    foreach my $from (@sources) {

        if ($OSNAME eq 'MSWin32') {
            Win32->require();
            # Work-around for agent running as a service on win32, making this
            # call fixes an error when requesting stat on file after a chdir
            $from = Win32::GetFullPathName($from);
        }

        $self->debug2("Moving '$from' to '$to'");

        my $from_local = $from;
        my $to_local = $to;

        if ($OSNAME eq 'MSWin32') {
            GLPI::Agent::Tools::Win32->require;
            my $localCodepage = GLPI::Agent::Tools::Win32::getLocalCodepage();
            if (Encode::is_utf8($from)) {
                $from_local = encode($localCodepage, $from);
            }
            if (Encode::is_utf8($to)) {
                $to_local = encode($localCodepage, $to);
            }
        }

        # Work-around for rmove which can fail in win32 service context
        if (!File::Copy::Recursive::rcopy($from_local, $to_local)) {
            my $m = "Failed to move: '".$from."' to '".$to."'";
            push @$msg, $m;
            $self->debug($m);
            if ($ERRNO) {
                push @$msg, $ERRNO;
                $self->debug2($ERRNO);
            }

            $status = 0;
        } else {
            remove_tree($from_local);
        }
    }
    return {
        status => $status,
        msg => $msg,
    };
}

1;
