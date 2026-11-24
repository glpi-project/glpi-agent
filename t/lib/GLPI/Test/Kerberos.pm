package GLPI::Test::Kerberos;

# Throwaway MIT Kerberos realm for tests
#
# This helper reproduces what an administrator does to get a working Kerberos
# client environment, but in a temporary folder and without root privileges:
#
#  1. write a krb5.conf (client side) and a kdc.conf (KDC side) and point the
#     Kerberos libraries to them with KRB5_CONFIG & KRB5_KDC_PROFILE,
#  2. create the KDC database (kdb5_util create),
#  3. create the principals (kadmin.local addprinc): one client principal for
#     the agent and one HTTP/<host> service principal per emulated WinRM
#     server. In an Active Directory domain, the KDC is the domain controller,
#     the client principal is a user or the computer account and the
#     computer account of the Windows host is registered with HOST/<fqdn>
#     service principals, the KDC maps HTTP/<fqdn> to them (sPNMappings),
#  4. export principal keys to keytabs (kadmin.local ktadd): the service
#     keytab is used by the emulated WinRM server to accept tokens, a Windows
#     host derives the same keys from its computer account secret, the client
#     keytab can be used by the agent to get its ticket without password,
#  5. start the KDC (krb5kdc) on a random local port,
#  6. get a Ticket Granting Ticket in a credentials cache with
#     "kinit -k -t client.keytab", exactly like an administrator would do with
#     "kinit user@REALM" and a password. KRB5CCNAME is set to this cache.
#
# After that, any GSSAPI client running in the test process finds its ticket
# in the credentials cache, like the agent does in real life.
#
# Unlike the MIT Kerberos default configuration, host name canonicalization
# with DNS is disabled (dns_canonicalize_hostname & rdns) so tests don't depend
# on the test system DNS setup.

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Temp qw(tempdir);
use File::Spec;
use IO::Socket::INET;
use MIME::Base64;
use POSIX ":sys_wait_h";

my @PATHS = (File::Spec->path(), qw(/usr/sbin /usr/local/sbin /sbin /usr/lib/mit/sbin));

sub _which {
    my ($binary) = @_;
    foreach my $path (@PATHS) {
        my $file = File::Spec->catfile($path, $binary);
        return $file if -x $file;
    }
    return;
}

# Return a reason why a test realm can't be set up, or undef if it can
sub unavailable {
    return "not supported on Windows" if $OSNAME eq 'MSWin32';
    eval { require GSSAPI; 1 }
        or return "GSSAPI perl module not available";
    foreach my $binary (qw(kdb5_util kadmin.local krb5kdc kinit klist)) {
        return "MIT Kerberos $binary command not found (install krb5-kdc, krb5-admin-server & krb5-user)"
            unless _which($binary);
    }
    return;
}

sub new {
    my ($class, %params) = @_;

    require GSSAPI;

    my $self = bless {
        realm    => $params{realm}    // 'GLPI.TEST',
        client   => $params{client}   // 'glpi-agent',
        services => $params{services} // [],
        dir      => tempdir(CLEANUP => 1),
        _env     => {},
        _owner   => $PID,
    }, $class;

    $self->{$_} = _which($_) foreach qw(kdb5_util kadmin.local krb5kdc kinit klist);

    $self->_configure();
    $self->_create_database();
    $self->_start_kdc();
    $self->kinit();

    return $self;
}

sub realm  { $_[0]->{realm} }
sub dir    { $_[0]->{dir} }
sub client { $_[0]->{client}.'@'.$_[0]->{realm} }

sub file {
    my ($self, $name) = @_;
    return File::Spec->catfile($self->{dir}, $name);
}

# Keytab containing the client principal key
sub client_keytab  { $_[0]->file('client.keytab') }

# Keytab containing all the service principals keys
sub service_keytab { $_[0]->file('service.keytab') }

# Credentials cache initialized by kinit
sub ccache         { 'FILE:'.$_[0]->file('ccache') }

