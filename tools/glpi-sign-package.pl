#!/usr/bin/perl

use strict;
use warnings;

# Smart fallback to GLPI Agent bundled Perl if Crypt::Ed25519 is missing
BEGIN {
    my $has_ed25519 = eval { require Crypt::Ed25519; 1 };
    if (!$has_ed25519) {
        my @bundled_perls;
        if ($^O eq 'MSWin32') {
            push @bundled_perls, 
                'C:\\Program Files\\GLPI-Agent\\perl\\bin\\perl.exe',
                'C:\\Program Files (x86)\\GLPI-Agent\\perl\\bin\\perl.exe';
        } elsif ($^O eq 'darwin') {
            push @bundled_perls, '/Applications/GLPI-Agent/bin/perl';
        }

        foreach my $bundled_perl (@bundled_perls) {
            if (-x $bundled_perl && $^X ne $bundled_perl) {
                print "Crypt::Ed25519 missing. Automatically switching to GLPI Agent Perl ($bundled_perl)...\n";
                exec($bundled_perl, $0, @ARGV) or die "Failed to execute $bundled_perl: $!\n";
            }
        }
    }
}

use Digest::SHA;
use UNIVERSAL::require;
use File::Find;
use Getopt::Long;
use File::Spec;

my ($dir, $key_file, @commands, $help);

GetOptions(
    'dir=s'     => \$dir,      # Directory of the package to sign
    'key=s'     => \$key_file, # File containing the private key
    'command=s' => \@commands, # Commands to authorize
    'help'      => \$help,
);

if ($help || !$dir || !$key_file) {
    print "Usage: $0 --dir <directory> --key <private_key_file> [--command \"cmd1\"] [--command \"cmd2\"]\n";
    print "\nOptions:\n";
    print "  --dir <directory>  Directory containing the files to be deployed\n";
    print "  --key <file>       File containing your Ed25519 private key (hex or PEM format)\n";
    print "  --command <cmd>    Authorize a specific command (can be repeated)\n";
    exit;
}

# 1. Load private key
unless (Crypt::Ed25519->require()) {
    die "Error: Crypt::Ed25519 perl module is required on this system to sign packages.\n";
}

my $content;
if (open my $kh, '<', $key_file) {
    binmode($kh);
    $content = do { local $/; <$kh> };
    close $kh;
} else {
    die "Can't open key file '$key_file': $!";
}

my $seed;
if ($content =~ /-----BEGIN/) {
    # PEM format
    require MIME::Base64;
    $content =~ s/-----BEGIN.*?-----//sg;
    $content =~ s/-----END.*?-----//sg;
    $seed = MIME::Base64::decode_base64($content);

    # Handle PKCS#8 Ed25519 (48 bytes)
    if (length($seed) == 48) {
        # Extract 32-byte seed from PKCS#8
        $seed = substr($seed, -32);
    }
} else {
    # Hex format
    $content =~ s/\s+//g;
    $seed = pack("H*", $content);
}

if (length($seed) != 32) {
    die "Error: Private key seed must be 32 bytes (got " . length($seed) . " bytes). Check your key format.\n";
}

# 2. Generate manifest (SHA-512 of each file)
my $manifest = "";
my @files;
my $abs_dir = File::Spec->rel2abs($dir);

File::Find::find(sub {
    return if -d $_;
    return if $_ eq 'signature.sig' || $_ eq 'manifest.sig';

    # Calculate relative path from the root of $dir
    # We use $abs_dir calculated outside find() because find() chdirs into directories
    my $rel_path = File::Spec->abs2rel(File::Spec->rel2abs($_), $abs_dir);
    push @files, $rel_path;
}, $dir);

foreach my $file (sort @files) {
    my $path = File::Spec->catfile($dir, $file);
    my $sha = Digest::SHA->new(512);
    $sha->addfile($path, 'b');
    # Normalize path separators to forward slashes
    my $normalized_file = $file;
    $normalized_file =~ s{\\}{/}g;
    $manifest .= $sha->hexdigest . " $normalized_file\n";
}

# 2b. Add authorized commands to manifest
foreach my $cmd (@commands) {
    my $sha = Digest::SHA->new(512);
    $sha->add($cmd);
    $manifest .= "COMMAND " . $sha->hexdigest . " $cmd\n";
}

# 3. Sign the manifest
# GAAS version of Crypt::Ed25519:
# generate_keypair($seed) returns ($public_32, $private_64)
# sign($message, $public_32, $private_64) returns $signature_64
my ($pub_bin, $priv_bin) = Crypt::Ed25519::generate_keypair($seed);
my $signature_bin = Crypt::Ed25519::sign($manifest, $pub_bin, $priv_bin);
my $signature_hex = unpack("H*", $signature_bin);

