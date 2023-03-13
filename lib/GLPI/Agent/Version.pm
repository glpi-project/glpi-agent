package GLPI::Agent::Version;

use strict;
use warnings;

our $VERSION = "1.5-dev";
our $PROVIDER = "GLPI";
our $COMMENTS = [];

1;

__END__

=head1 NAME

GLPI::Agent::Version - GLPI Agent version

=head1 DESCRIPTION

This module has the only purpose to simplify the way the agent is released. This
file could be automatically generated and overridden during packaging.

It permits to re-define agent VERSION and agent PROVIDER during packaging so
any distributor can simplify his distribution process and permit to identify
clearly the origin of the agent.

It also permits to put build comments in $COMMENTS. Each array ref element will
be reported in output while using --version option. This will be also seen in logs.
The idea is to authorize the provider to put useful information needed while
agent issue is reported.
One very useful information should be first defined like in that example:

our $COMMENTS = [
    "Based on GLPI Agent 1.5-dev"
];
