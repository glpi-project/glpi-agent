package FusionInventory::Agent::SOAP::WsMan::Envelope;

use strict;
use warnings;

package
    Envelope;

use FusionInventory::Agent::SOAP::WsMan::Attribute;
use FusionInventory::Agent::SOAP::WsMan::Header;
use FusionInventory::Agent::SOAP::WsMan::Body;

sub new {
    my ($class, @nodes) = @_;

    my $self = {
        _nodes      => [],
        _attributes => [
            Attribute->new("xmlns:s" => "https://www.w3.org/2003/05/soap-envelope"),
        ],
    };

    foreach my $node (@nodes) {
        my $ref = ref($node)
            or next;
        if ($ref eq 'Attribute') {
            push @{$self->{_attributes}}, $node;
        } elsif ($ref =~ /^Body|Header$/) {
            push @{$self->{_nodes}}, $node;
        } elsif ($ref eq 'HASH' && $node->{'s:Envelope'}) {
            $self->{_attributes} = [];
            foreach my $key (keys(%{$node->{'s:Envelope'}})) {
                if ($key =~ /^-(.+)$/) {
                    push @{$self->{_attributes}}, Attribute->new($1 => $node->{'s:Envelope'}->{$key});
                } elsif ($key =~ /^s:Header/i && defined($node->{'s:Envelope'}->{$key})) {
                    push @{$self->{_nodes}}, Header->new(%{$node->{'s:Envelope'}->{$key}});
                } elsif ($key =~ /^s:Body/i && defined($node->{'s:Envelope'}->{$key})) {
                    push @{$self->{_nodes}}, Body->new(%{$node->{'s:Envelope'}->{$key}});
                }
            }
        }
    }

    bless $self, $class;
    return $self;
}

sub _init {
    my ($self, $tree) = @_;
}

sub get {
    my ($self) = @_;

    my @envelope = map { $_->get() } @{$self->{_attributes}};
    push @envelope, map { $_->get() } @{$self->{_nodes}};

    return {
        "s:Envelope" => { @envelope }
    };
}

1;
