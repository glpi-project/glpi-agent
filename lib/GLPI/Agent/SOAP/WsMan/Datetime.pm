package GLPI::Agent::SOAP::WsMan::Datetime;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Datetime;

use parent
    'Node';

use constant xmlns  => 'cim';

sub new {
    my ($class, $datetime) = @_;

    # Convert Datetime
    if ($datetime =~ /^(\d{4})-(\d{2})-(\d{2})T00:00:00Z$/) {
        $datetime = "$2/$3/$1";
    } elsif ($datetime =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
        $datetime = "$1-$2-$3 $4:$5:$6";
    }

    my $self = $class->SUPER::new($datetime);

    bless $self, $class;

    return $self;
}

1;
