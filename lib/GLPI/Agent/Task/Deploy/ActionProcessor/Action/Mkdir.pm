package GLPI::Agent::Task::Deploy::ActionProcessor::Action::Mkdir;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Deploy::ActionProcessor::Action';

use File::Path qw(make_path);
use Encode;
use English qw(-no_match_vars);
use UNIVERSAL::require;

sub do {
    my ($self, $params) = @_;

    return {
        status => 0,
        msg => [ "No destination folder to create" ]
    } unless $params->{list} && @{$params->{list}};

    my $msg = [];
    my $status = 1;
    foreach my $dir (@{$params->{list}}) {

        my $dir_local = $dir;

        if ($OSNAME eq 'MSWin32' && Encode::is_utf8($dir)) {
            GLPI::Agent::Tools::Win32->require;
            my $localCodepage = GLPI::Agent::Tools::Win32::getLocalCodepage();
            $dir_local = encode($localCodepage, $dir);
        }

        if (-d $dir_local) {
            my $m = "Directory $dir already exists";
            push @$msg, $m;
            $self->debug($m);
        } else {
            my $error;
            $self->debug2("Trying to create '$dir'");
            make_path($dir_local, { error => \$error });
            if (!-d $dir_local) {
                $status = 0;
                my $m = "Failed to create $dir directory";
                push @$msg, $m;
                push @$msg, $error if $error;
                map { $self->debug($_) } @$msg;
            }
        }
    }
    return {
        status => $status,
        msg => $msg,
    };
}

1;
