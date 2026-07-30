package GLPI::Agent::Tools::Win32::Bluetooth;

use strict;
use warnings;
use parent 'Exporter';

use GLPI::Agent::Tools;

our @EXPORT = qw(
    getBluetoothParentInfo
);

sub getBluetoothParentInfo {
    my ($deviceid) = @_;

    my $info;

    Win32::API->require()
        or return;

    require Encode;

    my $CM_Locate_DevNodeW = Win32::API->new('cfgmgr32.dll', 'CM_Locate_DevNodeW', 'PPI', 'I')
        or return;
    my $CM_Get_Parent      = Win32::API->new('cfgmgr32.dll', 'CM_Get_Parent', 'PII', 'I')
        or return;
    my $CM_Get_Device_ID_Size = Win32::API->new('cfgmgr32.dll', 'CM_Get_Device_ID_Size', 'PPII', 'I')
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
            my $pulLen = pack('L', 0);
            if ($CM_Get_Device_ID_Size->Call($pulLen, $dnParentInst, 0) == 0) {
                my $len = unpack('L', $pulLen);
                $len += 1; # support the null terminating char the api is expected to insert
                my $buffer = "\0" x ($len * 2);
                if ($CM_Get_Device_IDW->Call($dnParentInst, $buffer, $len, 0) == 0) {
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
    }

    return $info;
}

1;
