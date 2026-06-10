#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::More;
use Test::MockModule;
use UNIVERSAL::require;

use GLPI::Test::Utils;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

use Config;
# check thread support availability
if (!$Config{usethreads} || $Config{usethreads} ne 'define') {
    plan skip_all => 'thread support required';
}

Test::NoWarnings->use();

GLPI::Agent::Task::Inventory::Win32::Networks->require();

my %tests = (
    xp => {
        'PCI\VEN_1022&DEV_2000&SUBSYS_20001022&REV_10\\4&47B7341&0&0088' => 'ethernet',
        'ROOT\\MS_PSCHEDMP\\0001' => undef,
        'ROOT\\MS_PSCHEDMP\\0002' => undef,
        'ROOT\\MS_PSCHEDMP\\0003' => undef,
        'ROOT\\MS_PPTPMINIPORT\\0000' => undef,
        'ROOT\\MS_PPPOEMINIPORT\\0000' => undef
    },
);

my $plan = 3; # Base 1 + 2 tests for bluetooth info
foreach my $test (keys %tests) {
    $plan += scalar (keys %{$tests{$test}});
}
plan tests => $plan;

foreach my $test (keys %tests) {

    my $file = "resources/win32/registry/$test-{4D36E972-E325-11CE-BFC1-08002BE10318}.reg";
    my $keys = loadRegistryDump($file);

    my $api_module = Test::MockModule->new('Win32::API');
    $api_module->mock('new', sub {
        my ($class, $dll, $func, $in, $out) = @_;
        my $self = { func => $func };
        return bless $self, 'Mock::Win32::API';
    });

    # Define the Mock package for Call
    {
        no warnings 'redefine';
        package Mock::Win32::API;
        sub Call {
            my ($self, @args) = @_;
            if ($self->{func} eq 'CM_Locate_DevNodeW') {
                $_[1] = pack('L', 1234); # Fake devInst
                return 0;
            }
            if ($self->{func} eq 'CM_Get_Parent') {
                $_[1] = pack('L', 5678); # Fake parentInst
                return 0;
            }
            if ($self->{func} eq 'CM_Get_Device_IDW') {
                require Encode;
                my $encoded = Encode::encode('UTF-16LE', "USB\\VID_0BDA&PID_C829\\00E04C000001\0");
                substr($_[2], 0, length($encoded)) = $encoded;
                return 0;
            }
            return 1;
        }
    }

    my $net_module = Test::MockModule->new('GLPI::Agent::Tools::Win32');
    $net_module->mock('getWMIObjects', mockGetWMIObjects($test));

    foreach my $deviceId (keys %{$tests{$test}}) {
        is(
            GLPI::Agent::Task::Inventory::Win32::Networks::_getMediaType($deviceId, $keys),
            $tests{$test}->{$deviceId},
            "$test sample, $deviceId device"
        );
    }

    my $bt_info = GLPI::Agent::Task::Inventory::Win32::Networks::_getBluetoothParentInfo('BTH\MS_BTHPAN\6&1AAC2CAC&0&2');
    is($bt_info->{MANUFACTURER}, 'Realtek Semiconductor Corp.', "$test sample, Bluetooth parent manufacturer");
    is($bt_info->{MODEL}, 'Realtek Bluetooth Adapter', "$test sample, Bluetooth parent model");
}

