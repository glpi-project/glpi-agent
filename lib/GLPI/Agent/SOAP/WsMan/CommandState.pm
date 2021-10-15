package GLPI::Agent::SOAP::WsMan::CommandState;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    CommandState;

use parent
    'Node';

use GLPI::Agent::Tools;

use constant    xmlns   => 'rsp';

sub support {
    return {
        ExitCode    => "rsp:ExitCode",
    };
}

sub done {
    my ($self, $cid) = @_;

    if ($cid) {
        my $thiscid = $self->attribute("CommandId");
        return 0 unless $thiscid && $thiscid eq $cid;
    }

    my $done_url = "http://schemas.microsoft.com/wbem/wsman/1/windows/shell/CommandState/Done";
    my $state = $self->attribute("State");

    return $state && $state eq $done_url ? 1 : 0 ;
}

sub exitcode {
    my ($self) = @_;

    my $exitcode = $self->get('ExitCode')
        or return;

    return $exitcode->string();
}

1;
