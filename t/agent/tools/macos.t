#!/usr/bin/perl

use strict;
use warnings;

# Tests are encoded in utf8 in this file
use utf8;

use Test::Deep;
use Test::More;
use English;
use UNIVERSAL::require;

use GLPI::Agent::Tools::MacOS;
use GLPI::Agent::Task::Inventory::MacOS::Softwares;

my %system_profiler_tests = (
    '10.4-powerpc' => {
        'Network' => {
            'Ethernet intégré 2' => {
                'Has IP Assigned' => 'No',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'en1',
                'Ethernet'        => {
                    'Media Subtype' => 'autoselect',
                    'MAC Address'   => '00:14:51:61:ef:09',
                    'Media Options' => undef
                },
                'Hardware' => 'Ethernet',
                'Type'     => 'Ethernet',
                'IPv4'     => { 'Configuration Method' => 'DHCP' },
                'Proxies'  => {
                    'Auto Discovery Enabled'     => 'No',
                    'FTP Passive Mode'           => 'Yes',
                    'Proxy Configuration Method' => 'Manual',
                    'ExcludeSimpleHostnames'     => '0'
                }
            },
            'Modem interne' => {
                'Has IP Assigned' => 'No',
                'Type'            => 'PPP (PPPSerial)',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'modem',
                'IPv4'            => { 'Configuration Method' => 'PPP' },
                'Hardware'        => 'Modem',
                'Proxies'         => {
                    'Auto Discovery Enabled'     => 'No',
                    'FTP Passive Mode'           => 'Yes',
                    'Proxy Configuration Method' => 'Manual',
                    'ExcludeSimpleHostnames'     => '0'
                }
            },
            'FireWire intégré_0' => {
                'Has IP Assigned' => 'No',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'fw1',
                'Ethernet'        => {
                    'Media Subtype' => 'autoselect',
                    'MAC Address'   => '00:14:51:ff:fe:1a:c8:e2',
                    'Media Options' => 'Full Duplex'
                },
                'Hardware' => 'FireWire',
                'Type'     => 'FireWire',
                'IPv4'     => { 'Configuration Method' => 'DHCP' },
                'Proxies'  => {
                    'Auto Discovery Enabled'     => 'No',
                    'FTP Passive Mode'           => 'Yes',
                    'Proxy Configuration Method' => 'Manual',
                    'ExcludeSimpleHostnames'     => '0'
                }
            },
            'Ethernet intégré' => {
                'Has IP Assigned' => 'Yes',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'en0',
                'Ethernet'        => {
                    'Media Subtype' => '100baseTX',
                    'MAC Address'   => '00:14:51:61:ef:08',
                    'Media Options' => 'Full Duplex, flow-control'
                },
                'Hardware' => 'Ethernet',
                'DNS'      => {
                    'Server Addresses' => '10.0.1.1',
                    'Domain Name'      => 'lan'
                },
                'Type'                  => 'Ethernet',
                'IPv4 Addresses'        => '10.0.1.110',
                'DHCP Server Responses' => {
                    'Routers'                  => '10.0.1.1',
                    'Domain Name'              => 'lan',
                    'Subnet Mask'              => '255.255.255.0',
                    'Server Identifier'        => '10.0.1.1',
                    'DHCP Message Type'        => '0x05',
                    'Lease Duration (seconds)' => '0',
                    'Domain Name Servers'      => '10.0.1.1'
                },
                'IPv4' => {
                    'Router'               => '10.0.1.1',
                    'Interface Name'       => 'en0',
                    'Configuration Method' => 'DHCP',
                    'Subnet Masks'         => '255.255.255.0',
                    'Addresses'            => '10.0.1.110'
                },
                'Proxies' => {
                    'SOCKS Proxy Enabled'  => 'No',
                    'HTTPS Proxy Enabled'  => 'No',
                    'FTP Proxy Enabled'    => 'No',
                    'Gopher Proxy Enabled' => 'No',
                    'FTP Passive Mode'     => 'Yes',
                    'HTTP Proxy Enabled'   => 'No',
                    'RTSP Proxy Enabled'   => 'No'
                }
            },
            'Bluetooth' => {
                'Has IP Assigned' => 'No',
                'Type'            => 'PPP (PPPSerial)',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'Bluetooth-Modem',
                'IPv4'            => { 'Configuration Method' => 'PPP' },
                'Hardware'        => 'Modem',
                'Proxies'         => {
                    'Auto Discovery Enabled'     => 'No',
                    'FTP Passive Mode'           => 'Yes',
                    'Proxy Configuration Method' => 'Manual',
                    'ExcludeSimpleHostnames'     => '0'
                }
            },
            'FireWire intégré' => {
                'Has IP Assigned' => 'No',
                'Type'            => 'FireWire',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'fw0',
                'IPv4'            => { 'Configuration Method' => 'DHCP' },
                'Hardware'        => 'FireWire',
                'Proxies'         => {
                    'Auto Discovery Enabled'     => 'No',
                    'FTP Passive Mode'           => 'Yes',
                    'Proxy Configuration Method' => 'Manual',
                    'ExcludeSimpleHostnames'     => '0'
                }
            }
        },
        'Locations' => {
            'Automatic' => {
                'Services' => {
                    'Ethernet intégré 2' => {
                        'Type' => 'Ethernet',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'en1',
                        'AppleTalk' => { 'Configuration Method' => 'Node' },
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'Auto Discovery Enabled'     => '0',
                            'FTP Passive Mode'           => '1',
                            'Proxy Configuration Method' => '2',
                            'ExcludeSimpleHostnames'     => '0'
                        },
                        'Hardware (MAC) Address' => '00:14:51:61:ef:09'
                    },
                    'Modem interne' => {
                        'Type'    => 'PPP',
                        'IPv6'    => { 'Configuration Method' => 'Automatic' },
                        'IPv4'    => { 'Configuration Method' => 'PPP' },
                        'Proxies' => {
                            'Auto Discovery Enabled'     => '0',
                            'FTP Passive Mode'           => '1',
                            'Proxy Configuration Method' => '2',
                            'ExcludeSimpleHostnames'     => '0'
                        },
                        'PPP' => {
                            'IPCP Compression VJ'            => '1',
                            'Idle Reminder'                  => '0',
                            'Disconnect On Idle Timer'       => '600',
                            'Dial On Demand'                 => '0',
                            'Idle Reminder Time'             => '1800',
                            'Disconnect On Fast User Switch' => '1',
                            'Disconnect On Logout'           => '1',
                            'ACSP Enabled'                   => '0',
                            'Log File'                => '/var/log/ppp.log',
                            'Redial Enabled'          => '1',
                            'Verbose Logging'         => '0',
                            'Redial Interval'         => '5',
                            'Use Terminal Script'     => '0',
                            'Disconnect On Sleep'     => '1',
                            'LCP Echo Failure'        => '4',
                            'Disconnect On Idle'      => '1',
                            'LCP Echo Interval'       => '10',
                            'Redial Count'            => '1',
                            'LCP Echo Enabled'        => '1',
                            'Display Terminal Window' => '0'
                        }
                    },
                    'FireWire intégré_0' => {
                        'Type' => 'FireWire',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'fw1',
                        'AppleTalk' => { 'Configuration Method' => 'Node' },
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'Auto Discovery Enabled'     => '0',
                            'FTP Passive Mode'           => '1',
                            'Proxy Configuration Method' => '2',
                            'ExcludeSimpleHostnames'     => '0'
                        },
                        'Hardware (MAC) Address' => '00:14:51:ff:fe:1a:c8:e2'
                    },
                    'Ethernet intégré' => {
                        'Type' => 'Ethernet',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'en0',
                        'AppleTalk' => { 'Configuration Method' => 'Node' },
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'SOCKS Proxy Enabled'  => '0',
                            'HTTPS Proxy Enabled'  => '0',
                            'FTP Proxy Enabled'    => '0',
                            'Gopher Proxy Enabled' => '0',
                            'FTP Passive Mode'     => '1',
                            'HTTP Proxy Enabled'   => '0',
                            'RTSP Proxy Enabled'   => '0'
                        },
                        'Hardware (MAC) Address' => '00:14:51:61:ef:08'
                    },
                    'Bluetooth' => {
                        'Type'    => 'PPP',
                        'IPv6'    => { 'Configuration Method' => 'Automatic' },
                        'IPv4'    => { 'Configuration Method' => 'PPP' },
                        'Proxies' => {
                            'Auto Discovery Enabled'     => '0',
                            'FTP Passive Mode'           => '1',
                            'Proxy Configuration Method' => '2',
                            'ExcludeSimpleHostnames'     => '0'
                        },
                        'PPP' => {
                            'IPCP Compression VJ'            => '1',
                            'Idle Reminder'                  => '0',
                            'Disconnect On Idle Timer'       => '600',
                            'Dial On Demand'                 => '0',
                            'Idle Reminder Time'             => '1800',
                            'Disconnect On Fast User Switch' => '1',
                            'Disconnect On Logout'           => '1',
                            'ACSP Enabled'                   => '0',
                            'Log File'                => '/var/log/ppp.log',
                            'Redial Enabled'          => '1',
                            'Verbose Logging'         => '0',
                            'Redial Interval'         => '5',
                            'Use Terminal Script'     => '0',
                            'Disconnect On Sleep'     => '1',
                            'LCP Echo Failure'        => '4',
                            'Disconnect On Idle'      => '1',
                            'LCP Echo Interval'       => '10',
                            'Redial Count'            => '1',
                            'LCP Echo Enabled'        => '0',
                            'Display Terminal Window' => '0'
                        }
                    },
                    'FireWire intégré' => {
                        'Type' => 'FireWire',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'fw0',
                        'AppleTalk' => { 'Configuration Method' => 'Node' },
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'Auto Discovery Enabled'     => '0',
                            'FTP Passive Mode'           => '1',
                            'Proxy Configuration Method' => '2',
                            'ExcludeSimpleHostnames'     => '0'
                        }
                    }
                },
                'Active Location' => 'Yes'
            }
        },
        'Hardware' => {
            'Hardware Overview' => {
                'Boot ROM Version'   => '5.2.7f1',
                'Machine Name'       => 'Power Mac G5',
                'Serial Number'      => 'CK54202SR6V',
                'Bus Speed'          => '1.15 GHz',
                'Machine Model'      => 'PowerMac11,2',
                'Number Of CPUs'     => '2',
                'Memory'             => '2 GB',
                'CPU Type'           => 'PowerPC G5 (1.1)',
                'L2 Cache (per CPU)' => '1 MB',
                'CPU Speed'          => '2.3 GHz'
            }
        },
        'Diagnostics' => {
            'Power On Self-Test' => {
                'Result'   => 'Passed',
                'Last Run' => '27/07/10 17:27'
            }
        },
        'Serial-ATA' => {
            'Serial-ATA Bus' => {
                'Maxtor 6B250S0' => {
                    'Volumes' => {
                        'osx105' => {
                            'Mount Point' => '/Volumes/osx105',
                            'File System' => 'Journaled HFS+',
                            'Writable'    => 'Yes',
                            'BSD Name'    => 'disk0s3',
                            'Capacity'    => '21.42 GB',
                            'Available'   => '6.87 GB'
                        },
                        'fwosx104' => {
                            'Mount Point' => '/',
                            'File System' => 'Journaled HFS+',
                            'Writable'    => 'Yes',
                            'BSD Name'    => 'disk0s5',
                            'Capacity'    => '212.09 GB',
                            'Available'   => '203.48 GB'
                        }
                    },
                    'Revision'         => 'BANC1E50',
                    'Detachable Drive' => 'No',
                    'Serial Number'    => 'B623KFXH',
                    'Volumes_0'        => {
                        'disk0s5' => {
                            'File System' => 'Journaled HFS+',
                            'Writable'    => 'Yes',
                            'Capacity'    => '212.09 GB',
                            'Available'   => '203.48 GB'
                        },
                        'disk0s3' => {
                            'File System' => 'Journaled HFS+',
                            'Writable'    => 'Yes',
                            'Capacity'    => '21.42 GB',
                            'Available'   => '6.87 GB'
                        }
                    },
                    'Capacity'          => '233.76 GB',
                    'Model'             => 'Maxtor 6B250S0',
                    'Bay Name'          => '"A (upper)"',
                    'Removable Media'   => 'No',
                    'OS9 Drivers'       => 'No',
                    'Socket Type'       => 'Serial-ATA',
                    'BSD Name'          => 'disk0',
                    'S.M.A.R.T. status' => 'Verified',
                    'Protocol'          => 'ata',
                    'Unit Number'       => '0'
                }
            }
        },
        'PCI Cards' => {
            'bcom5714_0' => {
                'Slot'                => 'GIGE',
                'Subsystem Vendor ID' => '0x106b',
                'Revision ID'         => '0x0003',
                'Device ID'           => '0x166a',
                'Type'                => 'network',
                'Subsystem ID'        => '0x0085',
                'Bus'                 => 'PCI',
                'Vendor ID'           => '0x14e4'
            },
            'bcom5714' => {
                'Slot'                => 'GIGE',
                'Subsystem Vendor ID' => '0x106b',
                'Revision ID'         => '0x0003',
                'Device ID'           => '0x166a',
                'Type'                => 'network',
                'Subsystem ID'        => '0x0085',
                'Bus'                 => 'PCI',
                'Vendor ID'           => '0x14e4'
            },
            'GeForce 6600' => {
                'Slot'                => 'SLOT-1',
                'Subsystem Vendor ID' => '0x10de',
                'Revision ID'         => '0x00a4',
                'Device ID'           => '0x0141',
                'Type'                => 'display',
                'Subsystem ID'        => '0x0010',
                'ROM Revision'        => '2149',
                'Bus'                 => 'PCI',
                'Name'                => 'NVDA,Display-B',
                'Vendor ID'           => '0x10de'
            }
        },
        'USB' => {
            'USB Bus' => {
                'Host Controller Driver'   => 'AppleUSBOHCI',
                'PCI Device ID'            => '0x0035',
                'Host Controller Location' => 'Built In USB',
                'Bus Number'               => '0x0b',
                'PCI Vendor ID'            => '0x1033',
                'PCI Revision ID'          => '0x0043'
            },
            'USB High-Speed Bus' => {
                'Host Controller Driver'   => 'AppleUSBEHCI',
                'PCI Device ID'            => '0x00e0',
                'Host Controller Location' => 'Built In USB',
                'Bus Number'               => '0x4b',
                'PCI Vendor ID'            => '0x1033',
                'PCI Revision ID'          => '0x0004'
            },
            'USB Bus_0' => {
                'Host Controller Driver'   => 'AppleUSBOHCI',
                'PCI Device ID'            => '0x0035',
                'Host Controller Location' => 'Built In USB',
                'Bus Number'               => '0x2b',
                'PCI Vendor ID'            => '0x1033',
                'PCI Revision ID'          => '0x0043'
            }
        },
        'ATA' => {
            'ATA Bus' => {
                'HL-DT-ST DVD-RW GWA-4165B' => {
                    'Revision'         => 'C006',
                    'Socket Type'      => 'Internal',
                    'Detachable Drive' => 'No',
                    'Serial Number'    => 'B6FD7234EC63',
                    'Protocol'         => 'ATAPI',
                    'Unit Number'      => '0',
                    'Model'            => 'HL-DT-ST DVD-RW GWA-4165B'
                }
            }
        },
        'Audio (Built In)' => {
            'Built In Sound Card_0' => {
                'Formats' => {
                    'PCM 24' => {
                        'Sample Rates' =>
                          '32 KHz, 44.1 KHz, 48 KHz, 64 KHz, 88.2 KHz, 96 KHz',
                        'Mixable'   => 'Yes',
                        'Channels'  => '2',
                        'Bit Width' => '32',
                        'Bit Depth' => '24'
                    },
                    'PCM 16' => {
                        'Sample Rates' =>
                          '32 KHz, 44.1 KHz, 48 KHz, 64 KHz, 88.2 KHz, 96 KHz',
                        'Mixable'   => 'Yes',
                        'Channels'  => '2',
                        'Bit Width' => '16',
                        'Bit Depth' => '16'
                    },
                    'AC3 16' => {
                        'Sample Rates' =>
                          '32 KHz, 44.1 KHz, 48 KHz, 64 KHz, 88.2 KHz, 96 KHz',
                        'Mixable'   => 'No',
                        'Channels'  => '2',
                        'Bit Width' => '16',
                        'Bit Depth' => '16'
                    }
                },
                'Devices' => {
                    'Crystal Semiconductor CS84xx' => {
                        'Inputs and Outputs' => {
                            'S/PDIF Digital Input' => {
                                'Playthrough' => 'No',
                                'PluginID'    => 'Topaz',
                                'Controls'    => 'Mute'
                            }
                        }
                    }
                }
            },
            'Built In Sound Card' => {
                'Formats' => {
                    'PCM 24' => {
                        'Sample Rates' =>
                          '32 KHz, 44.1 KHz, 48 KHz, 64 KHz, 88.2 KHz, 96 KHz',
                        'Mixable'   => 'Yes',
                        'Channels'  => '2',
                        'Bit Width' => '32',
                        'Bit Depth' => '24'
                    },
                    'PCM 16' => {
                        'Sample Rates' =>
                          '32 KHz, 44.1 KHz, 48 KHz, 64 KHz, 88.2 KHz, 96 KHz',
                        'Mixable'   => 'Yes',
                        'Channels'  => '2',
                        'Bit Width' => '16',
                        'Bit Depth' => '16'
                    },
                    'AC3 16' => {
                        'Sample Rates' =>
                          '32 KHz, 44.1 KHz, 48 KHz, 64 KHz, 88.2 KHz, 96 KHz',
                        'Mixable'   => 'No',
                        'Channels'  => '2',
                        'Bit Width' => '16',
                        'Bit Depth' => '16'
                    }
                },
                'Devices' => {
                    'Burr Brown PCM3052' => {
                        'Inputs and Outputs' => {
                            'Line Level Output' => {
                                'PluginID' => 'Onyx',
                                'Controls' => 'Mute, Left, Right'
                            },
                            'S/PDIF Digital Output' => {
                                'PluginID' => 'Onyx',
                                'Controls' => 'Mute'
                            },
                            'Internal Speakers' => {
                                'PluginID' => 'Onyx',
                                'Controls' => 'Mute, Master'
                            },
                            'Headphones' => {
                                'PluginID' => 'Onyx',
                                'Controls' => 'Mute, Left, Right'
                            },
                            'Line Level Input' => {
                                'Playthrough' => 'No',
                                'PluginID'    => 'Onyx',
                                'Controls'    => 'Mute, Master'
                            }
                        }
                    }
                }
            }
        },
        'Memory' => {
            'DIMM5/J7200' => {
                'Type'   => 'Empty',
                'Speed'  => 'Empty',
                'Size'   => 'Empty',
                'Status' => 'Empty'
            },
            'DIMM3/J7000' => {
                'Type'   => 'Empty',
                'Speed'  => 'Empty',
                'Size'   => 'Empty',
                'Status' => 'Empty'
            },
            'DIMM2/J6900' => {
                'Type'   => 'Empty',
                'Speed'  => 'Empty',
                'Size'   => 'Empty',
                'Status' => 'Empty'
            },
            'DIMM0/J6700' => {
                'Type'   => 'DDR2 SDRAM',
                'Speed'  => 'PC2-4200U-444',
                'Size'   => '1 GB',
                'Status' => 'OK'
            },
            'DIMM6/J7300' => {
                'Type'   => 'Empty',
                'Speed'  => 'Empty',
                'Size'   => 'Empty',
                'Status' => 'Empty'
            },
            'DIMM1/J6800' => {
                'Type'   => 'DDR2 SDRAM',
                'Speed'  => 'PC2-4200U-444',
                'Size'   => '1 GB',
                'Status' => 'OK'
            },
            'DIMM4/J7100' => {
                'Type'   => 'Empty',
                'Speed'  => 'Empty',
                'Size'   => 'Empty',
                'Status' => 'Empty'
            },
            'DIMM7/J7400' => {
                'Type'   => 'Empty',
                'Speed'  => 'Empty',
                'Size'   => 'Empty',
                'Status' => 'Empty'
            }
        },
        'Software' => {
            'System Software Overview' => {
                'Boot Volume'    => 'fwosx104',
                'System Version' => 'Mac OS X 10.4.11 (8S165)',
                'Kernel Version' => 'Darwin 8.11.0',
                'User Name'      => 'wawa (wawa)',
                'Computer Name'  => 'g5'
            }
        },
        'Disc Burning' => {
            'HL-DT-ST DVD-RW GWA-4165B' => {
                'Burn Underrun Protection DVD' => 'Yes',
                'Reads DVD'                    => 'Yes',
                'Cache'                        => '2048 KB',
                'Write Strategies' => 'CD-TAO, CD-SAO, CD-Raw, DVD-DAO',
                'Media'            => 'No',
                'Burn Underrun Protection CD' => 'Yes',
                'Interconnect'                => 'ATAPI',
                'DVD-Write'                   => '-R, -RW, +R, +RW, +R DL',
                'Burn Support'      => 'Yes (Apple Shipped/Supported)',
                'CD-Write'          => '-R, -RW',
                'Firmware Revision' => 'C006'
            }
        },
        'FireWire' => {
            'FireWire Bus' => {
                'Maximum Speed'  => 'Up to 800 Mb/sec',
                'Unknown Device' => {
                    'Maximum Speed'    => 'Up to 400 Mb/sec',
                    'Manufacturer'     => 'Unknown',
                    'Model'            => 'Unknown Device',
                    'Connection Speed' => 'Up to 400 Mb/sec'
                }
            }
        },
        'Graphics/Displays' => {
            'NVIDIA GeForce 6600' => {
                'Displays' => {
                    'Display'    => { 'Status' => 'No display connected' },
                    'ASUS VH222' => {
                        'Quartz Extreme' => 'Supported',
                        'Core Image'     => 'Supported',
                        'Display Asleep' => 'Yes',
                        'Main Display'   => 'Yes',
                        'Resolution'     => '1360 x 768 @ 60 Hz',
                        'Depth'          => '32-bit Color',
                        'Mirror'         => 'Off',
                        'Online'         => 'Yes'
                    }
                },
                'Slot'          => 'SLOT-1',
                'Chipset Model' => 'GeForce 6600',
                'Revision ID'   => '0x00a4',
                'Device ID'     => '0x0141',
                'Vendor'        => 'nVIDIA (0x10de)',
                'Type'          => 'Display',
                'ROM Revision'  => '2149',
                'Bus'           => 'PCI',
                'VRAM (Total)'  => '256 MB'
            }
        },
        'Power' => {
            'System Power Settings' => {
                'AC Power' => {
                    'Reduce Processor Speed'          => 'No',
                    'Dynamic Power Step'              => 'Yes',
                    'Display Sleep Timer (Minutes)'   => '10',
                    'Disk Sleep Timer (Minutes)'      => '10',
                    'Automatic Restart On Power Loss' => 'No',
                    'System Sleep Timer (Minutes)'    => '0',
                    'Sleep On Power Button'           => 'Yes',
                    'Wake On AC Change'               => 'No',
                    'Wake On Modem Ring'              => 'Yes',
                    'Wake On LAN'                     => 'Yes'
                }
            }
        }
    },
    '10.5-powerpc' => {
        'Locations' => {
            'Automatic' => {
                'Services' => {
                    'FireWire' => {
                        'Type' => 'FireWire',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'fw0',
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'FTP Passive Mode' => 'Yes',
                            'Exceptions List'  => '*.local, 169.254/16'
                        },
                        'Hardware (MAC) Address' => '00:14:51:ff:fe:1a:c8:e2'
                    },
                    'Ethernet' => {
                        'Type' => 'Ethernet',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'en0',
                        'AppleTalk' => { 'Configuration Method' => 'Node' },
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'FTP Passive Mode' => 'Yes',
                            'Exceptions List'  => '*.local, 169.254/16'
                        },
                        'Hardware (MAC) Address' => '00:14:51:61:ef:08',
                        'DNS'                    => {
                            'Server Addresses' => '10.0.1.1',
                            'Search Domains'   => 'lan'
                        }
                    },
                    'Bluetooth' => {
                        'Type'    => 'PPP',
                        'IPv6'    => { 'Configuration Method' => 'Automatic' },
                        'IPv4'    => { 'Configuration Method' => 'PPP' },
                        'Proxies' => { 'FTP Passive Mode' => 'Yes' },
                        'PPP'     => {
                            'IPCP Compression VJ'            => 'Yes',
                            'Idle Reminder'                  => 'No',
                            'Dial On Demand'                 => 'No',
                            'Idle Reminder Time'             => '1800',
                            'Disconnect On Fast User Switch' => 'Yes',
                            'Disconnect On Logout'           => 'Yes',
                            'ACSP Enabled'                   => 'No',
                            'Log File'                => '/var/log/ppp.log',
                            'Disconnect On Idle Time' => '600',
                            'Redial Enabled'          => 'Yes',
                            'Verbose Logging'         => 'No',
                            'Redial Interval'         => '5',
                            'Use Terminal Script'     => 'No',
                            'Disconnect On Sleep'     => 'Yes',
                            'LCP Echo Failure'        => '4',
                            'Disconnect On Idle'      => 'Yes',
                            'LCP Echo Interval'       => '10',
                            'Redial Count'            => '1',
                            'LCP Echo Enabled'        => 'No',
                            'Display Terminal Window' => 'No'
                        }
                    },
                    'AirPort' => {
                        'Type' => 'Ethernet',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'en1',
                        'AppleTalk' => { 'Configuration Method' => 'Node' },
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'FTP Passive Mode' => 'Yes',
                            'Exceptions List'  => '*.local, 169.254/16'
                        },
                        'Hardware (MAC) Address' => '00:14:51:61:ef:09'
                    }
                },
                'Active Location' => 'Yes'
            }
        },
        'PCI Cards' => {
            'Apple 5714' => {
                'Slot'                => 'GIGE',
                'Subsystem Vendor ID' => '0x106b',
                'Revision ID'         => '0x0003',
                'Device ID'           => '0x166a',
                'Type'                => 'network',
                'Driver Installed'    => 'Yes',
                'Subsystem ID'        => '0x0085',
                'Bus'                 => 'PCI',
                'Name'                => 'bcom5714',
                'Vendor ID'           => '0x14e4'
            },
            'GeForce 6600' => {
                'Slot'                => 'SLOT-1',
                'Subsystem Vendor ID' => '0x10de',
                'Link Width'          => 'x16',
                'Revision ID'         => '0x00a4',
                'Device ID'           => '0x0141',
                'Type'                => 'display',
                'Driver Installed'    => 'Yes',
                'Subsystem ID'        => '0x0010',
                'Link Speed'          => '2.5 GT/s',
                'ROM Revision'        => '2149',
                'Bus'                 => 'PCI',
                'Name'                => 'NVDA,Display-B',
                'Vendor ID'           => '0x10de'
            },
            'Apple 5714_0' => {
                'Slot'                => 'GIGE',
                'Subsystem Vendor ID' => '0x106b',
                'Revision ID'         => '0x0003',
                'Device ID'           => '0x166a',
                'Type'                => 'network',
                'Driver Installed'    => 'Yes',
                'Subsystem ID'        => '0x0085',
                'Bus'                 => 'PCI',
                'Name'                => 'bcom5714',
                'Vendor ID'           => '0x14e4'
            }
        },
        'USB' => {
            'USB Bus' => {
                'Host Controller Driver'   => 'AppleUSBOHCI',
                'PCI Device ID'            => '0x0035',
                'Host Controller Location' => 'Built In USB',
                'Logitech USB Keyboard'    => {
                    'Location ID'            => '0x0b200000',
                    'Version'                => '60.00',
                    'Current Available (mA)' => '500',
                    'Speed'                  => 'Up to 1.5 Mb/sec',
                    'Product ID'             => '0xc31b',
                    'Current Required (mA)'  => '98',
                    'Manufacturer'           => 'Logitech',
                    'Vendor ID'              => '0x046d  (Logitech Inc.)'
                },
                'Bus Number'      => '0x0b',
                'PCI Vendor ID'   => '0x1033',
                'PCI Revision ID' => '0x0043'
            },
            'USB High-Speed Bus' => {
                'Flash Disk' => {
                    'Product ID'       => '0x2092',
                    'Serial Number'    => '110074973765',
                    'Detachable Drive' => 'Yes',
                    'Volumes_0'        => {
                        'disk1s1' => {
                            'File System' => 'MS-DOS FAT32',
                            'Writable'    => 'Yes',
                            'Capacity'    => '1,96 GB',
                            'Available'   => '1,96 GB'
                        }
                    },
                    'Capacity'          => '1,96 GB',
                    'Mac OS 9 Drivers'  => 'No',
                    'Speed'             => 'Up to 480 Mb/sec',
                    'BSD Name'          => 'disk1',
                    'S.M.A.R.T. status' => 'Not Supported',
                    'Manufacturer'      => 'USB 2.0',
                    'Location ID'       => '0x4b400000',
                    'Volumes'           => {
                        'SANS TITRE' => {
                            'Mount Point' => '/Volumes/SANS TITRE',
                            'File System' => 'MS-DOS FAT32',
                            'Writable'    => 'Yes',
                            'BSD Name'    => 'disk1s1',
                            'Capacity'    => '1,96 GB',
                            'Available'   => '1,96 GB'
                        }
                    },
                    'Current Required (mA)'  => '100',
                    'Removable Media'        => 'Yes',
                    'Version'                => '1.00',
                    'Current Available (mA)' => '500',
                    'Partition Map Type'     => 'MBR (Master Boot Record)',
                    'Vendor ID' =>
                      '0x1e3d  (Chipsbrand Technologies (HK) Co., Limited)'
                },
                'Host Controller Driver'   => 'AppleUSBEHCI',
                'PCI Device ID'            => '0x00e0',
                'Host Controller Location' => 'Built In USB',
                'Bus Number'               => '0x4b',
                'DataTraveler 2.0'         => {
                    'Product ID'       => '0x1607',
                    'Serial Number'    => '89980116200801151425097A',
                    'Detachable Drive' => 'Yes',
                    'Volumes_0'        => {
                        'disk2s1' => {
                            'File System' => 'MS-DOS FAT32',
                            'Writable'    => 'Yes',
                            'Capacity'    => '3,76 GB',
                            'Available'   => '678,8 MB'
                        }
                    },
                    'Capacity'          => '3,76 GB',
                    'Mac OS 9 Drivers'  => 'No',
                    'Speed'             => 'Up to 480 Mb/sec',
                    'BSD Name'          => 'disk2',
                    'S.M.A.R.T. status' => 'Not Supported',
                    'Manufacturer'      => 'Kingston',
                    'Location ID'       => '0x4b100000',
                    'Volumes'           => {
                        'NO NAME' => {
                            'Mount Point' => '/Volumes/NO NAME',
                            'File System' => 'MS-DOS FAT32',
                            'Writable'    => 'Yes',
                            'BSD Name'    => 'disk2s1',
                            'Capacity'    => '3,76 GB',
                            'Available'   => '678,8 MB'
                        }
                    },
                    'Current Required (mA)'  => '100',
                    'Removable Media'        => 'Yes',
                    'Version'                => '2.00',
                    'Current Available (mA)' => '500',
                    'Partition Map Type'     => 'MBR (Master Boot Record)',
                    'Vendor ID' => '0x0951  (Kingston Technology Company)'
                },
                'PCI Revision ID' => '0x0004',
                'PCI Vendor ID'   => '0x1033'
            },
            'USB Bus_0' => {
                'Host Controller Driver' => 'AppleUSBOHCI',
                'USB Optical Mouse'      => {
                    'Location ID'            => '0x2b100000',
                    'Version'                => '2.00',
                    'Current Available (mA)' => '500',
                    'Speed'                  => 'Up to 1.5 Mb/sec',
                    'Product ID'             => '0x4d15',
                    'Current Required (mA)'  => '100',
                    'Vendor ID'              => '0x0461  (Primax Electronics)'
                },
                'PCI Device ID'            => '0x0035',
                'Host Controller Location' => 'Built In USB',
                'Bus Number'               => '0x2b',
                'PCI Vendor ID'            => '0x1033',
                'PCI Revision ID'          => '0x0043'
            }
        },
        'ATA' => {
            'ATA Bus' => {
                'HL-DT-ST DVD-RW GWA-4165B' => {
                    'Low Power Polling' => 'No',
                    'Revision'          => 'C006',
                    'Detachable Drive'  => 'No',
                    'Serial Number'     => 'B6FD7234EC63',
                    'Power Off'         => 'No',
                    'Model'             => 'HL-DT-ST DVD-RW GWA-4165B',
                    'Socket Type'       => 'Internal',
                    'Protocol'          => 'ATAPI',
                    'Unit Number'       => '0'
                }
            }
        },
        'Audio (Built In)' => {
            'Built-in Sound Card' => {
                'Formats' => {
                    'PCM 24' => {
                        'Sample Rates' =>
                          '32 KHz, 44.1 KHz, 48 KHz, 64 KHz, 88.2 KHz, 96 KHz',
                        'Mixable'   => 'Yes',
                        'Channels'  => '2',
                        'Bit Width' => '32',
                        'Bit Depth' => '24'
                    },
                    'PCM 16' => {
                        'Sample Rates' =>
                          '32 KHz, 44.1 KHz, 48 KHz, 64 KHz, 88.2 KHz, 96 KHz',
                        'Mixable'   => 'Yes',
                        'Channels'  => '2',
                        'Bit Width' => '16',
                        'Bit Depth' => '16'
                    },
                    'AC3 16' => {
                        'Sample Rates' =>
                          '32 KHz, 44.1 KHz, 48 KHz, 64 KHz, 88.2 KHz, 96 KHz',
                        'Mixable'   => 'No',
                        'Channels'  => '2',
                        'Bit Width' => '16',
                        'Bit Depth' => '16'
                    }
                },
                'Devices' => {
                    'Burr Brown PCM3052' => {
                        'Inputs and Outputs' => {
                            'Line Level Output' => {
                                'PluginID' => 'Onyx',
                                'Controls' => 'Mute, Left, Right'
                            },
                            'S/PDIF Digital Output' => {
                                'PluginID' => 'Onyx',
                                'Controls' => 'Mute'
                            },
                            'Internal Speakers' => {
                                'PluginID' => 'Onyx',
                                'Controls' => 'Mute, Master'
                            },
                            'Headphones' => {
                                'PluginID' => 'Onyx',
                                'Controls' => 'Mute, Left, Right'
                            },
                            'Line Level Input' => {
                                'Playthrough' => 'No',
                                'PluginID'    => 'Onyx',
                                'Controls'    => 'Mute, Master'
                            }
                        }
                    }
                }
            },
            'Built-in Sound Card_0' => {
                'Formats' => {
                    'PCM 24' => {
                        'Sample Rates' =>
                          '32 KHz, 44.1 KHz, 48 KHz, 64 KHz, 88.2 KHz, 96 KHz',
                        'Mixable'   => 'Yes',
                        'Channels'  => '2',
                        'Bit Width' => '32',
                        'Bit Depth' => '24'
                    },
                    'PCM 16' => {
                        'Sample Rates' =>
                          '32 KHz, 44.1 KHz, 48 KHz, 64 KHz, 88.2 KHz, 96 KHz',
                        'Mixable'   => 'Yes',
                        'Channels'  => '2',
                        'Bit Width' => '16',
                        'Bit Depth' => '16'
                    },
                    'AC3 16' => {
                        'Sample Rates' =>
                          '32 KHz, 44.1 KHz, 48 KHz, 64 KHz, 88.2 KHz, 96 KHz',
                        'Mixable'   => 'No',
                        'Channels'  => '2',
                        'Bit Width' => '16',
                        'Bit Depth' => '16'
                    }
                },
                'Devices' => {
                    'Crystal Semiconductor CS84xx' => {
                        'Inputs and Outputs' => {
                            'S/PDIF Digital Input' => {
                                'Playthrough' => 'No',
                                'PluginID'    => 'Topaz',
                                'Controls'    => 'Mute'
                            }
                        }
                    }
                }
            }
        },
        'Disc Burning' => {
            'HL-DT-ST DVD-RW GWA-4165B' => {
                'Reads DVD'        => 'Yes',
                'Cache'            => '2048 KB',
                'Write Strategies' => 'CD-TAO, CD-SAO, CD-Raw, DVD-DAO',
                'Media' =>
                  'Insert media and refresh to show available burn speeds',
                'Interconnect'      => 'ATAPI',
                'DVD-Write'         => '-R, -RW, +R, +R DL, +RW',
                'Burn Support'      => 'Yes (Apple Shipping Drive)',
                'CD-Write'          => '-R, -RW',
                'Firmware Revision' => 'C006'
            }
        },
        'Power' => {
            'Hardware Configuration' => { 'UPS Installed' => 'No' },
            'System Power Settings'  => {
                'AC Power' => {
                    'Reduce Processor Speed'          => 'No',
                    'Dynamic Power Step'              => 'Yes',
                    'Display Sleep Timer (Minutes)'   => '3',
                    'Disk Sleep Timer (Minutes)'      => '10',
                    'Automatic Restart On Power Loss' => 'No',
                    'System Sleep Timer (Minutes)'    => '0',
                    'Sleep On Power Button'           => 'Yes',
                    'Wake On AC Change'               => 'No',
                    'Wake On Clamshell Open'          => 'Yes',
                    'Wake On Modem Ring'              => 'Yes',
                    'Wake On LAN'                     => 'Yes'
                }
            }
        },
        'Universal Access' => {
            'Universal Access Information' => {
                'Zoom'                 => 'Off',
                'Display'              => 'Black on White',
                'Slow Keys'            => 'Off',
                'Flash Screen'         => 'Off',
                'Mouse Keys'           => 'Off',
                'Sticky Keys'          => 'Off',
                'VoiceOver'            => 'Off',
                'Cursor Magnification' => 'Off'
            }
        },
        'Volumes' => {
            'home' => {
                'Mounted From' => 'map auto_home',
                'Mount Point'  => '/home',
                'Type'         => 'autofs',
                'Automounted'  => 'Yes'
            },
            'net' => {
                'Mounted From' => 'map -hosts',
                'Mount Point'  => '/net',
                'Type'         => 'autofs',
                'Automounted'  => 'Yes'
            }
        },
        'Network' => {
            'FireWire' => {
                'Has IP Assigned' => 'No',
                'Type'            => 'FireWire',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'fw0',
                'Ethernet'        => {
                    'Media Subtype' => 'Auto Select',
                    'MAC Address'   => '00:14:51:ff:fe:1a:c8:e2',
                    'Media Options' => 'Full Duplex'
                },
                'Hardware' => 'FireWire',
                'Proxies'  => {
                    'FTP Passive Mode' => 'Yes',
                    'Exceptions List'  => '*.local, 169.254/16'
                }
            },
            'Ethernet' => {
                'Has IP Assigned' => 'Yes',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'en0',
                'Ethernet'        => {
                    'Media Subtype' => '100baseTX',
                    'MAC Address'   => '00:14:51:61:ef:08',
                    'Media Options' => 'Full Duplex, flow-control'
                },
                'AppleTalk' => {
                    'Node ID'              => '4',
                    'Network ID'           => '65420',
                    'Interface Name'       => 'en0',
                    'Default Zone'         => '*',
                    'Configuration Method' => 'Node'
                },
                'Hardware' => 'Ethernet',
                'DNS'      => {
                    'Server Addresses' => '10.0.1.1',
                    'Domain Name'      => 'lan',
                    'Search Domains'   => 'lan'
                },
                'DHCP Server Responses' => {
                    'Routers'                  => '10.0.1.1',
                    'Domain Name'              => 'lan',
                    'Subnet Mask'              => '255.255.255.0',
                    'Server Identifier'        => '10.0.1.1',
                    'DHCP Message Type'        => '0x05',
                    'Lease Duration (seconds)' => '0',
                    'Domain Name Servers'      => '10.0.1.1'
                },
                'Type'           => 'Ethernet',
                'IPv4 Addresses' => '10.0.1.110',
                'IPv4'           => {
                    'Router' => '10.0.1.1',
                    'NetworkSignature' =>
'IPv4.Router=10.0.1.1;IPv4.RouterHardwareAddress=00:1d:7e:43:96:57',
                    'Interface Name'       => 'en0',
                    'Configuration Method' => 'DHCP',
                    'Subnet Masks'         => '255.255.255.0',
                    'Addresses'            => '10.0.1.110'
                },
                'Proxies' => {
                    'FTP Passive Mode' => 'Yes',
                    'Exceptions List'  => '*.local, 169.254/16'
                }
            },
            'Bluetooth' => {
                'Has IP Assigned' => 'No',
                'Type'            => 'PPP (PPPSerial)',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'Bluetooth-Modem',
                'IPv4'            => { 'Configuration Method' => 'PPP' },
                'Hardware'        => 'Modem',
                'Proxies'         => { 'FTP Passive Mode' => 'Yes' }
            },
            'AirPort' => {
                'Has IP Assigned' => 'No',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'en1',
                'Ethernet'        => {
                    'Media Subtype' => 'Auto Select',
                    'MAC Address'   => '00:14:51:61:ef:09',
                    'Media Options' => undef
                },
                'Hardware' => 'AirPort',
                'Type'     => 'AirPort',
                'IPv4'     => { 'Configuration Method' => 'DHCP' },
                'Proxies'  => {
                    'FTP Passive Mode' => 'Yes',
                    'Exceptions List'  => '*.local, 169.254/16'
                }
            }
        },
        'Hardware' => {
            'Hardware Overview' => {
                'Model Identifier' => 'PowerMac11,2',
                'Boot ROM Version' => '5.2.7f1',
                'Processor Speed'  => '2.3 GHz',
                'Hardware UUID'    => '00000000-0000-1000-8000-00145161EF08',
                'Bus Speed'        => '1.15 GHz',
                'Processor Name'   => 'PowerPC G5 (1.1)',
                'Model Name'       => 'Power Mac G5',
                'Number Of CPUs'   => '2',
                'Memory'           => '2 GB',
                'Serial Number (system)' => 'CK54202SR6V',
                'L2 Cache (per CPU)'     => '1 MB'
            }
        },
        'Diagnostics' => {
            'Power On Self-Test' => {
                'Result'   => 'Passed',
                'Last Run' => '25/07/10 13:10'
            }
        },
        'Serial-ATA' => {
            'Serial-ATA Bus' => {
                'Maxtor 6B250S0' => {
                    'Revision'         => 'BANC1E50',
                    'Detachable Drive' => 'No',
                    'Serial Number'    => 'B623KFXH',
                    'Volumes_0'        => {
                        'disk0s5' => {
                            'File System' => 'Journaled HFS+',
                            'Writable'    => 'Yes',
                            'Capacity'    => '212,09 GB',
                            'Available'   => '211,8 GB'
                        },
                        'disk0s3' => {
                            'File System' => 'Journaled HFS+',
                            'Writable'    => 'Yes',
                            'Capacity'    => '21,42 GB',
                            'Available'   => '6,69 GB'
                        }
                    },
                    'Capacity'          => '233,76 GB',
                    'Model'             => 'Maxtor 6B250S0',
                    'Bay Name'          => '"B (lower)"',
                    'Mac OS 9 Drivers'  => 'No',
                    'Socket Type'       => 'Serial-ATA',
                    'BSD Name'          => 'disk0',
                    'S.M.A.R.T. status' => 'Verified',
                    'Unit Number'       => '0',
                    'Volumes'           => {
                        'osx105' => {
                            'Mount Point' => '/',
                            'File System' => 'Journaled HFS+',
                            'Writable'    => 'Yes',
                            'BSD Name'    => 'disk0s3',
                            'Capacity'    => '21,42 GB',
                            'Available'   => '6,69 GB'
                        },
                        'data' => {
                            'Mount Point' => '/Volumes/data',
                            'File System' => 'Journaled HFS+',
                            'Writable'    => 'Yes',
                            'BSD Name'    => 'disk0s5',
                            'Capacity'    => '212,09 GB',
                            'Available'   => '211,8 GB'
                        }
                    },
                    'Removable Media'    => 'No',
                    'Protocol'           => 'ata',
                    'Partition Map Type' => 'APM (Apple Partition Map)'
                }
            }
        },
        'FireWire' => {
            'FireWire Bus' => {
                'Maximum Speed'  => 'Up to 800 Mb/sec',
                'Unknown Device' => {
                    'Maximum Speed'    => 'Up to 400 Mb/sec',
                    'Manufacturer'     => 'Unknown',
                    'Model'            => 'Unknown',
                    'Connection Speed' => 'Unknown'
                },
                '(1394 ATAPI,Rev 1.00)' => {
                    'Maximum Speed' => 'Up to 400 Mb/sec',
                    'Sub-units'     => {
                        '(1394 ATAPI,Rev 1.00) Unit' => {
                            'Firmware Revision' => '0x12804',
                            'Sub-units'         => {
                                '(1394 ATAPI,Rev 1.00) SBP-LUN' => {
                                    'Volumes' => {
                                        'Video' => {
                                            'Mount Point' => '/Volumes/Video',
                                            'File System' => 'Journaled HFS+',
                                            'Writable'    => 'Yes',
                                            'BSD Name'    => 'disk3s3',
                                            'Capacity'    => '186,19 GB',
                                            'Available'   => '36,07 GB'
                                        }
                                    },
                                    'Volumes_0' => {
                                        'disk3s3' => {
                                            'File System' => 'Journaled HFS+',
                                            'Writable'    => 'Yes',
                                            'Capacity'    => '186,19 GB',
                                            'Available'   => '36,07 GB'
                                        }
                                    },
                                    'Capacity'          => '186,31 GB',
                                    'Removable Media'   => 'Yes',
                                    'Mac OS 9 Drivers'  => 'No',
                                    'BSD Name'          => 'disk3',
                                    'S.M.A.R.T. status' => 'Not Supported',
                                    'Partition Map Type' =>
                                      'APM (Apple Partition Map)'
                                }
                            },
                            'Product Revision Level' => {},
                            'Unit Spec ID'           => '0x609E',
                            'Unit Software Version'  => '0x10483'
                        }
                    },
                    'Manufacturer'     => 'Prolific PL3507 Combo Device',
                    'GUID'             => '0x50770E0000043E',
                    'Model'            => '0x1',
                    'Connection Speed' => 'Up to 400 Mb/sec'
                }
            }
        },
        'Software' => {
            'System Software Overview' => {
                'Time since boot' => '30 minutes',
                'Boot Mode'       => 'Normal',
                'Boot Volume'     => 'osx105',
                'System Version'  => 'Mac OS X 10.5.8 (9L31a)',
                'Kernel Version'  => 'Darwin 9.8.0',
                'User Name'       => 'fusioninventory (fusioninventory)',
                'Computer Name'   => 'g5'
            }
        },
        'Memory' => {
            'DIMM5/J7200' => {
                'Part Number'   => 'Empty',
                'Type'          => 'Empty',
                'Speed'         => 'Empty',
                'Size'          => 'Empty',
                'Status'        => 'Empty',
                'Serial Number' => 'Empty',
                'Manufacturer'  => 'Empty'
            },
            'DIMM3/J7000' => {
                'Part Number'   => 'Empty',
                'Type'          => 'Empty',
                'Speed'         => 'Empty',
                'Size'          => 'Empty',
                'Status'        => 'Empty',
                'Serial Number' => 'Empty',
                'Manufacturer'  => 'Empty'
            },
            'DIMM2/J6900' => {
                'Part Number'   => 'Empty',
                'Type'          => 'Empty',
                'Speed'         => 'Empty',
                'Size'          => 'Empty',
                'Status'        => 'Empty',
                'Serial Number' => 'Empty',
                'Manufacturer'  => 'Empty'
            },
            'DIMM0/J6700' => {
                'Part Number'   => 'Unknown',
                'Type'          => 'DDR2 SDRAM',
                'Speed'         => 'PC2-4200U-444',
                'Size'          => '1 GB',
                'Status'        => 'OK',
                'Serial Number' => 'Unknown',
                'Manufacturer'  => 'Unknown'
            },
            'DIMM6/J7300' => {
                'Part Number'   => 'Empty',
                'Type'          => 'Empty',
                'Speed'         => 'Empty',
                'Size'          => 'Empty',
                'Status'        => 'Empty',
                'Serial Number' => 'Empty',
                'Manufacturer'  => 'Empty'
            },
            'DIMM1/J6800' => {
                'Part Number'   => 'Unknown',
                'Type'          => 'DDR2 SDRAM',
                'Speed'         => 'PC2-4200U-444',
                'Size'          => '1 GB',
                'Status'        => 'OK',
                'Serial Number' => 'Unknown',
                'Manufacturer'  => 'Unknown'
            },
            'DIMM4/J7100' => {
                'Part Number'   => 'Empty',
                'Type'          => 'Empty',
                'Speed'         => 'Empty',
                'Size'          => 'Empty',
                'Status'        => 'Empty',
                'Serial Number' => 'Empty',
                'Manufacturer'  => 'Empty'
            },
            'DIMM7/J7400' => {
                'Part Number'   => 'Empty',
                'Type'          => 'Empty',
                'Speed'         => 'Empty',
                'Size'          => 'Empty',
                'Status'        => 'Empty',
                'Serial Number' => 'Empty',
                'Manufacturer'  => 'Empty'
            }
        },
        'Firewall' => {
            'Firewall Settings' =>
              { 'Mode' => 'Allow all incoming connections' }
        },
        'Printers' => {
            'Photosmart C4500 series [38705D]' => {
                'PPD'              => 'HP Photosmart C4500 series',
                'Print Server'     => 'Local',
                'PPD File Version' => '3.1',
                'URI' =>
'mdns://Photosmart%20C4500%20series%20%5B38705D%5D._pdl-datastream._tcp.local./?bidi',
                'Default'            => 'Yes',
                'Status'             => 'Idle',
                'Driver Version'     => '3.1',
                'PostScript Version' => '(3011.104) 0'
            }
        },
        'Graphics/Displays' => {
            'NVIDIA GeForce 6600' => {
                'Displays' => {
                    'Display Connector' =>
                      { 'Status' => 'No Display Connected' },
                    'ASUS VH222' => {
                        'Quartz Extreme' => 'Supported',
                        'Core Image'     => 'Hardware Accelerated',
                        'Main Display'   => 'Yes',
                        'Resolution'     => '1680 x 1050 @ 60 Hz',
                        'Depth'          => '32-Bit Color',
                        'Mirror'         => 'Off',
                        'Online'         => 'Yes',
                        'Rotation'       => 'Supported'
                    }
                },
                'Slot'            => 'SLOT-1',
                'PCIe Lane Width' => 'x16',
                'Chipset Model'   => 'GeForce 6600',
                'Revision ID'     => '0x00a4',
                'Device ID'       => '0x0141',
                'Vendor'          => 'NVIDIA (0x10de)',
                'Type'            => 'Display',
                'ROM Revision'    => '2149',
                'Bus'             => 'PCIe',
                'VRAM (Total)'    => '256 MB'
            }
        }
    },
    '10.6-intel' => {
        'Locations' => {
            'Automatic' => {
                'Services' => {
                    'Bluetooth DUN' => {
                        'Type'    => 'PPP',
                        'IPv6'    => { 'Configuration Method' => 'Automatic' },
                        'IPv4'    => { 'Configuration Method' => 'PPP' },
                        'Proxies' => { 'FTP Passive Mode' => 'Yes' },
                        'PPP'     => {
                            'IPCP Compression VJ'      => 'Yes',
                            'Idle Reminder'            => 'No',
                            'Idle Reminder Time'       => '1800',
                            'Disconnect on Logout'     => 'Yes',
                            'ACSP Enabled'             => 'No',
                            'Log File'                 => '/var/log/ppp.log',
                            'Redial Enabled'           => 'Yes',
                            'Verbose Logging'          => 'No',
                            'Dial on Demand'           => 'No',
                            'Redial Interval'          => '5',
                            'Use Terminal Script'      => 'No',
                            'Disconnect on Idle Timer' => '600',
                            'Disconnect on Sleep'      => 'Yes',
                            'LCP Echo Failure'         => '4',
                            'Disconnect on Idle'       => 'Yes',
                            'Disconnect on Fast User Switch' => 'Yes',
                            'LCP Echo Interval'              => '10',
                            'Redial Count'                   => '1',
                            'LCP Echo Enabled'               => 'No',
                            'Display Terminal Window'        => 'No'
                        }
                    },
                    'Parallels Host-Only Networking Adapter' => {
                        'Type' => 'Ethernet',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'en3',
                        'IPv4'            => {
                            'Configuration Method' => 'Manual',
                            'Subnet Masks'         => '255.255.255.0',
                            'Addresses'            => '192.168.1.16'
                        },
                        'Proxies' => {
                            'Exclude Simple Hostnames'   => 'No',
                            'Auto Discovery Enabled'     => 'No',
                            'FTP Passive Mode'           => 'Yes',
                            'Proxy Configuration Method' => '2'
                        },
                        'Hardware (MAC) Address' => '00:1c:42:00:00:09'
                    },
                    'Parallels Shared Networking Adapter' => {
                        'Type' => 'Ethernet',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'en2',
                        'IPv4'            => {
                            'Configuration Method' => 'Manual',
                            'Subnet Masks'         => '255.255.255.0',
                            'Addresses'            => '192.168.0.11'
                        },
                        'Proxies' => {
                            'Exclude Simple Hostnames'   => 'No',
                            'Auto Discovery Enabled'     => 'No',
                            'FTP Passive Mode'           => 'Yes',
                            'Proxy Configuration Method' => '2'
                        },
                        'Hardware (MAC) Address' => '00:1c:42:00:00:08'
                    },
                    'FireWire' => {
                        'Type' => 'FireWire',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'fw0',
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'FTP Passive Mode' => 'Yes',
                            'Exceptions List'  => '*.local, 169.254/16'
                        },
                        'Hardware (MAC) Address' => '00:1e:52:ff:fe:67:eb:68'
                    },
                    'Ethernet' => {
                        'Type' => 'Ethernet',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'en0',
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'FTP Passive Mode' => 'Yes',
                            'Exceptions List'  => '*.local, 169.254/16'
                        },
                        'Hardware (MAC) Address' => '00:1e:c2:0c:36:27'
                    },
                    'AirPort' => {
                        'Type' => 'IEEE80211',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'en1',
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'HTTP Proxy Server'  => '195.221.21.146',
                            'HTTP Proxy Port'    => '80',
                            'FTP Passive Mode'   => 'Yes',
                            'HTTP Proxy Enabled' => 'No',
                            'Exceptions List'    => '*.local, 169.254/16'
                        },
                        'Hardware (MAC) Address' => '00:1e:c2:a7:26:6f',
                        'IEEE80211'              => {
                            'Join Mode'              => 'Automatic',
                            'Disconnect on Logout'   => 'No',
                            'PowerEnabled'           => '0',
                            'RememberRecentNetworks' => '1',
                            'PreferredNetworks'      => {
                                'Unique Network ID' =>
                                  '905AE8BA-BD26-48F3-9486-AE5BC72FE642',
                                'SecurityType' => 'WPA2 Personal',
                                'Unique Password ID' =>
                                  '907EDC44-8C27-44A0-B5F5-2D04E1A5942A',
                                'SSID_STR' => 'freewa'
                            },
                            'JoinModeFallback' => 'Prompt'
                        }
                    }
                },
                'Active Location' => 'Yes'
            }
        },
        'USB' => {
            'USB Bus_1' => {
                'Host Controller Driver'   => 'AppleUSBUHCI',
                'PCI Device ID'            => '0x2831',
                'Host Controller Location' => 'Built-in USB',
                'Bus Number'               => '0x3d',
                'PCI Vendor ID'            => '0x8086',
                'PCI Revision ID'          => '0x0003'
            },
            'USB Bus_3' => {
                'Host Controller Driver'        => 'AppleUSBUHCI',
                'PCI Device ID'                 => '0x2834',
                'Bluetooth USB Host Controller' => {
                    'Location ID'            => '0x1a100000',
                    'Version'                => '19.65',
                    'Current Available (mA)' => '500',
                    'Speed'                  => 'Up to 12 Mb/sec',
                    'Product ID'             => '0x8206',
                    'Current Required (mA)'  => '0',
                    'Manufacturer'           => 'Apple Inc.',
                    'Vendor ID'              => '0x05ac  (Apple Inc.)'
                },
                'Host Controller Location' => 'Built-in USB',
                'Bus Number'               => '0x1a',
                'PCI Vendor ID'            => '0x8086',
                'PCI Revision ID'          => '0x0003'
            },
            'USB Bus' => {
                'Host Controller Driver'   => 'AppleUSBUHCI',
                'PCI Device ID'            => '0x2835',
                'Host Controller Location' => 'Built-in USB',
                'Bus Number'               => '0x3a',
                'PCI Vendor ID'            => '0x8086',
                'PCI Revision ID'          => '0x0003'
            },
            'USB High-Speed Bus_0' => {
                'Keyboard Hub' => {
                    'Location ID'       => '0xfa200000',
                    'Optical USB Mouse' => {
                        'Location ID'            => '0xfa230000',
                        'Version'                => ' 3.40',
                        'Current Available (mA)' => '100',
                        'Speed'                  => 'Up to 1.5 Mb/sec',
                        'Product ID'             => '0xc016',
                        'Current Required (mA)'  => '100',
                        'Manufacturer'           => 'Logitech',
                        'Vendor ID'              => '0x046d  (Logitech Inc.)'
                    },
                    'Flash Disk      ' => {
                        'Location ID' => '0xfa210000',
                        'Volumes'     => {
                            'SANS TITRE' => {
                                'Mount Point' => '/Volumes/SANS TITRE',
                                'File System' => 'MS-DOS FAT32',
                                'Writable'    => 'Yes',
                                'BSD Name'    => 'disk1s1',
                                'Capacity' =>
                                  '2,11 GB (2 109 671 424 bytes)',
                                'Available' =>
                                  '2,11 GB (2 105 061 376 bytes)'
                            }
                        },
                        'Product ID'            => '0x2092',
                        'Current Required (mA)' => '100',
                        'Serial Number'         => '110074973765',
                        'Detachable Drive'      => 'Yes',
                        'Capacity'        => '2,11 GB (2 109 734 912 bytes)',
                        'Removable Media' => 'Yes',
                        'Version'         => ' 1.00',
                        'Current Available (mA)' => '100',
                        'Speed'                  => 'Up to 480 Mb/sec',
                        'BSD Name'               => 'disk1',
                        'S.M.A.R.T. status'      => 'Not Supported',
                        'Partition Map Type'     => 'MBR (Master Boot Record)',
                        'Manufacturer'           => 'USB 2.0',
                        'Vendor ID' =>
                          '0x1e3d  (Chipsbrand Technologies (HK) Co., Limited)'
                    },
                    'Product ID'             => '0x1006',
                    'Current Required (mA)'  => '300',
                    'Serial Number'          => '000000000000',
                    'Version'                => '94.15',
                    'Speed'                  => 'Up to 480 Mb/sec',
                    'Current Available (mA)' => '500',
                    'Apple Keyboard'         => {
                        'Location ID'            => '0xfa220000',
                        'Version'                => ' 0.69',
                        'Current Available (mA)' => '100',
                        'Speed'                  => 'Up to 1.5 Mb/sec',
                        'Product ID'             => '0x0221',
                        'Current Required (mA)'  => '20',
                        'Manufacturer'           => 'Apple, Inc',
                        'Vendor ID'              => '0x05ac  (Apple Inc.)'
                    },
                    'Manufacturer' => 'Apple, Inc.',
                    'Vendor ID'    => '0x05ac  (Apple Inc.)'
                },
                'Host Controller Driver'   => 'AppleUSBEHCI',
                'PCI Device ID'            => '0x283a',
                'Host Controller Location' => 'Built-in USB',
                'Bus Number'               => '0xfa',
                'PCI Vendor ID'            => '0x8086',
                'PCI Revision ID'          => '0x0003'
            },
            'USB High-Speed Bus' => {
                'Host Controller Driver'   => 'AppleUSBEHCI',
                'PCI Device ID'            => '0x2836',
                'Host Controller Location' => 'Built-in USB',
                'Built-in iSight'          => {
                    'Location ID'            => '0xfd400000',
                    'Product ID'             => '0x8502',
                    'Current Required (mA)'  => '500',
                    'Serial Number'          => '6067E773DA9722F4 (03.01)',
                    'Version'                => ' 1.55',
                    'Speed'                  => 'Up to 480 Mb/sec',
                    'Current Available (mA)' => '500',
                    'Manufacturer'           => 'Apple Inc.',
                    'Vendor ID'              => '0x05ac  (Apple Inc.)'
                },
                'Bus Number'      => '0xfd',
                'PCI Vendor ID'   => '0x8086',
                'PCI Revision ID' => '0x0003'
            },
            'USB Bus_0' => {
                'Host Controller Driver'   => 'AppleUSBUHCI',
                'PCI Device ID'            => '0x2830',
                'Host Controller Location' => 'Built-in USB',
                'Bus Number'               => '0x1d',
                'PCI Vendor ID'            => '0x8086',
                'PCI Revision ID'          => '0x0003'
            },
            'USB Bus_2' => {
                'Host Controller Driver'   => 'AppleUSBUHCI',
                'PCI Device ID'            => '0x2832',
                'Host Controller Location' => 'Built-in USB',
                'Bus Number'               => '0x5d',
                'IR Receiver'              => {
                    'Location ID'            => '0x5d100000',
                    'Version'                => ' 0.16',
                    'Current Available (mA)' => '500',
                    'Speed'                  => 'Up to 1.5 Mb/sec',
                    'Product ID'             => '0x8242',
                    'Current Required (mA)'  => '100',
                    'Manufacturer'           => 'Apple Computer, Inc.',
                    'Vendor ID'              => '0x05ac  (Apple Inc.)'
                },
                'PCI Vendor ID'   => '0x8086',
                'PCI Revision ID' => '0x0003'
            }
        },
        'ATA' => {
            'ATA Bus' => {
                'MATSHITADVD-R   UJ-875' => {
                    'Low Power Polling' => 'Yes',
                    'Revision'          => 'DB09',
                    'Detachable Drive'  => 'No',
                    'Serial Number'     => '            fG424F9E',
                    'Power Off'         => 'No',
                    'Model'             => 'MATSHITADVD-R   UJ-875',
                    'Socket Type'       => 'Internal',
                    'Protocol'          => 'ATAPI',
                    'Unit Number'       => '0'
                }
            }
        },
        'Audio (Built In)' => {
            'Intel High Definition Audio' => {
                'Speaker' => { 'Connection' => 'Internal' },
                'S/PDIF Optical Digital Audio Input' =>
                  { 'Connection' => 'Combination Input' },
                'Headphone' => { 'Connection' => 'Combination Output' },
                'Internal Microphone' => { 'Connection' => 'Internal' },
                'Line Input' => { 'Connection' => 'Combination Input' },
                'Audio ID'   => '50',
                'S/PDIF Optical Digital Audio Output' =>
                  { 'Connection' => 'Combination Output' }
            }
        },
        'Disc Burning' => {
            'MATSHITA DVD-R   UJ-875' => {
                'Reads DVD'        => 'Yes',
                'Cache'            => '2048 KB',
                'Write Strategies' => 'CD-TAO, CD-SAO, DVD-DAO',
                'Media' =>
'To show the available burn speeds, insert a disc and choose View > Refresh',
                'Interconnect'      => 'ATAPI',
                'DVD-Write'         => '-R, -R DL, -RW, +R, +R DL, +RW',
                'Burn Support'      => 'Yes (Apple Shipping Drive)',
                'CD-Write'          => '-R, -RW',
                'Firmware Revision' => 'DB09'
            }
        },
        'Bluetooth' => {
            'Devices (Paired, Favorites, etc)' => {
                'Device_0' => {
                    'Type'      => 'Unknown',
                    'Connected' => 'No',
                    'Paired'    => 'No',
                    'Services'  => undef,
                    'Address'   => '00-0f-de-d0-2d-f6',
                    'Name'      => '00-0f-de-d0-2d-f6',
                    'Favorite'  => 'Yes'
                },
                'Device' => {
                    'Type'      => 'Unknown',
                    'Connected' => 'No',
                    'Paired'    => 'No',
                    'Services'  => undef,
                    'Address'   => '00-0a-28-f4-f3-23',
                    'Name'      => '00-0a-28-f4-f3-23',
                    'Favorite'  => 'Yes'
                },
                'Device_2' => {
                    'Type'      => 'Mobile Phone',
                    'Connected' => 'No',
                    'Paired'    => 'Yes',
                    'Services' =>
'Dial-up Networking, OBEX File Transfer, Voice GW, Object Push, Voice GW, WBTEXT, Advanced audio source, Serial Port',
                    'Address'      => '00-1e-e2-27-e9-02',
                    'Manufacturer' => 'Broadcom (0x3, 0x2222)',
                    'Name'         => 'SGH-D880',
                    'Favorite'     => 'Yes'
                },
                'Device_1' => {
                    'Type'      => 'Unknown',
                    'Connected' => 'No',
                    'Paired'    => 'No',
                    'Services'  => undef,
                    'Address'   => '00-12-d1-bf-a3-dc',
                    'Name'      => '00-12-d1-bf-a3-dc',
                    'Favorite'  => 'Yes'
                }
            },
            'Apple Bluetooth Software Version' => '2.3.3f8',
            'Outgoing Serial Ports'            => {
                'Serial Port 1' => {
                    'Address'                 => undef,
                    'Requires Authentication' => 'No',
                    'RFCOMM Channel'          => '0',
                    'Name'                    => 'Bluetooth-Modem'
                }
            },
            'Services' => {
                'Bluetooth File Transfer' => {
                    'Folder other devices can browse' => '~/Public',
                    'Requires Authentication'         => 'Yes',
                    'State'                           => 'Enabled'
                },
                'Bluetooth File Exchange' => {
                    'When receiving items'          => 'Prompt for each file',
                    'Folder for accepted items'     => '~/Documents',
                    'When PIM items are accepted'   => 'Ask',
                    'Requires Authentication'       => 'No',
                    'State'                         => 'Enabled',
                    'When other items are accepted' => 'Ask'
                }
            },
            'Hardware Settings' => {
                'Firmware Version'        => '1965',
                'Product ID'              => '0x8206',
                'Bluetooth Power'         => 'On',
                'Address'                 => '00-1e-52-ed-37-e4',
                'Requires Authentication' => 'No',
                'Discoverable'            => 'Yes',
                'Manufacturer'            => 'Cambridge Silicon Radio',
                'Vendor ID'               => '0x5ac',
                'Name'                    => 'lazer'
            },
            'Incoming Serial Ports' => {
                'Serial Port 1' => {
                    'Requires Authentication' => 'No',
                    'RFCOMM Channel'          => '3',
                    'Name'                    => 'Bluetooth-PDA-Sync'
                }
            }
        },
        'Power' => {
            'Hardware Configuration' => { 'UPS Installed' => 'No' },
            'System Power Settings'  => {
                'AC Power' => {
                    'Display Sleep Timer (Minutes)'   => '1',
                    'Disk Sleep Timer (Minutes)'      => '10',
                    'Automatic Restart On Power Loss' => 'No',
                    'System Sleep Timer (Minutes)'    => '10',
                    'Sleep On Power Button'           => 'Yes',
                    'Current Power Source'            => 'Yes',
                    'Display Sleep Uses Dim'          => 'Yes',
                    'Wake On LAN'                     => 'No'
                }
            }
        },
        'Universal Access' => {
            'Universal Access Information' => {
                'Zoom'                 => 'On',
                'Display'              => 'Black on White',
                'Slow Keys'            => 'Off',
                'Flash Screen'         => 'Off',
                'Mouse Keys'           => 'Off',
                'Sticky Keys'          => 'Off',
                'VoiceOver'            => 'Off',
                'Cursor Magnification' => 'Off'
            }
        },
        'Volumes' => {
            'home' => {
                'Mounted From' => 'map auto_home',
                'Mount Point'  => '/home',
                'Type'         => 'autofs',
                'Automounted'  => 'Yes'
            },
            'net' => {
                'Mounted From' => 'map -hosts',
                'Mount Point'  => '/net',
                'Type'         => 'autofs',
                'Automounted'  => 'Yes'
            }
        },
        'Network' => {
            'Parallels Host-Only Networking Adapter' => {
                'Has IP Assigned' => 'Yes',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'en3',
                'Ethernet'        => {
                    'Media Subtype' => 'Auto Select',
                    'MAC Address'   => '00:1c:42:00:00:09',
                    'Media Options' => undef
                },
                'Hardware'       => 'Ethernet',
                'Service Order'  => '9',
                'Type'           => 'Ethernet',
                'IPv4 Addresses' => '192.168.1.16',
                'IPv4'           => {
                    'Interface Name'       => 'en3',
                    'Configuration Method' => 'Manual',
                    'Subnet Masks'         => '255.255.255.0',
                    'Addresses'            => '192.168.1.16'
                },
                'Proxies' => {
                    'Exclude Simple Hostnames'   => '0',
                    'Auto Discovery Enabled'     => 'No',
                    'FTP Passive Mode'           => 'Yes',
                    'Proxy Configuration Method' => 'Manual'
                }
            },
            'Parallels Shared Networking Adapter' => {
                'Has IP Assigned' => 'Yes',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'en2',
                'Ethernet'        => {
                    'Media Subtype' => 'Auto Select',
                    'MAC Address'   => '00:1c:42:00:00:08',
                    'Media Options' => undef
                },
                'Hardware'       => 'Ethernet',
                'Service Order'  => '8',
                'Type'           => 'Ethernet',
                'IPv4 Addresses' => '192.168.0.11',
                'IPv4'           => {
                    'Interface Name'       => 'en2',
                    'Configuration Method' => 'Manual',
                    'Subnet Masks'         => '255.255.255.0',
                    'Addresses'            => '192.168.0.11'
                },
                'Proxies' => {
                    'Exclude Simple Hostnames'   => '0',
                    'Auto Discovery Enabled'     => 'No',
                    'FTP Passive Mode'           => 'Yes',
                    'Proxy Configuration Method' => 'Manual'
                }
            },
            'FireWire' => {
                'Has IP Assigned' => 'No',
                'Type'            => 'FireWire',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'fw0',
                'Ethernet'        => {
                    'Media Subtype' => 'Auto Select',
                    'MAC Address'   => '00:1e:52:ff:fe:67:eb:68',
                    'Media Options' => 'Full Duplex'
                },
                'IPv4'     => { 'Configuration Method' => 'DHCP' },
                'Hardware' => 'FireWire',
                'Proxies'  => {
                    'FTP Passive Mode' => 'Yes',
                    'Exceptions List'  => '*.local, 169.254/16'
                },
                'Service Order' => '2'
            },
            'Ethernet' => {
                'Has IP Assigned' => 'Yes',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'en0',
                'Ethernet'        => {
                    'Media Subtype' => '100baseTX',
                    'MAC Address'   => '00:1e:c2:0c:36:27',
                    'Media Options' => 'Full Duplex, Flow Control'
                },
                'Hardware'      => 'Ethernet',
                'Service Order' => '1',
                'DNS'           => {
                    'Server Addresses' => '10.0.1.1',
                    'Domain Name'      => 'lan'
                },
                'Type'                  => 'Ethernet',
                'IPv4 Addresses'        => '10.0.1.101',
                'DHCP Server Responses' => {
                    'Routers'                  => '10.0.1.1',
                    'Domain Name'              => 'lan',
                    'Subnet Mask'              => '255.255.255.0',
                    'Server Identifier'        => '10.0.1.1',
                    'DHCP Message Type'        => '0x05',
                    'Lease Duration (seconds)' => '0',
                    'Domain Name Servers'      => '10.0.1.1'
                },
                'IPv4' => {
                    'Router'         => '10.0.1.1',
                    'Interface Name' => 'en0',
                    'Network Signature' =>
'IPv4.Router=10.0.1.1;IPv4.RouterHardwareAddress=00:1d:7e:43:96:57',
                    'Configuration Method' => 'DHCP',
                    'Subnet Masks'         => '255.255.255.0',
                    'Addresses'            => '10.0.1.101'
                },
                'Proxies' => {
                    'FTP Passive Mode' => 'Yes',
                    'Exceptions List'  => '*.local, 169.254/16'
                }
            },
            'Bluetooth' => {
                'Has IP Assigned' => 'No',
                'Type'            => 'PPP (PPPSerial)',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'Bluetooth-Modem',
                'IPv4'            => { 'Configuration Method' => 'PPP' },
                'Hardware'        => 'Modem',
                'Proxies'         => { 'FTP Passive Mode' => 'Yes' },
                'Service Order'   => '0'
            },
            'AirPort' => {
                'Has IP Assigned' => 'No',
                'Type'            => 'AirPort',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'en1',
                'Ethernet'        => {
                    'Media Subtype' => 'Auto Select',
                    'MAC Address'   => '00:1e:c2:a7:26:6f',
                    'Media Options' => undef
                },
                'IPv4'     => { 'Configuration Method' => 'DHCP' },
                'Hardware' => 'AirPort',
                'Proxies'  => {
                    'HTTP Proxy Server'  => '195.221.21.146',
                    'HTTP Proxy Port'    => '80',
                    'FTP Passive Mode'   => 'Yes',
                    'HTTP Proxy Enabled' => 'No',
                    'Exceptions List'    => '*.local, 169.254/16'
                },
                'Service Order' => '3'
            }
        },
        'Ethernet Cards' => {
            'pci14e4,4328' => {
                'Slot'                => 'AirPort',
                'Subsystem Vendor ID' => '0x106b',
                'Link Width'          => 'x1',
                'Revision ID'         => '0x0003',
                'Device ID'           => '0x4328',
                'Kext name'           => 'AppleAirPortBrcm4311.kext',
                'BSD name'            => 'en1',
                'Version'             => '423.91.27',
                'Type'                => 'Other Network Controller',
                'Subsystem ID'        => '0x0088',
                'Bus'                 => 'PCI',
                'Location' =>
'/System/Library/Extensions/IO80211Family.kext/Contents/PlugIns/AppleAirPortBrcm4311.kext',
                'Vendor ID' => '0x14e4'
            },
            'Marvell Yukon Gigabit Adapter 88E8055 Singleport Copper SA' => {
                'Subsystem Vendor ID' => '0x11ab',
                'Link Width'          => 'x1',
                'Revision ID'         => '0x0013',
                'Device ID'           => '0x436a',
                'Kext name'           => 'AppleYukon2.kext',
                'BSD name'            => 'en0',
                'Version'             => '3.1.14b1',
                'Type'                => 'Ethernet Controller',
                'Subsystem ID'        => '0x00ba',
                'Bus'                 => 'PCI',
                'Location' =>
'/System/Library/Extensions/IONetworkingFamily.kext/Contents/PlugIns/AppleYukon2.kext',
                'Name'      => 'ethernet',
                'Vendor ID' => '0x11ab'
            }
        },
        'Hardware' => {
            'Hardware Overview' => {
                'SMC Version (system)' => '1.21f4',
                'Model Identifier'     => 'iMac7,1',
                'Boot ROM Version'     => 'IM71.007A.B03',
                'Processor Speed'      => '2,4 GHz',
                'Hardware UUID' => '00000000-0000-1000-8000-001EC20C3627',
                'Bus Speed'     => '800 MHz',
                'Total Number Of Cores'  => '2',
                'Number Of Processors'   => '1',
                'Processor Name'         => 'Intel Core 2 Duo',
                'Model Name'             => 'iMac',
                'Memory'                 => '2 GB',
                'Serial Number (system)' => 'W8805BRDX89',
                'L2 Cache'               => '4 MB'
            }
        },
        'Diagnostics' => {
            'Power On Self-Test' => {
                'Result'   => 'Passed',
                'Last Run' => '24/07/10 11:20'
            }
        },
        'Serial-ATA' => {
            'Intel ICH8-M AHCI' => {
                'WDC WD3200AAJS-40VWA0' => {
                    'Volumes' => {
                        'osx' => {
                            'Mount Point' => '/',
                            'File System' => 'Journaled HFS+',
                            'Writable'    => 'Yes',
                            'BSD Name'    => 'disk0s2',
                            'Capacity' =>
                              '216,53 GB (216 532 934 656 bytes)',
                            'Available' => '2,39 GB (2 389 823 488 bytes)'
                        },
                        'Sauvegardes' => {
                            'Mount Point' => '/Volumes/Sauvegardes',
                            'File System' => 'Journaled HFS+',
                            'Writable'    => 'Yes',
                            'BSD Name'    => 'disk0s3',
                            'Capacity' =>
                              '103,06 GB (103 061 807 104 bytes)',
                            'Available' => '1,76 GB (1 759 088 640 bytes)'
                        }
                    },
                    'Revision'         => '58.01D02',
                    'Detachable Drive' => 'No',
                    'Serial Number'    => '     WD-WMARW0629615',
                    'Capacity'        => '320,07 GB (320 072 933 376 bytes)',
                    'Model'           => 'WDC WD3200AAJS-40VWA0',
                    'Removable Media' => 'No',
                    'Medium Type'     => 'Rotational',
                    'BSD Name'        => 'disk0',
                    'S.M.A.R.T. status'      => 'Verified',
                    'Partition Map Type'     => 'GPT (GUID Partition Table)',
                    'Native Command Queuing' => 'Yes',
                    'Queue Depth'            => '32'
                },
                'Link Speed'            => '3 Gigabit',
                'Product'               => 'ICH8-M AHCI',
                'Vendor'                => 'Intel',
                'Description'           => 'AHCI Version 1.10 Supported',
                'Negotiated Link Speed' => '3 Gigabit'
            }
        },
        'Firewall' => {
            'Firewall Settings' => {
                'Services' =>
                  { 'Remote Login (SSH)' => 'Allow all connections' },
                'Applications' => {
                    'org.sip-communicator'     => 'Allow all connections',
                    'com.skype.skype'          => 'Allow all connections',
                    'com.hp.scan.app'          => 'Allow all connections',
                    'com.Growl.GrowlHelperApp' => 'Allow all connections',
                    'com.parallels.desktop.dispatcher' =>
                      'Allow all connections',
                    'net.sourceforge.xmeeting.XMeeting' =>
                      'Allow all connections',
                    'com.getdropbox.dropbox' => 'Allow all connections'
                },
                'Mode' =>
'Limit incoming connections to specific services and applications',
                'Stealth Mode'     => 'No',
                'Firewall Logging' => 'No'
            }
        },
        'Software' => {
            'System Software Overview' => {
                'Time since boot'              => '1 day1:09',
                'Computer Name'                => 'lazer',
                'Boot Volume'                  => 'osx',
                'Boot Mode'                    => 'Normal',
                'System Version'               => 'Mac OS X 10.6.4 (10F569)',
                'Kernel Version'               => 'Darwin 10.4.0',
                'Secure Virtual Memory'        => 'Enabled',
                '64-bit Kernel and Extensions' => 'No',
                'User Name'                    => 'wawa (wawa)'
            }
        },
        'FireWire' => {
            'FireWire Bus' => {
                'Maximum Speed'         => 'Up to 800 Mb/sec',
                '(1394 ATAPI,Rev 1.00)' => {
                    'Maximum Speed' => 'Up to 400 Mb/sec',
                    'Sub-units'     => {
                        '(1394 ATAPI,Rev 1.00) Unit' => {
                            'Firmware Revision' => '0x12804',
                            'Sub-units'         => {
                                '(1394 ATAPI,Rev 1.00) SBP-LUN' => {
                                    'Volumes' => {
                                        'Video' => {
                                            'Mount Point' => '/Volumes/Video',
                                            'File System' => 'Journaled HFS+',
                                            'Writable'    => 'Yes',
                                            'BSD Name'    => 'disk2s3',
                                            'Capacity' =>
'199,92 GB (199 915 397 120 bytes)',
                                            'Available' =>
'38,73 GB (38 726 303 744 bytes)'
                                        }
                                    },
                                    'BSD Name'          => 'disk2',
                                    'S.M.A.R.T. status' => 'Not Supported',
                                    'Partition Map Type' =>
                                      'APM (Apple Partition Map)',
                                    'Capacity' =>
                                      '200,05 GB (200 049 647 616 bytes)',
                                    'Removable Media' => 'Yes'
                                }
                            },
                            'Product Revision Level' => {},
                            'Unit Spec ID'           => '0x609E',
                            'Unit Software Version'  => '0x10483'
                        }
                    },
                    'Manufacturer'     => 'Prolific PL3507 Combo Device',
                    'GUID'             => '0x50770E0000043E',
                    'Model'            => '0x1',
                    'Connection Speed' => 'Up to 400 Mb/sec'
                }
            }
        },
        'Memory' => {
            'Memory Slots' => {
                'ECC'          => 'Disabled',
                'BANK 1/DIMM1' => {
                    'Part Number'   => '0x313032343633363735305320202020202020',
                    'Type'          => 'DDR2 SDRAM',
                    'Speed'         => '667 MHz',
                    'Size'          => '1 GB',
                    'Status'        => 'OK',
                    'Serial Number' => '0x00000000',
                    'Manufacturer'  => '0x0000000000000000'
                },
                'BANK 0/DIMM0' => {
                    'Part Number'   => '0x3848544631323836344844592D3636374531',
                    'Type'          => 'DDR2 SDRAM',
                    'Speed'         => '667 MHz',
                    'Size'          => '1 GB',
                    'Status'        => 'OK',
                    'Serial Number' => '0xD5289015',
                    'Manufacturer'  => '0x2C00000000000000'
                }
            }
        },
        'Printers' => {
            'Photosmart C4500 series [38705D]' => {
                'PPD'          => 'HP Photosmart C4500 series',
                'CUPS Version' => '1.4.4 (cups-218.12)',
                'URI' =>
'dnssd://Photosmart%20C4500%20series%20%5B38705D%5D._pdl-datastream._tcp.local./?bidi',
                'Default'                      => 'Yes',
                'Status'                       => 'Idle',
                'Driver Version'               => '4.1',
                'Scanner UUID'                 => '-',
                'Print Server'                 => 'Local',
                'Scanning app'                 => '-',
                'Scanning support'             => 'Yes',
                'PPD File Version'             => '4.1',
                'Scanning app (bundleID path)' => '-',
                'Fax support'                  => 'No',
                'PostScript Version'           => '(3011.104) 0'
            }
        },
        'AirPort' => {
            'Software Versions' => {
                'IO80211 Family'     => '3.1.1 (311.1)',
                'AirPort Utility'    => '5.5.1 (551.19)',
                'configd plug-in'    => '6.2.3 (623.1)',
                'Menu Extra'         => '6.2.1 (621.1)',
                'Network Preference' => '6.2.1 (621.1)',
                'System Profiler'    => '6.0 (600.9)'
            },
            'Interfaces' => {
                'en1' => {
                    'Firmware Version' => 'Broadcom BCM43xx 1.0 (5.10.91.27)',
                    'Status'           => 'Off',
                    'Locale'           => 'ETSI',
                    'Card Type'        => 'AirPort Extreme  (0x14E4, 0x88)',
                    'Supported PHY Modes' => '802.11 a/b/g/n',
                    'Supported Channels' =>
'1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 36, 40, 44, 48, 52, 56, 60, 64, 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140',
                    'Wake On Wireless' => 'Supported',
                    'Country Code'     => 'X3'
                }
            }
        },
        'Graphics/Displays' => {
            'ATI Radeon HD 2600 Pro' => {
                'Displays' => {
                    'Display Connector' =>
                      { 'Status' => 'No Display Connected' },
                    'iMac' => {
                        'Resolution'   => '1920 x 1200',
                        'Pixel Depth'  => '32-Bit Color (ARGB8888)',
                        'Main Display' => 'Yes',
                        'Mirror'       => 'Off',
                        'Built-In'     => 'Yes',
                        'Online'       => 'Yes'
                    }
                },
                'EFI Driver Version' => '01.00.219',
                'PCIe Lane Width'    => 'x16',
                'Chipset Model'      => 'ATI,RadeonHD2600',
                'Revision ID'        => '0x0000',
                'Device ID'          => '0x9583',
                'Vendor'             => 'ATI (0x1002)',
                'Type'               => 'GPU',
                'ROM Revision'       => '113-B2250F-219',
                'Bus'                => 'PCIe',
                'VRAM (Total)'       => '256 MB'
            }
        }
    },
    '10.6.6-intel' => {
        'Locations' => {
            'Automatic' => {
                'Services' => {
                    'Bluetooth DUN' => {
                        'Type'    => 'PPP',
                        'IPv6'    => { 'Configuration Method' => 'Automatic' },
                        'IPv4'    => { 'Configuration Method' => 'PPP' },
                        'Proxies' => { 'FTP Passive Mode' => 'Yes' },
                        'PPP'     => {
                            'IPCP Compression VJ'      => 'Yes',
                            'Idle Reminder'            => 'No',
                            'Idle Reminder Time'       => '1800',
                            'Disconnect on Logout'     => 'Yes',
                            'ACSP Enabled'             => 'No',
                            'Log File'                 => '/var/log/ppp.log',
                            'Redial Enabled'           => 'Yes',
                            'Verbose Logging'          => 'No',
                            'Dial on Demand'           => 'No',
                            'Redial Interval'          => '5',
                            'Use Terminal Script'      => 'No',
                            'Disconnect on Idle Timer' => '600',
                            'Disconnect on Sleep'      => 'Yes',
                            'LCP Echo Failure'         => '4',
                            'Disconnect on Idle'       => 'Yes',
                            'Disconnect on Fast User Switch' => 'Yes',
                            'LCP Echo Interval'              => '10',
                            'Redial Count'                   => '1',
                            'LCP Echo Enabled'               => 'No',
                            'Display Terminal Window'        => 'No'
                        }
                    },
                    'FireWire' => {
                        'Type' => 'FireWire',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'fw0',
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'FTP Passive Mode' => 'Yes',
                            'Exceptions List'  => '*.local, 169.254/16'
                        },
                        'Hardware (MAC) Address' => '00:1d:4f:ff:fe:66:f3:58'
                    },
                    'Ethernet' => {
                        'Type' => 'Ethernet',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'en0',
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'FTP Passive Mode' => 'Yes',
                            'Exceptions List'  => '*.local, 169.254/16'
                        },
                        'Hardware (MAC) Address' => '00:1b:63:36:1e:c3'
                    },
                    'AirPort' => {
                        'Type' => 'IEEE80211',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'en1',
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'FTP Passive Mode' => 'Yes',
                            'Exceptions List'  => '*.local, 169.254/16'
                        },
                        'Hardware (MAC) Address' => '00:1c:b3:c0:56:85',
                        'IEEE80211'              => {
                            'Join Mode'              => 'Automatic',
                            'Disconnect on Logout'   => 'Yes',
                            'PowerEnabled'           => '1',
                            'RememberRecentNetworks' => '0',
                            'RequireAdmin'           => '0',
                            'PreferredNetworks'      => {
                                'Unique Network ID' =>
                                  'A628B3F5-DB6B-48A6-A3A4-17D33697041B',
                                'SecurityType' => 'Open',
                                'SSID_STR'     => 'univ-paris1.fr'
                            },
                            'JoinModeFallback' => 'Prompt'
                        }
                    }
                },
                'Active Location' => 'No'
            },
            'universite-paris1' => {
                'Services' => {
                    'Bluetooth DUN' => {
                        'Type'    => 'PPP',
                        'IPv6'    => { 'Configuration Method' => 'Automatic' },
                        'IPv4'    => { 'Configuration Method' => 'PPP' },
                        'Proxies' => { 'FTP Passive Mode' => 'Yes' },
                        'PPP'     => {
                            'IPCP Compression VJ'      => 'Yes',
                            'Idle Reminder'            => 'No',
                            'Idle Reminder Time'       => '1800',
                            'Disconnect on Logout'     => 'Yes',
                            'ACSP Enabled'             => 'No',
                            'Log File'                 => '/var/log/ppp.log',
                            'Redial Enabled'           => 'Yes',
                            'Verbose Logging'          => 'No',
                            'Dial on Demand'           => 'No',
                            'Redial Interval'          => '5',
                            'Use Terminal Script'      => 'No',
                            'Disconnect on Idle Timer' => '600',
                            'Disconnect on Sleep'      => 'Yes',
                            'LCP Echo Failure'         => '4',
                            'Disconnect on Idle'       => 'Yes',
                            'Disconnect on Fast User Switch' => 'Yes',
                            'LCP Echo Interval'              => '10',
                            'Redial Count'                   => '1',
                            'LCP Echo Enabled'               => 'No',
                            'Display Terminal Window'        => 'No'
                        }
                    },
                    'FireWire' => {
                        'Type' => 'FireWire',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'fw0',
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'FTP Passive Mode' => 'Yes',
                            'Exceptions List'  => '*.local, 169.254/16'
                        },
                        'Hardware (MAC) Address' => '00:1d:4f:ff:fe:66:f3:58'
                    },
                    'Ethernet' => {
                        'Type' => 'Ethernet',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'en0',
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'FTP Passive Mode' => 'Yes',
                            'Exceptions List'  => '*.local, 169.254/16'
                        },
                        'Hardware (MAC) Address' => '00:1b:63:36:1e:c3'
                    },
                    'AirPort' => {
                        'Type' => 'IEEE80211',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'en1',
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'FTP Passive Mode' => 'Yes',
                            'Exceptions List'  => '*.local, 169.254/16'
                        },
                        'Hardware (MAC) Address' => '00:1c:b3:c0:56:85',
                        'IEEE80211'              => {
                            'Join Mode'              => 'Automatic',
                            'Disconnect on Logout'   => 'Yes',
                            'PowerEnabled'           => '1',
                            'RememberRecentNetworks' => '0',
                            'RequireAdmin'           => '0',
                            'PreferredNetworks'      => {
                                'Unique Network ID' =>
                                  '963478B4-1AC3-4B35-A4BB-3510FEA2FEF2',
                                'SecurityType' => 'WPA2 Enterprise',
                                'SSID_STR'     => 'eduroam'
                            },
                            'JoinModeFallback' => 'Prompt'
                        }
                    }
                },
                'Active Location' => 'No'
            },
            'eduroam' => {
                'Services' => {
                    'Bluetooth DUN' => {
                        'Type'    => 'PPP',
                        'IPv6'    => { 'Configuration Method' => 'Automatic' },
                        'IPv4'    => { 'Configuration Method' => 'PPP' },
                        'Proxies' => { 'FTP Passive Mode' => 'Yes' },
                        'PPP'     => {
                            'IPCP Compression VJ'      => 'Yes',
                            'Idle Reminder'            => 'No',
                            'Idle Reminder Time'       => '1800',
                            'Disconnect on Logout'     => 'Yes',
                            'ACSP Enabled'             => 'No',
                            'Log File'                 => '/var/log/ppp.log',
                            'Redial Enabled'           => 'Yes',
                            'Verbose Logging'          => 'No',
                            'Dial on Demand'           => 'No',
                            'Redial Interval'          => '5',
                            'Use Terminal Script'      => 'No',
                            'Disconnect on Idle Timer' => '600',
                            'Disconnect on Sleep'      => 'Yes',
                            'LCP Echo Failure'         => '4',
                            'Disconnect on Idle'       => 'Yes',
                            'Disconnect on Fast User Switch' => 'Yes',
                            'LCP Echo Interval'              => '10',
                            'Redial Count'                   => '1',
                            'LCP Echo Enabled'               => 'No',
                            'Display Terminal Window'        => 'No'
                        }
                    },
                    'FireWire' => {
                        'Type' => 'FireWire',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'fw0',
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'FTP Passive Mode' => 'Yes',
                            'Exceptions List'  => '*.local, 169.254/16'
                        },
                        'Hardware (MAC) Address' => '00:1d:4f:ff:fe:66:f3:58'
                    },
                    'Ethernet' => {
                        'Type' => 'Ethernet',
                        'IPv6' => { 'Configuration Method' => 'Automatic' },
                        'BSD Device Name' => 'en0',
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'FTP Passive Mode' => 'Yes',
                            'Exceptions List'  => '*.local, 169.254/16'
                        },
                        'Hardware (MAC) Address' => '00:1b:63:36:1e:c3'
                    },
                    'AirPort' => {
                        'Type'            => 'IEEE80211',
                        'BSD Device Name' => 'en1',
                        'AppleTalk'       => {
                            'Configuration Method' => 'Node',
                            'Node'                 => 'Node'
                        },
                        'IPv4'    => { 'Configuration Method' => 'DHCP' },
                        'Proxies' => {
                            'FTP Passive Mode' => 'Yes',
                            'Exceptions List'  => '*.local, 169.254/16'
                        },
                        'Hardware (MAC) Address' => '00:1c:b3:c0:56:85',
                        'IEEE80211'              => {
                            'Join Mode'              => 'Automatic',
                            'Disconnect on Logout'   => 'Yes',
                            'PowerEnabled'           => '0',
                            'RememberRecentNetworks' => '0',
                            'PreferredNetworks'      => {
                                'Unique Network ID' =>
                                  '46A33A68-7109-48AD-9255-900F0134903E',
                                'SecurityType' => 'WPA Personal',
                                'Unique Password ID' =>
                                  '2C0ADC06-C220-4F00-809E-C34A6085305F',
                                'SSID_STR' => 'undercover'
                            },
                            'JoinModeFallback' => 'Prompt'
                        }
                    }
                },
                'Active Location' => 'Yes'
            }
        },
        'USB' => {
            'USB Bus_1' => {
                'Host Controller Driver'        => 'AppleUSBUHCI',
                'PCI Device ID'                 => '0x27cb',
                'Bluetooth USB Host Controller' => {
                    'Location ID'            => '0x7d100000',
                    'Version'                => '19.65',
                    'Current Available (mA)' => '500',
                    'Speed'                  => 'Up to 12 Mb/sec',
                    'Product ID'             => '0x8205',
                    'Current Required (mA)'  => '0',
                    'Manufacturer'           => 'Apple Inc.',
                    'Vendor ID'              => '0x05ac  (Apple Inc.)'
                },
                'Host Controller Location' => 'Built-in USB',
                'Bus Number'               => '0x7d',
                'PCI Vendor ID'            => '0x8086',
                'PCI Revision ID'          => '0x0002'
            },
            'USB Bus' => {
                'Host Controller Driver'   => 'AppleUSBUHCI',
                'PCI Device ID'            => '0x27ca',
                'Host Controller Location' => 'Built-in USB',
                'Bus Number'               => '0x5d',
                'IR Receiver'              => {
                    'Location ID'            => '0x5d200000',
                    'Version'                => ' 1.10',
                    'Current Available (mA)' => '500',
                    'Speed'                  => 'Up to 12 Mb/sec',
                    'Product ID'             => '0x8240',
                    'Current Required (mA)'  => '100',
                    'Manufacturer'           => 'Apple Computer, Inc.',
                    'Vendor ID'              => '0x05ac  (Apple Inc.)'
                },
                'PCI Vendor ID'   => '0x8086',
                'PCI Revision ID' => '0x0002'
            },
            'USB High-Speed Bus' => {
                'Host Controller Driver'   => 'AppleUSBEHCI',
                'PCI Device ID'            => '0x27cc',
                'Host Controller Location' => 'Built-in USB',
                'Built-in iSight'          => {
                    'Location ID'            => '0xfd400000',
                    'Version'                => ' 1.89',
                    'Current Available (mA)' => '500',
                    'Speed'                  => 'Up to 480 Mb/sec',
                    'Product ID'             => '0x8501',
                    'Current Required (mA)'  => '100',
                    'Manufacturer'           => 'Micron',
                    'Vendor ID'              => '0x05ac  (Apple Inc.)'
                },
                'iPhone' => {
                    'Location ID'           => '0xfd300000',
                    'Product ID'            => '0x1297',
                    'Current Required (mA)' => '500',
                    'Serial Number' =>
                      'ad21f6125218200927797eb473d3e7eeae31e5ae',
                    'Version'                => ' 0.01',
                    'Speed'                  => 'Up to 480 Mb/sec',
                    'Current Available (mA)' => '500',
                    'Manufacturer'           => 'Apple Inc.',
                    'Vendor ID'              => '0x05ac  (Apple Inc.)'
                },
                'Bus Number'      => '0xfd',
                'PCI Revision ID' => '0x0002',
                'PCI Vendor ID'   => '0x8086'
            },
            'USB Bus_0' => {
                'Host Controller Driver'             => 'AppleUSBUHCI',
                'PCI Device ID'                      => '0x27c8',
                'Apple Internal Keyboard / Trackpad' => {
                    'Location ID'            => '0x1d200000',
                    'Version'                => ' 0.18',
                    'Current Available (mA)' => '500',
                    'Speed'                  => 'Up to 12 Mb/sec',
                    'Product ID'             => '0x021b',
                    'Current Required (mA)'  => '40',
                    'Manufacturer'           => 'Apple Computer',
                    'Vendor ID'              => '0x05ac  (Apple Inc.)'
                },
                'Host Controller Location' => 'Built-in USB',
                'Bus Number'               => '0x1d',
                'PCI Vendor ID'            => '0x8086',
                'PCI Revision ID'          => '0x0002'
            },
            'USB Bus_2' => {
                'Host Controller Driver'   => 'AppleUSBUHCI',
                'PCI Device ID'            => '0x27c9',
                'Host Controller Location' => 'Built-in USB',
                'Bus Number'               => '0x3d',
                'PCI Vendor ID'            => '0x8086',
                'PCI Revision ID'          => '0x0002'
            }
        },
        'ATA' => {
            'ATA Bus' => {
                'MATSHITACD-RW  CW-8221' => {
                    'Low Power Polling' => 'Yes',
                    'Revision'          => 'GA0J',
                    'Detachable Drive'  => 'No',
                    'Serial Number'     => undef,
                    'Power Off'         => 'Yes',
                    'Model'             => 'MATSHITACD-RW  CW-8221',
                    'Socket Type'       => 'Internal',
                    'Protocol'          => 'ATAPI',
                    'Unit Number'       => '0'
                }
            }
        },
        'Audio (Built In)' => {
            'Intel High Definition Audio' => {
                'Speaker' => { 'Connection' => 'Internal' },
                'S/PDIF Optical Digital Audio Input' =>
                  { 'Connection' => 'Combination Input' },
                'Headphone' => { 'Connection' => 'Combination Output' },
                'Internal Microphone' => { 'Connection' => 'Internal' },
                'Line Input' => { 'Connection' => 'Combination Input' },
                'Audio ID'   => '34',
                'S/PDIF Optical Digital Audio Output' =>
                  { 'Connection' => 'Combination Output' }
            }
        },
        'Disc Burning' => {
            'MATSHITA CD-RW  CW-8221' => {
                'Reads DVD'        => 'Yes',
                'Cache'            => '2048 KB',
                'Write Strategies' => 'CD-TAO, CD-SAO, CD-Raw',
                'Media' =>
'To show the available burn speeds, insert a disc and choose View > Refresh',
                'Interconnect'      => 'ATAPI',
                'Burn Support'      => 'Yes (Apple Shipping Drive)',
                'CD-Write'          => '-R, -RW',
                'Firmware Revision' => 'GA0J'
            }
        },
        'Bluetooth' => {
            'Apple Bluetooth Software Version' => '2.3.8f7',
            'Outgoing Serial Ports'            => {
                'Serial Port 1' => {
                    'Address'                 => undef,
                    'Requires Authentication' => 'No',
                    'RFCOMM Channel'          => '0',
                    'Name'                    => 'Bluetooth-Modem'
                }
            },
            'Services' => {
                'Bluetooth File Transfer' => {
                    'Folder other devices can browse' => '~/Public',
                    'Requires Authentication'         => 'Yes',
                    'State'                           => 'Enabled'
                },
                'Bluetooth File Exchange' => {
                    'When receiving items'          => 'Prompt for each file',
                    'Folder for accepted items'     => '~/Downloads',
                    'When PIM items are accepted'   => 'Ask',
                    'Requires Authentication'       => 'No',
                    'State'                         => 'Enabled',
                    'When other items are accepted' => 'Ask'
                }
            },
            'Hardware Settings' => {
                'Firmware Version'        => '1965',
                'Product ID'              => '0x8205',
                'Bluetooth Power'         => 'On',
                'Address'                 => '00-1d-4f-8f-13-b1',
                'Requires Authentication' => 'No',
                'Discoverable'            => 'Yes',
                'Manufacturer'            => 'Cambridge Silicon Radio',
                'Vendor ID'               => '0x5ac',
                'Name'                    => 'MacBookdeSAP'
            },
            'Incoming Serial Ports' => {
                'Serial Port 1' => {
                    'Requires Authentication' => 'No',
                    'RFCOMM Channel'          => '3',
                    'Name'                    => 'Bluetooth-PDA-Sync'
                }
            }
        },
        'Power' => {
            'Hardware Configuration' => { 'UPS Installed' => 'No' },
            'Battery Information'    => {
                'Charge Information' => {
                    'Full charge capacity (mAh)' => '0',
                    'Fully charged'              => 'No',
                    'Charging'                   => 'No',
                    'Charge remaining (mAh)'     => '0'
                },
                'Health Information' => {
                    'Cycle count' => '5',
                    'Condition'   => 'Replace Now'
                },
                'Voltage (mV)'      => '3908',
                'Model Information' => {
                    'PCB Lot Code'      => '0000',
                    'Firmware Version'  => '102a',
                    'Device name'       => 'ASMB016',
                    'Hardware Revision' => '0500',
                    'Cell Revision'     => '0102',
                    'Manufacturer'      => 'DP',
                    'Pack Lot Code'     => '0002'
                },
                'Battery Installed' => 'Yes',
                'Amperage (mA)'     => '74'
            },
            'System Power Settings' => {
                'AC Power' => {
                    'Wake On Clamshell Open'          => 'Yes',
                    'Disk Sleep Timer (Minutes)'      => '10',
                    'Display Sleep Timer (Minutes)'   => '10',
                    'Automatic Restart On Power Loss' => 'No',
                    'System Sleep Timer (Minutes)'    => '0',
                    'Wake On AC Change'               => 'No',
                    'Current Power Source'            => 'Yes',
                    'Display Sleep Uses Dim'          => 'Yes',
                    'Wake On LAN'                     => 'Yes'
                },
                'Battery Power' => {
                    'Reduce Brightness'             => 'Yes',
                    'Display Sleep Timer (Minutes)' => '5',
                    'Disk Sleep Timer (Minutes)'    => '5',
                    'System Sleep Timer (Minutes)'  => '5',
                    'Wake On AC Change'             => 'No',
                    'Wake On Clamshell Open'        => 'Yes',
                    'Display Sleep Uses Dim'        => 'Yes'
                }
            },
            'AC Charger Information' => {
                'ID'            => '0x0100',
                'Charging'      => 'No',
                'Revision'      => '0x0000',
                'Connected'     => 'Yes',
                'Serial Number' => '0x005a4e88',
                'Family'        => '0x00ba',
                'Wattage (W)'   => '60'
            }
        },
        'Universal Access' => {
            'Universal Access Information' => {
                'Zoom'                 => 'Off',
                'Display'              => 'Black on White',
                'Slow Keys'            => 'Off',
                'Flash Screen'         => 'Off',
                'Mouse Keys'           => 'Off',
                'Sticky Keys'          => 'Off',
                'VoiceOver'            => 'Off',
                'Cursor Magnification' => 'Off'
            }
        },
        'Volumes' => {
            'home' => {
                'Mounted From' => 'map auto_home',
                'Mount Point'  => '/home',
                'Type'         => 'autofs',
                'Automounted'  => 'Yes'
            },
            'net' => {
                'Mounted From' => 'map -hosts',
                'Mount Point'  => '/net',
                'Type'         => 'autofs',
                'Automounted'  => 'Yes'
            }
        },
        'Network' => {
            'FireWire' => {
                'Has IP Assigned' => 'No',
                'Type'            => 'FireWire',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'fw0',
                'Ethernet'        => {
                    'Media Subtype' => 'Auto Select',
                    'MAC Address'   => '00:1d:4f:ff:fe:66:f3:58',
                    'Media Options' => 'Full Duplex'
                },
                'IPv4'     => { 'Configuration Method' => 'DHCP' },
                'Hardware' => 'FireWire',
                'Proxies'  => {
                    'FTP Passive Mode' => 'Yes',
                    'Exceptions List'  => '*.local, 169.254/16'
                },
                'Service Order' => '2'
            },
            'Ethernet' => {
                'Has IP Assigned' => 'Yes',
                'IPv6 Address'    => '2001:0660:3305:0100:021b:63ff:fe36:1ec3',
                'IPv6'            => {
                    'Router' => 'fe80:0000:0000:0000:020b:60ff:feb0:b01b',
                    'Prefix Length'        => '64',
                    'Interface Name'       => 'en0',
                    'Flags'                => '32832',
                    'Configuration Method' => 'Automatic',
                    'Addresses' => '2001:0660:3305:0100:021b:63ff:fe36:1ec3'
                },
                'BSD Device Name' => 'en0',
                'Ethernet'        => {
                    'Media Subtype' => '100baseTX',
                    'MAC Address'   => '00:1b:63:36:1e:c3',
                    'Media Options' => 'Full Duplex, Flow Control'
                },
                'Hardware'      => 'Ethernet',
                'Service Order' => '1',
                'DNS'           => {
                    'Server Addresses' =>
                      '193.55.96.84, 193.55.99.70, 194.214.33.181',
                    'Domain Name' => 'univ-paris1.fr'
                },
                'Type'                  => 'Ethernet',
                'IPv4 Addresses'        => '172.20.10.171',
                'DHCP Server Responses' => {
                    'Routers'                  => '172.20.10.72',
                    'Domain Name'              => 'univ-paris1.fr',
                    'Subnet Mask'              => '255.255.254.0',
                    'Server Identifier'        => '172.20.0.2',
                    'DHCP Message Type'        => '0x05',
                    'Lease Duration (seconds)' => '0',
                    'Domain Name Servers' =>
                      '193.55.96.84,193.55.99.70,194.214.33.181'
                },
                'IPv4' => {
                    'Router'         => '172.20.10.72',
                    'Interface Name' => 'en0',
                    'Network Signature' =>
'IPv4.Router=172.20.10.72;IPv4.RouterHardwareAddress=00:0b:60:b0:b0:1b',
                    'Configuration Method' => 'DHCP',
                    'Subnet Masks'         => '255.255.254.0',
                    'Addresses'            => '172.20.10.171'
                },
                'Proxies' => {
                    'FTP Passive Mode' => 'Yes',
                    'Exceptions List'  => '*.local, 169.254/16'
                },
                'Sleep Proxies' => {
                    'MacBook de SAP ' => {
                        'Portability'    => '37',
                        'Type'           => '50',
                        'Metric'         => '503771',
                        'Marginal Power' => '71',
                        'Total Power'    => '72'
                    }
                }
            },
            'Bluetooth' => {
                'Has IP Assigned' => 'No',
                'Type'            => 'PPP (PPPSerial)',
                'IPv6'            => { 'Configuration Method' => 'Automatic' },
                'BSD Device Name' => 'Bluetooth-Modem',
                'IPv4'            => { 'Configuration Method' => 'PPP' },
                'Hardware'        => 'Modem',
                'Proxies'         => { 'FTP Passive Mode' => 'Yes' },
                'Service Order'   => '0'
            },
            'AirPort' => {
                'Has IP Assigned' => 'No',
                'Type'            => 'AirPort',
                'BSD Device Name' => 'en1',
                'Ethernet'        => {
                    'Media Subtype' => 'Auto Select',
                    'MAC Address'   => '00:1c:b3:c0:56:85',
                    'Media Options' => undef
                },
                'IPv4'     => { 'Configuration Method' => 'DHCP' },
                'Hardware' => 'AirPort',
                'Proxies'  => {
                    'FTP Passive Mode' => 'Yes',
                    'Exceptions List'  => '*.local, 169.254/16'
                },
                'Service Order' => '3'
            }
        },
        'Ethernet Cards' => {
            'Marvell Yukon Gigabit Adapter 88E8053 Singleport Copper SA' => {
                'Subsystem Vendor ID' => '0x11ab',
                'Link Width'          => 'x1',
                'Revision ID'         => '0x0022',
                'Device ID'           => '0x4362',
                'Kext name'           => 'AppleYukon2.kext',
                'BSD name'            => 'en0',
                'Version'             => '3.2.1b1',
                'Type'                => 'Ethernet Controller',
                'Subsystem ID'        => '0x5321',
                'Bus'                 => 'PCI',
                'Location' =>
'/System/Library/Extensions/IONetworkingFamily.kext/Contents/PlugIns/AppleYukon2.kext',
                'Name'      => 'ethernet',
                'Vendor ID' => '0x11ab'
            }
        },
        'Hardware' => {
            'Hardware Overview' => {
                'SMC Version (system)' => '1.17f0',
                'Model Identifier'     => 'MacBook2,1',
                'Boot ROM Version'     => 'MB21.00A5.B07',
                'Processor Speed'      => '2 GHz',
                'Hardware UUID' => '00000000-0000-1000-8000-001B66661EC3',
                'Sudden Motion Sensor'   => { 'State' => 'Enabled' },
                'Bus Speed'              => '667 MHz',
                'Total Number Of Cores'  => '2',
                'Number Of Processors'   => '1',
                'Processor Name'         => 'Intel Core 2 Duo',
                'Model Name'             => 'MacBook',
                'Memory'                 => '1 GB',
                'Serial Number (system)' => 'W8737DR1Z5V',
                'L2 Cache'               => '4 MB'
            }
        },
        'Diagnostics' => {
            'Power On Self-Test' => {
                'Result'   => 'Passed',
                'Last Run' => '1/13/11 9:43 AM'
            }
        },
        'Serial-ATA' => {
            'Intel ICH7-M AHCI' => {
                'FUJITSU MHW2080BHPL' => {
                    'Volumes' => {
                        'Writable'     => 'Yes',
                        'Macintosh HD' => {
                            'Mount Point' => '/',
                            'File System' => 'Journaled HFS+',
                            'Writable'    => 'Yes',
                            'BSD Name'    => 'disk0s2',
                            'Capacity'    => '79.68 GB (79,682,387,968 bytes)',
                            'Available'   => '45.62 GB (45,623,767,040 bytes)'
                        },
                        'BSD Name' => 'disk0s1',
                        'Capacity' => '209.7 MB (209,715,200 bytes)'
                    },
                    'Revision'           => '0081001C',
                    'Detachable Drive'   => 'No',
                    'Serial Number'      => '        K10RT792D51G',
                    'Capacity'           => '80.03 GB (80,026,361,856 bytes)',
                    'Model'              => 'FUJITSU MHW2080BHPL',
                    'Removable Media'    => 'No',
                    'Medium Type'        => 'Rotational',
                    'BSD Name'           => 'disk0',
                    'S.M.A.R.T. status'  => 'Verified',
                    'Partition Map Type' => 'GPT (GUID Partition Table)',
                    'Native Command Queuing' => 'Yes',
                    'Queue Depth'            => '32'
                },
                'Link Speed'            => '1.5 Gigabit',
                'Product'               => 'ICH7-M AHCI',
                'Vendor'                => 'Intel',
                'Description'           => 'AHCI Version 1.10 Supported',
                'Negotiated Link Speed' => '1.5 Gigabit'
            }
        },
        'Firewall' => {
            'Firewall Settings' => {
                'Mode'             => 'Allow all incoming connections',
                'Stealth Mode'     => 'No',
                'Firewall Logging' => 'No'
            }
        },
        'Software' => {
            'System Software Overview' => {
                'Time since boot'              => '2:37',
                'Computer Name'                => 'MacBook de SAP',
                'Boot Volume'                  => 'Macintosh HD',
                'Boot Mode'                    => 'Normal',
                'System Version'               => 'Mac OS X 10.6.6 (10J567)',
                'Kernel Version'               => 'Darwin 10.6.0',
                'Secure Virtual Memory'        => 'Enabled',
                '64-bit Kernel and Extensions' => 'No',
                'User Name'                    => 'System Administrator (root)'
            }
        },
        'FireWire' =>
          { 'FireWire Bus' => { 'Maximum Speed' => 'Up to 400 Mb/sec' } },
        'Memory' => {
            'Memory Slots' => {
                'ECC'          => 'Disabled',
                'BANK 1/DIMM1' => {
                    'Part Number'   => '0x48594D503536345336344350362D59352020',
                    'Type'          => 'DDR2 SDRAM',
                    'Speed'         => '667 MHz',
                    'Size'          => '512 MB',
                    'Status'        => 'OK',
                    'Serial Number' => '0x00006021',
                    'Manufacturer'  => '0xAD00000000000000'
                },
                'BANK 0/DIMM0' => {
                    'Part Number'   => '0x48594D503536345336344350362D59352020',
                    'Type'          => 'DDR2 SDRAM',
                    'Speed'         => '667 MHz',
                    'Size'          => '512 MB',
                    'Status'        => 'OK',
                    'Serial Number' => '0x00003026',
                    'Manufacturer'  => '0xAD00000000000000'
                }
            }
        },
        'Printers' => {
            '192.168.5.97' => {
                'PPD'                          => 'HP LaserJet 2200',
                'CUPS Version'                 => '1.4.6 (cups-218.28)',
                'URI'                          => 'socket://192.168.5.97/?bidi',
                'Default'                      => 'No',
                'Status'                       => 'Idle',
                'Driver Version'               => '10.4',
                'Scanner UUID'                 => '-',
                'Print Server'                 => 'Local',
                'Scanning app'                 => '-',
                'Scanning support'             => 'No',
                'PPD File Version'             => '17.3',
                'Scanning app (bundleID path)' => '-',
                'Fax support'                  => 'No',
                'PostScript Version'           => '(2014.116) 0'
            },
            '192.168.5.63' => {
                'PPD'                          => 'Generic PostScript Printer',
                'CUPS Version'                 => '1.4.6 (cups-218.28)',
                'URI'                          => 'lpd://192.168.5.63/',
                'Default'                      => 'No',
                'Status'                       => 'Idle',
                'Driver Version'               => '10.4',
                'Scanner UUID'                 => '-',
                'Print Server'                 => 'Local',
                'Scanning app'                 => '-',
                'Scanning support'             => 'No',
                'PPD File Version'             => '1.4',
                'Scanning app (bundleID path)' => '-',
                'Fax support'                  => 'No',
                'PostScript Version'           => '(2016.0) 0'
            }
        },
        'AirPort' => {
            'Software Versions' => {
                'IO80211 Family'     => '3.1.2 (312)',
                'AirPort Utility'    => '5.5.2 (552.11)',
                'configd plug-in'    => '6.2.3 (623.2)',
                'Menu Extra'         => '6.2.1 (621.1)',
                'Network Preference' => '6.2.1 (621.1)',
                'System Profiler'    => '6.0 (600.9)'
            },
            'Interfaces' => {
                'en1' => {
                    'Supported PHY Modes' => '802.11 a/b/g/n',
                    'Firmware Version'    => 'Atheros 5416: 2.1.14.5',
                    'Status'              => 'Off',
                    'Supported Channels' =>
'1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 36, 40, 44, 48, 52, 56, 60, 64, 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140',
                    'Locale'       => 'ETSI',
                    'Card Type'    => 'AirPort Extreme  (0x168C, 0x87)',
                    'Country Code' => undef
                }
            }
        },
        'Graphics/Displays' => {
            'Intel GMA 950' => {
                'Type'     => 'GPU',
                'Displays' => {
                    'Display Connector' =>
                      { 'Status' => 'No Display Connected' },
                    'Color LCD' => {
                        'Resolution'   => '1280 x 800',
                        'Pixel Depth'  => '32-Bit Color (ARGB8888)',
                        'Main Display' => 'Yes',
                        'Mirror'       => 'Off',
                        'Built-In'     => 'Yes',
                        'Online'       => 'Yes'
                    }
                },
                'Chipset Model' => 'GMA 950',
                'Bus'           => 'Built-In',
                'Revision ID'   => '0x0003',
                'Device ID'     => '0x27a2',
                'Vendor'        => 'Intel (0x8086)',
                'VRAM (Total)'  => '64 MB of Shared System Memory'
            }
        }
      }

);

