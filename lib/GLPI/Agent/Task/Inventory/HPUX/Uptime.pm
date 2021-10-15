package GLPI::Agent::Task::Inventory::HPUX::Uptime;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "hardware";

sub isEnabled {
    return
        canRun('uptime') &&
        canRun('uname');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $arch   = Uname("-m");
    my $uptime = _getUptime(command => 'uptime');
    $inventory->setHardware({
        DESCRIPTION => "$arch/$uptime"
    });
}

sub _getUptime {
    my ($days, $hours, $minutes) = getFirstMatch(
        pattern => qr/up \s (?:(\d+)\sdays\D+)? (\d{1,2}) : (\d{1,2})/x,
        @_
    );

    my $uptime = 0;
    $uptime += $days * 24 * 3600 if $days;
    $uptime += $hours * 3600;
    $uptime += $minutes * 60;

    return $uptime;
}

1;
