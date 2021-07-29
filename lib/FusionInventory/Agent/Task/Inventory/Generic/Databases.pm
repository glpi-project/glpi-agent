package FusionInventory::Agent::Task::Inventory::Generic::Databases;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use UNIVERSAL::require;
use English qw(-no_match_vars);

use constant    category    => "database";

sub isEnabled {
    return 1;
}

sub doInventory {}

sub _credentials {
    my ($hashref, $usage) = @_;

    my @credentials = ();
    my $params = delete $hashref->{params};

    if ($params) {
        foreach my $param (@{$params}) {
            my $url = delete $param->{params_url}
                or next;
            next unless $param->{params_id} && $params->{glpi_client};
            next unless $param->{category} && $param->{category} eq "database";
            next unless $param->{use} && grep { $_ eq "mysql" } @{$param->{use}};
            GLPI::Agent::Protocol::GetParams->require();
            if ($EVAL_ERROR) {
                $hashref->{logger}->error("Can't request credentials on $url")
                    if $hashref->{logger};
                last;
            }
            my $getparams = GLPI::Agent::Protocol::GetParams->new(
                deviceid    => $hashref->{inventory}->getDeviceId(),
                params_id   => $param->{params_id},
                use         => $usage,
            );
            my $answer = $hashref->{glpi_client}->send(
                send    => $url,
                message => $getparams
            );
            if ($answer) {
                my $credentials = $answer->get('credentials');
                push @credentials, @{$credentials} if @{$credentials};
            } else {
                $hashref->{logger}->error("Got no credentials with $param->{params_id} credentials id")
                    if $hashref->{logger};
            }
        }
    }

    if ($hashref->{inventory}) {
        my $credentials = $hashref->{inventory}->credentials();
        push @credentials, @{$credentials}
            if ref($credentials) eq "ARRAY";
    }

    # When no credential is provided, leave module tries its default database access
    push @credentials, {} unless @credentials;

    $hashref->{credentials} = \@credentials;
}

1;
