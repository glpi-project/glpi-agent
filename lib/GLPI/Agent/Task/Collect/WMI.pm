package GLPI::Agent::Task::Collect::WMI;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Collect::Common';

use UNIVERSAL::require;

use constant    function    => "getFromWMI";

use constant    OPTIONAL        => 0;
use constant    MANDATORY       => 1;

use constant    json_validation => {
    class      => MANDATORY,
    properties => MANDATORY,
    timeout    => OPTIONAL,
};

sub results {
    my ($self) = @_;

    return unless GLPI::Agent::Tools::Win32->require();

    return unless $self->{properties};
    return unless $self->{class};

    # Split given properties if possible
    $self->{properties} = [ split(/[, ]+/, $self->{properties}[0]) ]
        if $self->{properties}[0] =~ /[, ]/;

    my @results;

    my @objects = GLPI::Agent::Tools::Win32::getWMIObjects(%{$self});
    foreach my $object (@objects) {
        push @results, $object;
    }

    return \@results;
}

1;
