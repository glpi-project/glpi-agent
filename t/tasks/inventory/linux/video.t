#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::Linux::Videos;

my %ddcprobe = (
    '98LMTF053166' => {
        eisa        => 'ACI22ab',
        input       => 'sync on green, analog signal.',
        mode        => '640x480x64k',
        monitorserial => '98LMTF053166',
        edid        => '1 3',
        monitorrange => '30-85, 55-75',
        id          => '22ab',
        dtiming     => '1920x1080@67',
        serial      => '0000cfae',
        oem         => 'Intel(r) 82945GM Chipset Family Graphics Chip Accelerated VGA BIOS',
        ctiming     => '1920x1200@60',
        gamma       => '2.200000',
        memory      => '7872kb',
        timing      => '1280x1024@75 (VESA)',
        monitorname => 'ASUS VH222',
        screensize  => '47 26',
        manufacture => '32 2009',
        dpms        => 'RGB, active off, no suspend, no standby',
        product     => 'Intel(r) 82945GM Chipset Family Graphics Controller Hardware Version 0.0',
        vendor      => 'Intel Corporation',
        vbe         => 'VESA 3.0 detected.'
    },
    'B101AW03' => {
        eisa        => 'AUO30d2',
        input       => 'analog signal.',
        mode        => '640x480x64k',
        edid        => '1 3',
        id          => '30d2',
        dtiming     => '1024x600@74',
        serial      => '00000000',
        oem         => 'Intel(r) 82945GM Chipset Family Graphics Chip Accelerated VGA BIOS',
        gamma       => '2.200000',
        memory      => '7872kb',
        monitorid   => 'B101AW03 V0',
        screensize  => '22 13',
        manufacture => '1 2008',
        dpms        => 'RGB, no active off, no suspend, no standby',
        product     => 'Intel(r) 82945GM Chipset Family Graphics Controller Hardware Version 0.0',
        vendor      => 'Intel Corporation',
        vbe         => 'VESA 3.0 detected.'
    },
    'HT009154WU2' => {
        eisa        => 'LGD018f',
        input       => 'analog signal.',
        mode        => '640x480x64k',
        edid        => '1 3',
        id          => '018f',
        dtiming     => '1920x1200@54',
        serial      => '00000000',
        oem         => 'Intel(r)Cantiga Graphics Chip Accelerated VGA BIOS',
        gamma       => '2.200000',
        memory      => '32704kb',
        monitorid   => 'HT009154WU2',
        screensize  => '33 21',
        manufacture => '0 2008',
        dpms        => 'RGB, no active off, no suspend, no standby',
        product     => 'Intel(r)Cantiga Graphics Controller Hardware Version 0.0',
        vendor      => 'Intel Corporation',
        vbe         => 'VESA 3.0 detected.'
    },
    S2202W => {
        eisa        => 'ENC1975',
        input       => 'analog signal.',
        mode        => '1600x1200x64k',
        monitorserial => '53471089',
        edid        => '1 3',
        monitorrange => '31-65, 59-61',
        id          => '1975',
        dtiming     => '1680x1050@59',
        serial      => '01010101',
        oem         => 'ATI ATOMBIOS',
        ctiming     => '1280x960@60',
        gamma       => '2.200000',
        memory      => '16384kb',
        timing      => '1024x768@87 Hz Interlaced (8514A)',
        monitorname => 'S2202W',
        screensize  => '48 30',
        manufacture => '33 2009',
        dpms        => 'RGB, active off, suspend, standby',
        product     => 'RV620 01.00',
        vendor      => '(C) 1988-2005, ATI Technologies Inc.',
        vbe         => 'VESA 3.0 detected.'
    },
    'virtualbox-1' => {
        memory      => '12288kb',
        mode        => '1280x1024x16m',
        oem         => 'VirtualBox VBE BIOS http://www.virtualbox.org/',
        vbe         => 'VESA 2.0 detected.'
    },
    'no-edid' => {
        memory      => '12288kb',
        mode        => '1280x1024x16m',
        oem         => 'VirtualBox VBE BIOS http://www.virtualbox.org/',
        vbe         => 'VESA 2.0 detected.'
    },
    'B154EW02' => {
        eisa        => 'AUO2074',
        input       => 'analog signal.',
        mode        => '640x480x64k',
        edid        => '1 3',
        id          => '2074',
        dtiming     => '1280x800@60',
        serial      => '00000000',
        oem         => 'Intel(r)GM965/PM965/GL960 Graphics Chip Accelerated VGA BIOS',
        gamma       => '2.200000',
        memory      => '7616kb',
        monitorid   => 'B154EW02 V0',
        screensize  => '33 21',
        manufacture => '1 2006',
        dpms        => 'RGB, no active off, no suspend, no standby',
        product     => 'Intel(r)GM965/PM965/GL960 Graphics Controller Hardware Version 0.0',
        vendor      => 'Intel Corporation',
        vbe         => 'VESA 3.0 detected.'
    }
);

