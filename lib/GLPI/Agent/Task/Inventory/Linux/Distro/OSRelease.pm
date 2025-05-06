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

    # Handle Astra Linux information
    _fixAstraOS(os => $os)
        if canRead('/etc/astra/build_version');

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
    my $os = $params{os} ||= {};

    if (my $version = getFirstLine(file => '/etc/astra/build_version')) {
        $os->{VERSION} = $version if $version =~ /^\d/;
    }

    return unless canRead('/etc/astra_license');

    if (my $edition = getFirstMatch(
        pattern => qr/^DESCRIPTION="?(.*?)"?$/,
        file    => '/etc/astra_license'
    )) {
        my $security_level =
            $edition =~ /^([^\s()]+)\s*\(/    ? $1 :
            $edition =~ /\(([^\s()]+)\)/      ? $1 :
            $edition =~ /\(([^)]+)\)/         ? (split(/\s+/, $1))[0] :
            'unknown';

        $security_level = trimWhitespace($security_level) || 'unknown';
        $os->{FULL_NAME} =~ s/\(.*?\)//g;
        $os->{FULL_NAME} = trimWhitespace($os->{FULL_NAME}) . " (Security level: $security_level)";
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
