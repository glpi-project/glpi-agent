package GLPI::Agent::HTTP::Server::Plugin;

use strict;
use warnings;

use base "GLPI::Agent::Config";

use Cwd qw(abs_path);

use GLPI::Agent::Tools;

sub new {
    my ($class, %params) = @_;

    my ($name) = $class =~ /::(\w+)$/;

    my $self = {
        logger  => $params{server}->{logger} ||
                    GLPI::Agent::Logger->new(),
        server  => $params{server},
        name    => $name,
    };

    bless $self, $class;

    # Import _confdir from agent configuration
    $self->{_confdir} = $self->{server}->{agent}->{config}->{_confdir}
        if $self->{server};

    # Check _confdir imported from GLPI::Agent::Config
    unless ($self->{_confdir} && -d $self->{_confdir}) {
        # Set absolute confdir from default if replaced by Makefile otherwise search
        # from current path, mostly useful while running from source but also
        # with windows portable release
        $self->{_confdir} = abs_path(File::Spec->rel2abs(
            $self->{_confdir} || first { -d $_ } qw{ ./etc  ../etc ../../etc }
        ));
    }

    return $self;
}

sub init {
    my ($self) = @_;

    my $version;
    {
        no strict 'refs';  ## no critic
        $version = ${ref($self).'::VERSION'};
    }
    $version = $GLPI::Agent::VERSION unless $version;

    $self->debug("Initializing ".$self->{name}." v$version Server plugin...");

    # Load defaults
    my $defaults = $self->defaults();
    foreach my $param (keys(%{$defaults})) {
        $self->{$param} = $defaults->{$param};
    }

    if ($self->confdir() && $self->config_file()) {
        my $config = $self->confdir().'/'.$self->config_file();
        if (-f $config && -r $config) {
            $self->debug("Loading ".$self->{name}." Server plugin configuration from $config");
            # Load configuration file
            $self->loadFromFile({file => $config, defaults => $defaults});
        } else {
            $self->debug($self->{name}." Server plugin configuration missing: $config");
        }
    }
}

# Plugins with greater priority values are used first
sub priority { 10 }

sub name {
    my ($self) = @_;
    return $self->{name};
}

# Defaults must be a key-value pair list ref if and only if a config file
# is to be read while config_file() method returns a config filename
sub defaults {
    return {};
}

sub supported_method {
    my ($self, $method) = @_;

    return 1 if $method eq 'GET';

    $self->error("invalid request type: $method");

    return 0;
}

sub port {
    my ($self) = @_;
    return $self->{port}
        if ($self->{port} && $self->{port} =~ /^\d+$/ && $self->{port} < 65536);
    return 0;
}

# A plugin can be disabled by configuration or by server
sub disabled {
    my ($self) = @_;
    return ($self->{disabled} && $self->{disabled} !~ /^0|no$/i) ? 1 : 0 ;
}