sub _setenv {
    my ($self, $name, $value) = @_;
    $self->{_env}->{$name} = $ENV{$name} unless exists($self->{_env}->{$name});
    $ENV{$name} = $value;
}

sub _free_port {
    my $socket = IO::Socket::INET->new(
        LocalAddr   => '127.0.0.1',
        LocalPort   => 0,
        Proto       => 'tcp',
        Listen      => 1,
        ReuseAddr   => 1,
    ) or die "Can't find a free port: $EVAL_ERROR\n";
    my $port = $socket->sockport();
    close($socket);
    return $port;
}

sub _write {
    my ($self, $name, $content) = @_;
    my $file = $self->file($name);
    open(my $fh, '>', $file) or die "Can't write $file: $ERRNO\n";
    print $fh $content;
    close($fh);
    return $file;
}

sub _configure {
    my ($self) = @_;

    my $realm = $self->{realm};
    my $dir   = $self->{dir};
    $self->{port} = _free_port();

    # Client configuration: only use our KDC, never rely on DNS, and use TCP
    # to talk with the KDC. dns_canonicalize_hostname & rdns are disabled so
    # the service principal is built from the host name as given, which is
    # also what the agent expects as it resolves IPs to FQDN by itself.
    my $krb5_conf = $self->_write('krb5.conf', <<"EOF");
[libdefaults]
    default_realm = $realm
    dns_lookup_kdc = false
    dns_lookup_realm = false
    dns_canonicalize_hostname = false
    rdns = false
    udp_preference_limit = 1
    ticket_lifetime = 1h

[realms]
    $realm = {
        kdc = 127.0.0.1:$self->{port}
    }

[domain_realm]
    localhost = $realm
    .glpi.test = $realm
    glpi.test = $realm
EOF

    my $kdc_conf = $self->_write('kdc.conf', <<"EOF");
[kdcdefaults]
    kdc_listen = 127.0.0.1:$self->{port}
    kdc_tcp_listen = 127.0.0.1:$self->{port}

[realms]
    $realm = {
        database_name = $dir/principal
        key_stash_file = $dir/stash
        acl_file = $dir/kadm5.acl
        max_life = 1h
        supported_enctypes = aes256-cts-hmac-sha1-96:normal aes128-cts-hmac-sha1-96:normal
    }

[logging]
    kdc = FILE:$dir/kdc.log
    admin_server = FILE:$dir/kadmin.log
    default = FILE:$dir/krb5.log
EOF
    $self->_write('kadm5.acl', '');

    $self->_setenv(KRB5_CONFIG      => $krb5_conf);
    $self->_setenv(KRB5_KDC_PROFILE => $kdc_conf);
    # Acceptor (server) side keytab used by GSSAPI accept_sec_context
    $self->_setenv(KRB5_KTNAME      => 'FILE:'.$self->service_keytab);
    # Client side credentials cache
    $self->_setenv(KRB5CCNAME       => $self->ccache);
    # Keep acceptor replay cache in our folder
    $self->_setenv(KRB5RCACHEDIR    => $dir);
    # Don't let a client keytab from environment interfere
    $self->_setenv(KRB5_CLIENT_KTNAME => 'FILE:'.$self->file('none.keytab'));
}

sub _run {
    my ($self, @command) = @_;
    my $log = $self->file('commands.log');
    my $command = join(' ', map { "'$_'" } @command);
    system("$command >>'$log' 2>&1") == 0
        or die "Command failed: $command, see $log\n";
}

sub _kadmin {
    my ($self, $query) = @_;
    $self->_run($self->{'kadmin.local'}, '-r', $self->{realm}, '-q', $query);
}

sub _create_database {
    my ($self) = @_;

    $self->_run($self->{kdb5_util}, '-r', $self->{realm}, '-P', 'test-master-key', 'create', '-s');

    # -randkey: principals get a random key, nobody needs to know a password
    $self->_kadmin("addprinc -randkey $self->{client}");
    $self->_kadmin("ktadd -k ".$self->client_keytab." $self->{client}");
    $self->add_service($_) foreach @{$self->{services}};
}

