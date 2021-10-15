package GLPI::Agent::SOAP::WsMan::Attribute;

use strict;
use warnings;

## no critic (ProhibitMultiplePackages)
package
    Attribute;

sub new {
    my ($class, %params) = @_;

    my $self = \%params;

    bless $self, $class;
    return $self;
}

sub get {
    my ($self, $key) = @_;

    return $self->{$key} if $key;

    my @attributes;
    foreach my $key (keys(%{$self})) {
        push @attributes, "-$key", $self->{$key};
    }

    return \@attributes;
}

sub must_understand {
    my ($class, $bool) = @_;

    return $class->new("s:mustUnderstand" => $bool // "true");
}

1;
