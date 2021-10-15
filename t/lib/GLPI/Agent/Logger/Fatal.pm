package FusionInventory::Agent::Logger::Fatal;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Logger::Backend';

use English qw(-no_match_vars);
use Carp;

use constant    test => 1;

sub new {
    my ($class, $params) = @_;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub addMessage {
    my ($self, %params) = @_;

    croak $params{message};
}

1;
