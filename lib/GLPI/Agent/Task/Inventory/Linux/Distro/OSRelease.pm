package GLPI::Agent::Task::Inventory::Linux::Distro::OSRelease;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

sub isEnabled {
  return has_file('/etc/os-release');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $handle = getFileHandle(file => '/etc/os-release');

    my ($name, $version, $description);
    while (my $line = <$handle>) {
        $name        = $1 if $line =~ /^NAME="?([^"]+)"?/;
        $version     = $1 if $line =~ /^VERSION="?([^"]+)"?/;
        $description = $1 if $line =~ /^PRETTY_NAME="?([^"]+)"?/;
    }
    close $handle;

    # Handle Debian case where version is not complete like in Ubuntu
    # by checking /etc/debian_version
    if (has_file('/etc/debian_version')) {
        my $debian_version = getFirstLine(file => '/etc/debian_version');
        $version = $debian_version
            if $debian_version && $debian_version =~ /^\d/;
    }

    $inventory->setOperatingSystem({
        NAME      => $name,
        VERSION   => $version,
        FULL_NAME => $description
    });

}

1;
