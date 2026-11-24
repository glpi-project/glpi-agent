package GLPI::Agent::Event::Job;

use strict;
use warnings;

use parent qw(GLPI::Agent::Event);

use GLPI::Agent::Tools;

use constant priority   => 60;

use constant job        => 1;

sub new {
    my ($class, %params) = @_;

    # "job" event:
    #  - "name" params is mandatory
    #  - job events are created by toolbox managed inventory tasks
    #  - can't be triggered via http request

    return if empty($params{name}) || empty($params{job}) || $params{job} !~ /^yes|1$/i;

    # Partial inventory request on given categories
    my $self = {
        _name    => $params{name}, # mandatory
        _rundate => $params{rundate} // 0,
        _task    => $params{task} // "",
    };

    return bless $self, $class;
}

1;
