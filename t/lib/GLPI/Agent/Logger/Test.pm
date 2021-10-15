package GLPI::Agent::Logger::Test;

use strict;
use warnings;

use parent 'GLPI::Agent::Logger::Backend';

use English qw(-no_match_vars);

use constant    test => 1;

sub new {
    my ($class, $params) = @_;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub addMessage {
    my ($self, %params) = @_;

    $self->{message} = $params{message};
    $self->{level}   = $params{level};
}

1;
