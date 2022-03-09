#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::Deep;
use Test::More;

use GLPI::Agent::Tools::Unix;

my %df_tests = (
    'freebsd' => [
        {
            VOLUMN     => '/dev/ad4s1a',
            TOTAL      => '1447',
            FREE       => '965',
            TYPE       => '/',
            FILESYSTEM => 'ufs'
        },
        {
            VOLUMN     => '/dev/ad4s1g',
            TOTAL      => '138968',
            FREE       => '12851',
            TYPE       => '/Donnees',
            FILESYSTEM => 'ufs'
        },
        {
            VOLUMN     => '/dev/ad4s1e',
            TOTAL      => '495',
            FREE       => '397',
            TYPE       => '/tmp',
            FILESYSTEM => 'ufs'
        },
        {
            VOLUMN     => '/dev/ad4s1f',
            TOTAL      => '19832',
            FREE       => '5118',
            TYPE       => '/usr',
            FILESYSTEM => 'ufs'
        },
        {
            VOLUMN     => '/dev/ad4s1d',
            TOTAL      => '3880',
            FREE       => '2571',
            TYPE       => '/var',
            FILESYSTEM => 'ufs'
        }
    ],
    'linux' => [
        {
            VOLUMN     => '/dev/sda5',
            TOTAL      => '12106',
            FREE       => '6528',
            TYPE       => '/',
            FILESYSTEM => 'ext4'
        },
        {
            VOLUMN     => '/dev/sda3',
            TOTAL      => '60002',
            FREE       => '40540',
            TYPE       => '/media/windows',
            FILESYSTEM => 'fuseblk'
        },
        {
            VOLUMN     => '/dev/sda7',
            TOTAL      => '44110',
            FREE       => '21930',
            TYPE       => '/home',
            FILESYSTEM => 'crypt'
        }
    ],
    'netbsd' => [
        {
            VOLUMN     => '/dev/wd0a',
            TOTAL      => '15112',
            FREE       => '3581',
            TYPE       => '/',
            FILESYSTEM => undef
          }
    ],
    'openbsd' => [
        {
            VOLUMN     => '/dev/wd0a',
            TOTAL      => '784',
            FREE       => '174',
            TYPE       => '/',
            FILESYSTEM => undef
        },
        {
            VOLUMN     => '/dev/wd0e',
            TOTAL      => '251',
            FREE       => '239',
            TYPE       => '/home',
            FILESYSTEM => undef
        },
        {
            VOLUMN     => '/dev/wd0d',
            TOTAL      => '892',
            FREE       => '224',
            TYPE       => '/usr',
            FILESYSTEM => undef
        }
    ],
    'aix' => [
        {
            VOLUMN     => '/dev/hd4',
            TOTAL      => '2048',
            FREE       => '1065',
            TYPE       => '/',
            FILESYSTEM => undef
        },
        {
            VOLUMN     => '/dev/hd2',
            TOTAL      => '4864',
            FREE       => '2704',
            TYPE       => '/usr',
            FILESYSTEM => undef
        },
        {
            VOLUMN     => '/dev/hd9var',
            TOTAL      => '256',
            FREE       => '177',
            TYPE       => '/var',
            FILESYSTEM => undef
        },
        {
            VOLUMN     => '/dev/hd3',
            TOTAL      => '4096',
            FREE       => '837',
            TYPE       => '/tmp',
            FILESYSTEM => undef
        },
        {
            VOLUMN     => '/dev/fwdump',
            TOTAL      => '128',
            FREE       => '127',
            TYPE       => '/var/adm/ras/platform',
            FILESYSTEM => undef
        },
        {
            VOLUMN     => '/dev/hd1',
            TOTAL      => '2048',
            FREE       => '1027',
            TYPE       => '/home',
            FILESYSTEM => undef
        },
        {
            VOLUMN     => '/dev/hd11admin',
            TOTAL      => '128',
            FREE       => '127',
            TYPE       => '/admin',
            FILESYSTEM => undef
        },
        {
            VOLUMN     => '/dev/hd10opt',
            TOTAL      => '128',
            FREE       => '13',
            TYPE       => '/opt',
            FILESYSTEM => undef
        }
    ]
);

my @dhcp_leases_test = (
    {
        file   => 'dhclient-wlan0-1.lease',
        result => '192.168.0.254',
        if     => 'wlan0'
    },
    {
        file   => 'dhclient-wlan0-2.lease',
        result => '192.168.10.1',
        if     => 'wlan0'
    },
);

