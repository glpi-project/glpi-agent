package GLPI::Agent::Tools::Win32::KeyStore;

use strict;
use warnings;

use parent 'Exporter';

use UNIVERSAL::require();
use English qw(-no_match_vars);

use threads;
use threads 'exit' => 'threads_only';
use threads::shared;
use Thread::Semaphore;

BEGIN {
    # Only set if you're a developer and need to debug Win32::API usage
    $Win32::API::DEBUG = 0;
}

use Net::SSLeay;

use Win32::API;

use GLPI::Agent::Tools;

use constant    CERT_NAME_SIMPLE_DISPLAY_TYPE   => 4;
use constant    X509_ASN_ENCODING               => 1;

use constant    _log_prefix                     => "[ssl-keystore] ";

Win32::API::Type->typedef('HCERTSTORE',        'ULONG*');
Win32::API::Type->typedef('HCRYPTPROV_LEGACY', 'ULONG*');

my $_CertOpenSystemStoreA = Win32::API::More->Import(
    crypt32 => qq{
        HCERTSTORE CertOpenSystemStoreA(
            HCRYPTPROV_LEGACY hProv,
            LPCSTR szSubSystemProtocol
        );
    }
);

my $CertCloseStore = Win32::API::More->Import(
    crypt32 => qq{
        BOOL CertCloseStore(
            HCERTSTORE hCertStore,
            DWORD      dwFlags
        );
    }
);

my $_CertEnumCertificatesInStore = Win32::API::More->Import(
    crypt32 => 'CertEnumCertificatesInStore', 'NN', 'N'
);

my $CertGetNameStringA = Win32::API::More->Import(
    crypt32 => "CertGetNameStringA", "NIIPPI", "I"
);

# Shared lock variables for loaded CA certificates
my $locked : shared = 0;
my %locked : shared = ();
my %tid    : shared = ();

# Use a semaphore for loading as loading should be done by one thread and
# other threads should wait until loading is done
my $loadingSemaphore = Thread::Semaphore->new();

# Shared configuration
my $expiration : shared = 0;

# Shared loaded CA certificates keystores
my %certs : shared = ();

# Supported windows keystores
my %orderedSupportedKeyStore = qw(
    Mozilla::CA     0
    ROOT            1
    CA              2
    TRUST           3
    MY              4
);

# Only one instance of this object can be used
my $sharedApi;

sub new {
    my ($class, %params) = @_;

    return $sharedApi if defined($sharedApi);

    my @supported = sort {
        $orderedSupportedKeyStore{$a} <=> $orderedSupportedKeyStore{$b}
    } keys(%orderedSupportedKeyStore);

    my $self = {
        supported   => \@supported,
        qrSupported => qr/^(@supported)$/i,
    };

    $sharedApi = bless $self, $class;

    return $sharedApi;
}

