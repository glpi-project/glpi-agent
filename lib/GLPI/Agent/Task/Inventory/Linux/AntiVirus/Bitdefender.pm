package GLPI::Agent::Task::Inventory::Linux::AntiVirus::Bitdefender;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use UNIVERSAL::require;

use GLPI::Agent::Tools;

sub isEnabled {
    return canRun('/opt/bitdefender-security-tools/bin/bduitool');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $antivirus = _getBitdefenderInfo(logger => $logger);
    if ($antivirus) {
        $inventory->addEntry(
            section => 'ANTIVIRUS',
            entry   => $antivirus
        );

        $logger->debug2("Added $antivirus->{NAME}" . ($antivirus->{VERSION} ? " v$antivirus->{VERSION}" : ""))
            if $logger;
    }
}

sub _getBitdefenderInfo {
    my (%params) =  (
        command => '/opt/bitdefender-security-tools/bin/bduitool get ps',
        @_
    );

    my @output = getAllLines(%params)
        or return;

    my $av = {
        "name" => 'Bitdefender Endpoint Security Tools (BEST) for Linux',
        "manufacturer" => 'Bitdefender',
        "company" => 'Bitdefender',
        "uptodate" => 1,
    };

    foreach my $line (@output) {
        my ($key, $value) = $line =~ /^([^:]+):\s+(.+)$/
            or next;
        if ($key eq "Product version") {
            $av->{version} = $value;
        } elsif ($key eq "Engines version") {
            $av->{base_version} = $value;
        } elsif ($key eq "Antimalware status") {
            $av->{enabled} = $value eq "On" ? 1 : 0;
        } elsif ($key =~ /New (product update|security content) available/) {
            # Set "uptodate" to 0 if one of "new product update available" or "new security content available" is not "no"
            $av->{uptodate} = 0 if $value ne "no";
        } elsif ($key eq "Last security content update" && $value =~ /^(\d{4}-\d+-\d+) at/) {
            $av->{base_creation} = $1;
        }
    }

    return $av;
}

1;

