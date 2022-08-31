package GLPI::Agent::Task::Inventory::Generic::Networks::iLO;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Network;

our $runMeIfTheseChecksFailed = ['GLPI::Agent::Task::Inventory::Generic::Ipmi::Lan'];

sub isEnabled {
    return OSNAME eq 'MSWin32' ?
        canRun("C:\\Program\ Files\\HP\\hponcfg\\hponcfg.exe") :
        canRun('hponcfg');
}

sub _parseHponcfg {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my $interface = {
        DESCRIPTION => 'Management Interface - HP iLO',
        TYPE        => 'ethernet',
        MANAGEMENT  => 'iLO',
        STATUS      => 'Down',
    };

    foreach my $line (@lines) {
        if ($line =~ /<IP_ADDRESS VALUE="($ip_address_pattern)" ?\/>/) {
            $interface->{IPADDRESS} = $1 unless $1 eq '0.0.0.0';
        }
        if ($line =~ /<SUBNET_MASK VALUE="($ip_address_pattern)" ?\/>/) {
            $interface->{IPMASK} = $1;
        }
        if ($line =~ /<GATEWAY_IP_ADDRESS VALUE="($ip_address_pattern)"\/>/) {
            $interface->{IPGATEWAY} = $1;
        }
        if ($line =~ /<NIC_SPEED VALUE="([0-9]+)" ?\/>/) {
            $interface->{SPEED} = $1;
        }
        if ($line =~ /<ENABLE_NIC VALUE="Y" ?\/>/) {
            $interface->{STATUS} = 'Up';
        }
        if ($line =~ /not found/) {
            chomp $line;
            $params{logger}->error("error in hponcfg output: $line")
                if $params{logger};
        }
    }
    $interface->{IPSUBNET} = getSubnetAddress(
        $interface->{IPADDRESS}, $interface->{IPMASK}
    );

    return $interface;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $command = OSNAME eq 'MSWin32' ?
        '"c:\Program Files\HP\hponcfg\hponcfg" /a /w output.txt >nul 2>&1 && type output.txt' :
        'hponcfg -aw -';


    my $entry = _parseHponcfg(
        logger => $logger,
        command => $command
    );

    $inventory->addEntry(
        section => 'NETWORKS',
        entry   => $entry
    );
}

1;
