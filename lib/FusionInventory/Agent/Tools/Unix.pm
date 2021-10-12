package FusionInventory::Agent::Tools::Unix;

use strict;
use warnings;
use parent 'Exporter';

use English qw(-no_match_vars);
use File::Which;
use File::Basename qw(basename);
use Memoize;
use Time::Local;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Network;

our @EXPORT = qw(
    getDeviceCapacity
    getIpDhcp
    getFilesystemsFromDf
    getFilesystemsTypesFromMount
    getProcesses
    getRoutingTable
);

memoize('getProcesses');

sub getDeviceCapacity {
    my (%params) = @_;

    return unless $params{device};

    my $logger = delete $params{logger};
    # We need to support dump params to permit full testing when root params is set
    my $name = basename($params{device});
    my $root = $params{root} || "";
    $params{command} = "/sbin/fdisk -v";
    if ($params{dump}) {
        $params{dump}->{"fdisk-v"} = getAllLines(%params);
    }
    if ($root) {
        $params{file} = "$root/fdisk-v";
    }

    # GNU version requires -p flag
    $params{command} = getFirstLine(%params) =~ '^GNU' ?
        "/sbin/fdisk -p -s $params{device}" :
        "/sbin/fdisk -s $params{device}"    ;

    # Always override with a file if testing under $root
    $params{file} = "$root/fdisk-$name" if $root;

    if ($params{dump}) {
        $params{dump}->{"fdisk-$name"} = getAllLines(
            logger => $logger,
            %params
        );
    }

    my $capacity = getFirstLine(
        logger => $logger,
        %params
    );

    $capacity = int($capacity / 1000) if $capacity;

    return $capacity;
}

sub getIpDhcp {
    my ($logger, $if) = @_;

    my $dhcpLeaseFile = _findDhcpLeaseFile($if);

    return unless $dhcpLeaseFile;

    _parseDhcpLeaseFile($logger, $if, $dhcpLeaseFile);
}

sub _findDhcpLeaseFile {
    my ($if) = @_;

    my @directories = qw(
        /var/db
        /var/lib/dhcp3
        /var/lib/dhcp
        /var/lib/dhclient
    );
    my @patterns = ("*$if*.lease", "*.lease", "dhclient.leases.$if");
    my @files;

    foreach my $directory (@directories) {
        next unless has_folder($directory);
        foreach my $pattern (@patterns) {

            push @files, Glob("$directory/$pattern", "-s");
        }
    }

    return unless @files;

    # sort by creation time
    @files =
        map { $_->[0] }
        sort { $a->[1]->ctime() <=> $b->[1]->ctime() }
        map { [ $_, FileStat($_) ] }
        @files;

    # take the last one
    return $files[-1];
}

sub _parseDhcpLeaseFile {
    my ($logger, $if, $lease_file) = @_;


    my $handle = getFileHandle(file => $lease_file, logger => $logger);
    return unless $handle;

    my ($lease, $dhcp, $server_ip, $expiration_time);

    # find the last lease for the interface with its expire date
    while (my $line = <$handle>) {
        if ($line=~ /^lease/i) {
            $lease = 1;
            next;
        }
        if ($line=~ /^}/) {
            $lease = 0;
            next;
        }

        next unless $lease;

        # inside a lease section
        if ($line =~ /interface\s+"([^"]+)"/){
            $dhcp = ($1 eq $if);
            next;
        }

        next unless $dhcp;

        if (
            $line =~
            /option \s+ dhcp-server-identifier \s+ (\d{1,3}(?:\.\d{1,3}){3})/x
        ) {
            # server IP
            $server_ip = $1;
        } elsif (
            $line =~
            /expire \s+ \d \s+ (\d+)\/(\d+)\/(\d+) \s+ (\d+):(\d+):(\d+)/x
        ) {
            my ($year, $mon, $day, $hour, $min, $sec)
                = ($1, $2, $3, $4, $5, $6);
            # warning, expected ranges is 0-11, not 1-12
            $mon = $mon - 1;
            $expiration_time = timelocal($sec, $min, $hour, $day, $mon, $year);
        }
    }
    close $handle;

    return unless $expiration_time;

    my $current_time = time();

    return $current_time <= $expiration_time ? $server_ip : undef;
}

