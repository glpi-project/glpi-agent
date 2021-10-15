#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Generic::PCI::Controllers;

my %tests = (
    'dell-xt2' => [
        {
            NAME           => re('^Mobile 4 Series Chipset Memory Controller Hub'),
            TYPE           => 'Host bridge',
            CAPTION        => re('^Mobile 4 Series Chipset Memory Controller Hub'),
            DRIVER         => 'agpgart',
            PCISLOT        => '00:00.0',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0600',
            MANUFACTURER   => 'Intel Corporation',
            REV            => '07',
            VENDORID       => '8086',
            PRODUCTID      => '2a40',
        },
        {
            NAME           => re('^Mobile 4 Series Chipset Integrated Graphics Controller'),
            TYPE           => 'VGA compatible controller',
            CAPTION        => re('^Mobile 4 Series Chipset Integrated Graphics Controller'),
            DRIVER         => 'i915',
            PCISLOT        => '00:02.0',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0300',
            MANUFACTURER   => 'Intel Corporation',
            REV            => '07',
            VENDORID       => '8086',
            PRODUCTID      => '2a42'
        },
        {
            NAME           => re('^Mobile 4 Series Chipset Integrated Graphics Controller'),
            TYPE           => 'Display controller',
            CAPTION        => re('^Mobile 4 Series Chipset Integrated Graphics Controller'),
            PCISLOT        => '00:02.1',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0380',
            MANUFACTURER   => 'Intel Corporation',
            REV            => '07',
            VENDORID       => '8086',
            PRODUCTID      => '2a43'
        },
        {
            NAME           => re('^82567LM Gigabit Network Connection'),
            TYPE           => 'Ethernet controller',
            CAPTION        => re('^82567LM Gigabit Network Connection'),
            DRIVER         => 'e1000e',
            PCISLOT        => '00:19.0',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0200',
            MANUFACTURER   => 'Intel Corporation',
            REV            => '03',
            VENDORID       => '8086',
            PRODUCTID      => '10f5'
        },
        {
            NAME           => re('^82801I \([^)]+\) USB UHCI Controller #4'),
            TYPE           => 'USB controller',
            CAPTION        => re('^82801I \([^)]+\) USB UHCI Controller #4'),
            DRIVER         => 'uhci_hcd',
            PCISLOT        => '00:1a.0',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0c03',
            MANUFACTURER   => 'Intel Corporation',
            REV            => '03',
            VENDORID       => '8086',
            PRODUCTID      => '2937'
        },
        {
            NAME           => re('^82801I \([^)]+\) USB UHCI Controller #5'),
            TYPE           => 'USB controller',
            CAPTION        => re('^82801I \([^)]+\) USB UHCI Controller #5'),
            DRIVER         => 'uhci_hcd',
            PCISLOT        => '00:1a.1',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0c03',
            MANUFACTURER   => 'Intel Corporation',
            REV            => '03',
            VENDORID       => '8086',
            PRODUCTID      => '2938'
        },
        {
            NAME           => re('^82801I \([^)]+\) USB UHCI Controller #6'),
            TYPE           => 'USB controller',
            CAPTION        => re('^82801I \([^)]+\) USB UHCI Controller #6'),
            DRIVER         => 'uhci_hcd',
            PCISLOT        => '00:1a.2',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0c03',
            MANUFACTURER   => 'Intel Corporation',
            REV            => '03',
            VENDORID       => '8086',
            PRODUCTID      => '2939'
        },
        {
            NAME           => re('^82801I \([^)]+\) USB2 EHCI Controller #2'),
            TYPE           => 'USB controller',
            CAPTION        => re('^82801I \([^)]+\) USB2 EHCI Controller #2'),
            DRIVER         => 'ehci_hcd',
            PCISLOT        => '00:1a.7',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0c03',
            MANUFACTURER   => 'Intel Corporation',
            REV            => '03',
            VENDORID       => '8086',
            PRODUCTID      => '293c'
        },
        {
            NAME           => re('^82801I \([^)]+\) HD Audio Controller'),
            TYPE           => 'Audio device',
            CAPTION        => re('^82801I \([^)]+\) HD Audio Controller'),
            DRIVER         => 'snd_hda_intel',
            PCISLOT        => '00:1b.0',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0403',
            MANUFACTURER   => 'Intel Corporation',
            REV            => '03',
            VENDORID       => '8086',
            PRODUCTID      => '293e'
        },
        {
            NAME         => re('^82801I \([^)]+\) PCI Express Port 1'),
            TYPE         => 'PCI bridge',
            CAPTION      => re('^82801I \([^)]+\) PCI Express Port 1'),
            DRIVER       => 'pcieport',
            PCISLOT      => '00:1c.0',
            PCICLASS     => '0604',
            MANUFACTURER => 'Intel Corporation',
            REV          => '03',
            VENDORID     => '8086',
            PRODUCTID    => '2940'
        },
        {
            NAME         => re('^82801I \([^)]+\) PCI Express Port 2'),
            TYPE         => 'PCI bridge',
            CAPTION      => re('^82801I \([^)]+\) PCI Express Port 2'),
            DRIVER       => 'pcieport',
            PCISLOT      => '00:1c.1',
            PCICLASS     => '0604',
            MANUFACTURER => 'Intel Corporation',
            REV          => '03',
            VENDORID     => '8086',
            PRODUCTID    => '2942'
        },
        {
            NAME         => re('^82801I \([^)]+\) PCI Express Port 4'),
            TYPE         => 'PCI bridge',
            CAPTION      => re('^82801I \([^)]+\) PCI Express Port 4'),
            DRIVER       => 'pcieport',
            PCISLOT      => '00:1c.3',
            PCICLASS     => '0604',
            MANUFACTURER => 'Intel Corporation',
            REV          => '03',
            VENDORID     => '8086',
            PRODUCTID    => '2946'
        },
        {
            NAME           => re('^82801I \([^)]+\) USB UHCI Controller #1'),
            TYPE           => 'USB controller',
            CAPTION        => re('^82801I \([^)]+\) USB UHCI Controller #1'),
            DRIVER         => 'uhci_hcd',
            PCISLOT        => '00:1d.0',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0c03',
            MANUFACTURER   => 'Intel Corporation',
            REV            => '03',
            VENDORID       => '8086',
            PRODUCTID      => '2934'
        },
        {
            NAME           => re('^82801I \([^)]+\) USB UHCI Controller #2'),
            TYPE           => 'USB controller',
            CAPTION        => re('^82801I \([^)]+\) USB UHCI Controller #2'),
            DRIVER         => 'uhci_hcd',
            PCISLOT        => '00:1d.1',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0c03',
            MANUFACTURER   => 'Intel Corporation',
            REV            => '03',
            VENDORID       => '8086',
            PRODUCTID      => '2935'
        },
        {
            NAME           => re('^82801I \([^)]+\) USB UHCI Controller #3'),
            TYPE           => 'USB controller',
            CAPTION        => re('^82801I \([^)]+\) USB UHCI Controller #3'),
            DRIVER         => 'uhci_hcd',
            PCISLOT        => '00:1d.2',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0c03',
            MANUFACTURER   => 'Intel Corporation',
            REV            => '03',
            VENDORID       => '8086',
            PRODUCTID      => '2936'
        },
        {
            NAME           => re('^82801I \([^)]+\) USB2 EHCI Controller #1'),
            TYPE           => 'USB controller',
            CAPTION        => re('^82801I \([^)]+\) USB2 EHCI Controller #1'),
            DRIVER         => 'ehci_hcd',
            PCISLOT        => '00:1d.7',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0c03',
            MANUFACTURER   => 'Intel Corporation',
            REV            => '03',
            VENDORID       => '8086',
            PRODUCTID      => '293a'
        },
        {
            NAME         => re('^82801 Mobile PCI Bridge'),
            TYPE         => 'PCI bridge',
            CAPTION      => re('^82801 Mobile PCI Bridge'),
            PCISLOT      => '00:1e.0',
            PCICLASS     => '0604',
            MANUFACTURER => 'Intel Corporation',
            REV          => '93',
            VENDORID     => '8086',
            PRODUCTID    => '2448'
        },
        {
            NAME           => re('^ICH9M-E LPC Interface Controller'),
            TYPE           => 'ISA bridge',
            CAPTION        => re('^ICH9M-E LPC Interface Controller'),
            PCISLOT        => '00:1f.0',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0601',
            MANUFACTURER   => 'Intel Corporation',
            REV            => '03',
            VENDORID       => '8086',
            PRODUCTID      => '2917'
        },
        {
            TYPE           => 'RAID bus controller',
            PRODUCTID      => '282a',
            DRIVER         => 'ahci',
            VENDORID       => '8086',
            MANUFACTURER   => 'Intel Corporation',
            PCISLOT        => '00:1f.2',
            PCISUBSYSTEMID => '1028:0252',
            NAME           => '82801 Mobile SATA Controller [RAID mode]',
            REV            => '03',
            PCICLASS       => '0104',
            CAPTION        => '82801 Mobile SATA Controller [RAID mode]'
        },
        {
            NAME           => re('^82801I \([^)]+\) SMBus Controller'),
            TYPE           => 'SMBus',
            CAPTION        => re('^82801I \([^)]+\) SMBus Controller'),
            DRIVER         => 'i801_smbus',
            PCISLOT        => '00:1f.3',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0c05',
            MANUFACTURER   => 'Intel Corporation',
            REV            => '03',
            VENDORID       => '8086',
            PRODUCTID      => '2930'
        },
        {
            NAME           => re('^PCIxx12 Cardbus Controller'),
            TYPE           => 'CardBus bridge',
            CAPTION        => re('^PCIxx12 Cardbus Controller'),
            DRIVER         => 'yenta_cardbus',
            PCISLOT        => '02:01.0',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0607',
            MANUFACTURER   => 'Texas Instruments',
            REV            => undef,
            VENDORID       => '104c',
            PRODUCTID      => '8039'
        },
        {
            NAME           => re('^PCIxx12 OHCI Compliant IEEE 1394 Host Controller'),
            TYPE           => 'FireWire (IEEE 1394)',
            CAPTION        => re('^PCIxx12 OHCI Compliant IEEE 1394 Host Controller'),
            DRIVER         => 'firewire_ohci',
            PCISLOT        => '02:01.1',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0c00',
            MANUFACTURER   => 'Texas Instruments',
            REV            => undef,
            VENDORID       => '104c',
            PRODUCTID      => '803a'
        },
        {
            NAME           => re('^PCIxx12 SDA Standard Compliant SD Host Controller'),
            TYPE           => 'SD Host controller',
            CAPTION        => re('^PCIxx12 SDA Standard Compliant SD Host Controller'),
            DRIVER         => 'sdhci',
            PCISLOT        => '02:01.3',
            PCISUBSYSTEMID => '1028:0252',
            PCICLASS       => '0805',
            MANUFACTURER   => 'Texas Instruments',
            REV            => undef,
            VENDORID       => '104c',
            PRODUCTID      => '803c'
        },
        {
            NAME           => re('^WiFi Link 5100'),
            TYPE           => 'Network controller',
            CAPTION        => re('^WiFi Link 5100'),
            DRIVER         => 'iwlwifi',
            PCISLOT        => '0c:00.0',
            PCISUBSYSTEMID => '8086:1321',
            PCICLASS       => '0280',
            MANUFACTURER   => 'Intel Corporation',
            REV            => undef,
            VENDORID       => '8086',
            PRODUCTID      => '4232'
        }
    ],
    'linux-2' => [
        {
            CAPTION        => '82975X Memory Controller Hub',
            DRIVER         => 'i82975x_edac',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => '82975X Memory Controller Hub',
            PCICLASS       => '0600',
            PCISLOT        => '00:00.0',
            PCISUBSYSTEMID => '1028:01de',
            PRODUCTID      => '277c',
            REV            => undef,
            TYPE           => 'Host bridge',
            VENDORID       => '8086'
        },
        {
            CAPTION        => '82975X PCI Express Root Port',
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => '82975X PCI Express Root Port',
            PCICLASS       => '0604',
            PCISLOT        => '00:01.0',
            PRODUCTID      => '277d',
            REV            => undef,
            TYPE           => 'PCI bridge',
            VENDORID       => '8086'
        },
        {
            CAPTION        => 'NM10/ICH7 Family High Definition Audio Controller',
            DRIVER         => 'snd_hda_intel',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => 'NM10/ICH7 Family High Definition Audio Controller',
            PCICLASS       => '0403',
            PCISLOT        => '00:1b.0',
            PCISUBSYSTEMID => '1028:01de',
            PRODUCTID      => '27d8',
            REV            => '01',
            TYPE           => 'Audio device',
            VENDORID       => '8086'
        },
        {
            CAPTION        => 'NM10/ICH7 Family PCI Express Port 1',
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => 'NM10/ICH7 Family PCI Express Port 1',
            PCICLASS       => '0604',
            PCISLOT        => '00:1c.0',
            PRODUCTID      => '27d0',
            REV            => '01',
            TYPE           => 'PCI bridge',
            VENDORID       => '8086'
        },
        {
            CAPTION        => '82801GR/GH/GHM (ICH7 Family) PCI Express Port 5',
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => '82801GR/GH/GHM (ICH7 Family) PCI Express Port 5',
            PCICLASS       => '0604',
            PCISLOT        => '00:1c.4',
            PRODUCTID      => '27e0',
            REV            => '01',
            TYPE           => 'PCI bridge',
            VENDORID       => '8086'
        },
        {
            CAPTION        => '82801GR/GH/GHM (ICH7 Family) PCI Express Port 6',
            DRIVER         => 'pcieport',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => '82801GR/GH/GHM (ICH7 Family) PCI Express Port 6',
            PCICLASS       => '0604',
            PCISLOT        => '00:1c.5',
            PRODUCTID      => '27e2',
            REV            => '01',
            TYPE           => 'PCI bridge',
            VENDORID       => '8086'
        },
        {
            CAPTION        => 'NM10/ICH7 Family USB UHCI Controller #1',
            DRIVER         => 'uhci_hcd',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => 'NM10/ICH7 Family USB UHCI Controller #1',
            PCICLASS       => '0c03',
            PCISLOT        => '00:1d.0',
            PCISUBSYSTEMID => '1028:01de',
            PRODUCTID      => '27c8',
            REV            => '01',
            TYPE           => 'USB controller',
            VENDORID       => '8086'
        },
        {
            CAPTION        => 'NM10/ICH7 Family USB UHCI Controller #2',
            DRIVER         => 'uhci_hcd',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => 'NM10/ICH7 Family USB UHCI Controller #2',
            PCICLASS       => '0c03',
            PCISLOT        => '00:1d.1',
            PCISUBSYSTEMID => '1028:01de',
            PRODUCTID      => '27c9',
            REV            => '01',
            TYPE           => 'USB controller',
            VENDORID       => '8086'
        },
        {
            CAPTION        => 'NM10/ICH7 Family USB UHCI Controller #3',
            DRIVER         => 'uhci_hcd',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => 'NM10/ICH7 Family USB UHCI Controller #3',
            PCICLASS       => '0c03',
            PCISLOT        => '00:1d.2',
            PCISUBSYSTEMID => '1028:01de',
            PRODUCTID      => '27ca',
            REV            => '01',
            TYPE           => 'USB controller',
            VENDORID       => '8086'
        },
        {
            CAPTION        => 'NM10/ICH7 Family USB UHCI Controller #4',
            DRIVER         => 'uhci_hcd',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => 'NM10/ICH7 Family USB UHCI Controller #4',
            PCICLASS       => '0c03',
            PCISLOT        => '00:1d.3',
            PCISUBSYSTEMID => '1028:01de',
            PRODUCTID      => '27cb',
            REV            => '01',
            TYPE           => 'USB controller',
            VENDORID       => '8086'
        },
        {
            CAPTION        => 'NM10/ICH7 Family USB2 EHCI Controller',
            DRIVER         => 'ehci',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => 'NM10/ICH7 Family USB2 EHCI Controller',
            PCICLASS       => '0c03',
            PCISLOT        => '00:1d.7',
            PCISUBSYSTEMID => '1028:01de',
            PRODUCTID      => '27cc',
            REV            => '01',
            TYPE           => 'USB controller',
            VENDORID       => '8086'
        },
        {
            CAPTION        => '82801 PCI Bridge',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => '82801 PCI Bridge',
            PCICLASS       => '0604',
            PCISLOT        => '00:1e.0',
            PRODUCTID      => '244e',
            REV            => undef,
            TYPE           => 'PCI bridge',
            VENDORID       => '8086'
        },
        {
            CAPTION        => '82801GB/GR (ICH7 Family) LPC Interface Bridge',
            DRIVER         => 'lpc_ich',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => '82801GB/GR (ICH7 Family) LPC Interface Bridge',
            PCICLASS       => '0601',
            PCISLOT        => '00:1f.0',
            PRODUCTID      => '27b8',
            REV            => '01',
            TYPE           => 'ISA bridge',
            VENDORID       => '8086'
        },
        {
            CAPTION        => '82801G (ICH7 Family) IDE Controller',
            DRIVER         => 'ata_piix',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => '82801G (ICH7 Family) IDE Controller',
            PCICLASS       => '0101',
            PCISLOT        => '00:1f.1',
            PCISUBSYSTEMID => '1028:01de',
            PRODUCTID      => '27df',
            REV            => '01',
            TYPE           => 'IDE interface',
            VENDORID       => '8086'
        },
        {
            CAPTION        => 'NM10/ICH7 Family SATA Controller [AHCI mode]',
            DRIVER         => 'ahci',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => 'NM10/ICH7 Family SATA Controller [AHCI mode]',
            PCICLASS       => '0106',
            PCISLOT        => '00:1f.2',
            PCISUBSYSTEMID => '1028:01de',
            PRODUCTID      => '27c1',
            REV            => '01',
            TYPE           => 'SATA controller',
            VENDORID       => '8086'
        },
        {
            CAPTION        => 'NM10/ICH7 Family SMBus Controller',
            DRIVER         => 'i801_smbus',
            MANUFACTURER   => 'Intel Corporation',
            NAME           => 'NM10/ICH7 Family SMBus Controller',
            PCICLASS       => '0c05',
            PCISLOT        => '00:1f.3',
            PCISUBSYSTEMID => '1028:01de',
            PRODUCTID      => '27da',
            REV            => '01',
            TYPE           => 'SMBus',
            VENDORID       => '8086'
        },
        {
            CAPTION        => 'NV43GL [Quadro FX 550]',
            DRIVER         => 'nvidia',
            MANUFACTURER   => 'NVIDIA Corporation',
            NAME           => 'NV43GL [Quadro FX 550]',
            PCICLASS       => '0300',
            PCISLOT        => '01:00.0',
            PCISUBSYSTEMID => '10de:0349',
            PRODUCTID      => '014d',
            REV            => undef,
            TYPE           => 'VGA compatible controller',
            VENDORID       => '10de'
        },
        {
            CAPTION        => 'NetXtreme BCM5754 Gigabit Ethernet PCI Express',
            DRIVER         => 'tg3',
            MANUFACTURER   => 'Broadcom Inc. and subsidiaries',
            NAME           => 'Precision 390',
            PCICLASS       => '0200',
            PCISLOT        => '04:00.0',
            PCISUBSYSTEMID => '1028:01de',
            PRODUCTID      => '167a',
            REV            => '02',
            TYPE           => 'Ethernet controller',
            VENDORID       => '14e4'
        },
        {
            CAPTION        => 'FW322/323 [TrueFire] 1394a Controller',
            DRIVER         => 'firewire_ohci',
            MANUFACTURER   => 'LSI Corporation',
            NAME           => 'FW322/323 [TrueFire] 1394a Controller',
            PCICLASS       => '0c00',
            PCISLOT        => '05:02.0',
            PCISUBSYSTEMID => '1028:8010',
            PRODUCTID      => '5811',
            REV            => '61',
            TYPE           => 'FireWire (IEEE 1394)',
            VENDORID       => '11c1'
        }
    ],
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/generic/lspci/$test";
    my @controllers = GLPI::Agent::Task::Inventory::Generic::PCI::Controllers::_getControllers(file => $file, datadir => 'share');
    cmp_deeply(\@controllers, $tests{$test}, $test);
    lives_ok {
        $inventory->addEntry(section => 'CONTROLLERS', entry => $_)
            foreach @controllers;
    } "$test: registering";
}
