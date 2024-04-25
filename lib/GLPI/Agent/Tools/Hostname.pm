package GLPI::Agent::Tools::Hostname;

use strict;
use warnings;
use parent 'Exporter';

use UNIVERSAL::require();
use Encode;
use English qw(-no_match_vars);

our @EXPORT = qw(
    getHostname
    getRemoteFqdn
    getRemoteHostdomain
);

use GLPI::Agent::Tools;

BEGIN {
    if ($OSNAME eq 'MSWin32') {
        no warnings 'redefine'; ## no critic (ProhibitNoWarnings)
        Win32::API->require();
        # Kernel32.dll is used more or less everywhere.
        # Without this, Win32::API will release the DLL even
        # if it's a very bad idea
        *Win32::API::DESTROY = sub {};
    }
}

sub getHostname {
    my (%params) = @_;

    my $hostname;

    my $remote = $GLPI::Agent::Tools::remote;
    if ($remote) {
        if ($params{fqdn}) {
            $hostname = $remote->getRemoteFQDN()
                and $hostname =~ s/\.$//;  # the module may return a trailing dot
        }
        # Fallback on getgetRemoteHostname if fqdn was requested and failed
        $hostname = $remote->getRemoteHostname()
            if empty($hostname);
    } else {
        $hostname = $OSNAME eq 'MSWin32' ? _getHostnameWindows() : _getHostnameUnix(%params);
    }

    # Support assetname-support = 1 option
    if ($params{short}) {
        $hostname =~ s/\..*$//;
    }

    return $hostname;
}

sub _getHostnameUnix {
    my (%params) = @_;

    my $hostname;

    if ($params{fqdn}) {
        Net::Domain->require();
        my $fqdn = Net::Domain::hostfqdn();
        unless (empty($fqdn)) {
            $fqdn =~ s/\.$//;  # the module may return a trailing dot
            $hostname = $fqdn;
        }
    } else {
        Sys::Hostname->require();
        $hostname = Sys::Hostname::hostname();
    }

    return $hostname;
}

sub _getHostnameWindows {
    my $getComputerName = Win32::API->new(
        "kernel32", "GetComputerNameExW", ["I", "P", "P"], "N"
    );
    my $buffer = "\x00" x 1024;
    my $n = 1024; #pack ("c4", 160,0,0,0);

    $getComputerName->Call(3, $buffer, $n);

    # convert from UTF16 to UTF8
    my $hostname = substr(decode("UCS-2le", $buffer), 0, ord $n);

    return $hostname || $ENV{COMPUTERNAME};
}

sub getRemoteFqdn {
    my $remote = $GLPI::Agent::Tools::remote;
    return $remote->getRemoteFQDN() if $remote;
}

sub getRemoteHostdomain {
    my $remote = $GLPI::Agent::Tools::remote;
    return $remote->getRemoteHostDomain() if $remote;
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::Hostname - OS-independent hostname computing

=head1 DESCRIPTION

This module provides a generic function to retrieve host name

=head1 FUNCTIONS

=head2 getHostname()

Returns the host name.
