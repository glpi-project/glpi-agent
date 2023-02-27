package GLPI::Agent::SNMP::Device;

use strict;
use warnings;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;
use GLPI::Agent::Tools::Network;
use GLPI::Agent::SNMP::MibSupport;
use GLPI::Agent::SNMP::Device::Components;

# Supported infos are specified here:
# http://fusioninventory.org/documentation/dev/spec/protocol/netdiscovery.html
use constant discovery => [ qw(
        DESCRIPTION FIRMWARE ID IPS LOCATION MAC MEMORY MODEL SNMPHOSTNAME TYPE
        SERIAL UPTIME MANUFACTURER CONTACT AUTHSNMP
    )];
# http://fusioninventory.org/documentation/dev/spec/protocol/netinventory.html
# STORAGES is specified in inventory.schema.json and can be used to inventory SAN disks
use constant inventory => [ qw(
        INFO PORTS MODEMS FIRMWARES SIMCARDS PAGECOUNTERS CARTRIDGES COMPONENTS STORAGES
    )];

# common base variables
my $base_variables = {
    SNMPHOSTNAME => {
        oid  => [
            '.1.3.6.1.2.1.1.5.0',
            '.1.3.6.1.4.1.2699.1.2.1.2.1.1.2.1', # PRINTER-PORT-MONITOR-MIB, ppmPrinterName
        ],
        type => 'string',
    },
    LOCATION     => {
        oid  => '.1.3.6.1.2.1.1.6.0',
        type => 'string',
    },
    CONTACT      => {
        oid  => '.1.3.6.1.2.1.1.4.0',
        type => 'string',
    },
    UPTIME       => {
        oid  => '.1.3.6.1.2.1.1.3.0',
        type => 'string',
    },
};

# common base variables for inventory only
my $inventory_only_base_variables = {
    CPU          => {
        oid  => [
            '.1.3.6.1.4.1.9.9.109.1.1.1.1.6.1',
            '.1.3.6.1.4.1.9.9.109.1.1.1.1.3.1',
        ],
        type => 'count',
    },
    MEMORY       => {
        oid  => '.1.3.6.1.2.1.25.2.3.1.5.1',
        type => 'memory',
    },
    RAM          => {
        oid  => {
            '.1.3.6.1.4.1.2021.4.5'     => 'kb',
            '.1.3.6.1.4.1.9.3.6.6.0'    => 'bytes',
            '.1.3.6.1.2.1.25.2.2.0'     => 'kb',
        },
        type => 'memory',
    },
};

sub new {
    my ($class, %params) = @_;

    my $snmp   = $params{snmp};
    my $logger = $params{logger};

    return unless $snmp;

    my $self = {
        snmp   => $snmp,
        logger => $logger
    };

    bless $self, $class;

    return $self;
}

sub get {
    my ($self, $oid) = @_;

    return unless $self->{snmp} && $oid;

    return $self->{snmp}->get($oid);
}

sub walk {
    my ($self, $oid) = @_;

    return unless $self->{snmp} && $oid;

    return $self->{snmp}->walk($oid);
}

sub loadMibSupport {
    my ($self, $sysobjectid, $config) = @_;

    # list supported mibs regarding sysORID list as this list permits to
    # identify device supported MIBs
    $self->{MIBSUPPORT} = GLPI::Agent::SNMP::MibSupport->new(
        sysobjectid => $sysobjectid,
        device      => $self,
        config      => $config, # Required for ConfigurationPlugin module
        logger      => $self->{logger}
    );
}

sub runMibSupport {
    my ($self) = @_;

    return unless $self->{MIBSUPPORT};

    $self->{MIBSUPPORT}->run();
}

sub getSerialByMibSupport {
    my ($self) = @_;

    return unless $self->{MIBSUPPORT};

    return $self->{MIBSUPPORT}->getMethod('getSerial');
}

sub getFirmwareByMibSupport {
    my ($self) = @_;

    return unless $self->{MIBSUPPORT};

    return $self->{MIBSUPPORT}->getMethod('getFirmware');
}