my %busybox_ps_tests = (
    busybox => [
        {
            VIRTUALMEMORY => '2536',
            PID           => '1',
            CMD           => 'init',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '2',
            CMD           => '[kthreadd]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '3',
            CMD           => '[ksoftirqd/0]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '6',
            CMD           => '[migration/0]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '7',
            CMD           => '[migration/1]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '9',
            CMD           => '[ksoftirqd/1]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '11',
            CMD           => '[migration/2]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '13',
            CMD           => '[ksoftirqd/2]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '14',
            CMD           => '[migration/3]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '16',
            CMD           => '[ksoftirqd/3]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '17',
            CMD           => '[khelper]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '138',
            CMD           => '[sync_supers]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '140',
            CMD           => '[bdi-default]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '141',
            CMD           => '[kintegrityd]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '142',
            CMD           => '[kblockd]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '249',
            CMD           => '[ata_sff]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '257',
            CMD           => '[md]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '366',
            CMD           => '[rpciod]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '408',
            CMD           => '[kswapd0]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '409',
            CMD           => '[fsnotify_mark]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '410',
            CMD           => '[nfsiod]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '96192',
            PID           => '597',
            CMD           => '/usr/syno/apache/bin/httpd -DHAVE_PHP',
            USER          => 'nobody'
        },
        {
            VIRTUALMEMORY => '95672',
            PID           => '800',
            CMD           => '/usr/syno/apache/bin/httpd -DHAVE_PHP',
            USER          => 'nobody'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '871',
            CMD           => '[kworker/0:0]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '983',
            CMD           => '[iscsi_eh]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '1004',
            CMD           => '[scsi_eh_0]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '1007',
            CMD           => '[scsi_eh_1]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '1010',
            CMD           => '[scsi_eh_2]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '1013',
            CMD           => '[scsi_eh_3]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '1016',
            CMD           => '[scsi_eh_4]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '1019',
            CMD           => '[scsi_eh_5]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '1025',
            CMD           => '[kworker/u:5]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '1026',
            CMD           => '[kworker/u:6]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '1037',
            CMD           => '[scsi_eh_6]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '1040',
            CMD           => '[scsi_eh_7]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '1136',
            CMD           => '[md0_raid1]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '1143',
            CMD           => '[md1_raid1]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '1501',
            CMD           => '[jbd2/md0-8]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '1502',
            CMD           => '[ext4-dio-unwrit]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '2058',
            CMD           => '[kworker/0:1]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '12912',
            PID           => '2307',
            CMD           => 'sshd: root@pts/1',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '4752',
            PID           => '2345',
            CMD           => '-ash',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '11852',
            PID           => '2437',
            CMD           => '/usr/syno/bin/synonetbkpd -D',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '2518',
            CMD           => '[kworker/3:2]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '2708',
            CMD           => '[khubd]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '2826',
            CMD           => '[crypto]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '3068',
            CMD           => '[ecryptfs-kthrea]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '95908',
            PID           => '3124',
            CMD           => '/usr/syno/apache/bin/httpd -DHAVE_PHP',
            USER          => 'nobody'
        },
        {
            VIRTUALMEMORY => '98.1m',
            PID           => '3180',
            CMD           => '/usr/syno/apache/bin/httpd -DHAVE_PHP',
            USER          => 'nobody'
        },
        {
            VIRTUALMEMORY => '1472',
            PID           => '3439',
            CMD           => '/sbin/dhcpcd -n eth0 -t 30',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '2536',
            PID           => '3475',
            CMD           => '/sbin/syslogd -S',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '2536',
            PID           => '3480',
            CMD           => '/sbin/klogd',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '95644',
            PID           => '3981',
            CMD           => '/usr/syno/apache/bin/httpd -DHAVE_PHP',
            USER          => 'nobody'
        },
        {
            VIRTUALMEMORY => '12264',
            PID           => '4089',
            CMD           => '/usr/syno/apache/bin/httpd -f /usr/syno/apache/conf/httpd.conf-sys',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '12264',
            PID           => '4286',
            CMD           => '/usr/syno/apache/bin/httpd -f /usr/syno/apache/conf/httpd.conf-sys',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '55416',
            PID           => '4307',
            CMD           => '/usr/syno/mysql/libexec/mysqld --basedir=/usr/syno/mysql --datadir=/volume1/@database/mysql --user=admin --max_allowed_packet=8M',
            USER          => 'admin'
        },
        {
            VIRTUALMEMORY => '12264',
            PID           => '4476',
            CMD           => '/usr/syno/apache/bin/httpd -f /usr/syno/apache/conf/httpd.conf-sys',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '12256',
            PID           => '4766',
            CMD           => '/usr/syno/apache/bin/httpd -f /usr/syno/apache/conf/httpd.conf-sys',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '10908',
            PID           => '4785',
            CMD           => '/usr/syno/bin/findhostd',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '25228',
            PID           => '4811',
            CMD           => '/usr/syno/sbin/smbd -D',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '12092',
            PID           => '4819',
            CMD           => '/usr/syno/apache/bin/httpd -f /usr/syno/apache/conf/httpd.conf-sys',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '12092',
            PID           => '4820',
            CMD           => '/usr/syno/apache/bin/httpd -f /usr/syno/apache/conf/httpd.conf-sys',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '12092',
            PID           => '4821',
            CMD           => '/usr/syno/apache/bin/httpd -f /usr/syno/apache/conf/httpd.conf-sys',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '4752',
            PID           => '4822',
            CMD           => 'ps',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '5489',
            CMD           => '[kworker/2:1]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '9188',
            PID           => '5571',
            CMD           => '/usr/sbin/ntpd -p /var/run/ntpd.pid -g',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '9188',
            PID           => '5573',
            CMD           => '/usr/sbin/ntpd -p /var/run/ntpd.pid -g',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '9188',
            PID           => '5574',
            CMD           => '/usr/sbin/ntpd -p /var/run/ntpd.pid -g',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '6038',
            CMD           => '[kworker/3:1]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '6115',
            CMD           => '[flush-9:0]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '6116',
            CMD           => '[flush-9:2]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '13376',
            PID           => '6184',
            CMD           => 'scemd',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '13376',
            PID           => '6306',
            CMD           => 'scemd',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '13376',
            PID           => '6311',
            CMD           => 'scemd',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '7321',
            CMD           => '[scsi_eh_8]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '7339',
            CMD           => '[usb-storage]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '0',
            PID           => '7843',
            CMD           => '[kworker/1:1]',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '2540',
            PID           => '8035',
            CMD           => '/sbin/getty 115200 console',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '11988',
            PID           => '8357',
            CMD           => '/usr/syno/sbin/hotplugd',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '4748',
            PID           => '8371',
            CMD           => '/usr/sbin/inetd',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '13148',
            PID           => '8384',
            CMD           => '/usr/syno/sbin/snmpd -Ln -c /usr/syno/etc/snmpd.conf -p /var/run/snmpd.pid udp:161,udp6:161,tcp:161,tcp6:161',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '11696',
            PID           => '8587',
            CMD           => '/usr/syno/sbin/fileindexd',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '95228',
            PID           => '8635',
            CMD           => '/usr/syno/apache/bin/httpd -DHAVE_PHP',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '11292',
            PID           => '9466',
            CMD           => '/usr/syno/sbin/synosnmpcd',
            USER          => 'root'
        },
        {
            VIRTUALMEMORY => '12092',
            PID           => '9507',
            CMD           => '/usr/syno/apache/bin/httpd -f /usr/syno/apache/conf/httpd.conf-sys',
            USER          => 'root'
        },
        {
                VIRTUALMEMORY => '2232',
                PID           => '14163',
                CMD           => 'avahi-daemon: running [nas.local]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '14994',
                CMD           => '[LIO_rd_dr]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '15005',
                CMD           => '[iscsi_trx/1]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '15006',
                CMD           => '[iscsi_ttx/1]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '15007',
                CMD           => '[iscsi_trx/2]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '15008',
                CMD           => '[iscsi_ttx/2]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '15009',
                CMD           => '[iscsi_trx/3]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '15010',
                CMD           => '[iscsi_ttx/3]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '15011',
                CMD           => '[iscsi_trx/4]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '15012',
                CMD           => '[iscsi_ttx/4]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '15269',
                CMD           => '[iscsi_np]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '15272',
                CMD           => '[iscsi_np]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '15303',
                CMD           => '[LIO_fileio]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '18264',
                PID           => '16466',
                CMD           => '/usr/syno/sbin/nmbd -D',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '22548',
                PID           => '16482',
                CMD           => '/usr/syno/sbin/winbindd -D',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '22624',
                PID           => '16493',
                CMD           => '/usr/syno/sbin/winbindd -D',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '22100',
                PID           => '16516',
                CMD           => '/usr/syno/sbin/winbindd -D',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '22540',
                PID           => '16517',
                CMD           => '/usr/syno/sbin/winbindd -D',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '22136',
                PID           => '16521',
                CMD           => '/usr/syno/sbin/winbindd -D',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '24676',
                PID           => '16531',
                CMD           => '/usr/syno/sbin/smbd -D',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '24788',
                PID           => '16538',
                CMD           => '/usr/syno/sbin/smbd -D',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '1448',
                PID           => '17219',
                CMD           => '/sbin/portmap',
                USER          => '1'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '17222',
                CMD           => '[lockd]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '17223',
                CMD           => '[nfsd4]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '17224',
                CMD           => '[nfsd4_callbacks]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '17225',
                CMD           => '[nfsd]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '17226',
                CMD           => '[nfsd]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '17227',
                CMD           => '[nfsd]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '17228',
                CMD           => '[nfsd]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '17229',
                CMD           => '[nfsd]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '17230',
                CMD           => '[nfsd]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '17231',
                CMD           => '[nfsd]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '17232',
                CMD           => '[nfsd]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '7028',
                PID           => '17235',
                CMD           => '/usr/sbin/statd',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '7096',
                PID           => '17238',
                CMD           => '/usr/sbin/mountd -p 892',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '4748',
                PID           => '17401',
                CMD           => '/usr/sbin/crond',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '20328',
                PID           => '17406',
                CMD           => '/usr/syno/bin/synomkthumbd',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '20324',
                PID           => '17412',
                CMD           => '/usr/syno/sbin/synomkflvd',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '13048',
                PID           => '18978',
                CMD           => 'sshd: root@pts/0',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '4752',
                PID           => '18984',
                CMD           => '-ash',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '19872',
                CMD           => '[kworker/2:0]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '21228',
                CMD           => '[md2_raid5]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '25854',
                CMD           => '[kworker/1:2]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '12264',
                PID           => '28886',
                CMD           => '/usr/syno/apache/bin/httpd -f /usr/syno/apache/conf/httpd.conf-sys',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '29849',
                CMD           => '[jbd2/md2-8]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '0',
                PID           => '29850',
                CMD           => '[ext4-dio-unwrit]',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '7188',
                PID           => '29896',
                CMD           => '/usr/syno/sbin/cupsd -C /usr/local/cups/cupsd.conf',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '33336',
                PID           => '29971',
                CMD           => '/usr/syno/pgsql/bin/postgres -D /var/services/pgsql --config_file=/usr/syno/pgsql/etc/postgresql.conf --hba_file=/usr/syno/pgsql/',
                USER          => 'admin'
        },
        {
                VIRTUALMEMORY => '33336',
                PID           => '29973',
                CMD           => 'postgres: writer process   ',
                USER          => 'admin'
        },
        {
                VIRTUALMEMORY => '33336',
                PID           => '29974',
                CMD           => 'postgres: wal writer process   ',
                USER          => 'admin'
        },
        {
                VIRTUALMEMORY => '25132',
                PID           => '30086',
                CMD           => '/usr/syno/sbin/synoindexd',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '2536',
                PID           => '30639',
                CMD           => '/bin/sh /usr/syno/mysql/bin/mysqld_safe --datadir=/volume1/@database/mysql --pid-file=/tmp/mysqld.pid --datadir=/volume1/@databas',
                USER          => 'root'
        },
        {
                VIRTUALMEMORY => '55416',
                PID           => '30706',
                CMD           => '/usr/syno/mysql/libexec/mysqld --basedir=/usr/syno/mysql --datadir=/volume1/@database/mysql --user=admin --max_allowed_packet=8M',
                USER          => 'admin'
        },
        {
                VIRTUALMEMORY => '55416',
                PID           => '30707',
                CMD           => '/usr/syno/mysql/libexec/mysqld --basedir=/usr/syno/mysql --datadir=/volume1/@database/mysql --user=admin --max_allowed_packet=8M',
                USER          => 'admin'
        },
        {
                VIRTUALMEMORY => '55416',
                PID           => '30708',
                CMD           => '/usr/syno/mysql/libexec/mysqld --basedir=/usr/syno/mysql --datadir=/volume1/@database/mysql --user=admin --max_allowed_packet=8M',
                USER          => 'admin'
        },
        {
                VIRTUALMEMORY => '55416',
                PID           => '30709',
                CMD           => '/usr/syno/mysql/libexec/mysqld --basedir=/usr/syno/mysql --datadir=/volume1/@database/mysql --user=admin --max_allowed_packet=8M',
                USER          => 'admin'
        },
        {
                VIRTUALMEMORY => '55416',
                PID           => '30710',
                CMD           => '/usr/syno/mysql/libexec/mysqld --basedir=/usr/syno/mysql --datadir=/volume1/@database/mysql --user=admin --max_allowed_packet=8M',
                USER          => 'admin'
        },
        {
                VIRTUALMEMORY => '55416',
                PID           => '30711',
                CMD           => '/usr/syno/mysql/libexec/mysqld --basedir=/usr/syno/mysql --datadir=/volume1/@database/mysql --user=admin --max_allowed_packet=8M',
                USER          => 'admin'
        },
        {
                VIRTUALMEMORY => '55416',
                PID           => '30712',
                CMD           => '/usr/syno/mysql/libexec/mysqld --basedir=/usr/syno/mysql --datadir=/volume1/@database/mysql --user=admin --max_allowed_packet=8M',
                USER          => 'admin'
        },
        {
                VIRTUALMEMORY => '55416',
                PID           => '30713',
                CMD           => '/usr/syno/mysql/libexec/mysqld --basedir=/usr/syno/mysql --datadir=/volume1/@database/mysql --user=admin --max_allowed_packet=8M',
                USER          => 'admin'
        },
        {
                VIRTUALMEMORY => '55416',
                PID           => '30714',
                CMD           => '/usr/syno/mysql/libexec/mysqld --basedir=/usr/syno/mysql --datadir=/volume1/@database/mysql --user=admin --max_allowed_packet=8M',
                USER          => 'admin'
        },
        {
                VIRTUALMEMORY => '55416',
                PID           => '30715',
                CMD           => '/usr/syno/mysql/libexec/mysqld --basedir=/usr/syno/mysql --datadir=/volume1/@database/mysql --user=admin --max_allowed_packet=8M',
                USER          => 'admin'
        },
        {
                VIRTUALMEMORY => '55416',
                PID           => '30716',
                CMD           => '/usr/syno/mysql/libexec/mysqld --basedir=/usr/syno/mysql --datadir=/volume1/@database/mysql --user=admin --max_allowed_packet=8M',
                USER          => 'admin'
        },
        {
                VIRTUALMEMORY => '9948',
                PID           => '30968',
                CMD           => '/usr/syno/sbin/sshd',
                USER          => 'root'
        }
    ]
);

