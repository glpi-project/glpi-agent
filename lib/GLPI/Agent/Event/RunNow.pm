package GLPI::Agent::Event::RunNow;

use strict;
use warnings;

use parent qw(GLPI::Agent::Event);

use GLPI::Agent::Tools;

use constant priority       => 20;

use constant runnow         => 1;
use constant name           => "run now";

# A "runnow" event can be requested on agent httpd server
use constant httpd_support  => 1;

sub new {
    my ($class, %params) = @_;

    # "runnow" event:
    #  - can be trigerred by /now http requests from agent HTTP UI or GLPI
    #  - must be evaluated before partial inventory event as it can use "partial" param
    #  - can be used to trigger one or more tasks via task or tasks param
    #  - can be delayed using delay param to provide a delay value in seconds
    #  - inventory task can be forced to full by setting "full" param to "1" or "yes"

    return if empty($params{runnow}) || $params{runnow} !~ /^yes|1$/i;

    my $self = {
        _task    => $params{task} || $params{tasks} || "all",
        _delay   => $params{delay} // 0,
    };

    # Store any other params
    foreach my $key (grep { $_ !~ /^runnow|tasks?|delay$/i } keys(%params)) {
        $self->{_params}->{$key} = $params{$key} // "";
    }

    return bless $self, $class;
}

1;
