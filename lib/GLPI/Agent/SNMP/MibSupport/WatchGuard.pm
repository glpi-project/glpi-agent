package GLPI::Agent::SNMP::MibSupport::WatchGuard;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::SNMP::Hardware;
use GLPI::Agent::Tools::SNMP;

# WATCHGUARD-SMI
use constant    watchguard  => '.1.3.6.1.4.1.3097';

# WATCHGUARD-INFO-SYSTEM-MIB
use constant    wgInfoModule    => watchguard . '.6';

use constant    wgInfoGavService    => wgInfoModule . '.1.3.0';
use constant    wgInfoIpsService    => wgInfoModule . '.1.4.0';

# WATCHGUARD-SYSTEM-STATISTICS-MIB
use constant    wgSoftwareVersion   => wgInfoModule . '.3.1.0';

our $mibSupport = [
    {
        name    => "watchguard",
        oid     => watchguard
    }
];

sub getManufacturer {
    return "WatchGuard";
}

sub getFirmware {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $wgSoftwareVersion = getCanonicalString($self->get(wgSoftwareVersion));
    return if empty($wgSoftwareVersion);

    $device->{_wgSoftwareVersion} = $wgSoftwareVersion;

    my ($version) = $wgSoftwareVersion =~ /<sysa:([^>]+)>/
        or return;

    return $version;
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $manufacturer = $self->getManufacturer()
        or return;

    my $name = $device->{MODEL} || $manufacturer
        or return;

    unless (empty($device->{_wgSoftwareVersion})) {
        my ($sysBversion) = $device->{_wgSoftwareVersion} =~ /<sysb:([^>]+)>/;
        $device->addFirmware({
            NAME            => "$name sysB",
            DESCRIPTION     => "$name sysB software version",
            TYPE            => "system",
            VERSION         => $sysBversion,
            MANUFACTURER    => $manufacturer
        }) if $sysBversion;
    }

    my $wgInfoGavService = getCanonicalString($self->get(wgInfoGavService));
    unless (empty($wgInfoGavService)) {
        my ($version) = $wgInfoGavService =~ /^<gav_version:([^>]+)>/;
        $device->addFirmware({
            NAME            => "$name GAV",
            DESCRIPTION     => "$name Gateway Antivirus Service version",
            TYPE            => "service",
            VERSION         => $version,
            MANUFACTURER    => $manufacturer
        }) if $version;
    }

    my $wgInfoIpsService = getCanonicalString($self->get(wgInfoIpsService));
    unless (empty($wgInfoIpsService)) {
        my ($version) = $wgInfoIpsService =~ /^<ips_version:([^>]+)>/;
        $device->addFirmware({
            NAME            => "$name IPS",
            DESCRIPTION     => "$name Intrusion Prevention Service version",
            TYPE            => "service",
            VERSION         => $version,
            MANUFACTURER    => $manufacturer
        }) if $version;
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::WatchGuard - Inventory module to enhance WatchGuard devices support

=head1 DESCRIPTION

The module tries to enhance WatchGuard devices support.
