#!/usr/bin/perl

use strict;
use warnings;

use utf8;
use LWP::UserAgent;
use English qw(-no_match_vars);
use HTTP::Response;
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::MockObject::Extends;
use Test::MockModule;

use GLPI::Agent::Inventory;
use GLPI::Agent::XML;
use GLPI::Agent::SOAP::VMware;
use GLPI::Agent::Tools::Virtualization;

my %tests = (
    'esx-4.1.0-1' => {
        'connect' => [
          {
            'lastActiveTime' => '1970-01-25T03:53:04.326969+01:00',
            'loginTime' => '1970-01-25T03:53:04.326969+01:00',
            'fullName' => 'root',
            'messageLocale' => 'en',
            'locale' => 'en',
            'userName' => 'root',
            'key' => '52eec005-5d13-dfae-afd8-7e1b4561a154'
          }
        ],
        'getHostname' => [ 'esx-test.teclib.local' ],
        'getBiosInfo' => [
            {
              'SMANUFACTURER' => 'Sun Microsystems',
              'SMODEL' => 'Sun Fire X2200 M2 with Dual Core Processor',
              'BDATE' => '2009-02-04T00:00:00Z',
              'ASSETTAG' => ' To Be Filled By O.E.M.',
              'BVERSION' => 'S39_3B27'
            }
        ],
        'getHardwareInfo' => [
            {
          'NAME' => 'esx-test',
          'WORKGROUP' => 'teclib.local',
          'MEMORY' => 8190,
          'UUID' => 'b5bfd78a-fa79-0010-adfe-001b24f07258',
          'DNS' => '10.0.5.105'
          }
        ],
        'getOperatingSystemInfo' => [
            {
                NAME       => "VMware ESX",
                VERSION    => "4.1.0",
                FULL_NAME  => "VMware ESX 4.1.0 build-260247",
                FQDN       => "esx-test.teclib.local",
                DNS_DOMAIN => "teclib.local",
                BOOT_TIME  => "2011-01-25 14:11:07",
                TIMEZONE   => {
                    NAME   => "Europe/Berlin",
                    OFFSET => "+0100",
                },
            }
        ],
        'getCPUs' => [
          {
            'NAME' => 'Dual-Core AMD Opteron(tm) Processor 2218',
            'MANUFACTURER' => 'AMD',
            'SPEED' => 2613,
            'THREAD' => '1',
            'CORE' => 2
          },
          {
            'NAME' => 'Dual-Core AMD Opteron(tm) Processor 2218',
            'MANUFACTURER' => 'AMD',
            'SPEED' => 2613,
            'THREAD' => '1',
            'CORE' => 2
          }
        ],
        'getControllers' => [
          {
            'PCISUBSYSTEMID' => '108e:534b',
            'PCICLASS' => '0500',
            'NAME' => 'MCP55 Memory Controller',
            'MANUFACTURER' => 'nVidia Corporation',
            'VENDORID' => '10de',
            'PRODUCTID' => '0369',
            'PCISLOT' => '00:00.0'
          },
          {
            'PCISUBSYSTEMID' => '108e:534b',
            'PCICLASS' => '0601',
            'NAME' => 'MCP55 LPC Bridge',
            'MANUFACTURER' => 'nVidia Corporation',
            'VENDORID' => '10de',
            'PRODUCTID' => '0364',
            'PCISLOT' => '00:01.0'
          },
          {
            'PCISUBSYSTEMID' => '108e:534b',
            'PCICLASS' => '0c05',
            'NAME' => 'MCP55 SMBus',
            'MANUFACTURER' => 'nVidia Corporation',
            'VENDORID' => '10de',
            'PRODUCTID' => '0368',
            'PCISLOT' => '00:01.1'
          },
          {
            'PCISUBSYSTEMID' => '108e:534b',
            'PCICLASS' => '0c03',
            'NAME' => 'MCP55 USB Controller',
            'MANUFACTURER' => 'nVidia Corporation',
            'VENDORID' => '10de',
            'PRODUCTID' => '036c',
            'PCISLOT' => '00:02.0'
          },
          {
            'PCISUBSYSTEMID' => '108e:534b',
            'PCICLASS' => '0c03',
            'NAME' => 'MCP55 USB Controller',
            'MANUFACTURER' => 'nVidia Corporation',
            'VENDORID' => '10de',
            'PRODUCTID' => '036d',
            'PCISLOT' => '00:02.1'
          },
          {
            'PCISUBSYSTEMID' => '108e:534b',
            'PCICLASS' => '0101',
            'NAME' => 'NVidia NForce MCP55 IDE/PATA Controller',
            'MANUFACTURER' => 'nVidia Corporation',
            'VENDORID' => '10de',
            'PRODUCTID' => '036e',
            'PCISLOT' => '00:04.0'
          },
          {
            'PCISUBSYSTEMID' => '108e:534b',
            'PCICLASS' => '0101',
            'NAME' => 'MCP55 SATA Controller',
            'MANUFACTURER' => 'nVidia Corporation',
            'VENDORID' => '10de',
            'PRODUCTID' => '037f',
            'PCISLOT' => '00:05.0'
          },
          {
            'PCICLASS' => '0604',
            'NAME' => 'MCP55 PCI bridge',
            'MANUFACTURER' => 'nVidia Corporation',
            'VENDORID' => '10de',
            'PRODUCTID' => '0370',
            'PCISLOT' => '00:06.0'
          },
          {
            'PCISUBSYSTEMID' => '108e:534b',
            'PCICLASS' => '0680',
            'NAME' => 'nVidia NForce Network Controller',
            'MANUFACTURER' => 'nVidia Corporation',
            'VENDORID' => '10de',
            'PRODUCTID' => '0373',
            'PCISLOT' => '00:08.0'
          },
          {
            'PCISUBSYSTEMID' => '108e:534b',
            'PCICLASS' => '0680',
            'NAME' => 'nVidia NForce Network Controller',
            'MANUFACTURER' => 'nVidia Corporation',
            'VENDORID' => '10de',
            'PRODUCTID' => '0373',
            'PCISLOT' => '00:09.0'
          },
          {
            'PCICLASS' => '0604',
            'NAME' => 'MCP55 PCI Express bridge',
            'MANUFACTURER' => 'nVidia Corporation',
            'VENDORID' => '10de',
            'PRODUCTID' => '0376',
            'PCISLOT' => '00:0a.0'
          },
          {
            'PCICLASS' => '0604',
            'NAME' => 'MCP55 PCI Express bridge',
            'MANUFACTURER' => 'nVidia Corporation',
            'VENDORID' => '10de',
            'PRODUCTID' => '0374',
            'PCISLOT' => '00:0b.0'
          },
          {
            'PCICLASS' => '0604',
            'NAME' => 'MCP55 PCI Express bridge',
            'MANUFACTURER' => 'nVidia Corporation',
            'VENDORID' => '10de',
            'PRODUCTID' => '0374',
            'PCISLOT' => '00:0c.0'
          },
          {
            'PCICLASS' => '0604',
            'NAME' => 'MCP55 PCI Express bridge',
            'MANUFACTURER' => 'nVidia Corporation',
            'VENDORID' => '10de',
            'PRODUCTID' => '0378',
            'PCISLOT' => '00:0d.0'
          },
          {
            'PCICLASS' => '0604',
            'NAME' => 'MCP55 PCI Express bridge',
            'MANUFACTURER' => 'nVidia Corporation',
            'VENDORID' => '10de',
            'PRODUCTID' => '0377',
            'PCISLOT' => '00:0f.0'
          },
          {
            'PCICLASS' => '0600',
            'NAME' => 'K8 [Athlon64/Opteron] HyperTransport Technology Configuration',
            'MANUFACTURER' => 'Advanced Micro Devices [AMD]',
            'VENDORID' => '1022',
            'PRODUCTID' => '1100',
            'PCISLOT' => '00:18.0'
          },
          {
            'PCICLASS' => '0600',
            'NAME' => 'K8 [Athlon64/Opteron] Address Map',
            'MANUFACTURER' => 'Advanced Micro Devices [AMD]',
            'VENDORID' => '1022',
            'PRODUCTID' => '1101',
            'PCISLOT' => '00:18.1'
          },
          {
            'PCICLASS' => '0600',
            'NAME' => 'K8 [Athlon64/Opteron] DRAM Controller',
            'MANUFACTURER' => 'Advanced Micro Devices [AMD]',
            'VENDORID' => '1022',
            'PRODUCTID' => '1102',
            'PCISLOT' => '00:18.2'
          },
          {
            'PCICLASS' => '0600',
            'NAME' => 'K8 [Athlon64/Opteron] Miscellaneous Control',
            'MANUFACTURER' => 'Advanced Micro Devices [AMD]',
            'VENDORID' => '1022',
            'PRODUCTID' => '1103',
            'PCISLOT' => '00:18.3'
          },
          {
            'PCICLASS' => '0600',
            'NAME' => 'K8 [Athlon64/Opteron] HyperTransport Technology Configuration',
            'MANUFACTURER' => 'Advanced Micro Devices [AMD]',
            'VENDORID' => '1022',
            'PRODUCTID' => '1100',
            'PCISLOT' => '00:19.0'
          },
          {
            'PCICLASS' => '0600',
            'NAME' => 'K8 [Athlon64/Opteron] Address Map',
            'MANUFACTURER' => 'Advanced Micro Devices [AMD]',
            'VENDORID' => '1022',
            'PRODUCTID' => '1101',
            'PCISLOT' => '00:19.1'
          },
          {
            'PCICLASS' => '0600',
            'NAME' => 'K8 [Athlon64/Opteron] DRAM Controller',
            'MANUFACTURER' => 'Advanced Micro Devices [AMD]',
            'VENDORID' => '1022',
            'PRODUCTID' => '1102',
            'PCISLOT' => '00:19.2'
          },
          {
            'PCICLASS' => '0600',
            'NAME' => 'K8 [Athlon64/Opteron] Miscellaneous Control',
            'MANUFACTURER' => 'Advanced Micro Devices [AMD]',
            'VENDORID' => '1022',
            'PRODUCTID' => '1103',
            'PCISLOT' => '00:19.3'
          },
          {
            'PCISUBSYSTEMID' => '108e:534b',
            'PCICLASS' => '0300',
            'NAME' => 'ASPEED Graphics Family',
            'MANUFACTURER' => 'ASPEED Technology, Inc.',
            'VENDORID' => '1a03',
            'PRODUCTID' => '2000',
            'PCISLOT' => '01:05.0'
          },
          {
            'PCICLASS' => '0604',
            'NAME' => 'EPB PCI-Express to PCI-X Bridge',
            'MANUFACTURER' => 'Broadcom',
            'VENDORID' => '1166',
            'PRODUCTID' => '0103',
            'PCISLOT' => '05:00.0'
          },
          {
            'PCISUBSYSTEMID' => '108e:534b',
            'PCICLASS' => '0200',
            'NAME' => 'Broadcom BCM5715 Gigabit Ethernet',
            'MANUFACTURER' => 'Broadcom Corporation',
            'VENDORID' => '14e4',
            'PRODUCTID' => '1678',
            'PCISLOT' => '06:04.0'
          },
          {
            'PCISUBSYSTEMID' => '108e:534b',
            'PCICLASS' => '0200',
            'NAME' => 'Broadcom BCM5715 Gigabit Ethernet',
            'MANUFACTURER' => 'Broadcom Corporation',
            'VENDORID' => '14e4',
            'PRODUCTID' => '1678',
            'PCISLOT' => '06:04.1'
          }
        ],
        'getNetworks' => [
          {
            'IPMASK' => '255.255.0.0',
            'VIRTUALDEV' => 1,
            'STATUS' => 'Up',
            'MACADDR' => '00:50:56:75:f7:2e',
            'SPEED' => undef,
            'PCISLOT' => undef,
            'DRIVER' => undef,
            'MTU' => '1500',
            'DESCRIPTION' => 'vmk0',
            'IPADDRESS' => '10.0.2.189'
          },
          {
            'VIRTUALDEV' => 0,
            'STATUS' => 'Down',
            'MACADDR' => '00:1b:24:f0:6a:45',
            'SPEED' => '0',
            'PCISLOT' => '00:08.0',
            'DRIVER' => 'forcedeth',
            'MTU' => undef,
            'DESCRIPTION' => 'vmnic0',
          },
          {
            'VIRTUALDEV' => 0,
            'STATUS' => 'Down',
            'MACADDR' => '00:1b:24:f0:6a:46',
            'SPEED' => '0',
            'PCISLOT' => '00:09.0',
            'DRIVER' => 'forcedeth',
            'MTU' => undef,
            'DESCRIPTION' => 'vmnic1',
          },
          {
            'VIRTUALDEV' => 0,
            'STATUS' => 'Down',
            'MACADDR' => '00:1b:24:f0:6a:43',
            'SPEED' => '100',
            'PCISLOT' => '06:04.0',
            'DRIVER' => 'tg3',
            'MTU' => undef,
            'DESCRIPTION' => 'vmnic2',
          },
          {
            'VIRTUALDEV' => 0,
            'STATUS' => 'Down',
            'MACADDR' => '00:1b:24:f0:6a:44',
            'SPEED' => '0',
            'PCISLOT' => '06:04.1',
            'DRIVER' => 'tg3',
            'MTU' => undef,
            'DESCRIPTION' => 'vmnic3',
          },
          {
            'IPMASK' => '255.255.0.0',
            'VIRTUALDEV' => 0,
            'STATUS' => 'Up',
            'MACADDR' => '00:50:56:4e:eb:6f',
            'SPEED' => undef,
            'PCISLOT' => undef,
            'DRIVER' => undef,
            'MTU' => undef,
            'DESCRIPTION' => 'vswif0',
            'IPADDRESS' => '10.0.2.190'
          }
        ],
        'getStorages' => [
          {
            'NAME' => '/vmfs/devices/cdrom/mpx.vmhba0:C0:T0:L0',
            'FIRMWARE' => '1.AC',
            'TYPE' => 'cdrom',
            'DISKSIZE' => undef,
            'SERIAL' => undef,
            'DESCRIPTION' => 'Local TEAC CD-ROM (mpx.vmhba0:C0:T0:L0)',
            'MANUFACTURER' => 'TEAC',
            'MODEL' => 'DV-28E-V'
          },
          {
            'NAME' => '/vmfs/devices/disks/t10.ATA_____ST3250310NS_________________________________________9SF1F0TH',
            'FIRMWARE' => 'SN06',
            'TYPE' => 'disk',
            'DISKSIZE' => '238475',
            'SERIAL' => '3232323232323232323232325783704970488472',
            'DESCRIPTION' => 'Local ATA Disk (t10.ATA_____ST3250310NS_________________________________________9SF1F0TH)',
            'MANUFACTURER' => 'Seagate',
            'MODEL' => 'ST3250310NS'
          }

        ],
        'getDrives' => [
          {
            'VOLUMN' => undef,
            'LABEL' => 'datastore1',
            'TOTAL' => 248571,
            'SERIAL' => '4d3ea5ac-45d89fb1-847e-001b24f06a45',
            'TYPE' => '/vmfs/volumes/4d3ea5ac-45d89fb1-847e-001b24f06a45',
            'FILESYSTEM' => 'vmfs'
          },
          {
            'VOLUMN' => 'stockage1.teclib.local:/mnt/datastore/VmwareISO',
            'LABEL' => 'ISO-datastore',
            'TOTAL' => 53687,
            'SERIAL' => undef,
            'TYPE' => '/vmfs/volumes/6954b300-01710358',
            'FILESYSTEM' => 'nfs'
          }
        ],
       'getVirtualMachines' => [
          {
            'NAME' => 'ubuntu',
            'STATUS' => STATUS_RUNNING,
            'COMMENT' => '',
            'MAC' => '00:0c:29:06:42:d8',
            'VMTYPE' => 'VMware',
            'MEMORY' => '512',
            'UUID' => '564d9904-a176-a762-1b95-f75ddd0642d8',
            'SERIAL' => "VMware-56 4d 99 04 a1 76 a7 62-1b 95 f7 5d dd 06 42 d8",
            'VCPU' => '1'
          },
          {
            'NAME' => 'windows',
            'STATUS' => STATUS_RUNNING,
            'COMMENT' => '',
            'MAC' => '00:0c:29:58:44:c8',
            'VMTYPE' => 'VMware',
            'MEMORY' => '256',
            'UUID' => '564d0750-3ae1-d18d-1613-eb489b5844c8',
            'SERIAL' => "VMware-56 4d 07 50 3a e1 d1 8d-16 13 eb 48 9b 58 44 c8",
            'VCPU' => '1'
          },
          {
            'NAME' => 'solaris',
            'STATUS' => STATUS_RUNNING,
            'COMMENT' => '',
            'MAC' => '00:0c:29:5f:64:60',
            'VMTYPE' => 'VMware',
            'MEMORY' => '4096',
            'UUID' => '564df277-de0f-b401-0060-7d6a675f6460',
            'SERIAL' => "VMware-56 4d f2 77 de 0f b4 01-00 60 7d 6a 67 5f 64 60",
            'VCPU' => '2'
          },
          {
            'NAME' => 'Nouvelle machine virtuelle',
            'STATUS' => STATUS_OFF,
            'COMMENT' => '',
            'MAC' => '',
            'VMTYPE' => 'VMware',
            'MEMORY' => '512',
            'UUID' => '564d79a4-7ea6-3423-2980-0c882a78f698',
            'SERIAL' => "VMware-56 4d 79 a4 7e a6 34 23-29 80 0c 88 2a 78 f6 98",
            'VCPU' => '1'
          },
          {
            'NAME' => '阿帕奇网络服务器',
            'STATUS' => STATUS_RUNNING,
            'COMMENT' => '',
            'MAC' => '00:0c:29:06:42:ef',
            'VMTYPE' => 'VMware',
            'MEMORY' => '512',
            'UUID' => 'dc3cb882-0374-4379-875c-d5f6282cc8b9',
            'SERIAL' => "VMware-dc 3c b8 82 03 74 43 79-87 5c d5 f6 28 2c c8 b9",
            'VCPU' => '1'
          }
        ]
    },
);
my @methods = qw/
    getHostname
    getBiosInfo
    getHardwareInfo
    getOperatingSystemInfo
    getCPUs
    getControllers
    getNetworks
    getStorages
    getDrives
    getVirtualMachines
