package FusionInventory::Agent::Task::Deploy::ActionProcessor::Action::Move;

use strict;
use warnings;

$File::Copy::Recursive::CPRFComp = 1;
use English qw(-no_match_vars);
use File::Copy::Recursive;
use File::Glob;
use UNIVERSAL::require;

sub do {
    my ($params, $logger) = @_;

    my $msg = [];
    my $status = 1;
    foreach my $from (File::Glob::bsd_glob($params->{from})) {

        my $to = $params->{to};

        my $from_local = $from;
        my $to_local = $to;

        if ($OSNAME eq 'MSWin32') {
            FusionInventory::Agent::Tools::Win32->require;
            my $localCodepage = FusionInventory::Agent::Tools::Win32::getLocalCodepage();
            if (Encode::is_utf8($from)) {
                $from_local = encode($localCodepage, $from);
            }
            if (Encode::is_utf8($to)) {
                $to_local = encode($localCodepage, $to);
            }
        }

        if (!File::Copy::Recursive::rmove($from_local, $to_local)) {
            my $m = "Failed to move: `".$from."' to '".$to;
            push @$msg, $m;
            push @$msg, $ERRNO;
            $logger->debug($m);

            $status = 0;
        }
    }
    return {
        status => $status,
        msg => $msg,
    };
}

1;
