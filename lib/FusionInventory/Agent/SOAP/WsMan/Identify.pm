package FusionInventory::Agent::SOAP::WsMan::Identify;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Identify;

use parent 'Node';

my $xmlns = "wsmid";
my $xsd = "http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd";
my %values = map { $_ => "$xmlns:$_" } qw(ProtocolVersion ProductVendor ProductVersion);

sub get {
    my ($self, $valuename) = @_;

    if ($valuename) {
        return unless exists($values{$valuename});

        return $self->SUPER::get($values{$valuename});
    }

    return "$xmlns:IdentifyResponse" => $self->SUPER::get();
}

sub isvalid {
    my ($self) = @_;

    my ($nsxsd) = $self->attributes("xmlns:$xmlns");

    return $nsxsd && $nsxsd =~ /^$xsd$/i ? 1 : 0;
}

sub namespace {
    return "xmlns:$xmlns" => $xsd
}

sub request {
    return "$xmlns:Identify" => ""
}

1;
