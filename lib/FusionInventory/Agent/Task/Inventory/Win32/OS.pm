package FusionInventory::Agent::Task::Inventory::Win32::OS;

use strict;
use warnings;
use integer;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Hostname;
use FusionInventory::Agent::Tools::License;
use FusionInventory::Agent::Tools::Win32;

sub isEnabled {
    return 1;
}

sub isEnabledForRemote {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $remotewmi = $inventory->getRemote();

    my ($operatingSystem) = getWMIObjects(
        class      => 'Win32_OperatingSystem',
        properties => [ qw/
            OSLanguage Caption Version SerialNumber Organization RegisteredUser
            CSDVersion TotalSwapSpaceSize LastBootUpTime InstallDate
        / ]
    );

    my ($computerSystem) = getWMIObjects(
        class      => 'Win32_ComputerSystem',
        properties => [ qw/
            Name DNSHostName Domain Workgroup PrimaryOwnerName TotalPhysicalMemory
        / ]
    );

    my ($computerSystemProduct) = getWMIObjects(
        class      => 'Win32_ComputerSystemProduct',
        properties => [ qw/UUID/ ]
    );

    my $key =
        decodeMicrosoftKey(getRegistryValue(path => 'HKEY_LOCAL_MACHINE/Software/Microsoft/Windows NT/CurrentVersion/DigitalProductId')) ||
        decodeMicrosoftKey(getRegistryValue(path => 'HKEY_LOCAL_MACHINE/Software/Microsoft/Windows NT/CurrentVersion/DigitalProductId4'));

    my $description =
        encodeFromRegistry(getRegistryValue(path => 'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Services/lanmanserver/Parameters/srvcomment'));

    my $arch = is64bit() ? '64-bit' : '32-bit';

    my $swap = $operatingSystem->{TotalSwapSpaceSize} ?
        int($operatingSystem->{TotalSwapSpaceSize} / (1024 * 1024)) : undef;

    my $memory = $computerSystem->{TotalPhysicalMemory} ?
        int($computerSystem->{TotalPhysicalMemory} / (1024 * 1024)) : undef;

    my $uuid = ($computerSystemProduct->{UUID} && $computerSystemProduct->{UUID} !~ /^[0-]+$/) ?
        $computerSystemProduct->{UUID} : undef;

    my $boottime = getFormatedWMIDateTime($operatingSystem->{LastBootUpTime});

    my $installDate = getFormatedWMIDateTime($operatingSystem->{InstallDate});
    $installDate = _getInstallDate() unless ($installDate || $remotewmi);

    # Finally get the name through native Win32::API if local inventory and as
    # WMI DB is sometimes broken
    my $hostname = $computerSystem->{DNSHostName} || $computerSystem->{Name};
    $hostname = getHostname(short => 1) unless ($hostname || $remotewmi);

    my $os = {
        NAME           => "Windows",
        ARCH           => $arch,
        INSTALL_DATE   => $installDate,
        BOOT_TIME      => $boottime,
        KERNEL_VERSION => $operatingSystem->{Version},
        FULL_NAME      => $operatingSystem->{Caption},
        SERVICE_PACK   => $operatingSystem->{CSDVersion}
    };

    # Support ReleaseID as Operating system version for Windows 10
    my $releaseid = getRegistryValue(
        path => 'HKEY_LOCAL_MACHINE/Software/Microsoft/Windows NT/CurrentVersion/ReleaseId'
    );

    # Support DisplayVersion as Operating system version from Windows 10 20H1
    my $displayversion = getRegistryValue(
        path => 'HKEY_LOCAL_MACHINE/Software/Microsoft/Windows NT/CurrentVersion/DisplayVersion'
    );
    if ($displayversion) {
        $os->{VERSION} = $displayversion;
    } elsif ($releaseid) {
        $os->{VERSION} = $releaseid;
    }

    # We want to always reset FQDN on remote wmi inventory as it was set to local
    # agent fqdn in Generic module
    $os->{FQDN} = $hostname if ($remotewmi);
    if ($computerSystem->{Domain}) {
        $os->{FQDN} .= '.'.$computerSystem->{Domain} if ($remotewmi);
        $os->{DNS_DOMAIN} = $computerSystem->{Domain};
    }

    $inventory->setOperatingSystem($os);

    $inventory->setHardware({
        NAME        => $hostname,
        DESCRIPTION => $description,
        UUID        => $uuid,
        WINPRODKEY  => $key,
        WINLANG     => $operatingSystem->{OSLanguage},
        OSNAME      => $operatingSystem->{Caption},
        OSVERSION   => $operatingSystem->{Version},
        WINPRODID   => $operatingSystem->{SerialNumber},
        WINCOMPANY  => $operatingSystem->{Organization},
        WINOWNER    => $operatingSystem->{RegisteredUser} ||
                       $computerSystem->{PrimaryOwnerName},
        OSCOMMENTS  => $operatingSystem->{CSDVersion},
        SWAP        => $swap,
        MEMORY      => $memory,
        WORKGROUP   => $computerSystem->{Domain} ||
                       $computerSystem->{Workgroup},
    });
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
