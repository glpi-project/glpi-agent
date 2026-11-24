package GLPI::Agent::Event::Init;

use strict;
use warnings;

use parent qw(GLPI::Agent::Event);

use GLPI::Agent::Tools;

use constant priority   => 10;

use constant init       => 1;
use constant name       => "init";

sub new {
    my ($class, %params) = @_;

    # "init" event:
    #  - an init event is triggered for each supported task when the service starts
    #  - it can't be triggered via http request

    return if empty($params{init}) || $params{init} !~ /^yes|1$/i;

    my $self = {
        _task    => $params{task} // "",
        _rundate => $params{rundate} // 0,
    };

    return bless $self, $class;
}

1;
