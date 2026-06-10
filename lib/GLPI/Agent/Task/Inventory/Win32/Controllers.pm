package GLPI::Agent::Task::Inventory::Win32::Controllers;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools::Generic;
use GLPI::Agent::Tools::Win32;

use constant    category    => "controller";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $physical = $inventory->getHardware('VMSYSTEM') eq 'Physical';

    foreach my $controller (_getControllers(
        logger  => $params{logger},
        datadir => $params{datadir}
    )) {
        $inventory->addEntry(
            section => 'CONTROLLERS',
            entry   => $controller
        );

        if ($physical && $controller->{NAME} =~ /QEMU/i) {
            $inventory->setHardware ({
                VMSYSTEM => 'QEMU'
            });
        }
    }
}

sub _getControllers {
    my @controllers;
    my %seen;

    foreach my $controller (_getControllersFromWMI(@_)) {

        if ($controller->{deviceid} =~ /PCI\\VEN_(\S{4})&DEV_(\S{4})/) {
            $controller->{VENDORID} = lc($1);
            $controller->{PRODUCTID} = lc($2);
        }

        if ($controller->{deviceid} =~ /&SUBSYS_(\S{4})(\S{4})/) {
            $controller->{PCISUBSYSTEMID} = lc($2 . ':' . $1);
        }

        # only devices with a PCIID sounds resonable
        next unless $controller->{VENDORID} && $controller->{PRODUCTID};

        # avoid duplicates
        next if $seen{$controller->{VENDORID}}->{$controller->{PRODUCTID}}++;

        if ($controller->{deviceid}) {
            my $pnp_id = $controller->{deviceid};
            $pnp_id =~ s{\\}{/}g;
            my $enum_key = getRegistryKey(
                path     => "HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Enum/$pnp_id",
                required => [ qw/LocationInformation/ ]
            );
            if ($enum_key && $enum_key->{"/LocationInformation"}) {
                my $loc = $enum_key->{"/LocationInformation"};
                if ($loc =~ /\((\d+),\s*(\d+),\s*(\d+)\)$/ || $loc =~ /PCI bus (\d+),\s*device (\d+),\s*function (\d+)/i) {
                    $controller->{PCISLOT} = sprintf("%02x:%02x.%x", $1, $2, $3);
                }
            }
        }

        delete $controller->{deviceid};

        my $vendor_id    = lc($controller->{VENDORID});
        my $device_id    = lc($controller->{PRODUCTID});
        my $subdevice_id = lc($controller->{PCISUBSYSTEMID});

        my $vendor = getPCIDeviceVendor(id => $vendor_id, @_);
        if ($vendor) {
            $controller->{MANUFACTURER} = $vendor->{name};

            if ($vendor->{devices}->{$device_id}) {
                my $entry = $vendor->{devices}->{$device_id};
                $controller->{CAPTION} = $entry->{name};

                $controller->{NAME} =
                    $subdevice_id && $entry->{subdevices}->{$subdevice_id} ?

                    $entry->{subdevices}->{$subdevice_id}->{name} :
                    $entry->{name};
            }
        }

        push @controllers, $controller;
    }

    return @controllers;
}

sub _getControllersFromWMI {
    my @controllers;

    foreach my $class (qw/
        Win32_FloppyController Win32_IDEController Win32_SCSIController
        Win32_VideoController Win32_InfraredDevice Win32_USBController
        Win32_1394Controller Win32_PCMCIAController CIM_LogicalDevice
    /) {

        foreach my $object (getWMIObjects(
            class      => $class,
            properties => [ qw/
                Name Manufacturer Caption DeviceID PNPDeviceID
            /]
        )) {

            # For most WMI controller classes (Win32_USBController, Win32_IDEController,
            # etc.), DeviceID already contains the full PCI path like
            # PCI\VEN_8086&DEV_3185&SUBSYS_00000000&REV_06\3&11583659&0&10.
            # For Win32_VideoController, Microsoft chose a different convention:
            # DeviceID is just a generic "VideoController1", while the actual PCI
            # path lives in PNPDeviceID.
            # So the assignment uses PNPDeviceID when it starts with PCI\,
            # falling back to DeviceID otherwise.
            push @controllers, {
                NAME         => $object->{Name},
                MANUFACTURER => $object->{Manufacturer},
                CAPTION      => $object->{Caption},
                TYPE         => $object->{Caption},
                deviceid     => ($object->{PNPDeviceID} && $object->{PNPDeviceID} =~ /^PCI\\/i)
                    ? $object->{PNPDeviceID}
                    : $object->{DeviceID},
            };
        }
    }

    return @controllers;
}

1;
