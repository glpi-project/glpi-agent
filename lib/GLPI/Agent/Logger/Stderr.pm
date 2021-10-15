package GLPI::Agent::Logger::Stderr;

use strict;
use warnings;

use parent 'GLPI::Agent::Logger::Backend';

use English qw(-no_match_vars);

sub new {
    my ($class, %params) = @_;

    my $self = {
        _formats => $params{color} && {
            warning => "\033[1;35m[%s] %s\033[0m\n",
            error   => "\033[1;31m[%s] %s\033[0m\n",
            info    => "\033[1;34m[%s]\033[0m %s\n",
            debug   => "\033[1;1m[%s]\033[0m %s\n",
            debug2  => "\033[1;36m[%s]\033[0m %s\n"
        }
    };

    bless $self, $class;

    return $self;
}

sub addMessage {
    my ($self, %params) = @_;

    my $level   = $params{level} || 'info';
    my $message = $params{message}
        or return;

    my $format = $self->{_formats} && $self->{_formats}->{$level} ?
        $self->{_formats}->{$level} : "[%s] %s\n";

    printf STDERR $format, $level, $message;

}

1;
__END__

=head1 NAME

GLPI::Agent::Logger::Stderr - A stderr backend for the logger

=head1 DESCRIPTION

This is a stderr-based backend for the logger. It supports coloring based on
message level on Unix platforms.
