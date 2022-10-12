package GLPI::Agent::SOAP::WsMan::PartComponent;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    PartComponent;

# Required if we need to make request on Win32_SystemUsers

use parent
    'Node';

use constant    xmlns   => 'p';

use constant    dump_as_string => 1;

sub string {
    my ($self) = @_;

    my $refparams = $self->get("ReferenceParameters")
        or return;

    my $resource = $refparams->get("ResourceURI")
        or return;

    my $selectorset = $refparams->get("SelectorSet")
        or return;

    my $selector = $selectorset->get("Selector")
        or return;

    my $string = $resource->string.".";
    foreach my $node ($selector->nodes()) {
        my $name = $node->attribute("Name");
        my $text = $node->string;
        $string .= "," unless $string =~ /\.$/;
        $string .= "$name=\"$text\"";
    }

    return $string;
}

1;
