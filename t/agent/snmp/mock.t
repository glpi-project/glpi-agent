#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;

use GLPI::Agent::SNMP::Mock;

my %walks = (
    sample1 => {
        get => {
            '.1.3.6.1.2.1.1.5.0' => 'oyapock CR2', # Hostname
            '.1.3.6.1.2.1.1.6.0' => 'datacenter', # Location
            '.1.3.6.1.6.3.18.1.1.1.4.49' => '0x0000000B0000001871C1E000'
        },
        walk => {
            '.1.0.8802.1.1.2.1.3.7.1.2' => {
                '2' => '7',
                '1' => '7',
                '4' => '7',
                '3' => '7',
                '6' => '7',
                '5' => '7'
            }
        }
    },
    sample2 => {
        get => {
            '.1.3.6.1.2.1.1.1.0' => 'RICOH Aficio MP 171 1.00.1 / RICOH Network Printer C model / RICOH Network Scanner C model / RICOH Network Facsimile C model', # SysDescr
            # '.1.3.6.1.2.1.1.3.0' => '(950925200) 110 days, 1:27:32.00', # Uptime
            '.1.3.6.1.2.1.1.5.0' => 'Aficio MP 171' # Hostname
        },
        walk => {
        }
    },
    sample3 => {
        get => {
            '.1.3.6.1.2.1.1.3.0' => '11 days, 20:03:20.32', # Uptime
            '.1.3.6.1.2.1.2.2.1.2.1' => 'AL-CX11 Hard Ver.1.00 Firm Ver.2.30', # SysDescr
            '.1.3.6.1.2.1.1.5.0' => 'AL-CX11-CF9D9F' # Hostname
        },
        walk => {
        }
    },
    sample5 => {
        get => {
            '.1.3.6.1.2.1.1.1.0' => 'H3C Comware Platform Software, Software Version 5.20 Release 2208
H3C S5500-52C-EI
Copyright (c) 2004-2010 Hangzhou H3C Tech. Co., Ltd. All rights reserved.'
        }
    }
);

my $testCpt;
foreach my $test (keys %walks) {
    foreach (qw/get walk/) {
        $testCpt += keys (%{$walks{$test}->{$_}});
    }
}

plan tests => $testCpt;

foreach my $walk (keys %walks) {
    my $snmp = GLPI::Agent::SNMP::Mock->new(
        file => "resources/walks/$walk.walk"
    );

    foreach my $oid (keys %{$walks{$walk}->{get}}) {
        is($snmp->get($oid), $walks{$walk}->{get}{$oid}, $oid);
    }

    foreach my $oid (keys %{$walks{$walk}->{walk}}) {
        cmp_deeply($snmp->walk($oid), $walks{$walk}->{walk}{$oid}, $oid);
    }

}
