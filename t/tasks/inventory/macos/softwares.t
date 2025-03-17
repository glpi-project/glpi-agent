#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Data::Dumper;

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Tools qw(getAllLines);
use GLPI::Agent::Task::Inventory::MacOS::Softwares;

use English;

my %tests = (
    'sample1' => [ 349, 0 ], # [ Number of detected softwares, flag to trigger results file update ]
    'sample2' => [ 407, 0 ],
    'sample3' => [ 317, 0 ],
    'sample4' => [ 367, 0 ],
    'sample5' => [ 367, 0 ],
    'sample6' => [ 362, 0 ],
);

# Use a fixed local timezone offset
my $localTimeOffset = 7200;

plan tests => 3 * scalar (keys %tests)
    + 7;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (sort keys %tests) {
    my $results;
    my ($format, $file) = ("text", "resources/macos/system_profiler/$test.SPApplicationsDataType");
    if (-e $file."-xml") {
        # use "-xml" as extension as this is not critical and .xml is in root .gitignore
        $file .= "-xml";
        $format = "xml";
    }
    my $dump = $file.".results.txt";
    my $softwares = GLPI::Agent::Task::Inventory::MacOS::Softwares::_getSoftwaresList(
        file            => $file,
        format          => $format,
        localTimeOffset => $localTimeOffset
    );
    # Dump found result when still not integrated in test file
    my ($count, $update) = ref($tests{$test}) eq 'ARRAY' ? @{$tests{$test}} : (0, 1);
    unless ($count && !$update && -e $dump) {
        my $dumper = Data::Dumper->new([$softwares], ['results'])->Useperl(1)->Indent(1)->Sortkeys(1);
        $dumper->{xpad} = "    ";
        if (open my $fh, ">:encoding(utf8)", $dump) {
            print $fh "\nuse utf8;\n\n", $dumper->Dump();
            close($fh);
        }
        diag("$test: Dumped ".@{$softwares}." softwares into $dump");
    }
    if (-e $dump) {
        diag("$test: Loading just dumped softwares") if $update;
        $results = do "./$dump"
            or die "Failed to load results from $dump: $!\n";
    }
    if ($count && ref($results) eq 'ARRAY' && @{$results}) {
        is(scalar(@{$softwares}), $count, "test: Softwares count");
    } elsif ($count) {
        fail "$test: no results found in $dump";
    } else {
        fail "$test: ".@{$softwares}." softwares count not integrated";
    }
    cmp_deeply(
        $softwares,
        $results,
        "$test: parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'SOFTWARES', entry => $_)
            foreach @$softwares;
    } "$test: registering";
}

SKIP: {
    skip "Only if OS is darwin (Mac OS X) and command 'system_profiler' is available", 6
        unless $OSNAME eq 'darwin' && GLPI::Agent::Task::Inventory::MacOS::Softwares::isEnabled();

    my @hasSoftwareOutput = getAllLines(
        command => "/usr/sbin/system_profiler SPApplicationsDataType"
    );
    # On MacOSX, skip test as system_profiler may return no software in container, CircleCI case
    skip "No installed software seen on this system", 6
        if @hasSoftwareOutput == 0;

    my $softs = GLPI::Agent::Tools::MacOS::_getSystemProfilerInfosXML(
        type            => 'SPApplicationsDataType',
        localTimeOffset => GLPI::Agent::Tools::MacOS::detectLocalTimeOffset(),
        format => 'xml'
    );
    ok ($softs);
    ok (scalar(keys %$softs) > 0);

    my $infos = GLPI::Agent::Tools::MacOS::getSystemProfilerInfos(
        type            => 'SPApplicationsDataType',
        localTimeOffset => GLPI::Agent::Tools::MacOS::detectLocalTimeOffset(),
        format => 'xml'
    );
    ok ($infos);
    ok (scalar(keys %$infos) > 0);

    my $softwareHash = GLPI::Agent::Task::Inventory::MacOS::Softwares::_getSoftwaresList(
        format => 'xml',
    );
    ok (defined $softwareHash);
    ok (scalar(@{$softwareHash}) > 1);
}
