#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;
use Test::MockModule;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::AIX::Bios;

my %tests = (
    'aix-5.3a' => {
        UnameL  => "",
        infos   => {
            BMANUFACTURER => 'IBM',
            SMANUFACTURER => 'IBM',
            BVERSION      => 'SF240_202',
            SSN           => '65DEDAB',
            SMODEL        => '9111-520',
        }
    },
    'aix-5.3b' => {
        UnameL  => "",
        infos   => {
            BMANUFACTURER => 'IBM',
            SMANUFACTURER => 'IBM',
            BVERSION      => 'MB245_300_008',
            SSN           => '99DXY4Y',
            SMODEL        => '8844-31X',
        }
    },
    'aix-5.3c' => {
        UnameL  => "",
        infos   => {
            BMANUFACTURER => 'IBM',
            SMANUFACTURER => 'IBM',
            BVERSION      => 'EA350_074',
            SSN           => '106BDCA',
            SMODEL        => '7778-23X',
        }
    },
    'aix-6.1a' => {
        UnameL  => "",
        infos   => {
            BMANUFACTURER => 'IBM',
            SMANUFACTURER => 'IBM',
            BVERSION      => 'AL710_099',
            SSN           => '10086CP',
            SMODEL        => '8233-E8B',
        }
    },
    'aix-6.1b' => {
        UnameL  => "",
        infos   => {
            BMANUFACTURER => 'IBM',
            SMANUFACTURER => 'IBM',
            BVERSION      => 'EA350_038',
            SSN           => '066B96A',
            SMODEL        => '7998-60X',
        }
    },
    'aix-6.1b sample1' => {
        UnameL  => "1234 sample1",
        infos   => {
            BMANUFACTURER => 'IBM',
            SMANUFACTURER => 'IBM',
            BVERSION      => 'EA350_038',
            SSN           => 'aixlpar-066B96A-sample1',
            SMODEL        => '7998-60X',
        }
    },
    'aix-6.1b no-lparstat' => {
        UnameL  => "1234 no-lparstat",
        infos   => {
            BMANUFACTURER => 'IBM',
            SMANUFACTURER => 'IBM',
            BVERSION      => 'EA350_038',
            SSN           => 'aixlpar-066B96A-1234',
            SMODEL        => '7998-60X',
        }
    },
    'ibm-7040-681' => {
        UnameL  => "",
        infos   => {
            BMANUFACTURER => 'IBM',
            SMANUFACTURER => 'IBM',
            BVERSION      => '3H041021',
            SSN           => '835A7AA',
            SMODEL        => '7040-681',
        }
    },
    'ibm-9080-m9s' => {
        UnameL  => "",
        infos   => {
            BMANUFACTURER => 'IBM',
            SMANUFACTURER => 'IBM',
            BVERSION      => 'VH950_099',
            SSN           => '45XY777',
            SMODEL        => '9080-M9S',
        }
    },
);

plan tests => (2 * scalar keys %tests) + 1;

my $module = Test::MockModule->new(
    'GLPI::Agent::Task::Inventory::AIX::Bios'
);

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my ($file) = $test =~ /^(\S+)/;
    my $lsvpd_file  = "resources/aix/lsvpd/$file";
    my $lsconf_file = "resources/aix/lsconf/$file";
    my $UnameL        = $tests{$test}->{UnameL} // "";
    my $lparstat_file = $UnameL =~ /^\d+\s+(\S+)/ ? "resources/aix/lparstat/$1" : "";

    # Fake Uname("-L") & getFirstMatch() calls
    $module->mock(
        'Uname',
        sub {
            return $UnameL;
        }
    );
    $module->mock(
        'getFirstMatch',
        sub {
            return $module->original('getFirstMatch')->(@_, file => $lparstat_file);
        }
    );

    # We also have to force file loading while using lsconf
    $module->mock(
        'getLsconfInfos',
        sub {
            return $module->original('getLsconfInfos')->(@_, file => $lsconf_file);
        }
    );

    my $infos = GLPI::Agent::Task::Inventory::AIX::Bios::_getInfos(file => $lsvpd_file);
    cmp_deeply($infos, $tests{$test}->{infos}, "$test: parsing");

    lives_ok {
        $inventory->setBios($infos);
    } "$test: registering";
}
