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

    my $usepkg = canRun("pkg") ? 1 : 0;
    # Find installation date for any well-known core package
    foreach my $corepackage (qw(SUNWcs SUNWcsr SUNWcsl SUNWcsd SUNWcslr SUNWcsu)) {
        my $installdate = _getInstallDate(
            command => ($usepkg ? "pkg info" : "pkginfo -l")." ".$corepackage,
            usepkg  => $usepkg,
            logger => $logger
        );
        unless (empty($installdate)) {
            $os->{INSTALL_DATE} = $installdate;
            last;
        }
    }

    $inventory->setOperatingSystem($os);
}

sub _getInstallDate {
    my (%params) = @_;

    return unless DateTime->require();

    my $usepkg = delete $params{usepkg};

    my @match = $usepkg ? getFirstMatch(
        pattern => qr/Last Install Time:\s+\S+\s+(\S+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)$/,
        %params
    ) : getFirstMatch(
        pattern => qr/INSTDATE:\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+):(\d+)$/,
        %params
    );
    return unless @match;

    my $datetime;
    eval {
        my $dt = DateTime->new(
            month   => month($match[0]),
            day     => $match[1],
            year    => $usepkg ? $match[5] : $match[2],
            hour    => $usepkg ? $match[2] : $match[3],
            minute  => $usepkg ? $match[3] : $match[4],
            second  => $usepkg ? $match[4] : 0,
        );
        $datetime = $dt->datetime(' ');
    };

    return $datetime;
}

1;
