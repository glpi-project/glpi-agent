package GLPI::Agent::IEC61850::Device;

use strict;
use warnings;

use UNIVERSAL::require;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use GLPI::Agent::IEC61850::Protocol;

use constant discovery => [ qw( SNMPHOSTNAME TYPE )];
use constant inventory => [ qw( INFO )];

my $discovery_infos = {
    FIRMWARE        => [ qw( PhyNam swRev    ) ],
    LOCATION        => [ qw( PhyNam location ) ],
    MODEL           => [ qw( PhyNam model    ) ],
    SERIAL          => [ qw( PhyNam serNum   ) ],
    MANUFACTURER    => [ qw( PhyNam vendor   ) ],
    CONTACT         => [ qw( PhyNam owner    ) ],
    DESCRIPTION     => [ qw( Description     ) ],
};

sub new {
    my ($class, %params) = @_;

    my $self = {
        logger  => $params{logger},
        timeout => $params{timeout} // 60,
    };

    bless $self, $class;

    return $self;
}

sub scan {
    my ($self, $ip, $port) = @_;

    my $protocol = GLPI::Agent::IEC61850::Protocol->new(
        timeout => $self->{timeout},
        logger  => $self->{logger},
    );

    $protocol->connect($ip, $port)
        or return;

    $protocol->scan();

    $protocol->disconnect();

    $self->{protocol} = $protocol;

    return $self->getDiscoveryInfo();
}

sub getDiscoveryInfo {
    my ($self) = @_;

    return unless $self->{protocol};

    my $info = {};

    # Filter out to only keep discovery infos
    foreach my $infokey (sort keys(%{$discovery_infos})) {
        my $request = $discovery_infos->{$infokey};
        my $value = getCanonicalString($self->{protocol}->getVariable(@{$request}));
        next if empty($value);
        $info->{$infokey} = $value;
    }

    # Set type
    $info->{TYPE} = "NETWORKING";

    return $info;
}

1;

__END__

=head1 NAME

GLPI::Agent::IEC61850::Device - GLPI Agent IEC61850 device

=head1 DESCRIPTION

Class to help handle general methods to apply on a IEC61850 device
