#! /usr/bin/perl

use strict;
use warnings;

use JSON;
use LWP::UserAgent;
use Digest::SHA qw($errmsg);
use English qw(-no_match_vars);

unless ($ENV{VT_API_KEY}) {
    print STDERR "Set VT_API_KEY environment variable to your VirusTotal API Key if you want to check VirtusTotal reports.\n";
    exit(0);
}

my %sha256;
my $path;
my $debug = scalar(grep { /^--debug$/ } @ARGV);

while (@ARGV) {
    my $arg = shift @ARGV;
    if ($arg =~ /^--sha256$/) {
        my $sha256 = shift @ARGV;
        $sha256{$sha256} = "";
    } elsif ($arg =~ /^--debug$/) {
        $debug = 1;
    } elsif ($arg =~ /^--path$/) {
        $path = shift @ARGV;
        chdir $path
            or die "Can't change directory to $path: $!\n";
    } elsif (-e $arg) {
        my $digest = eval { Digest::SHA->new(256)->addfile($arg, "b") };
        if ($@) {
            warn "shasum: $arg: $errmsg\n" if $errmsg;
            next;
        }
        my $sha256 = $digest->hexdigest();
        print "debug: $arg sha256: $sha256\n" if $debug;
        $sha256{$sha256} = " for $arg";
    } else {
        print STDERR "No such '$arg' file\n";
    }
}

my @sha256 = keys(%sha256);
unless (@sha256) {
    print STDERR "No VirusTotal report to verify\n";
    exit(2);
}

my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1 });
my $baseurl = 'https://www.virustotal.com/api/v3/files';
my @failed;

my $first    = scalar(@sha256);
my $try      = 20 * $first;
my $nexttry  = 0;
my $timeout  = time + 600;
my $waittime = 15;
my %report;

while (time < $timeout && @sha256 && $try) {
    if (time > $nexttry) {
        my $sha256 = shift @sha256;
        my $url = "$baseurl/$sha256";
        print localtime().": debug: requesting $url...\n" if $debug;
        my $response = $ua->get( $url, 'x-apikey' => $ENV{VT_API_KEY});
        $nexttry = time + (--$first > 0 ? 0 : $waittime);
        if ($response->is_success) {
            my $content = $response->content;
            if ($content) {
                my $json = JSON->new->allow_nonref->decode($content);
                if ($json) {
                    # We expect to find VBA32 in results as we got false positive with that editor in the past
                    if (exists($json->{data}->{attributes}->{last_analysis_results}->{VBA32})) {
                        my $stat = $json->{data}->{attributes}->{last_analysis_stats};
                        if ($stat) {
                            if ($stat->{suspicious} || $stat->{malicious}) {
                                push @failed, $sha256;
                                print localtime().": Got malicious analysis reporting".$sha256{$sha256}."\n";
                                print "::warning title=Malicous analysis reporting$sha256{$sha256}::See https://www.virustotal.com/gui/file/$sha256\n";
                            } else {
                                print localtime().": No malicious analysis reporting".$sha256{$sha256}."\n";
                            }
                        } else {
                            warn localtime().": $url error: No expected stats data in '".JSON->new->allow_nonref->pretty->encode($json)."'\n";
                        }
                        my $handle;
                        if (open $handle, ">", "$sha256.json") {
                            print $handle $content;
                            close($handle);
                        } else {
                            warn localtime().": Can't write $sha256.json to $path: $!\n";
                        }
                        # Don't try to get next report for that sha256
                        undef $sha256;
                    } elsif ($json->{error} && $json->{error}->{code}) {
                        print localtime().": Report error code".$sha256{$sha256}.": ".$json->{error}->{code}."\n";
                    } else {
                        print localtime().": Analysis is running".$sha256{$sha256}."\n";
                    }
                } else {
                    warn localtime().": $url error: No json decoded from '$content'\n";
                }
            } else {
                warn localtime().": $url error: No content\n";
            }
        } else {
            warn localtime().": $url error: ".$response->status_line."\n";
        }
        push @sha256, $sha256 if defined($sha256);
        $try--;
    }
    sleep 1;
}

if (@failed) {
    print localtime().": Got malicious VirusTotal analysis reporting for ".scalar(@failed)." file".(@failed > 1 ? "s" : "").".\n";
} else {
    print localtime().": VirusTotal analysis reporting seems good.\n";
}

exit(0);
