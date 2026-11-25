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
                'C:\\Program Files\\GLPI-Agent\\perl\\bin\\perl.exe';
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
use Cwd qw(abs_path);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Cpanel::JSON::XS;
use GLPI::Agent::Task::Deploy::Signature qw(jobDigest payloadFiles);
use UNIVERSAL::require;
use Getopt::Long;
use File::Spec;

my ($dir, $key_file, $job_file, @commands, $help);

GetOptions(
    'dir=s'     => \$dir,      # Directory of the package to sign
    'key=s'     => \$key_file, # File containing the private key
    'command=s' => \@commands, # Commands to authorize
    'job=s'     => \$job_file,
    'help'      => \$help,
) or die "Invalid signing options\n";

if ($help || !$dir || !$key_file) {
    print "Usage: $0 --dir <directory> --key <private_key_file> --job <job.json>\n";
    print "\nOptions:\n";
    print "  --dir <directory>  Directory containing the files to be deployed\n";
    print "  --key <file>       File containing your Ed25519 private key (hex or PEM format)\n";
    print "  --command <cmd>    Authorize a specific command (can be repeated)\n";
    print "  --job <file>       Exact deployment actions, checks, requires and userinteractions as JSON\n";
    exit;
}

die "Use either --job or --command, not both\n" if $job_file && @commands;
die "A signed deployment plan (--job or --command) is required\n" unless $job_file || @commands;
my $job;
if ($job_file) {
    open my $handle, '<', $job_file or die "Can't read deployment plan: $!\n";
    binmode $handle;
    $job = Cpanel::JSON::XS->new->utf8->decode(do { local $/; <$handle> });
    close $handle;
} else {
    $job = { actions => [map { { cmd => { exec => $_ } } } @commands] };
}
my $job_digest = jobDigest($job);

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
    die "Invalid hexadecimal private key\n" unless $content =~ /\A[0-9a-fA-F]{64}\z/;
    $seed = pack("H*", $content);
}

if (length($seed) != 32) {
    die "Error: Private key seed must be 32 bytes (got " . length($seed) . " bytes). Check your key format.\n";
}

# 2. Generate manifest (SHA-512 of each file)
my $manifest = "GLPI-DEPLOY-SIGNATURE 2\nJOB $job_digest\n";
my $abs_dir = abs_path($dir);
die "Can't find package directory '$dir'\n" unless defined($abs_dir) && -d $abs_dir;

my @files = grep { $_ ne 'signature.sig' && $_ ne 'manifest.sig' } payloadFiles($abs_dir);
die "Remove manifest.sig before signing with signature.sig\n" if -e File::Spec->catfile($abs_dir, 'manifest.sig');

foreach my $file (sort @files) {
    my $path = File::Spec->catfile($abs_dir, $file);
    my $sha = Digest::SHA->new(512);
    $sha->addfile($path, 'b');
    # Normalize path separators to forward slashes
    my $normalized_file = $file;
    $normalized_file =~ s{\\}{/}g;
    $manifest .= $sha->hexdigest . " $normalized_file\n";
}

# 3. Sign the manifest
# GAAS version of Crypt::Ed25519:
# generate_keypair($seed) returns ($public_32, $private_64)
# sign($message, $public_32, $private_64) returns $signature_64
my ($pub_bin, $priv_bin) = Crypt::Ed25519::generate_keypair($seed);
my $signature_bin = Crypt::Ed25519::sign($manifest, $pub_bin, $priv_bin);
my $signature_hex = unpack("H*", $signature_bin);

# 4. Write signature.sig
my $sig_file = File::Spec->catfile($abs_dir, 'signature.sig');
open my $sh, '>', $sig_file or die "Can't write signature file '$sig_file': $!";
binmode($sh);
print $sh $signature_hex, "\n", $manifest;
close $sh;

print "Success: Package signed successfully in $sig_file\n";

__END__

=head1 NAME

glpi-sign-package.pl - Sign a deployment package for GLPI Agent

=head1 SYNOPSIS

glpi-sign-package.pl --dir <directory> --key <private_key_file> --job <job.json>

Options:
  --dir <directory>  Directory containing the files to be signed
  --key <file>       File containing your Ed25519 private key
  --job <file>       Deployment plan JSON
  --command <cmd>    Build a minimal cmd-only plan (can be repeated)
  --help             Display this help message