sub getFirmwareDateByMibSupport {
    my ($self) = @_;

    return unless $self->{MIBSUPPORT};

    return $self->{MIBSUPPORT}->getMethod('getFirmwareDate');
}

sub getMacAddressByMibSupport {
    my ($self) = @_;

    return unless $self->{MIBSUPPORT};

    return $self->{MIBSUPPORT}->getMethod('getMacAddress');
}

sub getIpByMibSupport {
    my ($self) = @_;

    return unless $self->{MIBSUPPORT};

    return $self->{MIBSUPPORT}->getMethod('getIp');
}

sub getDiscoveryInfo {
    my ($self) = @_;

    my $info = {};

    # Filter out to only keep discovery infos
    my $infos = discovery;
    foreach my $infokey (@{$infos}) {
        $info->{$infokey} = $self->{$infokey}
            if exists($self->{$infokey});
    }

    return $info;
}

sub getInventory {
    my ($self) = @_;

    my $inventory = {};

    # Filter out to only keep inventory infos
    my $infos = inventory;
    foreach my $infokey (@{$infos}) {
        $inventory->{$infokey} = $self->{$infokey}
            if exists($self->{$infokey});
    }

    return $inventory;
}

sub addComponent {
    my ($self, $component) = @_;

    return unless _cleanHash($component);

    push @{$self->{COMPONENTS}->{COMPONENT}}, $component;
}

sub addModem {
    my ($self, $modem) = @_;

    return unless _cleanHash($modem);

    push @{$self->{MODEMS}}, $modem;
}

sub addFirmware {
    my ($self, $firmware) = @_;

    return unless _cleanHash($firmware);

    push @{$self->{FIRMWARES}}, $firmware;
}

sub addSimcard {
    my ($self, $simcard) = @_;

    return unless _cleanHash($simcard);

    push @{$self->{SIMCARDS}}, $simcard;
}

sub addPort {
    my ($self, %ports) = @_;

    foreach my $port (keys(%ports)) {
        next unless _cleanHash($ports{$port});

        $self->{PORTS}->{PORT}->{$port} = $ports{$port};
    }
}

sub _cleanHash {
    my ($hashref) = @_;

    return unless ref($hashref) eq 'HASH';

    my $keys = 0 ;
    foreach my $key (keys(%{$hashref})) {
        $keys++;
        next if defined($hashref->{$key});
        delete $hashref->{$key};
        $keys--;
    }

    return $keys;
}

sub setSerial {
    my ($self) = @_;

    my $serial =
        # First try MIB Support mechanism
        $self->getSerialByMibSupport()                         ||
        # Entity-MIB::entPhysicalSerialNum
        $self->{snmp}->get_first('.1.3.6.1.2.1.47.1.1.1.1.11') ||
        # Printer-MIB::prtGeneralSerialNumber
        $self->{snmp}->get_first('.1.3.6.1.2.1.43.5.1.1.17');

    if ( not defined $serial ) {
        # vendor specific OIDs
        my @oids = (
            '.1.3.6.1.4.1.2636.3.1.3.0',             # Juniper-MIB
            '.1.3.6.1.4.1.248.14.1.1.9.1.10.1',      # Hirschman MIB
            '.1.3.6.1.4.1.253.8.53.3.2.1.3.1',       # Xerox-MIB
            '.1.3.6.1.4.1.367.3.2.1.2.1.4.0',        # Ricoh-MIB
            '.1.3.6.1.4.1.641.2.1.2.1.6.1',          # Lexmark-MIB
            '.1.3.6.1.4.1.1602.1.2.1.4.0',           # Canon-MIB
            '.1.3.6.1.4.1.2435.2.3.9.4.2.1.5.5.1.0', # Brother-MIB
            '.1.3.6.1.4.1.318.1.1.4.1.5.0',          # MasterSwitch-MIB
            '.1.3.6.1.4.1.6027.3.8.1.1.5.0',         # F10-C-SERIES-CHASSIS-MIB
            '.1.3.6.1.4.1.6027.3.10.1.2.2.1.12.1',   # FORCE10-SMI
            '.1.3.6.1.4.1.3417.2.11.1.4.0',          # BLUECOAT-SG-PROXY-MIB
            '.1.3.6.1.4.1.232.2.2.2.1.0',            # CPQSINFO-MIB
            '.1.3.6.1.4.1.232.11.2.10.3.0',          # CPQHOST-MIB
            '.1.3.6.1.4.1.14823.2.3.3.1.2.1.1.4.144.76.129.206.143.6', # ARUBA-MIB
        );
        foreach my $oid (@oids) {
            $serial = $self->get($oid);
            last if $serial;
        }
    }

    $serial = getCanonicalSerialNumber($serial);

    return unless $serial;

    # Skip well-known invalid serial number
    return if $serial =~ /^X+$/;

    $self->{SERIAL} = $serial;
}

