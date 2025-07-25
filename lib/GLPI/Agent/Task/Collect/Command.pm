package GLPI::Agent::Task::Collect::Command;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Collect::Common';

use constant    function    => "runCommand";

# As decided by developers team, the runCommand function is disabled for the moment.
use constant    disabled    => 1;

sub _runCommand {
    my ($self) = @_;

    my $filter = $self->{filter} // {};

    my $line;

    if ( $filter->{firstMatch} ) {
        $line = getFirstMatch(
            command => $self->{command},
            pattern => $filter->{firstMatch}
        );
    }
    elsif ( $filter->{firstLine} ) {
        $line = getFirstLine( command => $self->{command} );

    }
    elsif ( $filter->{lineCount} ) {
        $line = getLinesCount( command => $self->{command} );
    }
    else {
        $line = getAllLines( command => $self->{command} );

    }

    return ( { output => $line } );
}


1;
