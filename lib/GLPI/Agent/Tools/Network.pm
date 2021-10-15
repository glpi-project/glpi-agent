package GLPI::Agent::Tools::Network;

use strict;
use warnings;
use parent 'Exporter';

use English qw(-no_match_vars);
use Net::IP qw(:PROC);
use Net::hostent;
use Socket;

use GLPI::Agent::Tools;

our @EXPORT = qw(
    $mac_address_pattern
    $ib_mac_address_pattern
    $any_mac_address_pattern
    $ip_address_pattern
    $alt_mac_address_pattern
    $hex_ip_address_pattern
    $network_pattern
    getSubnetAddress
    getSubnetAddressIPv6
    getNetworkMask
    getNetworkMaskIPv6
    isSameNetwork
    isSameNetworkIPv6
    hex2canonical
    alt2canonical
    resolve
    compile
    isPartOf
);

my $dec_byte        = qr/[0-9]{1,3}/;
my $hex_byte        = qr/[0-9A-F]{1,2}/i;
my $padded_hex_byte = qr/[0-9A-F]{2}/i;

our $mac_address_pattern = qr/
    $hex_byte : $hex_byte : $hex_byte : $hex_byte : $hex_byte : $hex_byte
/x;

our $ib_mac_address_pattern = qr/
    $hex_byte : $hex_byte : $hex_byte : $hex_byte : $hex_byte : $hex_byte :
    $hex_byte : $hex_byte : $hex_byte : $hex_byte : $hex_byte : $hex_byte :
    $hex_byte : $hex_byte : $hex_byte : $hex_byte : $hex_byte : $hex_byte :
    $hex_byte : $hex_byte
/x;

our $any_mac_address_pattern = qr/
    (?:$ib_mac_address_pattern|$mac_address_pattern)
/x;

our $ip_address_pattern = qr/
    $dec_byte \. $dec_byte \. $dec_byte \. $dec_byte
/x;

our $alt_mac_address_pattern = qr/
    $padded_hex_byte
    $padded_hex_byte
    $padded_hex_byte
    $padded_hex_byte
    $padded_hex_byte
    $padded_hex_byte
/x;

our $hex_ip_address_pattern = qr/
    $padded_hex_byte
    $padded_hex_byte
    $padded_hex_byte
    $padded_hex_byte
/x;

our $network_pattern = qr/
    $dec_byte (?:\. $dec_byte (?:\. $dec_byte (?:\. $dec_byte)?)?)? \/ \d{1,2}
/x;

sub getSubnetAddress {
    my ($address, $mask) = @_;

    return undef unless $address && $mask; ## no critic (ExplicitReturnUndef)

    my $binaddress = ip_iptobin($address, 4);
    my $binmask    = ip_iptobin($mask, 4);
    my $binsubnet  = $binaddress & $binmask; ## no critic (ProhibitBitwise)

    return ip_bintoip($binsubnet, 4);
}

sub getSubnetAddressIPv6 {
    my ($address, $mask) = @_;

    return undef unless $address && $mask; ## no critic (ExplicitReturnUndef)

    my $binaddress = ip_iptobin(ip_expand_address($address, 6), 6);
    my $binmask    = ip_iptobin(ip_expand_address($mask, 6), 6);
    my $binsubnet  = $binaddress & $binmask; ## no critic (ProhibitBitwise)

    return ip_compress_address(ip_bintoip($binsubnet, 6), 6);
}

sub isSameNetwork {
    my ($address1, $address2, $mask) = @_;

    ## no critic (ExplicitReturnUndef)
    return undef unless $address1 && $address2 && $mask;

    my $binaddress1 = ip_iptobin($address1, 4);
    my $binaddress2 = ip_iptobin($address2, 4);
    my $binmask     = ip_iptobin($mask, 4);

    ## no critic (ProhibitBitwise)
    return ($binaddress1 & $binmask) eq ($binaddress2 & $binmask);
}

sub isSameNetworkIPv6 {
    my ($address1, $address2, $mask) = @_;

    ## no critic (ExplicitReturnUndef)
    return undef unless $address1 && $address2 && $mask;

    my $binaddress1 = ip_iptobin(ip_expand_address($address1, 6), 6);
    my $binaddress2 = ip_iptobin(ip_expand_address($address2, 6), 6);
    my $binmask     = ip_iptobin(ip_expand_address($mask, 6), 6);

    ## no critic (ProhibitBitwise)
    return ($binaddress1 & $binmask) eq ($binaddress2 & $binmask);
}

sub hex2canonical {
    my ($address) = @_;
    return unless $address;

    my @bytes = $address =~ /^(?:0x)?(..)(..)(..)(..)$/;
    return join('.', map { hex($_) } @bytes);
}

sub alt2canonical {
    my ($address) = @_;
    return unless $address;

    my @bytes = $address =~ /^(?:0x)?([[:xdigit:]]{2})[ :-]?([[:xdigit:]]{2})[ :-]?([[:xdigit:]]{2})[ :-]?([[:xdigit:]]{2})[ :-]?([[:xdigit:]]{2})[ :-]?([[:xdigit:]]{2})$/;
    return join(':', @bytes);
}

sub getNetworkMask {
    my ($prefix) = @_;

    return undef unless $prefix; ## no critic (ExplicitReturnUndef)

    return ip_bintoip(ip_get_mask($prefix, 4), 4);
}

