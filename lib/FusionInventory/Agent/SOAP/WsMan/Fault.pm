package FusionInventory::Agent::SOAP::WsMan::Fault;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Fault;

use parent 'Node';

use constant    xmlns   => 's';

sub support {
    return {
        Reason  => "s:Reason",
        Code    => "s:Code",
    };
}

sub reason {
    my ($self) = @_;

    my ($reason) = $self->get('Reason');

    return $reason // Reason->new();
}

sub errorCode {
    my ($self) = @_;

    my $details = $self->get('Detail')->get('MSFT_WmiError_Type')->get('error_Code')->string;

    return $details // 0;
}

1;