sub setFirmware {
    my ($self) = @_;

    my $firmware =
        # First try to get firmware from MIB Support mechanism
        $self->getFirmwareByMibSupport()                       ||
        # entPhysicalSoftwareRev
        $self->{snmp}->get_first('.1.3.6.1.2.1.47.1.1.1.1.10') ||
        # entPhysicalFirmwareRev
        $self->{snmp}->get_first('.1.3.6.1.2.1.47.1.1.1.1.9');

    if ( not defined $firmware ) {
        # vendor specific OIDs
        my @oids = (
            '.1.3.6.1.4.1.9.9.25.1.1.1.2.5',         # Cisco / IOS
            '.1.3.6.1.4.1.248.14.1.1.2.0',           # Hirschman MIB
            '.1.3.6.1.4.1.2636.3.40.1.4.1.1.1.5.0',  # Juniper-MIB
        );
        foreach my $oid (@oids) {
            $firmware = $self->get($oid);
            last if defined $firmware;
        }
        return unless defined $firmware;
    }

    $firmware = getCanonicalString($firmware);

    return unless $firmware;

    # Set device firmware
    $self->{FIRMWARE} = $firmware;

    # Also add firmware as device FIRMWARES
    $self->addFirmware({
        NAME            => $self->{MODEL} || 'device',
        DESCRIPTION     => 'device firmware',
        TYPE            => 'device',
        DATE            => $self->getFirmwareDateByMibSupport(),
        VERSION         => $self->{FIRMWARE},
        MANUFACTURER    => $self->{MANUFACTURER}
    });
}

