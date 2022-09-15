package GLPI::Agent::HTTP::Server::BasicAuthentication;

use strict;
use warnings;

use base "GLPI::Agent::HTTP::Server::Plugin";

use MIME::Base64;

# Authentication should be passed before other plugins
use constant priority => 100;

our $VERSION = "1.0";

sub urlMatch {
    my ($self, $path) = @_;
    # By default, re_path_match => qr{^.*$}
    return 0 unless $path =~ $self->{re_path_match};
    $self->{request} = $1;
    return 1;
}

sub log_prefix {
    return "[basic authentication server plugin] ";
}

sub config_file {
    return "basic-authentication-server-plugin.cfg";
}

sub defaults {
    return {
        disabled            => "yes",
        url_path_regexp     => ".*",
        port                => 0,
        realm               => undef,
        user                => undef,
        password            => undef,
        # Supported by class GLPI::Agent::HTTP::Server::Plugin
        maxrate             => 600,
        maxrate_period      => 600,
    };
}

sub init {
    my ($self) = @_;

    $self->SUPER::init(@_);

    # Don't do more initialization if disabled
    return if $self->disabled();

    # Check basic authentication is well setup if plugin is enabled
    unless ($self->config('user') && $self->config('password')) {
        $self->error("Plugin enabled without basic authentication fully setup");
        $self->disable("Plugin disabled on wrong configuration");
        return;
    }

    my $defaults = $self->defaults();
    my $url_path_regexp = $self->config('url_path_regexp');
    $self->debug("Using '$url_path_regexp' as base url matching regexp")
        if $url_path_regexp ne $defaults->{url_path_regexp};
    $self->{re_path_match} = qr{^$url_path_regexp$};

    # Setup a default realm if not set
    $self->config('realm', "GLPI Agent")
        unless $self->config('realm');
}

sub supported_method {
    my ($self, $method) = @_;

    return 1 if $method eq 'GET' || $method eq 'POST';

    $self->error("invalid request type: $method");

    return 0;
}

sub handle {
    my ($self, $client, $request, $clientIp) = @_;

    # rate limit by ip to avoid abuse
    if ($self->rate_limited($clientIp)) {
        $client->send_error(429); # Too Many Requests
        return 429;
    }

    my $auth = $request->header('Authorization');
    unless ($auth) {
        my $response = HTTP::Response->new(
            401,
            'Unauthorized',
            HTTP::Headers->new('WWW-Authenticate' => 'Basic realm="'.$self->config('realm').'"')
        );
        $client->send_response($response);
        return 401;
    }

    # Return 0 to leave other plugins really handle the request
    return 0 if $self->_authorized($auth);

    $client->send_error(403, "Forbidden");
    return 403;
}

sub _authorized {
    my ($self, $auth) = @_;

    my ($basic, $credential) = split(" ", $auth)
        or return 0;

    return 0 unless $basic =~ /^Basic$/i;

    my ($user, $password) = split(/:/, decode_base64($credential));
    return $user eq $self->config('user') && $password eq $self->config('password') ? 1 : 0;
}

1;
__END__

=head1 NAME

GLPI::Agent::HTTP::Server::BasicAuthentication - A plugin to enable basic authentication

=head1 DESCRIPTION

This is a server plugin to enable basic authentication.

It can only apply on other plugins requests and eventually on /runnow & /status requests.

=head1 CONFIGURATION

=over

=item disabled         C<yes> by default

=item url_path_regexp  C<.*> by default

=item port             C<0> by default to use default one

=item realm            C<GLPI Agent> by default

=item user             not defined by default. The plugin is disabled untill one is set.

=item password         not defined by default. The plugin is disabled untill one is set.

=item maxrate          C<600> by default

=item maxrate_period   C<600> (in seconds) by default.

=back

Defaults can be overrided in C<basic-authentication-server-plugin.cfg> file or better in the
C<basic-authentication-server-plugin.local> as included from C<basic-authentication-server-plugin.cfg>
by default.
