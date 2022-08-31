#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::Deep qw(cmp_deeply);
use Test::MockModule;
use Test::More;

use GLPI::Test::Utils;
use GLPI::Agent::Tools;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

use Config;
# check thread support availability
if (!$Config{usethreads} || $Config{usethreads} ne 'define') {
    plan skip_all => 'thread support required';
} elsif ($OSNAME eq 'MSWin32' && exists($ENV{GITHUB_ACTIONS})) {
    plan skip_all => 'Not working on github action windows image';
}

# REG_SZ & REG_DWORD provided by even faked Win32::TieRegistry module
Win32::TieRegistry->require();
Win32::TieRegistry->import('REG_DWORD', 'REG_SZ');

my %tests = (
    7 => [
        {
            dns         => '192.168.0.254',
            IPMASK      => '255.255.255.0',
            IPGATEWAY   => '192.168.0.254',
            MACADDR     => 'F4:6D:04:97:2D:3E',
            STATUS      => 'Up',
            IPDHCP      => '192.168.0.254',
            IPSUBNET    => '192.168.0.0',
            MTU         => undef,
            DESCRIPTION => 'Realtek PCIe GBE Family Controller',
            IPADDRESS   => '192.168.0.1',
            VIRTUALDEV  => 0,
            SPEED       => 100,
            PNPDEVICEID => 'PCI\VEN_10EC&DEV_8168&SUBSYS_84321043&REV_06\4&87D54EE&0&00E5',
            PCIID       => '10EC:8168:8432:1043',
            GUID        => '{442CDFAD-10E9-45B6-8CF9-C829034793B0}',
        },
        {
            dns         => '192.168.0.254',
            IPMASK6     => 'ffff:ffff:ffff:ffff::',
            MACADDR     => 'F4:6D:04:97:2D:3E',
            STATUS      => 'Up',
            IPADDRESS6  => 'fe80::311a:2127:dded:6618',
            MTU         => undef,
            IPSUBNET6   => 'fe80::',
            DESCRIPTION => 'Realtek PCIe GBE Family Controller',
            VIRTUALDEV  => 0,
            SPEED       => 100,
            PNPDEVICEID => 'PCI\VEN_10EC&DEV_8168&SUBSYS_84321043&REV_06\4&87D54EE&0&00E5',
            PCIID       => '10EC:8168:8432:1043',
            GUID        => '{442CDFAD-10E9-45B6-8CF9-C829034793B0}',
        },
        {
            dns         => undef,
            MTU         => undef,
            MACADDR     => '00:26:83:12:FB:0B',
            STATUS      => 'Down',
            DESCRIPTION => "Périphérique Bluetooth (réseau personnel)",
            VIRTUALDEV  => 0,
            PNPDEVICEID => 'BTH\MS_BTHPAN\7&42D85A8&0&2',
            GUID        => '{DDE01862-B0C0-4715-AF6C-51D31172EBF9}',
        },
    ],
    xp => [
        {
            dns         => undef,
            VIRTUALDEV  => 1,
            PNPDEVICEID => 'ROOT\\MS_PPTPMINIPORT\\0000',
            MACADDR     => '50:50:54:50:30:30',
            STATUS      => 'Down',
            MTU         => undef,
            DESCRIPTION => 'Minipuerto WAN (PPTP)'
        },
        {
            dns         => undef,
            VIRTUALDEV  => 1,
            PNPDEVICEID => 'ROOT\\MS_PPPOEMINIPORT\\0000',
            MACADDR     => '33:50:6F:45:30:30',
            STATUS      => 'Down',
            MTU         => undef,
            DESCRIPTION => 'Minipuerto WAN (PPPOE)'
        },
        {
            dns         => undef,
            VIRTUALDEV  => 1,
            PNPDEVICEID => 'ROOT\\MS_PSCHEDMP\\0000',
            MACADDR     => '26:0F:20:52:41:53',
            STATUS      => 'Down',
            MTU         => undef,
            DESCRIPTION => 'Minipuerto del administrador de paquetes'
        },
        {
            dns         => '10.36.6.100',
            IPMASK      => '255.255.254.0',
            IPGATEWAY   => '10.36.6.1',
            VIRTUALDEV  => 0,
            PNPDEVICEID => 'PCI\\VEN_14E4&DEV_1677&SUBSYS_3006103C&REV_01\\4&1886B119&0&00E1',
            PCIID       => '14E4:1677:3006:103C',
            MACADDR     => '00:14:C2:0D:B0:FB',
            STATUS      => 'Up',
            IPDHCP      => '10.36.6.100',
            IPSUBNET    => '10.36.6.0',
            MTU         => undef,
            DESCRIPTION => 'Broadcom NetXtreme Gigabit Ethernet - Teefer2 Miniport',
            IPADDRESS   => '10.36.6.30',
            DNSDomain   => 'sociedad.imaginaria.es',
        },
        {
            dns         => undef,
            VIRTUALDEV  => 1,
            PNPDEVICEID => 'ROOT\\MS_PSCHEDMP\\0002',
            MACADDR     => '00:14:C2:0D:B0:FB',
            STATUS      => 'Down',
            MTU         => undef,
            DESCRIPTION => 'Minipuerto del administrador de paquetes'
        },
        {
            dns         => undef,
            VIRTUALDEV  => 1,
            PNPDEVICEID => 'ROOT\\SYMC_TEEFER2MP\\0000',
            MACADDR     => '00:14:C2:0D:B0:FB',
            STATUS      => 'Down',
            MTU         => undef,
            DESCRIPTION => 'Teefer2 Miniport'
        },
        {
            dns         => undef,
            VIRTUALDEV  => 1,
            PNPDEVICEID => 'ROOT\\SYMC_TEEFER2MP\\0002',
            MACADDR     => '26:0F:20:52:41:53',
            STATUS      => 'Down',
            MTU         => undef,
            DESCRIPTION => 'Teefer2 Miniport'
        }
    ],
    '10-net'    => [
        {
            DESCRIPTION => 'Targus Giga Ethernet',
            DNSDomain   => 'contoso.com',
            IPADDRESS   => '192.168.0.2',
            IPDHCP      => '192.168.2.2',
            IPGATEWAY   => '192.168.0.254',
            IPMASK      => '255.255.255.0',
            IPSUBNET    => '192.168.0.0',
            MACADDR     => '00:50:00:00:F3:6D',
            PNPDEVICEID => 'USB\\VID_17E9&PID_4306&MI_05\\7&25c647c&0&0005',
            SPEED       => '1000',
            STATUS      => 'Up',
            VIRTUALDEV  => '0',
            GUID        => '{FD7B5BF5-2E4B-4CA4-0000-F633D86283A1}',
            dns         => '192.168.2.2',
            TYPE        => 'ethernet',
            MTU         => undef
        },
        {
            DESCRIPTION => 'Targus Giga Ethernet',
            DNSDomain   => 'contoso.com',
            IPADDRESS6  => 'fe80::2c1f:9a1f:dedd:699c',
            IPMASK6     => 'ffff:ffff:ffff:ffff::',
            IPSUBNET6   => 'fe80::',
            MACADDR     => '00:50:00:00:F3:6D',
            PNPDEVICEID => 'USB\\VID_17E9&PID_4306&MI_05\\7&25c647c&0&0005',
            SPEED       => '1000',
            STATUS      => 'Up',
            VIRTUALDEV  => '0',
            GUID        => '{FD7B5BF5-2E4B-4CA4-0000-F633D86283A1}',
            dns         => '192.168.2.2',
            TYPE        => 'ethernet',
            MTU         => undef
        },
        {
            DESCRIPTION => 'Hyper-V Virtual Ethernet Adapter',
            IPADDRESS   => '172.17.141.1',
            IPMASK      => '255.255.255.240',
            IPSUBNET    => '172.17.141.0',
            MACADDR     => '00:15:5D:00:00:96',
            PNPDEVICEID => 'ROOT\\VMS_MP\\0000',
            SPEED       => '10000',
            STATUS      => 'Up',
            VIRTUALDEV  => '1',
            GUID        => '{F2274B7D-033B-4FD1-B721-6B1E0E48D26D}',
            TYPE        => 'ethernet',
            IPDHCP      => undef,
            IPGATEWAY   => undef,
            MTU         => undef,
            dns         => undef
        },
        {
            DESCRIPTION => 'Hyper-V Virtual Ethernet Adapter',
            IPADDRESS6  => 'fe80::e1b8:381c:382e:d940',
            IPMASK6     => 'ffff:ffff:ffff:ffff::',
            IPSUBNET6   => 'fe80::',
            MACADDR     => '00:15:5D:00:00:96',
            PNPDEVICEID => 'ROOT\\VMS_MP\\0000',
            SPEED       => '10000',
            STATUS      => 'Up',
            VIRTUALDEV  => '1',
            GUID        => '{F2274B7D-033B-4FD1-B721-6B1E0E48D26D}',
            TYPE        => 'ethernet',
            MTU         => undef,
            dns         => undef
        },
        {
            DESCRIPTION => 'Bluetooth Device (Personal Area Network) #3',
            MACADDR     => '44:85:00:00:00:5F',
            PNPDEVICEID => 'BTH\\MS_BTHPAN\\6&12f29cde&1&2',
            SPEED       => '3',
            STATUS      => 'Down',
            VIRTUALDEV  => '1',
            GUID        => '{73513F19-5210-45E7-9CB5-6DB761D8291A}',
            TYPE        => 'ethernet',
            MTU         => undef,
            dns         => undef
        },
        {
            DESCRIPTION => 'TAP-Windows Adapter V9 #3',
            MACADDR     => '00:FF:20:00:00:80',
            PNPDEVICEID => 'ROOT\\NET\\0000',
            SPEED       => '100',
            STATUS      => 'Down',
            VIRTUALDEV  => '1',
            GUID        => '{201DE880-FE07-47BE-0000-A3ABDE40367F}',
            TYPE        => 'ethernet',
            MTU         => undef,
            dns         => undef
        },
        {
            DESCRIPTION => 'Intel(R) Dual Band Wireless-AC 8260',
            MACADDR     => '44:85:00:00:00:5B',
            PCIID       => '8086:24F3:0130:8086',
            PNPDEVICEID => 'PCI\\VEN_8086&DEV_24F3&SUBSYS_01308086&REV_3A\\448500000000005B00',
            STATUS      => 'Down',
            VIRTUALDEV  => '0',
            GUID        => '{05CAEBD3-9408-4A3D-0000-EB10577755E3}',
            TYPE        => 'wifi',
            MTU         => undef,
            dns         => undef
        }
    ]
);

