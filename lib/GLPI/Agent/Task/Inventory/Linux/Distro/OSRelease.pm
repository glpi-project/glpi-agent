package GLPI::Agent::Task::Inventory::Linux::Distro::OSRelease;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

sub isEnabled {
    return canRead('/etc/os-release');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $os = _getOSRelease(file => '/etc/os-release');

    # Handle Debian case where version is not complete like in Ubuntu
    # by checking /etc/debian_version
    _fixDebianOS(file => '/etc/debian_version', os => $os)
        if canRead('/etc/debian_version');

    # Handle Astra Linux version information
    _fixAstraOS(file => '/etc/astra/build_version', os => $os)
        if canRead('/etc/astra/build_version');

    # Handle Astra Linux license information
    _fixAstraLicense(file => '/etc/astra_license', os => $os)
        if canRead('/etc/astra_license');

    # Handle CentOS case as version is not well-defined on this distro
    # See https://bugs.centos.org/view.php?id=8359
    _fixCentOS(file => '/etc/centos-release', os => $os)
        if canRead('/etc/centos-release') && (!$os->{VERSION} || $os->{VERSION} =~ /^\d+ /);

    $inventory->setOperatingSystem($os);
}

sub _getOSRelease {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my $os;
    foreach my $line (@lines) {
        $os->{NAME}      = $1 if $line =~ /^NAME="?([^"]+)"?/;
        $os->{VERSION}   = $1 if $line =~ /^VERSION="?([^"]+)"?/;
        $os->{FULL_NAME} = $1 if $line =~ /^PRETTY_NAME="?([^"]+)"?/;
    }

    return $os;
}

sub _fixDebianOS {
    my (%params) = @_;

    my $os = $params{os} // {};

    my $debian_version = getFirstLine(%params);
    $os->{VERSION} = $debian_version
        if $debian_version && $debian_version =~ /^\d/;
}

sub _fixAstraOS {
    my (%params) = @_;

    my $os = $params{os} // {};

    my $astra_version = getFirstLine(%params);
    $os->{VERSION} = $astra_version
        if $astra_version && $astra_version =~ /^\d/;
}

sub _fixAstraLicense {
    my (%params) = @_;

    my $os = $params{os} // {};
    my @lines = getAllLines(%params) or return;

    foreach my $line (@lines) {
        if ($line =~ /^DESCRIPTION="?(.*?)"?$/) {
            my $edition = $1;
            
            my $security_level = 'unknown';
            
            if ($edition =~ /^([^\s()]+)\s*\(/) {
                $security_level = $1;
            }
            elsif ($edition =~ /\(([^\s()]+)\)/) {
                $security_level = $1;
            }
            elsif ($edition =~ /\(([^)]+)\)/) {
                ($security_level) = split(/\s+/, $1);
            }
            
            $security_level =~ s/^\s+|\s+$//g;
            $security_level = 'unknown' unless $security_level;
            
            $os->{FULL_NAME} =~ s/\(.*?\)//g;
            $os->{FULL_NAME} =~ s/\s+$//;
            $os->{FULL_NAME} .= " (Security level: $security_level)";
            
            last;
        }
    }
}

sub _fixCentOS {
    my (%params) = @_;

    my $os = $params{os} // {};

    my $centos_release = getFirstLine(%params)
        or return;
    ($os->{VERSION}) = $centos_release =~ /^CentOS .* ([0-9.]+.*)$/;
}

1;
