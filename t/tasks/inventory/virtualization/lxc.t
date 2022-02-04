#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::Deep;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::Virtualization::Lxc;
use GLPI::Agent::Tools::Virtualization;

my %result_lxc_info = (
    'lxc-info_-n_name1' => STATUS_RUNNING,
    'lxc-info_-n_name2' => STATUS_RUNNING,
);

my %container_tests = (
    config  => {
        version => 2.0,
        result  => {
            NAME    => 'config',
            VMTYPE  => 'lxc',
            STATUS  => STATUS_OFF,
            MEMORY  => '2048000',
            MAC     => '01:23:45:67:89:0a',
            VCPU    => 4
        }
    },
    'debian-hosting'  => {
        version => 3.0,
        result  => {
            NAME    => 'debian-hosting',
            VMTYPE  => 'lxc',
            STATUS  => STATUS_RUNNING,
            MAC     => '00:16:3e:c3:52:e4',
            VCPU    => 0
        }
    },
    'arch-linux'  => {
        version => 3.0,
        result  => {
            NAME    => 'arch-linux',
            VMTYPE  => 'lxc',
            STATUS  => STATUS_OFF,
            MAC     => '00:16:3e:1f:0b:1d',
            VCPU    => 3
        }
    },
    '200-proxmox'  => {
        version => 3.0,
        result  => {
            NAME    => 'glpi-10-rc1',
            VMTYPE  => 'lxc',
            STATUS  => STATUS_RUNNING,
            MAC     => 'fa:ee:26:ef:6b:1c',
            MEMORY  => 2147483648,
            VCPU    => 2
        }
    },
);

plan tests => keys(%result_lxc_info) + keys(%container_tests) + 1;

foreach my $file (keys(%result_lxc_info)) {
    my $state = GLPI::Agent::Task::Inventory::Virtualization::Lxc::_getVirtualMachineState(
        file => "resources/virtualization/lxc/$file"
    );
    is($state, $result_lxc_info{$file}, "checking $file LXC state");
}

foreach my $name (keys(%container_tests)) {
    my $file = "resources/virtualization/lxc/$name";
    $file =~ s|/|\\|g if $OSNAME eq "MSWin32";
    my $config = GLPI::Agent::Task::Inventory::Virtualization::Lxc::_getVirtualMachine(
        name          => $name =~ /(^.*)-proxmox$/ ? $1 : $name,
        version       => $container_tests{$name}->{version},
        test_cmdstate => $OSNAME eq "MSWin32" ? "type $file" : "cat $file",
        test_cmdinfo  => $OSNAME eq "MSWin32" ? "type $file" : "cat $file",
        config        => $file,
    );
    cmp_deeply($config, $container_tests{$name}->{result}, "checking $name lxc container");
}