my $pattern = qr/^\d\d\d\d-\d\d-\d\d \d\d:\d\d$/;
my %other_ps_tests = (
    linux => [
        {
            CMD           => '/sbin/init',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '128328'
        },
        {
            CMD           => '[kthreadd]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '2',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[ksoftirqd/0]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '3',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kworker/0:0H]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '5',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[rcu_sched]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '7',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[rcu_bh]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '8',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[migration/0]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '9',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[migration/1]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '10',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[ksoftirqd/1]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '11',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kworker/1:0H]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '13',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[migration/2]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '14',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[ksoftirqd/2]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '15',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kworker/2:0H]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '17',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[migration/3]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '18',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[ksoftirqd/3]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '19',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kworker/3:0H]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '21',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[khelper]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '22',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kdevtmpfs]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '23',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[netns]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '24',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[writeback]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '25',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kintegrityd]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '26',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[bioset]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '27',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kblockd]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '28',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[ata_sff]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '29',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[md]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '30',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[devfreq_wq]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '31',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[khungtaskd]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '35',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kswapd0]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '36',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[ksmd]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '37',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[khugepaged]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '38',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[fsnotify_mark]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '39',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[bioset]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '40',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[crypto]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '41',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kthrotld]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '48',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[irq/42-mei_me]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '49',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[scsi_eh_0]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '51',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[scsi_eh_1]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '52',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[scsi_eh_2]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '53',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[scsi_eh_3]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '54',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[scsi_eh_4]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '55',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[scsi_eh_5]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '56',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kpsmoused]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '63',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[deferwq]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '65',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[khubd]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '291',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kworker/1:1H]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '298',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kworker/2:1H]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '299',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kworker/0:1H]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '300',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kworker/3:1H]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '355',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[jbd2/sda5-8]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '390',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[ext4-rsv-conver]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '391',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '/usr/lib/systemd/systemd-journald',
            CPUUSAGE      => '0.0',
            MEM           => '0.1',
            PID           => '456',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '66956'
        },
        {
            CMD           => '[kauditd]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '457',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[rpciod]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '477',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '/usr/lib/systemd/systemd-udevd',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '500',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '34516'
        },
        {
            CMD           => '[cfg80211]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '567',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kvm-irqfd-clean]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '615',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[hd-audio0]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '645',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kworker/u9:0]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '828',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[hci0]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '829',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[hci0]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '830',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kworker/u9:1]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '831',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '/usr/libexec/bluetooth/bluetoothd',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '912',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '19136'
        },
        {
            CMD           => '/usr/sbin/irqbalance --foreground',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '913',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '19260'
        },
        {
            CMD           => '/usr/sbin/NetworkManager --no-daemon',
            CPUUSAGE      => '0.0',
            MEM           => '0.1',
            PID           => '920',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '320636'
        },
        {
            CMD           => '/sbin/rsyslogd -n -c 4',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '922',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '239040'
        },
        {
            CMD           => '/usr/sbin/ModemManager',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '948',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '318200'
        },
        {
            CMD           => '/usr/lib/systemd/systemd-logind',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '954',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '23568'
        },
        {
            CMD           => '/usr/lib/udisks/udisks-daemon --no-debug',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '955',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '193668'
        },
        {
            CMD           => '/usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '956',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => '499',
            VIRTUALMEMORY => '16380'
        },
        {
            CMD           => '/usr/libexec/upowerd',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '959',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '225836'
        },
        {
            CMD           => 'udisks-daemon: not polling any devices',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '961',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '45828'
        },
        {
            CMD           => '/usr/sbin/gdm -nodaemon',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '963',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '442392'
        },
        {
            CMD           => '/usr/lib/polkit-1/polkitd --no-debug',
            CPUUSAGE      => '0.0',
            MEM           => '0.1',
            PID           => '1006',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'polkitd',
            VIRTUALMEMORY => '367184'
        },
        {
            CMD           => '/etc/X11/X :0 -background none -noreset -verbose 3 -logfile /dev/null -auth /var/run/gdm/auth-for-gdm-4e7zdi/database -seat seat0 -nolisten tcp vt1',
            CPUUSAGE      => '1.2',
            MEM           => '1.5',
            PID           => '1054',
            STARTED       => re($pattern),
            TTY           => 'tty1',
            USER          => 'root',
            VIRTUALMEMORY => '401904'
        },
        {
            CMD           => '/usr/libexec/accounts-daemon',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1056',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '258432'
        },
        {
            CMD           => '/usr/sbin/acpid',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1060',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '4276'
        },
        {
            CMD           => 'gdm-session-worker [pam/gdm-launch-environment]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1356',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '211596'
        },
        {
            CMD           => '/usr/lib/systemd/systemd --user',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1468',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'gdm',
            VIRTUALMEMORY => '35416'
        },
        {
            CMD           => '(sd-pam)',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1470',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'gdm',
            VIRTUALMEMORY => '65312'
        },
        {
            CMD           => '/usr/bin/pulseaudio --start --log-target=syslog',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1839',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'gdm',
            VIRTUALMEMORY => '356624'
        },
        {
            CMD           => '/usr/libexec/rtkit-daemon',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1843',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'rtkit',
            VIRTUALMEMORY => '162488'
        },
        {
            CMD           => '/sbin/ifplugd -I -b -i eth0',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1873',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '6336'
        },
        {
            CMD           => '/usr/libexec/pulse/gconf-helper',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1897',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'gdm',
            VIRTUALMEMORY => '67260'
        },
        {
            CMD           => '/sbin/ifplugd -I -b -i wlan0',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '2055',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '6336'
        },
        {
            CMD           => '/usr/lib/udisks2/udisksd --no-debug',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '2096',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '419640'
        },
        {
            CMD           => '/sbin/dhclient -d -sf /usr/libexec/nm-dhcp-helper -pf /var/run/dhclient-eth0.pid -lf /var/lib/NetworkManager/dhclient-5fb06bd0-0bb0-7ffb-45f1-d6edd65f3e03-eth0.lease -cf /var/lib/NetworkManager/dhclient-eth0.conf eth0',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '2131',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '14344'
        },
        {
            CMD           => '/sbin/dhclient -1 -q -lf /var/lib/dhclient/dhclient--eth0.lease -pf /var/run/dhclient-eth0.pid eth0',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '3057',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '14344'
        },
        {
            CMD           => 'ssh plouf.leo-mare.org',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '4505',
            STARTED       => re($pattern),
            TTY           => 'pts/2',
            USER          => '500',
            VIRTUALMEMORY => '39804'
        },
        {
            CMD           => '/usr/libexec/dconf-service',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '5158',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => '500',
            VIRTUALMEMORY => '176180'
        },
        {
            CMD           => 'gdm-session-worker [pam/gdm-password]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '6042',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '429492'
        },
        {
            CMD           => 'pickup -l -t unix -u -c -o content_filter= -o receive_override_options=',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '6556',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'postfix',
            VIRTUALMEMORY => '25312'
        },
        {
            CMD           => '/usr/lib/systemd/systemd --user',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '6887',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => '500',
            VIRTUALMEMORY => '35416'
        },
        {
            CMD           => '(sd-pam)',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '6888',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => '500',
            VIRTUALMEMORY => '65312'
        },
        {
            CMD           => '[kdmflush]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '7302',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[bioset]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '7304',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kcryptd_io]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '7305',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[kcryptd]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '7306',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '[bioset]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '7307',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => 'perl -dI lib/ t/agent/http/client/ssl.t',
            CPUUSAGE      => '0.0',
            MEM           => '0.5',
            PID           => '7314',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => '500',
            VIRTUALMEMORY => '124008'
        },
        {
            CMD           => '[jbd2/dm-0-8]',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '7337',
            STARTED       => re($pattern),
            TTY           => '?',
            USER          => 'root',
            VIRTUALMEMORY => '0'
        }
    ],
    macos => [
        {
            CMD           => '/sbin/launchd',
            CPUUSAGE      => '0.1',
            MEM           => '0.0',
            PID           => '1',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2456844'
        },
        {
            CMD           => '/usr/libexec/kextd',
            CPUUSAGE      => '0.0',
            MEM           => '0.4',
            PID           => '10',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2455060'
        },
        {
            CMD           => '/usr/sbin/notifyd',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '11',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2444624'
        },
        {
            CMD           => '/usr/sbin/syslogd',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '12',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2457256'
        },
        {
            CMD           => '/usr/sbin/diskarbitrationd',
            CPUUSAGE      => '0.0',
            MEM           => '0.1',
            PID           => '13',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2446968'
        },
        {
            CMD           => '/usr/libexec/configd',
            CPUUSAGE      => '0.0',
            MEM           => '0.2',
            PID           => '14',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2475020'
        },
        {
            CMD           => '/usr/sbin/DirectoryService',
            CPUUSAGE      => '0.0',
            MEM           => '0.3',
            PID           => '15',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2452984'
        },
        {
            CMD           => '/usr/sbin/distnoted',
            CPUUSAGE      => '0.0',
            MEM           => '0.1',
            PID           => '16',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'daemon',
            VIRTUALMEMORY => '2446820'
        },
        {
            CMD           => '/usr/sbin/blued',
            CPUUSAGE      => '0.0',
            MEM           => '0.3',
            PID           => '17',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2462136'
        },
        {
            CMD           => '/usr/sbin/ntpd -c /private/etc/ntp-restrict.conf -n -g -p /var/run/ntpd.pid -f /var/db/ntp.drift',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '19',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2435292'
        },
        {
            CMD           => '/System/Library/PrivateFrameworks/MobileDevice.framework/Versions/A/Resources/usbmuxd -launchd',
            CPUUSAGE      => '0.0',
            MEM           => '0.1',
            PID           => '23',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => '_usbmuxd',
            VIRTUALMEMORY => '2460376'
        },
        {
            CMD           => '/usr/sbin/securityd -i',
            CPUUSAGE      => '0.0',
            MEM           => '0.1',
            PID           => '26',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2459996'
        },
        {
            CMD           => '/System/Library/Frameworks/CoreServices.framework/Frameworks/Metadata.framework/Support/mds',
            CPUUSAGE      => '0.0',
            MEM           => '2.9',
            PID           => '29',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2645284'
        },
        {
            CMD           => '/usr/sbin/mDNSResponder -launchd',
            CPUUSAGE      => '0.0',
            MEM           => '0.1',
            PID           => '30',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => '_mdnsresponder',
            VIRTUALMEMORY => '2460184'
        },
        {
            CMD           => '/System/Library/CoreServices/loginwindow.app/Contents/MacOS/loginwindow console',
            CPUUSAGE      => '0.0',
            MEM           => '0.5',
            PID           => '31',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2775456'
        },
        {
            CMD           => '/usr/sbin/KernelEventAgent',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '32',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2445904'
        },
        {
            CMD           => '/usr/libexec/hidd',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '34',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2445816'
        },
        {
            CMD           => '/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/CarbonCore.framework/Versions/A/Support/fseventsd',
            CPUUSAGE      => '0.0',
            MEM           => '0.1',
            PID           => '35',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2453724'
        },
        {
            CMD           => '/sbin/dynamic_pager -F /private/var/vm/swapfile',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '37',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2434864'
        },
        {
            CMD           => 'autofsd',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '43',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2446832'
        },
        {
            CMD           => '/System/Library/CoreServices/coreservicesd',
            CPUUSAGE      => '0.0',
            MEM           => '1.0',
            PID           => '48',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2500432'
        },
        {
            CMD           => '/usr/libexec/ApplicationFirewall/socketfilterfw',
            CPUUSAGE      => '0.0',
            MEM           => '0.2',
            PID           => '53',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2461760'
        },
        {
            CMD           => '/System/Library/Frameworks/ApplicationServices.framework/Frameworks/CoreGraphics.framework/Resources/WindowServer -daemon',
            CPUUSAGE      => '0.0',
            MEM           => '3.9',
            PID           => '77',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => '_windowserver',
            VIRTUALMEMORY => '2892276'
        },
        {
            CMD           => '/System/Library/Frameworks/OpenGL.framework/Versions/A/Libraries/cvmsServ',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '81',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2438704'
        },
        {
            CMD           => '/usr/sbin/coreaudiod',
            CPUUSAGE      => '0.0',
            MEM           => '0.2',
            PID           => '91',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => '_coreaudiod',
            VIRTUALMEMORY => '2451260'
        },
        {
            CMD           => '/sbin/launchd',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '94',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2456368'
        },
        {
            CMD           => '/System/Library/CoreServices/Dock.app/Contents/MacOS/Dock',
            CPUUSAGE      => '0.0',
            MEM           => '1.0',
            PID           => '98',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2818072'
        },
        {
            CMD           => '/System/Library/CoreServices/SystemUIServer.app/Contents/MacOS/SystemUIServer',
            CPUUSAGE      => '0.0',
            MEM           => '0.7',
            PID           => '99',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2765812'
        },
        {
            CMD           => '/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder',
            CPUUSAGE      => '0.0',
            MEM           => '2.8',
            PID           => '100',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '3968776'
        },
        {
            CMD           => '/System/Library/Frameworks/ApplicationServices.framework/Frameworks/ATS.framework/Support/fontd',
            CPUUSAGE      => '0.0',
            MEM           => '0.2',
            PID           => '109',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2496564'
        },
        {
            CMD           => '/usr/sbin/pboard',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '113',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2436408'
        },
        {
            CMD           => '/usr/libexec/UserEventAgent -l Aqua',
            CPUUSAGE      => '0.0',
            MEM           => '0.3',
            PID           => '118',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2460956'
        },
        {
            CMD           => '/System/Library/CoreServices/AirPort Base Station Agent.app/Contents/MacOS/AirPort Base Station Agent -launchd -allowquit',
            CPUUSAGE      => '0.0',
            MEM           => '0.3',
            PID           => '126',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2732816'
        },
        {
            CMD           => '/System/Library/CoreServices/Menu Extras/TextInput.menu/Contents/SharedSupport/TISwitcher.app/Contents/MacOS/TISwitcher',
            CPUUSAGE      => '0.0',
            MEM           => '0.2',
            PID           => '130',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2725604'
        },
        {
            CMD           => '/Applications/Antidote HD.app/Contents/SharedSupport/AgentAntidote.app/Contents/MacOS/AgentAntidote -psn_0_45067',
            CPUUSAGE      => '0.0',
            MEM           => '0.5',
            PID           => '132',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2770492'
        },
        {
            CMD           => '/Applications/iTunes.app/Contents/MacOS/iTunesHelper.app/Contents/MacOS/iTunesHelper -psn_0_49164',
            CPUUSAGE      => '0.0',
            MEM           => '0.1',
            PID           => '133',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2725896'
        },
        {
            CMD           => '/Applications/owncloud.app/Contents/MacOS/owncloud -psn_0_57358',
            CPUUSAGE      => '0.0',
            MEM           => '1.1',
            PID           => '135',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '3884996'
        },
        {
            CMD           => '/Applications/Canon Utilities/IJ Network Scanner Selector EX/Canon IJ Network Scanner Selector EX.app/Contents/CNSSelectorAgent.app/Contents/MacOS/CNSSelectorAgent -psn_0_73746',
            CPUUSAGE      => '0.0',
            MEM           => '0.2',
            PID           => '140',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2723908'
        },
        {
            CMD           => '/System/Library/Services/AppleSpell.service/Contents/MacOS/AppleSpell -psn_0_180268',
            CPUUSAGE      => '0.0',
            MEM           => '0.2',
            PID           => '250',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2466524'
        },
        {
            CMD           => '/System/Library/PrivateFrameworks/DiskImages.framework/Resources/diskimages-helper -uuid B1608F55-7461-41BA-A68A-2795732EDB0A -post-exec 4',
            CPUUSAGE      => '0.0',
            MEM           => '0.2',
            PID           => '274',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2476428'
        },
        {
            CMD           => '/System/Library/PrivateFrameworks/DiskImages.framework/Resources/hdiejectd',
            CPUUSAGE      => '0.0',
            MEM           => '0.1',
            PID           => '278',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2446144'
        },
        {
            CMD           => '/Applications/Utilities/Grab.app/Contents/MacOS/Grab -psn_0_249917',
            CPUUSAGE      => '0.0',
            MEM           => '0.8',
            PID           => '369',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2805360'
        },
        {
            CMD           => '/Applications/Adobe Photoshop CS3/Adobe Photoshop CS3.app/Contents/MacOS/Adobe Photoshop CS3 -psn_0_254014',
            CPUUSAGE      => '0.3',
            MEM           => '2.8',
            PID           => '399',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '815420'
        },
        {
            CMD           => '/Applications/Preview.app/Contents/MacOS/Preview -psn_0_372827',
            CPUUSAGE      => '0.0',
            MEM           => '1.0',
            PID           => '645',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2795552'
        },
        {
            CMD           => '/Applications/Microsoft Office 2008/Microsoft Excel.app/Contents/MacOS/Microsoft Excel -psn_0_536707',
            CPUUSAGE      => '0.0',
            MEM           => '3.7',
            PID           => '955',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '575112'
        },
        {
            CMD           => '/Applications/Microsoft Office 2008/Office/Microsoft Database Daemon.app/Contents/MacOS/Microsoft Database Daemon -psn_0_544901',
            CPUUSAGE      => '0.0',
            MEM           => '0.4',
            PID           => '959',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '423424'
        },
        {
            CMD           => '/System/Library/Frameworks/CoreServices.framework/Frameworks/Metadata.framework/Versions/A/Support/mdworker MDSImporterWorker com.apple.Spotlight.ImporterWorker.501',
            CPUUSAGE      => '0.0',
            MEM           => '0.3',
            PID           => '1185',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2468168'
        },
        {
            CMD           => '/System/Library/Frameworks/CoreServices.framework/Frameworks/Metadata.framework/Versions/A/Support/mdworker MDSImporterWorker com.apple.Spotlight.ImporterWorker.89',
            CPUUSAGE      => '0.0',
            MEM           => '0.3',
            PID           => '1186',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => '_spotlight',
            VIRTUALMEMORY => '2466288'
        },
        {
            CMD           => '/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal -psn_0_671908',
            CPUUSAGE      => '0.0',
            MEM           => '0.5',
            PID           => '1197',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2765332'
        },
        {
            CMD           => '/Applications/System Preferences.app/Contents/MacOS/System Preferences -psn_0_680102',
            CPUUSAGE      => '0.0',
            MEM           => '3.1',
            PID           => '1209',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '11278540'
        },
        {
            CMD           => '/System/Library/CoreServices/SecurityAgent.app/Contents/MacOS/SecurityAgent',
            CPUUSAGE      => '0.0',
            MEM           => '0.4',
            PID           => '1214',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => '_securityagent',
            VIRTUALMEMORY => '2751024'
        },
        {
            CMD           => '/System/Library/PrivateFrameworks/Admin.framework/Resources/writeconfig',
            CPUUSAGE      => '0.0',
            MEM           => '0.2',
            PID           => '1215',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2448884'
        },
        {
            CMD           => '/System/Library/Frameworks/OpenGL.framework/Versions/A/Libraries/cvmsComp_x86_64 1',
            CPUUSAGE      => '0.0',
            MEM           => '0.3',
            PID           => '1219',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2449200'
        },
        {
            CMD           => '(userInit)',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1232',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'guillaume',
            VIRTUALMEMORY => '0'
        },
        {
            CMD           => '/System/Library/Image Capture/Support/Image Capture Extension.app/Contents/MacOS/Image Capture Extension -psn_0_688296',
            CPUUSAGE      => '0.0',
            MEM           => '0.3',
            PID           => '1240',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'admin',
            VIRTUALMEMORY => '2724808'
        },
        {
            CMD           => '/usr/sbin/cupsd -l',
            CPUUSAGE      => '0.0',
            MEM           => '0.1',
            PID           => '1243',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2458752'
        },
        {
            CMD           => '/usr/libexec/launchproxy /usr/sbin/sshd -i',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1260',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2446308'
        },
        {
            CMD           => '/usr/libexec/sandboxd',
            CPUUSAGE      => '0.0',
            MEM           => '0.1',
            PID           => '1266',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2446348'
        },
        {
            CMD           => '/usr/sbin/sshd -i',
            CPUUSAGE      => '0.0',
            MEM           => '0.2',
            PID           => '1269',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'root',
            VIRTUALMEMORY => '2451060'
        },
        {
            CMD           => '/sbin/launchd',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1272',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'guillaume',
            VIRTUALMEMORY => '2456284'
        },
        {
            CMD           => '/usr/sbin/sshd -i',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1274',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'guillaume',
            VIRTUALMEMORY => '2451060'
        },
        {
            CMD           => '/System/Library/Frameworks/CoreServices.framework/Frameworks/Metadata.framework/Versions/A/Support/mdworker MDSImporterWorker com.apple.Spotlight.ImporterWorker.502',
            CPUUSAGE      => '0.0',
            MEM           => '0.2',
            PID           => '1275',
            STARTED       => re($pattern),
            TTY           => '??',
            USER          => 'guillaume',
            VIRTUALMEMORY => '2464352'
        },
        {
            CMD           => 'login -pf admin',
            CPUUSAGE      => '0.0',
            MEM           => '0.1',
            PID           => '1201',
            STARTED       => re($pattern),
            TTY           => 'ttys000',
            USER          => 'root',
            VIRTUALMEMORY => '2436216'
        },
        {
            CMD           => '-bash',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1202',
            STARTED       => re($pattern),
            TTY           => 'ttys000',
            USER          => 'admin',
            VIRTUALMEMORY => '2435548'
        },
        {
            CMD           => '-bash',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1277',
            STARTED       => re($pattern),
            TTY           => 'ttys001',
            USER          => 'guillaume',
            VIRTUALMEMORY => '2435548'
        },
        {
            CMD           => 'ps -A -o user,pid,pcpu,pmem,vsz,tty,etime,command',
            CPUUSAGE      => '0.0',
            MEM           => '0.0',
            PID           => '1282',
            STARTED       => re($pattern),
            TTY           => 'ttys001',
            USER          => 'root',
            VIRTUALMEMORY => '2434868'
        }
    ]
);

