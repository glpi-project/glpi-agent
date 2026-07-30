package GLPI::Agent::Task::Inventory::Linux::License::EEA;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant lic => '/opt/eset/eea/sbin/lic';

sub isEnabled {
    return canRun(lic);
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $license = _getEEALicense(logger => $logger);
    if ($license) {
        $inventory->addEntry(
            section => 'LICENSEINFOS',
            entry   => $license
        );
        $logger->debug2("Added license for $license->{NAME} [ENABLED]") if $logger;
    }
}

sub _getEEALicense {
    my (%params) = @_;

    my @lines = getAllLines(
        file    => $params{lic_status}, # Only used by tests
        command => lic . ' --status',
        %params
    );
    return unless @lines;

    my ($product_name, $public_id);
    foreach my $line (@lines) {
        last if empty($line) && $product_name;
        if ($line =~ /^Product name:\s*(.+?)(?:\s+for\s+(?:macOS|Linux|Windows))?$/i) {
            $product_name = $1;
        } elsif ($line =~ /^Public ID:\s*(\S+)/) {
            $public_id = $1;
        }
    }

    if ($public_id) {
        my $name = $product_name || 'ESET Endpoint Antivirus';
        return {
            NAME      => $name,
            FULLNAME  => $name,
            PRODUCTID => $public_id,
        };
    }

    return;
}

1;
