package GLPI::Agent::SNMP::MibSupport::Digi;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

# Constants extracted from Digi Sarian-Monitor.mib
use constant    sarianMonitor   => ".1.3.6.1.4.1.16378.10000" ;
use constant    sarianGPRS      => sarianMonitor . ".2" ;
use constant    sarianSystem    => sarianMonitor . ".3" ;

use English qw(-no_match_vars);
use UNIVERSAL::require;

our $mibSupport = [
    {
        name    => "sarianMonitor",
        oid     => sarianMonitor
    }
];

# Supported values start from index 1
my @gprsNetworkTechnology = qw(- unknown gprs edge umts hsdpa hsupa hspa lte);

sub getFirmware {
    my ($self) = @_;

    return $self->get(sarianSystem . '.16.0');
}

sub getSerial {
    my ($self) = @_;

    return $self->get(sarianSystem . '.15.0');
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $sarianSystem = $device->walk(sarianSystem);

    # Handle modem Digi private OIDs if found
    if ($sarianSystem) {
        my $modem = {
            NAME            => "Digi modem",
            DESCRIPTION     => $sarianSystem->{'14.0'},
            MODEL           => $sarianSystem->{'19.0'},
            MANUFACTURER    => "Digi",
        };

        # Handle SIM card looking for GRPS status
        my $sarianGPRS = $device->walk(sarianGPRS);
        if ($sarianGPRS) {
            my $simcard = {
                IMSI    => $sarianGPRS->{'21.0'}, # gprsIMSI
                ICCID   => $sarianGPRS->{'20.0'}, # gprsICCID
            };

            my $operator = $sarianGPRS->{'22.0'}; # gprsNetwork
            if ($operator) {
                my ($name, $mcc, $mnc) = $operator =~ /^(.*),\s*(\d{3})(\d+)$/ ;
                $simcard->{OPERATOR_NAME} = $name;
                if ($mcc) {
                    $simcard->{OPERATOR_CODE} = "$mcc.$mnc" if $mnc;
                    $simcard->{COUNTRY} = getCountryMCC($mcc)
                        if GLPI::Agent::Tools::Standards::MobileCountryCode->use();
                }
            }

            # Include used SIM in STATE
            my $sim_status = $sarianGPRS->{'26.0'}; # gprsSIMStatus
            my $sim_number = $sarianGPRS->{'30.0'}; # gprsCurrentSIM
            $simcard->{STATE} = ($sim_number ? "SIM$sim_number - " : "") .
                ( $sim_status || "" );

            $device->addSimcard($simcard);

            # use IMEI as modem serial
            $modem->{SERIAL} = $sarianGPRS->{'19.0'}; # gprsIMEI

            # set modem type
            my $techno = $sarianGPRS->{'7.0'}; # gprsNetworkTechnology
            if ($techno && $techno <= @gprsNetworkTechnology) {
                $modem->{TYPE} = $gprsNetworkTechnology[$techno];
            }
        }

        $device->addModem($modem);

        # Add modem firmware
        my $modemFirmware = {
            NAME            => "Digi modem",
            DESCRIPTION     => "Digi $sarianSystem->{'19.0'} modem",
            TYPE            => "modem",
            VERSION         => $sarianSystem->{'20.0'},
            MANUFACTURER    => "Digi"
        };

        $device->addFirmware($modemFirmware);
    }

}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Digi - Inventory module for Digi modems and associated sim cards & firmwares

=head1 DESCRIPTION

The module adds SIMCARDS, MODEMS & FIRMWARES support for Digi devices
