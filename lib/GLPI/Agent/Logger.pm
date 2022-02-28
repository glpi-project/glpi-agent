package GLPI::Agent::Logger;

use strict;
use warnings;

use constant {
    LOG_DEBUG2  => 5,
    LOG_DEBUG   => 4,
    LOG_INFO    => 3,
    LOG_WARNING => 2,
    LOG_ERROR   => 1,
    LOG_NONE    => 0,
};

use English qw(-no_match_vars);
use UNIVERSAL::require;

# Package level shared logger config
my $config;

sub new {
    my ($class, %params) = @_;

    my $first_pass = defined($config) ? 0 : 1 ;

    # Initialize or reset Logger configuration
    if ($params{config}) {
        $config = ref($params{config}) eq 'GLPI::Agent::Config' ?
            $params{config}->logger() : $params{config} ;
    } elsif ($first_pass) {
        $config = \%params;
    } else {
        # Later new creation could be used to update the shared config
        foreach my $param (keys(%params)) {
            $config->{$param} = $params{$param};
        }
    }

    my $debug = $config->{debug} || 0 ;

    my $self = {
        verbosity => $debug >= 2 ? LOG_DEBUG2 :
                     $debug == 1 ? LOG_DEBUG  :
                                   LOG_INFO
    };
    bless $self, $class;

    my %backends;
    my $backends = $config->{logger} || $params{logger};
    foreach (
        $backends ? @{$backends} : 'Stderr'
    ) {
        my $backend = ucfirst($_);
        next if $backends{$backend};
        my $package = "GLPI::Agent::Logger::$backend";
        $package->require();
        if ($EVAL_ERROR) {
            print STDERR
                "Failed to load Logger backend $backend: ($EVAL_ERROR)\n";
            next;
        }
        $backends{$backend} = 1;

        my $logger = $package->new(%{$config});
        push @{$self->{backends}}, $logger;

        # Only debug backend initialization was passed the first time
        $self->debug("Logger backend $backend initialized") if $first_pass && !$logger->test;
    }

    # Only log agent version string during the first object creation
    $self->debug($GLPI::Agent::VERSION_STRING) if $first_pass;

    return $self;
}

sub _log {
    my ($self, %params) = @_;

    # levels: debug2, debug, info, warning, error
    my $level = $params{level} || 'info';
    my $message = $params{message};

    return unless $message;

    # Add a prefix to the message if set
    $message = $self->{prefix}.$message if $self->{prefix};

    chomp($message);

    foreach my $backend (@{$self->{backends}}) {
        $backend->addMessage (
            level => $level,
            message => $message
        );
    }
}

sub reload {
    my ($self) = @_;

    foreach my $backend (@{$self->{backends}}) {
        $backend->reload();
    }
}

sub debug_level {
    my ($self) = @_;

    return $self->{verbosity} > LOG_INFO ? $self->{verbosity} - LOG_INFO : 0;
}

sub debug2 {
    my ($self, $message) = @_;

    return unless $self->{verbosity} >= LOG_DEBUG2;
    $self->_log(level => 'debug2', message => $message);
}

sub debug {
    my ($self, $message) = @_;

    return unless $self->{verbosity} >= LOG_DEBUG;
    $self->_log(level => 'debug', message => $message);
}

sub debug_result {
    my ($self, %params) = @_;

    return unless $self->{verbosity} >= LOG_DEBUG;

    my $status = $params{status} || ($params{data} ? 'success' : 'no result');

    $self->_log(
        level   => 'debug',
        message => sprintf('- %s: %s', $params{action}, $status)
    );
}

sub info {
    my ($self, $message) = @_;

    return unless $self->{verbosity} >= LOG_INFO;
    $self->_log(level => 'info', message => $message);
}

sub warning {
    my ($self, $message) = @_;

    return unless $self->{verbosity} >= LOG_WARNING;
    $self->_log(level => 'warning', message => $message);
}

sub error {
    my ($self, $message) = @_;

    return unless $self->{verbosity} >= LOG_ERROR;
    $self->_log(level => 'error', message => $message);
}

1;
__END__

=head1 NAME

GLPI::Agent::Logger - GLPI logger

=head1 DESCRIPTION

This is the logger object.

As this object will mostly be instanciated one time, logger configuration is stored
at the package level. So if you create a new object but without config, it will
re-use the saved configuration.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<config>

the agent configuration object, to pass debug level and backends parameters

=back

=head2 debug2($message)

Add a log message with debug2 level.

=head2 debug($message)

Add a log message with debug level.

=head2 info($message)

Add a log message with info level.

=head2 warning($message)

Add a log message with warning level.

=head2 error($message)

Add a log message with error level.

=head2 debug_result(%params)

Add a log message with debug level related to an action result.

=head2 debug_level()

Get current logger debug level.
