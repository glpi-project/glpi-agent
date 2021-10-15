package GLPI::Agent::Task::Inventory::Generic::Databases;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use UNIVERSAL::require;
use English qw(-no_match_vars);

use constant    category    => "database";

sub isEnabled {
    my (%params) = @_;

    # Database inventory can be done remotely by using appropriate credentials
    return $params{remote} ? 0 : 1;
}

sub doInventory {}

sub _credentials {
    my ($hashref, $usage) = @_;

    my @credentials = ();
    my $params = delete $hashref->{params};
    my $logger = $hashref->{logger};

    if ($params) {
        foreach my $param (@{$params}) {
            my $url = $param->{_glpi_url}
                or next;
            next unless $param->{params_id} && $param->{_glpi_client};
            next unless $param->{category} && $param->{category} eq "database";
            next unless $param->{use} && grep { $_ eq $usage } @{$param->{use}};
            GLPI::Agent::Protocol::GetParams->require();
            if ($EVAL_ERROR) {
                $logger->error("Can't request credentials on $url")
                    if $logger;
                last;
            }
            my $getparams = GLPI::Agent::Protocol::GetParams->new(
                deviceid    => $hashref->{inventory}->getDeviceId(),
                params_id   => $param->{params_id},
                use         => $usage,
            );
            my $answer = $param->{_glpi_client}->send(
                url     => $url,
                message => $getparams
            );
            if ($answer) {
                my $status = $answer->get('status');
                my $credentials = $answer->get('credentials');
                if ($status eq 'ok' && $credentials) {
                    if (@{$credentials}) {
                        push @credentials, @{$credentials};
                    } else {
                        $logger->debug("No credential returned for credentials id ".$param->{params_id})
                            if $logger;
                    }
                } elsif ($status eq 'error') {
                    my $message = $answer->get('message') // 'no error given';
                    $logger->debug("Credential request error: $message")
                        if $logger;
                } else {
                    $logger->error("Unsupported credentials request answer")
                        if $logger;
                }
            } else {
                $logger->error("Got no credentials with credentials id ".$param->{params_id})
                    if $logger;
            }
        }
    }

    if ($hashref->{inventory}) {
        my $credentials = $hashref->{inventory}->credentials();
        if (ref($credentials) eq "ARRAY") {
            push @credentials, grep {
                (!defined($_->{category}) || $_->{category} eq "database")
                &&
                (!defined($_->{use}) || $_->{use} =~ /\b$usage\b/i)
            } @{$credentials};
        }
    }

    # When no credential is provided, leave module tries its default database access
    push @credentials, {} unless @credentials;

    $hashref->{credentials} = \@credentials;
}

sub trying_credentials {
    my ($logger, $credential) = @_;

    return unless $logger && $credential;

    if ($credential->{type}) {
        my $debugid = defined($credential->{params_id}) && length($credential->{params_id}) ?
            " id $credential->{params_id}" : "";
        $logger->debug2("Trying $credential->{type} credential type$debugid");
    } else {
        $logger->debug2("Trying default credential");
    }
}

1;
