package FusionInventory::Agent::SOAP::WsMan::To;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    To;

use parent 'Node';

use constant    xmlns   => 'a';
use constant    xsd     => "http://schemas.xmlsoap.org/ws/2004/08/addressing";

use FusionInventory::Agent::SOAP::WsMan::Address;

sub new {
    my ($class, $url) = @_;

    my $self = $class->SUPER::new('#text' => $url);

    bless $self, $class;
    return $self;
}

sub anonymous {
    my ($class) = @_;

    return $class->new("http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous");
}

1;
