#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use lib 'tools';

use LWP::UserAgent;

use Changelog;
use GLPI::Agent::Tools;

# Touch pci.ids file with stored date to make mirror API works as expected
my ($date, $time) = getFirstMatch(
    file    => "share/pci.ids",
    pattern => qr/^#\s+Date:\s+([0-9-]+)\s+([0-9:]+)/,
);
system("touch -d '$date $time' share/pci.ids") if $date && $time;

my $ua = LWP::UserAgent->new();

my $response;

foreach my $url (qw(
    https://raw.githubusercontent.com/pciutils/pciids/master/pci.ids
    https://pci-ids.ucw.cz/v2.2/pci.ids
)) {
    $response = $ua->mirror(
        $url,
        "share/pci.ids"
    );
    last if $response->is_success();
}

if ($response->status_line =~ /Not Modified/) {
    print "share/pci.ids is still up-to-date\n";
    exit(0);
}

die "pci.ids not found in mirrors\n" unless $response->is_success();

my $version = getFirstMatch(
    file    => "share/pci.ids",
    pattern => qr/^#\s+Version:\s+([0-9.]+)/,
);

my $previous = getFirstMatch(
    file    => "Changes",
    pattern => qr/Updated pci.ids to ([0-9.]+) version/,
);

if ($version eq $previous) {
    print "share/pci.ids was still up-to-date\n";
    exit(0);
}

my $Changes = Changelog->new( file => "Changes" );
$Changes->add( inventory => "Updated pci.ids to $version version" );
$Changes->write();
