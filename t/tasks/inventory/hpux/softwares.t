#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::HPUX::Softwares;

my %tests = (
    hpux1 => [
        {
            PUBLISHER => 'HP',
            NAME      => 'B3929EA',
            COMMENTS  => 'HP OnLineJFS (Server)',
            VERSION   => '4.1.004'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'B6848BA',
            COMMENTS  => 'Ximian GNOME 1.4 GTK+ Libraries for HP-UX',
            VERSION   => '1.4.gm.46.9'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'B6849AA',
            COMMENTS  => 'Bastille Security Hardening Tool',
            VERSION   => 'B.02.01.02'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'B8465BA',
            COMMENTS  => 'HP WBEM Services for HP-UX',
            VERSION   => 'A.02.00.08'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'B9073BA',
            COMMENTS  => 'HP-UX iCOD (Instant Capacity)',
            VERSION   => 'B.11.23.07.00.00.03'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'B9788AA',
            COMMENTS  => 'Java2 1.3 SDK for HP-UX',
            VERSION   => '1.3.1.17.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'B9789AA',
            COMMENTS  => 'Java2 1.3 RTE for HP-UX',
            VERSION   => '1.3.1.17.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'B9901AA',
            COMMENTS  => 'HP IPFilter 3.5alpha5',
            VERSION   => 'A.03.05.12'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'BUNDLE',
            COMMENTS  => 'Patch Bundle',
            VERSION   => 'B.2009.02.14'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'BUNDLE11i',
            COMMENTS  => 'Required Patch Bundle for HP-UX 11i v2 (B.11.23), September 2004',
            VERSION   => 'B.11.23.0409.3'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Base-VXFS',
            COMMENTS  => 'VERITAS File System Bundle 4.1 for HP-UX',
            VERSION   => '4.1.002'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Base-VXVM',
            COMMENTS  => 'Base VERITAS Volume Manager Bundle 4.1 for HP-UX',
            VERSION   => 'B.04.10.011'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'CDE-English',
            COMMENTS  => 'English CDE Environment',
            VERSION   => 'B.11.23.0409'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'DSAUtilities',
            COMMENTS  => 'HP-UX Distributed Systems Administration Utilities',
            VERSION   => 'B.11.23'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'EnableVxFS',
            COMMENTS  => 'File-System library, commands enhancements for VxFS4.1',
            VERSION   => 'B.11.23.03'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'FDDI-00',
            COMMENTS  => 'PCI FDDI;Supptd HW=A3739B;SW=J3626AA',
            VERSION   => 'B.11.23.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'FEATURE11i',
            COMMENTS  => 'Feature Enablement Patches for HP-UX 11i v2, March 2008',
            VERSION   => 'B.11.23.0803.070a'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'FibrChanl-00',
            COMMENTS  => 'PCI FibreChannel;Supptd HW=A6795A,A5158A',
            VERSION   => 'B.11.23.0512'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'FibrChanl-01',
            COMMENTS  => 'PCI-X FibreChannel;Supptd HW=A6826A,A9782A,A9784A,AB465A,AB378A,AB379A',
            VERSION   => 'B.11.23.04.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'FileSystems',
            COMMENTS  => 'HP-UX Disks and File Systems Tool Bundle',
            VERSION   => 'B.11.23.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'GigEther-00',
            COMMENTS  => 'PCI GigEther;Supptd HW=A4926A/A4929A/A6096A;SW=J1642AA',
            VERSION   => 'B.11.23.0512'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'GigEther-01',
            COMMENTS  => 'PCI GigEther;Supptd HW=A6825A/A6794A/A6847A/A8685A/A9782A/A9784A/A7109A/AB465A',
            VERSION   => 'B.11.23.0505'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'HPUX11i-OE-Ent',
            COMMENTS  => 'HP-UX Enterprise Operating Environment Component',
            VERSION   => 'B.11.23.0512'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'HPUXBaseAux',
            COMMENTS  => 'HP-UX Base OS Auxiliary',
            VERSION   => 'B.11.23.0512'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'HPUXBaseOS',
            COMMENTS  => 'HP-UX Base OS',
            VERSION   => 'B.11.23'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'HWEnable11i',
            COMMENTS  => 'Hardware Enablement Patches for HP-UX 11i v2, December 2007',
            VERSION   => 'B.11.23.0712.070'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'IEther-00',
            COMMENTS  => 'PCI/PCI-X IEther;Supptd HW=A7011A/A7012A/AB352A/AB290A/AB545A',
            VERSION   => 'B.11.23.0505'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'IGNITE',
            COMMENTS  => 'HP-UX Installation Utilities (Ignite-UX)',
            VERSION   => 'C.7.7.98'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'ISEEPlatform',
            COMMENTS  => 'ISEE Platform',
            VERSION   => 'A.03.95.035'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Ignite-UX-11-23',
            COMMENTS  => 'HP-UX Installation Utilities for Installing 11.23 Systems',
            VERSION   => 'C.7.7.98'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'J4269AA',
            COMMENTS  => 'LDAP-UX Integration',
            VERSION   => 'B.04.00.03'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Java15JDK',
            COMMENTS  => 'Java 1.5 JDK for HP-UX',
            VERSION   => '1.5.0.01.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Java15JDKadd',
            COMMENTS  => 'Java 1.5 JDK -AA addon for HP-UX',
            VERSION   => '1.5.0.01.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Java15JRE',
            COMMENTS  => 'Java 1.5 JRE for HP-UX',
            VERSION   => '1.5.0.01.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Java15JREadd',
            COMMENTS  => 'Java 1.5 JRE -AA addon for HP-UX',
            VERSION   => '1.5.0.01.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Judy',
            COMMENTS  => 'Judy Library and Related files',
            VERSION   => 'B.11.23.04.17'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'LVMProvider',
            COMMENTS  => 'CIM/WBEM Provider for LVM',
            VERSION   => 'R11.23.003'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'MD5Checksum',
            COMMENTS  => 'HP-UX MD5 Secure Checksum',
            VERSION   => 'A.01.01.02'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'MOZILLA',
            COMMENTS  => 'Mozilla 1.711 for HP-UX',
            VERSION   => '1.7.11.00.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'MOZILLAsrc',
            COMMENTS  => 'Mozilla 1.711 Source distribution',
            VERSION   => '1.7.11.00.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'OnlineDiag',
            COMMENTS  => 'HPUX 11.23 Support Tools Bundle, Dec 2005',
            VERSION   => 'B.11.23.05.07'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'OpenSSL',
            COMMENTS  => 'Secure Network Communications Protocol',
            VERSION   => 'A.00.09.07e.013'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'ParMgr',
            COMMENTS  => 'Partition Manager - HP-UX',
            VERSION   => 'B.23.02.01.02'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'QPKAPPS',
            COMMENTS  => 'Applications Patches for HP-UX 11i v2, June 2008',
            VERSION   => 'B.11.23.0806.072'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'QPKBASE',
            COMMENTS  => 'Base Quality Pack Bundle for HP-UX 11i v2, June 2008',
            VERSION   => 'B.11.23.0806.072'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'RAID-01',
            COMMENTS  => 'RAID SA; Supptd HW=A7143A/A9890A/A9891A',
            VERSION   => 'B.11.23.0512'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Sec00Tools',
            COMMENTS  => 'Install-Time security infrastructure.',
            VERSION   => 'B.01.02.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'SecPatchCk',
            COMMENTS  => 'HP-UX Security Patch Check Tool',
            VERSION   => 'B.02.02'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'SysMgmtWeb',
            COMMENTS  => 'HP-UX Web Based System Management User Interfaces',
            VERSION   => 'A.2.2.1.4'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'T1456AA',
            COMMENTS  => 'Java2 1.4 SDK for HP-UX',
            VERSION   => '1.4.2.09.04'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'T1456AAaddon',
            COMMENTS  => 'Java2 1.4 SDK -AA addon for HP-UX',
            VERSION   => '1.4.2.09.04'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'T1457AA',
            COMMENTS  => 'Java2 1.4 RTE for HP-UX',
            VERSION   => '1.4.2.09.04'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'T1457AAaddon',
            COMMENTS  => 'Java2 1.4 RTE -AA addon for HP-UX',
            VERSION   => '1.4.2.09.04'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'T1471AA',
            COMMENTS  => 'HP-UX Secure Shell',
            VERSION   => 'A.04.00.003'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'T2743AA',
            COMMENTS  => 'HP Global Workload Manager Agent',
            VERSION   => 'A.01.01.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'USB-00',
            COMMENTS  => 'USB Subsystem and Drivers',
            VERSION   => 'C.01.02.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'UtilProvider',
            COMMENTS  => 'HP-UX Utilization Provider',
            VERSION   => 'A.01.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'VMGuestLib',
            COMMENTS  => 'Integrity VM Guest Support Libraries',
            VERSION   => 'A.01.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'VMProvider',
            COMMENTS  => 'WBEM Provider for Integrity VM',
            VERSION   => 'A.01.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'WBEMP-LAN-00',
            COMMENTS  => 'LAN Provider for Ethernet LAN interfaces.',
            VERSION   => 'B.11.23.03'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'hpuxwsApache',
            COMMENTS  => 'HP-UX Apache-based Web Server',
            VERSION   => 'B.2.0.54.03'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'hpuxwsTomcat',
            COMMENTS  => 'HP-UX Tomcat-based Servlet Engine',
            VERSION   => 'B.5.5.9.03'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'hpuxwsWebmin',
            COMMENTS  => 'HP-UX Webmin-based Admin',
            VERSION   => 'A.1.070.05'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'hpuxwsXml',
            COMMENTS  => 'HP-UX XML Web Server Tools',
            VERSION   => 'A.2.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'ixNet-SNMP',
            COMMENTS  => 'Simple Network Monitoring protocol',
            VERSION   => 'A.13.00-5.4.2.1.004'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'nParProvider',
            COMMENTS  => 'nPartition Provider - HP-UX',
            VERSION   => 'B.23.01.05.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'perl',
            COMMENTS  => 'Perl Programming Language',
            VERSION   => 'D.5.8.3.C'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'scsiU320-00',
            COMMENTS  => 'PCI-X SCSI U320; Supptd HW=A7173A/AB290A',
            VERSION   => 'B.11.23.0512'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'vParProvider',
            COMMENTS  => 'vPar Provider - HP-UX',
            VERSION   => 'B.11.23.01.03'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'DATA-PROTECTOR',
            COMMENTS  => 'HP OpenView Storage Data Protector',
            VERSION   => 'A.06.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'bzip2',
            COMMENTS  => 'bzip2',
            VERSION   => '1.0.5'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'lsof',
            COMMENTS  => 'lsof',
            VERSION   => '4.78'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'sudo',
            COMMENTS  => 'Provide limited super-user priveleges to specific users',
            VERSION   => '1.7.4p6'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'unzip',
            COMMENTS  => 'unzip',
            VERSION   => '5.52'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'zip',
            COMMENTS  => 'zip',
            VERSION   => '2.31'
        }
    ],
    hpux2 => [
        {
            PUBLISHER => 'HP',
            NAME      => 'AccessControl',
            COMMENTS  => 'HP-UX Role-Based Access Control Infrastructure',
            VERSION   => 'B.11.23.06.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'B6848BA',
            COMMENTS  => 'Ximian GNOME 1.4 GTK+ Libraries for HP-UX',
            VERSION   => '1.4.gm.46.13'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'B9073BA',
            COMMENTS  => 'HP-UX iCOD Instant Capacity (iCAP)',
            VERSION   => 'B.11.23.08.03.00.22'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'B9901AA',
            COMMENTS  => 'HP IPFilter 3.5alpha5',
            VERSION   => 'A.11.23.15.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'BUNDLE',
            COMMENTS  => 'Patch Bundle',
            VERSION   => 'B.2010.07.07'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'BUNDLE11i',
            COMMENTS  => 'Required Patch Bundle for HP-UX 11i v2 (B.11.23), September 2004',
            VERSION   => 'B.11.23.0409.3'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Base-VXFS',
            COMMENTS  => 'VERITAS File System Bundle 4.1 for HP-UX',
            VERSION   => '4.1.002'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Base-VXVM',
            COMMENTS  => 'Base VERITAS Volume Manager Bundle 4.1 for HP-UX',
            VERSION   => 'B.04.10.011'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'CDE-English',
            COMMENTS  => 'English CDE Environment',
            VERSION   => 'B.11.23.0409'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'CommonIO',
            COMMENTS  => 'Common IO Drivers',
            VERSION   => 'B.11.23.0712'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'DNSUPGRADE',
            COMMENTS  => 'BIND UPGRADE',
            VERSION   => 'C.9.3.2.7.0'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'DSAUtilities',
            COMMENTS  => 'HP-UX Distributed Systems Administration Utilities',
            VERSION   => 'C.01.00.11'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'DynRootDisk',
            COMMENTS  => 'Dynamic Root Disk',
            VERSION   => 'A.3.0.0.1027'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'EnableVxFS',
            COMMENTS  => 'File-System library, commands enhancements for VxFS4.1 and 5.0',
            VERSION   => 'B.11.23.07'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'FDDI-00',
            COMMENTS  => 'PCI FDDI;Supptd HW=A3739B;SW=J3626AA',
            VERSION   => 'B.11.23.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'FEATURE11i',
            COMMENTS  => 'Feature Enablement Patches for HP-UX 11i v2, March 2008',
            VERSION   => 'B.11.23.0803.070a'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'FIREFOX',
            COMMENTS  => 'Firefox for HP-UX',
            VERSION   => '2.0.0.4ar.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'FIREFOXsrc',
            COMMENTS  => 'Firefox Source distribution',
            VERSION   => '2.0.0.4ar.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'FibrChanl-00',
            COMMENTS  => 'PCI FibreChannel;Supptd HW=A6795A,A5158A',
            VERSION   => 'B.11.23.0712'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'FibrChanl-01',
            COMMENTS  => 'FibrChnl;SupptdHW=A6826A,A9782A,A9784A,AB378A,AB379A,AB465A,AD193A,AD194A,AD300A',
            VERSION   => 'B.11.23.08.02'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'FibrChanl-02',
            COMMENTS  => 'PCIe FibreChannel;Supptd HW=AD299A,AD355A',
            VERSION   => 'B.11.23.0712'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'GTK',
            COMMENTS  => 'GTK+ 2.6 The Gnome GUI Runtime  Toolkit',
            VERSION   => '2.6.8.00.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'GTKsrc',
            COMMENTS  => 'Gtk Source distribution',
            VERSION   => '2.6.8.00.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'GigEther-00',
            COMMENTS  => 'PCI GigEther;Supptd HW=A4926A/A4929A/A6096A;SW=J1642AA',
            VERSION   => 'B.11.23.0512'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'GigEther-01',
            COMMENTS  => 'PCI GigEther;Supptd HW=A6825A/A6794A/A6847A/A8685A/A9782A/A9784A/A7109A/AB465A',
            VERSION   => 'B.11.23.0712'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'GuestAVIOStor',
            COMMENTS  => 'HPVM Guest AVIO Storage Software',
            VERSION   => 'B.11.23.0712'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'GuestAvioLan',
            COMMENTS  => 'HPVM Guest AVIO LAN Software',
            VERSION   => 'B.11.23.0712'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'HPUX11i-OE-Ent',
            COMMENTS  => 'HP-UX Enterprise Operating Environment Component',
            VERSION   => 'B.11.23.0712'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'HPUXBaseAux',
            COMMENTS  => 'HP-UX Base OS Auxiliary',
            VERSION   => 'B.11.23.0712'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'HPUXBaseOS',
            COMMENTS  => 'HP-UX Base OS',
            VERSION   => 'B.11.23'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'HPUXBastille',
            COMMENTS  => 'Bastille Security Hardening Tool',
            VERSION   => 'B.3.0.29'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'HWEnable11i',
            COMMENTS  => 'Hardware Enablement Patches for HP-UX 11i v2, December 2007',
            VERSION   => 'B.11.23.0712.070'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'HostAVIOStor',
            COMMENTS  => 'HPVM Host AVIO Storage Software',
            VERSION   => 'B.11.23.0712'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'HostAvioLan',
            COMMENTS  => 'HPVM Host AVIO LAN Software',
            VERSION   => 'B.11.23.0712.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'IEther-00',
            COMMENTS  => 'PCI/PCI-X/PCIe IEther',
            VERSION   => 'B.11.23.0712'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'ISEEPlatform',
            COMMENTS  => 'ISEE Platform',
            VERSION   => 'A.03.95.510.46.03'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'IUX-Recovery',
            COMMENTS  => 'Ignite-UX network recovery tool subset',
            VERSION   => 'C.7.7.98'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'J4240AA',
            COMMENTS  => 'Auto-Port Aggregation Software',
            VERSION   => 'B.11.23.20'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Java15JDK',
            COMMENTS  => 'Java 1.5 JDK for HP-UX',
            VERSION   => '1.5.0.09.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Java15JDKadd',
            COMMENTS  => 'Java 1.5 JDK -AA addon for HP-UX',
            VERSION   => '1.5.0.09.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Java15JRE',
            COMMENTS  => 'Java 1.5 JRE for HP-UX',
            VERSION   => '1.5.0.09.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Java15JREadd',
            COMMENTS  => 'Java 1.5 JRE -AA addon for HP-UX',
            VERSION   => '1.5.0.09.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Judy',
            COMMENTS  => 'Judy Library and Related files',
            VERSION   => 'B.11.23.04.17'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'LVMProvider',
            COMMENTS  => 'CIM/WBEM Provider for LVM',
            VERSION   => 'R11.23.009'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'LibcEnhancement',
            COMMENTS  => 'Library for Libc enhancements',
            VERSION   => 'B.11.23.0.1'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'LoginLang',
            COMMENTS  => 'HP-UX 11.23 login(1) support for local languages',
            VERSION   => 'B.11.23.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'MD5Checksum',
            COMMENTS  => 'HP-UX MD5 Secure Checksum',
            VERSION   => 'A.01.01.02'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'MOZILLA',
            COMMENTS  => 'Mozilla for HP-UX',
            VERSION   => '1.7.13.01.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'MOZILLAsrc',
            COMMENTS  => 'Mozilla Source distribution',
            VERSION   => '1.7.13.01.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'NodeHostNameXpnd',
            COMMENTS  => 'Nodename, Hostname expansion enhancement',
            VERSION   => 'B.11.23.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'OnlineDiag',
            COMMENTS  => 'HPUX 11.23 Support Tools Bundle, December 2007',
            VERSION   => 'B.11.23.10.05'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'ParMgr',
            COMMENTS  => 'Partition Manager - HP-UX',
            VERSION   => 'B.23.02.01.03'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'PortPkg',
            COMMENTS  => 'HP-UX 11.23 PortPkg',
            VERSION   => 'B.11.23.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'ProviderDefault',
            COMMENTS  => 'Select WBEM Providers',
            VERSION   => 'B.11.23.0712'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'QPKAPPS',
            COMMENTS  => 'Applications Patches for HP-UX 11i v2, June 2010',
            VERSION   => 'B.11.23.1006.084a'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'QPKBASE',
            COMMENTS  => 'Base Quality Pack Bundle for HP-UX 11i v2, June 2010',
            VERSION   => 'B.11.23.1006.084a'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'RAID-01',
            COMMENTS  => 'RAID SA; Supptd HW=A7143A/A9890A/A9891A',
            VERSION   => 'B.11.23.0806'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'Sec00Tools',
            COMMENTS  => 'Install-Time security infrastructure.',
            VERSION   => 'B.01.04.10'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'SecurityExt',
            COMMENTS  => 'HP-UX Security Containment Extensions',
            VERSION   => 'B.11.23.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'SerialSCSI-00',
            COMMENTS  => 'PCI-X/PCI-E SerialSCSI',
            VERSION   => 'B.11.23.0806'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'StdModSecExt',
            COMMENTS  => 'HP-UX 11.23 Standard Mode Security Extensions',
            VERSION   => 'B.11.23.02'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'SwAssistant',
            COMMENTS  => 'HP-UX Software Assistant',
            VERSION   => 'C.01.02'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'SysFaultMgmt',
            COMMENTS  => 'HPUX System Fault Management',
            VERSION   => 'B.05.00.05.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'SysMgmtWeb',
            COMMENTS  => 'HP-UX Web Based System Management User Interfaces',
            VERSION   => 'A.2.2.7'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'T1456AA',
            COMMENTS  => 'Java2 1.4 SDK for HP-UX',
            VERSION   => '1.4.2.15.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'T1456AAaddon',
            COMMENTS  => 'Java2 1.4 SDK -AA addon for HP-UX',
            VERSION   => '1.4.2.15.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'T1457AA',
            COMMENTS  => 'Java2 1.4 RTE for HP-UX',
            VERSION   => '1.4.2.15.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'T1457AAaddon',
            COMMENTS  => 'Java2 1.4 RTE -AA addon for HP-UX',
            VERSION   => '1.4.2.15.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'T1471AA',
            COMMENTS  => 'HP-UX Secure Shell',
            VERSION   => 'A.04.50.021'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'TBIRD',
            COMMENTS  => 'Thunderbird for HP-UX',
            VERSION   => '2.0.0.6.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'TBIRDsrc',
            COMMENTS  => 'Thunderbird Source distribution',
            VERSION   => '2.0.0.6.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'USB-00',
            COMMENTS  => 'USB Subsystem and Drivers',
            VERSION   => 'C.01.04.07'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'VMGuestLib',
            COMMENTS  => 'Integrity VM Guest Support Libraries',
            VERSION   => 'A.03.50'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'hpuxwsApache',
            COMMENTS  => 'HP-UX Apache-based Web Server',
            VERSION   => 'B.2.0.59.01'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'hpuxwsTomcat',
            COMMENTS  => 'HP-UX Tomcat-based Servlet Engine',
            VERSION   => 'B.5.5.23.00'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'hpuxwsWebmin',
            COMMENTS  => 'HP-UX Webmin-based Admin',
            VERSION   => 'A.1.070.10'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'hpuxwsXml',
            COMMENTS  => 'HP-UX XML Web Server Tools',
            VERSION   => 'A.2.03'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'ixNet-SNMP',
            COMMENTS  => 'Simple Network Monitoring protocol',
            VERSION   => 'A.13.00-5.4.2.1.004'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'ixRsync',
            COMMENTS  => 'File Transfer Program',
            VERSION   => 'A.15.00-3.0.5.001'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'perl',
            COMMENTS  => '5.8.8 Perl Programming Language',
            VERSION   => 'D.5.8.8.B'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'scsiU320-00',
            COMMENTS  => 'PCI-X SCSI U320; Supptd HW=A7173A/AB290A',
            VERSION   => 'B.11.23.0712'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'bash',
            COMMENTS  => 'bash',
            VERSION   => '4.0.033'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'bzip2',
            COMMENTS  => 'bzip2',
            VERSION   => '1.0.5'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'gcc',
            COMMENTS  => 'gcc',
            VERSION   => '4.2.3'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'gettext',
            COMMENTS  => 'gettext',
            VERSION   => '0.17'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'libiconv',
            COMMENTS  => 'libiconv',
            VERSION   => '1.13.1'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'lsof',
            COMMENTS  => 'lsof',
            VERSION   => '4.78'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'sudo',
            COMMENTS  => 'Provide limited super-user priveleges to specific users',
            VERSION   => '1.7.4p6'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'termcap',
            COMMENTS  => 'termcap',
            VERSION   => '1.3.1'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'unzip',
            COMMENTS  => 'unzip',
            VERSION   => '5.52'
        },
        {
            PUBLISHER => 'HP',
            NAME      => 'zip',
            COMMENTS  => 'zip',
            VERSION   => '3.0'
        }
    ],
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/hpux/swlist/$test";
    my $softwares = GLPI::Agent::Task::Inventory::HPUX::Softwares::_getSoftwaresList(file => $file);
    cmp_deeply($softwares, $tests{$test}, "software: $test");
    lives_ok {
        $inventory->addEntry(section => 'SOFTWARES', entry => $_)
            foreach @$softwares;
    } "$test: registering";
}
