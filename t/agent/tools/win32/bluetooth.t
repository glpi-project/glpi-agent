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

GLPI::Agent::Tools::Win32::Bluetooth->require();

plan tests => 3;

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
        if ($self->{func} eq 'CM_Get_Device_ID_Size') {
            # Simulate returning size 36
            $_[1] = pack('L', 36);
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
$net_module->mock('getWMIObjects', sub {
    return {
        Manufacturer => 'Realtek',
        Caption      => 'Realtek Bluetooth 4.0 Adapter'
    };
});

my $info = GLPI::Agent::Tools::Win32::Bluetooth::getBluetoothParentInfo("BTH\\MS_BTHPAN\\6&3600EB65&0&2");

is($info->{MANUFACTURER}, 'Realtek', 'Check manufacturer');
is($info->{MODEL}, 'Realtek Bluetooth 4.0 Adapter', 'Check model');
