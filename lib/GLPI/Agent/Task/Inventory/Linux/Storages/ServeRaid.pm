package FusionInventory::Agent::Task::Inventory::Linux::Storages::ServeRaid;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Task::Inventory::Linux::Storages;

# Tested on 2.6.* kernels
#
# Cards tested :
#
# IBM ServeRAID-6M
# IBM ServeRAID-6i

sub isEnabled {
    return canRun('ipssend');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $handle1 = getFileHandle(
        logger => $logger,
        command => 'ipssend GETVERSION'
    );
    return unless $handle1;

    while (my $line1 = <$handle1>) {

# Example Output :
# Found 1 IBM ServeRAID controller(s).
#----------------------------------------------------------------------
#ServeRAID Controller(s) Version Information
#----------------------------------------------------------------------
#   Controlling BIOS version       : 7.00.14
        #
#ServeRAID Controller Number 1
#   Controller type                : ServeRAID-6M
#   Controller slot information    : 2
#   Actual BIOS version            : 7.00.14
#   Firmware version               : 7.00.14
#   Device driver version          : 7.10.18
        next unless /ServeRAID Controller Number\s(\d*)/;
        my $slot = $1;

        my $storage;
        my $handle2 = getFileHandle(
            logger => $logger,
            command => "ipssend GETCONFIG $slot PD"
        );
        next unless $handle2;

        while (my $line2 =~ <$handle2>) {
# Example Output :
#   Channel #1:
#      Target on SCSI ID 0
#         Device is a Hard disk
#         SCSI ID                  : 0
#         PFA (Yes/No)             : No
#         State                    : Online (ONL)
#         Size (in MB)/(in sectors): 34715/71096368
#         Device ID                : IBM-ESXSCBR036C3DFQDB2Q6CDKM
#         FRU part number          : 32P0729

            if ($line2 =~ /Size.*:\s(\d*)\/(\d*)/) {
                $storage->{DISKSIZE} = $1;
            } elsif ($line2 =~ /Device ID.*:\s(.*)/) {
                $storage->{SERIALNUMBER} = $1;
            } elsif ($line2 =~ /FRU part number.*:\s(.*)/) {
                $storage->{MODEL} = $1;
                $storage->{MANUFACTURER} = getCanonicalManufacturer(
                    $storage->{SERIALNUMBER}
                );
                $storage->{NAME} = $storage->{MANUFACTURER} . ' ' . $storage->{MODEL};
                $storage->{DESCRIPTION} = 'SCSI';
                $storage->{TYPE} = 'disk';

                $inventory->addEntry(section => 'STORAGES', entry => $storage);
                undef $storage;
            }
        }
        close $handle2;
    }
    close $handle1;
}

1;
