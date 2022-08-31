package GLPI::Agent::Task::Inventory::Solaris::Storages;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "storage";

sub isEnabled {
    return canRun('iostat');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my @storages = _getStorages(
        logger  => $logger,
        command => 'iostat -En'
    );

    foreach my $storage (@storages) {
        if (has_link("/dev/rdsk/$storage->{NAME}s2")) {
            my $rdisk_path = getFirstLine(
                command => "ls -l /dev/rdsk/$storage->{NAME}s2"
            );
            $storage->{TYPE} =
                $rdisk_path =~ /->.*scsi_vhci/ ? 'MPxIO' :
                $rdisk_path =~ /->.*fp@/       ? 'FC'    :
                $rdisk_path =~ /->.*scsi@/     ? 'SCSI'  :
                                                 undef   ;
        }

        $inventory->addEntry(section => 'STORAGES', entry => $storage);
    }
}

sub _getStorages {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @storages;
    my $storage;

    foreach my $line (@lines) {
        if ($line =~ /^(\S+)\s+Soft/) {
            $storage->{NAME} = $1;
        }
        if ($line =~ /^
            Vendor:       \s (\S+)          \s+
            Product:      \s (\S.*?\S)      \s+
            Revision:     \s (\S+)          \s+
            Serial \s No: (?:\s (\S*))?
        /x) {
            $storage->{MANUFACTURER} = $1;
            $storage->{MODEL} = $2;
            $storage->{FIRMWARE} = $3;
            $storage->{SERIALNUMBER} = $4 if $4;
        }
        if ($line =~ /<(\d+) bytes/) {
            $storage->{DISKSIZE} = int($1/(1000*1000));
        }
        if ($line =~ /^Illegal/) { # Last ligne

            ## To be removed when SERIALNUMBER will be supported
            if ($storage->{SERIALNUMBER}) {
                $storage->{DESCRIPTION} = $storage->{DESCRIPTION} ?
                $storage->{DESCRIPTION} . " S/N:" . $storage->{SERIALNUMBER} :
                                           "S/N:" . $storage->{SERIALNUMBER} ;

            }

            ## To be removed when FIRMWARE will be supported
            if ($storage->{FIRMWARE}) {
                $storage->{DESCRIPTION} = $storage->{DESCRIPTION} ?
                $storage->{DESCRIPTION} . " FW:" . $storage->{FIRMWARE} :
                                           "FW:" . $storage->{FIRMWARE} ;
            }

            if ($storage->{MANUFACTURER}) {
                ## Workaround for MANUFACTURER == ATA case
                if (
                    $storage->{MANUFACTURER} eq 'ATA' &&
                    $storage->{MODEL} =~ /^(Hitachi|Seagate|INTEL) (.+)/i) {
                        $storage->{MANUFACTURER} = $1;
                        $storage->{MODEL} = $2;
                }

                ## Drop the (R) from the manufacturer string
                $storage->{MANUFACTURER} =~ s/\(R\)$//i;
            }


            push @storages, $storage;
            undef $storage;
        }
    }

    return @storages;
}

1;
