package GLPI::Agent::Tools::Hardware::Brocade;

use strict;
use warnings;

use GLPI::Agent::Tools::SNMP qw/getCanonicalMacAddress/;

sub run {
    my (%params) = @_;

    my $snmp   = $params{snmp};
    my $device = $params{device};
    my $logger = $params{logger};

    my $ports = $device->{PORTS}->{PORT};

    my $wwns = getConnectedWWNs(
        snmp  => $snmp,
    );
    return unless $wwns;

    my $fc_ports = getFcPorts($ports);
    return unless $fc_ports;

    foreach my $idx (keys %$wwns) {
        if (!$ports->{$fc_ports->{$idx}}) {
            $logger->error("non-existing FC port $idx")
                if $logger;
            last;
        }
        my $port = $ports->{$fc_ports->{$idx}};

        push @{$port->{CONNECTIONS}->{CONNECTION}->{MAC}}, $wwns->{$idx};
    }
}

sub getFcPorts {
   my ($ports) = @_;

   my %fcPort;

   # map each IFMIB port to FIBRE-CHANNEL-FE-MIB port
   my $i = 1; # fc ports count from 1
   foreach my $idx (sort keys %$ports) {
      if ($ports->{$idx}->{IFTYPE} == 56) { # fibreChannel
         $fcPort{$i} = $idx;
         $i++;
      }
   }

   return \%fcPort;
}

sub getConnectedWWNs {
    my (%params) = @_;

    my $snmp = $params{snmp};

    my $results;
    my $fcFxPortNxPortName = $snmp->walk(".1.3.6.1.2.1.75.1.2.3.1.10");

    # .1.3.6.1.2.1.75.1.2.3.1.10.1.1.1 = Hex-STRING: 21 00 00 24 FF 57 5D 9C
    # .1.3.6.1.2.1.75.1.2.3.1.10.1.2.1 = Hex-STRING: 21 00 00 24 FF 57 5F 18
    #                              ^--- $idx
    while (my ($suffix, $wwn) = each %$fcFxPortNxPortName) {
        $wwn = getCanonicalMacAddress($wwn);
        next unless $wwn;

        my $idx = GLPI::Agent::Tools::Hardware::_getElement($suffix, 1);
        next unless $idx;

        push @{$results->{$idx}}, $wwn;
    }

    return $results;
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::Hardware::Brocade - Inventory module for Brocade fibre channel switches

=head1 DESCRIPTION

Inventories fibre-channel ports.
