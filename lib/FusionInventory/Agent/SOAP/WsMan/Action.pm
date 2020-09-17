package FusionInventory::Agent::SOAP::WsMan::Action;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Action;

use parent 'Node';

use constant    xmlns   => 'a';

use FusionInventory::Agent::SOAP::WsMan::Attribute;

my %actions = (
    get                 => "http://schemas.xmlsoap.org/ws/2004/09/transfer/Get",
    enumerate           => "http://schemas.xmlsoap.org/ws/2004/09/enumeration/Enumerate",
    enumerateresponse   => "http://schemas.xmlsoap.org/ws/2004/09/enumeration/EnumerateResponse",
    pull                => "http://schemas.xmlsoap.org/ws/2004/09/enumeration/Pull",
    pullresponse        => "http://schemas.xmlsoap.org/ws/2004/09/enumeration/PullResponse",
    end                 => "http://schemas.microsoft.com/wbem/wsman/1/wsman/End",
    fault               => "http://schemas.dmtf.org/wbem/wsman/1/wsman/fault",
);

sub new {
    my ($class, $action) = @_;

    my $url = $actions{$action} // $action;

    my @nodes = (
        Attribute->must_understand(),
        '#text' => $url,
    );

    my $self = $class->SUPER::new(@nodes);

    bless $self, $class;
    return $self;
}

sub set {
    my ($self, $action) = @_;

    return unless $actions{$action};

    return $self->string($actions{$action});
}

sub is {
    my ($self, $url) = @_;

    return unless $actions{$url};
    return $self->string eq $actions{$url};
}

sub what {
    my ($self) = @_;

    my $url = $self->string;

    foreach my $known (keys(%actions)) {
        return $known if $url eq $actions{$known};
    }

    return $url;
}

1;