# Emulated registry
my %register = (
    'HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node' => {
        'TeamViewer' => {
            # Values key begins with a slash
            '/ClientID' => '0x12345678',
            '/Version'  => '12.0.72365',
            # Subkey ends with a slash
            'subkey/'   => {
                '/value' => ''
            }
        }
    },
    'HKEY_LOCAL_MACHINE/CurrentControlSet/Control/Session Manager' => {
        'Environment' => {
            '/TEMP' => '%SystemRoot%\\TEMP',
            '/OS'   => 'Windows_NT',
        }
    },
    'HKEY_USERS/' => {
        'S-1-5-21-2246875202-1293753324-4206800371-500/' => {
            'Software/' => {
                'SimonTatham/' => {
                    'PuTTY/' => {
                        '/Version' => '4.1',
                        'SshHostKeys/' => {
                            '/rsa2@22:192.168.20.32' => '76f523a6eec4ea6b'
                        },
                        '/username' => 'johndoe'
                    }
                },
                'Mozilla/' => {
                    'Firefox/' => {
                        '/Version' => '59.0'
                    }
                }
            }
        },
        'S-1-5-21-2246875202-1293753324-4206800567-500/' => {
            '/DisplayName' => 'Janine',
            'Software/' => {
                'SimonTatham/' => {
                    'PuTTY/' => {
                        '/Version' => '5.2',
                        '/username' => 'jane',
                        'SshHostKeys/' => {
                            '/rsa2@22:192.168.20.54' => 'fdfb3a2eeaa7'
                        }
                    }
                },
                'Mozilla/' => {
                    'Firefox/' => {
                        '/Version' => '62.0',
                        'Configuration/' => {},
                        '/Timeout' => '15'
                    }
                }
            }
        }
    }
);

