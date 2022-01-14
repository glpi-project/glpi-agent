package GLPI::Agent::Task::Inventory::Virtualization::SolarisZones;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Solaris;

sub isEnabled {
    return
        canRun('zoneadm') &&
        getZone() eq 'global' &&
        _check_solaris_valid_release();
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my @zones =
        getAllLines(command => '/usr/sbin/zoneadm list -p', logger => $logger);

    foreach my $zone (@zones) {
        my ($zoneid, $zonename, $zonestatus, undef, $uuid) = split(/:/, $zone);
        next if $zonename eq 'global';

        # Memory considerations depends on rcapd or project definitions
        # Little hack, I go directly in /etc/zones reading mcap physcap for each zone.
        my $zonefile = "/etc/zones/$zonename.xml";

        my $line = getFirstMatch(
            file  => $zonefile,
            pattern => qr/(.*mcap.*)/
        );

        my $memory;

        if ($line) {
            my $memcap = $line;
            $memcap =~ s/[^\d]+//g;
            $memory = $memcap / 1024 / 1024;

        }

        my $vcpu = getFirstLine(command => '/usr/sbin/psrinfo -p');

        $inventory->addEntry(
            section => 'VIRTUALMACHINES',
            entry => {
                MEMORY    => $memory,
                NAME      => $zonename,
                UUID      => $uuid,
                STATUS    => $zonestatus,
                SUBSYSTEM => "Solaris Zones",
                VMTYPE    => "Solaris Zones",
                VCPU      => $vcpu,
            }
        );
    }
}

# check if Solaris 10 release is higher than 08/07
sub _check_solaris_valid_release{

    my $info = getReleaseInfo();
    my ($version) = $info->{version} =~ /^(\d+)/;
    return
        $version > 10
        ||
        $version == 10         &&
        $info->{subversion}    &&
        substr($info->{subversion}, 1) >= 4;
}

1;
