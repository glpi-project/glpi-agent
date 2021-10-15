package GLPI::Agent::Task::Inventory::Win32::CPU;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

################################################################################
#### Needed to support this module under other platforms than MSWin32 ##########
#### Needed to support WinRM RemoteInventory task ##############################
################################################################################
BEGIN {
    use English qw(-no_match_vars);
    if ($OSNAME ne 'MSWin32') {
        $INC{'Win32.pm'} = "-";
    }
}
################################################################################

use English qw(-no_match_vars);
use Win32;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Win32;
use GLPI::Agent::Tools::Generic;

use constant    category    => "cpu";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my @cpus = _getCPUs(%params);

    foreach my $cpu (@cpus) {
        $inventory->addEntry(
            section => 'CPUS',
            entry   => $cpu
        );
    }

    if (any { $_->{NAME} =~ /QEMU/i } @cpus) {
        $inventory->setHardware ({
            VMSYSTEM => 'QEMU'
        });
    }
}

sub _getCPUs {
    my (%params) = @_;

    my $remote = $params{inventory}->getRemote();

    my @dmidecodeInfos = $remote || Win32::GetOSName() eq 'Win2003' ?
        () : getCpusFromDmidecode();

    # the CPU description in WMI is false, we use the registry instead
    my $registryInfos = getRegistryKey(
        path   => "HKEY_LOCAL_MACHINE/Hardware/Description/System/CentralProcessor",
        # Important for remote inventory optimization
        required    => [ qw/Identifier ProcessorNameString VendorIdentifier/ ],
    );

    my $cpuId = 0;
    my $logicalId = 0;
    my @cpus;

    # Be aware, a bug on OS side may have reversed the order of processors infos regarding
    # dmi table order, see https://github.com/fusioninventory/fusioninventory-agent/issues/898
    # so we use dmidecode infos in priority even if it is not totally accurate
    foreach my $object (getWMIObjects(
        class      => 'Win32_Processor',
        properties => [ qw/
            NumberOfCores NumberOfLogicalProcessors ProcessorId MaxClockSpeed
            SerialNumber Name Description Manufacturer
            / ]
    )) {

        my $dmidecodeInfo = $dmidecodeInfos[$cpuId];
        my $registryInfo  = $registryInfos->{"$logicalId/"};

        # Compute WMI threads for this CPU if not available in dmidecode, this is the case on win2003r2 with 932370 hotfix applied (see #2894)
        my $wmi_threads   = !$dmidecodeInfo->{THREAD} && $object->{NumberOfCores} ? $object->{NumberOfLogicalProcessors}/$object->{NumberOfCores} : undef;

        # Split CPUID from its value inside registry
        my @splitted_identifier = split(/ |\n/, $registryInfo->{'/Identifier'} || $object->{Description});

        my $name = $dmidecodeInfo->{NAME};
        unless ($name) {
            $name = trimWhitespace($registryInfo->{'/ProcessorNameString'} || $object->{Name});
            $name =~ s/\((R|TM)\)//gi if $name;
        }

        my $cpu = {
            CORE         => $dmidecodeInfo->{CORE} || $object->{NumberOfCores},
            THREAD       => $dmidecodeInfo->{THREAD} || $wmi_threads,
            DESCRIPTION  => $dmidecodeInfo->{DESCRIPTION} || $registryInfo->{'/Identifier'} || $object->{Description},
            NAME         => $name,
            MANUFACTURER => $dmidecodeInfo->{MANUFACTURER} || getCanonicalManufacturer($registryInfo->{'/VendorIdentifier'} || $object->{Manufacturer}),
            SERIAL       => $dmidecodeInfo->{SERIAL} || $object->{SerialNumber},
            SPEED        => $dmidecodeInfo->{SPEED} || $object->{MaxClockSpeed},
            FAMILYNUMBER => $dmidecodeInfo->{FAMILYNUMBER} || $splitted_identifier[2],
            MODEL        => $dmidecodeInfo->{MODEL} || $splitted_identifier[4],
            STEPPING     => $dmidecodeInfo->{STEPPING} || $splitted_identifier[6],
            ID           => $dmidecodeInfo->{ID} || $object->{ProcessorId}
        };

        # Some information are missing on Win2000
        if (!$cpu->{NAME} && !$remote && $ENV{PROCESSOR_IDENTIFIER}) {
            $cpu->{NAME} = $ENV{PROCESSOR_IDENTIFIER};
            if ($cpu->{NAME} =~ s/,\s(\S+)$//) {
                $cpu->{MANUFACTURER} = $1;
            }
        }

        if ($cpu->{SERIAL}) {
            $cpu->{SERIAL} =~ s/\s//g;
        }

        if (!$cpu->{SPEED} && $cpu->{NAME} =~ /([\d\.]+)s*(GHZ)/i) {
            $cpu->{SPEED} = {
                ghz => 1000,
                mhz => 1,
            }->{lc($2)} * $1;
        }

        # Support CORECOUNT total available cores
        $cpu->{CORECOUNT} = $dmidecodeInfo->{CORECOUNT}
            if ($dmidecodeInfo->{CORECOUNT});

        push @cpus, $cpu;

        $cpuId++;
        $logicalId = $logicalId + ($object->{NumberOfLogicalProcessors} // 1);
    }

    return @cpus;
}

1;
