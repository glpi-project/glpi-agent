package FusionInventory::Agent::Task::Inventory::Generic::Dmidecode::Memory;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Generic;

# Run after virtualization to decide if found component is virtual
our $runAfterIfEnabled = [ qw(
    FusionInventory::Agent::Task::Inventory::Virtualization::Vmsystem
    FusionInventory::Agent::Task::Inventory::Win32::OS
    FusionInventory::Agent::Task::Inventory::Linux::Memory
    FusionInventory::Agent::Task::Inventory::BSD::Memory
)];

sub isEnabled {
    my (%params) = @_;
    return 0 if $params{no_category}->{memory};
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $memories = _getMemories(logger => $logger);

    return unless $memories;

    # If only one component is defined and we are under a vmsystem, we can update
    # component capacity to real found size. This permits to support memory size updates.
    my $vmsystem = $inventory->getHardware('VMSYSTEM');
    if ($vmsystem && $vmsystem ne 'Physical') {
        my @components = grep { exists $_->{CAPACITY} } @$memories;
        if ( @components == 1) {
            my $real_memory = $inventory->getHardware('MEMORY');
            my $component = shift @components;
            if (!$real_memory) {
                $logger->debug2("Can't verify real memory capacity on this virtual machine");
            } elsif (!$component->{CAPACITY} || $component->{CAPACITY} != $real_memory) {
                $logger->debug2($component->{CAPACITY} ?
                    "Updating virtual component memory capacity to found real capacity: $component->{CAPACITY} => $real_memory"
                    : "Setting virtual component memory capacity to $real_memory"
                );
                $component->{CAPACITY} = $real_memory;
            }
        }
    }

    foreach my $memory (@$memories) {
        $inventory->addEntry(
            section => 'MEMORIES',
            entry   => $memory
        );
    }
}

sub _getMemories {
    my $infos = getDmidecodeInfos(@_);

    my ($memories, $slot);

    if ($infos->{17}) {

        foreach my $info (@{$infos->{17}}) {
            $slot++;

            # Flash is 'in general' an unrelated internal BIOS storage
            # See bug: #1334
            next if $info->{'Type'} && $info->{'Type'} =~ /Flash/i;

            my $manufacturer;
            if (
                $info->{'Manufacturer'}
                    &&
                ( $info->{'Manufacturer'} !~ /
                  Manufacturer
                      |
                  Undefined
                      |
                  None
                      |
                  ^0x
                      |
                  00000
                      |
                  \sDIMM
                  /ix )
            ) {
                $manufacturer = $info->{'Manufacturer'};
            }

            my $memory = {
                NUMSLOTS         => $slot,
                DESCRIPTION      => $info->{'Form Factor'},
                CAPTION          => $info->{'Locator'},
                SPEED            => getCanonicalSpeed($info->{'Speed'}),
                TYPE             => $info->{'Type'},
                SERIALNUMBER     => $info->{'Serial Number'},
                MEMORYCORRECTION => $infos->{16}[0]{'Error Correction Type'},
                MANUFACTURER     => $manufacturer
            };

            if ($info->{'Size'} && $info->{'Size'} =~ /^(\d+ \s .B)$/x) {
                $memory->{CAPACITY} = getCanonicalSize($1, 1024);
            }

            if ($info->{'Part Number'}
                    &&
                $info->{'Part Number'} !~ /
                    DIMM            |
                    NOT\s*AVAILABLE |
                    None            |
                    Not\s*Specified |
                    O\.E\.M\.       |
                    Part\s*Num      |
                    Ser\s*Num       |
                    Unknown
                /xi
            ) {
                $memory->{MODEL} = trimWhitespace(
                    getSanitizedString( hex2char($info->{'Part Number'}) )
                );
            }

            push @$memories, $memory;
        }
    } elsif ($infos->{6}) {

        foreach my $info (@{$infos->{6}}) {
            $slot++;

            my $memory = {
                NUMSLOTS => $slot,
                TYPE     => $info->{'Type'},
            };

            if ($info->{'Installed Size'} && $info->{'Installed Size'} =~ /^(\d+\s*.B)/i) {
                $memory->{CAPACITY} = getCanonicalSize($1, 1024);
            }

            push @$memories, $memory;
        }
    }

    return $memories;
}

1;
