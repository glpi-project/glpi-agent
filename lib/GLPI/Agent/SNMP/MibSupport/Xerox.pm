package GLPI::Agent::SNMP::MibSupport::Xerox;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP::MibSupportTemplate';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;

use constant    enterprises => '.1.3.6.1.4.1' ;

# XEROX-COMMON-MIB
use constant    xerox       => enterprises . '.253';
use constant    xeroxCommonMIB  => xerox . '.8';

# XEROX-HOST-RESOURCES-EXT-MIB
use constant    xcmHrDevDetailEntry => xeroxCommonMIB . '.53.13.2.1' ;

use constant    xeroxTotalPrint => xcmHrDevDetailEntry . '.6.1.20.1' ;
use constant    xeroxColorPrint => xcmHrDevDetailEntry . '.6.1.20.33' ;
use constant    xeroxBlackPrint => xcmHrDevDetailEntry . '.6.1.20.34' ;
use constant    xeroxColorCopy  => xcmHrDevDetailEntry . '.6.11.20.25' ;
use constant    xeroxBlackCopy  => xcmHrDevDetailEntry . '.6.11.20.3' ;
use constant    xeroxScanSentByEmail    => xcmHrDevDetailEntry . '.6.10.20.11' ;
use constant    xeroxScanSavedOnNetwork => xcmHrDevDetailEntry . '.6.10.20.12' ;

our $mibSupport = [
    {
        name        => "xerox-printer",
        sysobjectid => getRegexpOidMatch(xeroxCommonMIB)
    }
];

sub run {
    my ($self) = @_;

    my $device = $self->device
        or return;

    my %mapping = (
        PRINTCOLOR  => xeroxColorPrint,
        PRINTBLACK  => xeroxBlackPrint,
        PRINTTOTAL  => xeroxTotalPrint,
        COPYCOLOR   => xeroxColorCopy,
        COPYBLACK   => xeroxBlackCopy,
        SCANNED     => [
            xeroxScanSentByEmail,
            xeroxScanSavedOnNetwork,
        ]
    );

    foreach my $counter (sort keys(%mapping)) {
        my $count = 0;
        if (ref($mapping{$counter})) {
            map { $count += $self->get($_) // 0 } @{$mapping{$counter}}
        } else {
            $count = $self->get($mapping{$counter});
        }
        next unless $count;
        $device->{PAGECOUNTERS}->{$counter} = $count;
    }

    # Set COPYTOTAL if copy found and no dedicated counter is defined
    if ($device->{PAGECOUNTERS}->{COPYCOLOR} || $device->{PAGECOUNTERS}->{COPYBLACK}) {
        $device->{PAGECOUNTERS}->{COPYTOTAL} = ($device->{PAGECOUNTERS}->{COPYBLACK} // 0) + ($device->{PAGECOUNTERS}->{COPYCOLOR} // 0);
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::Xerox - Inventory module for Xerox Printers

=head1 DESCRIPTION

The module enhances Xerox printers devices support.
