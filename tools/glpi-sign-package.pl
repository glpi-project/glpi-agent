#!/usr/bin/perl

use strict;
use warnings;
use Digest::SHA;
use UNIVERSAL::require;
use File::Find;
use Getopt::Long;
use File::Spec;

my ($dir, $key_file, $help);

GetOptions(
    'dir=s' => \$dir,      # Directory of the package to sign
    'key=s' => \$key_file, # File containing the private key (hex)
    'help'  => \$help,
);

if ($help || !$dir || !$key_file) {
    print "Usage: $0 --dir <directory> --key <private_key_file>\n";
    print "\nOptions:\n";
    print "  --dir <directory>  Directory containing the files to be deployed\n";
    print "  --key <file>       File containing your Ed25519 private key in hex format\n";
    exit;
}

# 1. Load private key
unless (Crypt::Ed25519->require()) {
    die "Error: Crypt::Ed25519 perl module is required on this system to sign packages.\n";
}

open my $kh, '<', $key_file or die "Can't open key file '$key_file': $!";
my $priv_hex = <$kh>;
close $kh;
$priv_hex =~ s/\s+//g;
my $priv_bin = pack("H*", $priv_hex);

if (length($priv_bin) != 32) {
    die "Error: Private key must be 32 bytes (64 hex characters).\n";
}

# 2. Generate manifest (SHA-512 of each file)
my $manifest = "";
my @files;

find(sub {
    return if -d $_;
    return if $_ eq 'signature.sig' || $_ eq 'manifest.sig';
    
    # Calculate relative path from the root of $dir
    my $rel_path = File::Spec->abs2rel($File::Spec->rel2abs($_), File::Spec->rel2abs($dir));
    push @files, $rel_path;
}, $dir);

foreach my $file (sort @files) {
    my $path = File::Spec->catfile($dir, $file);
    my $sha = Digest::SHA->new(512);
    $sha->addfile($path, 'b');
    $manifest .= $sha->hexdigest . " $file\n";
}

# 3. Sign the manifest
my $signature_bin = Crypt::Ed25519::sign($manifest, $priv_bin, Crypt::Ed25519::public_key($priv_bin));
my $signature_hex = unpack("H*", $signature_bin);

# 4. Write signature.sig
my $sig_file = File::Spec->catfile($dir, 'signature.sig');
open my $sh, '>', $sig_file or die "Can't write signature file '$sig_file': $!";
print $sh $signature_hex, "\n", $manifest;
close $sh;

print "Success: Package signed successfully in $sig_file\n";

__END__

=head1 NAME

glpi-sign-package.pl - Sign a deployment package for GLPI Agent

=head1 SYNOPSIS

glpi-sign-package.pl --dir <directory> --key <private_key_file>

=head1 DESCRIPTION

This tool creates a signed manifest for a directory intended to be used
with the GLPI Agent Deploy task. It generates SHA-512 hashes for all files
in the directory and signs the resulting manifest using an Ed25519 private key.

The output is a C<signature.sig> file created at the root of the directory.
