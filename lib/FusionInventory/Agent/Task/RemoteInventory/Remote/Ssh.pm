package FusionInventory::Agent::Task::RemoteInventory::Remote::Ssh;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use parent 'FusionInventory::Agent::Task::RemoteInventory::Remote';

use FusionInventory::Agent::Tools;

sub deviceid {
    my ($self) = @_;

    return $self->{_deviceid} = 'xps.root';
}

sub _ssh {
    my ($self, $command) = @_;
    return unless $command;
    return "ssh -q ".$self->host()." LANG=C $command";
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
    my $tempfile =  getFirstLine( command => "mktemp /tmp/.glpi-agent-XXXXXXXX" );
    # Otherwise we will create an unsafe one
    $tempfile = sprintf(".glpi-agent-%08x", rand(1<<32)) unless $tempfile && $tempfile =~ m|^/tmp/\.glpi-agent-|;

    $self->{logger}->debug2("creating remote $tempfile script to handle portable glob");

    # Ignore 'Broken Pipe' warnings on Solaris
    local $SIG{PIPE} = 'IGNORE' if $OSNAME eq 'solaris';
    my $command = $self->_ssh("'cat >$tempfile'");
    my $cmdpid  = open(SCRIPT, '|-', $command);
    if (!$cmdpid) {
        $self->{logger}->error("Can't run command $command: $ERRNO");
        return;
    }
    # Kill command if a timeout was set
    $SIG{ALRM} = sub { kill 'KILL', $cmdpid ; die "alarm\n"; } if $SIG{ALRM};
    print SCRIPT "for f in $glob; do test $test \"\$f\" && echo \"\$f\"; done\n";
    close(SCRIPT);

    my @glob = getAllLines( command => "sh $tempfile" );

    # Always remove remote tempfile
    system($self->_ssh("rm -f '$tempfile'")) if $tempfile;

    return @glob;
}

sub getRemoteHostname {
    # command is run remotely
    return getFirstLine(command => "hostname");
}

sub getRemoteFQDN {
    # command is run remotely
    return getFirstLine(command => "perl -e \"'use Net::Domain qw(hostfqdn); print hostfqdn()'\"");
}

sub getRemoteHostDomain {
    # command will be run remotely
    return getFirstLine(command => "perl -e \"'use Net::Domain qw(hostdomain); print hostdomain()'\"");
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
    my $stat = getFirstLine(command => "stat -t '$file'")
        or return;
    my ($name, $size, $bsize, $mode, $uid, $gid, $dev, $ino, $nlink, $major, $minor, $atime, $mtime, $stime, $ctime, $blocks) =
        split(/\s+/, $stat);
    return (undef, $ino, hex($mode), $nlink, $uid, $gid, undef, $size, $atime, $mtime, $ctime, $blocks);
}

sub remoteReadLink {
    my ($self, $link) = @_;
    # command will be run remotely
    return getFirstLine(command => "readlink '$link'");
}

sub remoteGetPwEnt {
    my ($self) = @_;
    unless ($self->{_users}) {
        $self->{_users} = [ map { /^([^:]+):/ } getAllLines( file => '/etc/passwd' ) ];
    }
    return shift(@{$self->{_users}}) if $self->{_users};
}

1;
