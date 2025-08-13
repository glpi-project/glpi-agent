package GLPI::Agent::Task::Inventory::Virtualization::SolarisZones;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Solaris;
use GLPI::Agent::XML;

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
        getAllLines(command => '/usr/sbin/zoneadm list -ip', logger => $logger);

    foreach my $zone (@zones) {
        my ($zoneid, $zonename, $zonestatus, undef, $uuid, $zonebrand) = split(/:/, $zone);
        next if $zonename eq 'global';

        $zonestatus = "off" if $zonestatus eq "installed";
        $zonebrand = "Solaris Zones" if empty($zonebrand);

        # Memory considerations depends on rcapd or project definitions
        # Little hack, I go directly in /etc/zones reading mcap physcap for each zone.
        my $zonefile = "/etc/zones/$zonename.xml";

        my ($memory, $vcpu);
        $vcpu = getFirstMatch(
            command => '/usr/sbin/psrinfo -p -v',
            pattern => qr/The physical processor has \d+ cores and (\d+) virtual processors/,
            logger  => $logger
        );

        # Read xml config on OmniOS to discover memory and cpu cap
        my $zone = getAllLines(file => $zonefile);
        my $config = GLPI::Agent::XML->new(string => $zone, force_array => [ qw(rctl) ])->dump_as_hash();
        if ($config && $config->{zone} && ref($config->{zone}->{rctl}) eq 'ARRAY') {
            foreach my $name (qw(zone.max-locked-memory zone.max-physical-memory)) {
                my ($conf) = first { $_->{'-name'} eq $name } @{$config->{zone}->{rctl}}
                    or next;
                $memory = getCanonicalSize($conf->{'rctl-value'}->{'-limit'} . "bytes", 1024)
                    if $conf->{'rctl-value'} && $conf->{'rctl-value'}->{'-limit'};
                last if $memory;
            }

            my ($cpucap) = first { $_->{'-name'} eq "zone.cpu-cap" } @{$config->{zone}->{rctl}};
            $vcpu = int($cpucap->{'rctl-value'}->{'-limit'}/100)
                if $cpucap && $cpucap->{'rctl-value'} && $cpucap->{'rctl-value'}->{'-limit'};

        } else {
            my $line = getFirstMatch(
                file    => $zonefile,
                pattern => qr/(.*mcap.*)/,
                logger  => $logger
            );

            if ($line) {
                my $memcap = $line;
                $memcap =~ s/[^\d]+//g;
                $memory = $memcap / 1024 / 1024;
            }

            # Use old command to set vcpu if not found before
            $vcpu = getFirstLine(command => '/usr/sbin/psrinfo -p', logger => $logger)
                unless $vcpu;
        }

        $inventory->addEntry(
            section => 'VIRTUALMACHINES',
            entry => {
                MEMORY    => $memory,
                NAME      => $zonename,
                UUID      => $uuid,
                STATUS    => $zonestatus,
                SUBSYSTEM => $zonebrand,
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
