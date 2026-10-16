package GLPI::Agent::SNMP::MibSupport::Huawei;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See HUAWEI-SERVER-IBMC-MIB

use constant    huawei  => '.1.3.6.1.4.1.2011';

use constant    hwServer    => huawei . '.2.235';
use constant    hwiBMC      => hwServer . '.1.1';

use constant    firmwareDescriptionEntry    => hwiBMC . '.11.50.1';
use constant    fruDescriptionEntry         => hwiBMC . '.19.50.1';

use constant    fruProductName          => fruDescriptionEntry . '.9.1';
use constant    fruProductSerialNumber  => fruDescriptionEntry . '.10.1';

use constant    firmwareVersion => firmwareDescriptionEntry . '.4';

our $mibSupport = [
    {
        name    => "huawei",
        sysobjectid => getRegexpOidMatch(huawei)
    }
];

sub _version {
    my ($self, $name) = @_;

    unless ($self->{_versions}) {
        $self->{_versions} = {};
        my $versions = $self->walk(firmwareVersion)
            or return;
        foreach my $key (keys(%{$versions})) {
            my $version = getCanonicalString($versions->{$key});
            next if empty($version) || $version !~ /^[0-9.]+$/;
            my @nums = split(/\./, $key);
            # Skip first oid num
            shift @nums;
            my $firmware = getCanonicalString(pack("C*", @nums));
            next if empty($firmware) || exists($self->{_versions}->{$firmware});
            $self->{_versions}->{$firmware} = getCanonicalString($versions->{$key});
        }
    }

    return $self->{_versions}->{$name} if $name;
    return $self->{_versions};
}

sub getFirmware {
    my ($self) = @_;

    return $self->_version('BIOS');
}

sub getType {
    return 'NETWORKING';
}

sub getManufacturer {
    return 'Huawei';
}

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(fruProductSerialNumber));
}

sub getModel {
    my ($self) = @_;

    return getCanonicalString($self->get(fruProductName));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $versions = $self->_version();
    if ($versions) {
        foreach my $name (sort keys(%{$versions})) {
            next if $name eq "BIOS";
            my $firmware = {
                NAME            => $name,
                DESCRIPTION     => "$name firmware",
                TYPE            => "device",
                VERSION         => $versions->{$name},
                MANUFACTURER    => "Huawei"
            };
            $device->addFirmware($firmware);
        }
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Huawei - Inventory module for Huawei

=head1 DESCRIPTION

This module enhances Huawei devices support.