my @ioreg_tests = (
    {
        file    => 'IOUSBDevice1',
        class   => 'IOUSBDevice',
        results => [
            {
                'IOGeneralInterest'   => 'IOCommand is not serializable',
                'USB Address'         => '2',
                'Requested Power'     => '20',
                'idProduct'           => '539',
                'bMaxPacketSize0'     => '8',
                'USB Vendor Name'     => 'Apple Computer',
                'sessionID'           => '922879256',
                'bNumConfigurations'  => '1',
                'bDeviceProtocol'     => '0',
                'Bus Power Available' => '250',
                'Device Speed'        => '1',
                'USB Product Name'    => 'Apple Internal Keyboard / Trackpad',
                'iProduct'            => '2',
                'IOUserClientClass'   => 'IOUSBDeviceUserClientV2',
                'non-removable'       => 'yes',
                'bDeviceClass'        => '0',
                'bDeviceSubClass'     => '0',
                'PortNum'             => '2',
                'bcdDevice'           => '24',
                'locationID'          => '488636416',
                'iManufacturer'       => '1',
                'iSerialNumber'       => '0',
                'idVendor'            => '1452'
            },
            {
                'IOGeneralInterest'   => 'IOCommand is not serializable',
                'USB Address'         => '2',
                'Requested Power'     => '50',
                'idProduct'           => '33344',
                'bMaxPacketSize0'     => '8',
                'USB Vendor Name'     => 'Apple Computer, Inc.',
                'sessionID'           => '944991920',
                'bNumConfigurations'  => '1',
                'bDeviceProtocol'     => '0',
                'Bus Power Available' => '250',
                'Device Speed'        => '1',
                'USB Product Name'    => 'IR Receiver',
                'iProduct'            => '2',
                'IOUserClientClass'   => 'IOUSBDeviceUserClientV2',
                'non-removable'       => 'yes',
                'bDeviceClass'        => '0',
                'bDeviceSubClass'     => '0',
                'PortNum'             => '2',
                'bcdDevice'           => '272',
                'locationID'          => '1562378240',
                'iManufacturer'       => '1',
                'iSerialNumber'       => '0',
                'idVendor'            => '1452'
            },
            {
                'IOGeneralInterest'   => 'IOCommand is not serializable',
                'USB Address'         => '2',
                'Requested Power'     => '0',
                'idProduct'           => '33285',
                'bMaxPacketSize0'     => '64',
                'USB Vendor Name'     => 'Apple Inc.',
                'sessionID'           => '3290864968',
                'bNumConfigurations'  => '1',
                'bDeviceProtocol'     => '1',
                'Bus Power Available' => '250',
                'Device Speed'        => '1',
                'iProduct'            => '0',
                'IOUserClientClass'   => 'IOUSBDeviceUserClientV2',
                'USB Product Name'    => 'Bluetooth USB Host Controller',
                'PortNum'             => '1',
                'bDeviceClass'        => '224',
                'bDeviceSubClass'     => '1',
                'non-removable'       => 'yes',
                'bcdDevice'           => '6501',
                'locationID'          => '2098200576',
                'iManufacturer'       => '0',
                'iSerialNumber'       => '0',
                'idVendor'            => '1452'
            },
            {
                'IOGeneralInterest'   => 'IOCommand is not serializable',
                'USB Address'         => '2',
                'Requested Power'     => '50',
                'idProduct'           => '34049',
                'bMaxPacketSize0'     => '64',
                'USB Vendor Name'     => 'Micron',
                'sessionID'           => '2717373407',
                'bNumConfigurations'  => '1',
                'bDeviceProtocol'     => '255',
                'Bus Power Available' => '250',
                'Device Speed'        => '2',
                'USB Product Name'    => 'Built-in iSight',
                'iProduct'            => '2',
                'IOUserClientClass'   => 'IOUSBDeviceUserClientV2',
                'non-removable'       => 'yes',
                'bDeviceClass'        => '255',
                'bDeviceSubClass'     => '255',
                'PortNum'             => '4',
                'bcdDevice'           => '393',
                'locationID'          => '18446744073663414272',
                'iManufacturer'       => '1',
                'iSerialNumber'       => '0',
                'idVendor'            => '1452'
            },
            {
                'IOGeneralInterest'   => 'IOCommand is not serializable',
                'USB Address'         => '3',
                'Requested Power'     => '50',
                'idProduct'           => '24613',
                'bMaxPacketSize0'     => '64',
                'USB Vendor Name'     => 'CBM',
                'sessionID'           => '3995793432240',
                'bNumConfigurations'  => '1',
                'bDeviceProtocol'     => '0',
                'Bus Power Available' => '250',
                'uid'                 => 'USB:197660250078C5C90000',
                'Device Speed'        => '2',
                'USB Product Name'    => 'Flash Disk',
                'iProduct'            => '2',
                'IOUserClientClass'   => 'IOUSBDeviceUserClientV2',
                'bDeviceClass'        => '0',
                'bDeviceSubClass'     => '0',
                'PortNum'             => '3',
                'bcdDevice'           => '256',
                'locationID'          => '18446744073662365696',
                'iManufacturer'       => '1',
                'iSerialNumber'       => '3',
                'idVendor'            => '6518',
                'USB Serial Number'   => '16270078C5C90000'
            }
        ],
    },
    {
        file    => 'IOUSBDevice2',
        class   => 'IOUSBDevice',
        results => [
            {
                'IOGeneralInterest'   => 'IOCommand is not serializable',
                'USB Address'         => '3',
                'Requested Power'     => '50',
                'idProduct'           => '54',
                'bMaxPacketSize0'     => '8',
                'USB Vendor Name'     => 'Genius',
                'sessionID'           => '1035836159',
                'bNumConfigurations'  => '1',
                'bDeviceProtocol'     => '0',
                'Bus Power Available' => '250',
                'Device Speed'        => '0',
                'USB Product Name'    => 'NetScroll + Mini Traveler',
                'iProduct'            => '1',
                'IOUserClientClass'   => 'IOUSBDeviceUserClientV2',
                'bDeviceClass'        => '0',
                'bDeviceSubClass'     => '0',
                'PortNum'             => '2',
                'bcdDevice'           => '272',
                'locationID'          => '438304768',
                'iManufacturer'       => '2',
                'iSerialNumber'       => '0',
                'idVendor'            => '1112'
            },
            {
                'IOGeneralInterest'   => 'IOCommand is not serializable',
                'USB Address'         => '2',
                'Requested Power'     => '0',
                'idProduct'           => '33286',
                'bMaxPacketSize0'     => '64',
                'USB Vendor Name'     => 'Apple Inc.',
                'sessionID'           => '3009829809',
                'bNumConfigurations'  => '1',
                'bDeviceProtocol'     => '1',
                'Bus Power Available' => '250',
                'Device Speed'        => '1',
                'iProduct'            => '0',
                'IOUserClientClass'   => 'IOUSBDeviceUserClientV2',
                'USB Product Name'    => 'Bluetooth USB Host Controller',
                'PortNum'             => '1',
                'bDeviceClass'        => '224',
                'bDeviceSubClass'     => '1',
                'non-removable'       => 'yes',
                'bcdDevice'           => '6501',
                'locationID'          => '437256192',
                'iManufacturer'       => '0',
                'iSerialNumber'       => '0',
                'idVendor'            => '1452'
            },
            {
                'IOGeneralInterest'   => 'IOCommand is not serializable',
                'USB Address'         => '3',
                'Requested Power'     => '10',
                'idProduct'           => '545',
                'bMaxPacketSize0'     => '8',
                'USB Vendor Name'     => 'Apple, Inc',
                'sessionID'           => '1018522533',
                'bNumConfigurations'  => '1',
                'bDeviceProtocol'     => '0',
                'Bus Power Available' => '50',
                'Device Speed'        => '0',
                'USB Product Name'    => 'Apple Keyboard',
                'iProduct'            => '2',
                'IOUserClientClass'   => 'IOUSBDeviceUserClientV2',
                'non-removable'       => 'yes',
                'bDeviceClass'        => '0',
                'bDeviceSubClass'     => '0',
                'PortNum'             => '2',
                'bcdDevice'           => '105',
                'locationID'          => '18446744073613213696',
                'iManufacturer'       => '1',
                'iSerialNumber'       => '0',
                'idVendor'            => '1452'
            },
            {
                'IOGeneralInterest'   => 'IOCommand is not serializable',
                'USB Address'         => '2',
                'Requested Power'     => '50',
                'idProduct'           => '33346',
                'bMaxPacketSize0'     => '8',
                'USB Vendor Name'     => 'Apple Computer, Inc.',
                'sessionID'           => '1116620200',
                'bNumConfigurations'  => '1',
                'bDeviceProtocol'     => '0',
                'Bus Power Available' => '250',
                'Device Speed'        => '0',
                'USB Product Name'    => 'IR Receiver',
                'iProduct'            => '2',
                'IOUserClientClass'   => 'IOUSBDeviceUserClientV2',
                'non-removable'       => 'yes',
                'bDeviceClass'        => '0',
                'bDeviceSubClass'     => '0',
                'PortNum'             => '1',
                'bcdDevice'           => '22',
                'locationID'          => '1561329664',
                'iManufacturer'       => '1',
                'iSerialNumber'       => '0',
                'idVendor'            => '1452'
            },
            {
                'IOGeneralInterest'   => 'IOCommand is not serializable',
                'USB Address'         => '2',
                'Requested Power'     => '1',
                'idProduct'           => '4138',
                'bMaxPacketSize0'     => '64',
                'USB Vendor Name'     => 'LaCie',
                'sessionID'           => '637721320',
                'bNumConfigurations'  => '1',
                'bDeviceProtocol'     => '0',
                'Bus Power Available' => '250',
                'uid'                 => 'USB:059F102A6E7A5FFFFFFF',
                'Device Speed'        => '2',
                'USB Product Name'    => 'LaCie Device',
                'iProduct'            => '11',
                'IOUserClientClass'   => 'IOUSBDeviceUserClientV2',
                'bDeviceClass'        => '0',
                'bDeviceSubClass'     => '0',
                'PortNum'             => '1',
                'bcdDevice'           => '256',
                'locationID'          => '18446744073660268544',
                'iManufacturer'       => '10',
                'iSerialNumber'       => '5',
                'idVendor'            => '1439',
                'USB Serial Number'   => '6E7A5FFFFFFF'
            },
            {
                'IOGeneralInterest'   => 'IOCommand is not serializable',
                'USB Address'         => '3',
                'Requested Power'     => '250',
                'idProduct'           => '34050',
                'bMaxPacketSize0'     => '64',
                'USB Vendor Name'     => 'Apple Inc.',
                'sessionID'           => '791376929',
                'bNumConfigurations'  => '1',
                'bDeviceProtocol'     => '1',
                'Bus Power Available' => '250',
                'Device Speed'        => '2',
                'USB Product Name'    => 'Built-in iSight',
                'iProduct'            => '2',
                'IOUserClientClass'   => 'IOUSBDeviceUserClientV2',
                'non-removable'       => 'yes',
                'bDeviceClass'        => '239',
                'bDeviceSubClass'     => '2',
                'PortNum'             => '4',
                'bcdDevice'           => '341',
                'locationID'          => '18446744073663414272',
                'iManufacturer'       => '1',
                'iSerialNumber'       => '3',
                'idVendor'            => '1452',
                'USB Serial Number'   => '6067E773DA9722F4 (03.01)'
            }
        ]
    },
    {
        file    => 'IOPlatformExpertDevice',
        class   => 'IOPlatformExpertDevice',
        results => [
            {
                'IOPlatformUUID' => '00000000-0000-1000-8000-001B633026B1',
                'IOBusyInterest' => 'IOCommand is not serializable',
                'IOPlatformSerialNumber' => 'W87305UMYA8',
                'IOPolledInterface' => 'SMCPolledInterface is not serializable',
                'compatible'        => 'MacBook2,1',
                'model'             => 'MacBook2,1',
                'serial-number' => '59413800000000000000000000573837333035554d59413800000000000000000000000000000000000000',
                'version'       => '1.0',
                'name'          => '/',
                'board-id'      => 'Mac-F4208CAA',
                'clock-frequency' => '00d69327',
                'system-type'     => '02',
                'manufacturer'    => 'Apple Inc.',
                'product-name'    => 'MacBook2,1',
                'IOPlatformArgs'  => '0030aa0100c0a901906aaf0100000000'
            }
        ],
    }
);

