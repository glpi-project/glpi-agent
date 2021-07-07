package FusionInventory::Agent::Task::Inventory::Solaris::Bios;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use Config;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Solaris;

sub isEnabled {
    return
        canRun('showrev') ||
        canRun('/usr/sbin/smbios');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $arch = $Config{archname} =~ /^i86pc/ ? 'i386' : 'sparc';

    my ($bios, $hardware);

    if (getZone() eq 'global') {
        if (canRun('showrev')) {
            my $infos = _parseShowRev(logger => $logger);
            $bios->{SMODEL}        = $infos->{'Application architecture'};
            $bios->{SMANUFACTURER} = $infos->{'Hardware provider'};
        }

        if ($arch eq "i386") {
            my $infos = getSmbios(logger => $logger);

            my $biosInfos = $infos->{SMB_TYPE_BIOS};
            $bios->{BMANUFACTURER} = $biosInfos->{'Vendor'};
            $bios->{BVERSION}      = $biosInfos->{'Version String'};
            $bios->{BDATE}         = $biosInfos->{'Release Date'};

            my $systemInfos = $infos->{SMB_TYPE_SYSTEM};
            $bios->{SMANUFACTURER} = $systemInfos->{'Manufacturer'};
            $bios->{SMODEL}        = $systemInfos->{'Product'};
            $bios->{SKUNUMBER}     = $systemInfos->{'SKU Number'};
            $hardware->{UUID}      = $systemInfos->{'UUID'};

            my $motherboardInfos = $infos->{SMB_TYPE_BASEBOARD};
            $bios->{MMODEL}        = $motherboardInfos->{'Product'};
            $bios->{MSN}           = $motherboardInfos->{'Serial Number'};
            $bios->{MMANUFACTURER} = $motherboardInfos->{'Manufacturer'};
        } else {
            my $info = getPrtconfInfos(logger => $logger);
            if ($info) {
                my $root = first { ref $_ eq 'HASH' } values %$info;
                $bios->{SMODEL} = $root->{'banner-name'};
                if ($root->{openprom}->{version} =~
                    m{OBP \s+ ([\d.]+) \s+ (\d{4})/(\d{2})/(\d{2})}x) {
                    $bios->{BVERSION} = $1;
                    $bios->{BDATE}    = join('/', $4, $3, $2);
                }
            }

            my $command = -x '/opt/SUNWsneep/bin/sneep' ?
                '/opt/SUNWsneep/bin/sneep' : 'sneep';

            $bios->{SSN} = getFirstLine(
                command => $command,
                logger  => $logger
            );

            $hardware->{UUID} = _getUUID(
                command => '/usr/sbin/zoneadm -z global list -p',
                logger  => $logger
            );
        }
    } else {
        my $infos = _parseShowRev(logger => $logger);
        $bios->{SMANUFACTURER} = $infos->{'Hardware provider'};
        $bios->{SMODEL}        = "Solaris Containers";

        if ($arch eq 'sparc') {
            $hardware->{UUID} = _getUUID(
                command => '/usr/sbin/zoneadm list -p',
                logger  => $logger
            )
        }
    }

    $inventory->setBios($bios);
    $inventory->setHardware($hardware);
}

sub _parseShowRev {
    my (%params) = (
        command => 'showrev',
        @_
    );

    my $handle = getFileHandle(%params);
    return unless $handle;

    my $infos;
    while (my $line = <$handle>) {
        next unless $line =~ /^ ([^:]+) : \s+ (\S+)/x;
        $infos->{$1} = $2;
    }
    close $handle;

    return $infos;
}

sub _getUUID {
    my (%params) = (
        command => '/usr/sbin/zoneadm list -p',
        @_
    );

    my $line = getFirstLine(%params);
    return unless $line;

    my @info = split(/:/, $line);
    my $uuid = $info[4];

    return $uuid;
}

1;
