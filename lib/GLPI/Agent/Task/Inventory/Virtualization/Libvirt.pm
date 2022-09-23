package GLPI::Agent::Task::Inventory::Virtualization::Libvirt;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;
use GLPI::Agent::XML;

sub isEnabled {
    return canRun('virsh');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $machine (_getMachines(logger => $logger)) {
        $inventory->addEntry(
            section => 'VIRTUALMACHINES', entry => $machine
        );
    }

    foreach my $machine (_getMachines(logger => $logger, uri => 'lxc:///')) {
        $inventory->addEntry(
            section => 'VIRTUALMACHINES', entry => $machine
        );
    }

}

sub _getMachines {
    my (%params) = @_;


    my $uri_param = $params{'uri'} ? "-c ".$params{'uri'} : "";

    my @machines = _parseList(
        command => "virsh $uri_param --readonly list --all",
        logger  => $params{logger}
    );

    foreach my $machine (@machines) {
        my %infos = _parseDumpxml(
            command => "virsh $uri_param --readonly dumpxml $machine->{NAME}",
            logger  => $params{logger}
        );

        $machine->{MEMORY}    = $infos{memory};
        $machine->{UUID}      = $infos{uuid};
        $machine->{SUBSYSTEM} = $infos{vmtype};
        $machine->{VCPU}      = $infos{vcpu};
    }

    return @machines;
}

sub _parseList {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @machines;
    foreach my $line (@lines) {
        next if $line =~ /^\s*Id/;
        next if $line =~ /^-{5}/;
        next unless $line =~ /^\s*(\d+|)(\-|)\s+(\S+)\s+(\S.+)/;

        my $name = $3;

        # ignore Xen Dom0
        next if $name eq 'Domain-0';

        my $status = $4;
        $status =~ s/^shut off/off/;

        my $machine = {
            NAME      => $name,
            STATUS    => $status,
            VMTYPE    => "libvirt",
        };

        push @machines, $machine;
    }

    return @machines;
}

sub _getKeyText {
    my ($key) = @_;

    if (ref($key) eq 'HASH') {
        return $key->{'#text'};
    } else {
        return $key;
    }
}

sub _parseDumpxml {
    my (%params) = @_;

    my $xml = getAllLines(%params);
    if (!$xml) {
        $params{logger}->error("No virsh xmldump output");
        return;
    }

    my $data;
    eval {
        $data = GLPI::Agent::XML->new(string => $xml)->dump_as_hash();
    };
    if ($EVAL_ERROR) {
        $params{logger}->error("Failed to parse XML output");
        return;
    }

    my $vcpu   = _getKeyText($data->{domain}{vcpu});
    my $uuid   = _getKeyText($data->{domain}{uuid});
    my $vmtype = $data->{domain}{'-type'};
    my $memory;
    my $currentMemory = _getKeyText($data->{domain}{currentMemory});
    if ($currentMemory =~ /(\d+)\d{3}$/) {
        $memory = $1;
    }

    return (
        vcpu => $vcpu,
        uuid => $uuid,
        vmtype => $vmtype,
        memory => $memory,
    );
}

1;
