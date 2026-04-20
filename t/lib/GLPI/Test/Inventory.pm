package GLPI::Test::Inventory;

use strict;
use warnings;
use parent qw(GLPI::Agent::Inventory);

use GLPI::Agent::Config;
use GLPI::Agent::Logger;

sub new {
    my ($class, %params) = @_;

    my $logger = GLPI::Agent::Logger->new(
        config => GLPI::Agent::Config->new(
            options => {
                config => 'none',
                debug  => 2,
                logger => 'Fatal'
            }
        )
    );

    # Tests should target glpi v11 support by default
    return $class->SUPER::new(
        glpi   => "11",
        logger => $logger
    );
}

1;
