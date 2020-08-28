package FusionInventory::Agent::SOAP::WsMan::Node;

use strict;
use warnings;

BEGIN {
    $INC{'Node.pm'} = __FILE__;
}

package
    Node;

use FusionInventory::Agent::SOAP::WsMan::Attribute;

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
        } elsif ($ref =~ /^Body|Header$/) {
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
    }

    bless $self, $class;
    return $self;
}

sub support {}

sub get {
    my ($self, $leaf) = @_;

    if ($leaf) {
        return $self->{_hash}->{$leaf}
            if ($self->{_hash} && exists($self->{_hash}->{$leaf}));
        my ($leafnode) = grep { ref($_) eq $leaf } @{$self->{_nodes}};
        return $leafnode;
    }

    my @nodes = map { $_->get() } @{$self->{_attributes}};
    push @nodes, map { $_->get() } @{$self->{_nodes}};

    push @nodes, @{$self->{_hash}} if $self->{_has_hash};

    return { @nodes };
}

sub nodes {
    my ($self) = @_;

    return @{$self->{_nodes}};
}

sub attributes {
    my ($self, $key) = @_;

    return map { $_->get($key) } @{$self->{_attributes}} if $key;

    return @{$self->{_attributes}};
}

1;
