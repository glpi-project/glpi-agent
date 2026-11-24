package GLPI::Agent::Event::Partial;

use strict;
use warnings;

use parent qw(GLPI::Agent::Event);

use GLPI::Agent::Tools;

use constant priority       => 40;

use constant partial        => 1;
use constant name           => "partial inventory";
use constant task           => "inventory";

# A "partial" inventory event can be requested on agent httpd server
use constant httpd_support  => 1;

sub new {
    my ($class, %params) = @_;

    # "partial" inventory event:
    #  - can be trigerred by /now http requests
    #  - can be requested by glpi-inventory run via --partial parameter

    return if empty($params{partial}) || $params{partial} !~ /^yes|1$/i;

    # Partial inventory request on given categories
    my $self = {
        _category => $params{category} // "",
    };

    # Store any other params (can be used by database partial inventory requests)
    foreach my $key (grep { $_ !~ /^partial$/i } keys(%params)) {
        $self->{_params}->{$key} = $params{$key} // "";
    }

    return bless $self, $class;
}

# Event attributes

sub category {
    my ($self) = @_;
    return $self->{_category} // "";
}

1;
