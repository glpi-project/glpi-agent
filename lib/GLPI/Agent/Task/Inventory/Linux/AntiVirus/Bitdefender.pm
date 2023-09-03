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

        $logger->debug2("Added $antivirus->{name}" . ($antivirus->{version} ? " v$antivirus->{version}" : ""))
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

    my $product_version = '';
    my $engines_version = '';
    my $enabled = '';
    my $antimalware_status = '';
    my $new_update_available = '';
    my $new_security_content_available = '';

    foreach my $line (@output) {
        my ($key, $value) = $line =~ /^([^:]+):\s+(.*)$/
            or next;
        if ($key eq "Product version") {
            $product_version = $value;
        } elsif ($key eq "Engines version") {
            $engines_version = $value;
        } elsif ($key eq "Antimalware status") {
            $antimalware_status = $value;
        } elsif ($key eq "New product update available") {
            $new_update_available = $value;
        } elsif ($key eq "New security content available") {
            $new_security_content_available = $value;
        }
    }

    $enabled = ($antimalware_status eq 'On') ? 1 : 0;

    # Set "uptodate" to 1 if both "new product update" and "new security content" are 'no'
    my $uptodate = ($new_update_available eq 'no' && $new_security_content_available eq 'no') ? 1 : 0;

    return {
        "name" => 'Bitdefender Endpoint Security Tools (BEST) for Linux',
        "manufacturer" => 'Bitdefender',
        "company" => 'Bitdefender',
        "version" => $product_version,
        "base_version" => $engines_version,
        "base_creation" => '',
        "enabled" => $enabled,
        "uptodate" => $uptodate,
        "expiration" => ''
    };
}

1;

