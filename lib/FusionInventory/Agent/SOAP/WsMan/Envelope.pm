package FusionInventory::Agent::SOAP::WsMan::Envelope;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

package
    Envelope;

use parent 'Node';

use FusionInventory::Agent::SOAP::WsMan::Attribute;
use FusionInventory::Agent::SOAP::WsMan::Header;
use FusionInventory::Agent::SOAP::WsMan::Body;

sub new {
    my ($class, @nodes) = @_;

    my $self;

    my ($first) = @nodes;
    if (ref($first) eq 'HASH' && $first->{'s:Envelope'}) {
        $self= $class->SUPER::new();
        foreach my $key (keys(%{$first->{'s:Envelope'}})) {
            if ($key =~ /^-(.+)$/) {
                push @{$self->{_attributes}}, Attribute->new($1 => $first->{'s:Envelope'}->{$key});
            } elsif ($key =~ /^s:Header/i && defined($first->{'s:Envelope'}->{$key})) {
                push @{$self->{_nodes}}, Header->new(%{$first->{'s:Envelope'}->{$key}});
            } elsif ($key =~ /^s:Body/i && defined($first->{'s:Envelope'}->{$key})) {
                push @{$self->{_nodes}}, Body->new(%{$first->{'s:Envelope'}->{$key}});
            }
        }
    } else {
        unshift @nodes, Attribute->new("xmlns:s" => "https://www.w3.org/2003/05/soap-envelope");
        $self= $class->SUPER::new(@nodes);
    }

    bless $self, $class;
    return $self;
}

sub get {
    my ($self, $node) = @_;

    return $self->SUPER::get($node) if $node;

    return {
        "s:Envelope" => $self->SUPER::get()
    };
}

sub body {
    my ($self) = @_;

    my ($body) = $self->get('Body');

    return $body // Body->new();
}

1;
