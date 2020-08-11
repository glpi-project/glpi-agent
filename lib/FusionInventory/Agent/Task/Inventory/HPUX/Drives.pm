package FusionInventory::Agent::Task::Inventory::HPUX::Drives;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use POSIX qw(strftime);

use FusionInventory::Agent::Tools;

use constant    category    => "drive";

sub isEnabled  {
    return
        canRun('fstyp') &&
        canRun('bdf');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # get filesystem types
    my @types = getAllLines(
        command => 'fstyp -l',
        logger  => $logger
    );

    # get filesystems for each type
    foreach my $type (@types) {
        foreach my $drive (_getDrives(type => $type, logger => $logger)) {
            $inventory->addEntry(section => 'DRIVES', entry => $drive);
        }
    }
}

sub _getDrives {
    my (%params) = @_;

    my @drives = _parseBdf(
        command => "bdf -t $params{type}", logger => $params{logger}
    );

    foreach my $drive (@drives) {
        $drive->{FILESYSTEM} = $params{type};
        if ($params{type} eq 'vxfs') {
            my $date = _getVxFSctime($drive->{VOLUMN}, $params{logger});
            $drive->{CREATEDATE} = $date if $date;
        }
    }

    return @drives;
}

sub _parseBdf {
    my $handle = getFileHandle(@_);
    return unless $handle;

    my @drives;

    # skip header
    my $line = <$handle>;

    my $device;
    while (my $line = <$handle>) {
        if ($line =~ /^(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+%)\s+(\S+)/) {
            push @drives, {
                VOLUMN     => $1,
                TOTAL      => $2,
                FREE       => $3,
                TYPE       => $6,
            };
            next;
        }

        if ($line =~ /^(\S+)\s/) {
            $device = $1;
            next;
        }

        if ($line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+%)\s+(\S+)/) {
            push @drives, {
                VOLUMN     => $device,
                TOTAL      => $1,
                FREE       => $3,
                TYPE       => $5,
            };
            next;
        }
    }
    close $handle;

    return @drives;
}

# get filesystem creation time by reading binary value directly on the device
sub _getVxFSctime {
    my ($device, $logger) = @_;

    # compute version-dependant read offset

    # Output of 'fstyp' should be something like the following:
    # $ fstyp -v /dev/vg00/lvol3
    #   vxfs
    #   version: 5
    #   .
    #   .
    my $version = getFirstMatch(
        command => "fstyp -v $device",
        logger  => $logger,
        pattern => qr/^version:\s+(\d+)$/
    );

    my $offset =
        $version == 5 ? 8200 :
        $version == 6 ? 8208 :
        $version == 7 ? 8208 :
                        undef;

    return $logger->error("unable to compute offset from fstyp output ($device)")
        unless $offset;

    # read value
    my $handle = getFileHandle( file => $device, mode => "<:raw:bytes" )
        or return;
    my $raw;
    if (seek($handle, $offset, 0)) {
        $logger->error("Can't read 4 bytes on device $device: $ERRNO")
            unless (read($handle, $raw, 4));
    } else {
        $logger->error("Can't seek offset $offset on device $device: $ERRNO");
    }
    close($handle);

    return unless defined($raw);

    # Convert the 4-byte raw data to long integer and
    # return a string representation of this time stamp
    return strftime("%Y/%m/%d %T", localtime(unpack('L', $raw)));
}

1;
