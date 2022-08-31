package GLPI::Agent::Tools::License;

use strict;
use warnings;
use parent 'Exporter';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

our @EXPORT = qw(
    getAdobeLicenses
    getAdobeLicensesWithoutSqlite
    decodeMicrosoftKey
);

# Thanks to Brandon Mulcahy
# http://www.a1vbcode.com/snippet-4796.asp
sub _decodeAdobeKey {
    my ($encrypted_key) = @_;

    return unless $encrypted_key;

    my @cipher_key = qw/
        0000000001 5038647192 1456053789 2604371895
        4753896210 8145962073 0319728564 7901235846
        7901235846 0319728564 8145962073 4753896210
        2604371895 1426053789 5038647192 3267408951
        5038647192 2604371895 8145962073 7901235846
        3267408951 1426053789 4753896210 0319728564/;

    my @decrypted_key_chars;
    foreach my $char (split(//, $encrypted_key)) {
        my $sub_cipher_key = shift @cipher_key;
        push @decrypted_key_chars, (split(//, $sub_cipher_key))[$char];
    }

    return sprintf
        '%s%s%s%s-%s%s%s%s-%s%s%s%s-%s%s%s%s-%s%s%s%s-%s%s%s%s',
        @decrypted_key_chars;
}

sub getAdobeLicenses {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @licenses;

    my %data;

    foreach my $line (@lines) {

        my @f = split(/ <> /, $line);

        next unless $f[3];

        $f[1] =~ s/\{\|\}.*//;
        $f[2] =~ s/\{\|\}.*//;
        $f[3] =~ s/\{\|\}.*//;

        if ($f[2] eq 'FLMap') {
            push @{$data{$f[3]}{with}}, $f[1];
        } elsif ($f[3] ne "unlicensed") {
            $data{$f[1]}{$f[2]} = $f[3];
        }
    }

    foreach my $key (keys %data) {
        next unless $data{$key}{SN} || $data{$key}{with};

        push @licenses, {
            NAME       => $key,
            FULLNAME   => $data{$key}{ALM_LicInfo_EpicAppName},
            KEY        => _decodeAdobeKey($data{$key}{SN}) || 'n/a',
            COMPONENTS => join('/', sort @{$data{$key}{with}})
        }
    }

    return @licenses;
}

sub getAdobeLicensesWithoutSqlite {
    my ($fileAdobe) = @_;

    my $contentFileAdobe = getAllLines(file => $fileAdobe) or return;

    my @licenses;
    $contentFileAdobe =~ s/\0//g;
    my $copyContent = $contentFileAdobe;
    my %products;
    while ($copyContent =~ s/1([a-zA-Z0-9\-\.]+)[\{\|\}[a-zA-Z0-9\-_]*]?FLMap([a-zA-Z0-9\-\.]{3,}).{2,3}//) {
        if (exists($products{$2})) {
            push @{$products{$2}}, $1 if !grep (/^$1$/, @{$products{$2}});
        } else {
            $products{$2} = [$1];
        }
    }

    while (my ($product, $component) = each %products) {
        $copyContent = $contentFileAdobe;
        my $regex = $product.'\{\|\}[a-zA-Z0-9\-_]+SN([0-9]{24})';
        $copyContent =~ /$regex/;
        if ($1) {
            my $SN = _decodeAdobeKey($1);
            $copyContent = $contentFileAdobe;
            $regex = $product.'ALM_LicInfo_EpicAppName\{\|\}[0-9]+([a-zA-Z]+[a-zA-Z0-9\.\- ]+).{2}';
            $copyContent =~ /$regex/;
            my $fullName = $product;
            $fullName = $1 if $1;

            push @licenses, {
                NAME       => $product,
                FULLNAME   => $fullName,
                KEY        => $SN,
                COMPONENTS => join('/', sort @{$component})
            }
        }
    }

    return @licenses;
}

# inspired by http://poshcode.org/4363
sub decodeMicrosoftKey {
    my ($raw) = @_;

    ## no critic (ProhibitBitwise)

    return unless $raw;

    my @key_bytes = unpack 'C*', $raw;

    # select correct bytes range:
    # - 808 to 822 for new style keys (Office 2010 and later)
    # - 52 to 66 for old style keys
    my $first_byte = defined $key_bytes[808] ? 808 : 52;
    my $last_byte  = $first_byte + 14;

    # check for Windows 8/Office 2013 style key (can contains the letter "N")
    my $containsN  = ($key_bytes[$last_byte] >> 3) & 1;
    $key_bytes[$last_byte] = $key_bytes[$last_byte] & 0xF7;

    # length of product key, in chars
    my $chars_length = 25;

    # length of product key, in bytes
    my $bytes_length = 15;

    # product key available characters
    my @letters = qw(B C D F G H J K M P Q R T V W X Y 2 3 4 6 7 8 9);

    # extract relevant bytes
    my @bytes = @key_bytes[$first_byte .. $last_byte];

    # return immediatly for null keys
    return if all { $_ == 00 } @bytes;

    # decoded product key
    my @chars;

    for (my $i = $chars_length - 1; $i >= 0; $i--) {
        my $index = 0;
        for (my $j = $bytes_length - 1; $j >= 0; $j--) {
            my $value = ($index << 8) | $bytes[$j];
            $bytes[$j] = $value / scalar @letters;
            $index = $value % (scalar @letters);
        }
        $chars[$i] = $letters[$index];
    }

    if ($containsN != 0) {
        my $first_char = shift @chars;
        my $first_char_index = 0;
        for (my $index = 0; $index < scalar @letters; $index++) {
            next if $first_char ne $letters[$index];
            $first_char_index = $index;
            last;
        }

        splice @chars, $first_char_index, 0, 'N';
    }

    return sprintf
        '%s%s%s%s%s-%s%s%s%s%s-%s%s%s%s%s-%s%s%s%s%s-%s%s%s%s%s', @chars;
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::License - License-related functions

=head1 DESCRIPTION

This module provides some functions to access license information.

=head1 FUNCTIONS

=head2 getAdobeLicenses

Returns a structured view of Adobe license.

=head2 getAdobeLicensesWithoutSqlite

Returns a structured view of Adobe license without Sqlite.

=head2 decodeMicrosoftKey($string)

Return a decoded string from a binary binary microsoft product key (XP, office,
etc)
