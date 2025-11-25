package GLPI::Agent::IEC61850::Device;

use strict;
use warnings;

use UNIVERSAL::require;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use GLPI::Agent::IEC61850::Protocol;

my $infos = {
    FIRMWARE        => [ qw( PhyNam swRev    ) ],
    LOCATION        => [ qw( PhyNam location ) ],
    MODEL           => [ qw( PhyNam model    ) ],
    SERIAL          => [ qw( PhyNam serNum   ) ],
    MANUFACTURER    => [ qw( PhyNam vendor   ) ],
    CONTACT         => [ qw( PhyNam owner    ) ],
    IEDNAME         => [ qw( Name            ) ],
    HARDWARE        => [ qw( PhyNam hwRev    ) ],
};

sub new {
    my ($class, %params) = @_;

    my $self = {
        logger  => $params{logger},
        glpi    => $params{glpi}    // '',
        timeout => $params{timeout} // 60,
        infos   => {
            TYPE    => "NETWORKING",
        },
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

    # Filter out to only keep discovery infos
    foreach my $infokey (sort keys(%{$infos})) {
        my $request = $infos->{$infokey};
        my $value = getCanonicalString($protocol->getVariable(@{$request}));
        next if empty($value);
        $self->{infos}->{$infokey} = $value;
    }

    # Set itemtype depending on server version or glpi-version option
    my $glpi_version = $self->{glpi} ? glpiVersion($self->{glpi}) : 0;
    if ($glpi_version && $glpi_version >= glpiVersion('11')) {
        # Set ITEMTYPE to IED
        $self->{infos}->{ITEMTYPE} = "Glpi\\CustomAsset\\IedAsset";
    }

    # Keep hardware version for complete inventory
    $self->{hardware} = delete $self->{infos}->{HARDWARE};

    return $self->{infos};
}

sub inventory {
    my ($self, $result) = @_;

    $self->{infos}->{MAC} = $result->{MAC}
        if $result->{MAC};

    if ($self->{infos}->{IEDNAME}) {
        my $name = delete $self->{infos}->{IEDNAME};

        # Cleanup name from manufacturer related suffix
        map {
            $name =~ s/$_//;
        } (
            qr/A_Allg$/, # Suffix seen on logical device name Siemens devices
        );

        $self->{infos}->{NAME} = $name;
    }

    if ($result->{IP}) {
        $self->{infos}->{IPS} = {
            IP  => $result->{IP},
        };
    }

    my @firmwares = (
        {
            NAME            => ($self->{infos}->{MODEL} || 'Electronic device')." firmware",
            DESCRIPTION     => 'Electronic device firmware',
            TYPE            => 'ied',
            VERSION         => $self->{infos}->{FIRMWARE},
            MANUFACTURER    => $self->{infos}->{MANUFACTURER}
        }
    );

    if ($self->{hardware}) {
        push @firmwares, {
            NAME            => ($self->{infos}->{MODEL} || 'Electronic device')." hardware",
            DESCRIPTION     => 'Electronic device hardware',
            TYPE            => 'ied',
            VERSION         => $self->{hardware},
            MANUFACTURER    => $self->{infos}->{MANUFACTURER}
        };
    }

    my $itemtype = delete $self->{infos}->{ITEMTYPE};

    my $inventory = {
        INFO        => $self->{infos},
        ITEMTYPE    => $itemtype,
        FIRMWARES   => \@firmwares,
    };

    return $inventory;
}

1;

__END__

=head1 NAME

GLPI::Agent::IEC61850::Device - GLPI Agent IEC61850 device

=head1 DESCRIPTION

Class to help handle general methods to apply on a IEC61850 device