my %netstat_tests = (
    openbsd => {
        'default'     => '10.0.1.1',
        '10.0.1/24'   => 'link#1',
        '10.0.1.1'    => '00:1d:7e:43:96:57',
        '10.0.1.100'  => '00:13:77:b3:cf:0c',
        '10.0.1.115'  => '127.0.0.1',
        '127/8'       => '127.0.0.1',
        '127.0.0.1'   => '127.0.0.1',
        '224/4'       => '127.0.0.1'
    },
    netbsd => {
        'default'     => '10.0.1.1',
        '10.0.1/24'   => 'link#1',
        '10.0.1.1'    => '00:1d:7e:43:96:57',
        '10.0.1.101'  => '00:1e:c2:0c:36:27',
        '10.0.1.124'  => '127.0.0.1',
        '127/8'       => '127.0.0.1',
        '127.0.0.1'   => '127.0.0.1',
    },
    hpux1 => {
        '10.0.4.55' => '10.0.4.55',
        '10.0.4.32' => '10.0.4.55',
        '127.0.0.0' => '127.0.0.1',
        '127.0.0.1' => '127.0.0.1',
        '10.0.4.56' => '10.0.4.56',
        'default'   => '10.0.4.33'
    },
    hpux2 => {
        '127.0.0.0'      => '127.0.0.1',
        '192.168.210.0'  => '192.168.210.40',
        '10.0.0.48'      => '10.0.0.48',
        'default'        => '10.0.0.33',
        '10.0.0.32'      => '10.0.0.49',
        '10.0.0.49'      => '10.0.0.49',
        '192.168.210.40' => '192.168.210.40',
        '127.0.0.1'      => '127.0.0.1',
        '192.168.210.91' => '10.0.0.48'
    },
    'aix-5.3a' => {
        '192.168.2.1'   => '127.0.0.1',
        '192.168.2.0'   => '192.168.2.1',
        'default'       => '192.168.2.250',
        '192.168.2/24'  => '192.168.2.1',
        '192.168.2.255' => '192.168.2.1',
        '127/8'         => '127.0.0.1'
    },
    'aix-5.3c' => {
        '10.3.40.255'     => '10.3.40.160',
        '192.168.203/24'  => '192.168.203.160',
        '192.168.1.255'   => '192.168.1.160',
        '10/8'            => '10.3.0.254',
        '192.168.1.160'   => '127.0.0.1',
        '10.3.40.0'       => '10.3.40.160',
        '10.3.40/24'      => '10.3.40.160',
        '192.168.203.0'   => '192.168.203.160',
        '192.168.4/24'    => '192.168.4.160',
        '10.3.40.160'     => '127.0.0.1',
        '192.168.203.255' => '192.168.203.160',
        '192.168.4.0'     => '192.168.4.160',
        '192.168.4.160'   => '127.0.0.1',
        'default'         => '10.3.0.253',
        '192.168.1/24'    => '192.168.1.160',
        '192.168.1.0'     => '192.168.1.160',
        '192.168.201/24'  => '192.168.203.254',
        '192.168.4.255'   => '192.168.4.160',
        '127/8'           => '127.0.0.1',
        '192.168.203.160' => '127.0.0.1'
    },
    'aix-6.1a' => {
        '172.16.0.80'  => '127.0.0.1',
        '172.16.0.0'   => '172.16.0.80',
        '172.16.7.255' => '172.16.0.80',
        'default'      => '172.16.0.254',
        '10.0.0.0'     => '10.0.0.103',
        '10/21'        => '10.0.0.103',
        '10.0.0.103'   => '127.0.0.1',
        '192.0.0/24'   => '172.16.0.254',
        '10.0.7.255'   => '10.0.0.103',
        '127/8'        => '127.0.0.1',
        '172.16/21'    => '172.16.0.80',
        '39/16'        => '172.16.0.21'
    },
    'aix-6.1b' => {
        '192.168.4.1'     => '127.0.0.1',
        '192.168.1.1'     => '127.0.0.1',
        '192.168.203/24'  => '192.168.203.101',
        '192.168.1.255'   => '192.168.1.1',
        '10/8'            => '10.3.0.254',
        '192.168.203.101' => '127.0.0.1',
        '10.3.40.101'     => '127.0.0.1',
        '192.168.203.0'   => '192.168.203.101',
        '192.168.3.1'     => '127.0.0.1',
        '192.168.4/24'    => '192.168.4.1',
        '192.168.3.255'   => '192.168.3.1',
        '192.168.203.255' => '192.168.203.101',
        '192.168.4.0'     => '192.168.4.1',
        '10.3.0.0'        => '10.3.40.101',
        'default'         => '10.3.0.253',
        '10.3/16'         => '10.3.40.101',
        '192.168.3/24'    => '192.168.3.1',
        '192.168.1/24'    => '192.168.1.1',
        '192.168.201/24'  => '192.168.203.254',
        '192.168.1.0'     => '192.168.1.1',
        '192.168.4.255'   => '192.168.4.1',
        '192.168.3.0'     => '192.168.3.1',
        '10.3.255.255'    => '10.3.40.101',
        '127/8'           => '127.0.0.1'
    },
    linux1 => {
        '0.0.0.0'     => '192.168.0.254',
        '192.168.0.0' => '0.0.0.0'
    },
    macosx1 => {
        '192.168.0.254' => 'f4:ca:e5:42:38:37',
        '127.0.0.1'     => '127.0.0.1',
        '192.168.0.27'  => '127.0.0.1',
        'default'       => '192.168.0.254'
    }
);

