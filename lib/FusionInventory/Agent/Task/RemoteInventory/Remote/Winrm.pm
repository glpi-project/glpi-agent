package FusionInventory::Agent::Task::RemoteInventory::Remote::Winrm;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use parent 'FusionInventory::Agent::Task::RemoteInventory::Remote';

use URI;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::SOAP::WsMan;

use constant    supported => 1;

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
        logger      => $self->{logger},
        url         => $url->canonical->as_string,
        user        => $self->{_user} || $ENV{USERNAME},
        password    => $self->{_pass} || $ENV{PASSWORD},
        winrm       => 1,
    );
}

sub checking_error {
    my ($self) = @_;

    my $identify = $self->{_winrm}->identify();
    return "Winrm identify request failure: ".$self->{_winrm}->lasterror()
        unless $identify;

    my $vendor = $identify->ProductVendor;
    return "Winrm not supported on WsMan backend"
        unless $vendor =~ /microsoft/i;

    my $deviceid = $self->getRemoteRegistryValue(path => 'HKLM/Software/GLPI-Agent/Remote/deviceid');
    if ($deviceid) {
        $self->deviceid(deviceid => $deviceid);
    } else {
        my $hostname = $self->getRemoteHostname()
            or return "Can't retrieve remote hostname";
        $deviceid = $self->deviceid(hostname => $hostname)
            or return "Can't compute deviceid getting remote hostname";
        $self->{logger}->debug2("Registering $deviceid as remote deviceid");
        $self->remoteStoreDeviceid(
            path        => 'HKLM/Software/GLPI-Agent/Remote/deviceid',
            deviceid    => $deviceid,
        )
            or return "Can't store deviceid on remote";
    }

    return '';
}

sub getRemoteFileHandle {
    my ($self, %params) = @_;

    my ($handle, $shell);

    # Still run command via WinRM and return an in-memory scalar handle
    if ($params{command}) {
        $shell = $self->{_winrm}->shell($params{command});
    } elsif ($params{file}) {
        $params{file} =~ s|/|\\|g;
        $shell = $self->{_winrm}->shell("type \"$params{file}\"");
    }

    # open directive needs a scalar ref to create an in-memory scalar handle
    defined($shell) and open $handle, "<", $shell->{stdout};

    return $handle;
}

sub remoteCanRun {
    my ($self, $binary) = @_;

    # Still return when looking for command with unix standard path
    return 0 if $binary =~ m{^(/usr)?/(s?bin|Library)/};

    # Support where argument synatx with a path set
    if ($binary =~ m|(.*)[\\/]([^\\/]+)$|) {
        $binary = "$1:$2";
        $binary =~ s|/|\\|g;
    }

    my $where = $self->{_winrm}->shell("where /q \"$binary\"");

    return ($where && $where->{exitcode} == 0) ? 1 : 0;
}

sub OSName {
    return 'MSWin32';
}

sub remoteGlob {
    my ($self, $glob) = @_;

    my $dirglob = $self->{_winrm}->shell("dir /b \"$glob\"");

    return unless $dirglob && $dirglob->{exitcode} == 0 && $dirglob->{stdout};

    my $stdout = ${$dirglob->{stdout}} or return;

    return grep { length($_) } split(qr|\r\n|m, $stdout);
}

sub _getComputerSystem {
    my ($self) = @_;

    return $self->{_cs} if $self->{_cs};

    my $res_url = "http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/Win32_ComputerSystem";
    my @cs = $self->{_winrm}->enumerate($res_url);
    unless (@cs == 1) {
        $self->{logger}->error("Winrm: Failed to request Win32_ComputerSystem: ".$self->{_winrm}->lasterror);
        return;
    }

    return $self->{_cs} = shift @cs;
}

sub getRemoteHostname {
    my ($self) = @_;

    my $computersystem = $self->_getComputerSystem()
        or return;

    my $hostname = $computersystem->{DNSHostName} || $computersystem->{Name};
    $self->{logger}->error("Winrm: Failed to get remote hostname from Win32_ComputerSystem")
        unless $hostname;

    return $hostname;
}

