package GLPI::Agent::SNMP::Device::Components;

use strict;
use warnings;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See ENTITY-MIB
use constant
    entPhysicalEntry    => '.1.3.6.1.2.1.47.1.1.1.1';

# components interface variables
my %physical_components_variables = (
    INDEX            => { # entPhysicalIndex
        suffix  => '1',
        type    => 'constant'
    },
    NAME             => { # entPhysicalName
        suffix  => '7',
        type    => 'string'
    },
    DESCRIPTION      => { # entPhysicalDescr
        suffix  => '2',
        type    => 'string'
    },
    SERIAL           => { # entPhysicalSerialNum
        suffix  => '11',
        type    => 'string'
    },
    MODEL            => { # entPhysicalModelName
        suffix  => '13',
        type    => 'string'
    },
    TYPE             => { # entPhysicalClass
        suffix  => '5',
        type => 'type',
        types => {
           'other(1)'       => 'other',
           1                => 'other',
           'unknown(2)'     => 'unknown',
           2                => 'unknown',
           'chassis(3)'     => 'chassis',
           3                => 'chassis',
           'backplane(4)'   => 'backplane',
           4                => 'backplane',
           'container(5)'   => 'container',
           5                => 'container',
           'powerSupply(6)' => 'powerSupply',
           6                => 'powerSupply',
           'fan(7)'         => 'fan',
           7                => 'fan',
           'sensor(8)'      => 'sensor',
           8                => 'sensor',
           'module(9)'      => 'module',
           9                => 'module',
           'port(10)'       => 'port',
           10               => 'port',
           'stack(11)'      => 'stack',
           11               => 'stack',
           'cpu(12)'        => 'cpu',
           12               => 'cpu'
        }
    },
    FRU              => { # entPhysicalIsFRU
        suffix  => '16',
        type    => 'constant'
    },
    MANUFACTURER     => { # entPhysicalMfgName
        suffix  => '12',
        type    => 'string'
    },
    FIRMWARE         => { # entPhysicalFirmwareRev
        suffix  => '9',
        type    => 'string'
    },
    REVISION         => { # entPhysicalHardwareRev
        suffix  => '8',
        type    => 'string'
    },
    VERSION          => { # entPhysicalSoftwareRev
        suffix  => '10',
        type    => 'string'
    },
    CONTAINEDININDEX => { # entPhysicalContainedIn
        suffix  => '4',
        type    => 'constant'
    },
    MAC => {
        type => 'mac'
    },
    IP => {
        type => 'string'
    },
);

sub new {
    my ($class, %params) = @_;

    my $device = $params{device};

    return unless $device;

    my $self = {
        device      => $device,
        _components => [],
    };

    # First walk all entPhysicalEntry entries
    my $walk = $device->walk(entPhysicalEntry)
        or return;
    return unless keys(%{$walk});

    # Parse suffixes to only keep what we really need from the walk
    my %supported = ();
    foreach my $key (keys(%physical_components_variables)) {
        next unless $physical_components_variables{$key}->{suffix};
        $supported{$physical_components_variables{$key}->{suffix}} = $key;
    }
    my $supported = join('|',sort { $a <=> $b } keys(%supported));
    my $supported_re = qr/^($supported)\.(.*)$/;
    my %walks = ();
    foreach my $oidleaf (keys(%{$walk})) {
        my ( $node, $suffix ) = $oidleaf =~ $supported_re;
        next unless defined $node && defined $suffix;
        $walks{$supported{$node}}->{$suffix} = $walk->{$oidleaf};
    }

    # No instanciation if no indexed component found by INDEX or based on NAME
    my @indexes;
    if ($walks{INDEX}) {
        # Trust INDEX table when present
        @indexes = values(%{$walks{INDEX}});
    } else {
        # Found the most populated info and use related suffixes as index table
        my %counts = map { $_ => scalar(keys(%{$walks{$_}})) } keys(%walks);
        my @larger = sort { $counts{$a} <=> $counts{$b} } keys(%walks);
        my $larger = pop @larger;
        @indexes = keys(%{$walks{$larger}});
    }
    return unless @indexes;

    @indexes = sort { $a <=> $b } @indexes;

    # Checking MAC & IP are for now only supported for Cisco based devices
    my $mac_indexes = $device->walk('.1.3.6.1.4.1.9.9.513.1.1.1.1.4');
    if ($mac_indexes) {
        # Get MAC addresses
        my $macaddresses = $device->walk('.1.3.6.1.4.1.9.9.513.1.1.1.1.2')
            || {};
        # Get IP addresses
        my $ipaddresses = $device->walk('.1.3.6.1.4.1.14179.2.2.1.1.19')
            || {};

        # Populate MAC & IP addresses
        while (my ($suffix, $index) = each %{$mac_indexes}) {
            $walks{MAC}->{$index} = $macaddresses->{$suffix}
                if $macaddresses->{$suffix};
            $walks{IP}->{$index} = $ipaddresses->{$suffix}
                if $ipaddresses->{$suffix};
        }
    }

    # Initialize _components array
    foreach my $index (@indexes) {
        push @{$self->{_components}}, {
            INDEX => getCanonicalConstant($walks{INDEX}->{$index} || $index)
        };
    };

    $self->{_indexes} = \@indexes;
    $self->{_walks}   = \%walks;

    bless $self, $class;

    return $self;
}

sub getPhysicalComponents {
    my ($self) = @_;

    # INDEX was still computed during object creation
    my @keys = sort grep { $_ ne 'INDEX' } keys(%physical_components_variables);

    my $i = 0;
    my $count = @{$self->{_indexes}};

    # Populate all components
    while ($i < $count) {
        my $component = $self->{_components}->[$i];
        my $index     = $self->{_indexes}->[$i++];

        foreach my $key (@keys) {
            my $variable  = $physical_components_variables{$key};
            my $type      = $variable->{type} || '';
            my $raw_value = $self->{_walks}->{$key}->{$index};
            next unless defined $raw_value;
            my $value =
                $type eq 'type'     ? $variable->{types}->{$raw_value}   :
                $type eq 'mac'      ? getCanonicalMacAddress($raw_value) :
                $type eq 'constant' ? getCanonicalConstant($raw_value)   :
                $type eq 'string'   ? getCanonicalString(trimWhitespace($raw_value)) :
                $type eq 'count'    ? getCanonicalCount($raw_value)      :
                                      $raw_value;
            $component->{$key} = $value
                if defined($value) && length($value);
        }
    }

    return $self->{_components};
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::Device::Components - GLPI agent SNMP device components

=head1 DESCRIPTION

Class to help handle components method for snmp device inventory

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item device (mandatory)  Device related object

=back