my %regkey_tests = (
    'nopath' => {
        _expected => undef
    },
    'undef-path' => {
        path      => undef,
        _expected => undef
    },
    'emptypath' => {
        path      => '',
        _expected => undef
    },
    'badroot' => {
        path      => 'HKEY_NOT_A_ROOT/Not_existing_Key_path',
        _expected => undef
    },
    'teamviewer' => {
        path      => 'HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/TeamViewer',
        _expected => bless({
            '/ClientID' => '0x12345678',
            '/Version'  => '12.0.72365',
            'subkey/'    => bless({
                '/value' => ''
            }, 'Win32::TieRegistry')
        }, 'Win32::TieRegistry')
    },
    'environment' => {
        path      => 'HKEY_LOCAL_MACHINE/CurrentControlSet/Control/Session Manager/Environment',
        _expected => bless({
            '/TEMP' => '%SystemRoot%\\TEMP',
            '/OS'   => 'Windows_NT'
        }, 'Win32::TieRegistry')
    }
);

my %regval_tests = (
    'nopath' => {
        _expected => undef
    },
    'undef-path' => {
        path      => undef,
        _expected => undef
    },
    'emptypath' => {
        path      => '',
        _expected => undef
    },
    'badroot' => {
        path      => 'HKEY_NOT_A_ROOT/Not_existing_Key_path',
        _expected => undef
    },
    'teamviewerid' => {
        path      => 'HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/TeamViewer/ClientID',
        _expected => '0x12345678'
    },
    'teamviewer-all' => {
        path      => 'HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/TeamViewer/*',
        _expected => {
            'ClientID' => '0x12345678',
            'Version'  => '12.0.72365',
        }
    },
    'teamviewerid-withtype' => {
        path      => 'HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/TeamViewer/ClientID',
        withtype  => 1,
        _expected => [ '0x12345678', REG_DWORD() ]
    },
    'teamviewer-all-withtype' => {
        path      => 'HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/TeamViewer/*',
        withtype  => 1,
        _expected => {
            'ClientID' => [ '0x12345678', REG_DWORD() ],
            'Version'  => [ '12.0.72365', REG_SZ() ],
        }
    },
    'temp-env' => {
        path      => 'HKEY_LOCAL_MACHINE/CurrentControlSet/Control/Session Manager/Environment/TEMP',
        _expected => '%SystemRoot%\\TEMP'
    },
    'putty_keys' => {
        path      => 'HKEY_USERS/**/Software/SimonTatham/PuTTY/SshHostKeys/*',
        _expected => {
            'S-1-5-21-2246875202-1293753324-4206800371-500/Software/SimonTatham/PuTTY/SshHostKeys/rsa2@22:192.168.20.32'
                => '76f523a6eec4ea6b',
            'S-1-5-21-2246875202-1293753324-4206800567-500/Software/SimonTatham/PuTTY/SshHostKeys/rsa2@22:192.168.20.54'
                => 'fdfb3a2eeaa7'
        }
    },
    'users_software_versions' => {
        path      => 'HKEY_USERS/**/Software/Mozilla/Firefox/Version',
        _expected => {
            'S-1-5-21-2246875202-1293753324-4206800567-500/Software/Mozilla/Firefox/Version' => '62.0',
            'S-1-5-21-2246875202-1293753324-4206800371-500/Software/Mozilla/Firefox/Version' => '59.0'
        }
    },
    'users_softwares_versions' => {
        path      => 'HKEY_USERS/**/Software/**/**/Version',
        _expected => {
            'S-1-5-21-2246875202-1293753324-4206800371-500/Software/SimonTatham/PuTTY/Version' => '4.1',
            'S-1-5-21-2246875202-1293753324-4206800567-500/Software/SimonTatham/PuTTY/Version' => '5.2',
            'S-1-5-21-2246875202-1293753324-4206800371-500/Software/Mozilla/Firefox/Version' => '59.0',
            'S-1-5-21-2246875202-1293753324-4206800567-500/Software/Mozilla/Firefox/Version' => '62.0'
        }
    },
    'users_software_values' => {
        path      => 'HKEY_USERS/**/Software/**/**/*',
        _expected => {
            'S-1-5-21-2246875202-1293753324-4206800371-500/Software/SimonTatham/PuTTY/Version' => '4.1',
            'S-1-5-21-2246875202-1293753324-4206800371-500/Software/SimonTatham/PuTTY/username' => 'johndoe',
            'S-1-5-21-2246875202-1293753324-4206800567-500/Software/SimonTatham/PuTTY/Version' => '5.2',
            'S-1-5-21-2246875202-1293753324-4206800567-500/Software/Mozilla/Firefox/Version' => '62.0',
            'S-1-5-21-2246875202-1293753324-4206800371-500/Software/Mozilla/Firefox/Version' => '59.0',
            'S-1-5-21-2246875202-1293753324-4206800567-500/Software/SimonTatham/PuTTY/username' => 'jane',
            'S-1-5-21-2246875202-1293753324-4206800567-500/Software/Mozilla/Firefox/Timeout' => '15'
        }
    },
    'users_software_values' => {
        path      => 'HKEY_USERS/**/Software/**/Firefox/*',
        _expected => {
            'S-1-5-21-2246875202-1293753324-4206800567-500/Software/Mozilla/Firefox/Version' => '62.0',
            'S-1-5-21-2246875202-1293753324-4206800371-500/Software/Mozilla/Firefox/Version' => '59.0',
            'S-1-5-21-2246875202-1293753324-4206800567-500/Software/Mozilla/Firefox/Timeout' => '15'
        }
    },
    'users_vars' => {
        path      => 'HKEY_USERS/**/*',
        _expected => {
            'S-1-5-21-2246875202-1293753324-4206800567-500/DisplayName' => 'Janine'
        }
    },
    'users_displayname' => {
        path      => 'HKEY_USERS/**/DisplayName',
        _expected => {
            'S-1-5-21-2246875202-1293753324-4206800567-500/DisplayName' => 'Janine'
        }
    },
    'bad_glob_on_values' => {
        path      => 'HKEY_USERS/**/Software/**/**/**',
        _expected => {}
    },
    'bad_glob_on_values_2' => {
        path      => 'HKEY_USERS/S-1-5-21-2246875202-1293753324-4206800371-500/Software/Mozilla/Firefox/**',
        _expected => undef
    },
    'bad_glob_on_values_3' => {
        path      => 'HKEY_USERS/**/**',
        _expected => {}
    }
);

