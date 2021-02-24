#!/usr/bin/perl

use strict;
use warnings;

use UNIVERSAL::require;

my $distfile = shift @ARGV;

die "Argument must be an existing glpi-agent archive release file\n"
    unless ($distfile && -e $distfile);

unless ($distfile) {
    ($distfile) = qx/egrep '^DISTVNAME =' Makefile/ =~ /^DISTVNAME = (.*)$/;
    $distfile .= ".tar.gz";
    die "Distribution file was not generated\n"
        unless $distfile && -e $distfile;
}

die "Module::CPANTS::Analyse required\n"
    unless Module::CPANTS::Analyse->require();
Module::CPANTS::Analyse->import();

my $analyser = Module::CPANTS::Analyse->new({
    dist    => $distfile,
});
my $kwalitee = $analyser->run;

my $max_kwalitee = keys(%{$kwalitee->{kwalitee}}) - 1;

print "Kwalitee: ", $kwalitee->{kwalitee}->{kwalitee}, "/$max_kwalitee\n";

my @keys = sort grep { !$kwalitee->{kwalitee}->{$_} } keys(%{$kwalitee->{kwalitee}});
foreach my $key (@keys) {
    print "failure: $key\n";
}

if ($kwalitee->{error}) {
    @keys = sort keys(%{$kwalitee->{error}});
    foreach my $key (@keys) {
        print "error($key):\n";
        my $error = $kwalitee->{error}->{$key};
        if (ref($error) eq 'ARRAY') {
            print map { " - $_\n" } @{$error};
        } else {
            print " - $error\n";
        }
    }
}
