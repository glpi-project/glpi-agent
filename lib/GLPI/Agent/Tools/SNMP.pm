package GLPI::Agent::Tools::SNMP;

use strict;
use warnings;
use base 'Exporter';

use Encode qw(decode);

use GLPI::Agent::Tools;

our @EXPORT = qw(
    getCanonicalSerialNumber
    getCanonicalString
    getCanonicalMacAddress
    getCanonicalConstant
    getCanonicalMemory
    getCanonicalCount
    getCanonicalDate
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

    # Decode string before attempting any truncate on invalid char
    $value = decode('UTF-8', $value);

    # truncate after first invalid character but keep newline as valid
    $value =~ s/[^\p{Print}\n].*$//;

    # Finally cleanup EOL if some is remaining at the end
    chomp($value);

    # Finally return decoded string
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

my %M = qw(Jan 1 Feb 2 Mar 3 Apr 4 May 5 Jun 6 Jul 7 Aug 8 Sep 9 Oct 10 Nov 11 Dec 12);
my $months = join('|', keys(%M));
my $days   = "Mon|Tue|Wed|Thu|Fri|Sat|Sun";
my $first  = join("|", map { "0?$_" } 1..9);
my $month  = join("|", $first, 10..12);
my $month2 = join("|", map { sprintf("%02d", $_) } 1..12);
my $day    = join("|", $first, 10..31);
my $day2   = join("|", map { sprintf("%02d", $_) } 1..31);
my $hour   = join("|", map { sprintf("%02d", $_) } 0..23);
my $min    = join("|", map { sprintf("%02d", $_) } 0..59);
my $sec    = $min;
my $year   = "[1-9][0-9]{3}";

# Return date if possible
sub getCanonicalDate {
    my ($value) = @_;

    return if empty($value);

    # Match on 'D M d H:i:s Y'
    if ($value =~ /^(?:$days) ($months) +($day) (?:$hour):(?:$min):(?:$sec) .*($year)$/) {
        return sprintf("%4d-%02d-%02d", $3, $M{$1}, $2);
    }

    # Match 'D M d, Y H:i:s' as in "Wed Aug 01, 2012 05:50:43PM"
    if ($value =~ /^(?:$days) ($months) +($day), ($year) /) {
        return sprintf("%4d-%02d-%02d", $3, $M{$1}, $2);
    }

    # Match on 'Y-m-d\TH:i:sZ' and others with same prefix
    if ($value =~ /^($year)-($month)-($day)/) {
        return sprintf("%4d-%02d-%02d", $1, $2, $3);
    }

    # Match on 'd/m/Y H:i:s' and others
    if ($value =~ m{^($day)/($month)/($year)} ) {
        return sprintf("%4d-%02d-%02d", $3, $2, $1);
    }

    # Match on 'm/d/Y'
    if ($value =~ m{^($month)/($day)/($year)} ) {
        return sprintf("%4d-%02d-%02d", $3, $1, $2);
    }

    # Match on 'd.m.Y'
    if ($value =~ /^($day)\.($month)\.($year)/ ) {
        return sprintf("%4d-%02d-%02d", $3, $2, $1);
    }

    # Match on 'Ymd'
    if ($value =~ /^($year)($month2)($day2)$/ ) {
        return sprintf("%4d-%02d-%02d", $1, $2, $3);
    }

    return;
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