sub setMacAddress {
    my ($self) = @_;

    my $address_oid = ".1.3.6.1.2.1.17.1.1.0";
    my $address = getCanonicalMacAddress(
        # use BRIDGE-MIB::dot1dBaseBridgeAddress if available
        $self->get($address_oid) ||
        # Try MIB Support mechanism
        $self->getMacAddressByMibSupport()
    );

    return $self->{MAC} = $address
        if $address && $address =~ /^$mac_address_pattern$/;

    # fallback on ports addresses (IF-MIB::ifPhysAddress) if unique
    my $addresses_oid = ".1.3.6.1.2.1.2.2.1.6";
    my $addresses = $self->walk($addresses_oid);

    # interfaces list with defined ip to use as filter to select shorter mac address list
    my $ips = $self->walk('.1.3.6.1.2.1.4.20.1.2');

    # If peer adress is known, get mac from it
    my $peer = $self->{snmp}->peer_address();
    if ($peer && $ips->{$peer} && $addresses->{$ips->{$peer}}) {
        $address = getCanonicalMacAddress($addresses->{$ips->{$peer}});
        return $self->{MAC} = $address
            if $address && $address =~ /^$mac_address_pattern$/;
    }

    my @all_mac_addresses = ();

    # Try first to obtain shorter mac address list using ip interface list filter
    @all_mac_addresses = grep { defined } map { $addresses->{$_} } values %{$ips}
        if (keys(%{$ips}));

    # Finally get all defined mac adresses if ip filtered related list remains empty
    @all_mac_addresses = grep { defined } values %{$addresses}
        unless @all_mac_addresses;

    my @valid_mac_addresses =
        uniq
        grep { /^$mac_address_pattern$/ }
        grep { $_ ne '00:00:00:00:00:00' }
        grep { $_ }
        map  { getCanonicalMacAddress($_) }
        @all_mac_addresses;

    if (@valid_mac_addresses) {
        return $self->{MAC} = $valid_mac_addresses[0]
            if @valid_mac_addresses == 1;

        # Compute mac addresses as number and sort them
        my %macs = map { $_ => _numericMac($_) } @valid_mac_addresses;
        my @sortedMac = sort { $macs{$a} <=> $macs{$b} } @valid_mac_addresses;

        # Then find first couple of consecutive mac and return first one as this
        # seems to be the first manufacturer defined mac address
        while (@sortedMac > 1) {
            my $currentMac = shift @sortedMac;
            return $self->{MAC} = $currentMac
                if ($macs{$currentMac} == $macs{$sortedMac[0]} - 1);
        }

        # Finally try to set mac from the first interface having speed set
        # On printer with ethernet port & wifi port, speed is not set if wifi is not configured
        my $ifSpeed = $self->walk(".1.3.6.1.2.1.2.2.1.5");
        foreach my $index (sort { $a <=> $b } keys(%{$ifSpeed})) {
            next unless $ifSpeed->{$index};
            my $currentMac = getCanonicalMacAddress($addresses->{$index})
                or next;
            next unless first { $_ eq $currentMac } @valid_mac_addresses;
            return $self->{MAC} = $currentMac;
        }
    }
}

# rules on model name to reset manufacturer to real vendor
my %sysmodel_first_word = (
    'dell'           => { manufacturer => 'Dell', },
);

sub setModel {
    my ($self) = @_;

    # fallback model identification attempt, using type-specific OID value
    if (!exists $self->{MODEL}) {
        my $model = exists $self->{TYPE} && $self->{TYPE} eq 'PRINTER' ?
            $self->get('.1.3.6.1.2.1.25.3.2.1.3.1')    :
            exists $self->{TYPE} && $self->{TYPE} eq 'POWER' ?
            $self->get('.1.3.6.1.2.1.33.1.1.5.0')      : # UPS-MIB
            $self->get('.1.3.6.1.2.1.47.1.1.1.1.13.1') ;
        $self->{MODEL} = getCanonicalString($model) if $model;
    }

    # fallback manufacturer identification attempt, using type-agnostic OID
    if (!exists $self->{MANUFACTURER}) {
        my $manufacturer = $self->get('.1.3.6.1.2.1.43.8.2.1.14.1.1');
        $self->{MANUFACTURER} = $manufacturer if $manufacturer;
    }

    # reset manufacturer by rule as real vendor based on first model word
    if (exists $self->{MODEL}) {
        my ($first_word) = $self->{MODEL} =~ /(\S+)/;
        my $result = $sysmodel_first_word{lc($first_word)};
        if ($result && $result->{manufacturer}) {
            $self->{MANUFACTURER} = $result->{manufacturer};
        }
    }

    # Permit mib support to reset model
    if ($self->{MIBSUPPORT}) {
        my $model = $self->{MIBSUPPORT}->getMethod('getModel');
        $self->{MODEL} = getCanonicalString($model) if $model;
    }
}

sub setType {
    my ($self) = @_;

    # Permit mib support to reset type
    if ($self->{MIBSUPPORT}) {
        my $type = $self->{MIBSUPPORT}->getMethod('getType');
        $self->{TYPE} = $type if $type;
    }
}

sub setManufacturer {
    my ($self) = @_;

    # Permit mib support to reset manufacturer
    if ($self->{MIBSUPPORT}) {
        my $manufacturer = $self->{MIBSUPPORT}->getMethod('getManufacturer');
        $self->{MANUFACTURER} = $manufacturer if $manufacturer;
    }
}

