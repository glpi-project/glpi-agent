package GLPI::Agent::Task::RemoteInventory::Remote::Winrm;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use parent 'GLPI::Agent::Task::RemoteInventory::Remote';

use URI;

use GLPI::Agent::Tools;
use GLPI::Agent::SOAP::WsMan;

use constant    supported => 1;

use constant    supported_modes => qw(ssl);

sub handle_url {
    my ($self, $url) = @_;

    my $scheme = $self->mode('ssl') ? "https" : "http";
    $url->scheme($scheme);
    bless $url, "URI::$scheme";

    if ($self->mode('ssl')) {
        $url->port(5986) if $url->port == 443;
    } else {
        $url->port(5985) if $url->port == 80;
    }

    $self->SUPER::handle_url($url);

    # We need to translate url for LWP::UserAgent client
    $url->path( "/wsman/" ) unless $url->path && $url->path ne '/';
    # Remove query in the case it contains mode=ssl
    $url->query_keywords([]);
    # Reset user/pass from URL as they are passed for UA as params
    $url->userinfo(undef);

    # Keep canonical URL for prepare API
    $self->{_canonical_url} = $url->canonical->as_string;
}

sub prepare {
    my ($self) = @_;

    $self->{_winrm} = GLPI::Agent::SOAP::WsMan->new(
        logger      => $self->{logger},
        config      => $self->config(),
        url         => $self->{_canonical_url},
        user        => $self->user(),
        password    => $self->pass(),
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

    my $deviceid = $self->getRemoteRegistryValue(
        path => 'HKEY_LOCAL_MACHINE/Software/GLPI-Agent/Remote/deviceid',
    );
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
        $shell = $self->{_winrm}->shell($params{command}." 2>nul");
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

    my @cs = $self->{_winrm}->enumerate(class => "Win32_ComputerSystem");
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

sub remoteGetNextUser {
    # GetNextUser not supported as not used for MSWin32 inventory
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

my %REGMETHODVALUENAME = qw(
    GetStringValue          sValue
    GetExpandedStringValue  sValue
    GetMultiStringValue     sValue
    GetBinaryValue          uValue
    GetDWORDValue           uValue
    GetQWORDValue           uValue
);

my %METHODBYTYPE = qw(
    1   GetStringValue
    2   GetExpandedStringValue
    3   GetBinaryValue
    4   GetDWORDValue
    7   GetMultiStringValue
    11  GetQWORDValue
);

sub getRemoteRegistryValue {
    my ($self, %params) = @_;

    my $method = $params{method} // "GetStringValue";
    my $valuename = $REGMETHODVALUENAME{$method}
        or return;

    my $result = $self->{_winrm}->runmethod(
        class   => "StdRegProv",
        moniker => "root/default",
        method  => $method,
        path    => $params{path},
        params  => [ $valuename, "ReturnValue" ],
        binds   => {
            ReturnValue => "exitcode",
            $valuename  => "value",
        },
        # Don't pollute debug2 too much
        nodebug => $params{nodebug} // 0,
    );

    return unless $result && delete $result->{exitcode} == 0 && defined($result->{value});

    return $result->{value};
}

sub getRemoteRegistryKey {
    my ($self, %params) = @_;

    my $hash = {};

    # Keep a safe maxdepth for recursive calls if not defined
    $params{maxdepth} = 10 unless defined($params{maxdepth});

    # First we enumerate registry key values
    my $values = $self->{_winrm}->runmethod(
        class   => "StdRegProv",
        moniker => "root/default",
        method  => "EnumValues",
        path    => $params{path},
        params  => [ "sNames", "Types", "ReturnValue" ],
        binds   => {
            ReturnValue => "exitcode",
            sNames      => "values",
            Types       => "types",
        },
        # Don't pollute debug2 too much
        nodebug => $params{nodebug} // 1,
    );

    if ($values && $values->{exitcode} == 0 && $values->{values}) {
        my $keys  = $values->{values};
        my $types = $values->{types};
        $types = [] unless ref($types) eq 'ARRAY';

        if ($keys && ref($keys) eq 'ARRAY') {
            foreach my $key (@{$keys}) {
                my $type = shift @{$types};
                # We don't care about default and unsupported value types
                next unless length($key) && $type && $METHODBYTYPE{$type};
                # Use required values to optimize registry key tree reading
                next unless !$params{required} || first { $key eq $_ } @{$params{required}};
                $hash->{"/$key"} = $self->getRemoteRegistryValue(
                    %params,
                    path    => "$params{path}/$key",
                    method  => $METHODBYTYPE{$type},
                    # Don't pollute debug2 too much
                    nodebug => $params{nodebug} // 1,
                );
            }
        }
    }

    # Handle maxdepth optimization
    return $hash unless $params{maxdepth}-- > 0;

    # Then we recursively scan other keys
    my $subkeys = $self->{_winrm}->runmethod(
        class   => "StdRegProv",
        moniker => "root/default",
        method  => "EnumKey",
        path    => $params{path},
        params  => [ "sNames", "ReturnValue" ],
        binds   => {
            ReturnValue => "exitcode",
            sNames      => "keys",
        },
        # Don't pollute debug2 too much
        nodebug => $params{nodebug} // 0,
    );

    if ($subkeys && $subkeys->{exitcode} == 0 && $subkeys->{keys} && ref($subkeys->{keys}) eq 'ARRAY') {
        foreach my $key (@{$subkeys->{keys}}) {
            # We can be asked to skip keys for remote inventory optimization
            $hash->{"$key/"} = $self->getRemoteRegistryKey(
                %params,
                path    => $params{path}."/$key",
                # Don't pollute debug2 too much
                nodebug => $params{nodebug} // 1,
            );
        }
    }

    return $hash;
}

sub getWMIObjects {
    my ($self, %params) = @_;

    my $altmoniker = delete $params{altmoniker};

    my @objects = $self->{_winrm}->enumerate(%params);

    # Try altmoniker when present
    if (!@objects && $altmoniker) {
        $params{moniker} = $altmoniker;
        @objects = $self->{_winrm}->enumerate(%params);
    }

    return @objects;
}

sub loadRemoteUserHive {
    my ($self, %params) = @_;

    # First test if we really need to load the hive
    my $userhive = 'HKEY_USERS/'.$params{sid};
    my $registry = $self->getRemoteRegistryKey(
        path        => $userhive,
        maxdepth    => 1,
    );
    return if $registry && keys(%{$registry});

    # Launch reg command to load the hive for the user
    $userhive =~ s|/|\\|g;
    $self->{logger}->debug("Loading $userhive registry");
    my $regload = $self->{_winrm}->shell("reg load $userhive \"$params{file}\"");
    unless ($regload && $regload->{exitcode} == 0) {
        $self->{logger}->debug("Failed to load $userhive registry");
        return;
    }

    push @{$self->{_loadedhives}}, $userhive;
}

sub unloadRemoteLoadedUserHives {
    my ($self) = @_;

    return unless $self->{_loadedhives};

    foreach my $userhive (@{$self->{_loadedhives}}) {
        my $unload = $self->{_winrm}->shell("reg unload $userhive");
        $self->{logger}->debug("Failed to unload $userhive registry")
            unless $unload && $unload->{exitcode} == 0;
    }
}

1;
