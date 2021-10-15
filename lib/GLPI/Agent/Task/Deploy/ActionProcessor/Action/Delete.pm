package FusionInventory::Agent::Task::Deploy::ActionProcessor::Action::Delete;

use strict;
use warnings;

use File::Path;
use UNIVERSAL::require;

use English qw(-no_match_vars);

sub do {
    my ($params, $logger) = @_;

    my $msg = [];
    my $status = 1;

    foreach my $loc (@{$params->{list}}) {

        my $loc_local = $loc;

        if ($OSNAME eq 'MSWin32') {
            FusionInventory::Agent::Tools::Win32->require;
            my $localCodepage = FusionInventory::Agent::Tools::Win32::getLocalCodepage();
            if (Encode::is_utf8($loc)) {
                $loc_local = encode($localCodepage, $loc);
            }
        }

        File::Path::remove_tree($loc_local);
        $status = 0 if -e $loc;
        my $m = "Failed to delete $loc";
        push @$msg, $m;
        $logger->debug($m);
    }
    return {
    status => $status,
    msg => $msg,
    };
}

1;
