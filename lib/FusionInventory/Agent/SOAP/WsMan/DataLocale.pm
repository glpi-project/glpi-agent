package FusionInventory::Agent::SOAP::WsMan::DataLocale;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    DataLocale;

use parent 'Node';

use FusionInventory::Agent::SOAP::WsMan::Attribute;

use constant    xmlns   => 'p';

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