sub loadKeyStore {
    my ($self, %params) = @_;

    lock(%locked);

    # Continue to use current keystore if still used by other threads
    return if $locked > 1;

    my $logger = $params{logger};

    my @stores;
    if ($params{store}) {
        foreach my $case (split(/,+/, $params{store})) {
            my $store = uc(trimWhitespace($case));
            # Strip prefix for previously supported store values used until v1.15
            $store =~ s/^\w+-// if $store =~ /^(User|Service|Enterprise|GroupPolicy)-/i;
            if ($store =~ $self->{qrSupported}) {
                push @stores, $store;
            } else {
                $logger->debug(_log_prefix."Unsupported ssl-keystore option definition: $case");
            }
        }
    } else {
        push @stores, grep { $_ ne "Mozilla::CA" } @{$self->{supported}};
    }

    my $total = 0;

    foreach my $store (@stores) {

        next unless $store;

        if ($certs{$store}) {
            if ($expiration && time < $expiration) {
                $total += scalar(@{$certs{$store}});
                next;
            } else {
                # Time to free
                my $certs = delete $certs{$store};
                Net::SSLeay::X509_free($_) for @{$certs};
            }
        }

        my @certs;

        my $hCertStore = CertOpenSystemStoreA(0, $store);
        unless ($hCertStore) {
            $logger->error(_log_prefix."Failed to open system $store keystore")
                if $logger;
            next;
        }

        my $count = 0;
        my $pPrev = 0;

        while ($pPrev = CertEnumCertificatesInStore($hCertStore, $pPrev)) {
            my $certName = " " x 256;
            my $length = CertGetNameStringA($pPrev, CERT_NAME_SIMPLE_DISPLAY_TYPE, 0, 0, $certName, 256);
            # Buffer includes null char at the end, skip on empty certificate name
            next unless $length > 1;
            $certName = trimWhitespace(substr($certName, 0, $length-1));
            my $buffer = Win32::API::ReadMemory($pPrev, 3*16);
            if (empty($buffer)) {
                $logger->debug(_log_prefix."Failed to copy CERT_CONTEXT ($count) for '$certName' certificate")
                    if $logger;
                next;
            }
            my ($dwCertEncodingType, $pbCertEncoded, $cbCertEncoded) = unpack("Q*", $buffer);
            next unless $dwCertEncodingType && $dwCertEncodingType == X509_ASN_ENCODING;
            unless ($pbCertEncoded && $cbCertEncoded) {
                $logger->debug(_log_prefix."Got wrong CERT_CONTEXT copy ($count) for '$certName' certificate")
                    if $logger;
                next;
            }
            my $certbuffer = Win32::API::ReadMemory($pbCertEncoded, $cbCertEncoded);
            if (empty($certbuffer)) {
                $logger->debug(_log_prefix."Failed to copy '$certName' certificate content ($count)")
                    if $logger;
                next;
            }
            my $bio = Net::SSLeay::BIO_new(Net::SSLeay::BIO_s_mem());
            my $rv = Net::SSLeay::BIO_write($bio, $certbuffer);
            unless ($rv == $cbCertEncoded) {
                $logger->debug(_log_prefix."Failed to import '$certName' certificate content ($count)")
                    if $logger;
                Net::SSLeay::BIO_free($bio);
                next;
            }

            my $cert = Net::SSLeay::d2i_X509_bio($bio);
            Net::SSLeay::BIO_free($bio);
             # On error, just skip it and log errors for diagnostic if required
            unless ($cert) {
               # Drop all errors before continuing to next Net::SSLeay call will fail
                while (my $rv = Net::SSLeay::ERR_get_error()) {
                    $logger->debug2(_log_prefix."Failed to import '$certName' certificate content: ".Net::SSLeay::ERR_error_string($rv))
                        if $logger;
                }
                $logger->debug(_log_prefix."$store-$count: '$certName' certificate skipped on import error")
                    if $logger;
                next;
            }

            $logger->debug(_log_prefix."$store-$count: Importing '$certName'")
                if $logger;

            push @certs, $cert;
            $count++;
        }

        unless (CertCloseStore($hCertStore, 0)) {
            $logger->debug(_log_prefix."Failed to close $store keystore")
                if $logger;
        }

        $logger->debug(_log_prefix."No certificate found in $store keystore")
            if !$count && $logger && @stores == 1;

        if ($count) {
            $certs{$store} = shared_clone(\@certs);
        }

        $total += $count;
    }

    $logger->debug(_log_prefix."No certificate found in (@stores) keystores")
        if !$total && $logger && @stores > 1;

    # Now we can update expiration
    $expiration = time + ($params{expiration} // 3600);

    # Release any thread which eventually tried to run loading concurrently
    $loadingSemaphore->up();
}

sub loadDefaultCaFile {
    my ($self, %params) = @_;

    # Only one thread should load any CA keystore at a time
    return unless $loadingSemaphore->down_timed(10);

    lock(%locked);

    # Continue to use current default ca store if still used by other threads
    return if $locked > 1;

    return unless $params{file};

    # Keep current loaded keyStore if not expired
    return if ref($certs{"Mozilla::CA"}) eq "ARRAY" && $expiration && time < $expiration;

    return unless -s $params{file};

    my @certs;

    my $bio = Net::SSLeay::BIO_new_file($params{file}, 'r')
        or return;

    while (my $cert = Net::SSLeay::PEM_read_bio_X509($bio)) {
        push @certs, $cert;
    }
    Net::SSLeay::BIO_free($bio);

    # Don't forget to free previously loaded default CAs before storing
    if ($certs{"Mozilla::CA"}) {
        my $certs = delete $certs{"Mozilla::CA"};
        Net::SSLeay::X509_free($_) for @{$certs};
    }

    $certs{"Mozilla::CA"} = shared_clone(\@certs);
}

sub getCAs {
    my ($self) = @_;

    lock(%locked);

    my @loaded = grep { ref($certs{$_}) eq "ARRAY" } @{$self->{supported}};
    return [ map { @{$certs{$_}} } @loaded ];
}

sub getNewClientUid {
    my ($self) = @_;

    lock(%locked);

    my $uid;
    while (!$uid || exists($locked{$uid})) {
        $uid = join('', map { sprintf("%02X", int(rand(256))) } 1..4);
    }

    # Register new uid as not locked client
    $locked{$uid} = 0;
    $tid{$uid} = &_tid;

    return $uid;
}

sub lockKeyStore {
    my ($self, $uid) = @_;

    lock(%locked);

    # Update locking variables
    $locked{$uid} = 1;
    $locked = scalar(grep { $_ } values(%locked));
}

sub unlockKeyStore {
    my ($self, $uid) = @_;

    lock(%locked);

    # Update locking variables
    delete $locked{$uid};
    $locked = scalar(grep { $_ } values(%locked));

    my $tid = &_tid;
    return unless $tid{$uid} && $tid{$uid} == $tid;
    delete $tid{$uid};

    # Check if it's time to free keyStore datas
    if (!$locked && $expiration && $expiration <= time) {
        foreach my $key (keys(%certs)) {
            next unless ref($certs{$key}) eq "ARRAY";
            Net::SSLeay::X509_free($_) for @{$certs{$key}};
        }
    }
}

my $_GetCurrentThreadId = Win32::API::More->Import(
    kernel32 => 'GetCurrentThreadId', '', 'I'
);

sub _tid {
    return GetCurrentThreadId();
}

sub END {
    eval {
        lock(%locked);
        return if $locked || scalar(values(%tid));

        my @stores = keys(%certs);
        foreach my $key (@stores) {
            my $store = delete $certs{$key};
            next unless ref($store) eq "ARRAY";
            Net::SSLeay::X509_free($_) for @{$store};
        }
    };
}

1;
