package FusionInventory::Agent::Task::Inventory::HPUX::Bios;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::HPUX;

use constant    category    => "bios";

sub isEnabled {
    return canRun('model');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $model = getFirstLine(command => 'model');

    my ($version, $serial);
    if (canRun('/usr/contrib/bin/machinfo')) {
        my $info = getInfoFromMachinfo(logger => $logger);
        $version = $info->{'Firmware info'}->{'firmware revision'};
        $serial  = $info->{'Platform info'}->{'machine serial number'};
    } else {
        my $handle = getFileHandle(
            logger  => $logger,
            command => "echo 'sc product cpu;il' | /usr/sbin/cstm",
            logger  => $logger
        );
        while (my $line = <$handle>) {
            next unless $line =~ /PDC Firmware/;
            next unless $line =~ /Revision:\s+(\S+)/;
            $version = "PDC $1";
        }
        close $handle;

        $serial = getFirstMatch(
            logger  => $logger,
            command => "echo 'sc product system;il' | /usr/sbin/cstm",
            pattern => qr/^System Serial Number:\s+: (\S+)/
        );
    }

    $inventory->setBios({
        BVERSION      => $version,
        BMANUFACTURER => "HP",
        SMANUFACTURER => "HP",
        SMODEL        => $model,
        SSN           => $serial,
    });
}

1;
