package GLPI::Agent::Tools::BSD;

use strict;
use warnings;
use parent 'Exporter';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Network;

our @EXPORT = qw(
    getInterfacesFromIfconfig
);

sub getInterfacesFromIfconfig {
    my (%params) = (
        command => '/sbin/ifconfig -a',
        @_
    );
    my @lines = getAllLines(%params)
        or return;

    my @interfaces; # global list of interfaces
    my @addresses;  # per-interface list of addresses
    my $interface;  # current interface

    my %types = (
        Ethernet => 'ethernet',
        IEEE     => 'wifi'
    );

    foreach my $line (@lines) {
        if ($line =~ /^(\S+): flags=\d+<([^>]+)> (?:metric \d+ )?mtu (\d+)/) {

            if (@addresses) {
                push @interfaces, @addresses;
                undef @addresses;
            } else {
                push @interfaces, $interface if $interface;
            }
            my ($name, $flags, $mtu) = ($1, $2, $3);
            my $status =
                (any { $_ eq 'UP' } split(/,/, $flags)) ? 'Up' : 'Down';

            $interface = {
                DESCRIPTION => $name,
                STATUS      => $status,
                MTU         => $mtu
            };
        } elsif ($line =~ /(?:address:|ether|lladdr) ($mac_address_pattern)/) {
            $interface->{MACADDR} = $1;
        } elsif ($line =~ /
            ssid \s (\S+) \s
            channel \s \d+ \s
            \(\d+ \s MHz \s (\S+)[^)]*\) \s
            bssid \s ($mac_address_pattern)
        /x) {
            foreach my $address (@addresses) {
                $address->{WIFI_SSID}    = $1;
                $address->{WIFI_VERSION} = '802.' . $2;
                $address->{WIFI_BSSID}   = $3;
            }
        } elsif ($line =~ /inet ($ip_address_pattern) (?:--> $ip_address_pattern )?netmask 0x($hex_ip_address_pattern)/) {
            my $address = $1;
            my $mask    = hex2canonical($2);
            my $subnet  = getSubnetAddress($address, $mask);

            push @addresses, {
                IPADDRESS   => $address,
                IPMASK      => $mask,
                IPSUBNET    => $subnet,
                STATUS      => $interface->{STATUS},
                DESCRIPTION => $interface->{DESCRIPTION},
                MACADDR     => $interface->{MACADDR},
                MTU         => $interface->{MTU}
            };
        } elsif ($line =~ /inet6 ([\w:]+)\S* prefixlen (\d+)/) {
            my $address = $1;
            my $mask    = getNetworkMaskIPv6($2);
            my $subnet  = getSubnetAddressIPv6($address, $mask);

            push @addresses, {
                IPADDRESS6  => $address,
                IPMASK6     => $mask,
                IPSUBNET6   => $subnet,
                STATUS      => $interface->{STATUS},
                DESCRIPTION => $interface->{DESCRIPTION},
                MACADDR     => $interface->{MACADDR},
                MTU         => $interface->{MTU}
            };

        }

        if ($line =~ /media: (\S+)/) {
            $interface->{TYPE} = $types{$1};
            $_->{TYPE} = $types{$1} foreach @addresses;
        }
    }

    # last interface
    if (@addresses) {
        push @interfaces, @addresses;
    } else {
        push @interfaces, $interface if $interface;
    }

    return @interfaces;
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::BSD - BSD generic functions

=head1 DESCRIPTION

This module provides some generic functions for BSD.

=head1 FUNCTIONS

=head2 getInterfacesFromIfconfig(%params)

Returns the list of interfaces, by parsing ifconfig command output.

Availables parameters:

=over

=item logger a logger object

=item command the command to use (default: /sbin/ifconfig -a)

=item file the file to use

=back
