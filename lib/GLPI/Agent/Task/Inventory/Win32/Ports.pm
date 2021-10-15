package GLPI::Agent::Task::Inventory::Win32::Ports;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

# Had never been tested.
use GLPI::Agent::Tools::Win32;

use constant    category    => "port";

# cf http://msdn.microsoft.com/en-us/library/aa394486%28VS.85%29.aspx
my @portType = (
    'Unknown',
    'Other',
    'Male',
    'Female',
    'Shielded',
    'Unshielded',
    'SCSI (A) High-Density (50 pins)',
    'SCSI (A) Low-Density (50 pins)',
    'SCSI (P) High-Density (68 pins)',
    'SCSI SCA-I (80 pins)',
    'SCSI SCA-II (80 pins)',
    'SCSI Fibre Channel (DB-9, Copper)',
    'SCSI Fibre Channel (Fibre)',
    'SCSI Fibre Channel SCA-II (40 pins)',
    'SCSI Fibre Channel SCA-II (20 pins)',
    'SCSI Fibre Channel BNC',
    'ATA 3-1/2 Inch (40 pins)',
    'ATA 2-1/2 Inch (44 pins)',
    'ATA-2',
    'ATA-3',
    'ATA/66',
    'DB-9',
    'DB-15',
    'DB-25',
    'DB-36',
    'RS-232C',
    'RS-422',
    'RS-423',
    'RS-485',
    'RS-449',
    'V.35',
    'X.21',
    'IEEE-488',
    'AUI',
    'UTP Category 3',
    'UTP Category 4',
    'UTP Category 5',
    'BNC',
    'RJ11',
    'RJ45',
    'Fiber MIC',
    'Apple AUI',
    'Apple GeoPort',
    'PCI',
    'ISA',
    'EISA',
    'VESA',
    'PCMCIA',
    'PCMCIA Type I',
    'PCMCIA Type II',
    'PCMCIA Type III',
    'ZV Port',
    'CardBus',
    'USB',
    'IEEE 1394',
    'HIPPI',
    'HSSDC (6 pins)',
    'GBIC',
    'DIN',
    'Mini-DIN',
    'Micro-DIN',
    'PS/2',
    'Infrared',
    'HP-HIL',
    'Access.bus',
    'NuBus',
    'Centronics',
    'Mini-Centronics',
    'Mini-Centronics Type-14',
    'Mini-Centronics Type-20',
    'Mini-Centronics Type-26',
    'Bus Mouse',
    'ADB',
    'AGP',
    'VME Bus',
    'VME64',
    'Proprietary',
    'Proprietary Processor Card Slot',
    'Proprietary Memory Card Slot',
    'Proprietary I/O Riser Slot',
    'PCI-66MHZ',
    'AGP2X',
    'AGP4X',
    'PC-98',
    'PC-98-Hireso',
    'PC-H98',
    'PC-98Note',
    'PC-98Full',
    'PCI-X',
    'SSA SCSI',
    'Circular',
    'On-Board IDE Connector',
    'On-Board Floppy Connector',
    '9 Pin Dual Inline',
    '25 Pin Dual Inline',
    '50 Pin Dual Inline',
    '68 Pin Dual Inline',
    'On-Board Sound Connector',
    'Mini-Jack',
    'PCI-X',
    'Sbus IEEE 1396-1993 32 Bit',
    'Sbus IEEE 1396-1993 64 Bit',
    'MCA',
    'GIO',
    'XIO',
    'HIO',
    'NGIO',
    'PMC',
    'MTRJ',
    'VF-45',
    'Future I/O',
    'SC',
    'SG',
    'Electrical',
    'Optical',
    'Ribbon',
    'GLM',
    '1x9',
    'Mini SG',
    'LC',
    'HSSC',
    'VHDCI Shielded (68 pins)',
    'InfiniBand',
    'AGP8X',
    'PCI-E',
);

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $object (getWMIObjects(
        class      => 'Win32_SerialPort',
        properties => [ qw/Name Caption Description/ ]
    )) {
        $inventory->addEntry(
            section => 'PORTS',
            entry   => {
                NAME        => $object->{Name},
                CAPTION     => $object->{Caption},
                DESCRIPTION => $object->{Description},
                TYPE        => 'Serial',
            }
        );
    }

    foreach my $object (getWMIObjects(
        class      => 'Win32_ParallelPort',
        properties => [ qw/Name Caption Description/ ]
    )) {

        $inventory->addEntry(
            section => 'PORTS',
            entry   => {
                NAME        => $object->{Name},
                CAPTION     => $object->{Caption},
                DESCRIPTION => $object->{Description},
                TYPE        => 'Parallel',
            }
        );
    }

    foreach my $object (getWMIObjects(
        class      => 'Win32_PortConnector',
        properties => [ qw/ConnectorType InternalReferenceDesignator/ ]
    )) {

        my $type;
        if ($object->{ConnectorType}) {
            if (ref($object->{ConnectorType}) eq 'ARRAY') {
                $type = join(', ', map { $portType[$_] } @{$object->{ConnectorType}});
            } elsif ($object->{ConnectorType} =~ /^\d+$/) {
                $type = $portType[int($object->{ConnectorType})];
            }
        }
        if (!$type) {
            $type = $object->{InternalReferenceDesignator};
            $type =~ s/\ \d.*//; # Drop the port number
        }

        if (!$type && !$object->{InternalReferenceDesignator}) {
            next;
        } elsif ($object->{InternalReferenceDesignator} =~ /SERIAL/) {
            next; # Already done
        } elsif ($object->{InternalReferenceDesignator} =~ /PARALLEL/) {
            next; # Already done
        }

        $inventory->addEntry(
            section => 'PORTS',
            entry   => {
                NAME        => $object->{InternalReferenceDesignator},
                CAPTION     => $object->{InternalReferenceDesignator},
                DESCRIPTION => $object->{InternalReferenceDesignator},
                TYPE        => $type
            }
        );

    }

}
1;
