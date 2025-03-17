package GLPI::Agent::SNMP::MibSupport::Canon;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

# See CANON-MIB & PRINTER-PORT-MONITOR-MIB

use constant enterprises    => '.1.3.6.1.4.1';
use constant canon          => enterprises . '.1602';
use constant ppmMIB         => enterprises . '.2699.1.2';

use constant canProductInfo => canon . '.1.1.1';
use constant canPdInfoProductName       => canProductInfo . '.1.0';
use constant canPdInfoProductVersion    => canProductInfo . '.4.0';

use constant canServInfoSerialNumberTable => canon . '.1.2.1.8';
use constant canServInfoSerialNumberDeviceNumber    => canServInfoSerialNumberTable . '.1.3.1.1';

use constant ppmPrinter     => ppmMIB . '.1.2';
use constant ppmPrinterName => ppmPrinter . '.1.1.2.1';

use constant countersC55XX      => canon . '.1.11.1.3.1.4';
use constant typesLPB76XX       => canon . '.1.11.2.1.1.2';
use constant countersLPB76XX    => canon . '.1.11.2.1.1.3';

our $mibSupport = [
    {
        name        => "canon",
        sysobjectid => qr/^\.1\.3\.6\.1\.4\.1\.1602\.4\./
    }
];

sub getSerial {
    my ($self) = @_;

    return getCanonicalString($self->get(canServInfoSerialNumberDeviceNumber));
}

sub getFirmware {
    my ($self) = @_;

    return $self->get(canPdInfoProductVersion);
}

sub getModel {
    my ($self) = @_;

    my $device = $self->device
        or return;

    return if $device->{MODEL};

    return getCanonicalString($self->get(canPdInfoProductName) || $self->get(ppmPrinterName));
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my $counters;
    if ($counters = $self->walk(countersC55XX)) {

        my %mapping = (
            101 => 'COPYTOTAL',
            112 => 'COPYBLACK',
            113 => 'COPYBLACK',
            122 => 'COPYCOLOR',
            123 => 'COPYCOLOR',
            301 => 'PRINTTOTAL',
            501 => 'SCANNED',
        );

        my %add_mapping = map { $_ => 1 } (112, 113, 122, 123);

        foreach my $index (sort keys(%{$counters})) {
            my $counter = $mapping{$index}
                or next;
            my $count = $counters->{$index}
                or next;
            if ($add_mapping{$index} && $device->{PAGECOUNTERS}->{$counter}) {
                $device->{PAGECOUNTERS}->{$counter} += $count;
            } else {
                $device->{PAGECOUNTERS}->{$counter} = $count;
            }
        }
    } elsif ($counters = $self->walk(countersLPB76XX)) {

        my $types = $self->walk(typesLPB76XX)
            or return;

        my %mapping = (
            'Total 1'                                   => 'TOTAL',
            'Total (Black 1)'                           => 'PRINTBLACK',
            'Total (Black/Large)'                       => 'PRINTBLACK',
            'Total (Black/Small)'                       => 'PRINTBLACK',
            'Total (Full Color + Single Color/Large)'   => 'PRINTCOLOR',
            'Total (Full Color + Single Color/Small)'   => 'PRINTCOLOR',
            'Print (Total 1)'                           => 'PRINTTOTAL',
            'Copy (Total 1)'                            => 'COPYTOTAL',
            'Scan (Total 1)'                            => 'SCANNED',
        );

        my %add_mapping = map { $_ => 1 } (
            'Total (Black/Large)',
            'Total (Black/Small)',
            'Total (Full Color + Single Color/Large)',
            'Total (Full Color + Single Color/Small)',
        );

        my %skip_add_mapping = (
            'Total (Black 1)'   => ['Total (Black/Large)', 'Total (Black/Small)'],
        );

        foreach my $index (sort keys(%{$types})) {
            my $type = hex2char($types->{$index})
                or next;
            my $counter = $mapping{$type}
                or next;
            my $count = $counters->{$index}
                or next;
            if ($add_mapping{$type} && $device->{PAGECOUNTERS}->{$counter}) {
                $device->{PAGECOUNTERS}->{$counter} += $count;
            } else {
                $device->{PAGECOUNTERS}->{$counter} = $count;
            }
            if ($skip_add_mapping{$type}) {
                # Forget other possible mapping
                foreach my $key (@{$skip_add_mapping{$type}}) {
                    delete $mapping{$key};
                }
            }
        }
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Canon - Inventory module for Canon

=head1 DESCRIPTION

This module enhances Canon printers support.
