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
'qemu-system-x86_64 -m 4G -smp 4 -cpu IvyBridge -cdrom .\VMware-VMvisor-Installer-8.0U3e-24677879.x86_64.iso -boot d -vga std -nic user -device usb-ehci -device usb-host,vendorid=0x058F,productid=0x6387 -d guest_errors,unimp,pcall -D qemu_debug.log',
        _result => {
            name   => '.\VMware-VMvisor-Installer-8.0U3e-24677879.x86_64.iso',
            mem    => 4096,
            vcpu   => 4,
            vmtype => 'qemu',
        }
    },
    {
        CMD =>
'qemu-system-x86_64 -m 4G -smp cores=2,threads=2,sockets=1 -cpu IvyBridge -cdrom .\VMware-VMvisor-Installer-8.0U3e-24677879.x86_64.iso -boot d -vga std -nic user -device usb-ehci -device usb-host,vendorid=0x058F,productid=0x6387 -d guest_errors,unimp,pcall -D qemu_debug.log',
        _result => {
            name   => '.\VMware-VMvisor-Installer-8.0U3e-24677879.x86_64.iso',
            mem    => 4096,
            vcpu   => 4,
            vmtype => 'qemu',
        }
    },
    {
        CMD =>
"usr/bin/qemu-system-x86_64 -name guest=instance-xxx,debug-threads=on -S -object secret,id=masterKey0,format=raw,file=/var/lib/libvirt/qemu/domain-3-instance-xxx/xxx -machine pc-i440fx-4.0,accel=kvm,usb=off,dump-guest-core=off -cpu EPYC-IBPB,x2apic=on,tsc-deadline=on,hypervisor=on,tsc_adjust=on,clwb=on,umip=on,spec-ctrl=on,stibp=on,arch-capabilities=on,ssbd=on,xsaves=on,cmp_legacy=on,perfctr_core=on,wbnoinvd=on,amd-ssbd=on,virt-ssbd=on,rdctl-no=on,skip-l1dfl-vmentry=on,mds-no=on,monitor=off -m 16384 -overcommit mem-lock=off -smp 4,sockets=4,cores=1,threads=1 -uuid 6df8f2f4-34dc-44da-bff8-b52fc993a7d2' -smbios type=1,manufacturer=OpenStack Foundation,product=OpenStack Nova,version=20.2.1,serial=xxx,uuid=xxx,family=Virtual Machine -no-user-config -nodefaults -chardev socket,id=charmonitor,fd=26,server,nowait -mon chardev=charmonitor,id=monitor,mode=control -rtc base=utc,driftfix=slew -global kvm-pit.lost_tick_policy=delay -no-hpet -no-shutdown -boot strict=on -device piix3-usb-uhci,id=usb,bus=pci.0,addr=0x1.0x2 -object secret,id=virtio-disk0-secret0,data=4O2/o/xxx=,keyid=masterKey0,iv=xxx==,format=base64 -drive file=rbd:volumes/volume-xxx:id=cinder:auth_supported=cephx\;none:mon_host=xxx\:6789\;xxx\:6789\;xxx\:6789,file.password-secret=virtio-disk0-secret0,format=raw,if=none,id=drive-virtio-disk0,cache=writethrough,discard=unmap -device virtio-blk-pci,scsi=off,bus=pci.0,addr=0x4,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=1,write-cache=off,serial=xxx -netdev tap,fd=27,id=hostnet0,vhost=on,vhostfd=28 -device virtio-net-pci,host_mtu=1500,netdev=hostnet0,id=net0,mac=xxx,bus=pci.0,addr=0x3 -chardev pty,id=charserial0,logfile=/var/lib/nova/instances/xxx/console.log,logappend=off -device isa-serial,chardev=charserial0,id=serial0 -device usb-tablet,id=input0,bus=usb.0,port=1 -vnc xxx:2 -device cirrus-vga,id=video0,bus=pci.0,addr=0x2 -device virtio-balloon-pci,id=balloon0,bus=pci.0,addr=0x5 -sandbox on,obsolete=deny,elevateprivileges=deny,spawn=deny,resourcecontrol=deny -msg timestamp=on",
        _result => {
            name   => 'guest=instance-xxx',
            mem    => 16384,
            vcpu   => 4,
            vmtype => 'kvm',
            uuid   => 'xxx',
            serial => 'xxx'
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
