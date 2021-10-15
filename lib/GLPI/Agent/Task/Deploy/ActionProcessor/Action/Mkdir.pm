package FusionInventory::Agent::Task::Deploy::ActionProcessor::Action::Mkdir;

use strict;
use warnings;

use File::Path;
use Encode;

use English qw(-no_match_vars);

use UNIVERSAL::require;

sub do {
    my ($params, $logger) = @_;


    my $msg = [];
    my $status = 1;
    foreach my $dir (@{$params->{list}}) {

        my $dir_local = $dir;

        if ($OSNAME eq 'MSWin32' && Encode::is_utf8($dir)) {
            FusionInventory::Agent::Tools::Win32->require;
            my $localCodepage = FusionInventory::Agent::Tools::Win32::getLocalCodepage();
            $dir_local = encode($localCodepage, $dir);
        }

        if (-d $dir_local) {
            my $m = "Directory $dir already exists";
            push @$msg, $m;
            $logger->debug($m);
        } else {
            File::Path::mkpath($dir_local);
            if (!-d $dir_local) {
                $status = 0;
                my $m = "Failed to create $dir directory";
                push @$msg, $m;
                $logger->debug($m);
            }
        }
    }
    return {
    status => $status,
    msg => $msg,
    };
}

1;
