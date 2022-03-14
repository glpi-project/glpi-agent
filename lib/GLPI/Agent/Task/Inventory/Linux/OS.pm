package GLPI::Agent::Task::Inventory::Linux::OS;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Unix;

use constant    category    => "os";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $kernelRelease = Uname("-r");

    my $hostid = getFirstLine(
        logger  => $logger,
        command => 'hostid'
    );

    my $os = {
        HOSTID         => $hostid,
        KERNEL_VERSION => $kernelRelease,
    };

    my $installdate = _getOperatingSystemInstallDate(logger => $logger);
    $os->{INSTALL_DATE} = $installdate
        if $installdate;

    $inventory->setOperatingSystem($os);
}

sub _getOperatingSystemInstallDate {
    my (%params) = @_;

    # Check for basesystem package installation date on rpm base systems
    if (canRun('rpm')) {
        my $time = _rpmBasesystemInstallDate(%params);
        return $time if $time;
    }

    # Check for dpkg based systems (debian, ubuntu) as base-files.list is generated
    # when base-files package is installed
    return _debianInstallDate()
        if has_file("/var/lib/dpkg/info/base-files.list");

    # Otherwise read birth date of root file system
    return getRootFSBirth(%params);
}

sub _rpmBasesystemInstallDate {
    my (%params) = (
        command => 'rpm -qa --queryformat \'%{INSTALLTIME}\n\' basesystem',
        @_
    );

    my $date = getFirstLine(%params);

    my $installdate;
    if (DateTime->require()) {
        eval {
            my $dt = DateTime->from_epoch( epoch => $date );
            $installdate = $dt->datetime(' ');
        }
    } else {
        $installdate = getFormatedLocalTime($date);
    }

    return $installdate;
}

sub _debianInstallDate {
    my (%params) = (
        command => 'stat -c %w /var/lib/dpkg/info/base-files.list',
        @_
    );

    return getFirstMatch(
        pattern => qr{^(\d+-\d+-\d+\s\d+:\d+:\d+)},
        %params
    );
}

1;
