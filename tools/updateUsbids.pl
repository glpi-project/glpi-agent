#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use lib 'tools';

use LWP::UserAgent;

use Changelog;
use GLPI::Agent::Tools;

my $ua = LWP::UserAgent->new();

my $response = $ua->mirror(
    "http://www.linux-usb.org/usb.ids",
    "share/usb.ids"
);

if ($response->status_line =~ /Not Modified/) {
    print "share/usb.ids is still up-to-date\n";
    exit(0);
}

die unless $response->is_success();

my $version = getFirstMatch(
    file    => "share/usb.ids",
    pattern => qr/^#\s+Version:\s+([0-9.]+)/,
);

my $previous = getFirstMatch(
    file    => "Changes",
    pattern => qr/Updated usb.ids to ([0-9.]+) version/,
);

if ($version eq $previous) {
    print "share/usb.ids was still up-to-date\n";
    exit(0);
}

my $Changes = Changelog->new( file => "Changes" );
$Changes->add( inventory => "Updated usb.ids to $version version" );
$Changes->write();
