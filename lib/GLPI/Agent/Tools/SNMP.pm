package GLPI::Agent::Tools::SNMP;

use strict;
use warnings;
use base 'Exporter';

use GLPI::Agent::Tools;

our @EXPORT = qw(
    getCanonicalSerialNumber
    getCanonicalString
    getCanonicalMacAddress
    getCanonicalConstant
    getCanonicalMemory
    getCanonicalCount
    isInteger
    getRegexpOidMatch
);

sub getCanonicalSerialNumber {
    my ($value) = @_;

    $value = hex2char($value);
    return unless $value;

    $value =~ s/[[:^print:]]//g;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    $value =~ s/\.{2,}//g;
    return unless $value;

    return $value;
}

sub getCanonicalString {
    my ($value) = @_;

    $value = hex2char($value);
    return unless defined $value;

    # unquote string
    $value =~ s/^\\?["']//;
    $value =~ s/\\?["']$//;

    # Be sure to work on utf-8 string
    $value = getUtf8String($value);

    return unless defined $value;

    # reduce linefeeds which can be found in descriptions or comments
    $value =~ s/\p{Control}+\n/\n/g;

    # truncate after first invalid character but keep newline as valid
    $value =~ s/[^\p{Print}\n].*$//;

    # Finally cleanup EOL if some is remaining at the end
    chomp($value);

    return $value;
}

sub getCanonicalMacAddress {
    my ($value) = @_;

    return unless $value;

    my $result;
    my @bytes;

    # packed value, convert from binary to hexadecimal
    if ($value =~ m/\A [[:ascii:]] \Z/xms || length($value) == 6) {
        $value = unpack 'H*', $value;
    }

    # Check if it's a hex value
    if ($value =~ /^(?:0x)?([0-9A-F]+)$/i) {
        @bytes = unpack("(A2)*", $1);
    } else {
        @bytes = split(':', $value);
        # return if bytes are not hex
        return if grep(!/^[0-9A-F]{1,2}$/i, @bytes);
    }

    if (scalar(@bytes) == 6) {
        # it's a MAC
    } elsif (scalar(@bytes) == 8 &&
        (($bytes[0] eq '10' && $bytes[1] =~ /^0+/) # WWN 10:00:...
            || $bytes[0] =~ /^2/)) {               # WWN 2X:XX:...
    } elsif (scalar(@bytes) < 6) {
        # make a WWN. prepend "10" and zeroes as necessary
        while (scalar(@bytes) < 7) { unshift @bytes, '00' }
        unshift @bytes, '10';
    } elsif (scalar(@bytes) > 6) {
        # make a MAC. take 6 bytes from the right
        @bytes = @bytes[-6 .. -1];
    }

    $result = join ":", map { sprintf("%02x", hex($_)) } @bytes;

    return if $result eq '00:00:00:00:00:00';
    return lc($result);
}

sub isInteger {
    my ($value) = @_;

    return $value =~ /^[+-]?\d+$/;
}

sub getCanonicalMemory {
    my ($value) = @_;

    # Don't try to analyse negative values
    return if $value =~ /^-/;

    if ($value =~ /^(\d+) (KBytes|kB)$/) {
        return int($1 / 1024);
    } else {
        return int($value / 1024 / 1024);
    }
}

sub getCanonicalCount {
    my ($value) = @_;

    return isInteger($value) ? $value  : undef;
}

sub getCanonicalConstant {
    my ($value) = @_;

    return $value if isInteger($value);
    return $1 if $value =~ /\((\d+)\)$/;
}

sub getRegexpOidMatch {
    my ($match) = @_;

    return $match unless $match && $match =~ /^[0-9.]+$/;

    # Protect dots for regexp compilation
    $match =~ s/\./\\./g;

    return qr/^$match/;
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::SNMP - SNMP Hardware-related functions

=head1 DESCRIPTION

This module provides some hardware-related functions for SNMP devices.

=head1 FUNCTIONS

=head2 getCanonicalSerialNumber($serial)

return a clean serial number string.

=head2 getCanonicalString($string)

return a clean generic string.

=head2 getCanonicalMacAddress($mac)

return a clean mac string.

=head2 getCanonicalConstant($value)

return a clean integer value.

=head2 isInteger($value)

return true if value is an integer.

=head2 getRegexpOidMatch($oid)

return compiled regexp to match given oid.