=head1 DESCRIPTION

This tool creates a signed manifest (C<signature.sig>) for a directory intended
to be used with the GLPI Agent C<Deploy> task.

It performs the following steps:
1. Requires regular, uniquely named files directly inside the target directory.
2. Calculates a SHA-512 hash for each file.
3. Computes the SHA-512 digest of the complete canonical deployment plan.
4. Generates a version 2 manifest containing these hashes.
5. Signs the manifest using the provided Ed25519 private key.
6. Writes the signature and the manifest into a C<signature.sig> file at the
   root of the target directory.

The plan must contain C<actions> in execution order, with every parameter
exactly as supplied by GLPI (including C<name>, C<envs>, C<checks>, return
handling and paths). C<checks> and C<userinteractions> default to empty arrays;
C<requires> defaults to an empty object. These four fields are encoded as
canonical UTF-8 JSON with sorted object keys by C<Cpanel::JSON::XS>. Array
order and JSON value types are preserved. The job UUID, download mirrors and
cache metadata are not part of the plan; file contents are bound separately
by the signed payload hashes.

Export or assemble the actual agent-facing plan and review it before signing.
A change to any signed field requires a new signature. C<--command> is a
shortcut for a plan containing only C<{"cmd":{"exec":"..."}}> actions;
use C<--job> when GLPI supplies additional parameters. Do not combine them.

Keep the private key off the GLPI server. The signature authorizes the plan,
not arbitrary future content downloaded by a signed script. Unchanged signed
plans can be replayed; there is no expiry or anti-rollback mechanism.

=head1 KEY GENERATION

The agent requires an Ed25519 key pair.

=head2 Using OpenSSL (Recommended)

1. Generate the private key in PEM (PKCS#8) format:

  openssl genpkey -algorithm ed25519 -outform PEM -out private.key

2. Extract the public key in hexadecimal (64 characters) for the agent
   configuration (C<deploy-public-key>):

  openssl pkey -in private.key -pubout -outform DER | tail -c 32 | xxd -p -c 32

OpenSSH private keys produced by C<ssh-keygen> are not supported by this tool.

=head1 KEY FORMATS

The tool supports Ed25519 private keys in the following formats:

=over 4

=item * B<PEM (PKCS#8)>: Unencrypted Ed25519 format generated by OpenSSL.

  -----BEGIN PRIVATE KEY-----
  MC4CAQAwBQYDK2VwBCIEIMUWFFWvbK9uT2P1mNVviQzshQhRMm7440fImmCYW8Jj
  -----END PRIVATE KEY-----

=item * B<Raw Hex>: A 64-character hexadecimal string representing the 32-byte
secret seed.

  c5161455af6caf6e4f63f598d56f890cec850851326ef8e347c89a60985bc263

=back

=head1 SIGNING ARCHIVES

Automatic C<uncompress> is rejected in signed mode, before any archive backend
is invoked. Sign archives as opaque files and authorize extraction explicitly:

1. Compress your files into an archive.
2. Place the archive in a directory by itself.
3. Put the exact extraction and installation actions into C<job.json>, outside
   the payload directory. Review their paths, environment and commands.
4. Run C<glpi-sign-package.pl --dir payload --key private.key --job job.json>.
5. Upload both the archive and C<signature.sig> with C<uncompress> disabled.
6. Configure GLPI to send exactly the reviewed plan. The signature file must
   remain external to the archive.

Old file-only and COMMAND manifests must be regenerated. There is deliberately
no fallback to the old format when C<deploy-public-key> is configured.

=head1 EXAMPLES

=head2 Sign a directory and authorize a command

  perl tools/glpi-sign-package.pl --dir /path/to/payload --key my_private.key --command "sh install.sh"

=head2 Sign a plan containing a configuration copy

Create C<job.json> outside the payload directory, matching GLPI's job fields:

  {
    "actions": [{"copy": {"from": "agent.cfg", "to": "/etc/glpi-agent/conf.d/10-site.cfg"}}],
    "checks": [],
    "requires": {},
    "userinteractions": []
  }

  perl tools/glpi-sign-package.pl --dir /path/to/payload --key private.key --job job.json

=head1 REQUIREMENTS

This tool requires the C<Crypt::Ed25519> Perl module.

=head1 SEE ALSO

L<GLPI::Agent::Task::Deploy>
