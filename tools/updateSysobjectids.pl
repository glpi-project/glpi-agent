#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use lib 'tools';

use LWP::UserAgent;
use Digest::SHA;

use Changelog;
use FusionInventory::Agent::Tools;

my $ua = LWP::UserAgent->new();

my $sha = Digest::SHA->new(1);
$sha->addfile("share/sysobject.ids");
my $digest = $sha->hexdigest;

my $response = $ua->mirror(
    "https://raw.githubusercontent.com/fusioninventory/sysobject.ids/master/sysobject.ids",
    "share/sysobject.ids"
);

if ($response->status_line =~ /Not Modified/) {
    print "share/sysobject.ids is still up-to-date\n";
    exit(0);
}

die unless $response->is_success();

$sha = Digest::SHA->new(1);
$sha->addfile("share/sysobject.ids");
my $newdigest = $sha->hexdigest;

exit(0) if $digest eq $newdigest;

my $Changes = Changelog->new( file => "Changes" );
$Changes->add( "netdiscovery/netinventory" => "Updated sysobject.ids" );
$Changes->write();
