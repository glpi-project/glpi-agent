#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::SNMP::Mock;
use GLPI::Agent::SNMP::Device;
use GLPI::Agent::SNMP::MibSupport::Force10S;


my $components = [
    {
        'CONTAINEDININDEX' => '0',
        'INDEX'            => '-1',
        'NAME'             => 'Force10 S-series Stack',
        'TYPE'             => 'stack',
    },
    {
        'CONTAINEDININDEX' => '-1',
        'DESCRIPTION'      => '48-port E/FE/GE (SB)',
        'FIRMWARE'         => '8.4.2.7',
        'INDEX'            => '1',
        'MODEL'            => 'S50-01-GE-48T-AC',
        'NAME'             => '0',
        'REVISION'         => 'D',
        'SERIAL'           => 'DL250170022',
        'TYPE'             => 'chassis',
    },
    {
        'CONTAINEDININDEX' => '-1',
        'DESCRIPTION'      => '48-port E/FE/GE (SB)',
        'FIRMWARE'         => '8.4.2.7',
        'INDEX'            => '2',
        'MODEL'            => 'S50-01-GE-48T-AC',
        'NAME'             => '1',
        'REVISION'         => 'E',
        'SERIAL'           => 'DL251050115',
        'TYPE'             => 'chassis',
    },
    {
        'CONTAINEDININDEX' => '-1',
        'DESCRIPTION'      => '48-port E/FE/GE (SB)',
        'FIRMWARE'         => '8.4.2.7',
        'INDEX'            => '3',
        'MODEL'            => 'S50-01-GE-48T-AC',
        'NAME'             => '2',
        'REVISION'         => 'D',
        'SERIAL'           => 'DL253170068',
        'TYPE'             => 'chassis',
    },
    {
        'CONTAINEDININDEX' => '-1',
        'DESCRIPTION'      => '48-port E/FE/GE (SB)',
        'FIRMWARE'         => '8.4.2.7',
        'INDEX'            => '4',
        'MODEL'            => 'S50-01-GE-48T-AC',
        'NAME'             => '3',
        'REVISION'         => 'D',
        'SERIAL'           => 'DL253170039',
        'TYPE'             => 'chassis',
    },
    {
        'CONTAINEDININDEX' => '-1',
        'DESCRIPTION'      => '48-port E/FE/GE (SB)',
        'FIRMWARE'         => '8.4.2.7',
        'INDEX'            => '5',
        'MODEL'            => 'S50-01-GE-48T-AC',
        'NAME'             => '4',
        'REVISION'         => 'D',
        'SERIAL'           => 'DL253170089',
        'TYPE'             => 'chassis',
    },
    {
        'CONTAINEDININDEX' => '-1',
        'DESCRIPTION'      => '48-port E/FE/GE (SB)',
        'FIRMWARE'         => '8.4.2.7',
        'INDEX'            => '6',
        'MODEL'            => 'S50-01-GE-48T-AC',
        'NAME'             => '5',
        'REVISION'         => 'D',
        'SERIAL'           => 'DL253170071',
        'TYPE'             => 'chassis',
    },
    {
        'CONTAINEDININDEX' => '-1',
        'DESCRIPTION'      => '48-port E/FE/GE (SB)',
        'FIRMWARE'         => '8.4.2.7',
        'INDEX'            => '7',
        'MODEL'            => 'S50-01-GE-48T-AC',
        'NAME'             => '6',
        'REVISION'         => 'E',
        'SERIAL'           => 'DL251050010',
        'TYPE'             => 'chassis',
    },
    {
        'CONTAINEDININDEX' => '-1',
        'DESCRIPTION'      => '48-port E/FE/GE (SB)',
        'FIRMWARE'         => '8.4.2.7',
        'INDEX'            => '8',
        'MODEL'            => 'S50-01-GE-48T-AC',
        'NAME'             => '7',
        'REVISION'         => 'E',
        'SERIAL'           => 'DL251280022',
        'TYPE'             => 'chassis',
    },
    {
        'CONTAINEDININDEX' => '1',
        'INDEX'            => '34653186',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '1',
        'INDEX'            => '34391042',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '1',
        'INDEX'            => '34128898',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '2',
        'INDEX'            => '67945474',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '2',
        'INDEX'            => '68207618',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '2',
        'INDEX'            => '67683330',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '3',
        'INDEX'            => '101237762',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '3',
        'INDEX'            => '101499906',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '3',
        'INDEX'            => '101762050',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '4',
        'INDEX'            => '135316482',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '4',
        'INDEX'            => '135054338',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '4',
        'INDEX'            => '134792194',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '5',
        'INDEX'            => '168870914',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '5',
        'INDEX'            => '168346626',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '5',
        'INDEX'            => '168608770',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '6',
        'INDEX'            => '202163202',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '6',
        'INDEX'            => '202425346',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '6',
        'INDEX'            => '201901058',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '7',
        'INDEX'            => '235979778',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '7',
        'INDEX'            => '235717634',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '7',
        'INDEX'            => '235455490',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '8',
        'INDEX'            => '269009922',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '8',
        'INDEX'            => '269534210',
        'TYPE'             => 'port',
    },
    {
        'CONTAINEDININDEX' => '8',
        'INDEX'            => '269272066',
        'TYPE'             => 'port',
    },
];

plan tests => 2;

my $snmp = GLPI::Agent::SNMP::Mock->new(
    file => "resources/walks/force10s.walk"
);
my $device = GLPI::Agent::SNMP::Device->new('snmp' => $snmp);
my $mibsupport = GLPI::Agent::SNMP::MibSupport::Force10S->new('device' => $device);

cmp_bag(
    $components,
    $mibsupport->getComponents()
);
