package GLPI::Agent::Task::Collect::Common;

use strict;
use warnings;

use constant    function        => "";
use constant    disabled        => 0;
use constant    json_validation => {};

use constant    OPTIONAL            => 0;
use constant    MANDATORY           => 1;
use constant    OPTIONAL_EXCLUSIVE  => 2;

sub new {
    my ($class, %params) = @_;

    my $self = $params{job} // {};

    $self->{logger} = $params{logger};

    bless $self, $class;

    return $self;
}

sub validateSpec {
    my ($self, $base, $key, $spec) = @_;

    if (ref($spec) eq 'HASH') {
        if (!exists($base->{$key})) {
            $self->{logger}->debug("$key mandatory values are missing in job");
            return 0;
        }
        $self->{logger}->debug2("$key mandatory values are present in job");
        foreach my $attribute (keys(%{$spec})) {
            return 0 unless $self->validateSpec($base->{$key}, $attribute, $spec->{$attribute});
        }
        return 1;
    }

    if ($spec == MANDATORY) {
        if (!exists($base->{$key})) {
            $self->{logger}->debug("$key mandatory value is missing in job");
            return 0;
        }
        $self->{logger}->debug2("$key mandatory value is present in job");
        return 1;
    }

    if ($spec == OPTIONAL && exists($base->{$key})) {
        $self->{logger}->debug2("$key optional value is present in job");
    }

    1;
}

1;
