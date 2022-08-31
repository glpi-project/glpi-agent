package GLPI::Agent::Task::Inventory::Solaris::Bios;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Config;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Solaris;

use constant    category    => "bios";

sub isEnabled {
    return canRun('showrev') || canRun('/usr/sbin/smbios');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $archname = $inventory->getRemote() ? Uname("-m") : $Config{archname};
    my $arch = $archname =~ /^i86pc/ ? 'i386' : 'sparc';

    my ($bios, $infos);
    if (canRun('showrev')) {
        $infos = _parseShowRev(logger => $logger);
        $bios->{SMANUFACTURER} = $infos->{'Hardware provider'};
    }
    if (getZone() eq 'global') {
        $bios->{SMODEL}        = $infos->{'Application architecture'};

        if ($arch eq "i386") {
            my $smbios = getSmbios(logger => $logger);

            if ($smbios) {
                my $biosInfos = $smbios->{SMB_TYPE_BIOS};
                $bios->{BMANUFACTURER} = $biosInfos->{'Vendor'};
                $bios->{BVERSION}      = $biosInfos->{'Version String'};
                $bios->{BDATE}         = $biosInfos->{'Release Date'};

                my $systemInfos = $smbios->{SMB_TYPE_SYSTEM};
                $bios->{SMANUFACTURER} = $systemInfos->{'Manufacturer'};
                $bios->{SMODEL}        = $systemInfos->{'Product'};
                $bios->{SKUNUMBER}     = $systemInfos->{'SKU Number'};

                my $motherboardInfos = $smbios->{SMB_TYPE_BASEBOARD};
                $bios->{MMODEL}        = $motherboardInfos->{'Product'};
                $bios->{MSN}           = $motherboardInfos->{'Serial Number'};
                $bios->{MMANUFACTURER} = $motherboardInfos->{'Manufacturer'};
            }
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

            my $command = canRun('/opt/SUNWsneep/bin/sneep') ?
                '/opt/SUNWsneep/bin/sneep' : 'sneep';

            $bios->{SSN} = getFirstLine(
                command => $command,
                logger  => $logger
            );
        }
    } else {
        $bios->{SMODEL}        = "Solaris Containers";
    }

    return unless $bios;

    $inventory->setBios($bios);
}

sub _parseShowRev {
    my (%params) = (
        command => 'showrev',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my $infos;
    foreach my $line (@lines) {
        next unless $line =~ /^ ([^:]+) : \s+ (\S+)/x;
        $infos->{$1} = $2;
    }

    return $infos;
}

1;