sub getRemoteFQDN {
    my ($self) = @_;

    my $computersystem = $self->_getComputerSystem()
        or return;

    my $fqdn = $computersystem->{DNSHostName} || $computersystem->{Name};
    $self->{logger}->error("Winrm: Failed to get remote hostname from Win32_ComputerSystem")
        unless $fqdn;
    $fqdn .= "." . $computersystem->{Domain} if $computersystem->{Domain};

    return $fqdn;
}

sub getRemoteHostDomain {
    my ($self) = @_;

    my $computersystem = $self->_getComputerSystem()
        or return;

    my $hostdomain = $computersystem->{Domain};
    $self->{logger}->error("Winrm: Failed to get remote domain from Win32_ComputerSystem")
        unless $hostdomain;

    return $hostdomain;
}

sub remoteTestFolder {
    my ($self, $folder) = @_;

    $folder =~ s|/|\\|g;
    $folder =~ s|\\*$||;

    my $exist = $self->{_winrm}->shell("if exist \"$folder\\\" echo yes");

    my $ret = $exist->{stdout} && ${$exist->{stdout}} || "no";

    return $ret =~ /^yes/ ? 1 : 0 ;
}

sub remoteTestFile {
    my ($self, $file) = @_;

    $file =~ s|/|\\|g;

    my $exist = $self->{_winrm}->shell("if exist \"$file\" echo yes");

    my $ret = $exist->{stdout} && ${$exist->{stdout}} || "no";

    return $ret =~ /^yes/ ? 1 : 0 ;
}

sub remoteTestLink {
    # TestLink not supported and not used for MSWin32 inventory
}

sub remoteFileStat {
    # FileStat not supported as not used for MSWin32 inventory
}

sub remoteReadLink {
    # ReadLink not supported as not used for MSWin32 inventory
}

sub remoteGetPwEnt {
    # GetPwEnt not supported as not used for MSWin32 inventory
}

sub winrm_url {
    my ($self) = @_;

    return $self->{_winrm}->url() if $self->{_winrm};
}

sub remoteStoreDeviceid {
    my ($self, %params) = @_;

    $params{path} =~ s|/|\\|g;

    my ($path, $value) = $params{path} =~ /^(.*)\\([^\\]+)$/;

    my $regexec = $self->{_winrm}->shell("reg add $path /t REG_SZ /f /v $value /d $params{deviceid}");

    return unless $regexec && $regexec->{exitcode} == 0;

    return 1;
}

sub getRemoteRegistryValue {
    my ($self, %params) = @_;

    $params{path} =~ s|/|\\|g;

    my ($path, $value) = $params{path} =~ /^(.*)\\([^\\]+)$/;

    my $regexec = $self->{_winrm}->shell("reg query $path /e /f $value");

    return unless $regexec && $regexec->{exitcode} == 0 && $regexec->{stdout};

    my $match;
    foreach my $line (split(qr|\r\n|m, ${$regexec->{stdout}})) {
        last if ($match) = $line =~ /^\s*$value\s+\w+\s+(.*)$/;
    }

    return $match;
}

sub getWMIObjects {
    my ($self, %params) = @_;

    if ($params{query} && $params{method}) {
        $self->{logger}->debug2("TODO: NOT SUPPORTED '$params{query}' query");
        return;
    }

    my $res_url = _resource_url($params{moniker}, $params{query} ? '*' : $params{class})
        or return;
    my @objects = $self->{_winrm}->enumerate($res_url, $params{query});

    # Try altmoniker when present
    if (!@objects && $params{altmoniker}) {
        $res_url = _resource_url($params{altmoniker}, $params{query} ? '*' : $params{class})
            or return;
        @objects = $self->{_winrm}->enumerate($res_url, $params{query});
    }

    return @objects;
}

sub _resource_url {
    my ($moniker, $class) = @_;

    my $path = "cimv2";

    if ($moniker) {
        $moniker =~ s/\\/\//g;
        ($path) = $moniker =~ m|root/(.*)$|;
        return unless $path;
        $path =~ s/\/*$//;
    }

    my $resource = lc("$path/$class");

    return "http://schemas.microsoft.com/wbem/wsman/1/wmi/root/$resource";
}

## no critic (ProhibitMultiplePackages)
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
