package GLPI::Agent::Task::Inventory::Solaris::OS;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use UNIVERSAL::require;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Solaris;

use constant    category    => "os";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # Operating system informations
    my $info          = getReleaseInfo();
    my $kernelVersion = Uname("-v");
    my $hostid        = getFirstLine(
        logger  => $logger,
        command => 'hostid'
    );

    my $os = {
        NAME           => "Solaris",
        HOSTID         => $hostid,
        FULL_NAME      => $info->{fullname},
        VERSION        => $info->{version},
        SERVICE_PACK   => $info->{subversion},
        KERNEL_VERSION => $kernelVersion
    };

    my $installdate = _getInstallDate(
        command => (canRun("pkg") ? "pkg info" : "pkginfo -l")." SUNWcs",
        logger => $logger
    );
    $os->{INSTALL_DATE} = $installdate
        if $installdate;

    $inventory->setOperatingSystem($os);
}

sub _getInstallDate {
    my (%params) = @_;

    return unless DateTime->require();

    my @match = getFirstMatch(
        pattern => qr/Last Install Time:\s+\S+\s+(\S+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)$/,
        %params
    );

    my $datetime;
    eval {
        my $dt = DateTime->new(
            month   => month($match[0]),
            day     => $match[1],
            year    => $match[5],
            hour    => $match[2],
            minute  => $match[3],
            second  => $match[4],
        );
        $datetime = $dt->datetime(' ');
    };

    return $datetime;
}

1;
