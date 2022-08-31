package GLPI::Agent::Task::Inventory::Solaris::Networks;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

#ce5: flags=1000843<UP,BROADCAST,RUNNING,MULTICAST,IPv4> mtu 1500 index 3
#        inet 55.37.101.171 netmask fffffc00 broadcast 55.37.103.255
#        ether 0:3:ba:24:9b:bf

#aggr40001:2: flags=201000843<UP,BROADCAST,RUNNING,MULTICAST,IPv4,CoS> mtu 1500 index 3
#        inet 55.37.101.172 netmask ffffff00 broadcast 223.0.146.255
#NDD=/usr/sbin/ndd
#KSTAT=/usr/bin/kstat
#IFC=/sbin/ifconfig
#DLADM=/usr/sbin/dladm

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Solaris;
use GLPI::Agent::Tools::Network;
use GLPI::Agent::Tools::Unix;

use constant    category    => "network";

sub isEnabled {
    return canRun('ifconfig');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $routes = getRoutingTable(logger => $logger);
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

    my @interfaces = _parseIfconfig(
        command => 'ifconfig -a',
        @_
    );

    my $has_dladm = canRun('/usr/sbin/dladm');

    foreach my $interface (@interfaces) {
        $interface->{IPSUBNET} = getSubnetAddress(
            $interface->{IPADDRESS},
            $interface->{IPMASK}
        );

        my $name = $interface->{DESCRIPTION}
            or next;

        my $speed;
        if ($has_dladm) {
            $speed = _getInterfaceSpeedviaDladm(
                logger => $params{logger},
                name   => $name
            );
        } else {
            $speed = _getInterfaceSpeed(
                logger => $params{logger},
                name   => $name
            );
        }
        $interface->{SPEED} = $speed if $speed;
    }

    if ($has_dladm) {
        push @interfaces, _parseDladm(
            command => '/usr/sbin/dladm show-aggr',
            logger  => $params{logger}
        );
    }

    if (canRun('/usr/sbin/fcinfo')) {
        push @interfaces, _parsefcinfo(
            command => '/usr/sbin/fcinfo hba-port',
            logger  => $params{logger}
        );
    }

    return @interfaces;
}

sub  _getInterfaceSpeedviaDladm {
    my (%params) = @_;

    return getFirstMatch(
        command => "/usr/sbin/dladm show-phys $params{name}",
        pattern => qr/^$params{name}\s+\S+\s+\S+\s+(\d+)\s+/,
        %params
    );
}

sub  _getInterfaceSpeed {
    my (%params) = @_;

    my $command;

    if ($params{name}) {
        return unless $params{name} =~ /^(\S+)(\d+)/;
        my $type     = $1;
        my $instance = $2;

        return if $type eq 'aggr';
        return if $type eq 'dmfe';

        $command = "/usr/bin/kstat -m $type -i $instance -s link_speed";
    }

    my $speed = getFirstMatch(
        %params,
        command => $command,
        pattern => qr/^\s*link_speed+\s*(\d+)/,
    );

    # By default, kstat reports speed as Mb/s, no need to normalize
    return $speed;
}

sub _parseIfconfig {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @interfaces;
    my $interface;

    foreach my $line (@lines) {
        if ($line =~ /^(\S+):(\S+):/) {
            # new interface
            push @interfaces, $interface if $interface;
            # quick assertion: nothing else as ethernet interface
            $interface = {
                STATUS      => 'Down',
                DESCRIPTION => $1 . ':' . $2,
                TYPE        => 'ethernet'
            };
        } elsif ($line =~ /^(\S+):/) {
            # new interface
            push @interfaces, $interface if $interface;
            # quick assertion: nothing else as ethernet interface
            $interface = {
                STATUS      => 'Down',
                DESCRIPTION => $1,
                TYPE        => 'ethernet'
            };
        }

        if ($line =~ /inet ($ip_address_pattern)/) {
            $interface->{IPADDRESS} = $1;
        } elsif ($line =~ /inet6 (\S+)\/(\d+)/) {
            $interface->{IPADDRESS6} = $1;
            $interface->{IPMASK6} = getNetworkMaskIPv6($2);
        }
        if ($line =~ /netmask ($hex_ip_address_pattern)/i) {
            $interface->{IPMASK} = hex2canonical($1);
        }
        if ($line =~ /ether\s+(\S+)/i) {
            # https://sourceforge.net/tracker/?func=detail&atid=487492&aid=1819948&group_id=58373
            $interface->{MACADDR} =
                sprintf "%02x:%02x:%02x:%02x:%02x:%02x" , map hex, split /\:/, $1;
        }
        if ($line =~ /<UP,/) {
            $interface->{STATUS} = "Up";
        }
    }

    # last interface
    push @interfaces, $interface if $interface;

    return @interfaces;
}

sub _parseDladm {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @interfaces;
    foreach my $line (@lines) {
        next if $line =~ /device/;
        next if $line =~ /key/;
        my $interface = {
            STATUS    => 'Down',
            IPADDRESS => "0.0.0.0",
        };
        next unless
            $line =~ /(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/;
        $interface->{DESCRIPTION} = $1;
        $interface->{MACADDR}     = $2;
        $interface->{SPEED}       = getCanonicalInterfaceSpeed($3 . $4);
        $interface->{STATUS}      = 'Up' if $line =~ /UP/;
        push @interfaces, $interface;
    }

    return @interfaces;
}

sub _parsefcinfo {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @interfaces;
    my $inc = 1;
    my $interface;
    foreach my $line (@lines) {
        $interface->{DESCRIPTION} = "HBA_Port_WWN_" . $inc
            if $line =~ /HBA Port WWN:\s+(\S+)/;
        $interface->{DESCRIPTION} .= " " . $1
            if $line =~ /OS Device Name:\s+(\S+)/;
        $interface->{SPEED} = getCanonicalInterfaceSpeed($1)
            if $line =~ /Current Speed:\s+(\S+)/;
        $interface->{WWN} = $1
            if $line =~ /Node WWN:\s+(\S+)/;
        $interface->{DRIVER} = $1
            if $line =~ /Driver Name:\s+(\S+)/i;
        $interface->{MANUFACTURER} = $1
            if $line =~ /Manufacturer:\s+(.*)$/;
        $interface->{MODEL} = $1
            if $line =~ /Model:\s+(.*)$/;
        $interface->{FIRMWARE} = $1
            if $line =~ /Firmware Version:\s+(.*)$/;
        $interface->{STATUS} = 'Up'
            if $line =~ /online/;

        if ($interface->{DESCRIPTION} && $interface->{WWN}) {
            $interface->{TYPE}   = 'fibrechannel';
            $interface->{STATUS} = 'Down' if !$interface->{STATUS};

            push @interfaces, $interface;
            $interface = {};
            $inc++;
        }
    }

    return @interfaces;
}

1;
