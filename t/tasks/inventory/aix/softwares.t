#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::AIX::Softwares;

my %tests = (
    'aix-4.3.1' => [
        {
            NAME     => 'X11.apps.pm',
            COMMENTS => 'AIXwindows Power Management GUI Utility',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.apps.pm',
            COMMENTS => 'AIXwindows Power Mgmt GUI Msgs - French',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.acct',
            COMMENTS => 'Accounting Services',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.lib',
            COMMENTS => 'Base Application Development Libraries',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.com',
            COMMENTS => 'Common Hardware Diagnostics',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.rte',
            COMMENTS => 'Hardware Diagnostics',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.util',
            COMMENTS => 'Hardware Diagnostics Utilities',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.fr_FR.com',
            COMMENTS => 'WebSM/SMIT Context Helps - French',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.html.en_US.topnav.navigate',
            COMMENTS => 'Top Level Navigation - U. S. English',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.com',
            COMMENTS => 'Common Language to Language Converters',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.fr_FR',
            COMMENTS => 'EBCDIC & ASCII Language Converters - French',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.ucs.com',
            COMMENTS => 'Unicode Base Converters for AIX Code Sets/Fonts',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.iso.fr_FR',
            COMMENTS => 'Base System Locale ISO Code Set - French',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mp',
            COMMENTS => 'Base Operating System Multiprocessor Runtime',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.diag.rte',
            COMMENTS => 'Hardware Diagnostics Messages - French',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.mp',
            COMMENTS => 'Base Operating System MP Messages - French',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.net.tcp.client',
            COMMENTS => 'TCP/IP Messages - French',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.rte',
            COMMENTS => 'Base Operating System Runtime Msgs - French',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ncs',
            COMMENTS => 'Network Computing System 1.5.1',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.client',
            COMMENTS => 'Network File System Client',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.client',
            COMMENTS => 'TCP/IP Client Support',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.smit',
            COMMENTS => 'TCP/IP SMIT Support',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.powermgt.rte',
            COMMENTS => 'Power Management Runtime Software',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte',
            COMMENTS => 'Base Operating System Runtime',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.Dt',
            COMMENTS => 'Desktop Integrator',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.ILS',
            COMMENTS => 'International Language Support',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.SRC',
            COMMENTS => 'System Resource Controller',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.X11',
            COMMENTS => 'AIXwindows Device Support',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.aio',
            COMMENTS => 'Asynchronous I/O Extension',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.archive',
            COMMENTS => 'Archive Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.bind_cmds',
            COMMENTS => 'Binder and Loader Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.boot',
            COMMENTS => 'Boot Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.bosinst',
            COMMENTS => 'Base OS Install Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.commands',
            COMMENTS => 'Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.compare',
            COMMENTS => 'File Compare Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.console',
            COMMENTS => 'Console',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.control',
            COMMENTS => 'System Control Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.cron',
            COMMENTS => 'Batch Operations',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.date',
            COMMENTS => 'Date Control Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.devices',
            COMMENTS => 'Base Device Drivers',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.devices_msg',
            COMMENTS => 'Device Driver Messages',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.diag',
            COMMENTS => 'Diagnostics',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.edit',
            COMMENTS => 'Editors',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.filesystem',
            COMMENTS => 'Filesystem Administration',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.iconv',
            COMMENTS => 'Language Converters',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.ifor_ls',
            COMMENTS => 'iFOR/LS Libraries',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.im',
            COMMENTS => 'Input Methods',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.install',
            COMMENTS => 'LPP Install Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.jfscomp',
            COMMENTS => 'JFS Compression',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libc',
            COMMENTS => 'libc Library',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libcfg',
            COMMENTS => 'libcfg Library',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libcur',
            COMMENTS => 'libcurses Library',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libdbm',
            COMMENTS => 'libdbm Library',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libnetsvc',
            COMMENTS => 'Network Services Libraries',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libpthreads',
            COMMENTS => 'pthreads Library',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libqb',
            COMMENTS => 'libqb Library',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libs',
            COMMENTS => 'libs Library',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.loc',
            COMMENTS => 'Base Locale Support',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.lvm',
            COMMENTS => 'Logical Volume Manager',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.man',
            COMMENTS => 'Man Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.methods',
            COMMENTS => 'Device Config Methods',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.misc_cmds',
            COMMENTS => 'Miscellaneous Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.net',
            COMMENTS => 'Network',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.odm',
            COMMENTS => 'Object Data Manager',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.printers',
            COMMENTS => 'Front End Printer Support',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.security',
            COMMENTS => 'Base Security Function',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.serv_aid',
            COMMENTS => 'Error Log Service Aids',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.shell',
            COMMENTS => 'Shells (bsh, ksh, csh)',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.streams',
            COMMENTS => 'Streams Libraries',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.tty',
            COMMENTS => 'Base TTY Support and Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.loginlic',
            COMMENTS => 'License Management',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.serv_aid',
            COMMENTS => 'Software Error Logging and Dump Service Aids',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.smit',
            COMMENTS => 'System Management Interface Tool (SMIT)',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.sysbr',
            COMMENTS => 'System Backup and BOS Install Utilities',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.rte',
            COMMENTS => 'Run-time Environment for AIX Terminals',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.client.base',
            COMMENTS => 'SystemView License Use Management Client Runtime',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.msg.fr_FR.base.cli',
            COMMENTS => 'LUM Runtime Code Messages - French',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hpJetDirect.attach',
            COMMENTS => 'Hewlett-Packard JetDirect Network Printer Attachment',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.msg.fr_FR.rte',
            COMMENTS => 'Printer Backend Messages - French',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.rte',
            COMMENTS => 'Printer Backend',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.rte',
            COMMENTS => 'C Set ++ for AIX Application Runtime',
            VERSION  => '3.6.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.acct',
            COMMENTS => 'Accounting Services',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.com',
            COMMENTS => 'Common Hardware Diagnostics',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.rte',
            COMMENTS => 'Hardware Diagnostics',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.util',
            COMMENTS => 'Hardware Diagnostics Utilities',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.html.en_US.topnav.navigate',
            COMMENTS => 'Top Level Navigation - U. S. English',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.mp',
            COMMENTS => 'Base Operating System Multiprocessor Runtime',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ncs',
            COMMENTS => 'Network Computing System 1.5.1',
            VERSION  => '4.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.client',
            COMMENTS => 'Network File System Client',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.client',
            COMMENTS => 'TCP/IP Client Support',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.powermgt.rte',
            COMMENTS => 'Power Management Runtime Software',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte',
            COMMENTS => 'Base Operating System Runtime',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.Dt',
            COMMENTS => 'Desktop Integrator',
            VERSION  => '4.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.SRC',
            COMMENTS => 'System Resource Controller',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.aio',
            COMMENTS => 'Asynchronous I/O Extension',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.boot',
            COMMENTS => 'Boot Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.commands',
            COMMENTS => 'Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.control',
            COMMENTS => 'System Control Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.cron',
            COMMENTS => 'Batch Operations',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.devices',
            COMMENTS => 'Base Device Drivers',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.diag',
            COMMENTS => 'Diagnostics',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.filesystem',
            COMMENTS => 'Filesystem Administration',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.jfscomp',
            COMMENTS => 'JFS Compression',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.lvm',
            COMMENTS => 'Logical Volume Manager',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.printers',
            COMMENTS => 'Front End Printer Support',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.security',
            COMMENTS => 'Base Security Function',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.serv_aid',
            COMMENTS => 'Error Log Service Aids',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.shell',
            COMMENTS => 'Shells (bsh, ksh, csh)',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.tty',
            COMMENTS => 'Base TTY Support and Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.loginlic',
            COMMENTS => 'License Management',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.serv_aid',
            COMMENTS => 'Software Error Logging and Dump Service Aids',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.sysbr',
            COMMENTS => 'System Backup and BOS Install Utilities',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'ifor_ls.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'ifor_ls.client.base',
            COMMENTS => 'SystemView License Use Management Client Runtime',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'printers.rte',
            COMMENTS => 'Printer Backend',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.terminfo.com.data',
            COMMENTS => 'Common Terminal Definitions',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.dec.data',
            COMMENTS => 'Digital Equipment Corp. Terminal Definitions',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.ibm.data',
            COMMENTS => 'IBM Terminal Definitions',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.pc.data',
            COMMENTS => 'Personal Computer Terminal Definitions',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.televideo.data',
            COMMENTS => 'Televideo Terminal Definitions',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.wyse.data',
            COMMENTS => 'Wyse Terminal Definitions',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        }
    ],
    'aix-4.3.2' => [
        {
            NAME     => 'X11.apps.pm',
            COMMENTS => 'AIXwindows Power Management GUI Utility',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.apps.pm',
            COMMENTS => 'AIXwindows Power Mgmt GUI Msgs - French',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.acct',
            COMMENTS => 'Accounting Services',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.lib',
            COMMENTS => 'Base Application Development Libraries',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.com',
            COMMENTS => 'Common Hardware Diagnostics',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.rte',
            COMMENTS => 'Hardware Diagnostics',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.util',
            COMMENTS => 'Hardware Diagnostics Utilities',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.docregister.com',
            COMMENTS => 'Docregister Common',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.fr_FR.com',
            COMMENTS => 'WebSM/SMIT Context Helps - French',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.html.en_US.topnav.navigate',
            COMMENTS => 'Top Level Navigation - U. S. English',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.com',
            COMMENTS => 'Common Language to Language Converters',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.fr_FR',
            COMMENTS => 'EBCDIC & ASCII Language Converters - French',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.ucs.com',
            COMMENTS => 'Unicode Base Converters for AIX Code Sets/Fonts',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.iso.fr_FR',
            COMMENTS => 'Base System Locale ISO Code Set - French',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mp',
            COMMENTS => 'Base Operating System Multiprocessor Runtime',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.diag.rte',
            COMMENTS => 'Hardware Diagnostics Messages - French',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.mp',
            COMMENTS => 'Base Operating System MP Messages - French',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.net.tcp.client',
            COMMENTS => 'TCP/IP Messages - French',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.rte',
            COMMENTS => 'Base Operating System Runtime Msgs - French',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ncs',
            COMMENTS => 'Network Computing System 1.5.1',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.client',
            COMMENTS => 'Network File System Client',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.client',
            COMMENTS => 'TCP/IP Client Support',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.server',
            COMMENTS => 'TCP/IP Server',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.smit',
            COMMENTS => 'TCP/IP SMIT Support',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.powermgt.rte',
            COMMENTS => 'Power Management Runtime Software',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte',
            COMMENTS => 'Base Operating System Runtime',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.Dt',
            COMMENTS => 'Desktop Integrator',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.ILS',
            COMMENTS => 'International Language Support',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.SRC',
            COMMENTS => 'System Resource Controller',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.X11',
            COMMENTS => 'AIXwindows Device Support',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.aio',
            COMMENTS => 'Asynchronous I/O Extension',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.archive',
            COMMENTS => 'Archive Commands',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.bind_cmds',
            COMMENTS => 'Binder and Loader Commands',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.boot',
            COMMENTS => 'Boot Commands',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.bosinst',
            COMMENTS => 'Base OS Install Commands',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.commands',
            COMMENTS => 'Commands',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.compare',
            COMMENTS => 'File Compare Commands',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.console',
            COMMENTS => 'Console',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.control',
            COMMENTS => 'System Control Commands',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.cron',
            COMMENTS => 'Batch Operations',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.date',
            COMMENTS => 'Date Control Commands',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.devices',
            COMMENTS => 'Base Device Drivers',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.devices_msg',
            COMMENTS => 'Device Driver Messages',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.diag',
            COMMENTS => 'Diagnostics',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.edit',
            COMMENTS => 'Editors',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.filesystem',
            COMMENTS => 'Filesystem Administration',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.iconv',
            COMMENTS => 'Language Converters',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.ifor_ls',
            COMMENTS => 'iFOR/LS Libraries',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.im',
            COMMENTS => 'Input Methods',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.install',
            COMMENTS => 'LPP Install Commands',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.jfscomp',
            COMMENTS => 'JFS Compression',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libc',
            COMMENTS => 'libc Library',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libcfg',
            COMMENTS => 'libcfg Library',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libcur',
            COMMENTS => 'libcurses Library',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libdbm',
            COMMENTS => 'libdbm Library',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libnetsvc',
            COMMENTS => 'Network Services Libraries',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libpthreads',
            COMMENTS => 'libpthreads Library',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libqb',
            COMMENTS => 'libqb Library',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libs',
            COMMENTS => 'libs Library',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.loc',
            COMMENTS => 'Base Locale Support',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.lvm',
            COMMENTS => 'Logical Volume Manager',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.man',
            COMMENTS => 'Man Commands',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.methods',
            COMMENTS => 'Device Config Methods',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.misc_cmds',
            COMMENTS => 'Miscellaneous Commands',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.net',
            COMMENTS => 'Network',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.odm',
            COMMENTS => 'Object Data Manager',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.printers',
            COMMENTS => 'Front End Printer Support',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.security',
            COMMENTS => 'Base Security Function',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.serv_aid',
            COMMENTS => 'Error Log Service Aids',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.shell',
            COMMENTS => 'Shells (bsh, ksh, csh)',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.streams',
            COMMENTS => 'Streams Libraries',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.tty',
            COMMENTS => 'Base TTY Support and Commands',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.loginlic',
            COMMENTS => 'License Management',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.serv_aid',
            COMMENTS => 'Software Error Logging and Dump Service Aids',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.smit',
            COMMENTS => 'System Management Interface Tool (SMIT)',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.sysbr',
            COMMENTS => 'System Backup and BOS Install Utilities',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.rte',
            COMMENTS => 'Run-time Environment for AIX Terminals',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.client.base',
            COMMENTS => 'SystemView License Use Management Client Runtime',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.client.gui',
            COMMENTS => 'License Use Management Client GUI',
            VERSION  => '4.3.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.msg.fr_FR.base.cli',
            COMMENTS => 'LUM Runtime Code Messages - French',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hpJetDirect.attach',
            COMMENTS => 'Hewlett-Packard JetDirect Network Printer Attachment',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.msg.fr_FR.rte',
            COMMENTS => 'Printer Backend Messages - French',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.rte',
            COMMENTS => 'Printer Backend',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.rte',
            COMMENTS => 'C Set ++ for AIX Application Runtime',
            VERSION  => '3.6.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.acct',
            COMMENTS => 'Accounting Services',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.com',
            COMMENTS => 'Common Hardware Diagnostics',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.rte',
            COMMENTS => 'Hardware Diagnostics',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.util',
            COMMENTS => 'Hardware Diagnostics Utilities',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.html.en_US.topnav.navigate',
            COMMENTS => 'Top Level Navigation - U. S. English',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.mp',
            COMMENTS => 'Base Operating System Multiprocessor Runtime',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ncs',
            COMMENTS => 'Network Computing System 1.5.1',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.client',
            COMMENTS => 'Network File System Client',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.client',
            COMMENTS => 'TCP/IP Client Support',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.server',
            COMMENTS => 'TCP/IP Server',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.powermgt.rte',
            COMMENTS => 'Power Management Runtime Software',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte',
            COMMENTS => 'Base Operating System Runtime',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.Dt',
            COMMENTS => 'Desktop Integrator',
            VERSION  => '4.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.SRC',
            COMMENTS => 'System Resource Controller',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.aio',
            COMMENTS => 'Asynchronous I/O Extension',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.boot',
            COMMENTS => 'Boot Commands',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.commands',
            COMMENTS => 'Commands',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.control',
            COMMENTS => 'System Control Commands',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.cron',
            COMMENTS => 'Batch Operations',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.devices',
            COMMENTS => 'Base Device Drivers',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.diag',
            COMMENTS => 'Diagnostics',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.filesystem',
            COMMENTS => 'Filesystem Administration',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.jfscomp',
            COMMENTS => 'JFS Compression',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.lvm',
            COMMENTS => 'Logical Volume Manager',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.printers',
            COMMENTS => 'Front End Printer Support',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.security',
            COMMENTS => 'Base Security Function',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.serv_aid',
            COMMENTS => 'Error Log Service Aids',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.shell',
            COMMENTS => 'Shells (bsh, ksh, csh)',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.tty',
            COMMENTS => 'Base TTY Support and Commands',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.loginlic',
            COMMENTS => 'License Management',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.serv_aid',
            COMMENTS => 'Software Error Logging and Dump Service Aids',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.sysbr',
            COMMENTS => 'System Backup and BOS Install Utilities',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'ifor_ls.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'ifor_ls.client.base',
            COMMENTS => 'SystemView License Use Management Client Runtime',
            VERSION  => '4.3.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'printers.rte',
            COMMENTS => 'Printer Backend',
            VERSION  => '4.3.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.terminfo.com.data',
            COMMENTS => 'Common Terminal Definitions',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.dec.data',
            COMMENTS => 'Digital Equipment Corp. Terminal Definitions',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.ibm.data',
            COMMENTS => 'IBM Terminal Definitions',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.pc.data',
            COMMENTS => 'Personal Computer Terminal Definitions',
            VERSION  => '4.3.2.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.televideo.data',
            COMMENTS => 'Televideo Terminal Definitions',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.wyse.data',
            COMMENTS => 'Wyse Terminal Definitions',
            VERSION  => '4.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        }
    ],
    'aix-5.3a' => [
        {
            NAME     => 'BULLENH_VERSION',
            COMMENTS => 'For BULLENH installation refer to SRB.',
            VERSION  => '5.30.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'BullSAN.ucode',
            COMMENTS => 'Firmware for FC infrastucture',
            VERSION  => '1.0.6.9',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Bulltape',
            COMMENTS => 'BULL SCSI Tapes Support',
            VERSION  => '5.1.1.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Bulltape_diag',
            COMMENTS => 'BULL SCSI Tapes Diagnostics Support',
            VERSION  => '5.1.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Bulltools',
            COMMENTS => 'Bull common tools',
            VERSION  => '5.1.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'EMC.CLARiiON.fcp.rte',
            COMMENTS => 'EMC CLARiiON Fibre Channel Support Software',
            VERSION  => '5.2.0.3',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'EMC.Symmetrix.aix.rte',
            COMMENTS => 'EMC Symmetrix AIX Support Software',
            VERSION  => '5.2.0.3',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'EMC.Symmetrix.fcp.rte',
            COMMENTS => 'EMC Symmetrix Fibre Channel Support Software',
            VERSION  => '5.2.0.3',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Java14.license',
            COMMENTS => 'Java SDK 32-bit License',
            VERSION  => '1.4.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Java14.sdk',
            COMMENTS => 'Java SDK 32-bit',
            VERSION  => '1.4.2.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'NAVIERRLOG',
            COMMENTS => 'Navisphere Errlogger',
            VERSION  => '5.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Tivoli_Management_Agent.client.rte',
            COMMENTS => 'Management Framework Endpoint Runtime"',
            VERSION  => '3.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.Dt.ToolTalk',
            COMMENTS => 'AIX CDE ToolTalk Support',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.Dt.adt',
            COMMENTS => 'AIX CDE Application Developers\' Toolkit',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.Dt.bitmaps',
            COMMENTS => 'AIX CDE Bitmaps',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.Dt.compat',
            COMMENTS => 'AIX CDE Compatibility',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.Dt.helpinfo',
            COMMENTS => 'AIX CDE Help Files and Volumes',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.Dt.helpmin',
            COMMENTS => 'AIX CDE Minimum Help Files',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.Dt.helprun',
            COMMENTS => 'AIX CDE Runtime Help',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.Dt.lib',
            COMMENTS => 'AIX CDE Runtime Libraries',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.Dt.rte',
            COMMENTS => 'AIX Common Desktop Environment (CDE) 1.0',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.Dt.xdt2cde',
            COMMENTS => 'AIX CDE Migration Tool',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.adt.bitmaps',
            COMMENTS => 'AIXwindows Application Development Toolkit Bitmap Files',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.adt.ext',
            COMMENTS => 'AIXwindows Application Development Toolkit for X Extensions',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.adt.imake',
            COMMENTS => 'AIXwindows Application Development Toolkit imake',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.adt.include',
            COMMENTS => 'AIXwindows Application Development Toolkit Include Files',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.adt.lib',
            COMMENTS => 'AIXwindows Application Development Toolkit Libraries',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.adt.motif',
            COMMENTS => 'AIXwindows Application Development Toolkit Motif',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.aixterm',
            COMMENTS => 'AIXwindows aixterm Application',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.clients',
            COMMENTS => 'AIXwindows Client Applications',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.config',
            COMMENTS => 'AIXwindows Configuration Applications',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.custom',
            COMMENTS => 'AIXwindows Customizing Tool',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.msmit',
            COMMENTS => 'AIXwindows msmit Application',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.rte',
            COMMENTS => 'AIXwindows Runtime Configuration Applications',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.util',
            COMMENTS => 'AIXwindows Utility Applications',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.xdm',
            COMMENTS => 'AIXwindows xdm Application',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.xterm',
            COMMENTS => 'AIXwindows xterm Application',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.base.common',
            COMMENTS => 'AIXwindows Runtime Common Directories',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.base.lib',
            COMMENTS => 'AIXwindows Runtime Libraries',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.base.rte',
            COMMENTS => 'AIXwindows Runtime Environment',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.base.smt',
            COMMENTS => 'AIXwindows Runtime Shared Memory Transport',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.base.xpconfig',
            COMMENTS => 'Xprint Configuration Files',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.compat.adt.Motif12',
            COMMENTS => 'AIXwindows Motif 1.2 Compatibility Development Toolkit',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.compat.lib.Motif10',
            COMMENTS => 'AIXwindows Motif 1.0 Libraries Compatibility',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.compat.lib.Motif114',
            COMMENTS => 'AIXwindows Motif 1.1.4 Libraries Compatibility',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.compat.lib.X11R3',
            COMMENTS => 'AIXwindows X11R3 Libraries Compatibility',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.compat.lib.X11R4',
            COMMENTS => 'AIXwindows X11R4 Libraries Compatibility',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.compat.lib.X11R5',
            COMMENTS => 'AIXwindows X11R5 Compatibility Libraries',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.Gr_Cyr_T1',
            COMMENTS => 'AIXwindows Greek-Cyrillic Type1 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.coreX',
            COMMENTS => 'AIXwindows X Consortium Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.defaultFonts',
            COMMENTS => 'AIXwindows Default Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.deform_JP',
            COMMENTS => 'AIXwindows Japanese PCF Deformed Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.fontServer',
            COMMENTS => 'AIXwindows Font Server',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.ibm1046',
            COMMENTS => 'AIXwindows Arabic Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.ibm1046_T1',
            COMMENTS => 'AIXwindows Arabic Type1 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso1',
            COMMENTS => 'AIXwindows Latin 1 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso2',
            COMMENTS => 'AIXwindows Latin 2 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso3',
            COMMENTS => 'AIXwindows Latin 3 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso4',
            COMMENTS => 'AIXwindows Latin 4 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso5',
            COMMENTS => 'AIXwindows Cyrillic Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso7',
            COMMENTS => 'AIXwindows Greek Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso8',
            COMMENTS => 'AIXwindows Hebrew Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso8_T1',
            COMMENTS => 'AIXwindows Hebrew Type1 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso9',
            COMMENTS => 'AIXwindows Turkish Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso_T1',
            COMMENTS => 'AIXwindows Latin Type1 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.ksc5601.ttf',
            COMMENTS => 'AIXwindows Korean KSC5601 TrueType Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.ucs.cjk',
            COMMENTS => 'AIXwindows Unicode CJK Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.ucs.com',
            COMMENTS => 'AIXwindows Common Fonts Unicode',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.ucs.ttf_CN',
            COMMENTS => 'AIXwindows Unicode TrueType Fonts - CJK China',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.ucs.ttf_extb',
            COMMENTS => 'AIXwindows Unicode TrueType Fonts - Extension B',
            VERSION  => '5.3.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.util',
            COMMENTS => 'AIXwindows Font Utilities',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.de_DE.Dt.rte',
            COMMENTS => 'CDE Locale Configuration - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.de_DE.base.lib',
            COMMENTS => 'AIXwindows Client Locale Config - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.de_DE.base.rte',
            COMMENTS => 'AIXwindows Locale Configuration - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.en_US.Dt.rte',
            COMMENTS => 'CDE Locale Configuration - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.en_US.base.lib',
            COMMENTS => 'AIXwindows Client Locale Config - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.en_US.base.rte',
            COMMENTS => 'AIXwindows Locale Configuration - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.es_ES.Dt.rte',
            COMMENTS => 'CDE Locale Configuration - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.es_ES.base.lib',
            COMMENTS => 'AIXwindows Client Locale Config - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.es_ES.base.rte',
            COMMENTS => 'AIXwindows Locale Configuration - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.fr_FR.Dt.rte',
            COMMENTS => 'CDE Locale Configuration - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.fr_FR.base.lib',
            COMMENTS => 'AIXwindows Client Locale Config - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.fr_FR.base.rte',
            COMMENTS => 'AIXwindows Locale Configuration - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.it_IT.Dt.rte',
            COMMENTS => 'CDE Locale Configuration - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.it_IT.base.lib',
            COMMENTS => 'AIXwindows Client Locale Config - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.it_IT.base.rte',
            COMMENTS => 'AIXwindows Locale Configuration - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.motif.lib',
            COMMENTS => 'AIXwindows Motif Libraries',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.motif.mwm',
            COMMENTS => 'AIXwindows Motif Window Manager',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.de_DE.Dt.helpmin',
            COMMENTS => 'AIX CDE Minimum Help Files - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.de_DE.Dt.rte',
            COMMENTS => 'AIX CDE Messages - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.de_DE.adt.imake',
            COMMENTS => 'AIXwindows imake Messages - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.de_DE.apps.aixterm',
            COMMENTS => 'AIXwindows aixterm Messages - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.de_DE.apps.clients',
            COMMENTS => 'AIXwindows Client Apps Msgs - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.de_DE.apps.config',
            COMMENTS => 'AIXwindows Config Apps Msgs - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.de_DE.apps.custom',
            COMMENTS => 'AIXwindows Custom Tool Msgs - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.de_DE.apps.rte',
            COMMENTS => 'AIXwindows Runtime Config Msgs - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.de_DE.apps.xdm',
            COMMENTS => 'AIXwindows xdm Messages - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.de_DE.base.common',
            COMMENTS => 'AIXwindows Common Messages - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.de_DE.base.rte',
            COMMENTS => 'AIXwindows Runtime Env. Msgs - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.de_DE.motif.lib',
            COMMENTS => 'AIXwindows Motif Lib. Msgs - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.de_DE.motif.mwm',
            COMMENTS => 'AIX Motif Window Mgr Msgs - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.de_DE.vsm.rte',
            COMMENTS => 'Visual Sys Mgmt. Helps & Msgs - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.Dt.helpmin',
            COMMENTS => 'AIX CDE Minimum Help Files - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.Dt.rte',
            COMMENTS => 'AIX CDE Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.adt.imake',
            COMMENTS => 'AIXwindows imake Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.apps.aixterm',
            COMMENTS => 'AIXwindows aixterm Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.apps.clients',
            COMMENTS => 'AIXwindows Client Apps Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.apps.config',
            COMMENTS => 'AIXwindows Config Apps Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.apps.custom',
            COMMENTS => 'AIXwindows Custom Tool Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.apps.rte',
            COMMENTS => 'AIXwindows Runtime Config Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.apps.xdm',
            COMMENTS => 'AIXwindows xdm Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.base.common',
            COMMENTS => 'AIXwindows Common Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.base.rte',
            COMMENTS => 'AIXwindows Runtime Env. Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.motif.lib',
            COMMENTS => 'AIXwindows Motif Lib. Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.motif.mwm',
            COMMENTS => 'AIX Motif Window Mgr Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.vsm.rte',
            COMMENTS => 'Visual Sys Mgmt. Helps & Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.es_ES.Dt.helpmin',
            COMMENTS => 'AIX CDE Minimum Help Files - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.es_ES.Dt.rte',
            COMMENTS => 'AIX CDE Messages - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.es_ES.adt.imake',
            COMMENTS => 'AIXwindows imake Messages - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.es_ES.apps.aixterm',
            COMMENTS => 'AIXwindows aixterm Messages - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.es_ES.apps.clients',
            COMMENTS => 'AIXwindows Client Apps Msgs - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.es_ES.apps.config',
            COMMENTS => 'AIXwindows Config Apps Msgs - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.es_ES.apps.custom',
            COMMENTS => 'AIXwindows Custom Tool Msgs - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.es_ES.apps.rte',
            COMMENTS => 'AIXwindows Runtime Config Msgs - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.es_ES.apps.xdm',
            COMMENTS => 'AIXwindows xdm Messages - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.es_ES.base.common',
            COMMENTS => 'AIXwindows Common Messages - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.es_ES.base.rte',
            COMMENTS => 'AIXwindows Runtime Env. Msgs - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.es_ES.motif.lib',
            COMMENTS => 'AIXwindows Motif Lib. Msgs - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.es_ES.motif.mwm',
            COMMENTS => 'AIX Motif Window Mgr Msgs - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.es_ES.vsm.rte',
            COMMENTS => 'Visual Sys Mgmt. Helps & Msgs - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.Dt.helpmin',
            COMMENTS => 'AIX CDE Minimum Help Files - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.Dt.rte',
            COMMENTS => 'AIX CDE Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.adt.ext',
            COMMENTS => 'AIXwindows X Extensions Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.adt.imake',
            COMMENTS => 'AIXwindows imake Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.apps.aixterm',
            COMMENTS => 'AIXwindows aixterm Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.apps.clients',
            COMMENTS => 'AIXwindows Client Apps Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.apps.config',
            COMMENTS => 'AIXwindows Config Apps Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.apps.custom',
            COMMENTS => 'AIXwindows Custom Tool Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.apps.rte',
            COMMENTS => 'AIXwindows Runtime Config Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.apps.xdm',
            COMMENTS => 'AIXwindows xdm Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.base.common',
            COMMENTS => 'AIXwindows Common Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.base.rte',
            COMMENTS => 'AIXwindows Runtime Env. Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.fnt.fontServer',
            COMMENTS => 'AIXwindows Font Server Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.fnt.util',
            COMMENTS => 'AIXwindows Font Utilities Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.motif.lib',
            COMMENTS => 'AIXwindows Motif Lib. Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.motif.mwm',
            COMMENTS => 'AIX Motif Window Mgr Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.vsm.rte',
            COMMENTS => 'Visual Sys Mgmt. Helps & Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.it_IT.Dt.helpmin',
            COMMENTS => 'AIX CDE Minimum Help Files - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.it_IT.Dt.rte',
            COMMENTS => 'AIX CDE Messages - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.it_IT.adt.imake',
            COMMENTS => 'AIXwindows imake Messages - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.it_IT.apps.aixterm',
            COMMENTS => 'AIXwindows aixterm Messages - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.it_IT.apps.clients',
            COMMENTS => 'AIXwindows Client Apps Msgs - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.it_IT.apps.config',
            COMMENTS => 'AIXwindows Config Apps Msgs - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.it_IT.apps.custom',
            COMMENTS => 'AIXwindows Custom Tool Msgs - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.it_IT.apps.rte',
            COMMENTS => 'AIXwindows Runtime Config Msgs - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.it_IT.apps.xdm',
            COMMENTS => 'AIXwindows xdm Messages - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.it_IT.base.common',
            COMMENTS => 'AIXwindows Common Messages - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.it_IT.base.rte',
            COMMENTS => 'AIXwindows Runtime Env. Msgs - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.it_IT.motif.lib',
            COMMENTS => 'AIXwindows Motif Lib. Msgs - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.it_IT.motif.mwm',
            COMMENTS => 'AIX Motif Window Mgr Msgs - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.it_IT.vsm.rte',
            COMMENTS => 'Visual Sys Mgmt. Helps & Msgs - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.samples.apps.clients',
            COMMENTS => 'AIXwindows Sample X Consortium Clients Binary/Source',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.samples.common',
            COMMENTS => 'AIXwindows Imakefile Structure for Samples',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.samples.lib.Core',
            COMMENTS => 'AIXwindows Sample X Consortium Core Libraries Binary/Source',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.vsm.lib',
            COMMENTS => 'Visual System Managment Library',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.64bit',
            COMMENTS => 'Base Operating System 64 bit Runtime',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.acct',
            COMMENTS => 'Accounting Services',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.base',
            COMMENTS => 'Base Application Development Toolkit',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.debug',
            COMMENTS => 'Base Application Development Debuggers',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.graphics',
            COMMENTS => 'Base Application Development Graphics Include Files',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.include',
            COMMENTS => 'Base Application Development Include Files',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.insttools',
            COMMENTS => 'Tool to Create installp Packages',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.lib',
            COMMENTS => 'Base Application Development Libraries',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.libm',
            COMMENTS => 'Base Application Development Math Library',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.prof',
            COMMENTS => 'Base Profiling Support',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.prt_tools',
            COMMENTS => 'Printer Support Development Toolkit',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.samples',
            COMMENTS => 'Base Operating System Samples',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.sccs',
            COMMENTS => 'SCCS Application Development Toolkit',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.syscalls',
            COMMENTS => 'System Calls Application Development Toolkit',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.utils',
            COMMENTS => 'Base Application Development Utilities - lex and yacc',
            VERSION  => '5.3.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.alt_disk_install.boot_images',
            COMMENTS => 'Alternate Disk Installation Disk Boot Images',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.alt_disk_install.rte',
            COMMENTS => 'Alternate Disk Installation Runtime',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.cdmount',
            COMMENTS => 'CD/DVD Automount Facility',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.cifs_fs.rte',
            COMMENTS => 'Runtime for SMBFS',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.cifs_fs.smit',
            COMMENTS => 'SMIT Interface for SMBFS',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.compat.cmds',
            COMMENTS => 'AIX 3.2 Compatibility Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.compat.libs',
            COMMENTS => 'AIX 3.2 Compatibility Libraries',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.compat.links',
            COMMENTS => 'AIX 3.2 to 4 Compatibility Links',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.compat.net',
            COMMENTS => 'AIX 3.2 TCP/IP Compatability Commands',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.compat.termcap',
            COMMENTS => 'AIX 3.2 Termcap Source and Library',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.content_list',
            COMMENTS => 'AIX Release Content List',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.com',
            COMMENTS => 'Common Hardware Diagnostics',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.rte',
            COMMENTS => 'Hardware Diagnostics',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.util',
            COMMENTS => 'Hardware Diagnostics Utilities',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.dosutil',
            COMMENTS => 'DOS Utilities',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.de_DE.com',
            COMMENTS => 'WebSM/SMIT Context Helps - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.en_US.com',
            COMMENTS => 'WebSM/SMIT Context Helps - U.S. English',
            VERSION  => '5.3.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.en_US.smit',
            COMMENTS => 'SMIT Context Helps - U.S. English',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.es_ES.com',
            COMMENTS => 'WebSM/SMIT Context Helps - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.fr_FR.com',
            COMMENTS => 'WebSM/SMIT Context Helps - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.it_IT.com',
            COMMENTS => 'WebSM/SMIT Context Helps - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.com',
            COMMENTS => 'Common Language to Language Converters',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.de_DE',
            COMMENTS => 'EBCDIC & ASCII Language Converters - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.es_ES',
            COMMENTS => 'EBCDIC & ASCII Language Converters - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.fr_FR',
            COMMENTS => 'EBCDIC & ASCII Language Converters - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.it_IT',
            COMMENTS => 'EBCDIC & ASCII Language Converters - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.ja_JP',
            COMMENTS => 'EBCDIC & ASCII Language Converters - Japanese',
            VERSION  => '5.3.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.ko_KR',
            COMMENTS => 'EBCDIC & ASCII Language Converters - Korean',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.ucs.ZH_CN',
            COMMENTS => 'Unicode Converters for Simplified Chinese',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.ucs.com',
            COMMENTS => 'Unicode Base Converters for AIX Code Sets/Fonts',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.zh_TW',
            COMMENTS => 'EBCDIC & ASCII Language Converters - Traditional Chinese',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.adt.iconv',
            COMMENTS => 'Language Converter Development Toolkit',
            VERSION  => '5.3.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.adt.imk',
            COMMENTS => 'Keymap Development Toolkit',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.adt.locale',
            COMMENTS => 'Locale Development Toolkit',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.com.CN',
            COMMENTS => 'Common Locale Support - Simplified Chinese',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.com.JP',
            COMMENTS => 'Common Locale Support - Japanese',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.com.bidi',
            COMMENTS => 'Common Locale Support - Bidirectional Languages',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.com.utf',
            COMMENTS => 'Common Locale Support - UTF-8',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.iso.de_DE',
            COMMENTS => 'Base System Locale ISO Code Set - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.iso.en_US',
            COMMENTS => 'Base System Locale ISO Code Set - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.iso.es_ES',
            COMMENTS => 'Base System Locale ISO Code Set - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.iso.fr_FR',
            COMMENTS => 'Base System Locale ISO Code Set - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.iso.it_IT',
            COMMENTS => 'Base System Locale ISO Code Set - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.iso.ko_KR',
            COMMENTS => 'Base System Locale ISO Code Set - Korean',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.iso.zh_TW',
            COMMENTS => 'Base System Locale ISO Code Set - Traditional Chinese',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.utf.HI_IN',
            COMMENTS => 'Base System Locale UTF Code Set - Hindi',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.utf.ZH_CN',
            COMMENTS => 'Base System Locale UTF Code Set - Simplified Chinese',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mh',
            COMMENTS => 'Mail Handler',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mp',
            COMMENTS => 'Base Operating System Multiprocessor Runtime',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mp64',
            COMMENTS => 'Base Operating System 64-bit Multiprocessor Runtime',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.de_DE.alt_disk_install.rte',
            COMMENTS => 'Alternate Disk Install Msgs - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.de_DE.diag.rte',
            COMMENTS => 'Hardware Diagnostics Messages - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.de_DE.mp',
            COMMENTS => 'Base Operating System MP Msgs - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.de_DE.net.ipsec',
            COMMENTS => 'IP Security Messages - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.de_DE.net.tcp.client',
            COMMENTS => 'TCP/IP Messages - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.de_DE.rte',
            COMMENTS => 'Base OS Runtime Messages - German',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.de_DE.txt.tfs',
            COMMENTS => 'Text Formatting Services Msgs - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.en_US.alt_disk_install.rte',
            COMMENTS => 'Alternate Disk Install Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.en_US.diag.rte',
            COMMENTS => 'Hardware Diagnostics Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.en_US.mp',
            COMMENTS => 'Base Operating System MP Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.en_US.net.ipsec',
            COMMENTS => 'IP Security Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.en_US.net.tcp.client',
            COMMENTS => 'TCP/IP Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.en_US.rte',
            COMMENTS => 'Base OS Runtime Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.en_US.txt.tfs',
            COMMENTS => 'Text Formatting Services Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.es_ES.alt_disk_install.rte',
            COMMENTS => 'Alternate Disk Install Msgs - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.es_ES.diag.rte',
            COMMENTS => 'Hardware Diagnostics Messages - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.es_ES.mp',
            COMMENTS => 'Base Operating System MP Msgs - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.es_ES.net.ipsec',
            COMMENTS => 'IP Security Messages - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.es_ES.net.tcp.client',
            COMMENTS => 'TCP/IP Messages - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.es_ES.rte',
            COMMENTS => 'Base OS Runtime Messages - Spanish',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.es_ES.txt.tfs',
            COMMENTS => 'Text Formatting Services Msgs - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.alt_disk_install.rte',
            COMMENTS => 'Alternate Disk Install Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.diag.rte',
            COMMENTS => 'Hardware Diagnostics Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.mp',
            COMMENTS => 'Base Operating System MP Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.net.ipsec',
            COMMENTS => 'IP Security Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.net.tcp.client',
            COMMENTS => 'TCP/IP Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.rte',
            COMMENTS => 'Base OS Runtime Messages - French',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.svprint',
            COMMENTS => 'System V Print Subsystem Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.txt.tfs',
            COMMENTS => 'Text Formatting Services Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.it_IT.alt_disk_install.rte',
            COMMENTS => 'Alternate Disk Install Msgs - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.it_IT.diag.rte',
            COMMENTS => 'Hardware Diagnostics Messages - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.it_IT.mp',
            COMMENTS => 'Base Operating System MP Msgs - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.it_IT.net.ipsec',
            COMMENTS => 'IP Security Messages - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.it_IT.net.tcp.client',
            COMMENTS => 'TCP/IP Messages - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.it_IT.rte',
            COMMENTS => 'Base OS Runtime Messages - Italian',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.it_IT.txt.tfs',
            COMMENTS => 'Text Formatting Services Msgs - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ate',
            COMMENTS => 'Asynchronous Terminal Emulator',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ewlm.rte',
            COMMENTS => 'netWLM',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ipsec.keymgt',
            COMMENTS => 'IP Security Key Management',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ipsec.rte',
            COMMENTS => 'IP Security',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ipsec.websm',
            COMMENTS => 'IP Security WebSM',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.mobip6.rte',
            COMMENTS => 'IPv6 Mobility',
            VERSION  => '5.3.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ncs',
            COMMENTS => 'Network Computing System 1.5.1',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.adt',
            COMMENTS => 'Network File System Development Toolkit',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.cachefs',
            COMMENTS => 'CacheFS File System',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.client',
            COMMENTS => 'Network File System Client',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.server',
            COMMENTS => 'Network File System Server',
            VERSION  => '5.3.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nis.client',
            COMMENTS => 'Network Information Service Client',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nis.server',
            COMMENTS => 'Network Information Service Server',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nisplus',
            COMMENTS => 'Network Information Services Plus (NIS+)',
            VERSION  => '5.3.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ppp',
            COMMENTS => 'Async Point to Point Protocol',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.sctp',
            COMMENTS => 'Stream Control Transmission Protocol',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.snapp',
            COMMENTS => 'System Networking Analysis and Performance Pilot',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.adt',
            COMMENTS => 'TCP/IP Application Toolkit',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.client',
            COMMENTS => 'TCP/IP Client Support',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.server',
            COMMENTS => 'TCP/IP Server',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.smit',
            COMMENTS => 'TCP/IP SMIT Support',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.uucp',
            COMMENTS => 'Unix to Unix Copy Program',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.diag_tool',
            COMMENTS => 'Performance Diagnostic Tool',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.gtools.perfwb',
            COMMENTS => 'Performance Workbench',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.gtools.procmon',
            COMMENTS => 'Procmon plugin for Performance Workbench',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.libperfstat',
            COMMENTS => 'Performance Statistics Library Interface',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.perfstat',
            COMMENTS => 'Performance Statistics Interface',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.proctools',
            COMMENTS => 'Proc Filesystem Tools',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.tools',
            COMMENTS => 'Base Performance Tools',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.tune',
            COMMENTS => 'Performance Tuning Support',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.events',
            COMMENTS => 'Performance Monitor API Event Codes',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.lib',
            COMMENTS => 'Performance Monitor API Library',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.pmsvcs',
            COMMENTS => 'Performance Monitor API Kernel Extension',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.samples',
            COMMENTS => 'Performance Monitor API Samples',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.tools',
            COMMENTS => 'Performance Monitor API Tools',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte',
            COMMENTS => 'Base Operating System Runtime',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.Dt',
            COMMENTS => 'Desktop Integrator',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.ILS',
            COMMENTS => 'International Language Support',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.SRC',
            COMMENTS => 'System Resource Controller',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.X11',
            COMMENTS => 'AIXwindows Device Support',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.aio',
            COMMENTS => 'Asynchronous I/O Extension',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.archive',
            COMMENTS => 'Archive Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.bind_cmds',
            COMMENTS => 'Binder and Loader Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.boot',
            COMMENTS => 'Boot Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.bosinst',
            COMMENTS => 'Base OS Install Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.commands',
            COMMENTS => 'Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.compare',
            COMMENTS => 'File Compare Commands',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.console',
            COMMENTS => 'Console',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.control',
            COMMENTS => 'System Control Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.cron',
            COMMENTS => 'Batch Operations',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.date',
            COMMENTS => 'Date Control Commands',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.devices',
            COMMENTS => 'Base Device Drivers',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.devices_msg',
            COMMENTS => 'Device Driver Messages',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.diag',
            COMMENTS => 'Diagnostics',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.edit',
            COMMENTS => 'Editors',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.filesystem',
            COMMENTS => 'Filesystem Administration',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.iconv',
            COMMENTS => 'Language Converters',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.ifor_ls',
            COMMENTS => 'iFOR/LS Libraries',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.im',
            COMMENTS => 'Input Methods',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.install',
            COMMENTS => 'LPP Install Commands',
            VERSION  => '5.3.7.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.jfscomp',
            COMMENTS => 'JFS Compression',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libc',
            COMMENTS => 'libc Library',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libcfg',
            COMMENTS => 'libcfg Library',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libcur',
            COMMENTS => 'libcurses Library',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libdbm',
            COMMENTS => 'libdbm Library',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libnetsvc',
            COMMENTS => 'Network Services Libraries',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libpthreads',
            COMMENTS => 'pthreads Library',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libqb',
            COMMENTS => 'libqb Library',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libs',
            COMMENTS => 'libs Library',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.loc',
            COMMENTS => 'Base Locale Support',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.lvm',
            COMMENTS => 'Logical Volume Manager',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.man',
            COMMENTS => 'Man Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.methods',
            COMMENTS => 'Device Config Methods',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.misc_cmds',
            COMMENTS => 'Miscellaneous Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.net',
            COMMENTS => 'Network',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.odm',
            COMMENTS => 'Object Data Manager',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.printers',
            COMMENTS => 'Front End Printer Support',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.security',
            COMMENTS => 'Base Security Function',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.serv_aid',
            COMMENTS => 'Error Log Service Aids',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.shell',
            COMMENTS => 'Shells (bsh, ksh, csh)',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.streams',
            COMMENTS => 'Streams Libraries',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.tty',
            COMMENTS => 'Base TTY Support and Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.suma',
            COMMENTS => 'Service Update Management Assistant (SUMA)',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.svpkg',
            COMMENTS => 'System V Packaging and Installation Tools',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.svprint.dir_enabled',
            COMMENTS => 'System V Directory-enabled Commands',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.svprint.fonts',
            COMMENTS => 'System V Print Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.svprint.hpnp',
            COMMENTS => 'System V Hewlett-Packard JetDirect',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.svprint.ps',
            COMMENTS => 'System V Print Postscript',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.svprint.rte',
            COMMENTS => 'System V Print Subsystem',
            VERSION  => '5.3.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.svprint.trans',
            COMMENTS => 'System V Print Translation',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.loginlic',
            COMMENTS => 'License Management',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.nim.client',
            COMMENTS => 'Network Install Manager - Client Tools',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.quota',
            COMMENTS => 'Filesystem Quota Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.serv_aid',
            COMMENTS => 'Software Error Logging and Dump Service Aids',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.smit',
            COMMENTS => 'System Management Interface Tool (SMIT)',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.sysbr',
            COMMENTS => 'System Backup and BOS Install Utilities',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.trace',
            COMMENTS => 'Software Trace Service Aids',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.rte',
            COMMENTS => 'Run-time Environment for AIX Terminals',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.bib',
            COMMENTS => 'Bibliography Support',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.hplj.fnt',
            COMMENTS => 'Fonts for Hewlett Packard Laser Jet Printers',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.ibm3812.fnt',
            COMMENTS => 'Fonts for IBM 3812 Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.ibm3816.fnt',
            COMMENTS => 'Fonts for IBM 3816 Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.spell',
            COMMENTS => 'Writer\'s Tools Commands',
            VERSION  => '5.3.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.tfs',
            COMMENTS => 'Text Formatting Services Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.ts',
            COMMENTS => 'TranScript Tools',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.xpv.rte',
            COMMENTS => 'Troff Xpreviewer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bullasync.base.rte',
            COMMENTS => 'Bull Common Asynchronous Adapter Software',
            VERSION  => '1.8.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bullasync.pci.diag',
            COMMENTS => 'Bull PCI Asynchronous Adapter Diagnostics',
            VERSION  => '1.8.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bullasync.pci.rte',
            COMMENTS => 'Bull PCI Asynchronous Adapter Software',
            VERSION  => '1.8.2.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.client',
            COMMENTS => 'Cluster Systems Management Client',
            VERSION  => '1.4.1.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.core',
            COMMENTS => 'Cluster Systems Management Core',
            VERSION  => '1.4.1.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.diagnostics',
            COMMENTS => 'Cluster Systems Management Probe Manager / Diagnostics',
            VERSION  => '1.4.1.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.dsh',
            COMMENTS => 'Cluster Systems Management Dsh',
            VERSION  => '1.4.1.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.gui.dcem',
            COMMENTS => 'Distributed Command Execution Manager Runtime Environment',
            VERSION  => '1.4.1.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.DE_DE.core',
            COMMENTS => 'CSM Core Func Msgs - German (UTF)',
            VERSION  => '1.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.EN_US.core',
            COMMENTS => 'CSM Core Func Msgs - U.S. English (UTF)',
            VERSION  => '1.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.ES_ES.core',
            COMMENTS => 'CSM Core Func Msgs - Spanish (UTF)',
            VERSION  => '1.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.FR_FR.core',
            COMMENTS => 'CSM Core Func Msgs - French (UTF)',
            VERSION  => '1.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.IT_IT.core',
            COMMENTS => 'CSM Core Func Msgs - Italian (UTF)',
            VERSION  => '1.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.de_DE.core',
            COMMENTS => 'CSM Core Func Msgs - German',
            VERSION  => '1.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.en_US.core',
            COMMENTS => 'CSM Core Func Msgs - U.S. English',
            VERSION  => '1.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.es_ES.core',
            COMMENTS => 'CSM Core Func Msgs - Spanish',
            VERSION  => '1.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.fr_FR.core',
            COMMENTS => 'CSM Core Func Msgs - French',
            VERSION  => '1.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.it_IT.core',
            COMMENTS => 'CSM Core Func Msgs - Italian',
            VERSION  => '1.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'eclipse2.rte',
            COMMENTS => 'Eclipse Integrated Tool Platform Runtime',
            VERSION  => '2.1.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'freeware.proftpd.rte',
            COMMENTS => 'ProFTPd ftp daemon',
            VERSION  => '1.2.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.msg.en_US.base.cli',
            COMMENTS => 'LUM Runtime Code Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'infocenter.man.EN_US.commands',
            COMMENTS => 'AIX manual commands - U.S. English',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'infocenter.man.EN_US.files',
            COMMENTS => 'AIX manual files - U.S. English',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.com',
            COMMENTS => 'Inventory Scout Microcode Catalog',
            VERSION  => '2.2.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.ldb',
            COMMENTS => 'Inventory Scout Logic Database',
            VERSION  => '2.2.0.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.msg.de_DE.rte',
            COMMENTS => 'Inventory Scout Messages - German',
            VERSION  => '2.1.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.msg.en_US.rte',
            COMMENTS => 'Inventory Scout Messages - U.S. English',
            VERSION  => '2.1.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.msg.es_ES.rte',
            COMMENTS => 'Inventory Scout Messages - Spanish',
            VERSION  => '2.1.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.msg.fr_FR.rte',
            COMMENTS => 'Inventory Scout Messages - French',
            VERSION  => '2.1.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.msg.it_IT.rte',
            COMMENTS => 'Inventory Scout Messages - Italian',
            VERSION  => '2.1.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.rte',
            COMMENTS => 'Inventory Scout Runtime',
            VERSION  => '2.2.0.7',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ldap.client.adt',
            COMMENTS => 'Directory Client SDK',
            VERSION  => '5.2.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ldap.client.rte',
            COMMENTS => 'Directory Client Runtime (No SSL)',
            VERSION  => '5.2.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ldap.html.fr_FR.config',
            COMMENTS => 'Directory Install/Config Gd-French',
            VERSION  => '5.2.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ldap.html.fr_FR.man',
            COMMENTS => 'Directory Man Pages - French',
            VERSION  => '5.2.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ldap.msg.fr_FR',
            COMMENTS => 'Directory Messages - French',
            VERSION  => '5.2.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'neciStorage.rte',
            COMMENTS => 'NEC runtime for AIX',
            VERSION  => '1.0.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'perfagent.tools',
            COMMENTS => 'Local Performance Analysis & Control Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'perl.libext',
            COMMENTS => 'Perl Library Extensions',
            VERSION  => '2.1.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'perl.rte',
            COMMENTS => 'Perl Version 5 Runtime Environment',
            VERSION  => '5.8.2.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull1015.com',
            COMMENTS => 'BULL Common Generic for HP-pcl5 and HP-pgl2 Emulations',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull1015.rte',
            COMMENTS => 'Bull Compuprint PageMaster 1015',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull1021.rte',
            COMMENTS => 'Bull Compuprint PageMaster 1021',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull1025.rte',
            COMMENTS => 'Bull Compuprint PageMaster 1025',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull1070.rte',
            COMMENTS => 'Bull Compuprint PageMaster 1070',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull1625.rte',
            COMMENTS => 'Bull Compuprint PageMaster 1625',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull200.rte',
            COMMENTS => 'Bull Compuprint PageMaster 200',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull201.rte',
            COMMENTS => 'Bull Compuprint PageMaster 201',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull411.rte',
            COMMENTS => 'Bull Compuprint PageMaster 411',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull413.rte',
            COMMENTS => 'Bull Compuprint PageMaster 413',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull422.rte',
            COMMENTS => 'Bull Compuprint PageMaster 422',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull451.rte',
            COMMENTS => 'Bull Compuprint 4/51',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull454.rte',
            COMMENTS => 'Bull Compuprint 4/54',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull721.rte',
            COMMENTS => 'Bull Compuprint PageMaster 721',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull815.rte',
            COMMENTS => 'Bull Compuprint PageMaster 815',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull825.rte',
            COMMENTS => 'Bull Compuprint PageMaster 825',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull9142.rte',
            COMMENTS => 'Bull Compuprint 914',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull9148.rte',
            COMMENTS => 'Bull Compuprint 914 N',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull922.com',
            COMMENTS => 'BULL Common Generic Epson predef File',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull922.rte',
            COMMENTS => 'Bull Compuprint PageMaster 922',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull923.rte',
            COMMENTS => 'Bull Compuprint PageMaster 923',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull924.rte',
            COMMENTS => 'Bull Compuprint PageMaster 924',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull924N.rte',
            COMMENTS => 'Bull Compuprint PageMaster 924 N',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull956.rte',
            COMMENTS => 'Bull Compuprint 956',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull970.com',
            COMMENTS => 'Common Bull 970/1070 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bull970.rte',
            COMMENTS => 'Bull Compuprint PageMaster 970',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bullpr88-vfu.rte',
            COMMENTS => 'Bull PR-88 VFU Handling',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bullpr88.rte',
            COMMENTS => 'Bull PR-88',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.bullpr90.rte',
            COMMENTS => 'Bull PR-90',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.canlbp-A404F_JP.rte',
            COMMENTS => 'Canon Laser Shot LBP-A404F Japan Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.canlbp-A404PS.rte',
            COMMENTS => 'Canon Laser Shot LBP-A404PS/Lite',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.canlbp-B406G.rte',
            COMMENTS => 'Canon Laser Shot LBP-B406G',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.canlbp.rte',
            COMMENTS => 'Canon Laser Shot LBP-B406/S/D,A404',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.dp2000.rte',
            COMMENTS => 'Dataproducts BP2000 Line Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.dp2665.rte',
            COMMENTS => 'Dataproducts LZR 2665 Laser Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.epsonLQ1600K_CN.rte',
            COMMENTS => 'Epson LQ1600K Chinese (Simplified) Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.escpj84_JP.rte',
            COMMENTS => 'ESC/P J84 Printer Support Japan Data Stream',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hindi.rte',
            COMMENTS => 'Hindi UTF-8 Datastream Printing',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hpJetDirect.attach',
            COMMENTS => 'Hewlett-Packard JetDirect Network Printer Attachment',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-2.rte',
            COMMENTS => 'Hewlett-Packard LaserJet II',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-2500C.rte',
            COMMENTS => 'Hewlett-Packard 2500C Color Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-2p_CN.rte',
            COMMENTS => 'Hewlett-Packard LaserJet IIP Simplified Chinese Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-3.rte',
            COMMENTS => 'Hewlett-Packard LaserJet III',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-3si.rte',
            COMMENTS => 'Hewlett-Packard LaserJet IIISi',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-4+.rte',
            COMMENTS => 'Hewlett-Packard LaserJet 4 Plus',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-4+_KR.rte',
            COMMENTS => 'Hewlett-Packard 4+ Korean Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-4.rte',
            COMMENTS => 'Hewlett-Packard LaserJet 4',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-4000.rte',
            COMMENTS => 'Hewlett-Packard LaserJet 4000',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-4000_KR.rte',
            COMMENTS => 'Hewlett-Packard 4000 Korean Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-4500.rte',
            COMMENTS => 'Hewlett-Packard Color LaserJet 4500',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-4_KR.rte',
            COMMENTS => 'Hewlett-Packard 4 Korean Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-4si.rte',
            COMMENTS => 'Hewlett-Packard LaserJet 4si',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-4si_KR.rte',
            COMMENTS => 'Hewlett-Packard 4si Korean Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-4v.rte',
            COMMENTS => 'Hewlett-Packard LaserJet 4V',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-4v_KR.rte',
            COMMENTS => 'Hewlett-Packard 4V Korean Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-5si.rte',
            COMMENTS => 'Hewlett-Packard LaserJet 5si',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-5siMopier.rte',
            COMMENTS => 'Hewlett-Packard LaserJet 5si Mopier',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-5siMopier_KR.rte',
            COMMENTS => 'Hewlett-Packard 5siMopier Korean Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-5si_KR.rte',
            COMMENTS => 'Hewlett-Packard 5si Korean Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-8000.rte',
            COMMENTS => 'Hewlett-Packard LaserJet 8000',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-8100.rte',
            COMMENTS => 'Hewlett-Packard LaserJet 8100',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-8500.rte',
            COMMENTS => 'Hewlett-Packard Color LaserJet 8500',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-D640.rte',
            COMMENTS => 'Hewlett-Packard LaserJet 5000 D640 Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-UTF8.rte',
            COMMENTS => 'Hewlett Packard LaserJet IIp UTF-8 Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.hplj-c.rte',
            COMMENTS => 'Hewlett-Packard LaserJet Color',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm-pages_JP.rte',
            COMMENTS => 'IBM PAGES Printers Japan Data Stream',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm2380-2.rte',
            COMMENTS => 'IBM 2380 Plus printer (Model 2)',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm2380.rte',
            COMMENTS => 'IBM 2380 Personal Printer II',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm2381-2.rte',
            COMMENTS => 'IBM 2381 Plus printer (Model 2)',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm2381.rte',
            COMMENTS => 'IBM 2381 Personal Printer II',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm2390-2.rte',
            COMMENTS => 'IBM 2390 Plus printer (Model 2)',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm2390.rte',
            COMMENTS => 'IBM 2390 Personal Printer II',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm2391-2.rte',
            COMMENTS => 'IBM 2391 Plus printer (Model 2)',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm2391.rte',
            COMMENTS => 'IBM 2391 Personal Printer II',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm3112.rte',
            COMMENTS => 'IBM 3112 Page Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm3116.rte',
            COMMENTS => 'IBM 3116 Page Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm3130.rte',
            COMMENTS => 'IBM 3130 LaserPrinter',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm3812-2.rte',
            COMMENTS => 'IBM 3812 Model 2 Page Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm3816.rte',
            COMMENTS => 'IBM 3816 Page Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4019.rte',
            COMMENTS => 'IBM 4019 LaserPrinter',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4019_AR.rte',
            COMMENTS => 'IBM 4019 LaserPrinter Arabic Printer Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4019_JP.rte',
            COMMENTS => 'IBM 4019 LaserPrinter Japanese Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4019_KR.rte',
            COMMENTS => 'IBM 4019 LaserPrinter Korean Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4029.rte',
            COMMENTS => 'IBM 4029 LaserPrinter',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4029_JP.rte',
            COMMENTS => 'IBM 4029 LaserPrinter Japanese Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4037.rte',
            COMMENTS => 'IBM 4037 LP printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4039.rte',
            COMMENTS => 'IBM 4039 LaserPrinter',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4070.rte',
            COMMENTS => 'IBM 4070 IJ Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4072.rte',
            COMMENTS => 'IBM 4072 ExecJet',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4076.rte',
            COMMENTS => 'IBM 4076 IJ printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4079.rte',
            COMMENTS => 'IBM 4079 Color Jetprinter PS',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4201-2.rte',
            COMMENTS => 'IBM 4201 Model 2 Proprinter II',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4201-3.rte',
            COMMENTS => 'IBM 4201 Model 3 Proprinter III',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4202-2.rte',
            COMMENTS => 'IBM 4202 Model 2 Proprinter II XL',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4202-3.rte',
            COMMENTS => 'IBM 4202 Model 3 Proprinter III XL',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4207-2.rte',
            COMMENTS => 'IBM 4207 Model 2 Proprinter X24E',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4208-2.rte',
            COMMENTS => 'IBM 4208 Model 2 Proprinter XL24E',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4208-502.rte',
            COMMENTS => 'IBM 4208 Model 502 Proprinter XL24EK',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4212.rte',
            COMMENTS => 'IBM 4212 Proprinter 24P',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4216-31.rte',
            COMMENTS => 'IBM 4216 Personal Page Printer, Model 031',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4216-510.rte',
            COMMENTS => 'IBM 4216 Model 510',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4224.rte',
            COMMENTS => 'IBM 4224 Printer, Models 301, 302, 3C2, 3E3',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4226.rte',
            COMMENTS => 'IBM 4226 Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4234.rte',
            COMMENTS => 'IBM 4234 Dot Band Printer, Model 013',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4234_AR.rte',
            COMMENTS => 'IBM 4234 Dot Band Printer, Model 13 Arabic Printer Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4247.rte',
            COMMENTS => 'IBM 4247 Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4247_HI.rte',
            COMMENTS => 'IBM 4247 Printer - Hindi UTF-8 Datastream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4303.rte',
            COMMENTS => 'IBM Network Color Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4312.rte',
            COMMENTS => 'IBM Network Printer 12',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4317.rte',
            COMMENTS => 'IBM Network Printer 17',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4320.rte',
            COMMENTS => 'IBM InfoPrint 20',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4324.rte',
            COMMENTS => 'IBM Network Printer 24',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4332.rte',
            COMMENTS => 'IBM InfoPrint 32',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4332_HI.rte',
            COMMENTS => 'IBM InfoPrint32 Hindi UTF-8 Datastream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm4340.rte',
            COMMENTS => 'IBM InfoPrint 40',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5202.rte',
            COMMENTS => 'IBM 5202 Quietwriter III',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5204.rte',
            COMMENTS => 'IBM 5204 Quickwriter',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5327.rte',
            COMMENTS => 'IBM 5327 Model 011',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5572.rte',
            COMMENTS => 'IBM 5572 Model B02',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5573.rte',
            COMMENTS => 'IBM 5573 Model H02',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5575.com',
            COMMENTS => 'IBM 5575 Model B02/F02 Device Driver',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5575_KR.rte',
            COMMENTS => 'IBM 5575 Model B02/F02 Korean Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5575_TW.rte',
            COMMENTS => 'IBM 5575 Model B02/F02 Traditional Chinese Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5577.com',
            COMMENTS => 'IBM 5577 Model B02/F02/H02/G02/FU2/J02/K02 Device Driver',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5577_KR.rte',
            COMMENTS => 'IBM 5577 Model B02/F02/H02/G02/FU2 Korean Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5577_TW.rte',
            COMMENTS => 'IBM 5577 Model B02/F02/H02/G02/FU2 Trad. Chinese Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5579.rte',
            COMMENTS => 'IBM 5579 Model H02/K02',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5584.rte',
            COMMENTS => 'IBM 5584 Model G02/H02',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5585.com',
            COMMENTS => 'IBM 5585 Model H01 Device Driver',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5585_TW.rte',
            COMMENTS => 'IBM 5585 Model H01 Traditional Chinese Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5587.rte',
            COMMENTS => 'IBM 5587 Model G01',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5587H.rte',
            COMMENTS => 'IBM 5587 Model H01',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm5589.rte',
            COMMENTS => 'IBM 5589 Model H01',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm6180.rte',
            COMMENTS => 'IBM 6180 Color Plotter',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm6182.rte',
            COMMENTS => 'IBM 6182 Auto Feed Color Plotter',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm6184.rte',
            COMMENTS => 'IBM 6184 Color Plotter',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm6185-1.rte',
            COMMENTS => 'IBM 6185-1 Color Plotter',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm6185-2.rte',
            COMMENTS => 'IBM 6185-2 Color Plotter',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm6186.rte',
            COMMENTS => 'IBM 6186 Color Plotter',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm6252.rte',
            COMMENTS => 'IBM 6252 Impactwriter',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm6262.rte',
            COMMENTS => 'IBM 6262 Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm6400.rte',
            COMMENTS => 'IBM 6400 Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm6400_HI.rte',
            COMMENTS => 'IBM 6400 Printer - Hindi UTF-8 Datastream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibm7372.rte',
            COMMENTS => 'IBM 7372 Color Plotter',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibmNetColor.attach',
            COMMENTS => 'IBM Network Color Printer Attachment',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibmNetPrinter.attach',
            COMMENTS => 'IBM Network Printer Attachment',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibmgb18030_CN.rte',
            COMMENTS => 'General Printer GB18030 Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ibmuniversal.rte',
            COMMENTS => 'Universal Printer UTF-8 Data Stream',
            VERSION  => '5.3.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lex2380-3.rte',
            COMMENTS => 'Lexmark 2380 Plus printer (Model 3)',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lex2381-3.rte',
            COMMENTS => 'Lexmark 2381 Plus printer (Model 3)',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lex2390-3.rte',
            COMMENTS => 'Lexmark 2390 Plus printer (Model 3)',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lex2391-3.rte',
            COMMENTS => 'Lexmark 2391 Plus printer (Model 3)',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lex4039+.rte',
            COMMENTS => 'Lexmark 4039 plus LaserPrinter',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lex4047.rte',
            COMMENTS => 'Lexmark ValueWriter 600',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lex4049.rte',
            COMMENTS => 'Lexmark Optra LaserPrinter',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lex4076-2c.rte',
            COMMENTS => 'Lexmark ExecJet IIc',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lex4079+.rte',
            COMMENTS => 'Lexmark 4079 Color Jetprinter Plus',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lex4227.rte',
            COMMENTS => 'Lexmark Forms Printer 4227',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptra+.rte',
            COMMENTS => 'Lexmark Optra Plus Laser Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptraC.rte',
            COMMENTS => 'Lexmark Optra C Color Laser Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptraC1200.rte',
            COMMENTS => 'Lexmark Optra Color 1200 Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptraC40.rte',
            COMMENTS => 'Lexmark Optra Color 40 Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptraC45.rte',
            COMMENTS => 'Lexmark Optra Color 45 Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptraE.rte',
            COMMENTS => 'Lexmark Optra E Laser Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptraE310.rte',
            COMMENTS => 'Lexmark Optra E310 Laser Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptraEp.rte',
            COMMENTS => 'Lexmark Optra Ep Laser Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptraK12.rte',
            COMMENTS => 'Lexmark Optra K 1220 Laser Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptraM410.rte',
            COMMENTS => 'Lexmark Optra M410 Laser Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptraN.rte',
            COMMENTS => 'Lexmark Optra N Laser Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptraS.rte',
            COMMENTS => 'Lexmark Optra S Laser Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptraSC.rte',
            COMMENTS => 'Lexmark Optra SC Color Laser Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptraSe.rte',
            COMMENTS => 'Lexmark Optra Se Laser Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptraT.rte',
            COMMENTS => 'Lexmark Optra T Laser Printer Family',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lexOptraW810.rte',
            COMMENTS => 'Lexmark Optra W810 Laser Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.lips4_JP.rte',
            COMMENTS => 'LIPS4 Printers Japan Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.msg.de_DE.rte',
            COMMENTS => 'Printer Backend Messages - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.msg.en_US.rte',
            COMMENTS => 'Printer Backend Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.msg.es_ES.rte',
            COMMENTS => 'Printer Backend Messages - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.msg.fr_FR.rte',
            COMMENTS => 'Printer Backend Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.msg.it_IT.rte',
            COMMENTS => 'Printer Backend Messages - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.oki400ps2_JP.rte',
            COMMENTS => 'OKI Japanese PostScript Printers Japan Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.oki801ps.rte',
            COMMENTS => 'OKI Microline 801PS, 801PS-F, 801PSII/-F, 800PSIILT',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.p9012.rte',
            COMMENTS => 'Printronix P9012 Line Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.qms100.rte',
            COMMENTS => 'QMS ColorScript 100, Model 20',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.rte',
            COMMENTS => 'Printer Backend',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.starAR2463_CN.rte',
            COMMENTS => 'Star AR2463 Chinese (Simplified) Data Stream',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.ti2115.rte',
            COMMENTS => 'Texas Instruments OmniLaser 2115 Page Printer',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rpm.rte',
            COMMENTS => 'RPM Package Manager',
            VERSION  => '3.0.5.39',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.basic.hacmp',
            COMMENTS => 'RSCT Basic Function (HACMP/ES Support)',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.basic.rte',
            COMMENTS => 'RSCT Basic Function',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.basic.sp',
            COMMENTS => 'RSCT Basic Function (PSSP Support)',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.clients.rte',
            COMMENTS => 'Supersede Entry - Not really installed',
            VERSION  => '99.99.999.999',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.compat.basic.hacmp',
            COMMENTS => 'RSCT Event Management Basic Function (HACMP/ES Support)',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.compat.basic.rte',
            COMMENTS => 'RSCT Event Management Basic Function',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.compat.basic.sp',
            COMMENTS => 'RSCT Event Management Basic Function (PSSP Support)',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.compat.clients.hacmp',
            COMMENTS => 'RSCT Event Management Client Function (HACMP/ES Support)',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.compat.clients.rte',
            COMMENTS => 'RSCT Event Management Client Function',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.compat.clients.sp',
            COMMENTS => 'RSCT Event Management Client Function (PSSP Support)',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.auditrm',
            COMMENTS => 'RSCT Audit Log Resource Manager',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.errm',
            COMMENTS => 'RSCT Event Response Resource Manager',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.fsrm',
            COMMENTS => 'RSCT File System Resource Manager',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.gui',
            COMMENTS => 'RSCT Graphical User Interface',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.hostrm',
            COMMENTS => 'RSCT Host Resource Manager',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.lprm',
            COMMENTS => 'RSCT Least Privilege Resource Manager',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.rmc',
            COMMENTS => 'RSCT Resource Monitoring and Control',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.sec',
            COMMENTS => 'RSCT Security',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.sensorrm',
            COMMENTS => 'RSCT Sensor Resource Manager',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.sr',
            COMMENTS => 'RSCT Registry',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.utils',
            COMMENTS => 'RSCT Utilities',
            VERSION  => '2.4.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.DE_DE.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - German (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.DE_DE.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - German (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.DE_DE.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - German (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.DE_DE.core.gui',
            COMMENTS => 'RSCT GUI Msgs - German (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.DE_DE.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - German (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.DE_DE.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - German (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.DE_DE.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - German (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.DE_DE.core.sec',
            COMMENTS => 'RSCT Security Msgs - German (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.DE_DE.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - German (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.DE_DE.core.sr',
            COMMENTS => 'RSCT Registry Msgs - German (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.DE_DE.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - German (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - U.S. English (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - U.S. English (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - U.S. English (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.gui',
            COMMENTS => 'RSCT GUI Msgs - U.S. English (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - U.S. English (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - U.S. English (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - U.S. English (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.sec',
            COMMENTS => 'RSCT Security Msgs - U.S. English (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - U.S. English (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.sr',
            COMMENTS => 'RSCT Registry Msgs - U.S. English (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - U.S. English (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.ES_ES.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - Spanish (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.ES_ES.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - Spanish (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.ES_ES.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - Spanish (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.ES_ES.core.gui',
            COMMENTS => 'RSCT GUI Msgs - Spanish (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.ES_ES.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - Spanish (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.ES_ES.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - Spanish (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.ES_ES.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - Spanish (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.ES_ES.core.sec',
            COMMENTS => 'RSCT Security Msgs - Spanish (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.ES_ES.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - Spanish (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.ES_ES.core.sr',
            COMMENTS => 'RSCT Registry Msgs - Spanish (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.ES_ES.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - Spanish (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.gui',
            COMMENTS => 'RSCT GUI Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.sec',
            COMMENTS => 'RSCT Security Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.sr',
            COMMENTS => 'RSCT Registry Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.IT_IT.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - Italian (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.IT_IT.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - Italian (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.IT_IT.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - Italian (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.IT_IT.core.gui',
            COMMENTS => 'RSCT GUI Msgs - Italian (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.IT_IT.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - Italian (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.IT_IT.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - Italian (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.IT_IT.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - Italian (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.IT_IT.core.sec',
            COMMENTS => 'RSCT Security Msgs - Italian (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.IT_IT.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - Italian (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.IT_IT.core.sr',
            COMMENTS => 'RSCT Registry Msgs - Italian (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.IT_IT.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - Italian (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.de_DE.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - German',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.de_DE.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - German',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.de_DE.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - German',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.de_DE.core.gui',
            COMMENTS => 'RSCT GUI Msgs - German',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.de_DE.core.gui.com',
            COMMENTS => 'RSCT GUI JAVA Msgs - German',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.de_DE.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - German',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.de_DE.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - German',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.de_DE.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - German',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.de_DE.core.rmc.com',
            COMMENTS => 'RSCT RMC JAVA Msgs - German',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.de_DE.core.sec',
            COMMENTS => 'RSCT Security Msgs - German',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.de_DE.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - German',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.de_DE.core.sr',
            COMMENTS => 'RSCT Registry Msgs - German',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.de_DE.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - German',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.basic.rte',
            COMMENTS => 'RSCT Basic Msgs - U.S. English',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - U.S. English',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - U.S. English',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - U.S. English',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.gui',
            COMMENTS => 'RSCT GUI Msgs - U.S. English',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.gui.com',
            COMMENTS => 'RSCT GUI JAVA Msgs - U.S. English',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - U.S. English',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - U.S. English',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - U.S. English',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.rmc.com',
            COMMENTS => 'RSCT RMC JAVA Msgs - U.S. English',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.sec',
            COMMENTS => 'RSCT Security Msgs - U.S. English',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - U.S. English',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.sr',
            COMMENTS => 'RSCT Registry Msgs - U.S. English',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - U.S. English',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.es_ES.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - Spanish',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.es_ES.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - Spanish',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.es_ES.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - Spanish',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.es_ES.core.gui',
            COMMENTS => 'RSCT GUI Msgs - Spanish',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.es_ES.core.gui.com',
            COMMENTS => 'RSCT GUI JAVA Msgs - Spanish',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.es_ES.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - Spanish',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.es_ES.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - Spanish',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.es_ES.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - Spanish',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.es_ES.core.rmc.com',
            COMMENTS => 'RSCT RMC JAVA Msgs - Spanish',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.es_ES.core.sec',
            COMMENTS => 'RSCT Security Msgs - Spanish',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.es_ES.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - Spanish',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.es_ES.core.sr',
            COMMENTS => 'RSCT Registry Msgs - Spanish',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.es_ES.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - Spanish',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.basic.rte',
            COMMENTS => 'RSCT Basic Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.gui',
            COMMENTS => 'RSCT GUI Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.gui.com',
            COMMENTS => 'RSCT GUI JAVA Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.rmc.com',
            COMMENTS => 'RSCT RMC JAVA Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.sec',
            COMMENTS => 'RSCT Security Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.sr',
            COMMENTS => 'RSCT Registry Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.it_IT.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - Italian',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.it_IT.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - Italian',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.it_IT.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - Italian',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.it_IT.core.gui',
            COMMENTS => 'RSCT GUI Msgs - Italian',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.it_IT.core.gui.com',
            COMMENTS => 'RSCT GUI JAVA Msgs - Italian',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.it_IT.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - Italian',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.it_IT.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - Italian',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.it_IT.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - Italian',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.it_IT.core.rmc.com',
            COMMENTS => 'RSCT RMC JAVA Msgs - Italian',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.it_IT.core.sec',
            COMMENTS => 'RSCT Security Msgs - Italian',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.it_IT.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - Italian',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.it_IT.core.sr',
            COMMENTS => 'RSCT Registry Msgs - Italian',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.it_IT.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - Italian',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsf.extended',
            COMMENTS => 'Extended Remote Services Facilities',
            VERSION  => '3.11.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsf.extended.snmp',
            COMMENTS => 'SNMP daemon for extended RSF',
            VERSION  => '3.11.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsf.rsflite',
            COMMENTS => 'RSF Remote Services Facilities',
            VERSION  => '3.11.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsf.rsflite.websm',
            COMMENTS => 'RSF WebSM Remote Services Facilities',
            VERSION  => '3.11.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'smw.oem',
            COMMENTS => 'OEMSMW SM',
            VERSION  => '1.1.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'smw.websm',
            COMMENTS => 'WatchWare SM',
            VERSION  => '2.1.2.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.help.de_DE.websm',
            COMMENTS => 'WebSM Extended Helps - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.help.en_US.websm',
            COMMENTS => 'WebSM Extended Helps - U.S. English',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.help.es_ES.websm',
            COMMENTS => 'WebSM Extended Helps - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.help.fr_FR.websm',
            COMMENTS => 'WebSM Extended Helps - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.help.it_IT.websm',
            COMMENTS => 'WebSM Extended Helps - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.help.msg.de_DE.websm',
            COMMENTS => 'WebSM Context Helps - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.help.msg.en_US.websm',
            COMMENTS => 'WebSM Context Helps - U.S. English',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.help.msg.es_ES.websm',
            COMMENTS => 'WebSM Context Helps - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.help.msg.fr_FR.websm',
            COMMENTS => 'WebSM Context Helps - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.help.msg.it_IT.websm',
            COMMENTS => 'WebSM Context Helps - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.msg.de_DE.sguide.rte',
            COMMENTS => 'TaskGuide Viewer Messages - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.msg.de_DE.websm.apps',
            COMMENTS => 'WebSM Client Apps. Messages - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.msg.en_US.sguide.rte',
            COMMENTS => 'TaskGuide Viewer Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.msg.en_US.websm.apps',
            COMMENTS => 'WebSM Client Apps. Messages - U.S. English',
            VERSION  => '5.3.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.msg.es_ES.sguide.rte',
            COMMENTS => 'TaskGuide Viewer Messages - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.msg.es_ES.websm.apps',
            COMMENTS => 'WebSM Client Apps. Messages - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.msg.fr_FR.sguide.rte',
            COMMENTS => 'TaskGuide Viewer Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.msg.fr_FR.websm.apps',
            COMMENTS => 'WebSM Client Apps. Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.msg.it_IT.sguide.rte',
            COMMENTS => 'TaskGuide Viewer Messages - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.msg.it_IT.websm.apps',
            COMMENTS => 'WebSM Client Apps. Messages - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.sguide.rte',
            COMMENTS => 'TaskGuide Runtime Environment',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.apps',
            COMMENTS => 'Web-based System Manager Applications',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.diag',
            COMMENTS => 'Web-based System Manager Diagnostic Applications',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.framework',
            COMMENTS => 'Web-based System Manager Client/Server Support',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.icons',
            COMMENTS => 'Web-based System Manager Icons',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.rte',
            COMMENTS => 'Web-based System Manager Runtime Environment',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.webaccess',
            COMMENTS => 'WebSM Web Access Enablement',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgtlib.framework.core',
            COMMENTS => 'System Management Service Libraries Common Code',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgtlib.libraries.apps',
            COMMENTS => 'System Management Service Libraries Application Code',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.aix50.rte',
            COMMENTS => 'C Set ++ Runtime for AIX 5.0',
            VERSION  => '6.0.0.13',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.cpp',
            COMMENTS => 'C for AIX Preprocessor',
            VERSION  => '6.0.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.msg.en_US.cpp',
            COMMENTS => 'C for AIX Preprocessor Messages--U.S. English',
            VERSION  => '6.0.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.msg.en_US.rte',
            COMMENTS => 'C Set ++ Runtime Messages--U.S. English',
            VERSION  => '6.0.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.rte',
            COMMENTS => 'C Set ++ Runtime',
            VERSION  => '6.0.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'BULLENH_VERSION',
            COMMENTS => 'For BULLENH installation refer to SRB.',
            VERSION  => '5.30.5.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'EMC.CLARiiON.fcp.rte',
            COMMENTS => 'EMC CLARiiON Fibre Channel Support Software',
            VERSION  => '5.2.0.3',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'EMC.Symmetrix.aix.rte',
            COMMENTS => 'EMC Symmetrix AIX Support Software',
            VERSION  => '5.2.0.3',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'EMC.Symmetrix.fcp.rte',
            COMMENTS => 'EMC Symmetrix Fibre Channel Support Software',
            VERSION  => '5.2.0.3',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'NAVIERRLOG',
            COMMENTS => 'Navisphere Errlogger',
            VERSION  => '5.1.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'Tivoli_Management_Agent.client.rte',
            COMMENTS => 'Management Framework Endpoint Runtime"',
            VERSION  => '3.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.Dt.ToolTalk',
            COMMENTS => 'AIX CDE ToolTalk Support',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.Dt.bitmaps',
            COMMENTS => 'AIX CDE Bitmaps',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.Dt.helpinfo',
            COMMENTS => 'AIX CDE Help Files and Volumes',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.Dt.helpmin',
            COMMENTS => 'AIX CDE Minimum Help Files',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.Dt.rte',
            COMMENTS => 'AIX Common Desktop Environment (CDE) 1.0',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.base.rte',
            COMMENTS => 'AIXwindows Runtime Environment',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.base.smt',
            COMMENTS => 'AIXwindows Runtime Shared Memory Transport',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.loc.de_DE.Dt.rte',
            COMMENTS => 'CDE Locale Configuration - German',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.loc.en_US.Dt.rte',
            COMMENTS => 'CDE Locale Configuration - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.loc.es_ES.Dt.rte',
            COMMENTS => 'CDE Locale Configuration - Spanish',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.loc.fr_FR.Dt.rte',
            COMMENTS => 'CDE Locale Configuration - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.loc.it_IT.Dt.rte',
            COMMENTS => 'CDE Locale Configuration - Italian',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.64bit',
            COMMENTS => 'Base Operating System 64 bit Runtime',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.acct',
            COMMENTS => 'Accounting Services',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.cdmount',
            COMMENTS => 'CD/DVD Automount Facility',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.cifs_fs.rte',
            COMMENTS => 'Runtime for SMBFS',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.cifs_fs.smit',
            COMMENTS => 'SMIT Interface for SMBFS',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.compat.links',
            COMMENTS => 'AIX 3.2 to 4 Compatibility Links',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.compat.net',
            COMMENTS => 'AIX 3.2 TCP/IP Compatability Commands',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.compat.termcap',
            COMMENTS => 'AIX 3.2 Termcap Source and Library',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.com',
            COMMENTS => 'Common Hardware Diagnostics',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.rte',
            COMMENTS => 'Hardware Diagnostics',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.util',
            COMMENTS => 'Hardware Diagnostics Utilities',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.mh',
            COMMENTS => 'Mail Handler',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.mp',
            COMMENTS => 'Base Operating System Multiprocessor Runtime',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.mp64',
            COMMENTS => 'Base Operating System 64-bit Multiprocessor Runtime',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ewlm.rte',
            COMMENTS => 'netWLM',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ipsec.keymgt',
            COMMENTS => 'IP Security Key Management',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ipsec.rte',
            COMMENTS => 'IP Security',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ipsec.websm',
            COMMENTS => 'IP Security WebSM',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.mobip6.rte',
            COMMENTS => 'IPv6 Mobility',
            VERSION  => '5.3.0.10',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ncs',
            COMMENTS => 'Network Computing System 1.5.1',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.cachefs',
            COMMENTS => 'CacheFS File System',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.client',
            COMMENTS => 'Network File System Client',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.nis.client',
            COMMENTS => 'Network Information Service Client',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.nis.server',
            COMMENTS => 'Network Information Service Server',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.nisplus',
            COMMENTS => 'Network Information Services Plus (NIS+)',
            VERSION  => '5.3.0.10',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ppp',
            COMMENTS => 'Async Point to Point Protocol',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.snapp',
            COMMENTS => 'System Networking Analysis and Performance Pilot',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.client',
            COMMENTS => 'TCP/IP Client Support',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.server',
            COMMENTS => 'TCP/IP Server',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.uucp',
            COMMENTS => 'Unix to Unix Copy Program',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.diag_tool',
            COMMENTS => 'Performance Diagnostic Tool',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.libperfstat',
            COMMENTS => 'Performance Statistics Library Interface',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.perfstat',
            COMMENTS => 'Performance Statistics Interface',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.tools',
            COMMENTS => 'Base Performance Tools',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.tune',
            COMMENTS => 'Performance Tuning Support',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.pmapi.pmsvcs',
            COMMENTS => 'Performance Monitor API Kernel Extension',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte',
            COMMENTS => 'Base Operating System Runtime',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.Dt',
            COMMENTS => 'Desktop Integrator',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.SRC',
            COMMENTS => 'System Resource Controller',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.aio',
            COMMENTS => 'Asynchronous I/O Extension',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.archive',
            COMMENTS => 'Archive Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.boot',
            COMMENTS => 'Boot Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.commands',
            COMMENTS => 'Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.control',
            COMMENTS => 'System Control Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.cron',
            COMMENTS => 'Batch Operations',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.devices',
            COMMENTS => 'Base Device Drivers',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.diag',
            COMMENTS => 'Diagnostics',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.filesystem',
            COMMENTS => 'Filesystem Administration',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.jfscomp',
            COMMENTS => 'JFS Compression',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.lvm',
            COMMENTS => 'Logical Volume Manager',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.printers',
            COMMENTS => 'Front End Printer Support',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.security',
            COMMENTS => 'Base Security Function',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.serv_aid',
            COMMENTS => 'Error Log Service Aids',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.shell',
            COMMENTS => 'Shells (bsh, ksh, csh)',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.tty',
            COMMENTS => 'Base TTY Support and Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.suma',
            COMMENTS => 'Service Update Management Assistant (SUMA)',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.svpkg',
            COMMENTS => 'System V Packaging and Installation Tools',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.svprint.ps',
            COMMENTS => 'System V Print Postscript',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.loginlic',
            COMMENTS => 'License Management',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.nim.client',
            COMMENTS => 'Network Install Manager - Client Tools',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.serv_aid',
            COMMENTS => 'Software Error Logging and Dump Service Aids',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.sysbr',
            COMMENTS => 'System Backup and BOS Install Utilities',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.trace',
            COMMENTS => 'Software Trace Service Aids',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bullasync.base.rte',
            COMMENTS => 'Bull Common Asynchronous Adapter Software',
            VERSION  => '1.8.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bullasync.pci.rte',
            COMMENTS => 'Bull PCI Asynchronous Adapter Software',
            VERSION  => '1.8.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.client',
            COMMENTS => 'Cluster Systems Management Client',
            VERSION  => '1.4.1.10',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.core',
            COMMENTS => 'Cluster Systems Management Core',
            VERSION  => '1.4.1.10',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.diagnostics',
            COMMENTS => 'Cluster Systems Management Probe Manager / Diagnostics',
            VERSION  => '1.4.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.dsh',
            COMMENTS => 'Cluster Systems Management Dsh',
            VERSION  => '1.4.1.10',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'ifor_ls.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'invscout.com',
            COMMENTS => 'Inventory Scout Microcode Catalog',
            VERSION  => '2.2.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'invscout.ldb',
            COMMENTS => 'Inventory Scout Logic Database',
            VERSION  => '2.2.0.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'invscout.rte',
            COMMENTS => 'Inventory Scout Runtime',
            VERSION  => '2.2.0.7',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'ldap.client.rte',
            COMMENTS => 'Directory Client Runtime (No SSL)',
            VERSION  => '5.2.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'neciStorage.rte',
            COMMENTS => 'NEC runtime for AIX',
            VERSION  => '1.0.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'perfagent.tools',
            COMMENTS => 'Local Performance Analysis & Control Commands',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'printers.rte',
            COMMENTS => 'Printer Backend',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rpm.rte',
            COMMENTS => 'RPM Package Manager',
            VERSION  => '3.0.5.39',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.basic.rte',
            COMMENTS => 'RSCT Basic Function',
            VERSION  => '2.4.3.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.compat.basic.rte',
            COMMENTS => 'RSCT Event Management Basic Function',
            VERSION  => '2.4.3.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.auditrm',
            COMMENTS => 'RSCT Audit Log Resource Manager',
            VERSION  => '2.4.3.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.errm',
            COMMENTS => 'RSCT Event Response Resource Manager',
            VERSION  => '2.4.3.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.fsrm',
            COMMENTS => 'RSCT File System Resource Manager',
            VERSION  => '2.4.3.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.hostrm',
            COMMENTS => 'RSCT Host Resource Manager',
            VERSION  => '2.4.3.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.lprm',
            COMMENTS => 'RSCT Least Privilege Resource Manager',
            VERSION  => '2.4.3.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.rmc',
            COMMENTS => 'RSCT Resource Monitoring and Control',
            VERSION  => '2.4.3.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.sec',
            COMMENTS => 'RSCT Security',
            VERSION  => '2.4.3.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.sensorrm',
            COMMENTS => 'RSCT Sensor Resource Manager',
            VERSION  => '2.4.3.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.sr',
            COMMENTS => 'RSCT Registry',
            VERSION  => '2.4.3.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.utils',
            COMMENTS => 'RSCT Utilities',
            VERSION  => '2.4.3.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsf.extended',
            COMMENTS => 'Extended Remote Services Facilities',
            VERSION  => '3.11.3.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsf.extended.snmp',
            COMMENTS => 'SNMP daemon for extended RSF',
            VERSION  => '3.11.3.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsf.rsflite',
            COMMENTS => 'RSF Remote Services Facilities',
            VERSION  => '3.11.3.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.apps',
            COMMENTS => 'Web-based System Manager Applications',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.framework',
            COMMENTS => 'Web-based System Manager Client/Server Support',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.rte',
            COMMENTS => 'Web-based System Manager Runtime Environment',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.adt.data',
            COMMENTS => 'Base Application Development Toolkit Data',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.compat.termcap.data',
            COMMENTS => 'AIX 3.2 Termcap Source Data',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.adds.data',
            COMMENTS => 'ADDS Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.annarbor.data',
            COMMENTS => 'Annarbor Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.ansi.data',
            COMMENTS => 'Amer National Stds Institute Terminal Defs',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.att.data',
            COMMENTS => 'AT&T Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.beehive.data',
            COMMENTS => 'Beehive Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.bull.data',
            COMMENTS => 'Bull Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.cdc.data',
            COMMENTS => 'Control Data Corp. Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.colorscan.data',
            COMMENTS => 'Datamedia Colorscan Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.com.data',
            COMMENTS => 'Common Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.datamedia.data',
            COMMENTS => 'Datamedia Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.dec.data',
            COMMENTS => 'Digital Equipment Corp. Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.diablo.data',
            COMMENTS => 'Generic Daisy Wheel Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.falco.data',
            COMMENTS => 'Falco Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.fortune.data',
            COMMENTS => 'Fortune Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.general.data',
            COMMENTS => 'General Terminal Corp. Term Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.hardcopy.data',
            COMMENTS => 'Hard Copy Terminals Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.hazeltine.data',
            COMMENTS => 'Hazeltine Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.hds.data',
            COMMENTS => 'Human Designed Systems Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.heath.data',
            COMMENTS => 'Heathkit and Zenith Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.homebrew.data',
            COMMENTS => 'Home-made Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.hp.data',
            COMMENTS => 'Hewlett-Packard Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.ibm.data',
            COMMENTS => 'IBM Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.lsi.data',
            COMMENTS => 'Lear Siegler Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.microterm.data',
            COMMENTS => 'Microterm Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.misc.data',
            COMMENTS => 'Miscellaneous Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.pc.data',
            COMMENTS => 'Personal Computer Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.pci.data',
            COMMENTS => 'DOS Server Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.perkinelmer.data',
            COMMENTS => 'Perkin Elmer Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.pmcons.data',
            COMMENTS => 'PMAX Console Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.print.data',
            COMMENTS => 'Generic Line Printer Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.special.data',
            COMMENTS => 'Special Generic Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.sperry.data',
            COMMENTS => 'Sperry Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.svprint.data',
            COMMENTS => 'System V Printer Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.tektronix.data',
            COMMENTS => 'Tektronix Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.teleray.data',
            COMMENTS => 'Teleray Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.televideo.data',
            COMMENTS => 'Televideo Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.ti.data',
            COMMENTS => 'Texas Instruments Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.tymshare.data',
            COMMENTS => 'Tymshare Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.visual.data',
            COMMENTS => 'Visual Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.wyse.data',
            COMMENTS => 'Wyse Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.bib.data',
            COMMENTS => 'Bibliography Support Data',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.spell.data',
            COMMENTS => 'Writer\'s Tools Data',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.tfs.data',
            COMMENTS => 'Text Formatting Services Data',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'rsf.rsflite.data',
            COMMENTS => 'RSF_data Remote Services Facilities (Data)',
            VERSION  => '3.11.3.0',
            FOLDER   => '/usr/share/lib/objrepos'
        }
    ],
    'aix-5.3b' => [
        {
            NAME     => 'Java14.sdk',
            COMMENTS => 'Java SDK 32-bit',
            VERSION  => '1.4.2.75',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Tivoli_Management_Agent.client.rte',
            COMMENTS => 'Management Framework Endpoint Runtime"',
            VERSION  => '3.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.adt.bitmaps',
            COMMENTS => 'AIXwindows Application Development Toolkit Bitmap Files',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.adt.imake',
            COMMENTS => 'AIXwindows Application Development Toolkit imake',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.adt.include',
            COMMENTS => 'AIXwindows Application Development Toolkit Include Files',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.adt.lib',
            COMMENTS => 'AIXwindows Application Development Toolkit Libraries',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.aixterm',
            COMMENTS => 'AIXwindows aixterm Application',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.clients',
            COMMENTS => 'AIXwindows Client Applications',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.config',
            COMMENTS => 'AIXwindows Configuration Applications',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.custom',
            COMMENTS => 'AIXwindows Customizing Tool',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.msmit',
            COMMENTS => 'AIXwindows msmit Application',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.rte',
            COMMENTS => 'AIXwindows Runtime Configuration Applications',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.util',
            COMMENTS => 'AIXwindows Utility Applications',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.xdm',
            COMMENTS => 'AIXwindows xdm Application',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.xterm',
            COMMENTS => 'AIXwindows xterm Application',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.base.common',
            COMMENTS => 'AIXwindows Runtime Common Directories',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.base.lib',
            COMMENTS => 'AIXwindows Runtime Libraries',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.base.rte',
            COMMENTS => 'AIXwindows Runtime Environment',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.base.smt',
            COMMENTS => 'AIXwindows Runtime Shared Memory Transport',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.base.xpconfig',
            COMMENTS => 'Xprint Configuration Files',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.coreX',
            COMMENTS => 'AIXwindows X Consortium Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.defaultFonts',
            COMMENTS => 'AIXwindows Default Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso1',
            COMMENTS => 'AIXwindows Latin 1 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso_T1',
            COMMENTS => 'AIXwindows Latin Type1 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.en_US.base.lib',
            COMMENTS => 'AIXwindows Client Locale Config - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.en_US.base.rte',
            COMMENTS => 'AIXwindows Locale Configuration - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.fr_FR.base.lib',
            COMMENTS => 'AIXwindows Client Locale Config - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.fr_FR.base.rte',
            COMMENTS => 'AIXwindows Locale Configuration - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.motif.lib',
            COMMENTS => 'AIXwindows Motif Libraries',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.motif.mwm',
            COMMENTS => 'AIXwindows Motif Window Manager',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.adt.imake',
            COMMENTS => 'AIXwindows imake Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.apps.aixterm',
            COMMENTS => 'AIXwindows aixterm Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.apps.clients',
            COMMENTS => 'AIXwindows Client Apps Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.apps.config',
            COMMENTS => 'AIXwindows Config Apps Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.apps.custom',
            COMMENTS => 'AIXwindows Custom Tool Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.apps.rte',
            COMMENTS => 'AIXwindows Runtime Config Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.apps.xdm',
            COMMENTS => 'AIXwindows xdm Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.base.common',
            COMMENTS => 'AIXwindows Common Messages - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.base.rte',
            COMMENTS => 'AIXwindows Runtime Env. Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.motif.lib',
            COMMENTS => 'AIXwindows Motif Lib. Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.motif.mwm',
            COMMENTS => 'AIX Motif Window Mgr Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.en_US.vsm.rte',
            COMMENTS => 'Visual Sys Mgmt. Helps & Msgs - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.adt.imake',
            COMMENTS => 'AIXwindows imake Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.apps.aixterm',
            COMMENTS => 'AIXwindows aixterm Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.apps.clients',
            COMMENTS => 'AIXwindows Client Apps Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.apps.config',
            COMMENTS => 'AIXwindows Config Apps Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.apps.custom',
            COMMENTS => 'AIXwindows Custom Tool Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.apps.rte',
            COMMENTS => 'AIXwindows Runtime Config Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.apps.xdm',
            COMMENTS => 'AIXwindows xdm Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.base.common',
            COMMENTS => 'AIXwindows Common Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.base.rte',
            COMMENTS => 'AIXwindows Runtime Env. Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.motif.lib',
            COMMENTS => 'AIXwindows Motif Lib. Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.motif.mwm',
            COMMENTS => 'AIX Motif Window Mgr Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.msg.fr_FR.vsm.rte',
            COMMENTS => 'Visual Sys Mgmt. Helps & Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.samples.apps.clients',
            COMMENTS => 'AIXwindows Sample X Consortium Clients Binary/Source',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.samples.common',
            COMMENTS => 'AIXwindows Imakefile Structure for Samples',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.samples.lib.Core',
            COMMENTS => 'AIXwindows Sample X Consortium Core Libraries Binary/Source',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.vsm.lib',
            COMMENTS => 'Visual System Managment Library',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.64bit',
            COMMENTS => 'Base Operating System 64 bit Runtime',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.acct',
            COMMENTS => 'Accounting Services',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.base',
            COMMENTS => 'Base Application Development Toolkit',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.include',
            COMMENTS => 'Base Application Development Include Files',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.lib',
            COMMENTS => 'Base Application Development Libraries',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.aixpert.cmds',
            COMMENTS => 'AIX Security Hardening',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.aixpert.websm',
            COMMENTS => 'AIX Security Hardening WebSM',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.alt_disk_install.boot_images',
            COMMENTS => 'Alternate Disk Installation Disk Boot Images',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.alt_disk_install.rte',
            COMMENTS => 'Alternate Disk Installation Runtime',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.cdmount',
            COMMENTS => 'CD/DVD Automount Facility',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.com',
            COMMENTS => 'Common Hardware Diagnostics',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.rte',
            COMMENTS => 'Hardware Diagnostics',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.util',
            COMMENTS => 'Hardware Diagnostics Utilities',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.ecc_client.rte',
            COMMENTS => 'Electronic Customer Care Runtime',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.en_US.com',
            COMMENTS => 'WebSM/SMIT Context Helps - U.S. English',
            VERSION  => '5.3.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.en_US.smit',
            COMMENTS => 'SMIT Context Helps - U.S. English',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.fr_FR.com',
            COMMENTS => 'WebSM/SMIT Context Helps - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.com',
            COMMENTS => 'Common Language to Language Converters',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.fr_FR',
            COMMENTS => 'EBCDIC & ASCII Language Converters - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.ucs.com',
            COMMENTS => 'Unicode Base Converters for AIX Code Sets/Fonts',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.iso.fr_FR',
            COMMENTS => 'Base System Locale ISO Code Set - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mh',
            COMMENTS => 'Mail Handler',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mp',
            COMMENTS => 'Base Operating System Multiprocessor Runtime',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mp64',
            COMMENTS => 'Base Operating System 64-bit Multiprocessor Runtime',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.alt_disk_install.rte',
            COMMENTS => 'Alternate Disk Install Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.diag.rte',
            COMMENTS => 'Hardware Diagnostics Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.mp',
            COMMENTS => 'Base Operating System MP Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.net.ipsec',
            COMMENTS => 'IP Security Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.net.tcp.client',
            COMMENTS => 'TCP/IP Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.rte',
            COMMENTS => 'Base OS Runtime Messages - French',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.txt.tfs',
            COMMENTS => 'Text Formatting Services Msgs - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ipsec.keymgt',
            COMMENTS => 'IP Security Key Management',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ipsec.rte',
            COMMENTS => 'IP Security',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ncs',
            COMMENTS => 'Network Computing System 1.5.1',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.client',
            COMMENTS => 'Network File System Client',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nis.client',
            COMMENTS => 'Network Information Service Client',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.snapp',
            COMMENTS => 'System Networking Analysis and Performance Pilot',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.adt',
            COMMENTS => 'TCP/IP Application Toolkit',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.client',
            COMMENTS => 'TCP/IP Client Support',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.server',
            COMMENTS => 'TCP/IP Server',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.smit',
            COMMENTS => 'TCP/IP SMIT Support',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.uucp',
            COMMENTS => 'Unix to Unix Copy Program',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.diag_tool',
            COMMENTS => 'Performance Diagnostic Tool',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.libperfstat',
            COMMENTS => 'Performance Statistics Library Interface',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.perfstat',
            COMMENTS => 'Performance Statistics Interface',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.proctools',
            COMMENTS => 'Proc Filesystem Tools',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.tools',
            COMMENTS => 'Base Performance Tools',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.tune',
            COMMENTS => 'Performance Tuning Support',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.events',
            COMMENTS => 'Performance Monitor API Event Codes',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.lib',
            COMMENTS => 'Performance Monitor API Library',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.pmsvcs',
            COMMENTS => 'Performance Monitor API Kernel Extension',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.samples',
            COMMENTS => 'Performance Monitor API Samples',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.tools',
            COMMENTS => 'Performance Monitor API Tools',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte',
            COMMENTS => 'Base Operating System Runtime',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.Dt',
            COMMENTS => 'Desktop Integrator',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.ILS',
            COMMENTS => 'International Language Support',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.SRC',
            COMMENTS => 'System Resource Controller',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.X11',
            COMMENTS => 'AIXwindows Device Support',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.aio',
            COMMENTS => 'Asynchronous I/O Extension',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.archive',
            COMMENTS => 'Archive Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.bind_cmds',
            COMMENTS => 'Binder and Loader Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.boot',
            COMMENTS => 'Boot Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.bosinst',
            COMMENTS => 'Base OS Install Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.commands',
            COMMENTS => 'Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.compare',
            COMMENTS => 'File Compare Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.console',
            COMMENTS => 'Console',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.control',
            COMMENTS => 'System Control Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.cron',
            COMMENTS => 'Batch Operations',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.date',
            COMMENTS => 'Date Control Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.devices',
            COMMENTS => 'Base Device Drivers',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.devices_msg',
            COMMENTS => 'Device Driver Messages',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.diag',
            COMMENTS => 'Diagnostics',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.edit',
            COMMENTS => 'Editors',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.filesystem',
            COMMENTS => 'Filesystem Administration',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.iconv',
            COMMENTS => 'Language Converters',
            VERSION  => '5.3.0.40',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.ifor_ls',
            COMMENTS => 'iFOR/LS Libraries',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.im',
            COMMENTS => 'Input Methods',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.install',
            COMMENTS => 'LPP Install Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.jfscomp',
            COMMENTS => 'JFS Compression',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libc',
            COMMENTS => 'libc Library',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libcfg',
            COMMENTS => 'libcfg Library',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libcur',
            COMMENTS => 'libcurses Library',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libdbm',
            COMMENTS => 'libdbm Library',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libnetsvc',
            COMMENTS => 'Network Services Libraries',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libpthreads',
            COMMENTS => 'pthreads Library',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libqb',
            COMMENTS => 'libqb Library',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libs',
            COMMENTS => 'libs Library',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.loc',
            COMMENTS => 'Base Locale Support',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.lvm',
            COMMENTS => 'Logical Volume Manager',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.man',
            COMMENTS => 'Man Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.methods',
            COMMENTS => 'Device Config Methods',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.misc_cmds',
            COMMENTS => 'Miscellaneous Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.net',
            COMMENTS => 'Network',
            VERSION  => '5.3.0.40',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.odm',
            COMMENTS => 'Object Data Manager',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.printers',
            COMMENTS => 'Front End Printer Support',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.security',
            COMMENTS => 'Base Security Function',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.serv_aid',
            COMMENTS => 'Error Log Service Aids',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.shell',
            COMMENTS => 'Shells (bsh, ksh, csh)',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.streams',
            COMMENTS => 'Streams Libraries',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.tty',
            COMMENTS => 'Base TTY Support and Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.suma',
            COMMENTS => 'Service Update Management Assistant (SUMA)',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.loginlic',
            COMMENTS => 'License Management',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.nim.client',
            COMMENTS => 'Network Install Manager - Client Tools',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.quota',
            COMMENTS => 'Filesystem Quota Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.serv_aid',
            COMMENTS => 'Software Error Logging and Dump Service Aids',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.smit',
            COMMENTS => 'System Management Interface Tool (SMIT)',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.sysbr',
            COMMENTS => 'System Backup and BOS Install Utilities',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.trace',
            COMMENTS => 'Software Trace Service Aids',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.rte',
            COMMENTS => 'Run-time Environment for AIX Terminals',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.spell',
            COMMENTS => 'Writer\'s Tools Commands',
            VERSION  => '5.3.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.tfs',
            COMMENTS => 'Text Formatting Services Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.client',
            COMMENTS => 'Cluster Systems Management Client',
            VERSION  => '1.5.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.core',
            COMMENTS => 'Cluster Systems Management Core',
            VERSION  => '1.5.1.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.deploy',
            COMMENTS => 'Cluster Systems Management Deployment Component',
            VERSION  => '1.5.1.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.diagnostics',
            COMMENTS => 'Cluster Systems Management Probe Manager / Diagnostics',
            VERSION  => '1.5.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.dsh',
            COMMENTS => 'Cluster Systems Management Dsh',
            VERSION  => '1.5.1.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.gui.dcem',
            COMMENTS => 'Distributed Command Execution Manager Runtime Environment',
            VERSION  => '1.5.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.FR_FR.core',
            COMMENTS => 'CSM Core Func Msgs - French (UTF)',
            VERSION  => '1.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.fr_FR.core',
            COMMENTS => 'CSM Core Func Msgs - French',
            VERSION  => '1.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'freeware.gnu.bash.rte',
            COMMENTS => 'bash Bourne Again SHell',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'freeware.gnu.gettext.rte',
            COMMENTS => 'GNU Internationalisation Utility',
            VERSION  => '0.10.35.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'infocenter.man.EN_US.commands',
            COMMENTS => 'AIX manual commands - U.S. English',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'infocenter.man.EN_US.files',
            COMMENTS => 'AIX manual files - U.S. English',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'infocenter.man.EN_US.libs',
            COMMENTS => 'AIX manual libs - U.S. English',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.com',
            COMMENTS => 'Inventory Scout Microcode Catalog',
            VERSION  => '2.2.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.ldb',
            COMMENTS => 'Inventory Scout Logic Database',
            VERSION  => '2.2.0.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.msg.fr_FR.rte',
            COMMENTS => 'Inventory Scout Messages - French',
            VERSION  => '2.1.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.rte',
            COMMENTS => 'Inventory Scout Runtime',
            VERSION  => '2.2.0.9',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'lum.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '5.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'lum.base.gui',
            COMMENTS => 'License Use Management Runtime GUI',
            VERSION  => '5.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssh.base.client',
            COMMENTS => 'Open Secure Shell Commands',
            VERSION  => '4.1.0.5300',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssh.base.server',
            COMMENTS => 'Open Secure Shell Server',
            VERSION  => '4.1.0.5300',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssh.license',
            COMMENTS => 'Open Secure Shell License',
            VERSION  => '4.1.0.5300',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssh.msg.fr_FR',
            COMMENTS => 'Open Secure Shell Messages - French',
            VERSION  => '4.1.0.5300',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'perfagent.tools',
            COMMENTS => 'Local Performance Analysis & Control Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'perl.libext',
            COMMENTS => 'Perl Library Extensions',
            VERSION  => '2.1.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'perl.rte',
            COMMENTS => 'Perl Version 5 Runtime Environment',
            VERSION  => '5.8.2.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.msg.fr_FR.rte',
            COMMENTS => 'Printer Backend Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.rte',
            COMMENTS => 'Printer Backend',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'pware53.base.rte',
            COMMENTS => 'pWare base for 5.3',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'pware53.gcc-g++.rte',
            COMMENTS => 'GNU GCC c/c++/objc/java/fortran 4.2.4',
            VERSION  => '4.2.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'pware53.gettext.rte',
            COMMENTS => 'GNU gettext 0.17',
            VERSION  => '0.17.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'pware53.gmp.rte',
            COMMENTS => 'gmp 4.2.4',
            VERSION  => '4.2.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'pware53.libiconv.rte',
            COMMENTS => 'GNU libiconv 1.12',
            VERSION  => '1.12.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'pware53.mpfr.rte',
            COMMENTS => 'mpfr 2.3.2',
            VERSION  => '2.3.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'pware53.net-snmp.rte',
            COMMENTS => 'Net-SNMP 5.4.2.1',
            VERSION  => '5.4.2.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'pware53.openssl.rte',
            COMMENTS => 'OpenSSL 0.9.8j',
            VERSION  => '0.9.8.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'pware53.zlib.rte',
            COMMENTS => 'zlib 1.2.3',
            VERSION  => '1.2.3.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rpm.rte',
            COMMENTS => 'RPM Package Manager',
            VERSION  => '3.0.5.39',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.auditrm',
            COMMENTS => 'RSCT Audit Log Resource Manager',
            VERSION  => '2.4.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.errm',
            COMMENTS => 'RSCT Event Response Resource Manager',
            VERSION  => '2.4.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.fsrm',
            COMMENTS => 'RSCT File System Resource Manager',
            VERSION  => '2.4.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.gui',
            COMMENTS => 'RSCT Graphical User Interface',
            VERSION  => '2.4.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.hostrm',
            COMMENTS => 'RSCT Host Resource Manager',
            VERSION  => '2.4.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.lprm',
            COMMENTS => 'RSCT Least Privilege Resource Manager',
            VERSION  => '2.4.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.rmc',
            COMMENTS => 'RSCT Resource Monitoring and Control',
            VERSION  => '2.4.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.sec',
            COMMENTS => 'RSCT Security',
            VERSION  => '2.4.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.sensorrm',
            COMMENTS => 'RSCT Sensor Resource Manager',
            VERSION  => '2.4.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.sr',
            COMMENTS => 'RSCT Registry',
            VERSION  => '2.4.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.utils',
            COMMENTS => 'RSCT Utilities',
            VERSION  => '2.4.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.gui',
            COMMENTS => 'RSCT GUI Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.sec',
            COMMENTS => 'RSCT Security Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.sr',
            COMMENTS => 'RSCT Registry Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.gui',
            COMMENTS => 'RSCT GUI Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.gui.com',
            COMMENTS => 'RSCT GUI JAVA Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.rmc.com',
            COMMENTS => 'RSCT RMC JAVA Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.sec',
            COMMENTS => 'RSCT Security Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.sr',
            COMMENTS => 'RSCT Registry Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - French',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.help.en_US.websm',
            COMMENTS => 'WebSM Extended Helps - U.S. English',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.help.msg.en_US.websm',
            COMMENTS => 'WebSM Context Helps - U.S. English',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.help.msg.fr_FR.websm',
            COMMENTS => 'WebSM Context Helps - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.msg.fr_FR.sguide.rte',
            COMMENTS => 'TaskGuide Viewer Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.msg.fr_FR.websm.apps',
            COMMENTS => 'WebSM Client Apps. Messages - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.sguide.rte',
            COMMENTS => 'TaskGuide Runtime Environment',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.apps',
            COMMENTS => 'Web-based System Manager Applications',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.diag',
            COMMENTS => 'Web-based System Manager Diagnostic Applications',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.framework',
            COMMENTS => 'Web-based System Manager Client/Server Support',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.icons',
            COMMENTS => 'Web-based System Manager Icons',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.rte',
            COMMENTS => 'Web-based System Manager Runtime Environment',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.webaccess',
            COMMENTS => 'WebSM Web Access Enablement',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgtlib.framework.core',
            COMMENTS => 'System Management Service Libraries Common Code',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgtlib.libraries.apps',
            COMMENTS => 'System Management Service Libraries Application Code',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.aix50.rte',
            COMMENTS => 'C Set ++ Runtime for AIX 5.0',
            VERSION  => '6.0.0.13',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.cpp',
            COMMENTS => 'C for AIX Preprocessor',
            VERSION  => '6.0.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.rte',
            COMMENTS => 'C Set ++ Runtime',
            VERSION  => '6.0.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Java14.sdk',
            COMMENTS => 'Java SDK 32-bit',
            VERSION  => '1.4.2.75',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'Tivoli_Management_Agent.client.rte',
            COMMENTS => 'Management Framework Endpoint Runtime"',
            VERSION  => '3.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.base.rte',
            COMMENTS => 'AIXwindows Runtime Environment',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.base.smt',
            COMMENTS => 'AIXwindows Runtime Shared Memory Transport',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.64bit',
            COMMENTS => 'Base Operating System 64 bit Runtime',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.acct',
            COMMENTS => 'Accounting Services',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.aixpert.cmds',
            COMMENTS => 'AIX Security Hardening',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.cdmount',
            COMMENTS => 'CD/DVD Automount Facility',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.com',
            COMMENTS => 'Common Hardware Diagnostics',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.rte',
            COMMENTS => 'Hardware Diagnostics',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.util',
            COMMENTS => 'Hardware Diagnostics Utilities',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.mh',
            COMMENTS => 'Mail Handler',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.mp',
            COMMENTS => 'Base Operating System Multiprocessor Runtime',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.mp64',
            COMMENTS => 'Base Operating System 64-bit Multiprocessor Runtime',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ipsec.keymgt',
            COMMENTS => 'IP Security Key Management',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ipsec.rte',
            COMMENTS => 'IP Security',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ncs',
            COMMENTS => 'Network Computing System 1.5.1',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.client',
            COMMENTS => 'Network File System Client',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.nis.client',
            COMMENTS => 'Network Information Service Client',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.snapp',
            COMMENTS => 'System Networking Analysis and Performance Pilot',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.client',
            COMMENTS => 'TCP/IP Client Support',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.server',
            COMMENTS => 'TCP/IP Server',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.uucp',
            COMMENTS => 'Unix to Unix Copy Program',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.diag_tool',
            COMMENTS => 'Performance Diagnostic Tool',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.libperfstat',
            COMMENTS => 'Performance Statistics Library Interface',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.perfstat',
            COMMENTS => 'Performance Statistics Interface',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.tools',
            COMMENTS => 'Base Performance Tools',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.tune',
            COMMENTS => 'Performance Tuning Support',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.pmapi.pmsvcs',
            COMMENTS => 'Performance Monitor API Kernel Extension',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte',
            COMMENTS => 'Base Operating System Runtime',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.Dt',
            COMMENTS => 'Desktop Integrator',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.SRC',
            COMMENTS => 'System Resource Controller',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.aio',
            COMMENTS => 'Asynchronous I/O Extension',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.archive',
            COMMENTS => 'Archive Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.boot',
            COMMENTS => 'Boot Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.commands',
            COMMENTS => 'Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.control',
            COMMENTS => 'System Control Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.cron',
            COMMENTS => 'Batch Operations',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.devices',
            COMMENTS => 'Base Device Drivers',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.diag',
            COMMENTS => 'Diagnostics',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.filesystem',
            COMMENTS => 'Filesystem Administration',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.jfscomp',
            COMMENTS => 'JFS Compression',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.lvm',
            COMMENTS => 'Logical Volume Manager',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.printers',
            COMMENTS => 'Front End Printer Support',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.security',
            COMMENTS => 'Base Security Function',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.serv_aid',
            COMMENTS => 'Error Log Service Aids',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.shell',
            COMMENTS => 'Shells (bsh, ksh, csh)',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.tty',
            COMMENTS => 'Base TTY Support and Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.suma',
            COMMENTS => 'Service Update Management Assistant (SUMA)',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.loginlic',
            COMMENTS => 'License Management',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.nim.client',
            COMMENTS => 'Network Install Manager - Client Tools',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.serv_aid',
            COMMENTS => 'Software Error Logging and Dump Service Aids',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.sysbr',
            COMMENTS => 'System Backup and BOS Install Utilities',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.trace',
            COMMENTS => 'Software Trace Service Aids',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.client',
            COMMENTS => 'Cluster Systems Management Client',
            VERSION  => '1.5.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.core',
            COMMENTS => 'Cluster Systems Management Core',
            VERSION  => '1.5.1.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.deploy',
            COMMENTS => 'Cluster Systems Management Deployment Component',
            VERSION  => '1.5.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.diagnostics',
            COMMENTS => 'Cluster Systems Management Probe Manager / Diagnostics',
            VERSION  => '1.5.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.dsh',
            COMMENTS => 'Cluster Systems Management Dsh',
            VERSION  => '1.5.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'ifor_ls.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'invscout.com',
            COMMENTS => 'Inventory Scout Microcode Catalog',
            VERSION  => '2.2.0.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'invscout.ldb',
            COMMENTS => 'Inventory Scout Logic Database',
            VERSION  => '2.2.0.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'invscout.rte',
            COMMENTS => 'Inventory Scout Runtime',
            VERSION  => '2.2.0.9',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'lum.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '5.1.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'openssh.base.client',
            COMMENTS => 'Open Secure Shell Commands',
            VERSION  => '4.1.0.5300',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'openssh.base.server',
            COMMENTS => 'Open Secure Shell Server',
            VERSION  => '4.1.0.5300',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'perfagent.tools',
            COMMENTS => 'Local Performance Analysis & Control Commands',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'printers.rte',
            COMMENTS => 'Printer Backend',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rpm.rte',
            COMMENTS => 'RPM Package Manager',
            VERSION  => '3.0.5.39',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.auditrm',
            COMMENTS => 'RSCT Audit Log Resource Manager',
            VERSION  => '2.4.5.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.errm',
            COMMENTS => 'RSCT Event Response Resource Manager',
            VERSION  => '2.4.5.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.fsrm',
            COMMENTS => 'RSCT File System Resource Manager',
            VERSION  => '2.4.5.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.hostrm',
            COMMENTS => 'RSCT Host Resource Manager',
            VERSION  => '2.4.5.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.lprm',
            COMMENTS => 'RSCT Least Privilege Resource Manager',
            VERSION  => '2.4.5.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.rmc',
            COMMENTS => 'RSCT Resource Monitoring and Control',
            VERSION  => '2.4.5.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.sec',
            COMMENTS => 'RSCT Security',
            VERSION  => '2.4.5.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.sensorrm',
            COMMENTS => 'RSCT Sensor Resource Manager',
            VERSION  => '2.4.5.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.sr',
            COMMENTS => 'RSCT Registry',
            VERSION  => '2.4.5.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.utils',
            COMMENTS => 'RSCT Utilities',
            VERSION  => '2.4.5.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.apps',
            COMMENTS => 'Web-based System Manager Applications',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.framework',
            COMMENTS => 'Web-based System Manager Client/Server Support',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'sysmgt.websm.rte',
            COMMENTS => 'Web-based System Manager Runtime Environment',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.terminfo.ansi.data',
            COMMENTS => 'Amer National Stds Institute Terminal Defs',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.com.data',
            COMMENTS => 'Common Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.dec.data',
            COMMENTS => 'Digital Equipment Corp. Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.ibm.data',
            COMMENTS => 'IBM Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.pc.data',
            COMMENTS => 'Personal Computer Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.print.data',
            COMMENTS => 'Generic Line Printer Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.televideo.data',
            COMMENTS => 'Televideo Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.wyse.data',
            COMMENTS => 'Wyse Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.spell.data',
            COMMENTS => 'Writer\'s Tools Data',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.tfs.data',
            COMMENTS => 'Text Formatting Services Data',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        }
    ],
    'aix-5.3c' => [
        {
            NAME     => 'Java14.sdk',
            COMMENTS => 'Java SDK 32-bit',
            VERSION  => '1.4.2.250',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Java6_64.sdk',
            COMMENTS => 'Java SDK 64-bit',
            VERSION  => '6.0.0.265',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Tivoli_Management_Agent.client.rte',
            COMMENTS => 'Management Framework Endpoint Runtime"',
            VERSION  => '3.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.Dt.ToolTalk',
            COMMENTS => 'AIX CDE ToolTalk Support',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.Dt.bitmaps',
            COMMENTS => 'AIX CDE Bitmaps',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.Dt.helpmin',
            COMMENTS => 'AIX CDE Minimum Help Files',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.Dt.lib',
            COMMENTS => 'AIX CDE Runtime Libraries',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.adt.bitmaps',
            COMMENTS => 'AIXwindows Application Development Toolkit Bitmap Files',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.adt.imake',
            COMMENTS => 'AIXwindows Application Development Toolkit imake',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.adt.include',
            COMMENTS => 'AIXwindows Application Development Toolkit Include Files',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.adt.lib',
            COMMENTS => 'AIXwindows Application Development Toolkit Libraries',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.aixterm',
            COMMENTS => 'AIXwindows aixterm Application',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.clients',
            COMMENTS => 'AIXwindows Client Applications',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.config',
            COMMENTS => 'AIXwindows Configuration Applications',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.custom',
            COMMENTS => 'AIXwindows Customizing Tool',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.msmit',
            COMMENTS => 'AIXwindows msmit Application',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.rte',
            COMMENTS => 'AIXwindows Runtime Configuration Applications',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.util',
            COMMENTS => 'AIXwindows Utility Applications',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.xdm',
            COMMENTS => 'AIXwindows xdm Application',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.apps.xterm',
            COMMENTS => 'AIXwindows xterm Application',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.base.common',
            COMMENTS => 'AIXwindows Runtime Common Directories',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.base.lib',
            COMMENTS => 'AIXwindows Runtime Libraries',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.base.rte',
            COMMENTS => 'AIXwindows Runtime Environment',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.base.smt',
            COMMENTS => 'AIXwindows Runtime Shared Memory Transport',
            VERSION  => '5.3.0.30',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.base.xpconfig',
            COMMENTS => 'Xprint Configuration Files',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.coreX',
            COMMENTS => 'AIXwindows X Consortium Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.defaultFonts',
            COMMENTS => 'AIXwindows Default Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso1',
            COMMENTS => 'AIXwindows Latin 1 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso2',
            COMMENTS => 'AIXwindows Latin 2 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso3',
            COMMENTS => 'AIXwindows Latin 3 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso4',
            COMMENTS => 'AIXwindows Latin 4 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.iso_T1',
            COMMENTS => 'AIXwindows Latin Type1 Fonts',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.fnt.ucs.com',
            COMMENTS => 'AIXwindows Common Fonts Unicode',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.en_US.base.lib',
            COMMENTS => 'AIXwindows Client Locale Config - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.loc.en_US.base.rte',
            COMMENTS => 'AIXwindows Locale Configuration - U.S. English',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.motif.lib',
            COMMENTS => 'AIXwindows Motif Libraries',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.motif.mwm',
            COMMENTS => 'AIXwindows Motif Window Manager',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'X11.vsm.lib',
            COMMENTS => 'Visual System Managment Library',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.64bit',
            COMMENTS => 'Base Operating System 64 bit Runtime',
            VERSION  => '5.3.10.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.acct',
            COMMENTS => 'Accounting Services',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.base',
            COMMENTS => 'Base Application Development Toolkit',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.include',
            COMMENTS => 'Base Application Development Include Files',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.lib',
            COMMENTS => 'Base Application Development Libraries',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.libm',
            COMMENTS => 'Base Application Development Math Library',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.prof',
            COMMENTS => 'Base Profiling Support',
            VERSION  => '5.3.10.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.alt_disk_install.boot_images',
            COMMENTS => 'Alternate Disk Installation Disk Boot Images',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.alt_disk_install.rte',
            COMMENTS => 'Alternate Disk Installation Runtime',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.cdmount',
            COMMENTS => 'CD/DVD Automount Facility',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.cifs_fs.rte',
            COMMENTS => 'Runtime for SMBFS',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.cifs_fs.smit',
            COMMENTS => 'SMIT Interface for SMBFS',
            VERSION  => '5.3.7.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.content_list',
            COMMENTS => 'AIX Release Content List',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.com',
            COMMENTS => 'Common Hardware Diagnostics',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.rte',
            COMMENTS => 'Hardware Diagnostics',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.util',
            COMMENTS => 'Hardware Diagnostics Utilities',
            VERSION  => '5.3.10.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.com',
            COMMENTS => 'Common Language to Language Converters',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.fr_FR',
            COMMENTS => 'EBCDIC & ASCII Language Converters - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.ucs.com',
            COMMENTS => 'Unicode Base Converters for AIX Code Sets/Fonts',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iocp.rte',
            COMMENTS => 'I/O Completion Ports API',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.iso.fr_FR',
            COMMENTS => 'Base System Locale ISO Code Set - French',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mh',
            COMMENTS => 'Mail Handler',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mp',
            COMMENTS => 'Base Operating System Multiprocessor Runtime',
            VERSION  => '5.3.10.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mp64',
            COMMENTS => 'Base Operating System 64-bit Multiprocessor Runtime',
            VERSION  => '5.3.10.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ncs',
            COMMENTS => 'Network Computing System 1.5.1',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.client',
            COMMENTS => 'Network File System Client',
            VERSION  => '5.3.10.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.server',
            COMMENTS => 'Network File System Server',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.snapp',
            COMMENTS => 'System Networking Analysis and Performance Pilot',
            VERSION  => '5.3.7.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.adt',
            COMMENTS => 'TCP/IP Application Toolkit',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.client',
            COMMENTS => 'TCP/IP Client Support',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.server',
            COMMENTS => 'TCP/IP Server',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.smit',
            COMMENTS => 'TCP/IP SMIT Support',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.uucp',
            COMMENTS => 'Unix to Unix Copy Program',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.diag_tool',
            COMMENTS => 'Performance Diagnostic Tool',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.libperfstat',
            COMMENTS => 'Performance Statistics Library Interface',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.perfstat',
            COMMENTS => 'Performance Statistics Interface',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.proctools',
            COMMENTS => 'Proc Filesystem Tools',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.tools',
            COMMENTS => 'Base Performance Tools',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.tune',
            COMMENTS => 'Performance Tuning Support',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.events',
            COMMENTS => 'Performance Monitor API Event Codes',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.lib',
            COMMENTS => 'Performance Monitor API Library',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.pmsvcs',
            COMMENTS => 'Performance Monitor API Kernel Extension',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.samples',
            COMMENTS => 'Performance Monitor API Samples',
            VERSION  => '5.3.7.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.tools',
            COMMENTS => 'Performance Monitor API Tools',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte',
            COMMENTS => 'Base Operating System Runtime',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.Dt',
            COMMENTS => 'Desktop Integrator',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.ILS',
            COMMENTS => 'International Language Support',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.SRC',
            COMMENTS => 'System Resource Controller',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.X11',
            COMMENTS => 'AIXwindows Device Support',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.aio',
            COMMENTS => 'Asynchronous I/O Extension',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.archive',
            COMMENTS => 'Archive Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.bind_cmds',
            COMMENTS => 'Binder and Loader Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.boot',
            COMMENTS => 'Boot Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.bosinst',
            COMMENTS => 'Base OS Install Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.commands',
            COMMENTS => 'Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.compare',
            COMMENTS => 'File Compare Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.console',
            COMMENTS => 'Console',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.control',
            COMMENTS => 'System Control Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.cron',
            COMMENTS => 'Batch Operations',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.date',
            COMMENTS => 'Date Control Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.devices',
            COMMENTS => 'Base Device Drivers',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.devices_msg',
            COMMENTS => 'Device Driver Messages',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.diag',
            COMMENTS => 'Diagnostics',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.edit',
            COMMENTS => 'Editors',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.filesystem',
            COMMENTS => 'Filesystem Administration',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.iconv',
            COMMENTS => 'Language Converters',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.ifor_ls',
            COMMENTS => 'iFOR/LS Libraries',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.im',
            COMMENTS => 'Input Methods',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.install',
            COMMENTS => 'LPP Install Commands',
            VERSION  => '5.3.10.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.jfscomp',
            COMMENTS => 'JFS Compression',
            VERSION  => '5.3.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libc',
            COMMENTS => 'libc Library',
            VERSION  => '5.3.10.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libcfg',
            COMMENTS => 'libcfg Library',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libcur',
            COMMENTS => 'libcurses Library',
            VERSION  => '5.3.10.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libdbm',
            COMMENTS => 'libdbm Library',
            VERSION  => '5.3.7.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libnetsvc',
            COMMENTS => 'Network Services Libraries',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libpthreads',
            COMMENTS => 'pthreads Library',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libqb',
            COMMENTS => 'libqb Library',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libs',
            COMMENTS => 'libs Library',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.loc',
            COMMENTS => 'Base Locale Support',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.lvm',
            COMMENTS => 'Logical Volume Manager',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.man',
            COMMENTS => 'Man Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.methods',
            COMMENTS => 'Device Config Methods',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.misc_cmds',
            COMMENTS => 'Miscellaneous Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.net',
            COMMENTS => 'Network',
            VERSION  => '5.3.0.40',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.odm',
            COMMENTS => 'Object Data Manager',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.printers',
            COMMENTS => 'Front End Printer Support',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.security',
            COMMENTS => 'Base Security Function',
            VERSION  => '5.3.10.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.serv_aid',
            COMMENTS => 'Error Log Service Aids',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.shell',
            COMMENTS => 'Shells (bsh, ksh, csh)',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.streams',
            COMMENTS => 'Streams Libraries',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.tty',
            COMMENTS => 'Base TTY Support and Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.suma',
            COMMENTS => 'Service Update Management Assistant (SUMA)',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.swma',
            COMMENTS => 'Software Maintenance Agreement',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.loginlic',
            COMMENTS => 'License Management',
            VERSION  => '5.3.7.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.nim.client',
            COMMENTS => 'Network Install Manager - Client Tools',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.quota',
            COMMENTS => 'Filesystem Quota Commands',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.serv_aid',
            COMMENTS => 'Software Error Logging and Dump Service Aids',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.smit',
            COMMENTS => 'System Management Interface Tool (SMIT)',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.sysbr',
            COMMENTS => 'System Backup and BOS Install Utilities',
            VERSION  => '5.3.10.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.trace',
            COMMENTS => 'Software Trace Service Aids',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.rte',
            COMMENTS => 'Run-time Environment for AIX Terminals',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.spell',
            COMMENTS => 'Writer\'s Tools Commands',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.tfs',
            COMMENTS => 'Text Formatting Services Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.client',
            COMMENTS => 'Cluster Systems Management Client',
            VERSION  => '1.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.core',
            COMMENTS => 'Cluster Systems Management Core',
            VERSION  => '1.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.deploy',
            COMMENTS => 'Cluster Systems Management Deployment Component',
            VERSION  => '1.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.diagnostics',
            COMMENTS => 'Cluster Systems Management Probe Manager / Diagnostics',
            VERSION  => '1.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.dsh',
            COMMENTS => 'Cluster Systems Management Dsh',
            VERSION  => '1.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.FR_FR.core',
            COMMENTS => 'CSM Core Func Msgs - French (UTF)',
            VERSION  => '1.7.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.html.en_US.base.cli',
            COMMENTS => 'LUM HTML Guides - U.S. English',
            VERSION  => '5.3.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'infocenter.man.EN_US.commands',
            COMMENTS => 'AIX manual commands - U.S. English',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'infocenter.man.EN_US.files',
            COMMENTS => 'AIX manual files - U.S. English',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'infocenter.man.EN_US.libs',
            COMMENTS => 'AIX manual libs - U.S. English',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.com',
            COMMENTS => 'Inventory Scout Microcode Catalog',
            VERSION  => '2.2.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.ldb',
            COMMENTS => 'Inventory Scout Logic Database',
            VERSION  => '2.2.0.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.rte',
            COMMENTS => 'Inventory Scout Runtime',
            VERSION  => '2.2.0.13',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'lum.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '5.1.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssh.base.client',
            COMMENTS => 'Open Secure Shell Commands',
            VERSION  => '5.2.0.5300',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssh.base.server',
            COMMENTS => 'Open Secure Shell Server',
            VERSION  => '5.2.0.5300',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssl.base',
            COMMENTS => 'Open Secure Socket Layer',
            VERSION  => '0.9.8.1100',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'perfagent.tools',
            COMMENTS => 'Local Performance Analysis & Control Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'perl.libext',
            COMMENTS => 'Perl Library Extensions',
            VERSION  => '2.1.0.10',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'perl.rte',
            COMMENTS => 'Perl Version 5 Runtime Environment',
            VERSION  => '5.8.2.100',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.rte',
            COMMENTS => 'Printer Backend',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rpm.rte',
            COMMENTS => 'RPM Package Manager',
            VERSION  => '3.0.5.47',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.auditrm',
            COMMENTS => 'RSCT Audit Log Resource Manager',
            VERSION  => '2.4.11.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.errm',
            COMMENTS => 'RSCT Event Response Resource Manager',
            VERSION  => '2.4.11.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.fsrm',
            COMMENTS => 'RSCT File System Resource Manager',
            VERSION  => '2.4.11.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.gui',
            COMMENTS => 'RSCT Graphical User Interface',
            VERSION  => '2.4.11.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.hostrm',
            COMMENTS => 'RSCT Host Resource Manager',
            VERSION  => '2.4.11.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.lprm',
            COMMENTS => 'RSCT Least Privilege Resource Manager',
            VERSION  => '2.4.11.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.microsensor',
            COMMENTS => 'RSCT MicroSensor Resource Manager',
            VERSION  => '2.4.11.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.rmc',
            COMMENTS => 'RSCT Resource Monitoring and Control',
            VERSION  => '2.4.11.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.sec',
            COMMENTS => 'RSCT Security',
            VERSION  => '2.4.11.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.sensorrm',
            COMMENTS => 'RSCT Sensor Resource Manager',
            VERSION  => '2.4.11.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.sr',
            COMMENTS => 'RSCT Registry',
            VERSION  => '2.4.11.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.utils',
            COMMENTS => 'RSCT Utilities',
            VERSION  => '2.4.11.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.sec',
            COMMENTS => 'RSCT Security Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.sr',
            COMMENTS => 'RSCT Registry Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - French (UTF)',
            VERSION  => '2.4.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'samba.base',
            COMMENTS => 'Samba for AIX',
            VERSION  => '3.2.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'samba.license',
            COMMENTS => 'Samba for AIX',
            VERSION  => '3.2.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'samba.man.en_US',
            COMMENTS => 'Samba for AIX',
            VERSION  => '3.2.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgt.sguide.rte',
            COMMENTS => 'TaskGuide Runtime Environment',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgtlib.framework.core',
            COMMENTS => 'System Management Service Libraries Common Code',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'sysmgtlib.libraries.apps',
            COMMENTS => 'System Management Service Libraries Application Code',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.aix50.rte',
            COMMENTS => 'XL C/C++ Runtime for AIX 5.3',
            VERSION  => '10.1.0.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.cpp',
            COMMENTS => 'C for AIX Preprocessor',
            VERSION  => '9.0.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.rte',
            COMMENTS => 'XL C/C++ Runtime',
            VERSION  => '10.1.0.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Java14.sdk',
            COMMENTS => 'Java SDK 32-bit',
            VERSION  => '1.4.2.250',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'Java6_64.sdk',
            COMMENTS => 'Java SDK 64-bit',
            VERSION  => '6.0.0.265',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'Tivoli_Management_Agent.client.rte',
            COMMENTS => 'Management Framework Endpoint Runtime"',
            VERSION  => '3.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.Dt.ToolTalk',
            COMMENTS => 'AIX CDE ToolTalk Support',
            VERSION  => '5.3.9.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.Dt.bitmaps',
            COMMENTS => 'AIX CDE Bitmaps',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.Dt.helpmin',
            COMMENTS => 'AIX CDE Minimum Help Files',
            VERSION  => '5.3.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.base.rte',
            COMMENTS => 'AIXwindows Runtime Environment',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'X11.base.smt',
            COMMENTS => 'AIXwindows Runtime Shared Memory Transport',
            VERSION  => '5.3.0.30',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.64bit',
            COMMENTS => 'Base Operating System 64 bit Runtime',
            VERSION  => '5.3.10.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.acct',
            COMMENTS => 'Accounting Services',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.cdmount',
            COMMENTS => 'CD/DVD Automount Facility',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.cifs_fs.rte',
            COMMENTS => 'Runtime for SMBFS',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.cifs_fs.smit',
            COMMENTS => 'SMIT Interface for SMBFS',
            VERSION  => '5.3.7.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.com',
            COMMENTS => 'Common Hardware Diagnostics',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.rte',
            COMMENTS => 'Hardware Diagnostics',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.util',
            COMMENTS => 'Hardware Diagnostics Utilities',
            VERSION  => '5.3.10.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.iocp.rte',
            COMMENTS => 'I/O Completion Ports API',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.mh',
            COMMENTS => 'Mail Handler',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.mp',
            COMMENTS => 'Base Operating System Multiprocessor Runtime',
            VERSION  => '5.3.10.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.mp64',
            COMMENTS => 'Base Operating System 64-bit Multiprocessor Runtime',
            VERSION  => '5.3.10.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ncs',
            COMMENTS => 'Network Computing System 1.5.1',
            VERSION  => '5.3.8.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.client',
            COMMENTS => 'Network File System Client',
            VERSION  => '5.3.10.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.snapp',
            COMMENTS => 'System Networking Analysis and Performance Pilot',
            VERSION  => '5.3.7.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.client',
            COMMENTS => 'TCP/IP Client Support',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.server',
            COMMENTS => 'TCP/IP Server',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.uucp',
            COMMENTS => 'Unix to Unix Copy Program',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.diag_tool',
            COMMENTS => 'Performance Diagnostic Tool',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.libperfstat',
            COMMENTS => 'Performance Statistics Library Interface',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.perfstat',
            COMMENTS => 'Performance Statistics Interface',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.tools',
            COMMENTS => 'Base Performance Tools',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.tune',
            COMMENTS => 'Performance Tuning Support',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.pmapi.pmsvcs',
            COMMENTS => 'Performance Monitor API Kernel Extension',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte',
            COMMENTS => 'Base Operating System Runtime',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.Dt',
            COMMENTS => 'Desktop Integrator',
            VERSION  => '5.3.9.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.SRC',
            COMMENTS => 'System Resource Controller',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.aio',
            COMMENTS => 'Asynchronous I/O Extension',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.archive',
            COMMENTS => 'Archive Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.boot',
            COMMENTS => 'Boot Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.commands',
            COMMENTS => 'Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.control',
            COMMENTS => 'System Control Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.cron',
            COMMENTS => 'Batch Operations',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.devices',
            COMMENTS => 'Base Device Drivers',
            VERSION  => '5.3.9.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.diag',
            COMMENTS => 'Diagnostics',
            VERSION  => '5.3.9.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.filesystem',
            COMMENTS => 'Filesystem Administration',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.jfscomp',
            COMMENTS => 'JFS Compression',
            VERSION  => '5.3.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.lvm',
            COMMENTS => 'Logical Volume Manager',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.printers',
            COMMENTS => 'Front End Printer Support',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.security',
            COMMENTS => 'Base Security Function',
            VERSION  => '5.3.10.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.serv_aid',
            COMMENTS => 'Error Log Service Aids',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.shell',
            COMMENTS => 'Shells (bsh, ksh, csh)',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.tty',
            COMMENTS => 'Base TTY Support and Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.suma',
            COMMENTS => 'Service Update Management Assistant (SUMA)',
            VERSION  => '5.3.9.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.loginlic',
            COMMENTS => 'License Management',
            VERSION  => '5.3.7.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.nim.client',
            COMMENTS => 'Network Install Manager - Client Tools',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.serv_aid',
            COMMENTS => 'Software Error Logging and Dump Service Aids',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.sysbr',
            COMMENTS => 'System Backup and BOS Install Utilities',
            VERSION  => '5.3.10.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.trace',
            COMMENTS => 'Software Trace Service Aids',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.client',
            COMMENTS => 'Cluster Systems Management Client',
            VERSION  => '1.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.core',
            COMMENTS => 'Cluster Systems Management Core',
            VERSION  => '1.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.deploy',
            COMMENTS => 'Cluster Systems Management Deployment Component',
            VERSION  => '1.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.diagnostics',
            COMMENTS => 'Cluster Systems Management Probe Manager / Diagnostics',
            VERSION  => '1.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.dsh',
            COMMENTS => 'Cluster Systems Management Dsh',
            VERSION  => '1.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'ifor_ls.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '5.3.8.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'invscout.com',
            COMMENTS => 'Inventory Scout Microcode Catalog',
            VERSION  => '2.2.0.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'invscout.ldb',
            COMMENTS => 'Inventory Scout Logic Database',
            VERSION  => '2.2.0.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'invscout.rte',
            COMMENTS => 'Inventory Scout Runtime',
            VERSION  => '2.2.0.13',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'lum.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '5.1.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'openssh.base.client',
            COMMENTS => 'Open Secure Shell Commands',
            VERSION  => '5.2.0.5300',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'openssh.base.server',
            COMMENTS => 'Open Secure Shell Server',
            VERSION  => '5.2.0.5300',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'openssl.base',
            COMMENTS => 'Open Secure Socket Layer',
            VERSION  => '0.9.8.1100',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'perfagent.tools',
            COMMENTS => 'Local Performance Analysis & Control Commands',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'printers.rte',
            COMMENTS => 'Printer Backend',
            VERSION  => '5.3.10.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rpm.rte',
            COMMENTS => 'RPM Package Manager',
            VERSION  => '3.0.5.47',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.auditrm',
            COMMENTS => 'RSCT Audit Log Resource Manager',
            VERSION  => '2.4.11.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.errm',
            COMMENTS => 'RSCT Event Response Resource Manager',
            VERSION  => '2.4.11.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.fsrm',
            COMMENTS => 'RSCT File System Resource Manager',
            VERSION  => '2.4.11.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.hostrm',
            COMMENTS => 'RSCT Host Resource Manager',
            VERSION  => '2.4.11.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.lprm',
            COMMENTS => 'RSCT Least Privilege Resource Manager',
            VERSION  => '2.4.11.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.microsensor',
            COMMENTS => 'RSCT MicroSensor Resource Manager',
            VERSION  => '2.4.11.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.rmc',
            COMMENTS => 'RSCT Resource Monitoring and Control',
            VERSION  => '2.4.11.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.sec',
            COMMENTS => 'RSCT Security',
            VERSION  => '2.4.11.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.sensorrm',
            COMMENTS => 'RSCT Sensor Resource Manager',
            VERSION  => '2.4.11.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.sr',
            COMMENTS => 'RSCT Registry',
            VERSION  => '2.4.11.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.utils',
            COMMENTS => 'RSCT Utilities',
            VERSION  => '2.4.11.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'samba.base',
            COMMENTS => 'Samba for AIX',
            VERSION  => '3.2.8.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.terminfo.adds.data',
            COMMENTS => 'ADDS Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.annarbor.data',
            COMMENTS => 'Annarbor Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.ansi.data',
            COMMENTS => 'Amer National Stds Institute Terminal Defs',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.att.data',
            COMMENTS => 'AT&T Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.beehive.data',
            COMMENTS => 'Beehive Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.bull.data',
            COMMENTS => 'Bull Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.cdc.data',
            COMMENTS => 'Control Data Corp. Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.colorscan.data',
            COMMENTS => 'Datamedia Colorscan Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.com.data',
            COMMENTS => 'Common Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.datamedia.data',
            COMMENTS => 'Datamedia Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.dec.data',
            COMMENTS => 'Digital Equipment Corp. Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.diablo.data',
            COMMENTS => 'Generic Daisy Wheel Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.falco.data',
            COMMENTS => 'Falco Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.fortune.data',
            COMMENTS => 'Fortune Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.general.data',
            COMMENTS => 'General Terminal Corp. Term Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.hardcopy.data',
            COMMENTS => 'Hard Copy Terminals Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.hazeltine.data',
            COMMENTS => 'Hazeltine Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.hds.data',
            COMMENTS => 'Human Designed Systems Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.heath.data',
            COMMENTS => 'Heathkit and Zenith Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.homebrew.data',
            COMMENTS => 'Home-made Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.hp.data',
            COMMENTS => 'Hewlett-Packard Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.ibm.data',
            COMMENTS => 'IBM Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.lsi.data',
            COMMENTS => 'Lear Siegler Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.microterm.data',
            COMMENTS => 'Microterm Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.misc.data',
            COMMENTS => 'Miscellaneous Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.pc.data',
            COMMENTS => 'Personal Computer Terminal Definitions',
            VERSION  => '5.3.10.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.pci.data',
            COMMENTS => 'DOS Server Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.perkinelmer.data',
            COMMENTS => 'Perkin Elmer Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.pmcons.data',
            COMMENTS => 'PMAX Console Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.print.data',
            COMMENTS => 'Generic Line Printer Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.special.data',
            COMMENTS => 'Special Generic Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.sperry.data',
            COMMENTS => 'Sperry Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.svprint.data',
            COMMENTS => 'System V Printer Terminal Definitions',
            VERSION  => '5.3.9.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.tektronix.data',
            COMMENTS => 'Tektronix Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.teleray.data',
            COMMENTS => 'Teleray Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.televideo.data',
            COMMENTS => 'Televideo Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.ti.data',
            COMMENTS => 'Texas Instruments Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.tymshare.data',
            COMMENTS => 'Tymshare Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.visual.data',
            COMMENTS => 'Visual Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.wyse.data',
            COMMENTS => 'Wyse Terminal Definitions',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.spell.data',
            COMMENTS => 'Writer\'s Tools Data',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.tfs.data',
            COMMENTS => 'Text Formatting Services Data',
            VERSION  => '5.3.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        }
    ],
    'aix-6.1a' => [
        {
            NAME     => 'Atape.driver',
            COMMENTS => 'IBM AIX Enhanced Tape and Medium Changer Device Driver',
            VERSION  => '12.2.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ICU4C.rte',
            COMMENTS => 'International Components for Unicode',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Java14.sdk',
            COMMENTS => 'Java SDK 32-bit',
            VERSION  => '1.4.2.275',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Tivoli_Management_Agent.client.rte',
            COMMENTS => 'Management Framework Endpoint Runtime"',
            VERSION  => '3.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.64bit',
            COMMENTS => 'Base Operating System 64 bit Runtime',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.acct',
            COMMENTS => 'Accounting Services',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.base',
            COMMENTS => 'Base Application Development Toolkit',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.include',
            COMMENTS => 'Base Application Development Include Files',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.lib',
            COMMENTS => 'Base Application Development Libraries',
            VERSION  => '6.1.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.aixpert.cmds',
            COMMENTS => 'AIX Security Hardening',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.cdmount',
            COMMENTS => 'CD/DVD Automount Facility',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.com',
            COMMENTS => 'Common Hardware Diagnostics',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.rte',
            COMMENTS => 'Hardware Diagnostics',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.util',
            COMMENTS => 'Hardware Diagnostics Utilities',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.dosutil',
            COMMENTS => 'DOS Utilities',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.en_US.com',
            COMMENTS => 'WebSM/SMIT Context Helps - U.S. English',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.en_US.smit',
            COMMENTS => 'SMIT Context Helps - U.S. English',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.com',
            COMMENTS => 'Common Language to Language Converters',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.ucs.com',
            COMMENTS => 'Unicode Base Converters for AIX Code Sets/Fonts',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iocp.rte',
            COMMENTS => 'I/O Completion Ports API',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.iso.en_US',
            COMMENTS => 'Base System Locale ISO Code Set - U.S. English',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mh',
            COMMENTS => 'Mail Handler',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mls.lib',
            COMMENTS => 'Trusted AIX Libraries',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mp64',
            COMMENTS => 'Base Operating System 64-bit Multiprocessor Runtime',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.en_US.diag.rte',
            COMMENTS => 'Hardware Diagnostics Messages - U.S. English',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.en_US.net.ipsec',
            COMMENTS => 'IP Security Messages - U.S. English',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.en_US.net.tcp.client',
            COMMENTS => 'TCP/IP Messages - U.S. English',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.en_US.rte',
            COMMENTS => 'Base OS Runtime Messages - U.S. English',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.en_US.txt.tfs',
            COMMENTS => 'Text Formatting Services Msgs - U.S. English',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ipsec.keymgt',
            COMMENTS => 'IP Security Key Management',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ipsec.rte',
            COMMENTS => 'IP Security',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ncs',
            COMMENTS => 'Network Computing System 1.5.1',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.client',
            COMMENTS => 'Network File System Client',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nis.client',
            COMMENTS => 'Network Information Service Client',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.snapp',
            COMMENTS => 'System Networking Analysis and Performance Pilot',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.adt',
            COMMENTS => 'TCP/IP Application Toolkit',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.client',
            COMMENTS => 'TCP/IP Client Support',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.server',
            COMMENTS => 'TCP/IP Server',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.smit',
            COMMENTS => 'TCP/IP SMIT Support',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.uucp',
            COMMENTS => 'Unix to Unix Copy Program',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.diag_tool',
            COMMENTS => 'Performance Diagnostic Tool',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.libperfstat',
            COMMENTS => 'Performance Statistics Library Interface',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.perfstat',
            COMMENTS => 'Performance Statistics Interface',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.proctools',
            COMMENTS => 'Proc Filesystem Tools',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.tools',
            COMMENTS => 'Base Performance Tools',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.tune',
            COMMENTS => 'Performance Tuning Support',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.events',
            COMMENTS => 'Performance Monitor API Event Codes',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.lib',
            COMMENTS => 'Performance Monitor API Library',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.pmsvcs',
            COMMENTS => 'Performance Monitor API Kernel Extension',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.samples',
            COMMENTS => 'Performance Monitor API Samples',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.tools',
            COMMENTS => 'Performance Monitor API Tools',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte',
            COMMENTS => 'Base Operating System Runtime',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.Dt',
            COMMENTS => 'Desktop Integrator',
            VERSION  => '6.1.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.ILS',
            COMMENTS => 'International Language Support',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.SRC',
            COMMENTS => 'System Resource Controller',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.X11',
            COMMENTS => 'AIXwindows Device Support',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.aio',
            COMMENTS => 'Asynchronous I/O Extension',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.archive',
            COMMENTS => 'Archive Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.bind_cmds',
            COMMENTS => 'Binder and Loader Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.boot',
            COMMENTS => 'Boot Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.bosinst',
            COMMENTS => 'Base OS Install Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.commands',
            COMMENTS => 'Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.compare',
            COMMENTS => 'File Compare Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.console',
            COMMENTS => 'Console',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.control',
            COMMENTS => 'System Control Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.cron',
            COMMENTS => 'Batch Operations',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.date',
            COMMENTS => 'Date Control Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.devices',
            COMMENTS => 'Base Device Drivers',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.devices_msg',
            COMMENTS => 'Device Driver Messages',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.diag',
            COMMENTS => 'Diagnostics',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.edit',
            COMMENTS => 'Editors',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.filesystem',
            COMMENTS => 'Filesystem Administration',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.iconv',
            COMMENTS => 'Language Converters',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.ifor_ls',
            COMMENTS => 'iFOR/LS Libraries',
            VERSION  => '6.1.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.im',
            COMMENTS => 'Input Methods',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.install',
            COMMENTS => 'LPP Install Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.jfscomp',
            COMMENTS => 'JFS Compression',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libc',
            COMMENTS => 'libc Library',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libcfg',
            COMMENTS => 'libcfg Library',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libcur',
            COMMENTS => 'libcurses Library',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libdbm',
            COMMENTS => 'libdbm Library',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libnetsvc',
            COMMENTS => 'Network Services Libraries',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libpthreads',
            COMMENTS => 'pthreads Library',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libqb',
            COMMENTS => 'libqb Library',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libs',
            COMMENTS => 'libs Library',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.loc',
            COMMENTS => 'Base Locale Support',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.lvm',
            COMMENTS => 'Logical Volume Manager',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.man',
            COMMENTS => 'Man Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.methods',
            COMMENTS => 'Device Config Methods',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.misc_cmds',
            COMMENTS => 'Miscellaneous Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.mlslib',
            COMMENTS => 'Trusted AIX Libraries',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.net',
            COMMENTS => 'Network',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.odm',
            COMMENTS => 'Object Data Manager',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.printers',
            COMMENTS => 'Front End Printer Support',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.security',
            COMMENTS => 'Base Security Function',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.serv_aid',
            COMMENTS => 'Error Log Service Aids',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.shell',
            COMMENTS => 'Shells (bsh, ksh, csh)',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.streams',
            COMMENTS => 'Streams Libraries',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.tty',
            COMMENTS => 'Base TTY Support and Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.suma',
            COMMENTS => 'Service Update Management Assistant (SUMA)',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.swma',
            COMMENTS => 'Software Maintenance Agreement',
            VERSION  => '6.1.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.loginlic',
            COMMENTS => 'License Management',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.nim.client',
            COMMENTS => 'Network Install Manager - Client Tools',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.quota',
            COMMENTS => 'Filesystem Quota Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.serv_aid',
            COMMENTS => 'Software Error Logging and Dump Service Aids',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.smit',
            COMMENTS => 'System Management Interface Tool (SMIT)',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.sysbr',
            COMMENTS => 'System Backup and BOS Install Utilities',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.trace',
            COMMENTS => 'Software Trace Service Aids',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.rte',
            COMMENTS => 'Run-time Environment for AIX Terminals',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.spell',
            COMMENTS => 'Writer\'s Tools Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.tfs',
            COMMENTS => 'Text Formatting Services Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.wpars',
            COMMENTS => 'AIX Workload Partitions',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'cas.client.rte',
            COMMENTS => 'Certificate Authentication Services Client',
            VERSION  => '5.2.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'cas.msg.en_US.client',
            COMMENTS => 'Cert Auth Serv Client Messages - U.S. English',
            VERSION  => '5.2.0.50',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'clic.rte.kernext',
            COMMENTS => 'CryptoLite for C Kernel',
            VERSION  => '4.7.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'clic.rte.lib',
            COMMENTS => 'CryptoLite for C Library',
            VERSION  => '4.7.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.client',
            COMMENTS => 'Cluster Systems Management Client',
            VERSION  => '1.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.core',
            COMMENTS => 'Cluster Systems Management Core',
            VERSION  => '1.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.deploy',
            COMMENTS => 'Cluster Systems Management Deployment Component',
            VERSION  => '1.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.diagnostics',
            COMMENTS => 'Cluster Systems Management Probe Manager / Diagnostics',
            VERSION  => '1.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.dsh',
            COMMENTS => 'Cluster Systems Management Dsh',
            VERSION  => '1.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.EN_US.core',
            COMMENTS => 'CSM Core Func Msgs - U.S. English (UTF)',
            VERSION  => '1.7.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.en_US.core',
            COMMENTS => 'CSM Core Func Msgs - U.S. English',
            VERSION  => '1.7.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'idsldap.clt32bit61.rte',
            COMMENTS => 'Directory Server - 32 bit Client',
            VERSION  => '6.1.0.26',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'idsldap.cltbase61.adt',
            COMMENTS => 'Directory Server - Base Client',
            VERSION  => '6.1.0.26',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'idsldap.cltbase61.rte',
            COMMENTS => 'Directory Server - Base Client',
            VERSION  => '6.1.0.26',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.html.en_US.base.cli',
            COMMENTS => 'LUM HTML Guides - U.S. English',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.msg.en_US.base.cli',
            COMMENTS => 'LUM Runtime Code Messages - U.S. English',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'infocenter.man.EN_US.commands',
            COMMENTS => 'AIX manual commands - U.S. English',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'infocenter.man.EN_US.files',
            COMMENTS => 'AIX manual files - U.S. English',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'infocenter.man.EN_US.libs',
            COMMENTS => 'AIX manual libs - U.S. English',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.com',
            COMMENTS => 'Inventory Scout Microcode Catalog',
            VERSION  => '2.2.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.ldb',
            COMMENTS => 'Inventory Scout Logic Database',
            VERSION  => '2.2.0.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.msg.en_US.rte',
            COMMENTS => 'Inventory Scout Messages - U.S. English',
            VERSION  => '2.1.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.rte',
            COMMENTS => 'Inventory Scout Runtime',
            VERSION  => '2.2.0.13',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'lum.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '5.1.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'lum.msg.en_US.base.cli',
            COMMENTS => 'LUM Runtime Code Messages - U.S. English',
            VERSION  => '5.1.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssh.base.client',
            COMMENTS => 'Open Secure Shell Commands',
            VERSION  => '5.2.0.5300',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssh.base.server',
            COMMENTS => 'Open Secure Shell Server',
            VERSION  => '5.2.0.5300',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssh.man.en_US',
            COMMENTS => 'Open Secure Shell Documentation - U.S. English',
            VERSION  => '5.2.0.5300',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssh.msg.en_US',
            COMMENTS => 'Open Secure Shell Messages - U.S. English',
            VERSION  => '5.2.0.5300',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssl.base',
            COMMENTS => 'Open Secure Socket Layer',
            VERSION  => '0.9.8.1100',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssl.license',
            COMMENTS => 'Open Secure Socket License',
            VERSION  => '0.9.8.1100',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssl.man.en_US',
            COMMENTS => 'Open Secure Socket Layer',
            VERSION  => '0.9.8.1100',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'perfagent.tools',
            COMMENTS => 'Local Performance Analysis & Control Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'perl.libext',
            COMMENTS => 'Perl Library Extensions',
            VERSION  => '2.2.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'perl.rte',
            COMMENTS => 'Perl Version 5 Runtime Environment',
            VERSION  => '5.8.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.msg.en_US.rte',
            COMMENTS => 'Printer Backend Messages - U.S. English',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.rte',
            COMMENTS => 'Printer Backend',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rpm.rte',
            COMMENTS => 'RPM Package Manager',
            VERSION  => '3.0.5.49',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.auditrm',
            COMMENTS => 'RSCT Audit Log Resource Manager',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.errm',
            COMMENTS => 'RSCT Event Response Resource Manager',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.fsrm',
            COMMENTS => 'RSCT File System Resource Manager',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.gui',
            COMMENTS => 'RSCT Graphical User Interface',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.hostrm',
            COMMENTS => 'RSCT Host Resource Manager',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.lprm',
            COMMENTS => 'RSCT Least Privilege Resource Manager',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.microsensor',
            COMMENTS => 'RSCT MicroSensor Resource Manager',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.rmc',
            COMMENTS => 'RSCT Resource Monitoring and Control',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.sec',
            COMMENTS => 'RSCT Security',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.sensorrm',
            COMMENTS => 'RSCT Sensor Resource Manager',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.sr',
            COMMENTS => 'RSCT Registry',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.utils',
            COMMENTS => 'RSCT Utilities',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - U.S. English (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - U.S. English (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - U.S. English (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.gui',
            COMMENTS => 'RSCT GUI Msgs - U.S. English (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - U.S. English (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - U.S. English (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - U.S. English (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.sec',
            COMMENTS => 'RSCT Security Msgs - U.S. English (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - U.S. English (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.sr',
            COMMENTS => 'RSCT Registry Msgs - U.S. English (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.EN_US.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - U.S. English (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - U.S. English',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - U.S. English',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - U.S. English',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.gui',
            COMMENTS => 'RSCT GUI Msgs - U.S. English',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.gui.com',
            COMMENTS => 'RSCT GUI JAVA Msgs - U.S. English',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - U.S. English',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - U.S. English',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.microsensorrm',
            COMMENTS => 'RSCT MicorSensor RM Msgs - U.S. English',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - U.S. English',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.rmc.com',
            COMMENTS => 'RSCT RMC JAVA Msgs - U.S. English',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.sec',
            COMMENTS => 'RSCT Security Msgs - U.S. English',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - U.S. English',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.sr',
            COMMENTS => 'RSCT Registry Msgs - U.S. English',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.en_US.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - U.S. English',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'wio.common',
            COMMENTS => 'Common I/O Support for Workload Partitions',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'wio.fcp',
            COMMENTS => 'FC I/O Support for Workload Partitions',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.aix61.rte',
            COMMENTS => 'XL C/C++ Runtime for AIX 6.1',
            VERSION  => '10.1.0.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.cpp',
            COMMENTS => 'C for AIX Preprocessor',
            VERSION  => '9.0.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.msg.en_US.cpp',
            COMMENTS => 'C for AIX Preprocessor Messages--U.S. English',
            VERSION  => '9.0.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.msg.en_US.rte',
            COMMENTS => 'XL C/C++ Runtime Messages--U.S. English',
            VERSION  => '10.1.0.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.rte',
            COMMENTS => 'XL C/C++ Runtime',
            VERSION  => '10.1.0.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.sup.aix50.rte',
            COMMENTS => 'XL C/C++ Runtime for AIX 5.2',
            VERSION  => '9.0.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Java14.sdk',
            COMMENTS => 'Java SDK 32-bit',
            VERSION  => '1.4.2.275',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'Tivoli_Management_Agent.client.rte',
            COMMENTS => 'Management Framework Endpoint Runtime"',
            VERSION  => '3.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.64bit',
            COMMENTS => 'Base Operating System 64 bit Runtime',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.acct',
            COMMENTS => 'Accounting Services',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.adt.base',
            COMMENTS => 'Base Application Development Toolkit',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.aixpert.cmds',
            COMMENTS => 'AIX Security Hardening',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.cdmount',
            COMMENTS => 'CD/DVD Automount Facility',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.com',
            COMMENTS => 'Common Hardware Diagnostics',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.rte',
            COMMENTS => 'Hardware Diagnostics',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.util',
            COMMENTS => 'Hardware Diagnostics Utilities',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.iocp.rte',
            COMMENTS => 'I/O Completion Ports API',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.mh',
            COMMENTS => 'Mail Handler',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.mp64',
            COMMENTS => 'Base Operating System 64-bit Multiprocessor Runtime',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ipsec.keymgt',
            COMMENTS => 'IP Security Key Management',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ipsec.rte',
            COMMENTS => 'IP Security',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ncs',
            COMMENTS => 'Network Computing System 1.5.1',
            VERSION  => '6.1.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.client',
            COMMENTS => 'Network File System Client',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.nis.client',
            COMMENTS => 'Network Information Service Client',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.snapp',
            COMMENTS => 'System Networking Analysis and Performance Pilot',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.client',
            COMMENTS => 'TCP/IP Client Support',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.server',
            COMMENTS => 'TCP/IP Server',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.smit',
            COMMENTS => 'TCP/IP SMIT Support',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.uucp',
            COMMENTS => 'Unix to Unix Copy Program',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.diag_tool',
            COMMENTS => 'Performance Diagnostic Tool',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.libperfstat',
            COMMENTS => 'Performance Statistics Library Interface',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.perfstat',
            COMMENTS => 'Performance Statistics Interface',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.tools',
            COMMENTS => 'Base Performance Tools',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.tune',
            COMMENTS => 'Performance Tuning Support',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.pmapi.pmsvcs',
            COMMENTS => 'Performance Monitor API Kernel Extension',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.pmapi.tools',
            COMMENTS => 'Performance Monitor API Tools',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte',
            COMMENTS => 'Base Operating System Runtime',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.Dt',
            COMMENTS => 'Desktop Integrator',
            VERSION  => '6.1.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.ILS',
            COMMENTS => 'International Language Support',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.SRC',
            COMMENTS => 'System Resource Controller',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.aio',
            COMMENTS => 'Asynchronous I/O Extension',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.archive',
            COMMENTS => 'Archive Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.bind_cmds',
            COMMENTS => 'Binder and Loader Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.boot',
            COMMENTS => 'Boot Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.commands',
            COMMENTS => 'Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.console',
            COMMENTS => 'Console',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.control',
            COMMENTS => 'System Control Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
        NAME     => 'bos.rte.cron',
        COMMENTS => 'Batch Operations',
        VERSION  => '6.1.4.0',
        FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.date',
            COMMENTS => 'Date Control Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.devices',
            COMMENTS => 'Base Device Drivers',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.diag',
            COMMENTS => 'Diagnostics',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.edit',
            COMMENTS => 'Editors',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.filesystem',
            COMMENTS => 'Filesystem Administration',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.iconv',
            COMMENTS => 'Language Converters',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.install',
            COMMENTS => 'LPP Install Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.jfscomp',
            COMMENTS => 'JFS Compression',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.libc',
            COMMENTS => 'libc Library',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.libcfg',
            COMMENTS => 'libcfg Library',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.libcur',
            COMMENTS => 'libcurses Library',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.libpthreads',
            COMMENTS => 'pthreads Library',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.loc',
            COMMENTS => 'Base Locale Support',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.lvm',
            COMMENTS => 'Logical Volume Manager',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.methods',
            COMMENTS => 'Device Config Methods',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.misc_cmds',
            COMMENTS => 'Miscellaneous Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.mlslib',
            COMMENTS => 'Trusted AIX Libraries',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.net',
            COMMENTS => 'Network',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.odm',
            COMMENTS => 'Object Data Manager',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.printers',
            COMMENTS => 'Front End Printer Support',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.security',
            COMMENTS => 'Base Security Function',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.serv_aid',
            COMMENTS => 'Error Log Service Aids',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.shell',
            COMMENTS => 'Shells (bsh, ksh, csh)',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.tty',
            COMMENTS => 'Base TTY Support and Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.suma',
            COMMENTS => 'Service Update Management Assistant (SUMA)',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.loginlic',
            COMMENTS => 'License Management',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.nim.client',
            COMMENTS => 'Network Install Manager - Client Tools',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.quota',
            COMMENTS => 'Filesystem Quota Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.serv_aid',
            COMMENTS => 'Software Error Logging and Dump Service Aids',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.smit',
            COMMENTS => 'System Management Interface Tool (SMIT)',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.sysbr',
            COMMENTS => 'System Backup and BOS Install Utilities',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.trace',
            COMMENTS => 'Software Trace Service Aids',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.wpars',
            COMMENTS => 'AIX Workload Partitions',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'cas.client.rte',
            COMMENTS => 'Certificate Authentication Services Client',
            VERSION  => '5.2.0.50',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'clic.rte.kernext',
            COMMENTS => 'CryptoLite for C Kernel',
            VERSION  => '4.7.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.client',
            COMMENTS => 'Cluster Systems Management Client',
            VERSION  => '1.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.core',
            COMMENTS => 'Cluster Systems Management Core',
            VERSION  => '1.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.deploy',
            COMMENTS => 'Cluster Systems Management Deployment Component',
            VERSION  => '1.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.diagnostics',
            COMMENTS => 'Cluster Systems Management Probe Manager / Diagnostics',
            VERSION  => '1.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.dsh',
            COMMENTS => 'Cluster Systems Management Dsh',
            VERSION  => '1.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'idsldap.clt32bit61.rte',
            COMMENTS => 'Directory Server - 32 bit Client',
            VERSION  => '6.1.0.26',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'idsldap.cltbase61.rte',
            COMMENTS => 'Directory Server - Base Client',
            VERSION  => '6.1.0.26',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'ifor_ls.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '6.1.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'invscout.com',
            COMMENTS => 'Inventory Scout Microcode Catalog',
            VERSION  => '2.2.0.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'invscout.ldb',
            COMMENTS => 'Inventory Scout Logic Database',
            VERSION  => '2.2.0.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'invscout.rte',
            COMMENTS => 'Inventory Scout Runtime',
            VERSION  => '2.2.0.13',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'lum.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '5.1.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'openssh.base.client',
            COMMENTS => 'Open Secure Shell Commands',
            VERSION  => '5.2.0.5300',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'openssh.base.server',
            COMMENTS => 'Open Secure Shell Server',
            VERSION  => '5.2.0.5300',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'openssl.base',
            COMMENTS => 'Open Secure Socket Layer',
            VERSION  => '0.9.8.1100',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'perfagent.tools',
            COMMENTS => 'Local Performance Analysis & Control Commands',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'printers.rte',
            COMMENTS => 'Printer Backend',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rpm.rte',
            COMMENTS => 'RPM Package Manager',
            VERSION  => '3.0.5.49',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.auditrm',
            COMMENTS => 'RSCT Audit Log Resource Manager',
            VERSION  => '2.5.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.errm',
            COMMENTS => 'RSCT Event Response Resource Manager',
            VERSION  => '2.5.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.fsrm',
            COMMENTS => 'RSCT File System Resource Manager',
            VERSION  => '2.5.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.hostrm',
            COMMENTS => 'RSCT Host Resource Manager',
            VERSION  => '2.5.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.lprm',
            COMMENTS => 'RSCT Least Privilege Resource Manager',
            VERSION  => '2.5.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.microsensor',
            COMMENTS => 'RSCT MicroSensor Resource Manager',
            VERSION  => '2.5.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.rmc',
            COMMENTS => 'RSCT Resource Monitoring and Control',
            VERSION  => '2.5.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.sec',
            COMMENTS => 'RSCT Security',
            VERSION  => '2.5.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.sensorrm',
            COMMENTS => 'RSCT Sensor Resource Manager',
            VERSION  => '2.5.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.sr',
            COMMENTS => 'RSCT Registry',
            VERSION  => '2.5.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.utils',
            COMMENTS => 'RSCT Utilities',
            VERSION  => '2.5.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'wio.common',
            COMMENTS => 'Common I/O Support for Workload Partitions',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.terminfo.ansi.data',
            COMMENTS => 'Amer National Stds Institute Terminal Defs',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.com.data',
            COMMENTS => 'Common Terminal Definitions',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.dec.data',
            COMMENTS => 'Digital Equipment Corp. Terminal Definitions',
            VERSION  => '6.1.1.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.ibm.data',
            COMMENTS => 'IBM Terminal Definitions',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.pc.data',
            COMMENTS => 'Personal Computer Terminal Definitions',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.print.data',
            COMMENTS => 'Generic Line Printer Terminal Definitions',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.televideo.data',
            COMMENTS => 'Televideo Terminal Definitions',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.wyse.data',
            COMMENTS => 'Wyse Terminal Definitions',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.spell.data',
            COMMENTS => 'Writer\'s Tools Data',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.tfs.data',
            COMMENTS => 'Text Formatting Services Data',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        }
    ],
    'aix-6.1b' => [
        {
            NAME     => 'Atape.driver',
            COMMENTS => 'IBM AIX Enhanced Tape and Medium Changer Device Driver',
            VERSION  => '12.0.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ICU4C.rte',
            COMMENTS => 'International Components for Unicode',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Tivoli_Management_Agent.client.rte',
            COMMENTS => 'Management Framework Endpoint Runtime"',
            VERSION  => '3.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'artex.base.rte',
            COMMENTS => 'AIX Runtime Expert',
            VERSION  => '6.1.6.3',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'artex.base.samples',
            COMMENTS => 'AIX Runtime Expert sample profiles',
            VERSION  => '6.1.6.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.64bit',
            COMMENTS => 'Base Operating System 64 bit Runtime',
            VERSION  => '6.1.6.4',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.acct',
            COMMENTS => 'Accounting Services',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.base',
            COMMENTS => 'Base Application Development Toolkit',
            VERSION  => '6.1.6.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.include',
            COMMENTS => 'Base Application Development Include Files',
            VERSION  => '6.1.6.4',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.adt.lib',
            COMMENTS => 'Base Application Development Libraries',
            VERSION  => '6.1.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.aixpert.cmds',
            COMMENTS => 'AIX Security Hardening',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.alt_disk_install.boot_images',
            COMMENTS => 'Alternate Disk Installation Disk Boot Images',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.alt_disk_install.rte',
            COMMENTS => 'Alternate Disk Installation Runtime',
            VERSION  => '6.1.6.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.cdmount',
            COMMENTS => 'CD/DVD Automount Facility',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.content_list',
            COMMENTS => 'AIX Release Content List',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.com',
            COMMENTS => 'Common Hardware Diagnostics',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.rte',
            COMMENTS => 'Hardware Diagnostics',
            VERSION  => '6.1.6.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.diag.util',
            COMMENTS => 'Hardware Diagnostics Utilities',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.en_US.com',
            COMMENTS => 'WebSM/SMIT Context Helps - U.S. English',
            VERSION  => '6.1.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.en_US.smit',
            COMMENTS => 'SMIT Context Helps - U.S. English',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.help.msg.fr_FR.com',
            COMMENTS => 'WebSM/SMIT Context Helps - French',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.com',
            COMMENTS => 'Common Language to Language Converters',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.fr_FR',
            COMMENTS => 'EBCDIC & ASCII Language Converters - French',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iconv.ucs.com',
            COMMENTS => 'Unicode Base Converters for AIX Code Sets/Fonts',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.iocp.rte',
            COMMENTS => 'I/O Completion Ports API',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.com.utf',
            COMMENTS => 'Common Locale Support - UTF-8',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.iso.en_US',
            COMMENTS => 'Base System Locale ISO Code Set - U.S. English',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.iso.fr_FR',
            COMMENTS => 'Base System Locale ISO Code Set - French',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.loc.utf.FR_FR',
            COMMENTS => 'Base System Locale UTF Code Set - French',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mh',
            COMMENTS => 'Mail Handler',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mls.lib',
            COMMENTS => 'Trusted AIX Libraries',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.mp64',
            COMMENTS => 'Base Operating System 64-bit Multiprocessor Runtime',
            VERSION  => '6.1.6.4',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.FR_FR.net.tcp.client',
            COMMENTS => 'TCP/IP Messages - French (UTF)',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.FR_FR.rte',
            COMMENTS => 'Base OS Runtime Messages - French (UTF)',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.alt_disk_install.rte',
            COMMENTS => 'Alternate Disk Install Msgs - French',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.diag.rte',
            COMMENTS => 'Hardware Diagnostics Messages - French',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.net.tcp.client',
            COMMENTS => 'TCP/IP Messages - French',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.rte',
            COMMENTS => 'Base OS Runtime Messages - French',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.msg.fr_FR.txt.tfs',
            COMMENTS => 'Text Formatting Services Msgs - French',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.ncs',
            COMMENTS => 'Network Computing System 1.5.1',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.client',
            COMMENTS => 'Network File System Client',
            VERSION  => '6.1.6.4',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.server',
            COMMENTS => 'Network File System Server',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.snapp',
            COMMENTS => 'System Networking Analysis and Performance Pilot',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.adt',
            COMMENTS => 'TCP/IP Application Toolkit',
            VERSION  => '6.1.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.client',
            COMMENTS => 'TCP/IP Client Support',
            VERSION  => '6.1.6.4',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.server',
            COMMENTS => 'TCP/IP Server',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.smit',
            COMMENTS => 'TCP/IP SMIT Support',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.diag_tool',
            COMMENTS => 'Performance Diagnostic Tool',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.fdpr',
            COMMENTS => 'Feedback Directed Program Restructuring performance tool',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.libperfstat',
            COMMENTS => 'Performance Statistics Library Interface',
            VERSION  => '6.1.6.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.perfstat',
            COMMENTS => 'Performance Statistics Interface',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.proctools',
            COMMENTS => 'Proc Filesystem Tools',
            VERSION  => '6.1.6.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.tools',
            COMMENTS => 'Base Performance Tools',
            VERSION  => '6.1.6.4',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.perf.tune',
            COMMENTS => 'Performance Tuning Support',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.events',
            COMMENTS => 'Performance Monitor API Event Codes',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.lib',
            COMMENTS => 'Performance Monitor API Library',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.pmsvcs',
            COMMENTS => 'Performance Monitor API Kernel Extension',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.samples',
            COMMENTS => 'Performance Monitor API Samples',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.pmapi.tools',
            COMMENTS => 'Performance Monitor API Tools',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte',
            COMMENTS => 'Base Operating System Runtime',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.Dt',
            COMMENTS => 'Desktop Integrator',
            VERSION  => '6.1.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.ILS',
            COMMENTS => 'International Language Support',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.SRC',
            COMMENTS => 'System Resource Controller',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.X11',
            COMMENTS => 'AIXwindows Device Support',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.aio',
            COMMENTS => 'Asynchronous I/O Extension',
            VERSION  => '6.1.6.3',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.archive',
            COMMENTS => 'Archive Commands',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.bind_cmds',
            COMMENTS => 'Binder and Loader Commands',
            VERSION  => '6.1.6.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.boot',
            COMMENTS => 'Boot Commands',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.bosinst',
            COMMENTS => 'Base OS Install Commands',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.commands',
            COMMENTS => 'Commands',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.compare',
            COMMENTS => 'File Compare Commands',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.console',
            COMMENTS => 'Console',
            VERSION  => '6.1.6.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.control',
            COMMENTS => 'System Control Commands',
            VERSION  => '6.1.6.4',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.cron',
            COMMENTS => 'Batch Operations',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.date',
            COMMENTS => 'Date Control Commands',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.devices',
            COMMENTS => 'Base Device Drivers',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.devices_msg',
            COMMENTS => 'Device Driver Messages',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.diag',
            COMMENTS => 'Diagnostics',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.edit',
            COMMENTS => 'Editors',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.filesystem',
            COMMENTS => 'Filesystem Administration',
            VERSION  => '6.1.6.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.iconv',
            COMMENTS => 'Language Converters',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.ifor_ls',
            COMMENTS => 'iFOR/LS Libraries',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.im',
            COMMENTS => 'Input Methods',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.install',
            COMMENTS => 'LPP Install Commands',
            VERSION  => '6.1.6.4',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.jfscomp',
            COMMENTS => 'JFS Compression',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libc',
            COMMENTS => 'libc Library',
            VERSION  => '6.1.6.4',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libcfg',
            COMMENTS => 'libcfg Library',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libcur',
            COMMENTS => 'libcurses Library',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libdbm',
            COMMENTS => 'libdbm Library',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libnetsvc',
            COMMENTS => 'Network Services Libraries',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libpthreads',
            COMMENTS => 'libpthreads Library',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libqb',
            COMMENTS => 'libqb Library',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.libs',
            COMMENTS => 'libs Library',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.loc',
            COMMENTS => 'Base Locale Support',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.lvm',
            COMMENTS => 'Logical Volume Manager',
            VERSION  => '6.1.6.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.man',
            COMMENTS => 'Man Commands',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.methods',
            COMMENTS => 'Device Config Methods',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.misc_cmds',
            COMMENTS => 'Miscellaneous Commands',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.mlslib',
            COMMENTS => 'Trusted AIX Libraries',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.net',
            COMMENTS => 'Network',
            VERSION  => '6.1.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.odm',
            COMMENTS => 'Object Data Manager',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.printers',
            COMMENTS => 'Front End Printer Support',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.security',
            COMMENTS => 'Base Security Function',
            VERSION  => '6.1.6.4',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.serv_aid',
            COMMENTS => 'Error Log Service Aids',
            VERSION  => '6.1.6.4',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.shell',
            COMMENTS => 'Shells (bsh, ksh, csh)',
            VERSION  => '6.1.6.4',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.streams',
            COMMENTS => 'Streams Libraries',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.rte.tty',
            COMMENTS => 'Base TTY Support and Commands',
            VERSION  => '6.1.6.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.suma',
            COMMENTS => 'Service Update Management Assistant (SUMA)',
            VERSION  => '6.1.5.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.swma',
            COMMENTS => 'Software Maintenance Agreement',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.loginlic',
            COMMENTS => 'License Management',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.nim.client',
            COMMENTS => 'Network Install Manager - Client Tools',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.nim.master',
            COMMENTS => 'Network Install Manager - Master Tools',
            VERSION  => '6.1.6.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.nim.spot',
            COMMENTS => 'Network Install Manager - SPOT',
            VERSION  => '6.1.6.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.quota',
            COMMENTS => 'Filesystem Quota Commands',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.serv_aid',
            COMMENTS => 'Software Error Logging and Dump Service Aids',
            VERSION  => '6.1.6.3',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.smit',
            COMMENTS => 'System Management Interface Tool (SMIT)',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.sysbr',
            COMMENTS => 'System Backup and BOS Install Utilities',
            VERSION  => '6.1.6.3',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.trace',
            COMMENTS => 'Software Trace Service Aids',
            VERSION  => '6.1.6.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.rte',
            COMMENTS => 'Run-time Environment for AIX Terminals',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.spell',
            COMMENTS => 'Writer\'s Tools Commands',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.tfs',
            COMMENTS => 'Text Formatting Services Commands',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'bos.wpars',
            COMMENTS => 'AIX Workload Partitions',
            VERSION  => '6.1.6.3',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'clic.rte.kernext',
            COMMENTS => 'CryptoLite for C Kernel',
            VERSION  => '4.7.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'clic.rte.lib',
            COMMENTS => 'CryptoLite for C Library',
            VERSION  => '4.7.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.client',
            COMMENTS => 'Cluster Systems Management Client',
            VERSION  => '1.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.core',
            COMMENTS => 'Cluster Systems Management Core',
            VERSION  => '1.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.deploy',
            COMMENTS => 'Cluster Systems Management Deployment Component',
            VERSION  => '1.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.diagnostics',
            COMMENTS => 'Cluster Systems Management Probe Manager / Diagnostics',
            VERSION  => '1.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.dsh',
            COMMENTS => 'Cluster Systems Management Dsh',
            VERSION  => '1.7.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.FR_FR.core',
            COMMENTS => 'CSM Core Func Msgs - French (UTF)',
            VERSION  => '1.7.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'csm.msg.fr_FR.core',
            COMMENTS => 'CSM Core Func Msgs - French',
            VERSION  => '1.7.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'expect.base',
            COMMENTS => 'Binary executable files of Expect',
            VERSION  => '5.42.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'expect.man.en_US',
            COMMENTS => 'Expect man page documentation',
            VERSION  => '5.42.1.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'ifor_ls.html.en_US.base.cli',
            COMMENTS => 'LUM HTML Guides - U.S. English',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'infocenter.man.EN_US.commands',
            COMMENTS => 'AIX manual commands - U.S. English',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'infocenter.man.EN_US.files',
            COMMENTS => 'AIX manual files - U.S. English',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'infocenter.man.EN_US.libs',
            COMMENTS => 'AIX manual libs - U.S. English',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.com',
            COMMENTS => 'Inventory Scout Microcode Catalog',
            VERSION  => '2.2.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.ldb',
            COMMENTS => 'Inventory Scout Logic Database',
            VERSION  => '2.2.0.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.msg.fr_FR.rte',
            COMMENTS => 'Inventory Scout Messages - French',
            VERSION  => '2.1.0.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'invscout.rte',
            COMMENTS => 'Inventory Scout Runtime',
            VERSION  => '2.2.0.15',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'lum.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '5.1.2.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssh.base.client',
            COMMENTS => 'Open Secure Shell Commands',
            VERSION  => '5.4.0.6100',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssh.base.server',
            COMMENTS => 'Open Secure Shell Server',
            VERSION  => '5.4.0.6100',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssh.msg.fr_FR',
            COMMENTS => 'Open Secure Shell Messages - French',
            VERSION  => '5.4.0.6100',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssl.base',
            COMMENTS => 'Open Secure Socket Layer',
            VERSION  => '0.9.8.1300',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssl.license',
            COMMENTS => 'Open Secure Socket License',
            VERSION  => '0.9.8.1300',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'openssl.man.en_US',
            COMMENTS => 'Open Secure Socket Layer',
            VERSION  => '0.9.8.1300',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'perfagent.tools',
            COMMENTS => 'Local Performance Analysis & Control Commands',
            VERSION  => '6.1.6.4',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'perl.libext',
            COMMENTS => 'Perl Library Extensions',
            VERSION  => '2.2.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'perl.rte',
            COMMENTS => 'Perl Version 5 Runtime Environment',
            VERSION  => '5.8.8.120',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.msg.fr_FR.rte',
            COMMENTS => 'Printer Backend Messages - French',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'printers.rte',
            COMMENTS => 'Printer Backend',
            VERSION  => '6.1.6.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rpm.rte',
            COMMENTS => 'RPM Package Manager',
            VERSION  => '3.0.5.51',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.auditrm',
            COMMENTS => 'RSCT Audit Log Resource Manager',
            VERSION  => '3.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.errm',
            COMMENTS => 'RSCT Event Response Resource Manager',
            VERSION  => '3.1.0.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.fsrm',
            COMMENTS => 'RSCT File System Resource Manager',
            VERSION  => '3.1.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.gui',
            COMMENTS => 'RSCT Graphical User Interface',
            VERSION  => '3.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.hostrm',
            COMMENTS => 'RSCT Host Resource Manager',
            VERSION  => '3.1.0.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.lprm',
            COMMENTS => 'RSCT Least Privilege Resource Manager',
            VERSION  => '3.1.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.microsensor',
            COMMENTS => 'RSCT MicroSensor Resource Manager',
            VERSION  => '3.1.0.3',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.rmc',
            COMMENTS => 'RSCT Resource Monitoring and Control',
            VERSION  => '3.1.0.3',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.sec',
            COMMENTS => 'RSCT Security',
            VERSION  => '3.1.0.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.sensorrm',
            COMMENTS => 'RSCT Sensor Resource Manager',
            VERSION  => '3.1.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.sr',
            COMMENTS => 'RSCT Registry',
            VERSION  => '3.1.0.2',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.core.utils',
            COMMENTS => 'RSCT Utilities',
            VERSION  => '3.1.0.3',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - French (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - French (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - French (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.gui',
            COMMENTS => 'RSCT GUI Msgs - French (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - French (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - French (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - French (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.sec',
            COMMENTS => 'RSCT Security Msgs - French (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - French (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.sr',
            COMMENTS => 'RSCT Registry Msgs - French (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.FR_FR.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - French (UTF)',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.auditrm',
            COMMENTS => 'RSCT Audit Log RM Msgs - French',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.errm',
            COMMENTS => 'RSCT Event Response RM Msgs - French',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.fsrm',
            COMMENTS => 'RSCT File System RM Msgs - French',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.gui',
            COMMENTS => 'RSCT GUI Msgs - French',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.gui.com',
            COMMENTS => 'RSCT GUI JAVA Msgs - French',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.hostrm',
            COMMENTS => 'RSCT Host RM Msgs - French',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.lprm',
            COMMENTS => 'RSCT LPRM Msgs - French',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.microsensorrm',
            COMMENTS => 'RSCT MicorSensor RM Msgs - French',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.rmc',
            COMMENTS => 'RSCT RMC Msgs - French',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.rmc.com',
            COMMENTS => 'RSCT RMC JAVA Msgs - French',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.sec',
            COMMENTS => 'RSCT Security Msgs - French',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.sensorrm',
            COMMENTS => 'RSCT Sensor RM Msgs - French',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.sr',
            COMMENTS => 'RSCT Registry Msgs - French',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'rsct.msg.fr_FR.core.utils',
            COMMENTS => 'RSCT Utilities Msgs - French',
            VERSION  => '2.5.4.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'samba.base',
            COMMENTS => 'Samba for AIX',
            VERSION  => '3.2.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'samba.license',
            COMMENTS => 'Samba for AIX',
            VERSION  => '3.2.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'samba.man.en_US',
            COMMENTS => 'Samba for AIX',
            VERSION  => '3.2.8.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'tcl.base',
            COMMENTS => 'Binary executable files of Tcl',
            VERSION  => '8.4.7.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'tcl.man.en_US',
            COMMENTS => 'Tcl man page documentation',
            VERSION  => '8.4.7.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'tk.base',
            COMMENTS => 'Binary executable files of Tk',
            VERSION  => '8.4.7.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'tk.man.en_US',
            COMMENTS => 'Tk man page documentation',
            VERSION  => '8.4.7.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'wio.common',
            COMMENTS => 'Common I/O Support for Workload Partitions',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'wio.fcp',
            COMMENTS => 'FC I/O Support for Workload Partitions',
            VERSION  => '6.1.6.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.aix61.rte',
            COMMENTS => 'XL C/C++ Runtime for AIX 6.1',
            VERSION  => '11.1.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.cpp',
            COMMENTS => 'C for AIX Preprocessor',
            VERSION  => '9.0.0.0',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.rte',
            COMMENTS => 'XL C/C++ Runtime',
            VERSION  => '11.1.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'xlC.sup.aix50.rte',
            COMMENTS => 'XL C/C++ Runtime for AIX 5.2',
            VERSION  => '9.0.0.1',
            FOLDER   => '/usr/lib/objrepos'
        },
        {
            NAME     => 'Tivoli_Management_Agent.client.rte',
            COMMENTS => 'Management Framework Endpoint Runtime"',
            VERSION  => '3.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'artex.base.rte',
            COMMENTS => 'AIX Runtime Expert',
            VERSION  => '6.1.6.3',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'artex.base.samples',
            COMMENTS => 'AIX Runtime Expert sample profiles',
            VERSION  => '6.1.6.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.64bit',
            COMMENTS => 'Base Operating System 64 bit Runtime',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.acct',
            COMMENTS => 'Accounting Services',
            VERSION  => '6.1.6.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.adt.base',
            COMMENTS => 'Base Application Development Toolkit',
            VERSION  => '6.1.6.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.aixpert.cmds',
            COMMENTS => 'AIX Security Hardening',
            VERSION  => '6.1.6.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.alt_disk_install.rte',
            COMMENTS => 'Alternate Disk Installation Runtime',
            VERSION  => '6.1.6.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.cdmount',
            COMMENTS => 'CD/DVD Automount Facility',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.com',
            COMMENTS => 'Common Hardware Diagnostics',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.rte',
            COMMENTS => 'Hardware Diagnostics',
            VERSION  => '6.1.6.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.diag.util',
            COMMENTS => 'Hardware Diagnostics Utilities',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.iocp.rte',
            COMMENTS => 'I/O Completion Ports API',
            VERSION  => '6.1.4.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.mh',
            COMMENTS => 'Mail Handler',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.mp64',
            COMMENTS => 'Base Operating System 64-bit Multiprocessor Runtime',
            VERSION  => '6.1.6.4',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.ncs',
            COMMENTS => 'Network Computing System 1.5.1',
            VERSION  => '6.1.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.nfs.client',
            COMMENTS => 'Network File System Client',
            VERSION  => '6.1.6.4',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.snapp',
            COMMENTS => 'System Networking Analysis and Performance Pilot',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.client',
            COMMENTS => 'TCP/IP Client Support',
            VERSION  => '6.1.6.4',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.server',
            COMMENTS => 'TCP/IP Server',
            VERSION  => '6.1.6.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.net.tcp.smit',
            COMMENTS => 'TCP/IP SMIT Support',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.diag_tool',
            COMMENTS => 'Performance Diagnostic Tool',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.libperfstat',
            COMMENTS => 'Performance Statistics Library Interface',
            VERSION  => '6.1.6.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.perfstat',
            COMMENTS => 'Performance Statistics Interface',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.tools',
            COMMENTS => 'Base Performance Tools',
            VERSION  => '6.1.6.4',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.perf.tune',
            COMMENTS => 'Performance Tuning Support',
            VERSION  => '6.1.6.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.pmapi.pmsvcs',
            COMMENTS => 'Performance Monitor API Kernel Extension',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.pmapi.tools',
            COMMENTS => 'Performance Monitor API Tools',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte',
            COMMENTS => 'Base Operating System Runtime',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.Dt',
            COMMENTS => 'Desktop Integrator',
            VERSION  => '6.1.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.ILS',
            COMMENTS => 'International Language Support',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.SRC',
            COMMENTS => 'System Resource Controller',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.aio',
            COMMENTS => 'Asynchronous I/O Extension',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.archive',
            COMMENTS => 'Archive Commands',
            VERSION  => '6.1.6.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.bind_cmds',
            COMMENTS => 'Binder and Loader Commands',
            VERSION  => '6.1.6.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.boot',
            COMMENTS => 'Boot Commands',
            VERSION  => '6.1.6.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.commands',
            COMMENTS => 'Commands',
            VERSION  => '6.1.6.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.console',
            COMMENTS => 'Console',
            VERSION  => '6.1.6.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.control',
            COMMENTS => 'System Control Commands',
            VERSION  => '6.1.6.4',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.cron',
            COMMENTS => 'Batch Operations',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.date',
            COMMENTS => 'Date Control Commands',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.devices',
            COMMENTS => 'Base Device Drivers',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.diag',
            COMMENTS => 'Diagnostics',
            VERSION  => '6.1.6.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.edit',
            COMMENTS => 'Editors',
            VERSION  => '6.1.6.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.filesystem',
            COMMENTS => 'Filesystem Administration',
            VERSION  => '6.1.6.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.iconv',
            COMMENTS => 'Language Converters',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.install',
            COMMENTS => 'LPP Install Commands',
            VERSION  => '6.1.6.4',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.jfscomp',
            COMMENTS => 'JFS Compression',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.libc',
            COMMENTS => 'libc Library',
            VERSION  => '6.1.6.4',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.libcfg',
            COMMENTS => 'libcfg Library',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.libcur',
            COMMENTS => 'libcurses Library',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.libpthreads',
            COMMENTS => 'libpthreads Library',
            VERSION  => '6.1.6.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.loc',
            COMMENTS => 'Base Locale Support',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.lvm',
            COMMENTS => 'Logical Volume Manager',
            VERSION  => '6.1.6.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.methods',
            COMMENTS => 'Device Config Methods',
            VERSION  => '6.1.6.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.misc_cmds',
            COMMENTS => 'Miscellaneous Commands',
            VERSION  => '6.1.6.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.mlslib',
            COMMENTS => 'Trusted AIX Libraries',
            VERSION  => '6.1.4.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.net',
            COMMENTS => 'Network',
            VERSION  => '6.1.5.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.odm',
            COMMENTS => 'Object Data Manager',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.printers',
            COMMENTS => 'Front End Printer Support',
            VERSION  => '6.1.6.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.security',
            COMMENTS => 'Base Security Function',
            VERSION  => '6.1.6.4',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.serv_aid',
            COMMENTS => 'Error Log Service Aids',
            VERSION  => '6.1.6.4',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.shell',
            COMMENTS => 'Shells (bsh, ksh, csh)',
            VERSION  => '6.1.6.4',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.rte.tty',
            COMMENTS => 'Base TTY Support and Commands',
            VERSION  => '6.1.6.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.suma',
            COMMENTS => 'Service Update Management Assistant (SUMA)',
            VERSION  => '6.1.5.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.loginlic',
            COMMENTS => 'License Management',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.nim.client',
            COMMENTS => 'Network Install Manager - Client Tools',
            VERSION  => '6.1.6.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.quota',
            COMMENTS => 'Filesystem Quota Commands',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.serv_aid',
            COMMENTS => 'Software Error Logging and Dump Service Aids',
            VERSION  => '6.1.6.3',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.smit',
            COMMENTS => 'System Management Interface Tool (SMIT)',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.sysbr',
            COMMENTS => 'System Backup and BOS Install Utilities',
            VERSION  => '6.1.6.3',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.sysmgt.trace',
            COMMENTS => 'Software Trace Service Aids',
            VERSION  => '6.1.6.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.wpars',
            COMMENTS => 'AIX Workload Partitions',
            VERSION  => '6.1.6.3',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'clic.rte.kernext',
            COMMENTS => 'CryptoLite for C Kernel',
            VERSION  => '4.7.0.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.client',
            COMMENTS => 'Cluster Systems Management Client',
            VERSION  => '1.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.core',
            COMMENTS => 'Cluster Systems Management Core',
            VERSION  => '1.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.deploy',
            COMMENTS => 'Cluster Systems Management Deployment Component',
            VERSION  => '1.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.diagnostics',
            COMMENTS => 'Cluster Systems Management Probe Manager / Diagnostics',
            VERSION  => '1.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'csm.dsh',
            COMMENTS => 'Cluster Systems Management Dsh',
            VERSION  => '1.7.1.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'ifor_ls.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '6.1.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'invscout.com',
            COMMENTS => 'Inventory Scout Microcode Catalog',
            VERSION  => '2.2.0.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'invscout.ldb',
            COMMENTS => 'Inventory Scout Logic Database',
            VERSION  => '2.2.0.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'invscout.rte',
            COMMENTS => 'Inventory Scout Runtime',
            VERSION  => '2.2.0.15',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'lum.base.cli',
            COMMENTS => 'License Use Management Runtime Code',
            VERSION  => '5.1.2.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'openssh.base.client',
            COMMENTS => 'Open Secure Shell Commands',
            VERSION  => '5.4.0.6100',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'openssh.base.server',
            COMMENTS => 'Open Secure Shell Server',
            VERSION  => '5.4.0.6100',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'openssl.base',
            COMMENTS => 'Open Secure Socket Layer',
            VERSION  => '0.9.8.1300',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'perfagent.tools',
            COMMENTS => 'Local Performance Analysis & Control Commands',
            VERSION  => '6.1.6.4',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'printers.rte',
            COMMENTS => 'Printer Backend',
            VERSION  => '6.1.6.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rpm.rte',
            COMMENTS => 'RPM Package Manager',
            VERSION  => '3.0.5.51',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.auditrm',
            COMMENTS => 'RSCT Audit Log Resource Manager',
            VERSION  => '3.1.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.errm',
            COMMENTS => 'RSCT Event Response Resource Manager',
            VERSION  => '3.1.0.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.fsrm',
            COMMENTS => 'RSCT File System Resource Manager',
            VERSION  => '3.1.0.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.gui',
            COMMENTS => 'RSCT Graphical User Interface',
            VERSION  => '3.1.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.hostrm',
            COMMENTS => 'RSCT Host Resource Manager',
            VERSION  => '3.1.0.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.lprm',
            COMMENTS => 'RSCT Least Privilege Resource Manager',
            VERSION  => '3.1.0.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.microsensor',
            COMMENTS => 'RSCT MicroSensor Resource Manager',
            VERSION  => '3.1.0.3',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.rmc',
            COMMENTS => 'RSCT Resource Monitoring and Control',
            VERSION  => '3.1.0.3',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.sec',
            COMMENTS => 'RSCT Security',
            VERSION  => '3.1.0.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.sensorrm',
            COMMENTS => 'RSCT Sensor Resource Manager',
            VERSION  => '3.1.0.1',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.sr',
            COMMENTS => 'RSCT Registry',
            VERSION  => '3.1.0.2',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'rsct.core.utils',
            COMMENTS => 'RSCT Utilities',
            VERSION  => '3.1.0.3',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'samba.base',
            COMMENTS => 'Samba for AIX',
            VERSION  => '3.2.8.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'wio.common',
            COMMENTS => 'Common I/O Support for Workload Partitions',
            VERSION  => '6.1.6.0',
            FOLDER   => '/etc/objrepos'
        },
        {
            NAME     => 'bos.terminfo.ansi.data',
            COMMENTS => 'Amer National Stds Institute Terminal Defs',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.com.data',
            COMMENTS => 'Common Terminal Definitions',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.dec.data',
            COMMENTS => 'Digital Equipment Corp. Terminal Definitions',
            VERSION  => '6.1.1.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.ibm.data',
            COMMENTS => 'IBM Terminal Definitions',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.pc.data',
            COMMENTS => 'Personal Computer Terminal Definitions',
            VERSION  => '6.1.4.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.print.data',
            COMMENTS => 'Generic Line Printer Terminal Definitions',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.televideo.data',
            COMMENTS => 'Televideo Terminal Definitions',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.terminfo.wyse.data',
            COMMENTS => 'Wyse Terminal Definitions',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.spell.data',
            COMMENTS => 'Writer\'s Tools Data',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        },
        {
            NAME     => 'bos.txt.tfs.data',
            COMMENTS => 'Text Formatting Services Data',
            VERSION  => '6.1.0.0',
            FOLDER   => '/usr/share/lib/objrepos'
        }
    ],
);

plan tests => (2 * scalar keys %tests) + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/aix/lslpp/$test";
    my $softwares = GLPI::Agent::Task::Inventory::AIX::Softwares::_getSoftwaresList(file => $file);
    cmp_deeply($softwares, $tests{$test}, "$test: parsing");
    lives_ok {
        $inventory->addEntry(section => 'SOFTWARES', entry => $_) foreach @$softwares;
    } "$test: registering";
}