sub disable {
    my ($self, $reason) = @_;
    $self->{disabled} = 1;
    $self->info($reason // "plugin disabled");
}

sub log_prefix {
    return "[http server plugin] ";
}

sub error {
    my ($self, $message) = @_;
    return unless $self->{logger};
    $self->{logger}->error( $self->log_prefix() . $message );
}

sub info {
    my ($self, $message) = @_;
    return unless $self->{logger};
    $self->{logger}->info( $self->log_prefix() . $message );
}

sub debug {
    my ($self, $message) = @_;
    return unless $self->{logger};
    $self->{logger}->debug( $self->log_prefix() . $message );
}

sub debug2 {
    my ($self, $message) = @_;
    return unless $self->{logger};
    $self->{logger}->debug2( $self->log_prefix() . $message );
}

sub config {
    my ($self, $name, $value) = @_;
    $self->{$name} = $value if (defined($value));
    return $self->{$name};
}

sub config_file {}

sub urlMatch {}

sub handle {}

sub timer_event {}

sub rate_limited {
    my ($self, $clientIp) = @_;

    my $maxrate = $self->config('maxrate');
    my $maxrate_period = $self->config('maxrate_period') || 3600;

    return unless $clientIp && $maxrate;

    my $now = time;

    $self->{_rate_limitation}->{$clientIp} = []
        unless ($self->{_rate_limitation} && $self->{_rate_limitation}->{$clientIp});

    my $tries = $self->{_rate_limitation}->{$clientIp};

    # First cleanup old tries
    while (@{$tries} && $tries->[0] < $now - $maxrate_period) {
        shift @{$tries};
    }

    # Keep try timestamp unless still limited and in the same second
    push @{$tries}, $now
        unless (@{$tries} > $maxrate && $tries->[-1] == $now);

    if (@{$tries} > $maxrate) {
        my $limit_log = $self->{_rate_limitation_log} || 0;
        # Also limit logging on heavy load
        if ($limit_log < $now - 10) {
            $self->info("request rate limitation applied for remote $clientIp");
            if ($self->{_rate_limitation_log_filter}) {
                $self->info("$self->{_rate_limitation_log_filter} limited requests not logged");
            }
            $self->{_rate_limitation_log_filter} = 0;
            $self->{_rate_limitation_log} = $now;
        } else {
            $self->{_rate_limitation_log_filter} ++;
        }
        return 1;
    }
    return 0;
}

1;
__END__

=head1 NAME

GLPI::Agent::HTTP::Server::Plugin - A class template for embedded HTTP server plugins

=head1 DESCRIPTION

This is a template class to base on GLPI::Agent::HTTP::Server plugins.

Plugins purpose is to handle specific requests.

=head1 CLASS METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<server>

the associated server

=back

=head1 INSTANCE METHODS

=head2 $plugin->urlMatch($path)

Returns true if the passed path match the plugin expected URL pattern.

=head2 $plugin->handle($client, $request, $clientIp)

Handles the matching incoming request.

=head2 $plugin->timer_event()

Can be defined to support events triggered on timeout. Should return the next
expected timer timeout (in seconds to be compared to time function returned value)
for this plugin.

=head2 $plugin->priority()

Returns plugin priority against any other plugin (default = 10).

Greater priority makes the plugin be used befores lower priority plugins.

=head2 $plugin->log_prefix()

Should return a log prefix to be used in logging for a plugin.

=head2 $plugin->config_file()

Can return config filename to be loaded from the config dir, none by default.

Config file can contain any key/value pair like the normal agent configuration
file. Even include directive could be used. No validation is done during the
configuration load. The plugin should carefully check loaded values when used.

=head2 $plugin->init()

Initializes a plugin, by default, this loads a configuration file if defined and found.

A calling plugin child should always test if it is disabled before continuing some
other initializations.

=head2 $plugin->config($name, $value)

Set named configuration value to $value if defined.

Returns the set or loaded configuration value for the given value name.

=head2 $plugin->error($message)

Log error level message using log_prefix

=head2 $plugin->info($message)

Log information level message using log_prefix

=head2 $plugin->debug($message)

Log debug level message using log_prefix

=head2 $plugin->debug2($message)

Log debug2 level message using log_prefix

=head2 $plugin->name()

Returns the plugin name

=head2 $plugin->defaults()

Returns a hash ref with default value to be used for not set parameters

=head2 $plugin->port()

Returns the configurated port or 0 to use the default

=head2 $plugin->disable()

Disable the plugin

=head2 $plugin->disabled()

Returns true is a plugin is disabled

=head2 $plugin->rate_limited()

Returns true if a request reach the rate limitation.

The plugin must support the "maxrate" parameter setting it with a default in
defaults() API. You can also set "maxrate_period" in defaults, but it could be
not set and then 3600 seconds will be used by default. If "maxrate" request count
is reach during the "maxrate_period" period in seconds, the API returns true.

The API keeps the time access by request by IP and will only keep the access of
requests in the "maxrate_period" last seconds. It is not advised to set a high
"maxrate".

Call this API from your handle() API as soon as possible to avoid any abuse.

=head2 $plugin->supported_method($method)

Returns true if $method is supported by this plugin. By default, only 'GET' is
supported.