my $win32_only_test_count = 7;

plan tests =>
    (scalar keys %tests) + $win32_only_test_count +
    (scalar keys %regkey_tests) + (scalar keys %regval_tests);

GLPI::Agent::Tools::Win32->require();
GLPI::Agent::Tools::Win32->use('getInterfaces');

my $module = Test::MockModule->new(
    'GLPI::Agent::Tools::Win32'
);

foreach my $test (keys %tests) {
    $module->mock(
        'getWMIObjects',
        mockGetWMIObjects($test)
    );

    my @interfaces = getInterfaces();
    cmp_deeply(
        \@interfaces,
        $tests{$test},
        "$test sample"
    );
}

SKIP: {
    skip 'Avoid windows-emulation based tests on win32',
        (scalar keys %regkey_tests) + (scalar keys %regval_tests)
            if $OSNAME eq 'MSWin32';

    $module->mock(
        '_getRegistryKey',
        sub {
            my (%params) = @_;
            return unless ($params{root} && $params{keyName});
            return unless exists($register{$params{root}});
            my $root = $register{$params{root}};
            return unless exists($root->{$params{keyName}});
            my $key = { %{$root->{$params{keyName}}} };
            # Bless leaf as expected
            map { bless $key->{$_}, 'Win32::TieRegistry' }
                grep { ref($key->{$_}) eq 'HASH' } keys %{$key};
            bless $key, 'Win32::TieRegistry';
            return $key;
        }
    );

    $module->mock(
        '_getRegistryRoot',
        sub {
            my (%params) = @_;
            return unless $params{root};
            my $root;
            if (exists($register{$params{root}})) {
                $root = { %{$register{$params{root}}} };
            } else {
                $root = \%register;
                foreach my $part (split('/',$params{root})) {
                    return unless $root->{$part.'/'};
                    $root = { %{$root->{$part.'/'}} }
                }
            }
            # Bless leaf as expected
            map { bless $root->{$_}, 'Win32::TieRegistry' } grep { m|/$| } keys %{$root};
            bless $root, 'Win32::TieRegistry';
            return $root;
        }
    );

    GLPI::Agent::Tools::Win32->use('getRegistryKey');
    foreach my $test (keys %regkey_tests) {

        my $regkey = getRegistryKey( %{$regkey_tests{$test}} );
        cmp_deeply(
            $regkey,
            $regkey_tests{$test}->{_expected},
            "$test regkey"
        );
    }

    GLPI::Agent::Tools::Win32->use('getRegistryValue');
    foreach my $test (keys %regval_tests) {

        my $regval = getRegistryValue( %{$regval_tests{$test}} );
        cmp_deeply(
            $regval,
            $regval_tests{$test}->{_expected},
            "$test regval"
        );
    }
}

