#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Task::Inventory::MacOS::OS;

my %installdate = (
    'macos-10.15' => {
        time        => "1606739790",
        installdate => "2020-11-30 13:36:30"
    },
);

plan tests => (scalar keys %installdate) * 2 + 1;

foreach my $test (keys %installdate) {
    my $file = "resources/macos/files/$test-install.log";
    my $time = GLPI::Agent::Task::Inventory::MacOS::OS::_getInstallDate(file => $file);
    my $installdate = GLPI::Agent::Task::Inventory::MacOS::OS::getFormatedLocalTime($time);
    is($time, $installdate{$test}->{time}, "$test time");
    is($installdate, $installdate{$test}->{installdate}, "$test installdate");
}
