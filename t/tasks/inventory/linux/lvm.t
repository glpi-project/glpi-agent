#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::LVM;

my %lvs = (
    'linux-1' => [
        {
            LV_UUID   => '2ByrwP-byIK-8twm-qyHd-Bjm9-EwFd-CzPaAd',
            SIZE      => 5901,
            ATTR      => '-wi-ao',
            VG_UUID   => 'Eubwcw-UFh2-P3Kn-aI6y-qcLT-VCzU-ls49ha',
            LV_NAME   => 'home',
            SEG_COUNT => '1'
        },
        {
            LV_UUID   => 'riXTVv-5mnl-GuL8-ScBl-MZXk-iXZu-QZsAz4',
            SIZE      => 348,
            ATTR      => '-wi-ao',
            VG_UUID   => 'Eubwcw-UFh2-P3Kn-aI6y-qcLT-VCzU-ls49ha',
            LV_NAME   => 'root',
            SEG_COUNT => '1'
        },
        {
            LV_UUID   => 'OHAvld-GHNN-OXCe-RgMc-gai7-Kybd-8BKTY8',
            SIZE      => 893,
            ATTR      => '-wi-ao',
            VG_UUID   => 'Eubwcw-UFh2-P3Kn-aI6y-qcLT-VCzU-ls49ha',
            LV_NAME   => 'swap_1',
            SEG_COUNT => '1'
        },
        {
            LV_UUID   => 'KxoaKL-QUpk-y6hr-aCdX-0d2g-RlGG-jX0Nf5',
            SIZE      => 398,
            ATTR      => '-wi-ao',
            VG_UUID   => 'Eubwcw-UFh2-P3Kn-aI6y-qcLT-VCzU-ls49ha',
            LV_NAME   => 'tmp',
            SEG_COUNT => '1'
        },
        {
            LV_UUID   => 'jJBN5Y-Fi5d-ee15-zL38-OCPh-HAfn-fnjbri',
            SIZE      => 5611,
            ATTR      => '-wi-ao',
            VG_UUID   => 'Eubwcw-UFh2-P3Kn-aI6y-qcLT-VCzU-ls49ha',
            LV_NAME   => 'usr',
            SEG_COUNT => '1'
        },
        {
            LV_UUID   => 'RULgoh-9Wey-1b0F-glTA-jYTY-eJdL-ThTqNM',
            SIZE      => 2692,
            ATTR      => '-wi-ao',
            VG_UUID   => 'Eubwcw-UFh2-P3Kn-aI6y-qcLT-VCzU-ls49ha',
            LV_NAME   => 'var',
            SEG_COUNT => '1'
        },
        {
            LV_UUID   => 'd7HvFr-XI61-W7tF-zjh8-hfqj-TH3G-AOi5Ul',
            SIZE      => 104,
            ATTR      => '-wi-a-',
            VG_UUID   => 'ZHOqQg-SNQJ-a79U-Jfn1-Az84-e04w-d9zH23',
            LV_NAME   => 'lvol0',
            SEG_COUNT => '1'
        },
        {
            LV_UUID   => 'FUrHhK-H53S-AWV6-lqcK-tcTm-dHYb-xIbhQs',
            SIZE      => 104,
            ATTR      => '-wi-a-',
            VG_UUID   => 'ZHOqQg-SNQJ-a79U-Jfn1-Az84-e04w-d9zH23',
            LV_NAME   => 'lvol1',
            SEG_COUNT => '1'
        }
    ]
);

