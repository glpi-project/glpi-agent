package GLPI::Agent::Task::Inventory::Linux::Uptime;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Time::HiRes qw(time);

use GLPI::Agent::Tools;

use constant    category    => "os";

sub isEnabled {
    return canRead('/proc/uptime');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $boottime = _getBootTime(
        logger  => $logger,
        file    => '/proc/uptime',
    )
        or return;
    $inventory->setOperatingSystem({
        BOOT_TIME => $boottime
    });
}

sub _getBootTime {
    my $time = time;
    my $uptime = getFirstMatch(
        pattern => qr/^([0-9.]+)/,
        @_
    );
    return unless $uptime;

    return getFormatedLocalTime($time - $uptime);
}

1;
