package GLPI::Agent::SNMP::MibSupport::Pantum;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    mib2        => '.1.3.6.1.2.1' ;
use constant    enterprises => '.1.3.6.1.4.1' ;

# Pantum private
use constant    pantum  => enterprises . '.40093';

use constant    pantumPrinter   => pantum . '.1.1' ;
use constant    pantumFWVersion     => pantumPrinter . '.1.1' ;
use constant    pantumRAM           => pantumPrinter . '.1.2' ;
use constant    pantumSerialNumber1 => pantumPrinter . '.1.5' ;
use constant    pantumSerialNumber2 => pantum . '.6.1.2' ;
use constant    pantumSerialNumber3 => pantum . '.10.1.1.4' ;
use constant    pantumCounters      => pantumPrinter . '.3' ;

# Printer-MIB
use constant    printmib                => mib2 . '.43' ;
use constant    prtGeneralPrinterName   => printmib . '.5.1.1.16.1' ;
use constant    prtMarkerSuppliesEntry  => printmib . '.11.1.1' ;
use constant    prtMarkerColorantEntry  => printmib . '.12.1.1' ;

our $mibSupport = [
    {
        name        => "pantum-printer",
        sysobjectid => getRegexpOidMatch(pantumPrinter)
    }
];

sub getModel {
    my ($self) = @_;

    return $self->get(prtGeneralPrinterName);
}

sub getManufacturer {
    return 'Pantum';
}

sub getSerial {
    my ($self) = @_;

    return $self->get(pantumSerialNumber1) || $self->get(pantumSerialNumber2) ||
        $self->get(pantumSerialNumber3);
}

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    # Consumable level: most manufacturers reports trees under .1.3.6.1.2.1.43.11.1.1.x.1 oids
    # where Pantum manufacturer decided to use directly each oids when they are using only one consumable

    # Same as in GLPI::Agent::Tools::Hardware
    my %consumable_types = (
         3 => 'TONER',
         4 => 'WASTETONER',
         5 => 'CARTRIDGE',
         6 => 'CARTRIDGE',
         8 => 'WASTETONER',
         9 => 'DRUM',
        10 => 'DEVELOPER',
        12 => 'CARTRIDGE',
        15 => 'FUSERKIT',
        18 => 'MAINTENANCEKIT',
        20 => 'TRANSFERKIT',
        21 => 'TONER',
        32 => 'STAPLES',
    );

    my $max     = $self->get(prtMarkerSuppliesEntry . '.8.1');
    my $current = $self->get(prtMarkerSuppliesEntry . '.9.1');
    if (defined($max) && defined($current)) {
        # Consumable identification
        my $type_id  = $self->get(prtMarkerSuppliesEntry . '.5.1');
        my $description = getCanonicalString($self->get(prtMarkerSuppliesEntry . '.6.1') // '');

        my $type;
        if ($type_id && $type_id != 1) {
            $type = $consumable_types{$type_id};
        } else {
            # fallback on description
            $type =
                $description =~ /maintenance/i ? 'MAINTENANCEKIT' :
                $description =~ /fuser/i       ? 'FUSERKIT'       :
                $description =~ /transfer/i    ? 'TRANSFERKIT'    :
                                                 undef            ;
        }

        if (!$type) {
            $device->{logger}->debug("unknown consumable type $type_id: " . ($description || "no description"))
                if $device->{logger};
        } elsif ($type eq 'TONER' || $type eq 'DRUM' || $type eq 'CARTRIDGE' || $type eq 'DEVELOPER') {
            my $color = getCanonicalString($self->get(prtMarkerColorantEntry . '.4.1'));
            if (!$color) {
                $device->{logger}->debug("setting black color as default for: " . ($description || "no description"))
                    if $device->{logger};
                # fallback on description or black
                $color =
                    $description =~ /cyan/i           ? 'cyan'    :
                    $description =~ /magenta/i        ? 'magenta' :
                    $description =~ /(yellow|jaune)/i ? 'yellow'  :
                    $description =~ /(black|noir)/i   ? 'black'   : 'black'   ;
            }
            $type .= uc($color);
        }

        my $value;
        if ($current == -2) {
            # A value of -2 means "unknown" according to the RFC - but this
            # is not NULL - it means "something undetermined between
            # OK and BAD".
            # Several makers seem to have grabbed it as a way of indicating
            # "almost out" for supplies and waste. (Like a vehicle low fuel warning)
            #
            # This was previously set to undef - but that was triggering a bug
            # that caused bad XML to be output and that in turn would block FI4G imports
            # which in turn would make page counters look strange for the days
            # when it was happening (zero pages, then a big spike)
            #
            # Using "WARNING" should allow print monitoring staff to ensure
            # replacement items are in stock before they go "BAD"
            $value = 'WARNING';
        } elsif ($current == -3) {
            # A value of -3 means that the printer knows that there is some
            # supply/remaining space, respectively.
            $value = 'OK';
        } else {
            if (isInteger($max) && $max >= 0) {
                if (isInteger($current) && $max > 0) {
                    $value = int(( 100 * $current ) / $max);
                }
            } else {
                # PrtMarkerSuppliesSupplyUnitTC in Printer MIB
                my $unit_id = $self->get(prtMarkerSuppliesEntry . '.7.1');
                $value =
                    $unit_id == 19 ?  $current                         :
                    $unit_id == 18 ?  $current         . 'items'       :
                    $unit_id == 17 ?  $current         . 'm'           :
                    $unit_id == 16 ?  $current         . 'feet'        :
                    $unit_id == 15 ? ($current / 10)   . 'ml'          :
                    $unit_id == 13 ? ($current / 10)   . 'g'           :
                    $unit_id == 11 ?  $current         . 'hours'       :
                    $unit_id ==  8 ?  $current         . 'sheets'      :
                    $unit_id ==  7 ?  $current         . 'impressions' :
                    $unit_id ==  4 ? ($current / 1000) . 'mm'          :
                                      $current         . '?'           ;
            }
        }

        $device->{CARTRIDGES}->{$type} = $value
            if $type && defined($value);
    }

    my $ram = $self->get(pantumRAM);
    $device->{INFO}->{RAM} = $ram
        if defined($ram) && isInteger($ram);

    my $counters = $self->walk(pantumCounters);
    if ($counters) {
        my $total = 0;
        my %mapping = (
            1   => 'DUPLEX',
            9   => 'COPYTOTAL',
            12  => 'PRINTTOTAL',
        );

        foreach my $key (sort keys(%mapping)) {
            my $count = $counters->{$key};
            next unless defined($count) && isInteger($count);
            $device->{PAGECOUNTERS}->{$mapping{$key}} = $count;
            $total += $count;
        }
        $device->{PAGECOUNTERS}->{TOTAL} = $total;
    }

    my $version = getCanonicalString($self->get(pantumFWVersion));
    if ($version) {
        my $firmware = {
            NAME            => "Pantum $device->{MODEL} firmware",
            DESCRIPTION     => "Pantum $device->{MODEL} firmware version",
            TYPE            => "printer",
            VERSION         => $version,
            MANUFACTURER    => "Pantum"
        };
        $device->addFirmware($firmware);
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Pantum - Inventory module for Pantum Printers

=head1 DESCRIPTION

The module enhances Pantum printers devices support.
