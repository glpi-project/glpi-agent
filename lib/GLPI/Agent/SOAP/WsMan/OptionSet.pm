package GLPI::Agent::SOAP::WsMan::OptionSet;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    OptionSet;

use parent
    'Node';

use constant    xmlns   => 'w';
use constant    xsins   => "http://www.w3.org/2001/XMLSchema-instance";

sub new {
    my ($class, @params) = @_;

    my $self = $class->SUPER::new(
        Attribute->new( "xmlns:xsi" => xsins ),
        @params,
    );

    bless $self, $class;
    return $self;
}

1;
