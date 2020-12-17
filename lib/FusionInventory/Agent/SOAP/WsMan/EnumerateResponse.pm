package FusionInventory::Agent::SOAP::WsMan::EnumerateResponse;

use strict;
use warnings;

use FusionInventory::Agent::SOAP::WsMan::Node;

BEGIN {
    # Needed for PullResponse class
    $INC{'EnumerateResponse.pm'} = __FILE__;
}

## no critic (ProhibitMultiplePackages)
package
    EnumerateResponse;

use parent 'Node';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::SOAP::WsMan::EnumerationContext;
use FusionInventory::Agent::SOAP::WsMan::Items;
use FusionInventory::Agent::SOAP::WsMan::EndOfSequence;

use constant    xmlns   => 'n';

sub new {
    my ($class, @enum) = @_;

    my $self = $class->SUPER::new(@enum);

    bless $self, $class;

    $self->push( EndOfSequence->new() ) unless @enum;

    return $self;
}

sub support {
    return {
        EnumerationContext  => "n:EnumerationContext",
        Items               => "w:Items",
        EndOfSequence       => "w:EndOfSequence",
    };
}

sub items {
    my ($self) = @_;

    my @items;
    foreach my $items ($self->nodes("Items")) {
        foreach my $key ($items->keys()) {
            my $item = $items->get($key)
                or next;
            push @items, _normalize(ref($item) eq 'ARRAY' ? @{$item} : $item);
        }
    }

    return @items;
}

sub end_of_sequence {
    my ($self) = @_;

    return first { ref($_) eq "EndOfSequence" } $self->nodes();
}

sub _normalize {
    my @normalized = ();

    foreach my $hash (@_) {
        my $normalized = {};
        foreach my $key (keys(%{$hash})) {
            next unless $key =~ /^p:(.*)$/;
            my $value = $hash->{$key};
            $value = $value->{'-xsi:nil'} if ref($value) eq 'HASH' && $value->{'-xsi:nil'};
            $normalized->{$1} = $value;
        }
        push @normalized, $normalized;
    }

    return @normalized;
}

sub context {
    my ($self) = @_;

    my ($context) = $self->get('EnumerationContext');

    $context->set_namespace() if $context;

    return $context // EnumerationContext->new();
}

1;
