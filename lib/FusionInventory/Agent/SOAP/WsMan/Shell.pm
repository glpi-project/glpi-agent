package FusionInventory::Agent::SOAP::WsMan::Shell;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Shell;

use parent 'Node';

use FusionInventory::Agent::SOAP::WsMan::Attribute;
use FusionInventory::Agent::SOAP::WsMan::InputStreams;
use FusionInventory::Agent::SOAP::WsMan::OutputStreams;
use FusionInventory::Agent::SOAP::WsMan::CommandLine;
use FusionInventory::Agent::SOAP::WsMan::Command;
use FusionInventory::Agent::SOAP::WsMan::Arguments;

use constant    xmlns   => 'rsp';
use constant    xsd     => "http://schemas.microsoft.com/wbem/wsman/1/windows/shell";

sub support {
    return {
        Selector    => "w:Selector",
    };
}

sub new {
    my ($class, @params) = @_;

    push @params, Attribute->new("xmlns:".$class->xmlns => xsd),
        InputStreams->new(),
        OutputStreams->new()
        unless @params;

    my $self = $class->SUPER::new(@params);

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
