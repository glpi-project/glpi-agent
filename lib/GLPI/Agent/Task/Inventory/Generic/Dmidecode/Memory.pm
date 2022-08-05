package GLPI::Agent::Task::Inventory::Generic::Dmidecode::Memory;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;
use GLPI::Agent::Tools::PartNumber;

use constant    category    => "memory";

# Run after virtualization to decide if found component is virtual
our $runAfterIfEnabled = [ qw(
    GLPI::Agent::Task::Inventory::Vmsystem
    GLPI::Agent::Task::Inventory::Win32::Hardware
    GLPI::Agent::Task::Inventory::Linux::Memory
    GLPI::Agent::Task::Inventory::BSD::Memory
)];

sub isEnabled {
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

    my ($memories, $slot, %defaults);

    my $bios_infos   = $infos->{0}->[0];
    my $bios_vendor  = $bios_infos->{Vendor} // "";
    my $bios_version = $bios_infos->{Version}      // "";

    if ($bios_vendor =~ /^Microsoft/i && $bios_version =~ /^Hyper-V/i) {
        %defaults = (
            Description  => "Hyper-V Memory",
            Manufacturer => $bios_vendor,
        );
    }

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
                  \d{4}
                      |
                  \sDIMM
                  /ix )
            ) {
                $manufacturer = $info->{'Manufacturer'};
            }

            my $memory = {
                NUMSLOTS         => $slot,
                DESCRIPTION      => $info->{'Form Factor'} // $defaults{Description},
                CAPTION          => $info->{'Locator'},
                SPEED            => getCanonicalSpeed($info->{'Speed'}),
                TYPE             => $info->{'Type'},
                SERIALNUMBER     => $info->{'Serial Number'},
                MEMORYCORRECTION => $infos->{16}[0]{'Error Correction Type'},
                MANUFACTURER     => $manufacturer // $defaults{Manufacturer}
            };

            if ($info->{'Size'} && $info->{'Size'} =~ /^(\d+ \s .B)$/x) {
                $memory->{CAPACITY} = getCanonicalSize($1, 1024);
            }

            if ($info->{'Part Number'}
                    &&
                $info->{'Part Number'} !~ /
                    DIMM            |
                    Part\s*Num      |
                    Ser\s*Num
                /xi
            ) {
                $memory->{MODEL} = trimWhitespace(
                    getSanitizedString( hex2char($info->{'Part Number'}) )
                );
                $memory->{MODEL} =~ s/-+$//;
                my $partnumber_factory = GLPI::Agent::Tools::PartNumber->new(@_);
                my $partnumber = $partnumber_factory->match(
                    partnumber  => $memory->{MODEL},
                    category    => "memory",
                    mm_id       => $info->{'Module Manufacturer ID'} // '',
                );
                if ($partnumber) {
                    $memory->{MANUFACTURER} = $partnumber->manufacturer;
                    $memory->{SPEED} = $partnumber->speed
                        if !$memory->{SPEED} && $partnumber->speed;
                    $memory->{TYPE} = $partnumber->type
                        if !$memory->{TYPE} && $partnumber->type;
                }
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
