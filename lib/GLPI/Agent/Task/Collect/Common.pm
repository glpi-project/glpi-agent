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

sub _validateSpec {
    my ($self, $base, $key, $spec) = @_;

    if (ref($spec) eq 'HASH') {
        if (!exists($base->{$key})) {
            $self->{logger}->debug("$key mandatory values are missing in job");
            return 0;
        }
        $self->{logger}->debug2("$key mandatory values are present in job");
        foreach my $attribute (keys(%{$spec})) {
            return 0 unless $self->_validateSpec($base->{$key}, $attribute, $spec->{$attribute});
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

sub validateAnswer {
    my ($self, %params) = @_;

    my $modules = $params{modules};
    my $json_validation = $params{json_validation};
    unless (ref($modules) && ref($json_validation)) {
        $self->{logger}->debug("Validation failure");
        return 0;
    }

    my $answer = $params{answer};
    unless (defined($answer)) {
        $self->{logger}->debug("Bad JSON: No answer from server.");
        return 0;
    }

    if (ref($answer) ne 'HASH') {
        $self->{logger}->debug("Bad JSON: Bad answer from server. Not a hash reference.");
        return 0;
    }

    if (!defined($answer->{jobs}) || ref($answer->{jobs}) ne 'ARRAY') {
        $self->{logger}->debug("Bad JSON: Missing jobs");
        return 0;
    }

    foreach my $job (@{$answer->{jobs}}) {

        foreach (qw/uuid function/) {
            if (!defined($job->{$_})) {
                $self->{logger}->debug("Bad JSON: Missing key '$_' in job");
                return 0;
            }
        }

        my $function = $job->{function};
        unless (exists($modules->{$function})) {
            $self->{logger}->debug("Bad JSON: not supported 'function' key value in job");
            return 0;
        }

        my $validation = $json_validation->{$function};
        unless (ref($validation)) {
            $self->{logger}->debug("Bad JSON: Can't validate job");
            return 0;
        }

        foreach my $attribute (keys(%{$validation})) {
            unless ($self->_validateSpec($job, $attribute, $validation->{$attribute})) {
                $self->{logger}->debug("Bad JSON: '$function' job JSON format is not valid");
                return 0;
            }
        }
    }

    return 1;
}

1;
