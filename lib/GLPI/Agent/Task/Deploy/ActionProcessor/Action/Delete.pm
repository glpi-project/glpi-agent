package GLPI::Agent::Task::Deploy::ActionProcessor::Action::Delete;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Deploy::ActionProcessor::Action';

use Encode;
use UNIVERSAL::require;

use English qw(-no_match_vars);

use GLPI::Agent::Task::Deploy::DiskFree;

sub do {
    my ($self, $params) = @_;

    return {
        status => 0,
        msg => [ "No folder to delete" ]
    } unless $params->{list} && @{$params->{list}};

    my $msg = [];
    my $status = 1;

    foreach my $loc (@{$params->{list}}) {

        my $loc_local = $loc;

        if ($OSNAME eq 'MSWin32') {
            GLPI::Agent::Tools::Win32->require;
            my $localCodepage = GLPI::Agent::Tools::Win32::getLocalCodepage();
            if (Encode::is_utf8($loc)) {
                $loc_local = encode($localCodepage, $loc);
            }
        }

        $self->debug2("Trying to delete '$loc'");
        remove_tree($loc_local);

        if (-e $loc || -d $loc) {
            $status = 0;
            my $m = "Failed to delete $loc";
            push @$msg, $m;
            $self->debug($m);
        }
    }
    return {
        status  => $status,
        msg     => $msg,
    };
}

1;
