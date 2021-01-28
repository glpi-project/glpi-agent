#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use lib 'tools';

use LWP::UserAgent;

use Changelog;
use FusionInventory::Agent::Tools;

my $ua = LWP::UserAgent->new();

my $response = $ua->mirror(
    "http://pciids.sourceforge.net/pci.ids",
    "share/pci.ids"
);

if ($response->status_line =~ /Not Modified/) {
    print "share/pci.ids is still up-to-date\n";
    exit(0);
}

die unless $response->is_success();

my $version = getFirstMatch(
    file    => "share/pci.ids",
    pattern => qr/^#\s+Version:\s+([0-9.]+)/,
);

my $Changes = Changelog->new( file => "Changes" );
$Changes->add( inventory => "Updated pci.ids to $version version" );
$Changes->write();
