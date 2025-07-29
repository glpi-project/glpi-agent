package GLPI::Agent::SNMP::MibSupport::Epson;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    epson   => '.1.3.6.1.4.1.1248' ;
use constant    model   => epson . '.1.2.2.1.1.1.2.1' ;
use constant    serial  => epson . '.1.2.2.1.1.1.5.1' ;
use constant    fw_base => epson . '.1.2.2.2.1.1' ;

use constant    cartridge_level => epson . '.1.2.2.28.1.1.2';
use constant    cartridge_label => epson . '.1.2.2.28.1.1.5';

our $mibSupport = [
    {
        name        => "epson-printer",
        sysobjectid => getRegexpOidMatch(epson)
    }
];

sub getSerial {
    my ($self) = @_;

    return $self->get(serial);
}

sub getModel {
    my ($self) = @_;

    return $self->get(model);
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $versions  = $self->walk(fw_base.'.2') || {};
    my $names     = $self->walk(fw_base.'.3') || {};
    my $firmwares = $self->walk(fw_base.'.4') || $names;
    if ($firmwares) {
        foreach my $index (keys(%{$firmwares})) {
            next unless $versions->{$index};
            my $firmware = {
                NAME            => "Epson ".(hex2char($names->{$index}) || "printer"),
                DESCRIPTION     => "Epson printer ".(hex2char($names->{$index}) || "firmware"),
                TYPE            => "printer",
                VERSION         => hex2char($versions->{$index}),
                MANUFACTURER    => "Epson"
            };
            $device->addFirmware($firmware);
        }
    }

    # Search for any maintenance cartridge level
    my $cartridges = $self->walk(cartridge_label);
    if ($cartridges) {
        my $levels = $self->walk(cartridge_level);
        foreach my $key (sort keys(%{$cartridges})) {
            my $label = hex2char($cartridges->{$key});
            next unless $label && $label =~ /maintenance/i;
            next unless defined($levels->{$key});
            $device->{CARTRIDGES}->{MAINTENANCEKIT} = $levels->{$key};
            last;
        }
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Epson - Inventory module for Epson Printers

=head1 DESCRIPTION

The module enhances Epson printers devices support.
