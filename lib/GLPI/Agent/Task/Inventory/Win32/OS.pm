package GLPI::Agent::Task::Inventory::Win32::OS;

use strict;
use warnings;
use integer;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Hostname;
use GLPI::Agent::Tools::Win32;

use constant    category    => "os";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my ($operatingSystem) = getWMIObjects(
        class      => 'Win32_OperatingSystem',
        properties => [ qw/
            Caption Version CSDVersion LastBootUpTime InstallDate
        / ]
    );

    my ($computerSystem) = getWMIObjects(
        class      => 'Win32_ComputerSystem',
        properties => [ qw/
            Name DNSHostName Domain
        / ]
    );

    my $arch = is64bit() ? '64-bit' : '32-bit';

    my $boottime = getFormatedWMIDateTime($operatingSystem->{LastBootUpTime});

    my $installDate = getFormatedWMIDateTime($operatingSystem->{InstallDate});
    $installDate = _getInstallDate() unless $installDate;

    my $os = {
        NAME           => "Windows",
        ARCH           => $arch,
        INSTALL_DATE   => $installDate,
        BOOT_TIME      => $boottime,
        KERNEL_VERSION => $operatingSystem->{Version},
        FULL_NAME      => $operatingSystem->{Caption},
        SERVICE_PACK   => $operatingSystem->{CSDVersion}
    };

    # Support DisplayVersion as Operating system version from Windows 10 20H1
    my $displayversion = getRegistryValue(
        path => 'HKEY_LOCAL_MACHINE/Software/Microsoft/Windows NT/CurrentVersion/DisplayVersion'
    );
    if ($displayversion) {
        $os->{VERSION} = $displayversion;
    } else {
        # Support ReleaseID as Operating system version for Windows 10
        my $releaseid = getRegistryValue(
            path => 'HKEY_LOCAL_MACHINE/Software/Microsoft/Windows NT/CurrentVersion/ReleaseId'
        );
        $os->{VERSION} = $releaseid
            if $releaseid;
    }

    if ($computerSystem->{Domain}) {
        $os->{DNS_DOMAIN} = $computerSystem->{Domain};
    }

    $inventory->setOperatingSystem($os);
}

sub _getInstallDate {
    my $installDate = getRegistryValue(
        path   => 'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows NT/CurrentVersion/InstallDate'
    );
    return unless $installDate;

    my $dec = hex2dec($installDate);
    return unless $dec;

    return getFormatedLocalTime($dec);
}

1;