my %xmlparsing = (
    "10.8-system_profiler" => {
        flatfile => "10.8-system_profiler_SPApplicationsDataType.example.txt",
        xmlfile  => "10.8-system_profiler_SPApplicationsDataType_-xml.example.xml",
        list => {
          '50onPaletteServer' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '30/06/2009',
            Location => '/System/Library/Input Methods/50onPaletteServer.app',
            Version => '1.0.3'
          },
          ARDAgent => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '22/05/2009',
            Location => '/System/Library/CoreServices/RemoteManagement/ARDAgent.app',
            Version => '3.5.4'
          },
          'ARM Help' => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '08/07/2009',
            Location => '/Library/Application Support/Shark/Helpers/ARM Help.app',
            Version => '4.7.1'
          },
          'AU Lab' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "2.1 \x{a9}2009, Apple, Inc",
            Kind => 'Intel',
            'Last Modified' => '25/06/2009',
            Location => '/Developer/Applications/Audio/AU Lab.app',
            Version => '2.1'
          },
          AVRCPAgent => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '2.4.5, Copyright (c) 2011 Apple Inc. All rights reserved.',
            Kind => 'Universal',
            'Last Modified' => '01/08/2009',
            Location => '/System/Library/CoreServices/AVRCPAgent.app',
            Version => '2.4.5'
          },
          'About Xcode' => {
            '64-Bit (Intel)' => 'No',
            'Get Info String' => 'About Xcode',
            Kind => 'Universal',
            'Last Modified' => '26/06/2009',
            Location => '/Developer/About Xcode.app',
            Version => '159'
          },
          'Accessibility Inspector' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'Accessibility Inspector 2.0, Copyright 2002-2009 Apple Inc.',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Utilities/Accessibility Tools/Accessibility Inspector.app',
            Version => '2.0'
          },
          'Accessibility Verifier' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Utilities/Accessibility Tools/Accessibility Verifier.app',
            Version => '1.2'
          },
          AddPrinter => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '24/07/2009',
            Location => '/System/Library/CoreServices/AddPrinter.app',
            Version => '6.6'
          },
          AddressBookManager => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '25/07/2009',
            Location => '/System/Library/Frameworks/AddressBook.framework/Versions/A/Resources/AddressBookManager.app',
            Version => '2.0.4'
          },
          AddressBookSync => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '25/07/2009',
            Location => '/System/Library/Frameworks/AddressBook.framework/Versions/A/Resources/AddressBookSync.app',
            Version => '2.0.4'
          },
          "Agent de la borne d\x{2019}acc\x{e8}s AirPort" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "1.5.4 (154.2), Copyright \x{a9} 2006-2009 Apple Inc. All Rights Reserved.",
            Kind => 'Intel',
            'Last Modified' => '11/06/2009',
            Location => '/System/Library/CoreServices/AirPort Base Station Agent.app',
            Version => '1.5.4'
          },
          "Aide-m\x{e9}moire" => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Applications/Stickies.app',
            Version => '7.0'
          },
          "Aper\x{e7}u" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '5.0.1, Copyright 2002-2009 Apple Inc.',
            Kind => 'Intel',
            'Last Modified' => '15/07/2009',
            Location => '/Applications/Preview.app',
            Version => '5.0.3'
          },
          'App Store' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/Applications/App Store.app',
            Version => '1.0.2'
          },
          Apple80211Agent => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.2.2, Copyright \x{a9} 2000\x{2013}2009 Apple Inc. All rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '21/07/2009',
            Location => '/System/Library/CoreServices/Apple80211Agent.app',
            Version => '6.2.2'
          },
          AppleFileServer => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/CoreServices/AppleFileServer.app'
          },
          AppleGraphicsWarning => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'Version 2.0.3, Copyright Apple Inc., 2008',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/AppleGraphicsWarning.app',
            Version => '2.0.3'
          },
          AppleMobileDeviceHelper => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/PrivateFrameworks/MobileDevice.framework/Versions/A/AppleMobileDeviceHelper.app',
            Version => '5.0'
          },
          AppleMobileSync => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/PrivateFrameworks/MobileDevice.framework/Versions/A/AppleMobileSync.app',
            Version => '5.0'
          },
          'AppleScript Runner' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/AppleScript Runner.app',
            Version => '1.0.2'
          },
          'Assistant Boot Camp' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "Boot Camp Assistant 3.0.4, Copyright \x{a9} 2010 Apple Inc. All rights reserved",
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Applications/Utilities/Boot Camp Assistant.app',
            Version => '3.0.4'
          },
          'Assistant de certification' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '02/07/2009',
            Location => '/System/Library/CoreServices/Certificate Assistant.app',
            Version => '3.0'
          },
          'Assistant migration' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/Applications/Utilities/Migration Assistant.app',
            Version => '3.0.4'
          },
          "Assistant r\x{e9}glages" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '10.6',
            Kind => 'Universal',
            'Last Modified' => '31/07/2009',
            Location => '/System/Library/CoreServices/Setup Assistant.app',
            Version => '10.6'
          },
          "Assistant r\x{e9}glages Bluetooth" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '2.4.5, Copyright (c) 2011 Apple Inc. All rights reserved.',
            Kind => 'Universal',
            'Last Modified' => '01/08/2009',
            Location => '/System/Library/CoreServices/Bluetooth Setup Assistant.app',
            Version => '2.4.5'
          },
          "Assistant r\x{e9}glages de r\x{e9}seau" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '1.6',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/Network Setup Assistant.app',
            Version => '1.6'
          },
          AutoImporter => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.0, \x{a9} Copyright 2000-2009 Apple Inc., all rights reserved.",
            Kind => 'Intel',
            'Last Modified' => '20/06/2009',
            Location => '/System/Library/Image Capture/Support/Application/AutoImporter.app',
            Version => '6.0.1'
          },
          Automator => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "2.1.1, Copyright \x{a9} 2004-2009 Apple Inc. All rights reserved.",
            Kind => 'Intel',
            'Last Modified' => '11/07/2009',
            Location => '/Applications/Automator.app',
            Version => '2.1.1'
          },
          'Automator Launcher' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "1.2, Copyright \x{a9} 2004-2009 Apple Inc. All rights reserved.",
            Kind => 'Intel',
            'Last Modified' => '11/07/2009',
            Location => '/System/Library/CoreServices/Automator Launcher.app',
            Version => '1.2'
          },
          'Automator Runner' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "1.1, Copyright \x{a9} 2006-2009 Apple Inc. All rights reserved.",
            Kind => 'Intel',
            'Last Modified' => '11/07/2009',
            Location => '/System/Library/CoreServices/Automator Runner.app',
            Version => '1.1'
          },
          BigTop => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '08/07/2009',
            Location => '/Developer/Applications/Performance Tools/BigTop.app',
            Version => '4.7.1'
          },
          'Bluetooth Diagnostics Utility' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '2.2, Copyright (c) 2009 Apple Inc. All rights reserved.',
            Kind => 'Universal',
            'Last Modified' => '01/08/2009',
            Location => '/Developer/Applications/Utilities/Bluetooth/Bluetooth Diagnostics Utility.app',
            Version => '2.2'
          },
          'Bluetooth Explorer' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '2.2, Copyright (c) 2009 Apple Inc. All rights reserved.',
            Kind => 'Universal',
            'Last Modified' => '01/08/2009',
            Location => '/Developer/Applications/Utilities/Bluetooth/Bluetooth Explorer.app',
            Version => '2.2'
          },
          BluetoothAudioAgent => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '2.4.5, Copyright (c) 2011 Apple Inc. All rights reserved.',
            Kind => 'Universal',
            'Last Modified' => '01/08/2009',
            Location => '/System/Library/CoreServices/BluetoothAudioAgent.app',
            Version => '2.4.5'
          },
          BluetoothCamera => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.0.1, \x{a9} Copyright 2004-2011 Apple Inc., all rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Devices/BluetoothCamera.app',
            Version => '6.0.1'
          },
          BluetoothUIServer => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '2.4.5, Copyright (c) 2011 Apple Inc. All rights reserved.',
            Kind => 'Universal',
            'Last Modified' => '01/08/2009',
            Location => '/System/Library/CoreServices/BluetoothUIServer.app',
            Version => '2.4.5'
          },
          'Build Applet' => {
            '64-Bit (Intel)' => 'No',
            'Get Info String' => '2.6.0a0, (c) 2004 Python Software Foundation.',
            'Last Modified' => '08/07/2009',
            Location => '/Developer/Applications/Utilities/Python 2.6/Build Applet.app',
            Version => '2.6.0'
          },
          'Build Applet_0' => {
            '64-Bit (Intel)' => 'No',
            'Get Info String' => '2.5.4a0, (c) 2004 Python Software Foundation.',
            'Last Modified' => '08/07/2009',
            Location => '/Developer/Applications/Utilities/MacPython 2.5/Build Applet.app',
            Version => '2.5.4'
          },
          CCacheServer => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.5 Copyright \x{a9} 2008 Massachusetts Institute of Technology",
            Kind => 'Universal',
            'Last Modified' => '29/05/2009',
            Location => '/System/Library/CoreServices/CCacheServer.app',
            Version => '6.5.11'
          },
          'CHUD Remover' => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '08/07/2009',
            Location => '/Developer/Applications/Performance Tools/CHUD/CHUD Remover.app',
            Version => '4.7.1'
          },
          CPUPalette => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '08/07/2009',
            Location => '/Library/Application Support/HWPrefs/CPUPalette.app',
            Version => '4.7.1'
          },
          Calculette => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '06/07/2009',
            Location => '/Applications/Calculator.app',
            Version => '4.5.3'
          },
          Capture => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Applications/Utilities/Grab.app',
            Version => '1.5'
          },
          "Carnet d\x{2019}adresses" => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '25/07/2009',
            Location => '/Applications/Address Book.app',
            Version => '5.0.3'
          },
          CharacterPalette => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '02/07/2009',
            Location => '/System/Library/Input Methods/CharacterPalette.app',
            Version => '1.0.4'
          },
          ChineseHandwriting => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '17/07/2009',
            Location => '/System/Library/Input Methods/ChineseHandwriting.app',
            Version => '1.0.1'
          },
          ChineseTextConverterService => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'Chinese Text Converter 1.1',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/Services/ChineseTextConverterService.app',
            Version => '1.2'
          },
          "Colorim\x{e8}tre num\x{e9}rique" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '3.7.2, Copyright 2001-2008 Apple Inc. All Rights Reserved.',
            Kind => 'Intel',
            'Last Modified' => '28/05/2009',
            Location => '/Applications/Utilities/DigitalColor Meter.app',
            Version => '3.7.2'
          },
          'Configuration actions de dossier' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/Folder Actions Setup.app',
            Version => '1.1.4'
          },
          'Configuration audio et MIDI' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '3.0.3, Copyright 2002-2010 Apple, Inc.',
            Kind => 'Intel',
            'Last Modified' => '11/07/2009',
            Location => '/Applications/Utilities/Audio MIDI Setup.app',
            Version => '3.0.3'
          },
          Console => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '07/04/2009',
            Location => '/Applications/Utilities/Console.app',
            Version => '10.6.3'
          },
          'Core Image Fun House' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Graphics Tools/Core Image Fun House.app',
            Version => '2.1.43'
          },
          CoreLocationAgent => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "Copyright \x{a9} 2009 Apple Inc.",
            Kind => 'Universal',
            'Last Modified' => '20/07/2009',
            Location => '/System/Library/CoreServices/CoreLocationAgent.app',
            Version => '12.3'
          },
          CoreServicesUIAgent => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "Copyright \x{a9} 2009 Apple Inc.",
            Kind => 'Intel',
            'Last Modified' => '23/05/2009',
            Location => '/System/Library/CoreServices/CoreServicesUIAgent.app',
            Version => '41.5'
          },
          CrashReporterPrefs => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '01/08/2009',
            Location => '/Developer/Applications/Utilities/CrashReporterPrefs.app',
            Version => '10.6'
          },
          "Cr\x{e9}ation de page Web" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.0, \x{a9} Copyright 2003-2009 Apple  Inc., all rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Automatic Tasks/Build Web Page.app',
            Version => '6.0'
          },
          Dashboard => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '1.7, Copyright 2006-2008 Apple Inc.',
            Kind => 'Universal',
            'Last Modified' => '31/07/2009',
            Location => '/Applications/Dashboard.app',
            Version => '1.7'
          },
          Dashcode => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '31/07/2009',
            Location => '/Developer/Applications/Dashcode.app',
            Version => '3.0'
          },
          'Database Events' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/Database Events.app',
            Version => '1.0.4'
          },
          'Default aohghmighlieiainnegkcijnfilokake' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '03/05/2015',
            Location => '/Users/teclib/Library/Application Support/Google/Chrome/Default/Web Applications/_crx_aohghmighlieiainnegkcijnfilokake/Default aohghmighlieiainnegkcijnfilokake.app',
            Version => '42.0.2311.135'
          },
          'Default aohghmighlieiainnegkcijnfilokake_0' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '03/05/2015',
            Location => '/Users/walid/Library/Application Support/Google/Chrome/Default/Web Applications/_crx_aohghmighlieiainnegkcijnfilokake/Default aohghmighlieiainnegkcijnfilokake.app',
            Version => '42.0.2311.135'
          },
          'Default apdfllckaahabafndbhieahigkjlhalf' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '29/07/2015',
            Location => '/Users/walid/Library/Application Support/Google/Chrome/Default/Web Applications/_crx_apdfllckaahabafndbhieahigkjlhalf/Default apdfllckaahabafndbhieahigkjlhalf.app',
            Version => '14.0'
          },
          'Default apdfllckaahabafndbhieahigkjlhalf_0' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '29/07/2015',
            Location => '/Users/walid/Applications/Chrome Apps.localized/Default apdfllckaahabafndbhieahigkjlhalf.app',
            Version => '14.0'
          },
          'Default blpcfgokakmgnkcojhhkbfbldkacnbeo' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '03/05/2015',
            Location => '/Users/walid/Library/Application Support/Google/Chrome/Default/Web Applications/_crx_blpcfgokakmgnkcojhhkbfbldkacnbeo/Default blpcfgokakmgnkcojhhkbfbldkacnbeo.app',
            Version => '42.0.2311.135'
          },
          'Default blpcfgokakmgnkcojhhkbfbldkacnbeo_0' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '03/05/2015',
            Location => '/Users/walid/Applications/Chrome Apps.localized/Default blpcfgokakmgnkcojhhkbfbldkacnbeo.app',
            Version => '42.0.2311.135'
          },
          'Default coobgpohoikkiipiblmjeljniedjpjpf' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '03/05/2015',
            Location => '/Users/walid/Library/Application Support/Google/Chrome/Default/Web Applications/_crx_coobgpohoikkiipiblmjeljniedjpjpf/Default coobgpohoikkiipiblmjeljniedjpjpf.app',
            Version => '42.0.2311.135'
          },
          'Default coobgpohoikkiipiblmjeljniedjpjpf_0' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '03/05/2015',
            Location => '/Users/walid/Applications/Chrome Apps.localized/Default coobgpohoikkiipiblmjeljniedjpjpf.app',
            Version => '42.0.2311.135'
          },
          'Default nmmhkkegccagdldgiimedpiccmgmieda' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '29/07/2015',
            Location => '/Users/walid/Library/Application Support/Google/Chrome/Default/Web Applications/_crx_nmmhkkegccagdldgiimedpiccmgmieda/Default nmmhkkegccagdldgiimedpiccmgmieda.app',
            Version => '0.1.2.0'
          },
          'Default pjkljhegncpnkpknbcohdijeoejaedia' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '03/05/2015',
            Location => '/Users/walid/Library/Application Support/Google/Chrome/Default/Web Applications/_crx_pjkljhegncpnkpknbcohdijeoejaedia/Default pjkljhegncpnkpknbcohdijeoejaedia.app',
            Version => '42.0.2311.135'
          },
          'Default pjkljhegncpnkpknbcohdijeoejaedia_0' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '03/05/2015',
            Location => '/Users/walid/Applications/Chrome Apps.localized/Default pjkljhegncpnkpknbcohdijeoejaedia.app',
            Version => '42.0.2311.135'
          },
          'Deskjet 2540 series [CE35D9]' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '24/07/2009',
            Location => '/Users/teclib/Library/Printers/Deskjet 2540 series [CE35D9].app',
            Version => '6.6'
          },
          "Diagnostic r\x{e9}seau" => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '20/05/2009',
            Location => '/System/Library/CoreServices/Network Diagnostics.app',
            Version => '1.1.3'
          },
          DiskImageMounter => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '11/07/2009',
            Location => '/System/Library/CoreServices/DiskImageMounter.app',
            Version => '10.6.8'
          },
          'DiskImages UI Agent' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '11/07/2009',
            Location => '/System/Library/PrivateFrameworks/DiskImages.framework/Versions/A/Resources/DiskImages UI Agent.app',
            Version => '289.1'
          },
          Dock => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'Dock 1.7',
            Kind => 'Intel',
            'Last Modified' => '31/07/2009',
            Location => '/System/Library/CoreServices/Dock.app',
            Version => '1.7'
          },
          'EM64T Help' => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '08/07/2009',
            Location => '/Library/Application Support/Shark/Helpers/EM64T Help.app',
            Version => '4.7.1'
          },
          Embed => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '25/04/2009',
            Location => '/Library/Scripts/ColorSync/Embed.app'
          },
          "Expos\x{e9}" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '1.1, Copyright 2007-2008 Apple Inc.',
            Kind => 'Universal',
            'Last Modified' => '31/07/2009',
            Location => '/Applications/Utilities/Expose.app',
            Version => '1.1'
          },
          Extract => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '25/04/2009',
            Location => '/Library/Scripts/ColorSync/Extract.app'
          },
          'File Sync' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "\x{a9} Copyright 2009 Apple Inc., all rights reserved.",
            Kind => 'Intel',
            'Last Modified' => '23/07/2009',
            Location => '/System/Library/CoreServices/File Sync.app',
            Version => '5.0.3'
          },
          FileMerge => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Utilities/FileMerge.app',
            Version => '2.4'
          },
          FileSyncAgent => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "\x{a9} Copyright 2009 Apple Inc., all rights reserved.",
            Kind => 'Intel',
            'Last Modified' => '23/07/2009',
            Location => '/System/Library/CoreServices/FileSyncAgent.app',
            Version => '5.0.3'
          },
          Finder => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'Mac OS X Finder 10.6.8',
            Kind => 'Intel',
            'Last Modified' => '31/07/2009',
            Location => '/System/Library/CoreServices/Finder.app',
            Version => '10.6.8'
          },
          Firefox => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'Firefox 37.0.2',
            Kind => 'Intel',
            'Last Modified' => '18/01/2016',
            Location => '/Applications/Firefox.app',
            Version => '37.0.2'
          },
          'Folder Actions Dispatcher' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/Folder Actions Dispatcher.app',
            Version => '1.0.2'
          },
          FontRegistryUIAgent => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "Copyright \x{a9} 2011 Apple Inc.",
            Kind => 'Intel',
            'Last Modified' => '26/07/2009',
            Location => '/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/ATS.framework/Versions/A/Support/FontRegistryUIAgent.app',
            Version => '33.12'
          },
          FontSyncScripting => {
            '64-Bit (Intel)' => 'No',
            'Get Info String' => "FontSync Scripting 2.0. Copyright \x{a9} 2000-2008 Apple Inc.",
            Kind => 'Universal',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/ScriptingAdditions/FontSyncScripting.app',
            Version => '2.0.6'
          },
          'Front Row' => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Universal',
            'Last Modified' => '22/07/2009',
            Location => '/System/Library/CoreServices/Front Row.app',
            Version => '2.2.1'
          },
          'Git Gui' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "Git Gui 0.19.0.18.g4498b \x{a9} 2006-2007 Shawn Pearce, et. al.",
            Kind => 'Intel',
            'Last Modified' => '03/05/2015',
            Location => '/usr/local/Cellar/git/2.4.0/share/git-gui/lib/Git Gui.app',
            Version => '0.19.0.18.g4498b'
          },
          Gmail => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '02/03/2016',
            Location => '/Users/teclib/Library/Application Support/Google/Chrome/Default/Web Applications/_crx_pjkljhegncpnkpknbcohdijeoejaedia/Default pjkljhegncpnkpknbcohdijeoejaedia.app',
            Version => '8.1'
          },
          Gmail_0 => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '02/03/2016',
            Location => '/Users/teclib/Applications/Chrome Apps.localized/Default pjkljhegncpnkpknbcohdijeoejaedia.app',
            Version => '8.1'
          },
          'Google Chrome' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '06/04/2016',
            Location => '/Applications/Google Chrome.app',
            Version => '49.0.2623.112'
          },
          "Google\x{a0}Drive" => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '02/03/2016',
            Location => '/Users/teclib/Library/Application Support/Google/Chrome/Default/Web Applications/_crx_apdfllckaahabafndbhieahigkjlhalf/Default apdfllckaahabafndbhieahigkjlhalf.app',
            Version => '14.1'
          },
          "Google\x{a0}Drive_0" => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '02/03/2016',
            Location => '/Users/teclib/Applications/Chrome Apps.localized/Default apdfllckaahabafndbhieahigkjlhalf.app',
            Version => '14.1'
          },
          Grapher => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '07/04/2009',
            Location => '/Applications/Utilities/Grapher.app',
            Version => '2.1'
          },
          HALLab => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Audio/HALLab.app',
            Version => '1.6'
          },
          'HP Scan' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "Copyright \x{a9} 2010-2013, Hewlett-Packard Development Company, L.P.",
            Kind => 'Intel',
            'Last Modified' => '23/11/2015',
            Location => '/Applications/Hewlett-Packard/HP Scan 3.app',
            Version => '4.4.1'
          },
          'HP Scanner 3' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "Copyright \x{a9} 2011-2013, Hewlett-Packard Development Company, L.P.",
            Kind => 'Intel',
            'Last Modified' => '23/11/2015',
            Location => '/Library/Image Capture/Devices/HP Scanner 3.app',
            Version => '4.5.0'
          },
          'HP Utility' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'HP Utility 5.21.2, Copyright (c) 2005-2013 Hewlett-Packard Development Company, L.P.',
            Kind => 'Intel',
            'Last Modified' => '23/11/2015',
            Location => '/Library/Printers/hp/Utilities/HP Utility.app',
            Version => '5.21.2'
          },
          'Help Indexer' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Utilities/Help Indexer.app',
            Version => '4.0'
          },
          HelpViewer => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '14/07/2009',
            Location => '/System/Library/CoreServices/HelpViewer.app',
            Version => '5.0.4'
          },
          'IA32 Help' => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '08/07/2009',
            Location => '/Library/Application Support/Shark/Helpers/IA32 Help.app',
            Version => '4.7.1'
          },
          IORegistryExplorer => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Utilities/IORegistryExplorer.app',
            Version => '2.1'
          },
          'Icon Composer' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Utilities/Icon Composer.app',
            Version => '2.1'
          },
          'Image Capture Extension' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.1, \x{a9} Copyright 2000-2011 Apple Inc. All rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Support/Image Capture Extension.app',
            Version => '6.1'
          },
          'Image Capture Web Server' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.0, \x{a9} Copyright 2003-2009 Apple Inc., all rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Support/Image Capture Web Server.app',
            Version => '6.0'
          },
          'Image Events' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/Image Events.app',
            Version => '1.1.4'
          },
          ImageCaptureService => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.0, \x{a9} Copyright 2003-2009 Apple Inc., all rights reserved.",
            Kind => 'Intel',
            'Last Modified' => '20/06/2009',
            Location => '/System/Library/Services/ImageCaptureService.app',
            Version => '6.0.1'
          },
          IncompatibleAppDisplay => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '01/08/2009',
            Location => '/System/Library/PrivateFrameworks/SystemMigration.framework/Versions/A/Resources/IncompatibleAppDisplay.app',
            Version => '305'
          },
          "Informations Syst\x{e8}me" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '10.6.0, Copyright 1997-2009 Apple, Inc.',
            Kind => 'Universal',
            'Last Modified' => '19/05/2009',
            Location => '/Applications/Utilities/System Profiler.app',
            Version => '10.6.0'
          },
          InkServer => {
            '64-Bit (Intel)' => 'No',
            'Get Info String' => '1.0, Copyright 2008 Apple Inc.',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/Input Methods/InkServer.app',
            Version => '1.0'
          },
          Inkjet9 => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'HP Inkjet 9 Driver 2.3.1, Copyright (c) 1994-2013 Hewlett-Packard Development Company, L.P.',
            Kind => 'Intel',
            'Last Modified' => '19/08/2013',
            Location => '/Library/Printers/hp/cups/Inkjet9.driver',
            Version => '2.3.1'
          },
          "Installation \x{e0} distance de Mac\x{a0}OS\x{a0}X" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "Remote Install Mac OS X 1.1.1, Copyright \x{a9} 2007-2009 Apple Inc. All rights reserved",
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Applications/Utilities/Remote Install Mac OS X.app',
            Version => '1.1.1'
          },
          Instruments => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '24/07/2009',
            Location => '/Developer/Applications/Instruments.app',
            Version => '2.0'
          },
          'Interface Builder' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '11/07/2009',
            Location => '/Developer/Applications/Interface Builder.app',
            Version => '3.2'
          },
          'Jar Bundler' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '08/07/2015',
            Location => '/usr/share/java/Tools/Jar Bundler.app',
            Version => '13.9.8'
          },
          'Jar Launcher' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/CoreServices/Jar Launcher.app',
            Version => '13.9.8'
          },
          'Java VisualVM' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '08/07/2015',
            Location => '/usr/share/java/Tools/Java VisualVM.app',
            Version => '13.9.8'
          },
          'Java Web Start' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/CoreServices/Java Web Start.app',
            Version => '13.9.8'
          },
          KerberosAgent => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '29/05/2009',
            Location => '/System/Library/CoreServices/KerberosAgent.app',
            Version => '6.5.11'
          },
          KeyboardSetupAssistant => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/KeyboardSetupAssistant.app',
            Version => '10.5.0'
          },
          KeyboardViewer => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "2.0, Copyright \x{a9} 2004-2009 Apple Inc., All Rights Reserved",
            Kind => 'Universal',
            'Last Modified' => '11/06/2009',
            Location => '/System/Library/Input Methods/KeyboardViewer.app',
            Version => '2.0'
          },
          'Keychain Scripting' => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Universal',
            'Last Modified' => '03/07/2009',
            Location => '/System/Library/ScriptingAdditions/Keychain Scripting.app',
            Version => '4.0.2'
          },
          KoreanIM => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.0, Copyright \x{a9} 1997-2006 Apple Computer Inc., All Rights Reserved",
            Kind => 'Universal',
            'Last Modified' => '05/05/2009',
            Location => '/System/Library/Input Methods/KoreanIM.app',
            Version => '6.1'
          },
          Kotoeri => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '11/06/2009',
            Location => '/System/Library/Input Methods/Kotoeri.app',
            Version => '4.2.1'
          },
          "Lanceur d\x{2019}applets" => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '08/07/2015',
            Location => '/usr/share/java/Tools/Applet Launcher.app',
            Version => '13.9.8'
          },
          'Language Chooser' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'System Language Initializer',
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/CoreServices/Language Chooser.app',
            Version => '20'
          },
          'Lecteur DVD' => {
            '64-Bit (Intel)' => 'No',
            'Get Info String' => "5.4, Copyright \x{a9} 2001-2010 by Apple Inc.  All Rights Reserved.",
            Kind => 'Intel',
            'Last Modified' => '14/07/2009',
            Location => '/Applications/DVD Player.app',
            Version => '5.4'
          },
          License => {
            '64-Bit (Intel)' => 'No',
            'Get Info String' => 'License',
            Kind => 'Universal',
            'Last Modified' => '25/07/2009',
            Location => '/Library/Documentation/License.app',
            Version => '11'
          },
          'Livre des polices' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "2.2.2, Copyright \x{a9} 2003-2010 Apple Inc.",
            Kind => 'Intel',
            'Last Modified' => '05/05/2009',
            Location => '/Applications/Font Book.app',
            Version => '2.2.2'
          },
          MRTAgent => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/CoreServices/MRTAgent.app',
            Version => '1.2'
          },
          Mail => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/Applications/Mail.app',
            Version => '4.6'
          },
          MakePDF => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.0, \x{a9} Copyright 2003-2009 Apple Inc., all rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Automatic Tasks/MakePDF.app',
            Version => '6.0'
          },
          MallocDebug => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Universal',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Performance Tools/MallocDebug.app',
            Version => '1.7.1'
          },
          ManagedClient => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '24/07/2009',
            Location => '/System/Library/CoreServices/ManagedClient.app',
            Version => '2.5'
          },
          MassStorageCamera => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.1, \x{a9} Copyright 2000-2011 Apple Inc. All rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Devices/MassStorageCamera.app',
            Version => '6.1'
          },
          Match => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '25/04/2009',
            Location => '/Library/Scripts/ColorSync/Match.app'
          },
          MiniTerm => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'Terminal window application for PPP',
            Kind => 'Universal',
            'Last Modified' => '08/07/2015',
            Location => '/usr/libexec/MiniTerm.app',
            Version => '1.5'
          },
          "Mise \x{e0} jour de logiciels" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "Software Update version 4.0, Copyright \x{a9} 2000-2009, Apple Inc. All rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/CoreServices/Software Update.app',
            Version => '4.0.6'
          },
          "Moniteur d\x{2019}activit\x{e9}" => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '31/07/2009',
            Location => '/Applications/Utilities/Activity Monitor.app',
            Version => '10.6'
          },
          NetAuthAgent => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '23/06/2009',
            Location => '/System/Library/CoreServices/NetAuthAgent.app',
            Version => '2.1'
          },
          OBEXAgent => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '2.4.5, Copyright (c) 2011 Apple Inc. All rights reserved.',
            Kind => 'Universal',
            'Last Modified' => '01/08/2009',
            Location => '/System/Library/CoreServices/OBEXAgent.app',
            Version => '2.4.5'
          },
          ODSAgent => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "1.4.1 (141.6), Copyright \x{a9} 2007-2009 Apple Inc. All Rights Reserved.",
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/ODSAgent.app',
            Version => '1.4.1'
          },
          'OpenGL Driver Monitor' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "1.5, Copyright \x{a9} 2009 Apple Inc.",
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Graphics Tools/OpenGL Driver Monitor.app',
            Version => '1.5'
          },
          'OpenGL Profiler' => {
            '64-Bit (Intel)' => 'No',
            'Get Info String' => '4.2, Copyright 2003-2009 Apple, Inc.',
            Kind => 'Universal',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Graphics Tools/OpenGL Profiler.app',
            Version => '4.2'
          },
          'OpenGL Shader Builder' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Graphics Tools/OpenGL Shader Builder.app',
            Version => '2.1'
          },
          "Outil d\x{2019}\x{e9}talonnage du moniteur" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '4.6, Copyright 2008 Apple Computer, Inc.',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/ColorSync/Calibrators/Display Calibrator.app',
            Version => '4.6'
          },
          PTPCamera => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.1, \x{a9} Copyright 2004-2011 Apple Inc., all rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Devices/PTPCamera.app',
            Version => '6.1'
          },
          PackageMaker => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Utilities/PackageMaker.app',
            Version => '3.0.4'
          },
          PacketLogger => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '2.2, Copyright (c) 2009 Apple Inc. All rights reserved.',
            Kind => 'Universal',
            'Last Modified' => '01/08/2009',
            Location => '/Developer/Applications/Utilities/Bluetooth/PacketLogger.app',
            Version => '2.2'
          },
          "Paiements via le Chrome\x{a0}Web\x{a0}Store" => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '25/04/2016',
            Location => '/Users/teclib/Library/Application Support/Google/Chrome/Default/Web Applications/_crx_nmmhkkegccagdldgiimedpiccmgmieda/Default nmmhkkegccagdldgiimedpiccmgmieda.app',
            Version => '1.0.0.0'
          },
          ParentalControls => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '2.0, Copyright Apple Inc. 2007-2009',
            Kind => 'Universal',
            'Last Modified' => '01/08/2009',
            Location => '/System/Library/PrivateFrameworks/FamilyControls.framework/Versions/A/Resources/ParentalControls.app',
            Version => '2.0'
          },
          "Partage d\x{2019}\x{e9}cran" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "1.1.1, Copyright \x{a9} 2007-2009 Apple Inc., All Rights Reserved.",
            Kind => 'Universal',
            'Last Modified' => '02/07/2009',
            Location => '/System/Library/CoreServices/Screen Sharing.app',
            Version => '1.1.1'
          },
          Pixie => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Graphics Tools/Pixie.app',
            Version => '2.3'
          },
          PluginIM => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/Input Methods/PluginIM.app',
            Version => '1.1'
          },
          PluginProcess => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '6534.59.10, Copyright 2003-2013 Apple Inc.',
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/PrivateFrameworks/WebKit2.framework/PluginProcess.app',
            Version => '6534.59'
          },
          'PowerPC Help' => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '08/07/2009',
            Location => '/Library/Application Support/Shark/Helpers/PowerPC Help.app',
            Version => '4.7.1'
          },
          PreferenceSyncClient => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '02/07/2009',
            Location => '/System/Library/CoreServices/PreferenceSyncClient.app',
            Version => '2.0'
          },
          'Printer Setup Utility' => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Universal',
            'Last Modified' => '24/07/2009',
            Location => '/System/Library/CoreServices/Printer Setup Utility.app',
            Version => '6.6'
          },
          PrinterProxy => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '24/07/2009',
            Location => '/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/Print.framework/Versions/A/Plugins/PrinterProxy.app',
            Version => '6.6'
          },
          'Problem Reporter' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '01/08/2009',
            Location => '/System/Library/CoreServices/Problem Reporter.app',
            Version => '10.6.7'
          },
          "Programme de d\x{e9}sinstallation HP" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '5.2.0.13',
            Kind => 'Intel',
            'Last Modified' => '23/11/2015',
            Location => '/Applications/Hewlett-Packard/HP Uninstaller.app',
            Version => '5.2.0.13'
          },
          "Programme d\x{2019}installation" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "3.0, Copyright \x{a9} 2000-2006 Apple Computer Inc., All Rights Reserved",
            Kind => 'Universal',
            'Last Modified' => '27/06/2009',
            Location => '/System/Library/CoreServices/Installer.app',
            Version => '4.0'
          },
          Proof => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '25/04/2009',
            Location => '/Library/Scripts/ColorSync/Proof.app'
          },
          'Property List Editor' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '11/07/2009',
            Location => '/Developer/Applications/Utilities/Property List Editor.app',
            Version => '3.2'
          },
          "Pr\x{e9}f\x{e9}rences Java" => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '08/07/2015',
            Location => '/Applications/Utilities/Java Preferences.app',
            Version => '13.9.8'
          },
          "Pr\x{e9}f\x{e9}rences Syst\x{e8}me" => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '27/06/2009',
            Location => '/Applications/System Preferences.app',
            Version => '7.0'
          },
          PubSubAgent => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/Frameworks/PubSub.framework/Versions/A/Resources/PubSubAgent.app',
            Version => '1.0.5'
          },
          Python => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '2.6, (c) 2004 Python Software Foundation.',
            Kind => 'Universal',
            'Last Modified' => '08/07/2009',
            Location => '/System/Library/Frameworks/Python.framework/Versions/2.6/Resources/Python.app',
            Version => '2.6'
          },
          'Python Launcher' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "2.6.1, \x{a9} 001-2006 Python Software Foundation",
            Kind => 'Universal',
            'Last Modified' => '08/07/2009',
            Location => '/System/Library/Frameworks/Python.framework/Versions/2.6/Resources/Python Launcher.app',
            Version => '2.6.1'
          },
          'Python Launcher_0' => {
            '64-Bit (Intel)' => 'No',
            'Get Info String' => "2.5.4, \x{a9} 001-2006 Python Software Foundation",
            Kind => 'Universal',
            'Last Modified' => '08/07/2009',
            Location => '/System/Library/Frameworks/Python.framework/Versions/2.5/Resources/Python Launcher.app',
            Version => '2.5.4'
          },
          Python_0 => {
            '64-Bit (Intel)' => 'No',
            'Get Info String' => '2.5.4a0, (c) 2004 Python Software Foundation.',
            Kind => 'Universal',
            'Last Modified' => '08/07/2009',
            Location => '/System/Library/Frameworks/Python.framework/Versions/2.5/Resources/Python.app',
            Version => '2.5.4'
          },
          Python_1 => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Universal',
            'Last Modified' => '13/05/2009',
            Location => '/Developer/SDKs/MacOSX10.5.sdk/System/Library/Frameworks/Python.framework/Versions/2.5/Resources/Python.app'
          },
          'Quartz Composer' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '28/05/2009',
            Location => '/Developer/Applications/Quartz Composer.app',
            Version => '4.0'
          },
          'Quartz Composer Visualizer' => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Graphics Tools/Quartz Composer Visualizer.app',
            Version => '1.2'
          },
          'Quartz Debug' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'Quartz Debug 4.0',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Performance Tools/Quartz Debug.app',
            Version => '4.0'
          },
          'QuickTime Player' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "10.0, Copyright \x{a9} 2010-2011 Apple Inc. All Rights Reserved.",
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/Applications/QuickTime Player.app',
            Version => '10.0'
          },
          'Recherche Google' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '02/03/2016',
            Location => '/Users/teclib/Library/Application Support/Google/Chrome/Default/Web Applications/_crx_coobgpohoikkiipiblmjeljniedjpjpf/Default coobgpohoikkiipiblmjeljniedjpjpf.app',
            Version => '0.0.0.60'
          },
          'Recherche Google_0' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '02/03/2016',
            Location => '/Users/teclib/Applications/Chrome Apps.localized/Default coobgpohoikkiipiblmjeljniedjpjpf.app',
            Version => '0.0.0.60'
          },
          'Reggie SE' => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '08/07/2009',
            Location => '/Developer/Applications/Performance Tools/CHUD/Hardware Tools/Reggie SE.app',
            Version => '4.7.1'
          },
          Remove => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '25/04/2009',
            Location => '/Library/Scripts/ColorSync/Remove.app'
          },
          Rename => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '25/04/2009',
            Location => '/Library/Scripts/ColorSync/Rename.app'
          },
          'Repeat After Me' => {
            '64-Bit (Intel)' => 'No',
            'Get Info String' => "1.3, Copyright \x{a9} 2002-2005 Apple Computer, Inc.",
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Utilities/Speech/Repeat After Me.app',
            Version => '1.3'
          },
          "R\x{e9}solution des conflits" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '1.0, Copyright Apple Computer Inc. 2004',
            Kind => 'Universal',
            'Last Modified' => '18/07/2009',
            Location => '/System/Library/PrivateFrameworks/SyncServicesUI.framework/Versions/A/Resources/Conflict Resolver.app',
            Version => '5.2'
          },
          SCIM => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "4.0, Copyright \x{a9} 1997-2009 Apple Inc., All Rights Reserved",
            Kind => 'Universal',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/Input Methods/SCIM.app',
            Version => '4.3'
          },
          SRLanguageModeler => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Utilities/Speech/SRLanguageModeler.app',
            Version => '1.9'
          },
          Safari => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "5.1.10, Copyright \x{a9} 2003-2013 Apple Inc.",
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/Applications/Safari.app',
            Version => '5.1.10'
          },
          Saturn => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '08/07/2009',
            Location => '/Developer/Applications/Performance Tools/CHUD/Saturn.app',
            Version => '4.7.1'
          },
          ScanEventHandler => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'Copyright (c) 2013 Hewlett-Packard Development Company, L.P.',
            Kind => 'Intel',
            'Last Modified' => '23/11/2015',
            Location => '/Library/Printers/hp/Utilities/Handlers/ScanEventHandler.app',
            Version => '1.0.0'
          },
          ScreenReaderUIServer => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '18/07/2009',
            Location => '/System/Library/PrivateFrameworks/ScreenReader.framework/Versions/A/Resources/ScreenReaderUIServer.app',
            Version => '3.5.0'
          },
          ScreenSaverEngine => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '24/06/2009',
            Location => '/System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app',
            Version => '3.0.3'
          },
          SecurityAgent => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '18/07/2009',
            Location => '/System/Library/CoreServices/SecurityAgent.app',
            Version => '5.2'
          },
          SecurityFixer => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/SecurityFixer.app',
            Version => '10.6'
          },
          SecurityProxy => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '21/05/2009',
            Location => '/System/Library/CoreServices/SecurityProxy.app',
            Version => '1.0'
          },
          ServerJoiner => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/07/2009',
            Location => '/System/Library/CoreServices/ServerJoiner.app',
            Version => '10.6.3'
          },
          "Service de r\x{e9}sum\x{e9}" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'Summary Service Version  2',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/Services/SummaryService.app',
            Version => '2.0'
          },
          'Set Info' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '25/04/2009',
            Location => '/Library/Scripts/ColorSync/Set Info.app'
          },
          Shark => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '08/07/2009',
            Location => '/Developer/Applications/Performance Tools/Shark.app',
            Version => '4.7.1'
          },
          'Show Info' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '25/04/2009',
            Location => '/Library/Scripts/ColorSync/Show Info.app'
          },
          Skype => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '19/08/2014',
            Location => '/Applications/Skype.app',
            Version => '6.15'
          },
          SleepX => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Utilities/SleepX.app',
            Version => '2.7'
          },
          Spaces => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '1.1, Copyright 2007-2008 Apple Inc.',
            Kind => 'Universal',
            'Last Modified' => '31/07/2009',
            Location => '/Applications/Utilities/Spaces.app',
            Version => '1.1'
          },
          SpeakableItems => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/Speech/Recognizers/AppleSpeakableItems.SpeechRecognizer/Contents/Resources/SpeakableItems.app',
            Version => '3.7.8'
          },
          'Speech Startup' => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '29/05/2009',
            Location => '/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/SpeechRecognition.framework/Versions/A/Resources/Speech Startup.app',
            Version => '3.8.1'
          },
          SpeechFeedbackWindow => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '29/05/2009',
            Location => '/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/SpeechRecognition.framework/Versions/A/Resources/SpeechFeedbackWindow.app',
            Version => '3.8.1'
          },
          SpeechRecognitionServer => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '29/05/2009',
            Location => '/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/SpeechRecognition.framework/Versions/A/Resources/SpeechRecognitionServer.app',
            Version => '3.11.1'
          },
          SpeechService => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '12/07/2009',
            Location => '/System/Library/Services/SpeechService.service',
            Version => '3.10.35'
          },
          SpeechSynthesisServer => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '12/07/2009',
            Location => '/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/SpeechSynthesis.framework/Versions/A/Resources/SpeechSynthesisServer.app',
            Version => '3.10.35'
          },
          'Spin Control' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'Spin Control',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Performance Tools/Spin Control.app',
            Version => '0.9'
          },
          SpindownHD => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Intel',
            'Last Modified' => '08/07/2009',
            Location => '/Developer/Applications/Performance Tools/CHUD/Hardware Tools/SpindownHD.app',
            Version => '4.7.1'
          },
          Spotlight => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '24/07/2009',
            Location => '/System/Library/Services/Spotlight.service',
            Version => '2.0'
          },
          SyncDiagnostics => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '18/07/2009',
            Location => '/System/Library/Frameworks/SyncServices.framework/Versions/A/Resources/SyncDiagnostics.app',
            Version => '5.2'
          },
          SyncServer => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "\x{a9} 2002-2003 Apple",
            Kind => 'Universal',
            'Last Modified' => '18/07/2009',
            Location => '/System/Library/Frameworks/SyncServices.framework/Versions/A/Resources/SyncServer.app',
            Version => '5.2'
          },
          Syncrospector => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "Syncrospector 3.0, \x{a9} 2004 Apple Computer, Inc., All rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '18/07/2009',
            Location => '/Developer/Applications/Utilities/Syncrospector.app',
            Version => '4.0'
          },
          'System Events' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/System Events.app',
            Version => '1.3.4'
          },
          SystemUIServer => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'SystemUIServer version 1.6, Copyright 2000-2009 Apple Computer, Inc.',
            Kind => 'Intel',
            'Last Modified' => '22/07/2009',
            Location => '/System/Library/CoreServices/SystemUIServer.app',
            Version => '1.6'
          },
          TCIM => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.2, Copyright \x{a9} 1997-2006 Apple Computer Inc., All Rights Reserved",
            Kind => 'Universal',
            'Last Modified' => '07/07/2009',
            Location => '/System/Library/Input Methods/TCIM.app',
            Version => '6.3'
          },
          TWAINBridge => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.0.1, \x{a9} Copyright 2000-2010 Apple Inc., all rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Devices/TWAINBridge.app',
            Version => '6.0.1'
          },
          TamilIM => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'Tamil Input Method 1.2',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/Input Methods/TamilIM.app',
            Version => '1.3'
          },
          Terminal => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "2.1.2, \x{a9} 1995-2010 Apple Inc. All Rights Reserved.",
            Kind => 'Intel',
            'Last Modified' => '06/07/2009',
            Location => '/Applications/Utilities/Terminal.app',
            Version => '2.1.2'
          },
          TextEdit => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '27/06/2009',
            Location => '/Applications/TextEdit.app',
            Version => '1.6'
          },
          'Ticket Viewer' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/Ticket Viewer.app',
            Version => '1.0'
          },
          'Time Machine' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '1.1, Copyright 2007-2008 Apple Inc.',
            Kind => 'Universal',
            'Last Modified' => '31/07/2009',
            Location => '/Applications/Time Machine.app',
            Version => '1.1'
          },
          'Transfert de podcast' => {
            '64-Bit (Intel)' => 'No',
            'Get Info String' => "2.0.1, Copyright \x{a9} 2007-2009 Apple Inc.",
            Kind => 'Intel',
            'Last Modified' => '21/07/2009',
            Location => '/Applications/Utilities/Podcast Capture.app',
            Version => '2.0.2'
          },
          "Transfert d\x{2019}images" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.0, \x{a9} Copyright 2000-2009 Apple Inc., all rights reserved.",
            Kind => 'Intel',
            'Last Modified' => '20/06/2009',
            Location => '/Applications/Image Capture.app',
            Version => '6.0.1'
          },
          "Trousseau d\x{2019}acc\x{e8}s" => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '31/07/2009',
            Location => '/Applications/Utilities/Keychain Access.app',
            Version => '4.1.1'
          },
          Type1Camera => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.0, \x{a9} Copyright 2000-2009 Apple Inc., all rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Devices/Type1Camera.app',
            Version => '6.0'
          },
          Type2Camera => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.0, \x{a9} Copyright 2000-2009 Apple Inc., all rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Devices/Type2Camera.app',
            Version => '6.0'
          },
          Type3Camera => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.0, \x{a9} Copyright 2001-2009 Apple Inc., all rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Devices/Type3Camera.app',
            Version => '6.0'
          },
          Type4Camera => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.1, \x{a9} Copyright 2001-2011 Apple Inc. All rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Devices/Type4Camera.app',
            Version => '6.1'
          },
          Type5Camera => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.1, \x{a9} Copyright 2001-2011 Apple Inc., all rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Devices/Type5Camera.app',
            Version => '6.1'
          },
          Type6Camera => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.0, \x{a9} Copyright 2002-2009 Apple Inc., all rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Devices/Type6Camera.app',
            Version => '6.0'
          },
          Type7Camera => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.0, \x{a9} Copyright 2002-2009 Apple Inc., all rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Devices/Type7Camera.app',
            Version => '6.0'
          },
          Type8Camera => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "6.1, \x{a9} Copyright 2002-2011 Apple Inc., all rights reserved.",
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Image Capture/Devices/Type8Camera.app',
            Version => '6.1'
          },
          'URL Access Scripting' => {
            '64-Bit (Intel)' => 'No',
            'Get Info String' => "URL Access Scripting 1.1, Copyright \x{a9} 2002-2004 Apple Computer, Inc.",
            Kind => 'Universal',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/ScriptingAdditions/URL Access Scripting.app',
            Version => '1.1.1'
          },
          'USB Prober' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "3.7.5, Copyright \x{a9} 2002-2007 Apple Inc. All Rights Reserved.",
            Kind => 'Intel',
            'Last Modified' => '01/08/2009',
            Location => '/Developer/Applications/Utilities/USB Prober.app',
            Version => '3.7.5'
          },
          UnmountAssistantAgent => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '03/07/2009',
            Location => '/System/Library/CoreServices/UnmountAssistantAgent.app',
            Version => '1.0'
          },
          Updated => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'Firefox 43.0.4',
            Kind => 'Intel',
            'Last Modified' => '18/01/2016',
            Location => '/Users/teclib/Library/Caches/Mozilla/updates/Applications/Firefox/updates/0/Updated.app',
            Version => '43.0.4'
          },
          UserNotificationCenter => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/UserNotificationCenter.app',
            Version => '3.1.0'
          },
          'Utilitaire AirPort' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '5.4.2, Copyright 2001-2009 Apple Inc.',
            Kind => 'Intel',
            'Last Modified' => '27/04/2009',
            Location => '/Applications/Utilities/AirPort Utility.app',
            Version => '5.4.2'
          },
          'Utilitaire AppleScript' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/AppleScript Utility.app',
            Version => '1.1.1'
          },
          'Utilitaire ColorSync' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "4.6.2, \x{a9} Copyright 2009 Apple Inc.",
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Applications/Utilities/ColorSync Utility.app',
            Version => '4.6.2'
          },
          'Utilitaire RAID' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "RAID Utility 1.0 (121), Copyright \x{a9} 2007-2009 Apple Inc.",
            Kind => 'Intel',
            'Last Modified' => '01/08/2009',
            Location => '/Applications/Utilities/RAID Utility.app',
            Version => '1.2'
          },
          'Utilitaire VoiceOver' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '18/07/2009',
            Location => '/Applications/Utilities/VoiceOver Utility.app',
            Version => '3.5.0'
          },
          'Utilitaire de disque' => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "Version 11.5.2, Copyright \x{a9} 1999-2010 Apple Inc. All rights reserved.",
            Kind => 'Intel',
            'Last Modified' => '01/08/2009',
            Location => '/Applications/Utilities/Disk Utility.app',
            Version => '11.5.2'
          },
          "Utilitaire de r\x{e9}seau" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "Version 1.4.6, Copyright \x{a9} 2000-2009 Apple Inc. All rights reserved.",
            Kind => 'Intel',
            'Last Modified' => '25/06/2009',
            Location => '/Applications/Utilities/Network Utility.app',
            Version => '1.4.6'
          },
          "Utilitaire d\x{2019}annuaire" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "2.2, Copyright \x{a9} 2001\x{2013}2008 Apple Inc.",
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/Directory Utility.app',
            Version => '2.2'
          },
          "Utilitaire d\x{2019}archive" => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '18/06/2009',
            Location => '/System/Library/CoreServices/Archive Utility.app',
            Version => '10.6'
          },
          "Utilitaire d\x{2019}emplacement de m\x{e9}moire" => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/Memory Slot Utility.app',
            Version => '1.4.1'
          },
          "Utilitaire d\x{2019}emplacement d\x{2019}extension" => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/CoreServices/Expansion Slot Utility.app',
            Version => '1.4.1'
          },
          VietnameseIM => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/Input Methods/VietnameseIM.app',
            Version => '1.1.1'
          },
          VoiceOver => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '18/07/2009',
            Location => '/System/Library/CoreServices/VoiceOver.app',
            Version => '3.5.0'
          },
          'VoiceOver Quickstart' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '18/07/2009',
            Location => '/System/Library/PrivateFrameworks/ScreenReader.framework/Versions/A/Resources/VoiceOver Quickstart.app',
            Version => '3.5.0'
          },
          WebKitPluginHost => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/Frameworks/WebKit.framework/WebKitPluginHost.app',
            Version => '6534'
          },
          WebKitPluginHost_0 => {
            '64-Bit (Intel)' => 'No',
            'Last Modified' => '11/07/2009',
            Location => '/Developer/SDKs/MacOSX10.6.sdk/System/Library/Frameworks/WebKit.framework/WebKitPluginHost.app'
          },
          WebProcess => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '6534.59.10, Copyright 2003-2013 Apple Inc.',
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/PrivateFrameworks/WebKit2.framework/WebProcess.app',
            Version => '6534.59'
          },
          Wish => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "Wish Shell 8.5.7,
