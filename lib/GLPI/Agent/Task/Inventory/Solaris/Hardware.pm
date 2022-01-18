package GLPI::Agent::Task::Inventory::Solaris::Hardware;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Config;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Solaris;

use constant    category    => "hardware";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $kernelArch = getFirstLine(
        logger  => $logger,
        command => 'arch -k'
    );
    my $proct      = Uname("-p");
    my $platform   = Uname("-i");
    my $hostid     = getFirstLine(
        logger  => $logger,
        command => 'hostid'
    );
    my $description   = "$platform($kernelArch)/$proct HostID=$hostid";

    my $hardware = {
        DESCRIPTION => $description
    };

    my $archname = $inventory->getRemote() ? Uname("-m") : $Config{archname};
    my $arch = $archname =~ /^i86pc/ ? 'i386' : 'sparc';
    if (getZone() eq 'global') {
        if ($arch eq "i386") {
            my $infos = getSmbios(logger => $logger);
            $hardware->{UUID} = $infos->{SMB_TYPE_SYSTEM}->{'UUID'}
                if $infos && $infos->{SMB_TYPE_SYSTEM};
        } else {
            $hardware->{UUID} = _getUUID(
                command => '/usr/sbin/zoneadm -z global list -p',
                logger  => $logger
            );
        }
    } elsif ($arch eq 'sparc') {
        $hardware->{UUID} = _getUUID( logger  => $logger );
    }

    $inventory->setHardware($hardware);
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