my %xorg = (
    'linux-intel-1' => {
        pcislot    => '00:02.0',
        pciid      => '8086:27ae:1025:022f',
        resolution => '1024x600',
        name       => 'Intel(R) 945GME'
    },
    'linux-intel-2' => {
        pcislot    => '00:02.0',
        pciid      => '8086:27ae:144d:ca00',
        resolution => '1024x600',
        name       => 'Intel(R) 945GME'
    },
    'linux-intel-3' => {
        pcislot    => '00:02.0',
        pciid      => '8086:2e32:1028:0400',
        resolution => '1920x1080',
        name       => 'Intel(R) G41'
    },
    'linux-intel-4' => {
        memory     => '7616kB',
        resolution => '1280x800',
        pcislot    => '00:02.0',
        name       => 'Intel(r)GM965/PM965/GL960 Graphics Chip Accelerated VGA BIOS',
        product    => 'Intel(r)GM965/PM965/GL960 Graphics Controller'
    },
    'linux-nvidia-1' => {
        pcislot    => '05:00.0',
        pciid      => '10de:06e4:0000:0000',
        resolution => '1680x1050',
        memory     => '524288kB',
        name       => 'GeForce 8400 GS (G98)'
    },
    'linux-nvidia-2' => {
        pcislot    => '01:00.0',
        pciid      => '10de:01d3:10b0:0401',
        resolution => '2960x1050',
        memory     => '524288kB',
        name       => 'GeForce 7300 SE/7200 GS (G72)'
    },
    'linux-nvidia-3' => {
        pcislot    => '01:00.0',
        pciid      => '10de:014d:10de:0349',
        resolution => '1600x1200',
        memory     => '131072kB',
        name       => 'Quadro FX 550 (NV43GL)',
    },
    'linux-vesa-1' => {
        memory     => '12288kB',
        resolution => '1280x1024',
        pcislot    => '00:02.0',
        name       => 'VirtualBox VBE BIOS http://www.virtualbox.org/',
        product    => 'Oracle VM VirtualBox VBE Adapter'
    },
    'linux-vesa-3' => {
        memory     => '12288kB',
        resolution => '1024x768',
        pcislot    => '00:02.0',
        name       => 'VirtualBox VBE BIOS http://www.virtualbox.org/',
        product    => 'Oracle VM VirtualBox VBE Adapter'
    },
    'linux-ati-1' => {
        pcislot    => '01:05.0',
        pciid      => '1002:9715:1458:d000',
        resolution => '1920x1080',
        name       => 'ATI Radeon HD 4290'
    },
    'linux-ati-2' => {
        pcislot    => '00:01.0',
        memory     => '8128kB',
        resolution => '1024x768',
        name       => 'ATI MACH64',
        product    => 'MACH64GM'
    },
    'linux-nouveau' => {
        pcislot    => '01:00.0',
        pciid      => '10de:0421:1043:8264',
        resolution => '1680x1050',
        product    => 'NVIDIA NV86'
    }

);

plan tests =>
    (scalar keys %ddcprobe) +
    (scalar keys %xorg)     +
    1;

foreach my $test (keys %ddcprobe) {
    my $file = "resources/linux/ddcprobe/$test";
    my $result = GLPI::Agent::Task::Inventory::Linux::Videos::_getDdcprobeData(file => $file);
    cmp_deeply($result, $ddcprobe{$test}, $test);
}

foreach my $test (keys %xorg) {
    my $file = "resources/generic/xorg/$test";
    my $result = GLPI::Agent::Task::Inventory::Linux::Videos::_parseXorgFd(file => $file);
    cmp_deeply($result, $xorg{$test}, $test);
}
