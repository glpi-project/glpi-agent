package GLPI::Agent::SOAP::WsMan::Shell;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Shell;

use parent
    'Node';

use GLPI::Agent::SOAP::WsMan::Attribute;
use GLPI::Agent::SOAP::WsMan::InputStreams;
use GLPI::Agent::SOAP::WsMan::OutputStreams;
use GLPI::Agent::SOAP::WsMan::CommandLine;
use GLPI::Agent::SOAP::WsMan::Command;
use GLPI::Agent::SOAP::WsMan::Arguments;

use constant    xmlns   => 'rsp';
use constant    xsd     => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell";

sub support {
    return {
        Selector    => "w:Selector",
    };
}

sub new {
    my ($class, @params) = @_;

    # For some reasons, remote answers with wrong case on ResourceURI when remote is done from windows
    $params[0]->{'rsp:ResourceURI'} = delete $params[0]->{'rsp:ResourceUri'}
        if $params[0] && ref($params[0]) eq 'HASH' && exists($params[0]->{'rsp:ResourceUri'});

    my $self = $class->SUPER::new(@params);

    $self->push(
        Attribute->new("xmlns:".$class->xmlns => xsd),
        InputStreams->new(),
        OutputStreams->new()
    ) unless @params;

    bless $self, $class;

    return $self;
}

sub commandline {
    my ($self, $command) = @_;

    my ($cmd, $args) = $command =~ /^\s*(\S+)\s*(.*)$/;

    my $cmdline = CommandLine->new(
        Attribute->new( $self->namespace ),
        Command->new($cmd),
    );
    $cmdline->push(Arguments->new($args))
        if defined($args) && length($args);

    return $cmdline;
}

1;
