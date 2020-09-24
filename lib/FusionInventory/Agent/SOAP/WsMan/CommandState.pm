package FusionInventory::Agent::SOAP::WsMan::CommandState;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    CommandState;

use parent 'Node';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::SOAP::WsMan::Stream;
use FusionInventory::Agent::SOAP::WsMan::ExitCode;

use constant    xmlns   => 'rsp';

sub support {
    return {
        ExitCode    => "rsp:ExitCode",
    };
}

sub done {
    my ($self, $cid) = @_;

    if ($cid) {
        my $thiscid = first { $_->get("CommandId") } $self->attributes();
        return 0 unless $thiscid && $thiscid->get("CommandId") eq $cid;
    }

    my $done_url = "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/CommandState/Done";
    my $state = first { $_->get("State") } $self->attributes();
    return $state && $state->get("State") eq $done_url ? 1 : 0 ;
}

sub exitcode {
    my ($self) = @_;

    my $exitcode = $self->get('ExitCode')
        or return;

    return $exitcode->string();
}

1;
