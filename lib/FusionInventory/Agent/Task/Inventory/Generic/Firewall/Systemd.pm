package FusionInventory::Agent::Task::Inventory::Generic::Firewall::Systemd;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools::Constants;
use FusionInventory::Agent::Tools;

our $runMeIfTheseChecksFailed = ["FusionInventory::Agent::Task::Inventory::Generic::Firewall::Ufw"];

sub isEnabled {
    return
        canRun('systemctl');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $firewallStatus = _getFirewallStatus(
        logger => $logger
    );
    $inventory->addEntry(
        section => 'FIREWALL',
        entry   => {
            STATUS => $firewallStatus
        }
    );

}

sub _getFirewallStatus {
    my (%params) = @_;

    my $lines = getAllLines(
        command => 'systemctl status firewalld.service',
        %params
    );
    # multiline regexp to match for example :
    #   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
    #   Active: active (running) since Tue 2017-03-14 15:33:24 CET; 1h 16min ago
    # This permits to check if service is loaded, enabled and active
    return ($lines =~ /^\s*Loaded: loaded [^;]+firewalld[^;]*; [^;]*;[^\n]*\n\s*Active: active \(running\)/m) ?
        STATUS_ON :
        STATUS_OFF;
}

1;
