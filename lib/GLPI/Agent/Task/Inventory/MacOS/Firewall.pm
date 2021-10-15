package GLPI::Agent::Task::Inventory::MacOS::Firewall;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Constants;

use constant    category    => "firewall";

sub isEnabled {
    return canRun('defaults') && canRun('launchctl');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger = $params{logger};

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

    return STATUS_OFF unless _checkFirewallService(%params);

    my $status = getFirstMatch(
        command => 'defaults read /Library/Preferences/com.apple.alf globalstate',
        pattern => qr/^(\d)$/,
        %params
    );
    if ($status && $status eq '1') {
        $status = STATUS_ON;
    } else {
        $status = STATUS_OFF;
    }

    return $status;
}

sub _checkFirewallService {
    my (%params) = @_;

    my $pid = _getFirewallServicePID(
        file => $params{pidFile} || undef
    );
    return unless $pid;

    return _checkRunning(
        pid => $pid,
        file => $params{runningFile} || undef
    );
}

sub _getFirewallServicePID {
    my (%params) = @_;

    return getFirstMatch(
        command => 'launchctl list',
        pattern => qr/^(\d+)\s+\S+\s+com\.apple\.alf$/,
        %params
    );
}

sub _checkRunning {
    my (%params) = @_;
    return unless $params{pid};

    return getFirstMatch(
            command => 'sudo launchctl procinfo ' . $params{pid},
            pattern => qr/^\s*state = running\s*$/,
            %params
        ) ?
        1 :
        0;
}

1;
