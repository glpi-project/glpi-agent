package FusionInventory::Agent::Task::Inventory::Solaris::Hardware;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use Config;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Solaris;

use constant    category    => "hardware";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # Operating system informations
    my $info          = getReleaseInfo();
    my $kernelArch    = getFirstLine(
        logger  => $logger,
        command => 'arch -k'
    );
    my $proct         = getFirstLine(
        logger  => $logger,
        command => 'uname -p'
    );
    my $platform      = getFirstLine(
        logger  => $logger,
        command => 'uname -i'
    );
    my $hostid        = getFirstLine(
        logger  => $logger,
        command => 'hostid'
    );
    my $description   = "$platform($kernelArch)/$proct HostID=$hostid";

    my $hardware = {
        OSNAME      => "Solaris",
        OSVERSION   => $info->{version},
        OSCOMMENTS  => $info->{subversion},
        DESCRIPTION => $description
    };

    my $arch = $Config{archname} =~ /^i86pc/ ? 'i386' : 'sparc';
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
