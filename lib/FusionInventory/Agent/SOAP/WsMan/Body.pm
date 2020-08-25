package FusionInventory::Agent::SOAP::WsMan::Body;

use strict;
use warnings;

package
    Body;

sub new {
    my ($class, %params) = @_;

    my $self = {
        _body => {
            %params,
        }
    };

    bless $self, $class;
    return $self;
}

sub get {
    my ($self) = @_;

    my @bodies;

    foreach my $body (keys(%{$self->{_body}})) {
        push @bodies, "$body", $self->{_body}->{$body};
    }

    return "s:Body" => { @bodies };
}

1;
