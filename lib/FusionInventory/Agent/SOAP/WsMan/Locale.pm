package FusionInventory::Agent::SOAP::WsMan::Locale;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Locale;

use parent 'Node';

use constant    xmlns   => 'w';

use FusionInventory::Agent::SOAP::WsMan::Attribute;

sub new {
    my ($class, $locale) = @_;

    my @nodes = (
        Attribute->must_understand("false"),
        Attribute->new( "xml:lang" => $locale),
    );

    my $self = $class->SUPER::new(@nodes);

    bless $self, $class;
    return $self;
}

1;