Copyright \x{a9} 1989-2009 Tcl Core Team,
Copyright \x{a9} 2002-2009 Daniel A. Steffen,
Copyright \x{a9} 2001-2009 Apple Inc.,
Copyright \x{a9} 2001-2002 Jim Ingham & Ian Reid",
            Kind => 'Intel',
            'Last Modified' => '23/07/2009',
            Location => '/System/Library/Frameworks/Tk.framework/Versions/8.5/Resources/Wish.app',
            Version => '8.5.7'
          },
          Wish_0 => {
            '64-Bit (Intel)' => 'No',
            'Get Info String' => "Wish Shell 8.4.19,
Copyright \x{a9} 2009 Tcl Core Team,
Copyright \x{a9} 2002-2009 Daniel A. Steffen,
Initial MacOS X Port by Jim Ingham & Ian Reid,
Copyright \x{a9} 2001-2002, Apple Computer, Inc.",
            Kind => 'Intel',
            'Last Modified' => '23/07/2009',
            Location => '/System/Library/Frameworks/Tk.framework/Versions/8.4/Resources/Wish.app',
            Version => '8.4.19'
          },
          Xcode => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'Xcode version 3.2',
            Kind => 'Universal',
            'Last Modified' => '31/07/2009',
            Location => '/Developer/Applications/Xcode.app',
            Version => '3.2'
          },
          'Yahoo! Sync' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/PrivateFrameworks/YahooSync.framework/Versions/A/Resources/Yahoo! Sync.app',
            Version => '1.3'
          },
          YouTube => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '02/03/2016',
            Location => '/Users/teclib/Library/Application Support/Google/Chrome/Default/Web Applications/_crx_blpcfgokakmgnkcojhhkbfbldkacnbeo/Default blpcfgokakmgnkcojhhkbfbldkacnbeo.app',
            Version => '4.2.8'
          },
          YouTube_0 => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '02/03/2016',
            Location => '/Users/teclib/Applications/Chrome Apps.localized/Default blpcfgokakmgnkcojhhkbfbldkacnbeo.app',
            Version => '4.2.8'
          },
          autosetup => {
            'Last Modified' => '14/08/2013',
            Location => '/Library/Printers/hp/cups/tools/autosetup.tool'
          },
          check_afp => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "AFP Client Session Monitor, Copyright \x{a9} 2000 - 2010, Apple Inc.",
            Kind => 'Universal',
            'Last Modified' => '03/07/2009',
            Location => '/System/Library/Filesystems/AppleShare/check_afp.app',
            Version => '2.1'
          },
          commandtohp => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'HP Command File Filter 2.2.1, Copyright (c) 2006-2013 Hewlett-Packard Development Company, L.P.',
            Kind => 'Intel',
            'Last Modified' => '14/08/2013',
            Location => '/Library/Printers/hp/cups/filters/commandtohp.filter',
            Version => '2.2.1'
          },
          dotmacfx => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '26/06/2009',
            Location => '/System/Library/Frameworks/SecurityFoundation.framework/Versions/A/dotmacfx.app',
            Version => '3.0'
          },
          eaptlstrust => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/PrivateFrameworks/EAP8021X.framework/Support/eaptlstrust.app',
            Version => '10.0'
          },
          fax => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'HP Fax 5.11.0, Copyright (c) 2009-2013 Hewlett-Packard Development Company, L.P.',
            Kind => 'Intel',
            'Last Modified' => '14/08/2013',
            Location => '/Library/Printers/hp/Fax/fax.backend',
            Version => '5.11.0'
          },
          hpdot4d => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'hpdot4d 4.8.3, Copyright (c) 2005-2013 Hewlett-Packard Development Company, L.P.',
            Kind => 'Intel',
            'Last Modified' => '23/11/2015',
            Location => '/Library/Printers/hp/Frameworks/HPDeviceModel.framework/Versions/4.0/Runtime/hpdot4d.app',
            Version => '4.8.3'
          },
          iCal => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/Applications/iCal.app',
            Version => '4.0.4'
          },
          'iCal Helper' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '16/07/2009',
            Location => '/System/Library/Frameworks/CalendarStore.framework/Versions/A/Resources/iCal Helper.app',
            Version => '4.0.4'
          },
          iChatAgent => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '29/07/2009',
            Location => '/System/Library/Frameworks/IMCore.framework/iChatAgent.app',
            Version => '5.0.3'
          },
          iSync => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "3.1.2, Copyright \x{a9} 2003-2010 Apple Inc.",
            Kind => 'Intel',
            'Last Modified' => '19/05/2009',
            Location => '/Applications/iSync.app',
            Version => '3.1.2'
          },
          'iSync Plug-in Maker' => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '19/05/2009',
            Location => '/Developer/Applications/Utilities/iSync Plug-in Maker.app',
            Version => '3.1'
          },
          iTunes => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => "iTunes 11.4, \x{a9} 2000\x{2013}2014 Apple Inc. All rights reserved.",
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/Applications/iTunes.app',
            Version => '11.4'
          },
          kcSync => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '26/06/2009',
            Location => '/System/Library/Frameworks/SecurityFoundation.framework/Versions/A/kcSync.app',
            Version => '3.0.1'
          },
          loginwindow => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Universal',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/CoreServices/loginwindow.app',
            Version => '6.1.2'
          },
          pdftopdf => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'HP PDF Filter 2.5.2, Copyright (c) 2001-2013 Hewlett-Packard Development Company, L.P.',
            Kind => 'Intel',
            'Last Modified' => '14/08/2013',
            Location => '/Library/Printers/hp/cups/filters/pdftopdf.filter',
            Version => '2.5.2'
          },
          quicklookd => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '1.0, Copyright Apple Inc. 2007',
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/Frameworks/QuickLook.framework/Versions/A/Resources/quicklookd.app',
            Version => '2.3'
          },
          quicklookd32 => {
            '64-Bit (Intel)' => 'No',
            'Get Info String' => '1.0, Copyright Apple Inc. 2007',
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/Frameworks/QuickLook.framework/Versions/A/Resources/quicklookd32.app',
            Version => '2.3'
          },
          rastertofax => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => 'HP Fax 5.11.0, Copyright (c) 2009-2013 Hewlett-Packard Development Company, L.P.',
            Kind => 'Intel',
            'Last Modified' => '14/08/2013',
            Location => '/Library/Printers/hp/Fax/rastertofax.filter',
            Version => '5.11.0'
          },
          rcd => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '2.6',
            Kind => 'Intel',
            'Last Modified' => '01/08/2009',
            Location => '/System/Library/CoreServices/rcd.app',
            Version => '2.6'
          },
          store_helper => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '02/06/2011',
            Location => '/System/Library/PrivateFrameworks/CommerceKit.framework/Versions/A/Resources/store_helper.app',
            Version => '1.0'
          },
          syncuid => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '4.0, Copyright Apple Computer Inc. 2004',
            Kind => 'Universal',
            'Last Modified' => '18/07/2009',
            Location => '/System/Library/PrivateFrameworks/SyncServicesUI.framework/Versions/A/Resources/syncuid.app',
            Version => '5.2'
          },
          updater => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '18/01/2016',
            Location => '/Users/teclib/Library/Caches/Mozilla/updates/Applications/Firefox/updates/0/updater.app',
            Version => '1.0'
          },
          webdav_cert_ui => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '08/07/2015',
            Location => '/System/Library/Filesystems/webdav.fs/Support/webdav_cert_ui.app',
            Version => '1.8.3'
          },
          wxPerl => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Universal',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/Perl/Extras/5.8.9/darwin-thread-multi-2level/auto/Wx/wxPerl.app',
            Version => '1.0'
          },
          wxPerl_0 => {
            '64-Bit (Intel)' => 'No',
            Kind => 'Universal',
            'Last Modified' => '19/05/2009',
            Location => '/System/Library/Perl/Extras/5.10.0/darwin-thread-multi-2level/auto/Wx/wxPerl.app',
            Version => '1.0'
          },
          "\x{c9}change de fichiers Bluetooth" => {
            '64-Bit (Intel)' => 'Yes',
            'Get Info String' => '2.4.5, Copyright (c) 2011 Apple Inc. All rights reserved.',
            Kind => 'Universal',
            'Last Modified' => '01/08/2009',
            Location => '/Applications/Utilities/Bluetooth File Exchange.app',
            Version => '2.4.5'
          },
          "\x{c9}diteur AppleScript" => {
            '64-Bit (Intel)' => 'Yes',
            Kind => 'Intel',
            'Last Modified' => '24/04/2009',
            Location => '/Applications/Utilities/AppleScript Editor.app',
            Version => '2.3'
          }
        },
        count => 291,
    }
);

