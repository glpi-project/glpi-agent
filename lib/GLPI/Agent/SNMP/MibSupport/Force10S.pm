package GLPI::Agent::SNMP::MibSupport::Force10S;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant Force10S => '.1.3.6.1.4.1.6027.1.3' ;

our $mibSupport = [
    {
        name        => "Force10 S-series",
        sysobjectid => getRegexpOidMatch(Force10S)
    }
];

# See F10-S-SERIES-CHASSIS-MIB
use constant
    chStackUnitEntry => '.1.3.6.1.4.1.6027.3.10.1.2.2.1';

use constant
    chSysPortIfIndex => '.1.3.6.1.4.1.6027.3.10.1.2.5.1.5';

# components interface variables
my %physical_components_variables = (
    INDEX            => { # chStackUnitNumber
        suffix  => '2',
        type    => 'integer'
    },
    MODEL            => { # chStackUnitModelID
        suffix  => '7',
        type    => 'string'
    },
    DESCRIPTION      => { # chStackUnitDescription
        suffix  => '9',
        type    => 'string'
    },
    FIRMWARE         => { # chStackUnitCodeVersion
        suffix  => '10',
        type    => 'string'
    },
    SERIAL           => { # chStackUnitSerialNumber
        suffix  => '12',
        type    => 'string'
    },
    REVISION         => { # chStackUnitProductRev
        suffix  => '21',
        type    => 'string'
    },
);


sub getComponents {
    my ($self) = @_;

    my @components;

    my $stack_components = $self->_get_stack_units();
    my $ports_components = $self->_get_ports();
    push @components, @{$stack_components} if $stack_components;
    push @components, @{$ports_components} if $ports_components;

    # adding root unit
    if (scalar @components) {
        push @components, {
            CONTAINEDININDEX => '0',
            INDEX            => '-1',
            TYPE             => 'stack',
            NAME             => 'Force10 S-series Stack'
        };
    }

    return \@components;
}

sub _get_ports {
    my ($self) = @_;

    my $walk = $self->walk(chSysPortIfIndex)
        or return;
    return unless keys %$walk;

    my @ports;
    while (my ($suffix, $ifIndex) = each %$walk) {
        my $stack_id = _getElement($suffix, -2);
        next unless defined $stack_id;

        push @ports, {
            INDEX            => $ifIndex,
            CONTAINEDININDEX => $stack_id,
            TYPE             => 'port'
        };
    }

    return \@ports;
}

sub _get_stack_units {
    my ($self) = @_;

    my $walk = $self->walk(chStackUnitEntry)
        or return;
    return unless keys %$walk;

    # Parse suffixes to only keep what we really need from the walk
    my %supported = ();
    foreach my $key (keys %physical_components_variables) {
        next unless $physical_components_variables{$key}->{suffix};
        $supported{$physical_components_variables{$key}->{suffix}} = $key;
    }
    my $supported = join '|', sort { $a <=> $b } keys %supported;
    my $supported_re = qr/^($supported)\.(.*)$/;
    my %walks = ();
    foreach my $oidleaf (keys %$walk) {
        my ($node, $suffix) = $oidleaf =~ $supported_re;
        next unless defined $node && defined $suffix;
        $walks{$supported{$node}}->{$suffix} = $walk->{$oidleaf};
    }

    my @indexes = values %{$walks{INDEX}};
    return unless @indexes;

    @indexes = sort { $a <=> $b } @indexes;

    # Initialize components array
    my @components;
    foreach my $index (@indexes) {
        my $idx = getCanonicalConstant($walks{INDEX}->{$index} || $index);
        push @components, {
            INDEX            => $idx,
            # minimal chassis number in an interface name is zero, e.g. Gi0/1
            NAME             => $idx - 1,
            CONTAINEDININDEX => '-1',
            TYPE             => 'chassis',
        };
    };

    my @keys = sort grep {$_ ne 'INDEX'} keys %physical_components_variables;

    # Populate all components
    my $i = 0;
    while ($i < scalar @indexes) {
        my $component = $components[$i];
        my $index     = $indexes[$i++];

        foreach my $key (@keys) {
            my $variable  = $physical_components_variables{$key};
            my $type      = $variable->{type} || '';
            my $raw_value = $walks{$key}->{$index};
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

    return \@components;
}

sub _getElement {
    my ($oid, $index) = @_;

    my @array = split(/\./, $oid);
    return $array[$index];
}

1;

__END__
