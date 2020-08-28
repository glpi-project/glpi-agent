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

    $self->{_winrm} = FusionInventory::Agent::SOAP::WsMan->new(
        url     => $url->as_string,
        config  => $self->config(),
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

package
    URI::winrm;

use strict;
use warnings;

use parent 'URI::http';

sub default_port {
    my ($self) = @_;
    my $modessl = $self->query() && $self->query() =~ /mode=ssl/i;
    return $modessl ? 5986 : 5985;
}

1;
