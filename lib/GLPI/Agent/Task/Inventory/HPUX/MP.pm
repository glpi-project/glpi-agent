package GLPI::Agent::Task::Inventory::HPUX::MP;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Network;

use constant    category    => "network";

#TODO driver pcislot virtualdev

sub isEnabled {
    return
        canRun('/opt/hpsmh/data/htdocs/comppage/getMPInfo.cgi') ||
        canRun('/opt/sfm/bin/CIMUtil');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $ipaddress = canRun('/opt/hpsmh/data/htdocs/comppage/getMPInfo.cgi') ?
        _parseGetMPInfo(logger => $logger) : _parseCIMUtil(logger => $logger);

    $inventory->addEntry(
        section => 'NETWORKS',
        entry => {
            DESCRIPTION => 'Management Interface - HP MP',
            TYPE        => 'Ethernet',
            MANAGEMENT  => 'MP',
            IPADDRESS   => $ipaddress,
        }
    );

}

sub _parseGetMPInfo {
    return getFirstMatch(
        command => '/opt/hpsmh/data/htdocs/comppage/getMPInfo.cgi',
        pattern => qr{RIBLink = "https?://($ip_address_pattern)";},
        @_
    );
}

sub _parseCIMUtil {
    return getFirstMatch(
        command => '/opt/sfm/bin/CIMUtil -e root/cimv2 HP_ManagementProcessor',
        pattern => qr{^IPAddress\s+:\s+($ip_address_pattern)},
        @_
    );
}

1;
