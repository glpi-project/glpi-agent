#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::Virtualization::Qemu;

my @tests = (
    {
        CMD     => "qemu -hda /dev/hda -m 256 foobar",
        _result => {
            name    => '/dev/hda',
            vmtype  => 'qemu',
            mem     => 256
        }
    },
    {
        CMD =>
"kvm -k fr -name xppro --smbios type=1,manufacturer=MySelf,product=myBios,version=1.2.3,serial=myserial,uuid=BB123450-C977-11DF-1234-B01234557082 -vnc :1 -vga std -m 512 -net nic,model=rtl8139,macaddr=12:34:56:17:24:56 -net user -usb -usbdevice host:0a5c:5800 -usbdevice mouse -usbdevice host:0bb4:0c02 -redir tcp:3390::3389 xppro.raw -boot c",
        _result => {
            'serial' => 'myserial',
            'mem'    => 512,
            'uuid'   => 'BB123450-C977-11DF-1234-B01234557082',
            'vmtype' => 'kvm',
            'name'   => 'xppro'
        }
    },
    {
        CMD =>
"qemu -hda /dev/hda -uuid BB123450-C977-11DF-1234-B01234557082 -m 256 -name foobar",
        _result => {
            'name' => 'foobar',
            'mem'  => 256,
            vmtype => 'qemu',
            'uuid' => 'BB123450-C977-11DF-1234-B01234557082'
        }
    },
    {
        CMD =>
"/usr/bin/kvm -id 108 -daemonize -smbios type=1,uuid=a61349d9-c2b8-4d6c-9539-e1c7af2136c5 -name Win2008x64 -nodefaults -vga vmware -no-hpet -m size=1024,slots=255,maxmem=4194304M -netdev type=tap,id=net0,ifname=tap108i0,script=/var/lib/qemu-server/pve-bridge,downscript=/var/lib/qemu-server/pve-bridgedown -device e1000,mac=92:AE:98:70:A0:99,netdev=net0,bus=pci.0,addr=0x12,id=net0,bootindex=300 -rtc driftfix=slew,base=localtime -global kvm-pit.lost_tick_policy=discard",
        _result => {
            'name' => 'Win2008x64',
            'mem'  => 1024,
            vmtype => 'kvm',
            'uuid' => 'a61349d9-c2b8-4d6c-9539-e1c7af2136c5'
        }
    },
    {
        CMD =>
"qemu-system-x86_64 -enable-kvm -name DEV -m 4096 -uuid 6df8f2f4-34dc-44da-bff8-b52fc993a7d2",
        _result => {
            name   => 'DEV',
            mem    => 4096,
            vmtype => 'kvm',
            uuid   => '6df8f2f4-34dc-44da-bff8-b52fc993a7d2'
        }
    },
    {
        CMD =>
"/usr/bin/kvm -id 1010 -name pve100-wts1c,debug-threads=on -no-shutdown -chardev socket,id=qmp,path=/var/run/qemu-server/1010.qmp,server=on,wait=off -mon chardev=qmp,mode=control -chardev socket,id=qmp-event,path=/var/run/qmeventd.sock,reconnect=5 -mon chardev=qmp-event,mode=control -pidfile /var/run/qemu-server/1010.pid -daemonize -smbios type=1",
        _result => {
            name   => 'pve100-wts1c',
            vmtype => 'kvm',
        }
    },
);

plan tests => (scalar @tests) + 1;

foreach my $test (@tests) {
    my $values =
      GLPI::Agent::Task::Inventory::Virtualization::Qemu::_parseProcessList(
        $test);
    cmp_deeply( $values, $test->{_result} );
}
