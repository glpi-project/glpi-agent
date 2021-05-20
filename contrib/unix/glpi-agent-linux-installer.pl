#! /usr/bin/perl

use strict;
use warnings;

use lib 'installer';

use InstallerVersion;
use Getopt;
use LinuxDistro;
use RpmDistro;
use Archive;

BEGIN {
    $ENV{LC_ALL} = 'C';
    $ENV{LANG}="C";
}

die "This installer can only be run on linux systems, not on $^O\n"
    unless $^O eq "linux";

my $options = Getopt::GetOptions() or die Getopt::Help();
if ($options->{help}) {
    print Getopt::Help();
    exit 0;
}

if ($options->{version}) {
    print "GLPI-Agent installer for ", InstallerVersion::DISTRO(), " v", InstallerVersion::VERSION(), "\n";
    exit 0;
}

my $uninstall = delete $options->{uninstall};
my $install   = delete $options->{install};
my $clean     = delete $options->{clean};
my $reinstall = delete $options->{reinstall};
my $extract   = delete $options->{extract};
$install = 1 unless (defined($install) || $uninstall || $reinstall);

die "--install and --uninstall options are mutually exclusive\n" if $install && $uninstall;
die "--install and --reinstall options are mutually exclusive\n" if $install && $reinstall;
die "--reinstall and --uninstall options are mutually exclusive\n" if $reinstall && $uninstall;

my $distro = LinuxDistro->new($options);

$distro->uninstall($clean) if $uninstall || $reinstall;

$distro->clean() if $clean;

unless ($uninstall) {
    my $archive = Archive->new();
    $distro->extract($archive, $extract);
    $distro->info("Installing glpi-agent v".InstallerVersion::VERSION()."...");
    $distro->install() if $install || $reinstall;
}

exit(0);
