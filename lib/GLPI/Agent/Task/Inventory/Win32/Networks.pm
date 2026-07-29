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

    my $inventory = $params{inventory};
    my (@gateways, @dns);

    my $keys;
    $keys = getRegistryKey(
        path   => "HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Network/{4D36E972-E325-11CE-BFC1-08002BE10318}",
        # Important for remote inventory optimization
        required    => [ qw/PnpInstanceID MediaSubType/ ],
    ) if grep { $_->{PNPDEVICEID}} @interfaces;

    foreach my $interface (@interfaces) {
        push @gateways, $interface->{IPGATEWAY}
            if $interface->{IPGATEWAY};
        push @dns, $interface->{dns}
            if $interface->{dns};

        # Cleanup not necessary values
        delete $interface->{dns};
        delete $interface->{DNSDomain};
        delete $interface->{GUID};

        if ($interface->{PNPDEVICEID} && $interface->{PNPDEVICEID} =~ /^BTH/i) {
            my $parentInfo = _getBluetoothParentInfo($interface->{PNPDEVICEID});
            if ($parentInfo) {
                $interface->{MANUFACTURER} = $parentInfo->{MANUFACTURER} if $parentInfo->{MANUFACTURER};
                $interface->{MODEL}        = $parentInfo->{MODEL}        if $parentInfo->{MODEL};
            }
        }

        if ($interface->{PNPDEVICEID} && !$interface->{TYPE}) {
            my $type = _getMediaType($interface->{PNPDEVICEID}, $keys);
            $interface->{TYPE} = $type if defined($type);
        }

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

sub _getBluetoothParentInfo {
    my ($deviceid) = @_;

    my $info;

    Win32::API->require()
        or return;

    require Encode;

    my $CM_Locate_DevNodeW = Win32::API->new('cfgmgr32.dll', 'CM_Locate_DevNodeW', 'PPI', 'I')
        or return;
    my $CM_Get_Parent      = Win32::API->new('cfgmgr32.dll', 'CM_Get_Parent', 'PII', 'I')
        or return;
    my $CM_Get_Device_IDW  = Win32::API->new('cfgmgr32.dll', 'CM_Get_Device_IDW', 'IPII', 'I')
        or return;

    my $deviceIdW = Encode::encode('UTF-16LE', $deviceid . "\0");
    my $devInst = pack('L', 0);

    if ($CM_Locate_DevNodeW->Call($devInst, $deviceIdW, 0) == 0) {
        my $dnDevInst = unpack('L', $devInst);
        my $parentInst = pack('L', 0);
        if ($CM_Get_Parent->Call($parentInst, $dnDevInst, 0) == 0) {
            my $dnParentInst = unpack('L', $parentInst);
            my $buffer = "\0" x 512;
            if ($CM_Get_Device_IDW->Call($dnParentInst, $buffer, 256, 0) == 0) {
                my $parentDeviceId = Encode::decode('UTF-16LE', $buffer);
                $parentDeviceId = getSanitizedString($parentDeviceId);

                my $wmiQueryId = $parentDeviceId;
                $wmiQueryId =~ s/\\/\\\\/g;
                my ($parentDev) = GLPI::Agent::Tools::Win32::getWMIObjects(
                    class      => 'Win32_PnPEntity',
                    properties => [ qw/Manufacturer Caption/ ],
                    query      => "SELECT Manufacturer, Caption FROM Win32_PnPEntity WHERE PNPDeviceID='$wmiQueryId'"
                );

                if ($parentDev) {
                    $info->{MANUFACTURER} = $parentDev->{Manufacturer} if $parentDev->{Manufacturer};
                    $info->{MODEL}        = $parentDev->{Caption}      if $parentDev->{Caption};
                }
            }
        }
    }

    return $info;
}

1;