SKIP: {
    skip 'Windows-specific test', $win32_only_test_count
        unless $OSNAME eq 'MSWin32';

    GLPI::Agent::Tools::Win32->use('runCommand');

    my ($code, $fd) = runCommand(command => "perl -V");
    ok($code eq 0, "perl -V returns 0");

    ok(any { /Summary of my perl5/ } <$fd>, "perl -V output looks good");

    ($code, $fd) = runCommand(
        timeout => 1,
        command => "perl -e\"sleep 10\""
    );
    ok($code eq 293, "timeout=1: timeout catched");
    my $command = "perl -BAD";
    ($code, $fd) = runCommand(
        command => $command,
        no_stderr => 1
    );
    ok(defined(<$fd>), "no_stderr=0: catch STDERR output");

    # From here we need to avoid crashes due to not thread-safe Win32::OLE
    GLPI::Agent::Tools::Win32::start_Win32_OLE_Worker();

    GLPI::Agent::Tools::Win32->use('is64bit');
    ok(defined(is64bit()), "is64bit api call");

    GLPI::Agent::Tools::Win32->use('getLocalCodepage');
    ok(defined(getLocalCodepage()), "getLocalCodepage api call");
    ok(getLocalCodepage() =~ /^cp.+/, "local codepage check");

    # If we crash after that, this means Win32::OLE is not used in a
    # dedicated thread
    my $pid = fork;
    if (defined($pid)) {
        waitpid $pid, 0;
    } else {
        exit(0);
    }
}
