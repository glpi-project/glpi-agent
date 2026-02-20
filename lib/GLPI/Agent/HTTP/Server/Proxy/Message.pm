package GLPI::Agent::HTTP::Server::Proxy::Message;

use strict;
use warnings;

sub new {
    my ($class, %params) = @_;

    my $self = {
        content => $params{content},
    };
    bless $self, $class;
}

sub getContent {
    my ($self) = @_;

    return $self->{content};
}

1;
