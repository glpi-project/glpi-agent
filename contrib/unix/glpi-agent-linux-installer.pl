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

my $version = InstallerVersion::VERSION();
if ($options->{version}) {
    print "GLPI-Agent installer for ", InstallerVersion::DISTRO(), " v$version\n";
    exit 0;
}

Archive->new()->list() if $options->{list};

my $uninstall = delete $options->{uninstall};
my $install   = delete $options->{install};
my $clean     = delete $options->{clean};
my $reinstall = delete $options->{reinstall};
my $extract   = delete $options->{extract};
$install = 1 unless (defined($install) || $uninstall || $reinstall || $extract);

die "--install and --uninstall options are mutually exclusive\n" if $install && $uninstall;
die "--install and --reinstall options are mutually exclusive\n" if $install && $reinstall;
die "--reinstall and --uninstall options are mutually exclusive\n" if $reinstall && $uninstall;

if ($install || $uninstall || $reinstall) {
    my $id = qx/id -u/;
    die "This installer can only be run as root when installing or uninstalling\n"
        unless $id =~ /^\d+$/ && $id == 0;
}

my $distro = LinuxDistro->new($options);

my $installed = $distro->installed;
my $bypass = $extract && $extract ne "keep" ? 1 : 0;
if ($installed && !$uninstall && !$reinstall && !$bypass && $version =~ /-git\w+$/ && $version ne $installed) {
    # Force installation for development version if still installed, needed for deb based distros
    $distro->verbose("Forcing installation of $version over $installed...");
    $distro->allowDowngrade();
}

$distro->uninstall($clean) if !$bypass && ($uninstall || $reinstall);

$distro->clean() if !$bypass && $clean && ($install || $uninstall || $reinstall);

unless ($uninstall) {
    my $archive = Archive->new();
    $distro->extract($archive, $extract);
    if ($install || $reinstall) {
        $distro->info("Installing glpi-agent v$version...");
        $distro->install();
    }
}

END {
    $distro->clean_packages() if $distro;
}

exit(0);
