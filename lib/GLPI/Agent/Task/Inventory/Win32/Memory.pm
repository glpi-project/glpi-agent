package GLPI::Agent::Task::Inventory::Win32::Memory;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Win32;

use constant    category    => "memory";

our $runMeIfTheseChecksFailed =
    ["GLPI::Agent::Task::Inventory::Generic::Dmidecode"];

my @formFactorVal = qw/
    Unknown
    Other
    SIP
    DIP
    ZIP
    SOJ
    Proprietary
    SIMM
    DIMM
    TSOP
    PGA
    RIMM
    SODIMM
    SRIMM
    SMD
    SSMP
    QFP
    TQFP
    SOIC
    LCC
    PLCC
    BGA
    FPBGA
    LGA
/;

my @memoryTypeVal = qw/
    Unknown
    Other
    DRAM
    Synchronous DRAM
    Cache DRAM
    EDO
    EDRAM
    VRAM
    SRAM
    RAM
    ROM
    Flash
    EEPROM
    FEPROM
    EPROM
    CDRAM
    3DRAM
    SDRAM
    SGRAM
    RDRAM
    DDR
    DDR-2
/;

my @memoryErrorProtection = (
    undef,
    'Other',
    undef,
    'None',
    'Parity',
    'Single-bit ECC',
    'Multi-bit ECC',
    'CRC',
);

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $memory (_getMemories()) {
        $inventory->addEntry(
            section => 'MEMORIES',
            entry   => $memory
        );
    }
}

sub _getMemories {

    my $cpt = 0;
    my @memories;

    foreach my $object (getWMIObjects(
        class      => 'Win32_PhysicalMemory',
        properties => [ qw/
            Capacity Caption Description FormFactor Removable Speed MemoryType
            SerialNumber
        / ]
    )) {
        # Ignore ROM storages (BIOS ROM)
        my $type = $memoryTypeVal[$object->{MemoryType} // 0];
        next if $type && $type eq 'ROM';
        next if $type && $type eq 'Flash';

        my $capacity;
        $capacity = $object->{Capacity} / (1024 * 1024)
            if $object->{Capacity};

        push @memories, {
            CAPACITY     => $capacity,
            CAPTION      => $object->{Caption},
            DESCRIPTION  => $object->{Description},
            FORMFACTOR   => $formFactorVal[$object->{FormFactor} // 0],
            REMOVABLE    => $object->{Removable} ? 1 : 0,
            SPEED        => getCanonicalSpeed($object->{Speed}),
            TYPE         => $memoryTypeVal[$object->{MemoryType} // 0],
            NUMSLOTS     => $cpt++,
            SERIALNUMBER => $object->{SerialNumber}
        }
    }

    foreach my $object (getWMIObjects(
        class      => 'Win32_PhysicalMemoryArray',
        properties => [ qw/
            MemoryDevices SerialNumber MemoryErrorCorrection
        / ]
    )) {
        my $memory = defined($object->{MemoryDevices}) ?
            $memories[$object->{MemoryDevices} - 1] : $memories[0];
        if (!$memory->{SERIALNUMBER}) {
            $memory->{SERIALNUMBER} = $object->{SerialNumber};
        }

        if ($object->{MemoryErrorCorrection}) {
            $memory->{MEMORYCORRECTION} =
                $memoryErrorProtection[$object->{MemoryErrorCorrection} // 0];
            if ($memory->{MEMORYCORRECTION} && $object->{MemoryErrorCorrection}>3) {
                $memory->{DESCRIPTION} .= " (".$memory->{MEMORYCORRECTION}.")";
            }
        }

    }

    return @memories;
}

1;