my %mount_tests = (
    linux   => [ qw/ext4 tmpfs proc sysfs devpts binfmt_misc/ ],
    darwin  => [ qw/local union/ ],
    freebsd => [ qw/ufs/ ]
);

my %rootfsbirth = (
    'old-fedora'    => "2013-12-22 22:47:33",
);

plan tests =>
    (scalar keys %df_tests)         +
    (scalar keys %busybox_ps_tests) +
    (scalar keys %other_ps_tests)   +
    (scalar keys %netstat_tests)    +
    (scalar keys %mount_tests)      +
    (scalar keys %rootfsbirth)      +
    (scalar @dhcp_leases_test);

foreach my $test (keys %df_tests) {
    my $file = "resources/generic/df/$test";
    my @infos = getFilesystemsFromDf(file => $file);
    cmp_deeply(\@infos, $df_tests{$test}, "$test df parsing");
}

foreach my $test (keys %busybox_ps_tests) {
    my $file = "resources/generic/ps/$test";
    my @processes = GLPI::Agent::Tools::Unix::_getProcessesBusybox(file => $file);
    cmp_deeply(\@processes, $busybox_ps_tests{$test}, "$test ps parsing");
}

foreach my $test (keys %other_ps_tests) {
    my $file = "resources/generic/ps/$test";
    my @processes = GLPI::Agent::Tools::Unix::_getProcessesOther(file => $file);
    cmp_deeply(\@processes, $other_ps_tests{$test}, "$test ps parsing");
}

foreach my $test (@dhcp_leases_test) {
    my $file = "resources/generic/dhcp/$test->{file}";
    my $server = GLPI::Agent::Tools::Unix::_parseDhcpLeaseFile(undef, $test->{if}, $file);
    ok(
        $server && ($server eq $test->{result}),
        "Parse DHCP lease"
    );
}

foreach my $test (keys %netstat_tests) {
    my $file = "resources/generic/netstat/$test";
    my $routes = getRoutingTable(file => $file);
    cmp_deeply($routes, $netstat_tests{$test}, $test);
}

foreach my $test (keys %mount_tests) {
    my $file = "resources/generic/mount/$test";
    my @types = getFilesystemsTypesFromMount(file => $file);
    cmp_deeply(\@types, $mount_tests{$test}, $test);
}

foreach my $test (keys %rootfsbirth) {
    my $file = "resources/generic/stat/$test";
    my $installdate = GLPI::Agent::Tools::Unix::getRootFSBirth(file => $file);
    is($installdate, $rootfsbirth{$test}, "$test installdate");
}
