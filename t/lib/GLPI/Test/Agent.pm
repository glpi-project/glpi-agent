package GLPI::Test::Agent;

use strict;
use warnings;
use parent qw(GLPI::Agent);

use File::Temp;

sub new {
    my ($class) = @_;

    # It's more reliable to store File::Temp object in a private property and then store the vardir path in config as a string
    my $vardir = File::Temp->newdir();
    my $path   = $vardir->dirname;

    my $self = {
        status  => 'ok',
        targets => [],
        _vardir => $vardir,
        config  => {
            vardir  => $path
        }
    };
    bless $self, $class;

    return $self;
}

1;
