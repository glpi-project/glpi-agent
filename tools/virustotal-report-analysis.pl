#! /usr/bin/perl

use strict;
use warnings;

use JSON;
use LWP::UserAgent;

unless ($ENV{VT_API_KEY}) {
    print STDERR "Set VT_API_KEY environment variable to your VirusTotal API Key if you want to check VirtusTotal reports.\n";
    exit(0);
}

my @sha256;

while (@ARGV) {
    my $arg = shift @ARGV;
    if ($arg =~ /^--sha256$/) {
        push @sha256, shift @ARGV;
    } elsif (-e $arg) {
        my ($sha256) = split(" ", qx/sha256sum "$arg"/);
        push @sha256, $sha256;
    } else {
        print STDERR "No such '$_' file\n";
    }
}

unless (@sha256) {
    print STDERR "No VirusTotal report to verify\n";
    exit(2);
}

my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1 });
my $baseurl = 'https://www.virustotal.com/api/v3/files';
my @failed;

foreach my $sha256 (@sha256) {
    my $url = "$baseurl/$sha256";
    my $response = $ua->get( $url, 'x-apikey' => $ENV{VT_API_KEY});
    die "$url error: ".$response->status_line."\n"
       unless $response->is_success;

    my $content = $response->content
        or die "$url error: No content\n";
    my $json = JSON->new->allow_nonref->decode($content)
        or die "$url error: No json decoded from '$content'\n";
    die "$url error: No expected data in '".JSON->new->allow_nonref->pretty->encode($json)."'\n"
     unless $json->{data} && $json->{data}->{attributes} && $json->{data}->{attributes}->{last_analysis_stats};
    my $stat = $json->{data}->{attributes}->{last_analysis_stats};
    push @failed, $sha256 if $stat->{suspicious} || $stat->{malicious};
}

if (@failed) {
    die "VirusTotal check failure\n".join("\n", map { "See https://www.virustotal.com/gui/file/$_" } @failed)."\n";
} else {
    print "VirusTotal check is good.\n";
}

exit(0);
