package GLPI::Agent::Task::Inventory::Win32::Networks;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Network;
use GLPI::Agent::Tools::Win32;

our @runAfter = (
    'GLPI::Agent::Task::Inventory::Win32::USB'
);

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
            $interface->{TYPE} = 'bluetooth';

            my $parentInfo = _getBluetoothParentInfo($interface->{PNPDEVICEID}, $inventory);
            if ($parentInfo) {
                $interface->{MANUFACTURER} = $parentInfo->{MANUFACTURER} if $parentInfo->{MANUFACTURER};
                $interface->{MODEL}        = $parentInfo->{MODEL}        if $parentInfo->{MODEL};
            }
        } elsif ($interface->{PNPDEVICEID} && !$interface->{TYPE}) {
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
    my ($deviceid, $inventory) = @_;

    my $info;

    UNIVERSAL::require('Win32::API');
    return $info unless $Win32::API::VERSION;

    require Encode;

    my $CM_Locate_DevNodeW = Win32::API->new('cfgmgr32.dll', 'CM_Locate_DevNodeW', 'PPI', 'I');
    my $CM_Get_Parent      = Win32::API->new('cfgmgr32.dll', 'CM_Get_Parent', 'PII', 'I');
    my $CM_Get_Device_IDW  = Win32::API->new('cfgmgr32.dll', 'CM_Get_Device_IDW', 'IPII', 'I');

    return $info unless $CM_Locate_DevNodeW && $CM_Get_Parent && $CM_Get_Device_IDW;

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
                $parentDeviceId =~ s/\0.*//;

                my $matched_usb;
                if ($inventory) {
                    my $usbDevices = $inventory->getSection('USBDEVICES');
                    if ($usbDevices) {
                        if (my ($vid, $pid, $serial) = $parentDeviceId =~ /^USB\\VID_([0-9A-F]+)&PID_([0-9A-F]+)\\(.*)/i) {
                            for (my $i = 0; $i < @$usbDevices; $i++) {
                                my $dev = $usbDevices->[$i];
                                my $dvid = $dev->{VENDORID} || '';
                                my $dpid = $dev->{PRODUCTID} || '';
                                my $dser = $dev->{SERIAL} || '';
                                
                                # Support the manufacturer pseudo-serial workaround present in USB.pm
                                my $clean_serial = $serial;
                                $clean_serial = $1 if $clean_serial =~ /^S\/N:([0-9A-F]+)/i;
                                
                                if (lc($dvid) eq lc($vid) && lc($dpid) eq lc($pid) && (lc($dser) eq lc($clean_serial) || $dser eq '')) {
                                    $matched_usb = splice(@$usbDevices, $i, 1);
                                    last;
                                }
                            }
                        }
                    }
                }

                if ($matched_usb) {
                    $info->{MANUFACTURER} = $matched_usb->{MANUFACTURER} if $matched_usb->{MANUFACTURER};
                    $info->{MODEL}        = $matched_usb->{NAME} || $matched_usb->{CAPTION};
                } else {
                    if ($parentDeviceId =~ /^USB\\VID_([0-9A-F]+)&PID_([0-9A-F]+)/i) {
                        my $vid = $1;
                        my $pid = $2;
                        UNIVERSAL::require('GLPI::Agent::Tools::Generic');
                        if ($GLPI::Agent::Tools::Generic::VERSION || defined(&GLPI::Agent::Tools::Generic::getUSBDeviceVendor)) {
                            my $vendor = GLPI::Agent::Tools::Generic::getUSBDeviceVendor(id => lc($vid));
                            if ($vendor) {
                                $info->{MANUFACTURER} = $vendor->{name} if $vendor->{name};
                                my $device = $vendor->{devices}->{lc($pid)};
                                $info->{MODEL} = $device->{name} if $device && $device->{name};
                            }
                        }
                    } elsif ($parentDeviceId =~ /^PCI\\VEN_([0-9A-F]+)&DEV_([0-9A-F]+)/i) {
                        my $ven = $1;
                        my $dev = $2;
                        UNIVERSAL::require('GLPI::Agent::Tools::Generic');
                        if ($GLPI::Agent::Tools::Generic::VERSION || defined(&GLPI::Agent::Tools::Generic::getPCIDeviceVendor)) {
                            my $vendor = GLPI::Agent::Tools::Generic::getPCIDeviceVendor(id => lc($ven));
                            if ($vendor) {
                                $info->{MANUFACTURER} = $vendor->{name} if $vendor->{name};
                                my $device = $vendor->{devices}->{lc($dev)};
                                $info->{MODEL} = $device->{name} if $device && $device->{name};
                            }
                        }
                    }

                    if (!$info->{MANUFACTURER} || !$info->{MODEL}) {
                        my $wmiQueryId = $parentDeviceId;
                        $wmiQueryId =~ s/\\/\\\\/g;
                        my ($parentDev) = GLPI::Agent::Tools::Win32::getWMIObjects(
                            class      => 'Win32_PnPEntity',
                            properties => [ qw/Manufacturer Caption/ ],
                            query      => "SELECT Manufacturer, Caption FROM Win32_PnPEntity WHERE PNPDeviceID='$wmiQueryId'"
                        );

                        if ($parentDev) {
                            $info->{MANUFACTURER} = $parentDev->{Manufacturer} if !$info->{MANUFACTURER} && $parentDev->{Manufacturer};
                            $info->{MODEL}        = $parentDev->{Caption}      if !$info->{MODEL}        && $parentDev->{Caption};
                        }
                    }
                }
            }
        }
    }

    return $info;
}

1;
