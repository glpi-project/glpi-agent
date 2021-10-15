package GLPI::Agent::SOAP::WsMan::ResourceURI;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    ResourceURI;

use parent
    'Node';

use constant    xmlns   => 'w';

use GLPI::Agent::SOAP::WsMan::Attribute;

sub new {
    my ($class, $url) = @_;

    my $self = $class->SUPER::new(
        Attribute->must_understand(),
        $url,
    );

    bless $self, $class;
    return $self;
}

1;
