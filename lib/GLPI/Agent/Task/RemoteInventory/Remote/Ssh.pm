package GLPI::Agent::Task::RemoteInventory::Remote::Ssh;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use parent 'GLPI::Agent::Task::RemoteInventory::Remote';

use GLPI::Agent::Tools;

use constant    supported => 1;

sub _ssh {
    my ($self, $command) = @_;
    return unless $command;
    return "ssh -q ".$self->host()." LANG=C $command";
}

sub init {
    my ($self) = @_;

    my $mode = $self->mode();
    $self->resetmode() if ($mode && $mode !~ /^perl$/);
}

sub checking_error {
    my ($self) = @_;

    my $root = $self->getRemoteFirstLine(command => "id -u");

    return "Can't run simple command on remote, check server is up and ssh access is setup"
        unless defined($root) && length($root);

    warn "You should execute remote inventory as super-user\n" unless $root eq "0";

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
        system($self->_ssh("sh -c \"'echo $deviceid >.glpi-agent-deviceid'\""))
            or return "Can't store deviceid on remote";
    }

    return '';
}

sub getRemoteFileHandle {
    my ($self, %params) = @_;

    my $command;
    if ($params{file}) {
        $command .= "cat '$params{file}'";
    } elsif ($params{command}) {
        $params{command} =~ s/\\/\\\\/g;
        $params{command} =~ s/\$/\\\$/g;
        $command .= $params{command};
    }
    return unless $command;

    return getFileHandle(
        command => $self->_ssh($command),
        logger  => $self->{logger},
        local   => 1
    );
}

sub remoteCanRun {
    my ($self, $binary) = @_;

    my $command = $binary =~ m{^/} ? "test -x '$binary'" : "which $binary >/dev/null";
    $command .= $OSNAME eq 'MSWin32' ? " 2>nul" : " 2>/dev/null";

    return system($self->_ssh($command)) == 0;
}

sub OSName {
    return 'linux';
}

sub remoteGlob {
    my ($self, $glob, $test) = @_;
    return unless $glob;

    $test = "-e" unless $test;

    # Create a safe tempfile
    my $tempfile =  $self->getRemoteFirstLine( command => "mktemp /tmp/.glpi-agent-XXXXXXXX" );
    # Otherwise we will create an unsafe one
    $tempfile = sprintf(".glpi-agent-%08x", rand(1<<32)) unless $tempfile && $tempfile =~ m|^/tmp/\.glpi-agent-|;

    $self->{logger}->debug2("creating remote $tempfile script to handle portable glob");

    # Ignore 'Broken Pipe' warnings on Solaris
    local $SIG{PIPE} = 'IGNORE' if $OSNAME eq 'solaris';
    my $handle;
    my $command = $self->_ssh("'cat >$tempfile'");
    my $cmdpid  = open($handle, '|-', $command);
    if (!$cmdpid) {
        $self->{logger}->error("Can't run command $command: $ERRNO");
        return;
    }
    # Kill command if a timeout was set
    $SIG{ALRM} = sub { kill 'KILL', $cmdpid ; die "alarm\n"; } if $SIG{ALRM};
    print $handle "for f in $glob; do test $test \"\$f\" && echo \"\$f\"; done\n";
    close($handle);

    my @glob = $self->getRemoteAllLines( command => "sh $tempfile" );

    # Always remove remote tempfile
    system($self->_ssh("rm -f '$tempfile'")) if $tempfile;

    return @glob;
}

sub getRemoteHostname {
    my ($self) = @_;
    # command is run remotely
    return $self->getRemoteFirstLine(command => "hostname");
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
    return system($self->_ssh("test -d '$folder'")) == 0;
}

sub remoteTestFile {
    my ($self, $file) = @_;
    return system($self->_ssh("test -e '$file'")) == 0;
}

sub remoteTestLink {
    my ($self, $link) = @_;
    return system($self->_ssh("test -h '$link'")) == 0;
}

# This API only need to return ctime & mtime
sub remoteFileStat {
    my ($self, $file) = @_;
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
