package GLPI::Agent::SOAP::WsMan::Fault;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Fault;

use parent
    'Node';

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

    my $code;

    my $detail = $self->get('Detail');

    my $wmierror = $detail->get('MSFT_WmiError_Type');
    $code = $wmierror->get('error_Code')->string if $wmierror;

    my $wsmanerror;
    $wsmanerror = $detail->get('WSManFault') unless $code;
    $code = $wsmanerror->attribute('Code') if $wsmanerror;

    return $code // 0;
}

1;
