package FusionInventory::Agent::Task::Inventory::Win32::Hardware;

use strict;
use warnings;
use integer;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Hostname;
use FusionInventory::Agent::Tools::License;
use FusionInventory::Agent::Tools::Win32;

use constant    category    => "hardware";

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
            OSLanguage SerialNumber Organization RegisteredUser TotalSwapSpaceSize
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

    my $swap = $operatingSystem->{TotalSwapSpaceSize} ?
        int($operatingSystem->{TotalSwapSpaceSize} / (1024 * 1024)) : undef;

    my $memory = $computerSystem->{TotalPhysicalMemory} ?
        int($computerSystem->{TotalPhysicalMemory} / (1024 * 1024)) : undef;

    my $uuid = ($computerSystemProduct->{UUID} && $computerSystemProduct->{UUID} !~ /^[0-]+$/) ?
        $computerSystemProduct->{UUID} : undef;

    # Finally get the name through native Win32::API if local inventory and as
    # WMI DB is sometimes broken
    my $hostname = $computerSystem->{DNSHostName} || $computerSystem->{Name};
    $hostname = getHostname(short => 1) unless ($hostname || $remotewmi);

    $inventory->setHardware({
        NAME        => $hostname,
        DESCRIPTION => $description,
        UUID        => $uuid,
        WINPRODKEY  => $key,
        WINLANG     => $operatingSystem->{OSLanguage},
        WINPRODID   => $operatingSystem->{SerialNumber},
        WINCOMPANY  => $operatingSystem->{Organization},
        WINOWNER    => $operatingSystem->{RegisteredUser} ||
                       $computerSystem->{PrimaryOwnerName},
        SWAP        => $swap,
        MEMORY      => $memory,
        WORKGROUP   => $computerSystem->{Domain} ||
                       $computerSystem->{Workgroup},
    });
}

1;
