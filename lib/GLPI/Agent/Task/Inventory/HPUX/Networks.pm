package GLPI::Agent::Task::Inventory::HPUX::Networks;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Unix;
use GLPI::Agent::Tools::Network;

use constant    category    => "network";

#TODO Get pcislot virtualdev

sub isEnabled {
    return canRun('lanscan');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $routes = getRoutingTable(command => 'netstat -nr', logger => $logger);
    my $default = $routes->{'0.0.0.0'};

    my @interfaces = _getInterfaces(logger => $logger);
    foreach my $interface (@interfaces) {
        # if the default gateway address and the interface address belongs to
        # the same network, that's the gateway for this network
        $interface->{IPGATEWAY} = $default if isSameNetwork(
            $default, $interface->{IPADDRESS}, $interface->{IPMASK}
        );

        $inventory->addEntry(
            section => 'NETWORKS',
            entry   => $interface
        );
    }

    $inventory->setHardware({
        DEFAULTGATEWAY => $default
    });
}

sub _getInterfaces {
    my (%params) = @_;

    my @prototypes = _parseLanscan(
        command => 'lanscan -iap',
        logger  => $params{logger}
    );

    my %ifStatNrv = _parseNetstatNrv();

    my @interfaces;
    foreach my $prototype (@prototypes) {

        my $lanadminInfo = _getLanadminInfo(
            command => "lanadmin -g $prototype->{lan_id}",
            logger  => $params{logger}
        );
        $prototype->{TYPE}  = $lanadminInfo->{'Type (value)'};
        $prototype->{SPEED} = $lanadminInfo->{Speed} > 1000000 ?
            $lanadminInfo->{Speed} / 1000000 : $lanadminInfo->{Speed};

        if ($ifStatNrv{$prototype->{DESCRIPTION}}) {
            # if this interface name has been found in netstat output, let's
            # use the list of interfaces found there, using the prototype
            # to provide additional informations
            foreach my $interface (@{$ifStatNrv{$prototype->{DESCRIPTION}}}) {
                foreach my $key (qw/MACADDR STATUS TYPE SPEED/) {
                    next unless $prototype->{$key};
                    $interface->{$key} = $prototype->{$key};
                }
                push @interfaces, $interface;
            }
        } else {
            # otherwise, we promote this prototype to an interface, using
            # ifconfig to provide additional informations
            my $ifconfigInfo = _getIfconfigInfo(
                command => "ifconfig $prototype->{DESCRIPTION}",
                logger  => $params{logger}
            );
            $prototype->{STATUS}    = $ifconfigInfo->{status};
            $prototype->{IPADDRESS} = $ifconfigInfo->{address};
            $prototype->{IPMASK}    = $ifconfigInfo->{netmask};
            delete $prototype->{lan_id};
            push @interfaces, $prototype;
        }
    }

    foreach my $interface (@interfaces) {
        if ($interface->{IPADDRESS} && $interface->{IPADDRESS} eq '0.0.0.0') {
            $interface->{IPADDRESS} = undef;
            $interface->{IPMASK}    = undef;
        } else {
            $interface->{IPSUBNET} = getSubnetAddress(
                $interface->{IPADDRESS},
                $interface->{IPMASK}
            );
        }
    }

    return @interfaces;
}

sub _parseLanscan {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @interfaces;
    foreach my $line (@lines) {
        next unless $line =~ /^
            0x($alt_mac_address_pattern)
            \s
            (\S+)
            \s
            \S+
            \s+
            (\S+)
            /x;

        # quick assertion: nothing else as ethernet interface
        my $interface = {
            MACADDR     => alt2canonical($1),
            STATUS      => 'Down',
            DESCRIPTION => $2,
            TYPE        => 'ethernet',
            lan_id      => $3,
        };

        push @interfaces, $interface;
    }

    return @interfaces;
}

sub _getLanadminInfo {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my $info;
    foreach my $line (@lines) {
        next unless $line =~ /^(\S.+\S) \s+ = \s (.+)$/x;
        $info->{$1} = $2;
    }

    return $info;
}

sub _getIfconfigInfo {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my $info;
    foreach my $line (@lines) {
        if ($line =~ /<UP/) {
            $info->{status} = 'Up';
        }
        if ($line =~ /inet ($ip_address_pattern)/) {
            $info->{address} = $1;
        }
        if ($line =~ /netmask ($hex_ip_address_pattern)/) {
            $info->{netmask} = hex2canonical($1);
        }
    }

    return $info;
}

# will be need to get the bonding configuration
sub _getNwmgrInfo {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my $info;
    foreach my $line (@lines) {
        next unless $line =~ /^
            (\w+)
            \s+
            (\w+)
            \s+
            0x($alt_mac_address_pattern)
            \s+
            (\w+)
            \s+
            (\w*)
            /x;
        my $interface = $1;

        $info->{$interface} = {
            status     => $2,
            mac        => alt2canonical($3),
            driver     => $4,
            media      => $5,
            related_if => undef
        }
    }

    return $info;
}

sub _parseNetstatNrv {
    my (%params) = (
        command => 'netstat -nrv',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my %interfaces;
    foreach my $line (@lines) {
        next unless $line =~ /^
            ($ip_address_pattern) # address
            \/
            ($ip_address_pattern) # mask
            \s+
            ($ip_address_pattern) # gateway
            \s+
            [A-Z]* H [A-Z]*       # host flag
            \s+
            \d
            \s+
            (\w+) (?: :\d+)?      # interface name, with optional alias
            \s+
            (\d+)                 # MTU
            $/x;

        my $address   = $1;
        my $mask      = $2;
        my $gateway   = ($3 ne $1) ? $3 : undef;
        my $interface = $4;
        my $mtu       = $5;

        # quick assertion: nothing else as ethernet interface
        push @{$interfaces{$interface}}, {
            IPADDRESS   => $address,
            IPMASK      => $mask,
            IPGATEWAY   => $gateway,
            DESCRIPTION => $interface,
            TYPE        => 'ethernet',
            MTU         => $mtu
        }
    }

    return %interfaces;
}

1;
