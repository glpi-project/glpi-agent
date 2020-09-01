package FusionInventory::Agent::Task::RemoteInventory::Remote::Winrm;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use parent 'FusionInventory::Agent::Task::RemoteInventory::Remote';

use URI;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::SOAP::WsMan;

sub init {
    my ($self) = @_;

    my $url = URI->new($self->url());

    # We need to translate url for LWP::UserAgent client
    my $port = $url->port;
    $url->scheme( $self->mode('ssl') ? "https" : "http" );
    # Reset port after changing scheme
    $url->port($port);
    $url->path( "/wsman/" ) unless $url->path && $url->path ne '/';
    # Remove query in the case it contains mode=ssl
    $url->query_keywords([]);
    # Reset user/pass from URL as they are passed for UA as params
    $url->userinfo(undef);

    $self->{_winrm} = FusionInventory::Agent::SOAP::WsMan->new(
        url         => $url->canonical->as_string,
        user        => $self->{_user} || $ENV{USERNAME},
        password    => $self->{_pass} || $ENV{PASSWORD},
        winrm       => 0,
    );
}

sub checking_error {
    my ($self) = @_;

    my $identify = $self->{_winrm}->identify();
    return "Winrm identify request failure: ".$self->{_winrm}->lasterror()
        unless $identify;

    my $vendor = $identify->get("ProductVendor");
    return "Winrm not supported on WsMan backend"
        unless $vendor =~ /microsoft/i;

    my $deviceid = $self->getRemoteRegistryValue(path => 'HKEY_LOCAL_MACHINE/Software/GLPI-Agent/Remote/deviceid');
    if ($deviceid) {
        $self->deviceid(deviceid => $deviceid);
    } else {
        my $hostname = $self->getRemoteHostname()
            or return "Can't retrieve remote hostname";
        $deviceid = $self->deviceid(hostname => $hostname)
            or return "Can't compute deviceid getting remote hostname";
        $self->getRemoteStoreDeviceid(
            path        => 'HKEY_LOCAL_MACHINE/Software/GLPI-Agent/Remote/deviceid',
            deviceid    => $deviceid,
        )
            or return "Can't store deviceid on remote";
    }

    return '';
}

sub getRemoteFileHandle {
    my ($self, %params) = @_;

    # TODO not implemented
}

sub remoteCanRun {
    my ($self, $binary) = @_;

    # TODO not implemented
}

sub OSName {
    return 'MSWin32';
}

sub remoteGlob {
    my ($self, $glob, $test) = @_;

    # TODO not implemented
}

sub getRemoteHostname {
    my ($self) = @_;

    # TODO not implemented
    return '';
}

sub getRemoteFQDN {
    my ($self) = @_;

    # TODO not implemented
}

sub getRemoteHostDomain {
    my ($self) = @_;

    # TODO not implemented
}

sub remoteTestFolder {
    my ($self, $folder) = @_;

    # TODO not implemented
}

sub remoteTestFile {
    my ($self, $file) = @_;

    # TODO not implemented
}

sub remoteTestLink {
    my ($self, $link) = @_;

    # TODO not implemented
}

# This API only need to return ctime & mtime
sub remoteFileStat {
    my ($self, $file) = @_;

    # TODO not implemented
}

sub remoteReadLink {
    my ($self, $link) = @_;

    # TODO not implemented
}

sub remoteGetPwEnt {
    my ($self) = @_;

    # TODO not implemented
}

sub winrm_url {
    my ($self) = @_;

    return $self->{_winrm}->url() if $self->{_winrm};
}

sub getRemoteStoreDeviceid {
    my ($self, %params) = @_;

    # TODO not implemented
    return 0;
}

sub getRemoteRegistryValue {
    my ($self, %params) = @_;

    # TODO not implemented
    return '';
}

package
    URI::winrm;

use strict;
use warnings;

use parent 'URI::http';

sub default_port {
    my ($self) = @_;
    my $modessl = $self->query() && $self->query() =~ /\bmode=ssl\b/i;
    return $modessl ? 5986 : 5985;
}

1;