sub getFilesystemsFromDf {
    my (%params) = @_;
    my $handle = getFileHandle(%params);

    my @filesystems;

    # get headers line first
    my $line = <$handle>;
    return unless $line;

    chomp $line;
    my @headers = split(/\s+/, $line);

    while (my $line = <$handle>) {
        chomp $line;
        my @infos = split(/\s+/, $line);

        # depending on the df implementation, and how it is called
        # the filesystem type may appear as second colum, or be missing
        # in the second case, it has to be given by caller
        my ($filesystem, $total, $used, $free, $type);
        if ($headers[1] eq 'Type') {
            $filesystem = $infos[1];
            $total      = $infos[2];
            $used       = $infos[3];
            $free       = $infos[4];
            $type       = $infos[6];
        } else {
            $filesystem = $params{type};
            $total      = $infos[1];
            $used       = $infos[2];
            $free       = $infos[3];
            $type       = $infos[5];
        }

        # Fix total for zfs under Solaris
        $total = $used + $free if (!$total && ($used || $free));

        # skip some virtual filesystems
        next if $total !~ /^\d+$/ || $total == 0;
        next if $free  !~ /^\d+$/ || $free  == 0;

        push @filesystems, {
            VOLUMN     => $infos[0],
            FILESYSTEM => $filesystem,
            TOTAL      => int($total / 1024),
            FREE       => int($free / 1024),
            TYPE       => $type
        };
    }

    close $handle;

    return wantarray ? @filesystems : \@filesystems ;
}

