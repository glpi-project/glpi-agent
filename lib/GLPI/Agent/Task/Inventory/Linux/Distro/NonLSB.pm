package GLPI::Agent::Task::Inventory::Linux::Distro::NonLSB;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

# This array contains four items for each distribution:
# - release file
# - distribution name,
# - regex to get the version
# - template to get the full name
my @distributions = (
    # vmware-release contains something like "VMware ESX Server 3" or "VMware ESX 4.0 (Kandinsky)"
    [ '/etc/vmware-release',    'VMWare',                     '([\d.]+)',         '%s' ],

    [ '/etc/arch-release',      'ArchLinux',                  '(.*)',             'ArchLinux' ],

    [ '/etc/debian_version',    'Debian',                     '(.*)',             'Debian GNU/Linux %s'],

    # fedora-release contains something like "Fedora release 9 (Sulphur)"
    [ '/etc/fedora-release',    'Fedora',                     'release ([\d.]+)', '%s' ],

    [ '/etc/gentoo-release',    'Gentoo',                     '(.*)',             'Gentoo Linux %s' ],

    # knoppix_version contains something like "3.2 2003-04-15".
    # Note: several 3.2 releases can be made, with different dates, so we need to keep the date suffix
    [ '/etc/knoppix_version',   'Knoppix',                    '(.*)',             'Knoppix GNU/Linux %s' ],

    # mandriva-release contains something like "Mandriva Linux release 2010.1 (Official) for x86_64"
    [ '/etc/mandriva-release',  'Mandriva',                   'release ([\d.]+)', '%s'],

    # mandrake-release contains something like "Mandrakelinux release 10.1 (Community) for i586"
    [ '/etc/mandrake-release',  'Mandrake',                   'release ([\d.]+)', '%s'],

    # oracle-release contains something like "Oracle Linux Server release 6.3"
    [ '/etc/oracle-release',    'Oracle Linux Server',        'release ([\d.]+)', '%s' ],

    # centos-release contains something like "CentOS Linux release 6.0 (Final)
    [ '/etc/centos-release',    'CentOS',                     'release ([\d.]+)', '%s' ],

    # redhat-release contains something like "Red Hat Enterprise Linux Server release 5 (Tikanga)"
    [ '/etc/redhat-release',    'RedHat',                     'release ([\d.]+)', '%s' ],

    [ '/etc/slackware-version', 'Slackware',                  'Slackware (.*)',   '%s' ],

    # SuSE-release contains something like "SUSE Linux Enterprise Server 11 (x86_64)"
    # Note: it may contain several extra lines
    [ '/etc/SuSE-release',      'SuSE',                       '([\d.]+)',         '%s' ],

    # trustix-release contains something like "Trustix Secure Linux release 2.0 (Cloud)"
    [ '/etc/trustix-release',   'Trustix',                    'release ([\d.]+)', '%s' ],

    # Fallback
    [ '/etc/issue',             'Unknown Linux distribution', '([\d.]+)'        , '%s' ],

    # Note: Ubuntu is not listed here as it does not have a
    # ubuntu-{release,version} file, but it should always have the lsb_release
    # command so it will be handled by the Linux::Distro::LSB module
);

our $runMeIfTheseChecksFailed =
    ["GLPI::Agent::Task::Inventory::Linux::Distro::OSRelease"];

sub isEnabled {
    return canRead('/etc/os-release') ? 0 : 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $distribution = first { has_file($_->[0]) } @distributions;
    return unless $distribution;

    my $data = _getDistroData($distribution);

    $inventory->setOperatingSystem($data);
}

sub _getDistroData {
    my ($distribution) = @_;

    my $name     = $distribution->[1];
    my $regexp   = $distribution->[2];
    my $template = $distribution->[3];

    my $line       = getFirstLine(file => $distribution->[0]);
    # Arch Linux has an empty release file
    my ($release, $version);
    if ($line) {
        $release   = sprintf $template, $line;
        ($version) = $line =~ /$regexp/;
    } else {
        $release = $template;
    }

    # If the detected OS is RedHat, but the release contains Scientific, then it is Scientific
    if ($name =~ /RedHat/) {
        if ($release =~ /Scientific/) {
            # this is really a scientific linux, we have to change the name
            $name = "Scientific";
        }
    }

    my $data = {
        NAME      => $name,
        VERSION   => $version,
        FULL_NAME => $release
    };

    if ($name eq 'SuSE') {
        # SLES15 doesn't have /etc/SuSE-release
        if (-e '/etc/SuSE-release') {
            $data->{SERVICE_PACK} = getFirstMatch(
                file    => '/etc/SuSE-release',
                pattern => qr/^PATCHLEVEL = ([0-9]+)/
            );
        } else {
            # fall back by checking if there's a -SP in the current version
            # if so, split by -SP
            if ($version =~ m/\-SP.+/) {
              ($data->{VERSION}, $data->{SERVICE_PACK}) = $version =~ m/(.*)-SP(.*)/;
            }
        }
    }

    return $data;
}

1;
