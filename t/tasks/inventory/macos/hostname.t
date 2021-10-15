#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::MacOS::Hostname;

my %tests = (
    '10.6-system_profiler_Software_SPSoftwareDataType' => 'mac-fusion01'
);

plan tests => (scalar keys %tests) + 1;

my $pathToResourcesDir = 'resources/macos/system_profiler/';
foreach my $fileName (keys %tests) {
    my $filePath = $pathToResourcesDir . $fileName;
    my $hostname = GLPI::Agent::Task::Inventory::MacOS::Hostname::_getHostname(
        file => $filePath,
        format => 'text'
    );
    ok ($hostname eq $tests{$fileName}, "$fileName text _getHostname() API");
}