# 4. Write signature.sig
my $sig_file = File::Spec->catfile($dir, 'signature.sig');
open my $sh, '>', $sig_file or die "Can't write signature file '$sig_file': $!";
binmode($sh);
print $sh $signature_hex, "\n", $manifest;
close $sh;

print "Success: Package signed successfully in $sig_file\n";

__END__

=head1 NAME

glpi-sign-package.pl - Sign a deployment package for GLPI Agent

=head1 SYNOPSIS

glpi-sign-package.pl --dir <directory> --key <private_key_file> [--command "cmd1"]

Options:
  --dir <directory>  Directory containing the files to be signed
  --key <file>       File containing your Ed25519 private key
  --command <cmd>    Authorize a specific shell command (can be repeated)
  --help             Display this help message

=head1 DESCRIPTION

This tool creates a signed manifest (C<signature.sig>) for a directory intended 
to be used with the GLPI Agent C<Deploy> task.

It performs the following steps:
1. Scans the target directory for all files (excluding existing signatures).
2. Calculates a SHA-512 hash for each file.
3. Adds SHA-512 hashes for any authorized commands provided via --command.
4. Generates a manifest containing these hashes.
5. Signs the manifest using the provided Ed25519 private key.
6. Writes the signature and the manifest into a C<signature.sig> file at the 
   root of the target directory.

=head1 KEY GENERATION

The agent requires an Ed25519 key pair.

=head2 Using OpenSSL (Recommended)

1. Generate the private key in PEM (PKCS#8) format:

  openssl genpkey -algorithm ed25519 -outform PEM -out private.key

2. Extract the public key in hexadecimal (64 characters) for the agent 
   configuration (C<deploy-public-key>):

  openssl pkey -in private.key -pubout -outform DER | tail -c 32 | xxd -p -c 32

=head2 Using ssh-keygen

1. Generate the key pair:

  ssh-keygen -t ed25519 -f ./my_private.key -N ""

2. The private key format might need conversion if the agent's perl 
   Crypt::Ed25519 module doesn't support the RFC4716 format directly. 
   Using OpenSSL is generally more portable for this script.

=head1 KEY FORMATS

The tool supports Ed25519 private keys in the following formats:

=over 4

=item * B<PEM (PKCS#8)>: Standard format generated by OpenSSL or ssh-keygen.

  -----BEGIN PRIVATE KEY-----
  MC4CAQAwBQYDK2VwBCIEIMUWFFWvbK9uT2P1mNVviQzshQhRMm7440fImmCYW8Jj
  -----END PRIVATE KEY-----

=item * B<Raw Hex>: A 64-character hexadecimal string representing the 32-byte 
secret seed.

  c5161455af6caf6e4f63f598d56f890cec850851326ef8e347c89a60985bc263

=back

=head1 SIGNING ARCHIVES

If you intend to use a compressed archive (e.g., C<.zip>, C<.tar.gz>) with the 
GLPI Server, be careful how you handle the signature if the B<"uncompress"> 
option is enabled in the Deploy task.

When "uncompress" is checked, the agent extracts the archive and then B<deletes> 
the original archive file before verifying the signature.

You have two correct ways to handle archives:

=head2 Method A: Sign the contents (Recommended for "uncompress")

1. Place all your uncompressed files in a directory.
2. Run C<glpi-sign-package.pl> on that directory. This creates C<signature.sig>.
3. Compress the directory contents B<including> the C<signature.sig> file into 
   a single archive.
4. Upload the archive to GLPI and B<check> the "uncompress" option.

=head2 Method B: Sign the archive itself (For manual extraction)

1. Compress your files into an archive.
2. Place the archive in a directory by itself.
3. Run C<glpi-sign-package.pl> on that directory.
4. Upload both the archive and the generated C<signature.sig> to GLPI.
5. B<DO NOT check> the "uncompress" option. You will have to extract the archive 
   manually using a command in your deployment action.

=head1 EXAMPLES

=head2 Sign a directory and authorize a command

  perl tools/glpi-sign-package.pl --dir /path/to/payload --key my_private.key --command "sh install.sh"

=head2 Sign a directory using a hex key

  echo "c5161455af6caf6e4f63f598d56f890cec850851326ef8e347c89a60985bc263" > hex.key
  perl tools/glpi-sign-package.pl --dir /path/to/payload --key hex.key

=head1 REQUIREMENTS

This tool requires the C<Crypt::Ed25519> Perl module.

=head1 SEE ALSO

L<GLPI::Agent::Task::Deploy>
