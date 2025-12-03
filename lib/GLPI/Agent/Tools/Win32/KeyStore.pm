package GLPI::Agent::Tools::Win32::KeyStore;

use strict;
use warnings;

use parent 'Exporter';

use UNIVERSAL::require();
use English qw(-no_match_vars);

BEGIN {
    # Only set if you're a developer and need to debug Win32::API usage
    $Win32::API::DEBUG = 0;
}

use Net::SSLeay;

Win32::API->require();

use GLPI::Agent::Tools;

use constant    CERT_NAME_SIMPLE_DISPLAY_TYPE   => 4;
use constant    X509_ASN_ENCODING               => 1;

use constant    _log_prefix                     => "[ssl-keystore] ";

our @EXPORT = qw(
    getKeyStore
);

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

sub getKeyStore {
    my (%params) = @_;

    my $logger = $params{logger};

    my @stores = $params{store} ? ($params{store}) : qw(
        ROOT
        CA
        TRUST
        MY
    );

    my @certs;

    foreach my $store (@stores) {

        next unless $store;

        my $hCertStore = CertOpenSystemStoreA(0, $store);
        unless ($hCertStore) {
            $logger->error(_log_prefix."Failed to open system $store keystore")
                if $logger;
            next;
        }

        my $count;
        my $pPrev = 0;

        while ($pPrev = CertEnumCertificatesInStore($hCertStore, $pPrev)) {
            $count++;
            my $certName = " " x 256;
            my $length = CertGetNameStringA($pPrev, CERT_NAME_SIMPLE_DISPLAY_TYPE, 0, 0, $certName, 256);
            if ($length) {
                $certName = trimWhitespace($certName);
                $logger->debug(_log_prefix."$store-$count: Importing $certName")
                    if $logger;
            }
            my $buffer = Win32::API::ReadMemory($pPrev, 3*16);
            if (empty($buffer)) {
                $logger->debug(_log_prefix."Failed to copy CERT_CONTEXT ($count)")
                    if $logger;
                next;
            }
            my ($dwCertEncodingType, $pbCertEncoded, $cbCertEncoded) = unpack("Q*", $buffer);
            next unless $dwCertEncodingType && $dwCertEncodingType == X509_ASN_ENCODING;
            unless ($pbCertEncoded && $cbCertEncoded) {
                $logger->debug(_log_prefix."Got wrong CERT_CONTEXT copy ($count)")
                    if $logger;
                next;
            }
            my $certbuffer = Win32::API::ReadMemory($pbCertEncoded, $cbCertEncoded);
            if (empty($certbuffer)) {
                $logger->debug(_log_prefix."Failed to copy certificate content ($count)")
                    if $logger;
                next;
            }
            my $bio = Net::SSLeay::BIO_new(Net::SSLeay::BIO_s_mem());
            my $rv = Net::SSLeay::BIO_write($bio, $certbuffer);
            unless ($rv == $cbCertEncoded) {
                $logger->debug(_log_prefix."Failed to import certificate content ($count)")
                    if $logger;
                Net::SSLeay::BIO_free($bio) if $rv > 0;
                next;
            }
            my $cert = Net::SSLeay::d2i_X509_bio($bio);
            Net::SSLeay::BIO_free($bio);
            push @certs, $cert;
        }

        unless (CertCloseStore($hCertStore, 0)) {
            $logger->debug(_log_prefix."Failed to close $store keystore")
                if $logger;
        }

        $logger->debug(_log_prefix."No certificate found in $store keystore")
            if !$count  && $logger && @stores == 1;
    }

    return @certs;
}

1;