# Add a service principal like HTTP/winrm.glpi.test and export its key
# in the service keytab
sub add_service {
    my ($self, $service) = @_;
    $self->_kadmin("addprinc -randkey $service");
    $self->_kadmin("ktadd -k ".$self->service_keytab." $service");
}

sub _start_kdc {
    my ($self) = @_;

    my $pid = fork();
    die "Can't fork: $ERRNO\n" unless defined($pid);
    unless ($pid) {
        open(STDOUT, '>>', $self->file('kdc.out'));
        open(STDERR, '>&', \*STDOUT);
        # -n: don't detach so we can stop it with our pid
        { exec($self->{krb5kdc}, '-n', '-r', $self->{realm}) };
        POSIX::_exit(1);
    }
    $self->{_kdc_pid} = $pid;
}

# Get a TGT for the client principal from its keytab in the credentials cache
sub kinit {
    my ($self) = @_;

    my $log = $self->file('commands.log');
    my $command = join(' ', map { "'$_'" }
        $self->{kinit}, '-k', '-t', $self->client_keytab, '-c', $self->ccache, $self->client);

    # Retry while the KDC is starting
    foreach (1..50) {
        return if system("$command >>'$log' 2>&1") == 0;
        die "KDC failed to start, see ".$self->file('kdc.out')."\n"
            if waitpid($self->{_kdc_pid}, WNOHANG) > 0;
        select(undef, undef, undef, 0.2);
    }
    die "kinit failed, see $log\n";
}

# List principals of the tickets found in a credentials cache with klist, the
# TGT is listed as krbtgt/REALM@REALM
sub tickets {
    my ($self, $ccache) = @_;

    $ccache //= $self->ccache;
    open(my $klist, '-|', "'$self->{klist}' -c '$ccache' 2>/dev/null")
        or return;
    my @tickets;
    while (my $line = <$klist>) {
        next if $line =~ /^(Ticket cache|Default principal|Valid starting)/;
        push @tickets, $1 if $line =~ /\s(\S+\@\S+)\s*$/;
    }
    close($klist);

    return @tickets;
}

# Server side of the authentication, as done by the WinRM service of a Windows
# host: accept the base64 token received in "Authorization: Negotiate <token>"
# header using the service key found in the keytab set in KRB5_KTNAME. On
# success, return the authenticated client principal and the base64 token to
# send back in "WWW-Authenticate: Negotiate <token>" header so the client can
# verify the server identity (mutual authentication).
sub accept_token {
    my ($token) = @_;

    require GSSAPI;

    my ($context, $client, $otoken);
    my $status = GSSAPI::Context::accept(
        $context,                               # new context created on first call
        GSSAPI::GSS_C_NO_CREDENTIAL(),          # use any key from KRB5_KTNAME keytab
        MIME::Base64::decode_base64($token),
        GSSAPI::GSS_C_NO_CHANNEL_BINDINGS(),
        $client,                                # authenticated client name
        undef,                                  # mechanism, not needed
        $otoken,                                # mutual authentication token
        undef, undef, undef,                    # flags, time & delegated credentials
    );

    return unless $status && $status->major() == GSSAPI::GSS_S_COMPLETE();

    my $name;
    $client->display($name);

    return ($name, MIME::Base64::encode_base64($otoken // '', ''));
}

sub stop {
    my ($self) = @_;

    # Only the process which started the KDC can stop it, not a forked child
    # like a test server
    return unless $self->{_owner} == $PID;

    if (my $pid = delete $self->{_kdc_pid}) {
        kill 'TERM', $pid;
        waitpid($pid, 0);
    }

    foreach my $name (keys(%{$self->{_env}})) {
        if (defined($self->{_env}->{$name})) {
            $ENV{$name} = $self->{_env}->{$name};
        } else {
            delete $ENV{$name};
        }
    }
    $self->{_env} = {};
}

sub DESTROY {
    my ($self) = @_;
    $self->stop() if $self->{_kdc_pid};
}

1;
