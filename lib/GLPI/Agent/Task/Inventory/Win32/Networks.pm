package GLPI::Agent::Task::Inventory::Win32::Networks;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Network;
use GLPI::Agent::Tools::Win32;

use constant    category    => "network";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my @interfaces = getInterfaces()
        or return;

    my %statistics;

    my @modern_stats = getWMIObjects(
        moniker    => 'winmgmts://./root/StandardCimv2',
        class      => 'MSFT_NetAdapterStatisticsSettingData',
        properties => [ qw/Name ReceivedBytes SentBytes ReceivedPacketErrors OutboundPacketErrors/ ]
    );

    foreach my $stat (@modern_stats) {
        $statistics{$stat->{Name}} = {
            ifinoctets  => $stat->{ReceivedBytes},
            ifoutoctets => $stat->{SentBytes},
            ifinerrors  => $stat->{ReceivedPacketErrors},
            ifouterrors => $stat->{OutboundPacketErrors}
        } if $stat->{Name};
    }

    my @legacy_stats = getWMIObjects(
        class      => 'Win32_PerfRawData_Tcpip_NetworkInterface',
        properties => [ qw/Name BytesReceivedPersec BytesSentPersec PacketsReceivedErrors PacketsOutboundErrors/ ]
    );

    foreach my $stat (@legacy_stats) {
        # Keep modern stats if they exist (they map nicely by DESCRIPTION)
        # But populate legacy ones too for adapters that only show up here
        $statistics{$stat->{Name}} //= {
            ifinoctets  => $stat->{BytesReceivedPersec},
            ifoutoctets => $stat->{BytesSentPersec},
            ifinerrors  => $stat->{PacketsReceivedErrors},
            ifouterrors => $stat->{PacketsOutboundErrors}
        } if $stat->{Name};
    }

    my $inventory = $params{inventory};
    my (@gateways, @dns);

    my $keys;
    $keys = getRegistryKey(
        path   => "HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Network/{4D36E972-E325-11CE-BFC1-08002BE10318}",
        # Important for remote inventory optimization
        required    => [ qw/PnpInstanceID MediaSubType/ ],
    ) if grep { $_->{PNPDEVICEID}} @interfaces;

    # The legacy WMI class Win32_PerfRawData_Tcpip_NetworkInterface lacks strict linkage properties (like MAC or GUID).
    # When multiple physical NICs of the exact same model exist, Windows natively assigns them sequential suffixes
    # (e.g. "_2", " _3") based on their PnP enumeration order. Since getInterfaces natively arrays them
    # in this exact same index order, we generate sequential lookup strings here to map them 1:1 reliably.
    my %model_counts;
    foreach my $interface (@interfaces) {
        my $lookup_name = $interface->{MODEL} || '';
        if ($lookup_name) {
            $interface->{_MODEL_COUNT} = ++$model_counts{$lookup_name};
            if ($interface->{_MODEL_COUNT} > 1) {
                $lookup_name .= ' _' . $interface->{_MODEL_COUNT};
            }
        }

        push @gateways, $interface->{IPGATEWAY}
            if $interface->{IPGATEWAY};
        push @dns, $interface->{dns}
            if $interface->{dns};

        # Cleanup not necessary values
        delete $interface->{dns};
        delete $interface->{DNSDomain};
        delete $interface->{GUID};

        if ($interface->{PNPDEVICEID} && !$interface->{TYPE}) {
            my $type = _getMediaType($interface->{PNPDEVICEID}, $keys);
            $interface->{TYPE} = $type if defined($type);
        }

        if (my $stat = $statistics{$interface->{DESCRIPTION}} || ($lookup_name && $statistics{$lookup_name})) {
            # getInterfaces() duplicates adapters in the array if they have multiple IP addresses.
            # We track them by MAC and DESCRIPTION so we only inject one NETWORKPORTS block per physical card.
            my $seen_key = "seen_" . ($interface->{MACADDR} || '') . "_" . ($interface->{DESCRIPTION} || '');
            if (!$statistics{$seen_key}) {
                $statistics{$seen_key} = 1;
                my $network_port = {
                    NAME        => $interface->{DESCRIPTION},
                    MAC         => $interface->{MACADDR},
                    IFNUMBER    => $interface->{_IFNUMBER},
                    IFINOCTETS  => $stat->{ifinoctets},
                    IFOUTOCTETS => $stat->{ifoutoctets},
                    IFINERRORS  => $stat->{ifinerrors},
                    IFOUTERRORS => $stat->{ifouterrors}
                };
            $inventory->addEntry(
                section => 'NETWORK_PORTS',
                entry   => $network_port
            );
            }
        }
        delete $interface->{_MODEL_COUNT};
        delete $interface->{_IFNUMBER};
        $inventory->addEntry(
            section => 'NETWORKS',
            entry   => $interface
        );
    }

    $inventory->setHardware({
        DEFAULTGATEWAY => join('/', uniq @gateways),
        DNS            => join('/', uniq @dns),
    });

}

sub _getMediaType {
    my ($deviceid, $keys) = @_;

    return unless defined $deviceid && $keys;

    my $subtype;

    foreach my $subkey_name (keys %{$keys}) {
        # skip variables
        next if $subkey_name =~ m{^/};
        my $subkey_connection = $keys->{$subkey_name}->{'Connection/'}
            or next;
        my $subkey_deviceid   = $subkey_connection->{'/PnpInstanceID'}
            or next;
        # Normalize PnpInstanceID
        $subkey_deviceid =~ s/\\\\/\\/g;
        if (lc($subkey_deviceid) eq lc($deviceid)) {
            $subtype = $subkey_connection->{'/MediaSubType'};
            last;
        }
    }

    return unless defined $subtype;

    return  $subtype eq '0x00000001' ? 'ethernet'  :
            $subtype eq '0x00000002' ? 'wifi'      :
            $subtype eq '0x00000007' ? 'bluetooth' :
                                       undef;
}

1;
