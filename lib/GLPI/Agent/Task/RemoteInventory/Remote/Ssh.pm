package GLPI::Agent::Task::RemoteInventory::Remote::Ssh;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use parent 'GLPI::Agent::Task::RemoteInventory::Remote';

use GLPI::Agent::Tools;

use constant    supported => 1;

use constant    supported_modes => qw(ssh libssh2 perl);

sub _ssh {
    my ($self, $command) = @_;
    return unless $command;
    my $options = "-q -o BatchMode=yes";
    $options .= " -p " . $self->port() if $self->port() && $self->port() != 22;
    $options .= " -l " . $self->user() if $self->user();
    return "ssh $options ".$self->host()." LANG=C $command";
}

sub disconnect {
    my ($self) = @_;

    if ($self->{_ssh2}) {
        $self->{_ssh2}->disconnect() if $self->{_ssh2}->sock;
        delete $self->{_ssh2};
        $self->{logger}->debug2("Disconnected from '".$self->host()."' remote host...");
    }
}

# APIs dedicated to Net::SSH2 support
sub _connect {
    my ($self) = @_;

    unless ($self->{_ssh2} || ($self->mode('ssh') && !$self->mode('libssh2'))) {
        Net::SSH2->require();
        unless ($EVAL_ERROR) {
            my $timeout = $self->config->{"backend-collect-timeout"} // 60;
            $self->{_ssh2} = Net::SSH2->new(timeout => $timeout * 1000);
            my $version = $self->{_ssh2}->version;
            $self->{logger}->debug2("Using libssh2 $version for ssh remote")
                if $self->{logger};
        }
    }

    my $ssh2 = $self->{_ssh2}
        or return 0;
    return 1 if defined($ssh2->sock);

    my $host = $self->host();
    my $port = $self->port();
    my $remote = $host . ($port && $port == 22 ? "" : ":$port");
    $self->{logger}->debug2("Connecting to '$remote' remote host...");
    if (!$ssh2->connect($host, $port // 22)) {
        my @error = $ssh2->error;
        $self->{logger}->debug("Can't reach $remote for ssh remoteinventory via libss2: @error");
        undef $self->{_ssh2};
        return;
    }

    # Use Trust On First Use policy to verify remote host
    $self->{logger}->debug2("Check remote host key...");
    if ($OSNAME eq 'MSWin32') {
        # On windows, use vardir as HOME to store known_hosts file
        my $home = $self->config->{vardir};
        $ENV{HOME} = $self->config->{vardir};
        my $dotssh = "$home/.ssh";
        mkdir $dotssh unless -d $dotssh;
        unless (-e "$dotssh/known_hosts") {
            # Create empty known_hosts
            my $fh;
            close($fh)
                if open $fh, ">", "$dotssh/known_hosts";
        }
    }
    unless ($ssh2->check_hostkey(Net::SSH2::LIBSSH2_HOSTKEY_POLICY_TOFU())) {
        my @error = $ssh2->error;
        $self->{logger}->error("Can't trust $remote for ssh remoteinventory: @error");
        undef $self->{_ssh2};
        return;
    }

    # Support authentication by password
    if ($self->pass()) {
        $self->{logger}->debug2("Try authentication by password...");
        my $user = $self->user();
        unless ($user) {
            if ($ENV{USER}) {
                $user = $ENV{USER};
                $self->{logger}->debug2("Trying '$user' as login");
            } else {
                $self->{logger}->error("No user given for password authentication");
            }
        }
        if ($user) {
            unless ($ssh2->auth_password($user, $self->pass())) {
                my @error = $ssh2->error;
                $self->{logger}->debug("Can't authenticate to $remote with given password for ssh remoteinventory: @error");
            }
            if ($ssh2->auth_ok) {
                $self->{logger}->debug2("Authenticated on $remote remote with given password");
                $self->user($user);
                return 1;
            }
        }
    }

    # Find private keys in default user env
    if (!$self->{_private_keys} || $self->{_private_keys_lastscan} < time-60) {
        $self->{_private_keys} = {};
        foreach my $file (glob($ENV{HOME}."/.ssh/*")) {
            next unless getFirstMatch(
                file    => $file,
                pattern => qr/^-----BEGIN (.*) PRIVATE KEY-----$/,
            );
            my ($key) = $file =~ m{/([^/]+)$};
            $self->{_private_keys}->{$key} = $file;
        }
        $self->{_private_keys_lastscan} = time;
    }

    # Support public key athentication
    my $user = $self->user() // $ENV{USER};
    foreach my $private (sort(keys(%{$self->{_private_keys}}))) {
        $self->{logger}->debug2("Try authentication using $private key...");
        my $file = $self->{_private_keys}->{$private};
        my $pubkey;
        $pubkey = $file.".pub" if -e $file.".pub";
        next unless $ssh2->auth_publickey($user, $pubkey, $file, $self->pass());
        if ($ssh2->auth_ok) {
            $self->{logger}->debug2("Authenticated on $remote remote with $private key");
            return 1;
        }
    }

    $self->{logger}->error("Can't authenticate on $remote remote host");
    undef $self->{_ssh2};
    return 0;
}

sub _ssh2_exec_status {
    my ($self, $command) = @_;

    # Support Net::SSH2 facilities to exec command
    return unless $self->_connect();

    my $ret;
    my $chan = $self->{_ssh2}->channel();
    $chan->ext_data('ignore');
    $self->{logger}->debug2("Testing \"$command\"...");
    if ($chan && $chan->exec("LANG=C $command")) {
        $ret = $chan->exit_status();
        $chan->close;
    } else {
        $self->{logger}->debug2("Failed to start '$command' using ssh2 lib");
    }

    return $ret;
}

sub checking_error {
    my ($self) = @_;

    my $libssh2 = $self->_connect();
    return "Can't run simple command on remote via libssh2, check server is up and ssh access is setup"
        if $self->mode('libssh2') && !$self->mode('ssh') && !$libssh2;

    my $root = $self->getRemoteFirstLine(command => "id -u");

    return "Can't run simple command on remote, check server is up and ssh access is setup"
        unless defined($root) && length($root);

    $self->{logger}->warning("You should execute remote inventory as super-user on remote host")
        unless $root eq "0";

    return "Mode perl required but can't run perl"
        if $self->mode('perl') && ! $self->remoteCanRun("perl");

    my $deviceid = $self->getRemoteFirstLine(file => ".glpi-agent-deviceid");
    if ($deviceid) {
        $self->deviceid(deviceid => $deviceid);
    } else {
        my $hostname = $self->getRemoteHostname()
            or return "Can't retrieve remote hostname";
        $deviceid = $self->deviceid(hostname => $hostname)
            or return "Can't compute deviceid getting remote hostname";

        my $command = "echo $deviceid >.glpi-agent-deviceid";

        # Support Net::SSH2 facilities to exec command
        my $ret = $self->_ssh2_exec_status($command);
        if (defined($ret)) {
            if ($ret) {
                $self->{logger}->warning("Failed to store deviceid using ssh2");
            } else {
                return '';
            }
        }

        system($self->_ssh("sh -c \"'$command'\""))
            or return "Can't store deviceid on remote";
    }

    return '';
}

sub getRemoteFileHandle {
    my ($self, %params) = @_;

    my $command;
    if ($params{file}) {
        # Support Net::SSH2 facilities to read file with sftp protocol
        if ($self->{_ssh2}) {
            # Reconnect if needed
            $self->_connect();
            my $sftp = $self->{_ssh2}->sftp();
            if ($sftp) {
                $self->{logger}->debug2("Trying to read '$params{file}' via sftp subsystem");
                my $fh = $sftp->open($params{file});
                return $fh if $fh;
                my @error = $sftp->error;
                if (@error && $error[0]) {
                    if ($error[0] == 2) { # SSH_FX_NO_SUCH_FILE
                        $self->{logger}->debug2("'$params{file}' file not found");
                        return;
                    } elsif ($error[0] == 3) { # SSH_FX_PERMISSION_DENIED
                        $self->{logger}->debug2("Not authorized to read '$params{file}'");
                        return;
                    } else {
                        $self->{logger}->debug2("Unsupported SFTP error (@error)");
                    }
                }

                # Also log libssh2 error
                @error = $self->{_ssh2}->error();
                $self->{logger}->debug2("Failed to open file with SFTP: libssh2 err code is $error[1]");
                $self->{logger}->debug("Failed to open file with SFTP: $error[2]");
            }
        }
        $command = "cat '$params{file}'";
    } elsif ($params{command}) {
        $command = $params{command};
    } else {
        $self->{logger}->debug("Unsupported getRemoteFileHandle() call with ".join(",",keys(%params))." parameters");
        return;
    }

    # Support Net::SSH2 facilities to exec command
    if ($self->{_ssh2}) {
        # Reconnect if needed
        $self->_connect();
        my $chan = $self->{_ssh2}->channel();
        if ($chan) {
            $chan->ext_data('ignore');
            $self->{logger}->debug2("Running \"$command\"...");
            if ($chan->exec("LANG=C $command")) {
                return $chan;
            }
        }
    }

    $command =~ s/\\/\\\\/g;
    $command =~ s/\$/\\\$/g;

    return getFileHandle(
        command => $self->_ssh($command),
        logger  => $self->{logger},
        local   => 1
    );
}

sub remoteCanRun {
    my ($self, $binary) = @_;

    my $command = $binary =~ m{^/} ? "test -x '$binary'" : "which $binary >/dev/null";

    # Support Net::SSH2 facilities to exec command
    my $ret = $self->_ssh2_exec_status($command);
    return $ret == 0
        if defined($ret);

    my $stderr = $OSNAME eq 'MSWin32' ? " 2>nul" : " 2>/dev/null";

    return system($self->_ssh($command).$stderr) == 0;
}

sub OSName {
    my ($self) = @_;
    my $OS = lc($self->getRemoteFirstLine(command => "uname -s"));
    return 'solaris' if $OS eq 'sunos';
    return 'hpux' if $OS eq 'hp-ux';
    return $OS;
}

sub remoteGlob {
    my ($self, $glob, $test) = @_;
    return unless $glob;

    my $command = "sh -c 'for f in $glob; do if test ".($test // "-e")." \"\$f\"; then echo \$f; fi; done'";

    my @glob = $self->getRemoteAllLines(
        command => $self->{_ssh2} ? $command : "\"$command\""
    );

    return @glob;
}

sub getRemoteHostname {
    my ($self) = @_;
    # command is run remotely
    my $hostname = $self->getRemoteFirstLine(command => "hostname");

    # Fallback to get hostname from remote definition
    ($hostname) = $self->host() =~ /^(.*):?(\d+)?$/
        unless $hostname;

    return $hostname;
}

sub getRemoteFQDN {
    my ($self) = @_;
    # command is run remotely
    return $self->getRemoteFirstLine(command => "perl -e \"'use Net::Domain qw(hostfqdn); print hostfqdn()'\"")
        if $self->mode('perl');
}

sub getRemoteHostDomain {
    my ($self) = @_;
    # command will be run remotely
    return $self->getRemoteFirstLine(command => "perl -e \"'use Net::Domain qw(hostdomain); print hostdomain()'\"")
        if $self->mode('perl');
}

sub remoteTestFolder {
    my ($self, $folder) = @_;

    my $command = "test -d '$folder'";

    # Support Net::SSH2 facilities to exec command
    my $ret = $self->_ssh2_exec_status($command);
    return $ret == 0
        if defined($ret);

    return system($self->_ssh($command)) == 0;
}

sub remoteTestFile {
    my ($self, $file, $filetest) = @_;

    # Support Net::SSH2 facilities to stat file with sftp protocol
    if ($self->{_ssh2}) {
        # Reconnect if needed
        $self->_connect();
        my $sftp = $self->{_ssh2}->sftp();
        if ($sftp) {
            if ($filetest && $filetest eq "r") {
                $self->{logger}->debug2("Trying to stat if '$file' is readable via sftp subsystem");
                my $fh = $sftp->open($file);
                return 0 unless $fh;
                close($fh);
                return 1;
            }
            $self->{logger}->debug2("Trying to stat '$file' via sftp subsystem");
            my $stat = $sftp->stat($file);
            return 1 if defined($stat);
            my @error = $sftp->error;
            if (@error && $error[0]) {
                if ($error[0] == 2) { # SSH_FX_NO_SUCH_FILE
                    return 0;
                } elsif ($error[0] == 3) { # SSH_FX_PERMISSION_DENIED
                    $self->{logger}->debug2("Not authorized to access '$file'");
                    return 0;
                } else {
                    $self->{logger}->debug2("Unsupported SFTP error (@error)");
                }
            }

            # Also log libssh2 error
            @error = $self->{_ssh2}->error();
            $self->{logger}->debug2("Failed to stat file with SFTP: libssh2 err code is $error[1]");
            $self->{logger}->debug("Failed to stat file with SFTP: $error[2]");
        }
    }

    my $command = $filetest && $filetest eq "r" ? "test -r '$file'" : "test -e '$file'";

    # Support Net::SSH2 facilities to exec command
    my $ret = $self->_ssh2_exec_status($command);
    return $ret == 0
        if defined($ret);

    return system($self->_ssh($command)) == 0;
}

sub remoteTestLink {
    my ($self, $link) = @_;

    my $command = "test -h '$link'";

    # Support Net::SSH2 facilities to exec command
    my $ret = $self->_ssh2_exec_status($command);
    return $ret == 0
        if defined($ret);

    return system($self->_ssh($command)) == 0;
}

# This API only need to return ctime & mtime
sub remoteFileStat {
    my ($self, $file) = @_;

    # Support Net::SSH2 facilities to stat file with sftp protocol
    if ($self->{_ssh2}) {
        # Reconnect if needed
        $self->_connect();
        my $sftp = $self->{_ssh2}->sftp();
        if ($sftp) {
            $self->{logger}->debug2("Trying to stat '$file' via sftp subsystem");
            my $stat = $sftp->stat($file);
            if (ref($stat) eq 'HASH') {
                return (
                    undef,
                    undef,
                    hex($stat->{mode}),
                    undef,
                    $stat->{uid},
                    $stat->{gid},
                    undef,
                    $stat->{size},
                    $stat->{atime},
                    $stat->{mtime},
                    undef,
                    undef
                );
            }
            my @error = $sftp->error;
            if (@error && $error[0]) {
                if ($error[0] == 2) { # SSH_FX_NO_SUCH_FILE
                    return;
                } elsif ($error[0] == 3) { # SSH_FX_PERMISSION_DENIED
                    $self->{logger}->debug2("Not authorized to access '$file'");
                    return;
                } else {
                    $self->{logger}->debug2("Unsupported SFTP error (@error)");
                }
            }

            # Also log libssh2 error
            @error = $self->{_ssh2}->error();
            $self->{logger}->debug2("Failed to stat file with SFTP: libssh2 err code is $error[1]");
            $self->{logger}->debug("Failed to stat file with SFTP: $error[2]");
        }
    }

    my $stat = $self->getRemoteFirstLine(command => "stat -t '$file'")
        or return;
    my ($name, $size, $bsize, $mode, $uid, $gid, $dev, $ino, $nlink, $major, $minor, $atime, $mtime, $stime, $ctime, $blocks) =
        split(/\s+/, $stat);
    return (undef, $ino, hex($mode), $nlink, $uid, $gid, undef, $size, $atime, $mtime, $ctime, $blocks);
}

sub remoteReadLink {
    my ($self, $link) = @_;
    # command will be run remotely
    return $self->getRemoteFirstLine(command => "readlink '$link'");
}

sub remoteGetNextUser {
    my ($self) = @_;
    unless ($self->{_users} && @{$self->{_users}}) {
        $self->{_users} = [
            map {
                my @entry = split(':', $_);
                {
                    name    => $entry[0],
                    uid     => $entry[2],
                    dir     => $entry[5]
                }
            } getAllLines( file => '/etc/passwd' )
        ];
    }
    return shift(@{$self->{_users}}) if $self->{_users};
}

1;