sub setBaseInfos {
    my ($self) = @_;
    $self->_set_from_oid_list($base_variables, $self);

    # Filter out LOCATION & CONTACT from unwanted values
    if ($self->{LOCATION} && $self->{LOCATION} =~ /edit \/etc.*snmp.*\.conf/) {
        delete $self->{LOCATION};
    }
    if ($self->{CONTACT} && $self->{CONTACT} =~ /configure \/etc.*snmp.*\.conf/) {
        delete $self->{CONTACT};
    }
}

sub setSnmpHostname {
    my ($self) = @_;

    # Permit mib support to reset snmphostname
    if ($self->{MIBSUPPORT}) {
        my $name = $self->{MIBSUPPORT}->getMethod('getSnmpHostname');
        $self->{SNMPHOSTNAME} = $name if $name;
    }
}

sub setInventoryBaseInfos {
    my ($self) = @_;
    $self->_set_from_oid_list($inventory_only_base_variables, $self->{INFO});
}

sub _set_from_oid_list {
    my ($self, $list, $where) = @_;

    foreach my $key (keys %{$list}) {
        my $variable = $list->{$key};
        my $type = $variable->{type};

        my $raw_value;
        if (ref $variable->{oid} eq 'ARRAY') {
            foreach my $oid (@{$variable->{oid}}) {
                $raw_value = $self->get($oid);
                if (defined($raw_value) && $type =~ /^memory|count$/) {
                    # Skip value if it seems not to include a number for memory & count
                    undef $raw_value unless $raw_value =~ /\d+/;
                }
                last if defined $raw_value;
            }
        } elsif (ref $variable->{oid} eq 'HASH') {
            foreach my $oid (keys %{$variable->{oid}}) {
                $raw_value = $self->get($oid);
                if (defined($raw_value) && $type =~ /^memory|count$/) {
                    # Skip value if it seems not to include a number for memory & count
                    undef $raw_value unless $raw_value =~ /\d+/;
                    $raw_value .= ' kB' if $variable->{oid}->{$oid} eq 'kb' && isInteger($raw_value);
                }
                last if defined $raw_value;
            }
        } else {
            $raw_value = $self->get($variable->{oid});
        }
        next unless defined $raw_value;

        my $value =
            $type eq 'memory' ? getCanonicalMemory($raw_value) :
            $type eq 'string' ? getCanonicalString($raw_value) :
            $type eq 'count'  ? getCanonicalCount($raw_value)  :
                                $raw_value;

        $where->{$key} = $value if defined $value;
    }
}

sub _numericMac {
    my ($mac) = @_;

    my $number = 0;
    my $multiplicator = 1;

    my @parts = split(':', $mac);
    while (@parts) {
        $number += hex(pop(@parts))*$multiplicator;
        $multiplicator <<= 8 ;
    }

    return $number;
}


sub setIp {
    my ($self) = @_;

    my $results = $self->walk('.1.3.6.1.2.1.4.20.1.1');
    return $self->{IPS}->{IP} = [
        sort values %{$results}
    ] if $results;

    my $ip = $self->getIpByMibSupport();
    $self->{IPS}->{IP} = [ $ip ] if $ip;
}

sub setComponents {
    my ($self) = @_;

    # First try to get components from standard ENTITY-MIB support
    my $components = GLPI::Agent::SNMP::Device::Components->new(
        device => $self
    );
    if ($components) {
        foreach my $component (@{$components->getPhysicalComponents()}) {
            $self->addComponent($component);
        }
    }

    # Then look for any plugin providing getComponents API
    if ($self->{MIBSUPPORT}) {
        $components = $self->{MIBSUPPORT}->getMethod('getComponents') || [];
        foreach my $component (@{$components}) {
            $self->addComponent($component);
        }
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::Device - GLPI agent SNMP device

=head1 DESCRIPTION

Class to help handle general method to apply on snmp device discovery/inventory

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item logger

=item snmp (mandatory)  SNMP session object

=back
