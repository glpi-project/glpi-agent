package FusionInventory::Agent::SOAP::WsMan::Attribute;

use strict;
use warnings;

package
    Attribute;

sub new {
    my ($class, %params) = @_;

    my $self = {
        _attribute  => {
            %params,
        }
    };

    bless $self, $class;
    return $self;
}

sub get {
    my ($self, $key) = @_;

    return $self->{_attribute}->{$key} if $key;

    my @attributes;

    foreach my $name (sort keys(%{$self->{_attribute}})) {
        push @attributes, "-$name", $self->{_attribute}->{$name};
    }

    return @attributes;
}

1;
