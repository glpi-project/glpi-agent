package GLPI::Agent::Event::TaskRun;

use strict;
use warnings;

use parent qw(GLPI::Agent::Event);

use GLPI::Agent::Tools;

use constant priority       => 30;

use constant taskrun        => 1;
use constant name           => "run";

# A "taskrun" event can be requested on agent httpd server
use constant httpd_support  => 1;

sub new {
    my ($class, %params) = @_;

    # "taskrun" event:
    #  - can be trigerred by /now http requests or following a runnow event
    #  - must be evaluated before partial inventory as it can use "partial" param
    #  - task is mandatory and can only be used to trigger a planned task
    #  - can be delayed using delay param to provide a delay value in seconds
    #  - for inventory task:
    #    - full or partial params can be to "1" or "yes"
    #    - full default is 1 and has precedence other partial if the 2 are defined

    return if empty($params{task}) || empty($params{taskrun}) || $params{taskrun} !~ /^yes|1$/i;

    # Partial inventory request on given categories
    my $self = {
        _task    => $params{task}, # mandatory
        _delay   => $params{delay} // 0,
        _params  => {
            # Support parameter to reset target next rundate on task run
            reschedule => $params{reschedule} // 0,
        }
    };

    # Bless before calling supported method
    bless $self, $class;

    # Store any other supported params
    if ($self->task eq "inventory") {
        if (defined($params{full})) {
            $self->{_params}->{full} = $params{full} =~ /^yes|1$/i ? 1 : 0;
        } elsif (defined($params{partial})) {
            $self->{_params}->{full} = $params{partial} =~ /^yes|1$/i ? 0 : 1;
        } else {
            # Always default to full when full and partial are not set
            $self->{_params}->{full} = 1;
        }
    }

    return $self;
}

1;