sub getNetworkMaskIPv6 {
    my ($prefix) = @_;

    return undef unless $prefix; ## no critic (ExplicitReturnUndef)

    return ip_compress_address(ip_bintoip(ip_get_mask($prefix, 6), 6), 6);
}

sub resolve {
    my ($name, $logger) = @_;

    my @addresses;
    my @errors;

    # Avoid an error as Socket::VERSION may contain underscore
    my ($SocketVersion) = split('_',$Socket::VERSION);

    if ($SocketVersion >= 1.94) {
        # IPv6 compatible version
        my ($error, @results) = Socket::getaddrinfo(
            $name, undef, {
                family   => Socket::AF_UNSPEC(),
                protocol => Socket::IPPROTO_TCP()
            }
        );
        if ($error) {
            push @errors, "unable to get address for '$name': $error";
            @results = ();
        }

        # and push all of their addresses in the list
        foreach my $result (@results) {
            my ($error, $address) = Socket::getnameinfo(
                $result->{addr}, Socket::NI_NUMERICHOST()
            );
            if ($error) {
                push @errors,
                    "unable to translate binary address for '$name': $error";
                next;
            }

            # Drop the zone index, as Net::IP does not support it
            $address =~ s/%.*$//;

            push @addresses, $address;
        }
    }

    # If needed, try also legacy resolving and only report previous errors from here
    unless (@addresses) {
        # IPv4-only version
        my $result = gethostbyname($name);
        if (!$result) {
            push @errors,
                "unable to get address for '$name': $ERRNO";
            map { $logger->error($_) } @errors
                if $logger;
            return;
        }
        foreach my $packed_address (@{$result->addr_list()}) {
            push @addresses, inet_ntoa($packed_address);
        }
    }

    return map { Net::IP->new($_) } @addresses;
}

sub _expand_ipv4_to_ipv6 {
    my @expanded;
    foreach my $netip (@_) {
        my $version = ip_get_version($netip->ip());
        next unless $version == 4;
        my $prefix = 128 - 32 + $netip->prefixlen();
        my $ipv6_string = "::ffff:".$netip->ip()."/".$prefix;
        push @expanded, Net::IP->new($ipv6_string);
        # Also include shorten ipv6 loopback address if needed
        push @expanded, Net::IP->new("::1") if $netip->print() eq "127.0.0.1/32";
    }
    return @_, @expanded;
}

sub compile {
    my ($string, $logger) = @_;

    return unless $string;

    # that's already an IP address, just convert it
    return _expand_ipv4_to_ipv6(Net::IP->new($string))
        if $string =~ /^$ip_address_pattern/;

    # otherwise resolve the name
    return _expand_ipv4_to_ipv6(resolve($string, $logger));
}

sub isPartOf {
    my ($string, $ranges, $logger) = @_;

    return unless $string;
    return unless $ranges;

    my $address = Net::IP->new($string);

    if (!$address) {
        $logger->error("Not well formatted source IP: $string");
        return;
    }

    my $version = ip_get_version($string);
    if (!$version) {
        $logger->error("Source IP error '$string': ".Net::IP::Error());
        return;
    }

    # We only want to compare on same kind of ips
    my @ranges = grep { ip_get_version($_->ip()) == $version } @{$ranges};
    foreach my $range (@ranges) {
        my $result = $address->overlaps($range);

        if (!$result && Net::IP::Error()) {
            $logger->debug("Server: ".Net::IP::Error());
            next;
        }

        # included in trusted range
        return 1 if $result == $IP_A_IN_B_OVERLAP;

        # equals trusted address
        return 1 if $result == $IP_IDENTICAL;
    }

    return 0;
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::Network - Network-related patterns and functions

=head1 DESCRIPTION

This module provides some network-related patterns and functions.

=head1 PATTERNS

=head2 mac_address_pattern

This pattern matches a MAC address in canonical form (aa:bb:cc:dd:ee:ff).

=head2 ip_address_pattern

This pattern matches an IP address in canonical form (xyz.xyz.xyz.xyz).

=head2 alt_mac_address_pattern

This pattern matches a MAC address in alternative form (aabbccddeeff).

=head2 hex_ip_address_pattern

This pattern matches an IP address in hexadecimal form (aabbccdd).

=head1 FUNCTIONS

=head2 hex2canonical($address)

Convert an ip address from hexadecimal to canonical form.

=head2 alt2canonical($address)

Convert a mac address from alternative to canonical form.

=head2 getSubnetAddress($address, $mask)

Returns the subnet address for IPv4.

=head2 getSubnetAddressIPv6($address, $mask)

Returns the subnet address for IPv6.

=head2 getNetworkMask($prefix)

Returns the network mask for IPv4.

=head2 getNetworkMaskIPv6($prefix)

Returns the network mask for IPv6.

=head2 isSameNetwork($address1, $address2, $mask)

Returns true if both addresses belongs to the same network, for IPv4.

=head2 isSameNetworkIPv6($address1, $address2, $mask)

Returns true if both addresses belongs to the same network, for IPv6.

=head2 resolve($host, $logger)

Returns a list of addresses, as Net::IP objects, for the given host name, as a
string.

=head2 compile($spec, $logger)

Returns a list of addresses, as Net::IP objects, for the given IP address or
host name, as a string.

=head2 isPartOf($address, $addresses, $logger)

Returns true if the given address, as a string, is part of any address from the
given list, as Net::IP objects.
