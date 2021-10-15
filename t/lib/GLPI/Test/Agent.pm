package GLPI::Test::Agent;

use strict;
use warnings;
use parent qw(GLPI::Agent);

use File::Temp;

sub new {
    my ($class) = @_;

    my $self = {
        status  => 'ok',
        targets => [],
        config  => {
            vardir  => File::Temp->newdir()
        }
    };
    bless $self, $class;

    return $self;
}

1;
