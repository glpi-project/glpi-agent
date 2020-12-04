#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;
use English;
use UNIVERSAL::require;

use FusionInventory::Agent::Tools::MacOS;
use FusionInventory::Agent::Task::Inventory::MacOS::Softwares;

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

my $versionNumbersComparisons = [
    ['10.8.0', '10.11'],
    ['5.22', '5.22.1'],
    ['5.8.9.2', '5.10.3'],
    ['5.4.2', '10.2']
];

plan tests =>
    scalar (keys %system_profiler_tests) +
    scalar @ioreg_tests
    + 11
    + scalar (@$versionNumbersComparisons);

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

my $type = 'SPApplicationsDataType';
my $flatFile = 'resources/macos/system_profiler/10.8-system_profiler_SPApplicationsDataType.example.txt';
my $softwaresFromFlatFile = FusionInventory::Agent::Tools::MacOS::_getSystemProfilerInfosText(file => $flatFile, type => $type);
my $xmlFile = 'resources/macos/system_profiler/10.8-system_profiler_SPApplicationsDataType_-xml.example.xml';
my $softwaresFromXmlFile = FusionInventory::Agent::Tools::MacOS::_getSystemProfilerInfosXML(file => $xmlFile, type => $type, localTimeOffset => 7200);

XML::XPath->require();
my $checkXmlXPath = $EVAL_ERROR ? 0 : 1;
SKIP : {
    skip 'test only if module XML::XPath available', 6 unless $checkXmlXPath;

    ok (ref($softwaresFromFlatFile) eq 'HASH');
    ok (ref($softwaresFromXmlFile) eq 'HASH');

    # because existing function returns only first line of data
    # and the new being tested here returns all lines
    # just a few deletions that don't remove the sense of these tests
    delete $softwaresFromFlatFile->{"Applications"}{"Wish"}{"Get\ Info\ String"};
    delete $softwaresFromXmlFile->{"Applications"}{"Wish"}{"Get\ Info\ String"};
    delete $softwaresFromFlatFile->{"Applications"}{"Wish_0"}{"Get\ Info\ String"};
    delete $softwaresFromXmlFile->{"Applications"}{"Wish_0"}{"Get\ Info\ String"};

    # before comparing, because with more recent method dates are already formatted,
    # we format dates in the other hash as it's currently done
    for my $soft (keys %{$softwaresFromFlatFile->{"Applications"}}) {
        if (defined($softwaresFromFlatFile->{"Applications"}->{$soft}->{'Last Modified'})) {
            my $formattedDate = FusionInventory::Agent::Task::Inventory::MacOS::Softwares::_formatDate($softwaresFromFlatFile->{"Applications"}->{$soft}->{'Last Modified'});
            $softwaresFromFlatFile->{"Applications"}->{$soft}->{'Last Modified'} = $formattedDate;
        }
    }

    cmp_deeply(
        $softwaresFromFlatFile,
        $softwaresFromXmlFile
    );
    my $softwaresFromFlatFileSize = scalar(keys %{$softwaresFromFlatFile->{'Applications'}});
    my $softwaresFromXmlFileSize = scalar(keys %{$softwaresFromXmlFile->{'Applications'}});
    ok ($softwaresFromFlatFileSize == $softwaresFromXmlFileSize,
        $softwaresFromFlatFileSize.' from flat file and '.$softwaresFromXmlFileSize.' from XML file');

    FusionInventory::Agent::Tools::MacOS::_initXmlParser(
        file => 'resources/macos/system_profiler/10.8-system_profiler_SPApplicationsDataType_-xml.example.xml'
    );
    my $softs = FusionInventory::Agent::Tools::MacOS::_extractSoftwaresFromXml(
        localTimeOffset => 7200
    );
    ok ($softs);
    ok (scalar(keys %$softs) == 291, 'must be 291 and is ' . scalar(keys %$softs));
}

my $extractedHash = {
    '_name' => "Programme d’installation",
    "has64BitIntelCode" => "yes",
    "info" => "3.0, Copyright © 2000-2006 Apple Computer Inc., All Rights Reserved",
    "lastModified" => "2009-06-27T06:18:49Z",
    "path" => "/System/Library/CoreServices/Installer.app",
    "runtime_environment" => "universal",
    "version" => "4.0"
};

my $expectedHash = {
    'Programme d’installation' => {
        '64-Bit (Intel)' => 'yes',
        'Get Info String'           => '3.0, Copyright © 2000-2006 Apple Computer Inc., All Rights Reserved',
        'Last Modified'  => '2009-06-27T06:18:49Z',
        'Location'       => '/System/Library/CoreServices/Installer.app',
        'Kind'           => 'universal',
        'Version'        => '4.0'
    }
};
my $hashMapped = FusionInventory::Agent::Tools::MacOS::_mapApplicationDataKeys($extractedHash);
cmp_deeply(
    $expectedHash,
    $hashMapped
);


my $dateStr = '2009-04-07T00:42:37Z';
my $dateExpectedStr = '07/04/2009';
my $offset = 7200;
my $convertedDate = FusionInventory::Agent::Tools::MacOS::_convertDateFromApplicationDataXml($dateStr, $offset);
ok ($dateExpectedStr eq $convertedDate, $dateExpectedStr . ' eq ' . $convertedDate . ' ?');

$dateStr = '2009-04-06T23:42:37Z';
$dateExpectedStr = '07/04/2009';
$offset = 3600 * 3;
$convertedDate = FusionInventory::Agent::Tools::MacOS::_convertDateFromApplicationDataXml($dateStr, $offset);
ok ($dateExpectedStr eq $convertedDate, $dateExpectedStr . ' eq ' . $convertedDate . ' ?');

sub _cmpVersionNumbers {
    my ($str1, $str2) = @_;

    my @list1 = reverse split(/\./, $str1);
    my @list2 = reverse split(/\./, $str2);

    my $cmp = 0;
    my $int1;
    while (
        $cmp == 0 && ($int1 = pop @list1)
    ) {
        $int1 = int($int1);
        my $int2 = pop @list2;
        if (defined $int2) {
            $int2 = int($int2);
            $cmp = $int1 <=> $int2;
        } else {
            $cmp = 1;
        }
    }
    # if $cmp is still 0 and list2 still contains values,
    # so $str2 is greater
    if ($cmp == 0 && (@list2) > 0) {
        $cmp = -1;
    }

    return $cmp;
}

for my $listVersionNumbers (@$versionNumbersComparisons) {
    my $cmp0vs1 = _cmpVersionNumbers($listVersionNumbers->[0], $listVersionNumbers->[1]);
    my $cmp1vs0 = _cmpVersionNumbers($listVersionNumbers->[1], $listVersionNumbers->[0]);
    ok (
        $cmp0vs1 == -1
        && $cmp1vs0 == 1
    );
}
ok (_cmpVersionNumbers('5.34.54', '5.34.54') == 0);

SKIP : {
    skip 'MacOS specific test', 1 unless $OSNAME eq 'darwin';

    my $boottime = getBootTime();
    ok ($boottime);
}
