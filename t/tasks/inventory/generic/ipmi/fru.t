#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Generic::Dmidecode::Psu;
use GLPI::Agent::Task::Inventory::Generic::Ipmi::Fru::Psu;

my %tests = (
    '1' => {
        dmidecode   => [],
        fru         => [
            {
                PARTNUM        => '05NF18',
                SERIALNUMBER   => 'CN1797238QA8B4',
                MANUFACTURER   => 'Dell',
                NAME           => 'PWR SPLY,750WP,RDNT,DELTA',
            },
            {
                PARTNUM        => '05NF18',
                SERIALNUMBER   => 'CN1797238QA8EI',
                MANUFACTURER   => 'Dell',
                NAME           => 'PWR SPLY,750WP,RDNT,DELTA',
            },
        ]
    },
    '2' => {
        dmidecode   => [],
        fru         => [],
    },
    '3' => {
        dmidecode   => [],
        fru         => [],
    },
    '4' => {
        dmidecode   => [],
        fru         => [
            {
                PARTNUM        => 'H66158-007',
                SERIALNUMBER   => 'CNS2221A4SG7Q0942',
                MANUFACTURER   => 'Samsung',
                NAME           => 'PSSF222201A',
            },
            {
                PARTNUM        => 'H66158-007',
                SERIALNUMBER   => 'CNS2221A4SG7Q0944',
                MANUFACTURER   => 'Samsung',
                NAME           => 'PSSF222201A',
            },
        ],
    },
);

plan tests => 4 *(scalar keys %tests) + 1;

foreach my $index (keys %tests) {
    my $dmidecode = "resources/generic/powersupplies/dmidecode_$index.txt";
    my $inventory = GLPI::Test::Inventory->new();

    lives_ok {
        GLPI::Agent::Task::Inventory::Generic::Dmidecode::Psu::doInventory(
            inventory   => $inventory,
            file        => $dmidecode
        );
    } "test $index: dmidecode runInventory()";

    my $psu = $inventory->getSection('POWERSUPPLIES') || [];
    my @psu = sort { ($a->{SERIALNUMBER}||'') cmp ($b->{SERIALNUMBER}||'') } @{$psu};
    cmp_deeply(
        \@psu,
        $tests{$index}->{dmidecode},
        "test $index: parsing dmidecode"
    );

    my $fru = "resources/generic/powersupplies/fru_$index.txt";
    lives_ok {
        GLPI::Agent::Task::Inventory::Generic::Ipmi::Fru::Psu::doInventory(
            inventory   => $inventory,
            file        => $fru
        );
    } "test $index: runInventory(s)";

    $psu = $inventory->getSection('POWERSUPPLIES') || [];
    @psu = sort { ($a->{SERIALNUMBER}||'') cmp ($b->{SERIALNUMBER}||'') } @{$psu};
    cmp_deeply(
        \@psu,
        $tests{$index}->{fru},
        "test $index: parsing fru"
    );
}
