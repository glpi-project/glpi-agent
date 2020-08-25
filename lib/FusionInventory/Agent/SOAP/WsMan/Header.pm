package FusionInventory::Agent::SOAP::WsMan::Header;

use strict;
use warnings;

package
    Header;

sub new {
    my ($class, @headers) = @_;

    my $self = {
        _header => [ @headers ],
    };

    bless $self, $class;
    return $self;
}

sub get {
    my ($self) = @_;

    return "s:Header" => { map { $_->get() } @{$self->{_header}} };
}

1;
