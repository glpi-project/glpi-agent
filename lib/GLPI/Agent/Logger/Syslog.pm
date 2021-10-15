package GLPI::Agent::Logger::Syslog;

use strict;
use warnings;

use parent 'GLPI::Agent::Logger::Backend';

use Sys::Syslog qw(:standard :macros);

use GLPI::Agent::Version;

my %syslog_levels = (
    error   => LOG_ERR,
    warning => LOG_WARNING,
    info    => LOG_INFO,
    debug   => LOG_DEBUG,
    debug2  => LOG_DEBUG
);

my $syslog_name = lc($GLPI::Agent::Version::PROVIDER)."-agent";

sub new {
    my ($class, %params) = @_;

    my $self = {
        facility => $params{logfacility} || 'LOG_USER',
    };
    bless $self, $class;

    openlog($syslog_name, 'cons,pid', $self->{facility});

    return $self;
}

sub addMessage {
    my ($self, %params) = @_;

    my $level   = $params{level} || 'info';
    my $message = $params{message};

    syslog($syslog_levels{$level}, $message);
}

sub reload {
    my ($self) = @_;

    closelog();
    openlog($syslog_name, 'cons,pid', $self->{facility});
}

sub DESTROY {
    closelog();
}

1;
__END__

=head1 NAME

GLPI::Agent::Logger::Syslog - A syslog backend for the logger

=head1 DESCRIPTION

This is a syslog-based backend for the logger.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<facility>

the syslog facility to use (default: LOG_USER)

=back