sub getFilesystemsTypesFromMount {
    my (%params) = (
        command => 'mount',
        @_
    );

    my $handle = getFileHandle(%params);
    return unless $handle;

    my @types;
    while (my $line = <$handle>) {
        # BSD-style:
        # /dev/mirror/gm0s1d on / (ufs, local, soft-updates)
        if ($line =~ /^\S+ on \S+ \((\w+)/) {
            push @types, $1;
            next;
        }
        # Linux style:
        # /dev/sda2 on / type ext4 (rw,noatime,errors=remount-ro)
        if ($line =~ /^\S+ on \S+ type (\w+)/) {
            push @types, $1;
            next;
        }
    }
    close $handle;

    ### raw result: @types

    return
        uniq
        @types;
}

sub getProcesses {
    my $ps = which('ps');
    return -l $ps && readlink($ps) eq 'busybox' ? _getProcessesBusybox(@_) :
                                                  _getProcessesOther(@_)   ;
}

sub _getProcessesBusybox {
    my (%params) = (
        command => 'ps',
        @_
    );

    my $handle = getFileHandle(%params);

    # skip headers
    my $line = <$handle>;

    my @processes;

    while ($line = <$handle>) {
        next unless $line =~
            /^
            \s* (\S+)
            \s+ (\S+)
            \s+ (\S+)
            \s+ ...
            \s+ (\S.+)
            /x;
        my $pid   = $1;
        my $user  = $2;
        my $vsz   = $3;
        my $cmd   = $4;

        push @processes, {
            USER          => $user,
            PID           => $pid,
            VIRTUALMEMORY => $vsz,
            CMD           => $cmd
        };
    }

    close $handle;

    return @processes;
}

sub _getProcessesOther {
    my (%params) = (
        command =>
            'ps -A -o user,pid,pcpu,pmem,vsz,tty,etime' . ',' .
            (OSNAME() eq 'solaris' ? 'comm' : 'command'),
        @_
    );

    my $handle = getFileHandle(%params);

    # skip headers
    my $line = <$handle>;

    # get the current timestamp
    my $localtime = time();

    my @processes;

    while ($line = <$handle>) {

        next unless $line =~
            /^ \s*
            (\S+) \s+
            (\S+) \s+
            (\S+) \s+
            (\S+) \s+
            (\S+) \s+
            (\S+) \s+
            (\S+) \s+
            (\S.*\S)
            /x;

        my $user  = $1;
        my $pid   = $2;
        my $cpu   = $3;
        my $mem   = $4;
        my $vsz   = $5;
        my $tty   = $6;
        my $etime = $7;
        my $cmd   = $8;

        push @processes, {
            USER          => $user,
            PID           => $pid,
            CPUUSAGE      => $cpu,
            MEM           => $mem,
            VIRTUALMEMORY => $vsz,
            TTY           => $tty,
            STARTED       => _getProcessStartTime($localtime, $etime),
            CMD           => $cmd
        };
    }

    close $handle;

    return @processes;
}

my %month = (
    Jan => '01',
    Feb => '02',
    Mar => '03',
    Apr => '04',
    May => '05',
    Jun => '06',
    Jul => '07',
    Aug => '08',
    Sep => '09',
    Oct => '10',
    Nov => '11',
    Dec => '12',
);
my %day = (
    Mon => '01',
    Tue => '02',
    Wed => '03',
    Thu => '04',
    Fry => '05',
    Sat => '06',
    Sun => '07',
);
my $monthPattern = join ('|', keys %month);

# Computes a consistent process starting time from the process etime value.
sub _getProcessStartTime {
    my ($localtime, $elapsedtime_string) = @_;


    # POSIX specifies that ps etime entry looks like [[dd-]hh:]mm:ss
    # if either day and hour are not present then they will eat
    # up the minutes and seconds so split on a non digit and reverse it:
    my ($psec, $pmin, $phour, $pday) =
        reverse(split(/\D/, $elapsedtime_string));

    ## no critic (ExplicitReturnUndef)
    return undef unless defined $psec && defined $pmin;

    # Compute a timestamp from the process etime value
    my $elapsedtime = $psec                                +
                      $pmin                      * 60      +
                      ($phour ? $phour      * 60 * 60 : 0) +
                      ($pday  ? $pday  * 24 * 60 * 60 : 0) ;

    # Substract this timestamp from the current time, creating the date at which
    # the process was launched
    my (undef, $min, $hour, $day, $month, $year) =
        localtime($localtime - $elapsedtime);

    # Output the final date, after completing it (time + UNIX epoch)
    $year  = $year + 1900;
    $month = $month + 1;
    return sprintf("%04d-%02d-%02d %02d:%02d", $year, $month, $day, $hour, $min);
}

sub getRoutingTable {
    my (%params) = (
        command => 'netstat -nr -f inet',
        @_
    );

    my $handle = getFileHandle(%params);
    return unless $handle;

    my $routes;

    # first, skip all header lines
    while (my $line = <$handle>) {
        last if $line =~ /^Destination/;
    }

    # second, collect routes
    while (my $line = <$handle>) {
        next unless $line =~ /^
            (
                $ip_address_pattern
                |
                $network_pattern
                |
                default
            )
            \s+
            (
                $ip_address_pattern
                |
                $mac_address_pattern
                |
                link\#\d+
            )
            /x;
        $routes->{$1} = $2;
    }
    close $handle;

    return $routes;
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Tools::Unix - Unix-specific generic functions

=head1 DESCRIPTION

This module provides some Unix-specific generic functions.

=head1 FUNCTIONS

=head2 getDeviceCapacity(%params)

Returns storage capacity of given device, using fdisk.

Availables parameters:

=over

=item logger a logger object

=item device the device to use

=back

=head2 getIpDhcp

Returns an hashref of information for current DHCP lease.

=head2 getFilesystemsFromDf(%params)

Returns a list of filesystems as a list of hashref, by parsing given df command
output.

=over

=item logger a logger object

=item command the exact command to use

=item file the file to use, as an alternative to the command

=back

=head2 getFilesystemsTypesFromMount(%params)

Returns a list of used filesystems types, by parsing given mount command
output.

=over

=item logger a logger object

=item command the exact command to use

=item file the file to use, as an alternative to the command

=back

=head2 getProcessesFromPs(%params)

Returns a list of processes as a list of hashref, by parsing given ps command
output.

=over

=item logger a logger object

=item command the exact command to use

=item file the file to use, as an alternative to the command

=back

=head2 getRoutingTable

Returns the routing table as an hashref, by parsing netstat command output.

=over

=item logger a logger object

=item command the exact command to use (default: netstat -nr -f inet)

=item file the file to use, as an alternative to the command

=back
