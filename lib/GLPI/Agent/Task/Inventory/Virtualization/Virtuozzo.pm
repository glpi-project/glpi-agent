package GLPI::Agent::Task::Inventory::Virtualization::Virtuozzo;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Network;
use GLPI::Agent::Tools::Virtualization;

sub isEnabled {
    # Avoid duplicated entry with libvirt
    return if canRun('virsh');

    return canRun('vzlist');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $vz (@{_parseVzlist(%params)}) {
        $inventory->addEntry(
            section => 'VIRTUALMACHINES',
            entry => $vz
        );
    }
}

sub _parseVzlist {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my @lines = getAllLines(
        command => 'vzlist --all --no-header -o hostname,ctid,cpulimit,status,ostemplate',
        %params
    );

    return unless @lines;

    my $vzlist;
    my $confctid_template = $params{ctid_template} ||
        "/etc/vz/conf/__XXX__.conf";

    my $hostID = $inventory->getHardware('UUID') || '';

    my %status_list = (
        'stopped'   => STATUS_OFF,
        'running'   => STATUS_RUNNING,
        'paused'    => STATUS_PAUSED,
        'mounted'   => STATUS_OFF,
        'suspended' => STATUS_PAUSED,
        'unknown'   => STATUS_OFF,
    );

    foreach my $line (@lines) {
        my ($name, $ctid, $cpus, $status, $subsys) = split(/[ \t]+/, $line);

        my $ctid_conf = $confctid_template;
        $ctid_conf =~ s/__XXX__/$ctid/;

        my $memory = getFirstMatch(
            file    => $ctid_conf,
            pattern => qr/^SLMMEMORYLIMIT="\d+:(\d+)"$/,
            logger  => $logger,
        );
        if ($memory) {
            $memory = $memory / 1024 / 1024;
        } else {
            $memory = getFirstMatch(
                file    => $ctid_conf,
                pattern => qr/^PRIVVMPAGES="\d+:(\d+)"$/,
                logger  => $logger,
            );
            if ($memory) {
                $memory = $memory * 4 / 1024;
            } else {
                $memory = getFirstMatch(
                    file    => $ctid_conf,
                    pattern => qr/^PHYSPAGES="\d+:(\d+\w{0,1})"$/,
                    logger  => $logger,
                );
                if ($memory) {
                    $memory =~ /(\d+)(\w{0,1})/;
                    if ($2 eq "M") {
                        $memory=$1;
                    } elsif ($2 eq "G") {
                        $memory=$1*1024;
                    } elsif ($2 eq "K") {
                        $memory=$1/1024;
                    } else {
                        $memory=$1/1024/1024;
                    }
                }
            }
        }

        # compute specific identifier for the guest, as CTID is
        # unique only for the local hosts
        my $uuid = $hostID . '-' . $ctid;

        $status = $status_list{$status} || STATUS_OFF;

        my $container = {
            NAME      => $name,
            VCPU      => $cpus,
            UUID      => $uuid,
            MEMORY    => $memory,
            STATUS    => $status,
            SUBSYSTEM => $subsys,
            VMTYPE    => "virtuozzo",
        };

        my $mac = _getMACs(
            status  => $status,
            ctid    => $ctid,
            logger  => $logger
        );
        $container->{MAC} = $mac if $mac;

        push @{$vzlist}, $container;
    }

    return $vzlist;
}

sub _getMACs {
    my (%params) = @_;

    # Don't try to run a command in a not running container
    return unless $params{status} && $params{status} eq STATUS_RUNNING;

    my @ipLines = getAllLines(
        command => "vzctl exec '$params{ctid}' 'ip -0 a'",
        %params
    );

    my @macs;
    foreach my $line (@ipLines) {
        next unless $line =~ /^\s+link\/ether ($mac_address_pattern)\s/;
        push @macs, $1;
    }

    return join('/', @macs);
}


1;
