package GLPI::Agent::SOAP::WsMan::Action;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Action;

use parent
    'Node';

use constant    xmlns   => 'a';

use GLPI::Agent::Tools;
use GLPI::Agent::SOAP::WsMan::Attribute;

my %actions = (
    command             => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/Command",
    commandresponse     => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/CommandResponse",
    create              => "http://schemas.xmlsoap.org/ws/2004/09/transfer/Create",
    createresponse      => "http://schemas.xmlsoap.org/ws/2004/09/transfer/CreateResponse",
    delete              => "http://schemas.xmlsoap.org/ws/2004/09/transfer/Delete",
    deleteresponse      => "http://schemas.xmlsoap.org/ws/2004/09/transfer/DeleteResponse",
    receive             => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/Receive",
    receiveresponse     => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/ReceiveResponse",
    signal              => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/Signal",
    signalresponse      => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/SignalResponse",
    get                 => "http://schemas.xmlsoap.org/ws/2004/09/transfer/Get",
    enumerate           => "http://schemas.xmlsoap.org/ws/2004/09/enumeration/Enumerate",
    enumerateresponse   => "http://schemas.xmlsoap.org/ws/2004/09/enumeration/EnumerateResponse",
    pull                => "http://schemas.xmlsoap.org/ws/2004/09/enumeration/Pull",
    pullresponse        => "http://schemas.xmlsoap.org/ws/2004/09/enumeration/PullResponse",
    end                 => "http://schemas.microsoft.com/wbem/wsman/1/wsman/End",
    fault               => [
        "http://schemas.dmtf.org/wbem/wsman/1/wsman/fault",
        "http://schemas.xmlsoap.org/ws/2004/08/addressing/fault",
    ],
);

sub new {
    my ($class, $action) = @_;

    my $url = $actions{$action} // $action;

    my $self = $class->SUPER::new(
        Attribute->must_understand(),
        $url
    );

    bless $self, $class;
    return $self;
}

sub set {
    my ($self, $action) = @_;

    return unless $actions{$action};

    return $self->string($actions{$action});
}

sub is {
    my ($self, $action) = @_;

    return unless $actions{$action};

    my $string = $self->string;
    return first { $string eq $_ } @{$actions{$action}}
        if ref($actions{$action}) eq 'ARRAY';

    return $string eq $actions{$action};
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