/;
plan tests =>
    (scalar keys %tests) * (scalar @methods + 3);

my $module = Test::MockModule->new('LWP::UserAgent');

foreach my $test (keys %tests) {
    my $dir = "resources/esx/$test";

    # create mock user agent
    my $ua   = LWP::UserAgent->new();
    my $mock = Test::MockObject::Extends->new($ua);
    $mock->mock(
        'request',
        sub {
            my ($self, $request) = @_;

            # compute SOAP dump file name
            my ($action) =
                $request->header('soapaction') =~ /"urn:vim25#(\S+)"/;

            my $tree = GLPI::Agent::XML->new(string => $request->content())->dump_as_hash();
            my $body = $tree->{'soapenv:Envelope'}->{'soapenv:Body'};
            my $obj  = $body->{RetrieveProperties}->{specSet}->{objectSet}->{obj};
            if ($obj->{'-type'} && $obj->{'-type'} eq 'VirtualMachine') {
                $action .= "-VM-$obj->{'#text'}";
            }
            my $file = $dir . "/" . $action . ".soap";

            local $INPUT_RECORD_SEPARATOR; # Set input to "slurp" mode.
            open(my $handle, '<', $file) or die "failed to open $file";
            my $content = <$handle>;
            close $handle;

            return HTTP::Response->new(
                200, 'OK', undef, $content
            );
        }
    );

    # ensure a call to LWP::UserAgent->new() return our mock agent
    $module->mock(new => sub { return $mock; });

    my $vpbs = GLPI::Agent::SOAP::VMware->new(
        user => 'foo',
    );

    my $result;
    lives_ok {
        $result = $vpbs->connect('foo', 'bar')
    } "$test connect()";

    cmp_deeply($result, $tests{$test}->{connect}, 'connect()');

    lives_ok {
        $result = $vpbs->getHostFullInfo()
    } "$test getHostFullInfo()";

    foreach my $method (@methods) {
        cmp_deeply(
            [ $result->$method() ],
            $tests{$test}->{$method},
            "$test $method()"
        );
    }
}
