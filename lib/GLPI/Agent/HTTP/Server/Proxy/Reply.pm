package GLPI::Agent::HTTP::Server::Proxy::Reply;

use strict;
use warnings;

use GLPI::Agent::XML;

sub new {
    my ($class, %params) = @_;

    my $self = {
        content => $params{content}
    };

    bless $self, $class;

    return $self;
}

sub getContent {
    my ($self) = @_;

    return GLPI::Agent::XML->new()->write({ REPLY => $self->{content} });
}

1;
