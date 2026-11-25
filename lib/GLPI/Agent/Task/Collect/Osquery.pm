package GLPI::Agent::Task::Collect::Osquery;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Collect::Common';

use UNIVERSAL::require;

use GLPI::Agent::Tools;

use constant    function    => "runOsquery";

use constant    OPTIONAL        => 0;
use constant    MANDATORY       => 1;

use constant    json_validation => {
    query   => MANDATORY,
    timeout => OPTIONAL,
};

sub results {
    my ($self) = @_;

    return unless $self->{query} && $self->{query} =~ /^select\s/i;

    my $command = [ "osqueryi", "--json", "--query", $self->{query} ];

    my $output = getAllLines(
        command => $command,
        logger  => $self->{logger},
    );

    Cpanel::JSON::XS->require();
    Cpanel::JSON::XS->import("decode_json");

    my $json;

    eval {
        $json = decode_json($output);
    };

    return ref($json) eq "ARRAY" ? $json : [];
}

1;
