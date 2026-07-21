#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use File::Temp;

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::AntiVirus::Wazuh;

my %sample = (
    wazuh_version   => 'WAZUH_VERSION="v4.14.5"
WAZUH_REVISION="rc1"
WAZUH_TYPE="agent"
',
    wazuh_status    => 'wazuh-modulesd is running...
wazuh-logcollector is running...
wazuh-syscheckd is running...
wazuh-agentd is running...
wazuh-execd is running...
');

my %av_outputs = (
    'wazuh-4.14.5' => {
        %sample,
    },
);

my %av_tests = (
    'wazuh-4.14.5' => {
        COMPANY         => "Wazuh, Inc.",
        NAME            => "Wazuh Agent",
        ENABLED         => 1,
        UPTODATE        => 1,
        VERSION         => "4.14.5",
    },
);

plan tests =>
    (2 * scalar keys %av_tests) +
    1;

foreach my $test (keys %av_tests) {
    my $inventory = GLPI::Test::Inventory->new();

    my $antivirus = GLPI::Agent::Task::Inventory::Linux::AntiVirus::Wazuh::_getWazuhInfo(
        %{$av_outputs{$test}},
    );

    cmp_deeply($antivirus, $av_tests{$test}, "$test: parsing");

    lives_ok {
        $inventory->addEntry(section => 'ANTIVIRUS', entry => $antivirus);
    } "$test: registering";
}