# Fix 'Get Info String' to be a regexp as it is not multiline on flatfile case
foreach my $case (values(%xmlparsing)) {
    foreach my $entry (values(%{$case->{list}})) {
        my $string = $entry->{'Get Info String'}
            or next;
        my @lines = split("\n", $string);
        next unless @lines > 1;
        $string = $lines[0];
        $string =~ s/\./\\./g;
        $entry->{'Get Info String'} = re("^$string");
    }
}

my %dateconv = (
    # LastModified date         TZ offset   Expected
    "2009-04-07T00:42:37Z" => [ 7200,       "07/04/2009" ],
    "2009-04-06T23:42:37Z" => [ 3*3600,     "07/04/2009" ],
);

my %datesStr = (
    "not a date"      => 'not a date',
    "7/8/15 11:11 PM" => '08/07/2015',
    "7/31/09 9:18 AM" => '31/07/2009',
    "1/13/10 6:16 PM" => '13/01/2010',
    "04/09/11 22:42"  => '09/04/2011'
);

plan tests =>
    scalar (keys %system_profiler_tests) +
    scalar @ioreg_tests
    + 6 * scalar(keys %xmlparsing) + 3 * scalar(grep { $xmlparsing{$_}->{flatfile} } keys(%xmlparsing))
    + scalar (keys %dateconv)
    + scalar (keys %datesStr)
    + 1;

