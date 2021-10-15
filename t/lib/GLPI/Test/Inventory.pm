package FusionInventory::Test::Inventory;

use strict;
use warnings;
use parent qw(FusionInventory::Agent::Inventory);

use FusionInventory::Agent::Config;
use FusionInventory::Agent::Logger;

sub new {
    my ($class, %params) = @_;

    my $logger = FusionInventory::Agent::Logger->new(
        config => FusionInventory::Agent::Config->new(
            options => {
                config => 'none',
                debug  => 2,
                logger => 'Fatal'
            }
        )
    );

    return $class->SUPER::new(logger => $logger);
}

1;
