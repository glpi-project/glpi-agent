package GLPI::Agent::SNMP::MibSupport::Avaya;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# Constants extracted from Avaya Avaya-J100IpPhone-MIB.mib
use constant    avaya   => ".1.3.6.1.4.1.6889" ;

use constant    products    => avaya . ".1";
use constant    avayaipEndpointProd     => products . ".69";
use constant    avaya96x1SIPEndpoints   => avayaipEndpointProd . ".6";

use constant    avayaMibs   => avaya . ".2" ;
use constant    ipEndpointMIBs  => avayaMibs . ".69" ;
use constant    avayaSparkMIB   => ipEndpointMIBs . ".6" ;

use constant    endptID => avayaSparkMIB . ".1";
use constant    endptAPPINUSE       => endptID . ".4.0";
use constant    endptDSPVERSION     => endptID . ".27.0";
use constant    endptMODEL          => endptID . ".52.0";
use constant    endptPHONESN        => endptID . ".57.0";
use constant    endptHWVER          => endptID . ".139.0";
use constant    endptOpenSSLVersion => endptID . ".168.0";
use constant    endptOpenSSHVersion => endptID . ".169.0";

our $mibSupport = [
    {
        name        => "avaya-j100-ipphone",
        sysobjectid => getRegexpOidMatch(avaya96x1SIPEndpoints)
    }
];

sub getFirmware {
    my ($self) = @_;

    return $self->get(endptAPPINUSE);
}

sub getModel {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return $device->{MODEL} // getCanonicalString($self->get(endptMODEL));
}

sub getSerial {
    my ($self) = @_;

    return $self->get(endptPHONESN);
}

sub getType {
    return 'NETWORKING';
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Handle DSP version if found
    my $dspVersion = getCanonicalString($self->get(endptDSPVERSION));
    unless (empty($dspVersion)) {
        my $dspFirmware = {
            NAME            => $self->getModel() . " DSP firmware",
            DESCRIPTION     => "DSP firmware version",
            TYPE            => "dsp",
            VERSION         => $dspVersion,
            MANUFACTURER    => "Avaya"
        };

        $device->addFirmware($dspFirmware);
    }

    # Handle hardware version if found
    my $hwVersion = getCanonicalString($self->get(endptHWVER));
    unless (empty($hwVersion)) {
        my $hardware = {
            NAME            => $self->getModel() . " Hardware",
            DESCRIPTION     => "Hardware version",
            TYPE            => "hardware",
            VERSION         => $hwVersion,
            MANUFACTURER    => "Avaya"
        };

        $device->addFirmware($hardware);
    }

    # OpenSSL version if found
    my $openSSLVersion = getCanonicalString($self->get(endptOpenSSLVersion));
    unless (empty($openSSLVersion)) {
        my $openssl = {
            NAME            => $self->getModel() . " OpenSSL",
            DESCRIPTION     => "OpenSSL version",
            TYPE            => "software",
            VERSION         => $openSSLVersion,
            MANUFACTURER    => "Avaya"
        };

        $device->addFirmware($openssl);
    }

    # OpenSSH version if found
    my $openSSHVersion = getCanonicalString($self->get(endptOpenSSHVersion));
    unless (empty($openSSHVersion)) {
        my $openssh = {
            NAME            => $self->getModel() . " OpenSSH",
            DESCRIPTION     => "OpenSSH version",
            TYPE            => "software",
            VERSION         => $openSSHVersion,
            MANUFACTURER    => "Avaya"
        };

        $device->addFirmware($openssh);
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Avaya - Inventory module for Avaya devices

=head1 DESCRIPTION

The module enhances support for Avaya devices
