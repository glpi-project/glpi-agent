package FusionInventory::Agent::SOAP::WsMan::Node;

use strict;
use warnings;

BEGIN {
    $INC{'Node.pm'} = __FILE__;
}

package
    Node;

use constant    xmlns   => "";
use constant    xsd     => "";

use FusionInventory::Agent::SOAP::WsMan::Attribute;
use FusionInventory::Agent::SOAP::WsMan::Body;
use FusionInventory::Agent::SOAP::WsMan::Header;
use FusionInventory::Agent::SOAP::WsMan::Fault;
use FusionInventory::Agent::SOAP::WsMan::Reason;
use FusionInventory::Agent::SOAP::WsMan::Code;
use FusionInventory::Agent::SOAP::WsMan::Identify;
use FusionInventory::Agent::SOAP::WsMan::Text;
use FusionInventory::Agent::SOAP::WsMan::Value;
use FusionInventory::Agent::SOAP::WsMan::Option;
use FusionInventory::Agent::SOAP::WsMan::Shell;
use FusionInventory::Agent::SOAP::WsMan::ReferenceParameters;

my $autoload = join('|', qw(
    Body        Header      To          ResourceURI ReplyTo     Address
    MessageID   Action      Locale      DataLocale  SessionId   OperationID
    SequenceId  SelectorSet Selector    Items       EndOfSequence
    Identify    MaxEnvelopeSize         OperationTimeout        SelectorSet
    Enumerate   EnumerateResponse       EnumerationContext      PullResponse
    Shell       Option      InputStreams            Code        OutputStreams
    CommandLine Command     CommandId   CommandResponse         CommandState
    Receive     Signal      DesiredStream           ReceivedResponse
));

my $autoload_re = qr/^$autoload$/;

sub new {
    my ($class, @nodes) = @_;

    my $self = {
        _nodes      => [],
        _attributes => [],
    };

    # List of class names supported by this node
    my $supported = $class->support() // {};

    foreach my $node (@nodes) {
        my $ref = ref($node);
        if ($ref eq 'Attribute') {
            push @{$self->{_attributes}}, $node;
        } elsif ($ref =~ $autoload_re) {
            push @{$self->{_nodes}}, $node;
        } else {
            push @{$self->{_raw}}, $node;
        }
    }

    if ($self->{_raw} && @{$self->{_raw}} % 2 == 0) {
        $self->{_hash} = { @{$self->{_raw}} };
        delete $self->{_raw};
        foreach my $key (keys(%{$self->{_hash}})) {
            if ($key =~ /^-(.+)$/) {
                my $value = delete $self->{_hash}->{$key};
                push @{$self->{_attributes}}, Attribute->new( $1 => $value );
            } else {
                foreach my $support (keys(%{$supported})) {
                    next unless $supported->{$support} eq $key;
                    my $node = delete $self->{_hash}->{$key};
                    push @{$self->{_nodes}}, $support->new( ref($node) eq 'HASH' ? %{$node} : $node );
                    last;
                }
            }
        }
    } elsif ($self->{_raw} && @{$self->{_raw}} == 1) {
        my $raw = delete $self->{_raw};
        $self->{_hash}->{'#text'} = shift @{$raw};
    }

    bless $self, $class;
    return $self;
}

sub namespace {
    my ($self) = @_;

    return "xmlns:".$self->xmlns() => $self->xsd();
}

sub set_namespace {
    my ($self) = @_;

    return if grep { /^xmlns:/ } map { keys(%{$_}) } @{$self->{_attributes}};

    $self->push( Attribute->new($self->namespace) );
}

sub reset_namespace {
    my ($self, @attributes) = @_;

    $self->{_attributes} = \@attributes;
}

sub support {}

sub values {}

sub get {
    my ($self, $leaf) = @_;

    if ($leaf) {
        return $self->{_hash}->{$leaf}
            if ($self->{_hash} && exists($self->{_hash}->{$leaf}));
        my $values = $self->values;
        if ($values && grep { $leaf eq $_ } @{$values}) {
            my $value = $self->xmlns.":".$leaf;
            return $self->{_hash}->{$value};
        }
        my $supported = $self->support;
        return unless $supported && $supported->{$leaf};
        my ($leafnode) = grep { ref($_) eq $leaf } @{$self->{_nodes}};
        return $leafnode;
    }

    my %nodes;
    foreach my $node (@{$self->{_attributes}}, @{$self->{_nodes}}) {
        my $insert = $node->get();
        if (ref($insert) eq 'HASH') {
            foreach my $key (keys(%{$insert})) {
                if ($nodes{$key}) {
                    $nodes{$key} = [ $nodes{$key} ]
                        unless ref($nodes{$key}) eq 'ARRAY';
                    push @{$nodes{$key}}, $insert->{$key};
                } else {
                    $nodes{$key} = $insert->{$key};
                }
            }
        } elsif (ref($insert) eq 'ARRAY') {
            while (@{$insert}) {
                my $key = shift @{$insert};
                my $value = shift @{$insert};
                if ($nodes{$key}) {
                    $nodes{$key} = [ $nodes{$key} ]
                        unless ref($nodes{$key}) eq 'ARRAY';
                    push @{$nodes{$key}}, $value;
                } else {
                    $nodes{$key} = $value;
                }
            }
        }
    }

    if ($self->{_hash}) {
        foreach my $key (keys(%{$self->{_hash}})) {
            if ($nodes{$key}) {
                $nodes{$key} = [ $nodes{$key} ]
                    unless ref($nodes{$key}) eq 'ARRAY';
                push @{$nodes{$key}}, $self->{_hash}->{$key};
            } else {
                $nodes{$key} = $self->{_hash}->{$key};
            }
        }
    }

    return { $self->xmlns.":".ref($self) => \%nodes };
}

sub delete {
    my ($self, $leaf) = @_;

    return unless $leaf && $self->{_hash} && exists($self->{_hash}->{$leaf});

    return delete $self->{_hash}->{$leaf};
}

sub nodes {
    my ($self, $filter) = @_;

    return grep { ref($_) eq $filter } @{$self->{_nodes}}
        if $filter;

    return @{$self->{_nodes}};
}

sub keys {
    my ($self) = @_;

    return keys(%{$self->{_hash}});
}

sub push {
    my ($self, @nodes) = @_;

    return unless @nodes;

    foreach my $node (@nodes) {
        if (ref($node) eq 'Attribute') {
            push @{$self->{_attributes}}, $node;
        } else {
            push @{$self->{_nodes}}, $node;
        }
    }
}

sub attributes {
    my ($self, $key) = @_;

    return map { $_->get($key) } @{$self->{_attributes}} if $key;

    return @{$self->{_attributes}};
}

sub string {
    my ($self, $string) = @_;

    return $self->{_hash}->{'#text'} = $string
        if $string;

    return $self->get('#text') // '';
}

sub reset {
    my ($self, @nodes) = @_;

    $self->{_nodes} = [];

    $self->push(@nodes);
}

1;
