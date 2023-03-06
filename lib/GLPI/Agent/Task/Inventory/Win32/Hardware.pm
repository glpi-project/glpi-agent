package GLPI::Agent::Task::Inventory::Win32::Hardware;

use strict;
use warnings;
use integer;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Hostname;
use GLPI::Agent::Tools::License;
use GLPI::Agent::Tools::Win32;

use constant    category    => "hardware";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $remote    = $inventory->getRemote();

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
        decodeMicrosoftKey(
            getRegistryValue(
                path    => 'HKEY_LOCAL_MACHINE/Software/Microsoft/Windows NT/CurrentVersion/DigitalProductId',
                method  => "GetBinaryValue", # method for winrm remote inventory
            )) ||
        decodeMicrosoftKey(
            getRegistryValue(
                path => 'HKEY_LOCAL_MACHINE/Software/Microsoft/Windows NT/CurrentVersion/DigitalProductId4',
                method  => "GetBinaryValue", # method for winrm remote inventory
            ));

    my $description = getRegistryValue(path => 'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Services/lanmanserver/Parameters/srvcomment');

    my $swap = $operatingSystem->{TotalSwapSpaceSize} && $operatingSystem->{TotalSwapSpaceSize} =~ /^\d+$/ ?
        int($operatingSystem->{TotalSwapSpaceSize} / (1024 * 1024)) : undef;

    my $memory = $computerSystem->{TotalPhysicalMemory} && $computerSystem->{TotalPhysicalMemory} =~ /^\d+$/  ?
        int($computerSystem->{TotalPhysicalMemory} / (1024 * 1024)) : undef;

    my $uuid = ($computerSystemProduct->{UUID} && $computerSystemProduct->{UUID} !~ /^[0-]+$/) ?
        $computerSystemProduct->{UUID} : undef;

    # Finally get the name through native Win32::API if local inventory and as
    # WMI DB is sometimes broken
    my $hostname = $computerSystem->{DNSHostName} || $computerSystem->{Name};
    $hostname = getHostname(short => 1) unless ($hostname || $remote);

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
