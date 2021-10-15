package GLPI::Agent::SOAP::WsMan::Code;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Code;

use parent
    'Node';

sub support {
    return {
        Value   => "s:Value",
    };
}

sub xmlns {
    my ($self) = @_;

    return $self->{_signal} ? 'rsp' : 's';
}

sub signal {
    my ($class, $signal) = @_;

    my %code = (
        terminate   => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/signal/terminate",
    );

    return unless $code{$signal};

    my $new = $class->new($code{$signal});
    $new->{_signal} = 1;

    return $new;
}

1;
