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
        foreach my $item ($items->nodes()) {
            push @items, _dump($item);
        }
    }

    return @items;
}

sub end_of_sequence {
    my ($self) = @_;

    return first { ref($_) eq "EndOfSequence" } $self->nodes();
}

sub _dump {
    my @dump = ();

    foreach my $object (@_) {
        my $dump = {};
        foreach my $node ($object->nodes()) {
            my $key = ref($node);
            my $nil = $node->attribute('xsi:nil');
            my @nodes = $node->nodes();
            if ($nil && $nil eq 'true') {
                $dump->{$key} = undef;
            } elsif ($node->attribute('xsi:type')) {
                push @dump, _dump($node);
                undef $dump;
            } else {
                $dump->{$key} = @nodes > 1 ? [ map { $_->string } @nodes ] : $node->string;
            }
        }
        push @dump, $dump if $dump;
    }

    return @dump;
}

sub context {
    my ($self) = @_;

    my ($context) = $self->get('EnumerationContext');

    $context->set_namespace() if $context;

    return $context // EnumerationContext->new();
}

1;
