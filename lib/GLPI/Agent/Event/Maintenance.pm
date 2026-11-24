package GLPI::Agent::Event::Maintenance;

use strict;
use warnings;

use parent qw(GLPI::Agent::Event);

use GLPI::Agent::Tools;

use constant priority       => 50;

use constant maintenance    => 1;

sub new {
    my ($class, %params) = @_;

    # "maintenance" event:
    #  - a "maintenance" event can triggered to handle delayed code
    #  - for deploy, it cleans up storage from file parts when too old
    #  - it can't be triggered via http request

    return if empty($params{maintenance}) || $params{maintenance} !~ /^yes|1$/i;

    # Partial inventory request on given categories
    my $self = {
        _name   => $params{name} // "maintenance",
        _task    => $params{task} // "",
        _delay  => $params{delay} // 0,
    };

    return bless $self, $class;
}

1;
