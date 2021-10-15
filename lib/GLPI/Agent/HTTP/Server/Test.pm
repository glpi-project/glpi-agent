package GLPI::Agent::HTTP::Server::Test;

use strict;
use warnings;

use base "GLPI::Agent::HTTP::Server::Plugin";

sub urlMatch {
    my ($self, $path) = @_;

    $self->debug("Matching on $path ?");

    if ($path =~ m{^/test/([\w\d/-]+)?$}) {
        $self->{test} = $1;
        $self->debug2("Found matching on $path");
        return 1;
    }

    return 0;
}

sub handle {
    my ($self, $client, $request, $clientIp) = @_;

    $self->info("Test request from $clientIp: /test/".$self->{test}." (config: ".($self->{configtest}||"none").")");

    delete $self->{test};

    $client->send_response(200);
    return 200;
}

sub log_prefix {
    return "[server test plugin] ";
}

sub config_file {
    return "server-test-plugin.cfg";
}

sub defaults {
    return {
        disabled    => "yes",
        configtest  => "test",
        port        => 0,
    };
}

1;
__END__

=head1 NAME

GLPI::Agent::HTTP::Server::Test - An embedded HTTP server plugin as
test and sample server plugin

=head1 DESCRIPTION

This is a server plugin to listen for test requests.

It listens on port 62354 by default.

Any requests matching the following is accepted and returns a 200 HTTP code:

=over

=item /test/*

=back
