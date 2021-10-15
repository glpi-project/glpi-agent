package GLPI::Test::Auth;

use strict;
use parent 'Authen::Simple::Adapter';

__PACKAGE__->options({
    user => {
        type => Params::Validate::SCALAR
    },
    password => {
        type => Params::Validate::SCALAR
    }
});

sub check {
    my ($self, $user, $password) = @_;

    return
        $user eq $self->user() &&
        $password eq $self->password();
}

1