my %pvs = (
    'linux-1' => [
        {
            SIZE        => 15846,
            FORMAT      => 'lvm2',
            ATTR        => 'a-',
            FREE        => 0,
            DEVICE      => '/dev/sda5',
            PV_PE_COUNT => '3778',
            PE_SIZE     => 4,
            PV_UUID     => 'MjsnP7-GaGC-NIo7-tS3o-gf2t-di2R-eP3Au7',
            VG_UUID     => undef
        },
        {
            SIZE        => 2466,
            FORMAT      => 'lvm2',
            ATTR        => 'a-',
            FREE        => 2256,
            DEVICE      => '/dev/sdb1',
            PV_PE_COUNT => '588',
            PE_SIZE     => 4,
            PV_UUID     => 'LNDa6y-PQGQ-gtnc-c7Wc-W2lS-Soaf-Bwu2Me',
            VG_UUID     => undef
        },
        {
            SIZE        => 2894,
            FORMAT      => 'lvm2',
            ATTR        => 'a-',
            FREE        => 2894,
            DEVICE      => '/dev/sdb2',
            PV_PE_COUNT => '690',
            PE_SIZE     => 4,
            PV_UUID     => 'xkxfmu-fQLt-DtKZ-YnkY-vwcj-JqC2-WmQddD',
            VG_UUID     => undef
        }
    ],
    'linux-2' => [
        {
            SIZE        => 311452,
            FORMAT      => 'lvm2',
            ATTR        => 'a--',
            FREE        => 125694,
            DEVICE      => '/dev/sda2',
            PV_PE_COUNT => 9282,
            PE_SIZE     => 33,
            PV_UUID     => 'CnCKHH-tnlS-BFL5-qRMa-HaV2-10zm-kNIpEp',
            VG_UUID     => 'OFXZR2-dEjD-qVIj-VJnw-1dQY-wC57-O1TABn'
        },
        {
            SIZE        => 58921,
            FORMAT      => 'lvm2',
            ATTR        => 'a--',
            FREE        => 18119,
            DEVICE      => '/dev/sdb2',
            PV_PE_COUNT => 1756,
            PE_SIZE     => 33,
            PV_UUID     => 'XMzcNr-5qrL-pXk1-9Ycl-FyfN-nXPe-ndRvHF',
            VG_UUID     => 'OFXZR2-dEjD-qVIj-VJnw-1dQY-wC57-O1TABn'
        },
        {
            SIZE        => 500095,
            FORMAT      => 'lvm2',
            ATTR        => 'a--',
            FREE        => 241323,
            DEVICE      => '/dev/sdc1',
            PV_PE_COUNT => 14904,
            PE_SIZE     => 33,
            PV_UUID     => 'GnT78t-kb92-k8di-1uUv-28HK-H6za-SXe2EZ',
            VG_UUID     => 'OFXZR2-dEjD-qVIj-VJnw-1dQY-wC57-O1TABn'
        }
    ],
    'linux-3' => [
        {
            SIZE        => 53791,
            FORMAT      => 'lvm2',
            ATTR        => 'a-',
            FREE        => 18694,
            DEVICE      => '/dev/sda5',
            PV_PE_COUNT => 12825,
            VG_UUID     => '4D8fsm-J18u-IBB8-0TDT-tdIc-qDWr-COXhld',
            PE_SIZE     => 4,
            PV_UUID     => 'wDobJX-zfTq-A1Ka-70Nz-caiV-uNbt-QZEsKS'
        },
        {
            SIZE        => 182087,
            FORMAT      => 'lvm2',
            ATTR        => 'a-',
            FREE        => 0,
            DEVICE      => '/dev/sdb',
            PV_PE_COUNT => 43413,
            VG_UUID     => '8VYDvK-WrSD-5v8m-UgyR-g7GR-V4hK-y7q2On',
            PE_SIZE     => 4,
            PV_UUID     => 'HIQlf6-bTeX-douO-zHZQ-U1SG-637I-tsaxwL'
        },
        {
            SIZE        => 182087,
            FORMAT      => 'lvm2',
            ATTR        => 'a-',
            FREE        => 4,
            DEVICE      => '/dev/sdc',
            PV_PE_COUNT => 43413,
            VG_UUID     => '8VYDvK-WrSD-5v8m-UgyR-g7GR-V4hK-y7q2On',
            PE_SIZE     => 4,
            PV_UUID     => 'FyNUgz-K2Qs-q8vt-1yO4-3TQy-3z1H-Xg6B0r'
        }
    ]
);

my %vgs = (
    'linux-1' => [
        {
            SIZE           => 15846,
            ATTR           => 'wz--n-',
            VG_NAME        => 'lvm',
            FREE           => 0,
            PV_COUNT       => '1',
            VG_UUID        => 'Eubwcw-UFh2-P3Kn-aI6y-qcLT-VCzU-ls49ha',
            LV_COUNT       => '6',
            VG_EXTENT_SIZE => '4.19'
        },
        {
            SIZE           => 5360,
            ATTR           => 'wz--n-',
            VG_NAME        => 'lvm2',
            FREE           => 5150,
            PV_COUNT       => '2',
            VG_UUID        => 'ZHOqQg-SNQJ-a79U-Jfn1-Az84-e04w-d9zH23',
            LV_COUNT       => '2',
            VG_EXTENT_SIZE => '4.19'
        }
    ],
    'linux-2' => [
        {
            SIZE           => 870469,
            ATTR           => 'wz--n-',
            VG_NAME        => 'vg00',
            FREE           => 385137,
            PV_COUNT       => '3',
            VG_UUID        => 'OFXZR2-dEjD-qVIj-VJnw-1dQY-wC57-O1TABn',
            LV_COUNT       => '16',
            VG_EXTENT_SIZE => '33.55'
        }
    ],
    'linux-3' => [
        {
            SIZE           => 53791,
            ATTR           => 'wz--n-',
            VG_NAME        => 'vg0',
            FREE           => 18694,
            PV_COUNT       => '1',
            VG_UUID        => '4D8fsm-J18u-IBB8-0TDT-tdIc-qDWr-COXhld',
            LV_COUNT       => '5',
            VG_EXTENT_SIZE => '4.19'
        },
        {
            SIZE           => 364174,
            ATTR           => 'wz--n-',
            VG_NAME        => 'vg1',
            FREE           => 4,
            PV_COUNT       => '2',
            VG_UUID        => '8VYDvK-WrSD-5v8m-UgyR-g7GR-V4hK-y7q2On',
            LV_COUNT       => '1',
            VG_EXTENT_SIZE => '4.19'
        }
    ]
);

plan tests =>
    (2 * scalar keys %pvs) +
    (2 * scalar keys %lvs) +
    (2 * scalar keys %vgs) +
    1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %pvs) {
    my @pvs = GLPI::Agent::Task::Inventory::Linux::LVM::_getPhysicalVolumes(file => "resources/lvm/linux/pvs/$test");
    cmp_deeply(\@pvs, $pvs{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'PHYSICAL_VOLUMES', entry => $_)
            foreach @pvs;
    } "$test: registering";
}

foreach my $test (keys %lvs) {
    my @lvs = GLPI::Agent::Task::Inventory::Linux::LVM::_getLogicalVolumes(file => "resources/lvm/linux/lvs/$test");
    cmp_deeply(\@lvs, $lvs{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'LOGICAL_VOLUMES', entry => $_)
            foreach @lvs;
    } "$test: registering";
}

foreach my $test (keys %vgs) {
    my @vgs = GLPI::Agent::Task::Inventory::Linux::LVM::_getVolumeGroups(file => "resources/lvm/linux/vgs/$test");
    cmp_deeply(\@vgs, $vgs{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'VOLUME_GROUPS', entry => $_)
            foreach @vgs;
    } "$test: registering";
}
