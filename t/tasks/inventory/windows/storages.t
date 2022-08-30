#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::Deep;
use Test::Exception;
use Test::MockModule;
use Test::More;
use UNIVERSAL::require;

use GLPI::Agent::Inventory;
use GLPI::Test::Utils;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

use Config;
# check thread support availability
if (!$Config{usethreads} || $Config{usethreads} ne 'define') {
    plan skip_all => 'thread support required';
}

Test::NoWarnings->use();

GLPI::Agent::Task::Inventory::Win32::Storages->require();

my %tests = (
    'win7-sp1-x64' => [
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VBOX HARDDISK ATA Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE0',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'IDE',
            FIRMWARE     => '1.0',
            SCSI_COID    => '2',
            SCSI_LUN     => '0',
            SCSI_UNID    => '0',
            DISKSIZE     => 102398,
            SERIAL       => 'VB2cff0f95-b2f7db11',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'Msft Virtual Disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE1',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '32',
            SCSI_LUN     => '1',
            SCSI_UNID    => '0',
            DISKSIZE     => 94,
        },
    ],
    '2008-Enterprise' => [
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE5',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '3',
            SCSI_LUN     => '0',
            SCSI_UNID    => '5',
            DISKSIZE     => 10236,
            SERIAL       => '6177c38f910a83560899e28ee97c6204',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE7',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '3',
            SCSI_LUN     => '0',
            SCSI_UNID    => '8',
            DISKSIZE     => 10236,
            SERIAL       => '6177c384f3a4b22fe3a32a1f1df90dd1',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE1',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '3',
            SCSI_LUN     => '0',
            SCSI_UNID    => '1',
            DISKSIZE     => 15359,
            SERIAL       => '6177c38465431cc70afd3be80ab1d98a',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE10',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '3',
            SCSI_LUN     => '0',
            SCSI_UNID    => '11',
            DISKSIZE     => 5114,
            SERIAL       => '6177c38882b0dcfec9dc3525ae711228',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE4',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '3',
            SCSI_LUN     => '0',
            SCSI_UNID    => '4',
            DISKSIZE     => 10236,
            SERIAL       => '6177c38fa127e960d13ab1f8f7926078',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE0',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '3',
            SCSI_LUN     => '0',
            SCSI_UNID    => '0',
            DISKSIZE     => 51199,
            SERIAL       => '6177c3800071a573d412dbd2e9a6f956',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE9',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '3',
            SCSI_LUN     => '0',
            SCSI_UNID    => '10',
            DISKSIZE     => 10236,
            SERIAL       => '6177c38350ccec80e6da3e20ed996381',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE3',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '3',
            SCSI_LUN     => '0',
            SCSI_UNID    => '3',
            DISKSIZE     => 10236,
            SERIAL       => '6177c38326803917dd2ef267a714c769',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE6',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '3',
            SCSI_LUN     => '0',
            SCSI_UNID    => '6',
            DISKSIZE     => 20473,
            SERIAL       => '6177c387b3af81b5328641579c1f7529',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE8',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '3',
            SCSI_LUN     => '0',
            SCSI_UNID    => '9',
            DISKSIZE     => 10236,
            SERIAL       => '6177c381745989ec97acaa3f8c78b479',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE2',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '3',
            SCSI_LUN     => '0',
            SCSI_UNID    => '2',
            DISKSIZE     => 20473,
            SERIAL       => '6177c387f9626cdf1fdd32a9cc06eadc',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE11',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '3',
            SCSI_LUN     => '0',
            SCSI_UNID    => '12',
            DISKSIZE     => 5114,
            SERIAL       => '6177c38064011ebba03c8181a9278340',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE12',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '3',
            SCSI_LUN     => '0',
            SCSI_UNID    => '13',
            DISKSIZE     => 5114,
            SERIAL       => '6177c38a85018bdb60210b12fcc086ca',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE13',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '3',
            SCSI_LUN     => '0',
            SCSI_UNID    => '14',
            DISKSIZE     => 5114,
            SERIAL       => '6177c38f54fc585faac8c2c9e22f6d1f',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE14',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '3',
            SCSI_LUN     => '0',
            SCSI_UNID    => '15',
            DISKSIZE     => 5114,
            SERIAL       => '6177c38082d23ed577bf5edbc0e01e20',
        },
        {
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'VMware Virtual disk SCSI Disk Device',
            DESCRIPTION  => 'Lecteur de disque',
            NAME         => '\\\\.\\PHYSICALDRIVE15',
            TYPE         => 'Fixed hard disk media',
            INTERFACE    => 'SCSI',
            FIRMWARE     => '1.0',
            SCSI_COID    => '4',
            SCSI_LUN     => '0',
            SCSI_UNID    => '0',
            DISKSIZE     => 5114,
            SERIAL       => '6177c38f7f15954bc0aecde5929afc0a',
        },
    ],
    'win10-crypt' => [
        {
            DESCRIPTION  => 'Lecteur de disque',
            DISKSIZE     => 488382,
            FIRMWARE     => 'AACA4100',
            INTERFACE    => 'SCSI',
            MANUFACTURER => '(Lecteurs de disque standard)',
            MODEL        => 'KXG50ZNV512G NVMe TOSHIBA 512GB',
            NAME         => '\\\\.\\PHYSICALDRIVE0',
            SCSI_COID    => '0',
            SCSI_LUN     => '0',
            SCSI_UNID    => '0',
            SERIAL       => '0000_A5B0_0000_0010_0008_0E02_0037_E465.',
            TYPE         => 'Fixed hard disk media'
        }
    ],
    'win10-edu-2020-fr' => [
        {
            MANUFACTURER => undef,
            MODEL        => 'VBOX HARDDISK',
            DESCRIPTION  => 'Integrated : Bus 0 : Device 13 : Function 0 : Adapter 0 : Port 0',
            NAME         => 'PhysicalDisk0',
            TYPE         => 'Virtual',
            INTERFACE    => 'SATA',
            FIRMWARE     => '1.0',
            SCSI_COID    => undef,
            SCSI_LUN     => undef,
            SCSI_UNID    => undef,
            DISKSIZE     => 51200,
            SERIAL       => 'VB56f85924-28919b73',
        },
        {
            MANUFACTURER => '(Lecteurs de CD-ROM standard)',
            MODEL        => 'VBOX CD-ROM',
            DESCRIPTION  => 'Lecteur de CD-ROM',
            NAME         => 'VBOX CD-ROM',
            TYPE         => 'Virtual',
            INTERFACE    => undef,
            FIRMWARE     => undef,
            SCSI_COID    => '0',
            SCSI_LUN     => '0',
            SCSI_UNID    => '0',
            DISKSIZE     => 60,
        },
    ],
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Agent::Inventory->new();

my $module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::Win32::Storages'
);

foreach my $test (sort keys %tests) {
    $module->mock(
        'getWMIObjects',
        mockGetWMIObjects($test)
    );

    my @storages;
    my $storages;

    $storages = GLPI::Agent::Task::Inventory::Win32::Storages::_getDrives(
        class   => 'MSFT_PhysicalDisk',
        moniker => 'winmgmts://./root/microsoft/windows/storage',
    );
    unless (@{$storages}) {
        $storages = GLPI::Agent::Task::Inventory::Win32::Storages::_getDrives(
            class => 'Win32_DiskDrive'
        );
    }
    push @storages, @{$storages};
    $storages = GLPI::Agent::Task::Inventory::Win32::Storages::_getDrives(
        class => 'Win32_CDROMDrive'
    );
    push @storages, @{$storages};

    cmp_deeply(
        \@storages,
        $tests{$test},
        "$test: parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'STORAGES', entry => $_)
            foreach @storages;
    } "$test: registering";
}