foreach my $test (keys %system_profiler_tests) {
    my $file = "resources/macos/system_profiler/$test";
    my $infos = getSystemProfilerInfos(file => $file, format => 'text');
    cmp_deeply($infos, $system_profiler_tests{$test}, "$test system profiler parsing");
}

foreach my $test (@ioreg_tests) {
    my $file = "resources/macos/ioreg/$test->{file}";
    my @devices = getIODevices(file => $file, class => $test->{class});
    cmp_deeply(\@devices, $test->{results}, "$test->{file} ioreg parsing");
}

foreach my $test (keys(%xmlparsing)) {
    my $type = 'SPApplicationsDataType';

    if ($xmlparsing{$test}->{flatfile}) {
        my $flatFile = 'resources/macos/system_profiler/'.$xmlparsing{$test}->{flatfile};
        my $softwaresFromFlatFile = GLPI::Agent::Tools::MacOS::getSystemProfilerInfos(file => $flatFile, type => $type);

        ok (ref($softwaresFromFlatFile) eq 'HASH');
        cmp_deeply(
            $softwaresFromFlatFile->{Applications},
            $xmlparsing{$test}->{list},
            "$test: flat file control"
        );

        my $softwaresFromFlatFileSize = scalar(keys %{$softwaresFromFlatFile->{'Applications'}});
        ok ($softwaresFromFlatFileSize == $xmlparsing{$test}->{count},
            "count: $softwaresFromFlatFileSize from flat file, expecting ".$xmlparsing{$test}->{count});
    }

    my $xmlFile = 'resources/macos/system_profiler/'.$xmlparsing{$test}->{xmlfile};
    my $softwaresFromXmlFile = GLPI::Agent::Tools::MacOS::getSystemProfilerInfos(
        file => $xmlFile,
        type => $type,
        format => 'xml',
        localTimeOffset => 7200
    );
    my $softwaresFromXmlFileSize = scalar(keys %{$softwaresFromXmlFile->{'Applications'}});

    ok (ref($softwaresFromXmlFile) eq 'HASH');
    cmp_deeply(
        $softwaresFromXmlFile->{Applications},
        $xmlparsing{$test}->{list},
        "$test: XML file control"
    );
    ok ($softwaresFromXmlFileSize == $xmlparsing{$test}->{count},
        "count: $softwaresFromXmlFileSize from XML file, expecting ".$xmlparsing{$test}->{count});

    my $softs = GLPI::Agent::Tools::MacOS::_extractSoftwaresFromXml(
        file => $xmlFile,
        localTimeOffset => 7200
    );
    ok (ref($softs) eq 'HASH');
    cmp_deeply(
        $softs,
        $xmlparsing{$test}->{list},
        "$test: XML file API control"
    );
    my $count = keys(%{$softs});
    ok ($count == $xmlparsing{$test}->{count},
        "extracted count: $count from XML file, expecting ".$xmlparsing{$test}->{count});
}

foreach my $date (keys(%dateconv)) {
    my $convertedDate = GLPI::Agent::Tools::MacOS::_getOffsetDate($date, $dateconv{$date}->[0]);
    ok ($convertedDate eq $dateconv{$date}->[1], $date . ': ' . $convertedDate . ' eq ' . $dateconv{$date}->[1] . ' ?');
}

for my $dateStr (keys(%datesStr)) {
    my $formatted = GLPI::Agent::Tools::MacOS::_formatDate($dateStr);
    ok ($formatted eq $datesStr{$dateStr}, "'" . $datesStr{$dateStr} ."' expected but got '" . $formatted . "'");
}

SKIP : {
    skip 'MacOS specific test', 1 unless $OSNAME eq 'darwin';

    my $boottime = getBootTime();
    ok ($boottime);
}
