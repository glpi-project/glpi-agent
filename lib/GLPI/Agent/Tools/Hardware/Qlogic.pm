package GLPI::Agent::Tools::Hardware::Qlogic;

use strict;
use warnings;

use GLPI::Agent::Tools::SNMP qw/getCanonicalMacAddress getCanonicalSerialNumber/;

sub run {
   my (%params) = @_;

   my $snmp   = $params{snmp};
   my $device = $params{device};

   my $ports = $device->{PORTS}->{PORT};

   my $serial = getSerial(snmp => $snmp);
   $device->{INFO}->{SERIAL} = $serial if $serial;

   my $fc_ports = getFcPorts(
      snmp => $snmp,
   );
   return unless $fc_ports;

   my $connected_wwns = getConnectedWWNs(
      snmp => $snmp,
   );

   my $port_status = getFcPortStatus(
      snmp => $snmp,
   );

   foreach my $idx (keys %$fc_ports) {
      # Generate ifNumber for FC ports to avoid confusion with
      # ethernet ports numbers
      my $port_id = sprintf("10%02d00", $idx);

      $ports->{$port_id} = {
         IFNUMBER => $port_id,
         IFTYPE   => 56,               # fibreChannel
         IFNAME   => "FC port $idx",
         MAC      => $fc_ports->{$idx},
         IFSTATUS => $port_status->{$idx},
      };

      if (defined $connected_wwns->{$idx}) {
         $ports->{$port_id}->{CONNECTIONS}->{CONNECTION}->{MAC} =
            [ $connected_wwns->{$idx} ];
      }
   }
}

sub getFcPorts {
   my (%params) = @_;

   my $snmp = $params{snmp};

   my %fcPort;

   my $fcFxPortName = $snmp->walk(".1.3.6.1.2.1.75.1.1.5.1.2.1");

   #FIBRE-CHANNEL-FE-MIB::fcFxPortName.1.1 = Hex-STRING: 20 00 00 C0 DD 0C C5 27
   #FIBRE-CHANNEL-FE-MIB::fcFxPortName.1.2 = Hex-STRING: 20 01 00 C0 DD 0C C5 27
   while (my ($idx, $wwn) = each %$fcFxPortName) {
       $wwn = getCanonicalMacAddress($wwn);
       next unless $wwn;

       $fcPort{$idx} = $wwn;
   }

   return \%fcPort;
}

sub getFcPortStatus {
   my (%params) = @_;

   my $snmp = $params{snmp};

   my $fcFxPortPhysOperStatus = $snmp->walk(".1.3.6.1.2.1.75.1.2.2.1.2.1");

   return $fcFxPortPhysOperStatus;
}

sub getConnectedWWNs {
    my (%params) = @_;

    my $snmp = $params{snmp};

    my $results;
    my $fcFxPortNxPortName = $snmp->walk(".1.3.6.1.2.1.75.1.2.3.1.10.1");

    # .1.3.6.1.2.1.75.1.2.3.1.10.1.1.1 = Hex-STRING: 21 00 00 24 FF 57 5D 9C
    # .1.3.6.1.2.1.75.1.2.3.1.10.1.2.1 = Hex-STRING: 21 00 00 24 FF 57 5F 18
    while (my ($suffix, $wwn) = each %$fcFxPortNxPortName) {
        $wwn = getCanonicalMacAddress($wwn);
        next unless $wwn;

        my $idx = GLPI::Agent::Tools::Hardware::_getElement($suffix, 0);
        next unless $idx;

        push @{$results->{$idx}}, $wwn;
    }

    return $results;
}

sub getSerial {
    my (%params) = @_;
    my $snmp = $params{snmp};

    my $walk = $snmp->walk(".1.3.6.1.3.94.1.6.1.8.16.0.0.192.221.12");

    if ($walk) {
        while (my ($suffix, $serial) = each %$walk) {
            return getCanonicalSerialNumber($serial) if $serial;
        }
    }
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::Hardware::Qlogic - Inventory module for Qlogic fibre channel switches

=head1 DESCRIPTION

Inventories fibre-channel ports.

Qlogic switches are stackable but whichever switch you get SNMP data from
it is always stack member #1. So just get the data for the 1st member and
don't worry about the others.
