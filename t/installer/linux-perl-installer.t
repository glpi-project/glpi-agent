#!/usr/bin/perl

use strict;
use warnings;

use lib 'contrib/unix/installer';

use English qw(-no_match_vars);
use UNIVERSAL::require;
use File::Temp qw(tempdir);

use Test::Exception;
use Test::More;

use LinuxDistro;

plan skip_all => 'Only tested on linux'
    unless $OSNAME =~ /^linux$/i;

Test::NoWarnings->use()
    if $OSNAME eq 'linux';

my %distros = (
    'unknown' => {
        name    => undef,
        version => undef,
        release => undef,
        class   => 'LinuxDistro',
        files   => [],
        dies    => qr/Not supported linux distribution/
    },
    'fedora-38' => {
        name    => 'Fedora Linux',
        version => '38 (Thirty Eight)',
        release => 'Fedora Linux 38 (Thirty Eight)',
        class   => 'RpmDistro',
        files   => [
            {
                name    => '/etc/os-release',
                content => 'NAME="Fedora Linux"
VERSION="38 (Thirty Eight)"
ID=fedora
VERSION_ID=38
VERSION_CODENAME=""
PLATFORM_ID="platform:f38"
PRETTY_NAME="Fedora Linux 38 (Thirty Eight)"
ANSI_COLOR="0;38;2;60;110;180"
LOGO=fedora-logo-icon
CPE_NAME="cpe:/o:fedoraproject:fedora:38"
DEFAULT_HOSTNAME="fedora"
HOME_URL="https://fedoraproject.org/"
DOCUMENTATION_URL="https://docs.fedoraproject.org/en-US/fedora/f38/system-administrators-guide/"
SUPPORT_URL="https://ask.fedoraproject.org/"
BUG_REPORT_URL="https://bugzilla.redhat.com/"
REDHAT_BUGZILLA_PRODUCT="Fedora"
REDHAT_BUGZILLA_PRODUCT_VERSION=38
REDHAT_SUPPORT_PRODUCT="Fedora"
REDHAT_SUPPORT_PRODUCT_VERSION=38
SUPPORT_END=2024-05-14'
            },
            {
                name    => '/etc/fedora-release',
                content => 'Fedora release 38 (Thirty Eight)'
            },
            {
                name    => '/etc/redhat-release',
                link    => 'fedora-release'
            },
            {
                name    => '/etc/system-release',
                link    => 'fedora-release'
            }
        ],
    },
    'debian-12.1' => {
        name    => 'Debian GNU/Linux',
        version => '12 (bookworm)',
        release => 'Debian GNU/Linux 12 (bookworm)',
        class   => 'DebDistro',
        files   => [
            {
                name    => '/etc/os-release',
                content => 'PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
NAME="Debian GNU/Linux"
VERSION_ID="12"
VERSION="12 (bookworm)"
VERSION_CODENAME=bookworm
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"'
            },
            {
                name    => '/etc/debian_version',
                content => '12.1'
            }
        ],
    },
    'ubuntu-16.04.4-lts' => {
        name    => 'Ubuntu',
        version => '16.04.4 LTS (Xenial Xerus)',
        release => 'Ubuntu 16.04.4 LTS',
        class   => 'DebDistro',
        files   => [
            {
                name    => '/etc/os-release',
                content => 'NAME="Ubuntu"
VERSION="16.04.4 LTS (Xenial Xerus)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 16.04.4 LTS"
VERSION_ID="16.04"
HOME_URL="http://www.ubuntu.com/"
SUPPORT_URL="http://help.ubuntu.com/"
BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
VERSION_CODENAME=xenial
UBUNTU_CODENAME=xenial'
            },
            {
                name    => '/etc/lsb-release',
                content => 'DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=16.04
DISTRIB_CODENAME=xenial
DISTRIB_DESCRIPTION="Ubuntu 16.04.4 LTS"'
            },
            {
                name    => '/etc/debian_version',
                content => 'stretch/sid'
            }
        ],
    },
    'ubuntu-18.04.6-lts' => {
        name    => 'Ubuntu',
        version => '18.04.6 LTS (Bionic Beaver)',
        release => 'Ubuntu 18.04.6 LTS',
        class   => 'DebDistro',
        files   => [
            {
                name    => '/etc/os-release',
                content => 'NAME="Ubuntu"
VERSION="18.04.6 LTS (Bionic Beaver)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 18.04.6 LTS"
VERSION_ID="18.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=bionic
UBUNTU_CODENAME=bionic'
            },
            {
                name    => '/etc/lsb-release',
                content => 'DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=18.04
DISTRIB_CODENAME=bionic
DISTRIB_DESCRIPTION="Ubuntu 18.04.6 LTS"'
            },
            {
                name    => '/etc/debian_version',
                content => 'buster/sid'
            }
        ],
    },
    'ubuntu-20.04.5-lts' => {
        name    => 'Ubuntu',
        version => '20.04.5 LTS (Focal Fossa)',
        release => 'Ubuntu 20.04.5 LTS',
        class   => 'DebDistro',
        files   => [
            {
                name    => '/etc/os-release',
                content => 'NAME="Ubuntu"
VERSION="20.04.5 LTS (Focal Fossa)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 20.04.5 LTS"
VERSION_ID="20.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=focal
UBUNTU_CODENAME=focal'
            },
            {
                name    => '/etc/lsb-release',
                content => 'DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=20.04
DISTRIB_CODENAME=focal
DISTRIB_DESCRIPTION="Ubuntu 20.04.5 LTS"'
            },
            {
                name    => '/etc/debian_version',
                content => 'bullseye/sid'
            }
        ],
    },
    'ubuntu-22.04.2-lts' => {
        name    => 'Ubuntu',
        version => '22.04.2 LTS (Jammy Jellyfish)',
        release => 'Ubuntu 22.04.2 LTS',
        class   => 'DebDistro',
        files   => [
            {
                name    => '/etc/os-release',
                content => 'PRETTY_NAME="Ubuntu 22.04.2 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04.2 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=jammy'
            },
            {
                name    => '/etc/lsb-release',
                content => 'DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=22.04
DISTRIB_CODENAME=jammy
DISTRIB_DESCRIPTION="Ubuntu 22.04.2 LTS"'
            },
            {
                name    => '/etc/debian_version',
                content => 'bookworm/sid'
            }
        ],
    },
    'centos-6.6' => {
        name    => 'CentOS',
        version => '6.6',
        release => 'CentOS release 6.6 (Final)',
        class   => 'RpmDistro',
        files   => [
            {
                name    => '/etc/centos-release',
                content => 'CentOS release 6.6 (Final)'
            },
            {
                name    => '/etc/redhat-release',
                link    => 'centos-release'
            },
            {
                name    => '/etc/system-release',
                link    => 'centos-release'
            }
        ],
    },
    'centos-7.9' => {
        name    => 'CentOS Linux',
        version => '7 (Core)',
        release => 'CentOS Linux 7 (Core)',
        class   => 'RpmDistro',
        files   => [
            {
                name    => '/etc/os-release',
                content => 'NAME="CentOS Linux"
VERSION="7 (Core)"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="7"
PRETTY_NAME="CentOS Linux 7 (Core)"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:centos:centos:7"
HOME_URL="https://www.centos.org/"
BUG_REPORT_URL="https://bugs.centos.org/"

CENTOS_MANTISBT_PROJECT="CentOS-7"
CENTOS_MANTISBT_PROJECT_VERSION="7"
REDHAT_SUPPORT_PRODUCT="centos"
REDHAT_SUPPORT_PRODUCT_VERSION="7"

'
            },
            {
                name    => '/etc/centos-release',
                content => 'CentOS Linux release 7.9.2009 (Core)'
            },
            {
                name    => '/etc/redhat-release',
                link    => 'centos-release'
            },
            {
                name    => '/etc/system-release',
                link    => 'centos-release'
            }
        ],
    },
    'centos-8-stream' => {
        name    => 'CentOS Stream',
        version => '8',
        release => 'CentOS Stream 8',
        class   => 'RpmDistro',
        files   => [
            {
                name    => '/etc/os-release',
                content => 'NAME="CentOS Stream"
VERSION="8"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="8"
PLATFORM_ID="platform:el8"
PRETTY_NAME="CentOS Stream 8"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:centos:centos:8"
HOME_URL="https://centos.org/"
BUG_REPORT_URL="https://bugzilla.redhat.com/"
REDHAT_SUPPORT_PRODUCT="Red Hat Enterprise Linux 8"
REDHAT_SUPPORT_PRODUCT_VERSION="CentOS Stream"'
            },
            {
                name    => '/etc/centos-release',
                content => 'CentOS Stream release 8'
            },
            {
                name    => '/etc/redhat-release',
                link    => 'centos-release'
            },
            {
                name    => '/etc/system-release',
                link    => 'centos-release'
            }
        ],
    },
    'centos-9-stream' => {
        name    => 'CentOS Stream',
        version => '9',
        release => 'CentOS Stream 9',
        class   => 'RpmDistro',
        files   => [
            {
                name    => '/etc/os-release',
                content => 'NAME="CentOS Stream"
VERSION="9"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="9"
PLATFORM_ID="platform:el9"
PRETTY_NAME="CentOS Stream 9"
ANSI_COLOR="0;31"
LOGO="fedora-logo-icon"
CPE_NAME="cpe:/o:centos:centos:9"
HOME_URL="https://centos.org/"
BUG_REPORT_URL="https://bugzilla.redhat.com/"
REDHAT_SUPPORT_PRODUCT="Red Hat Enterprise Linux 9"
REDHAT_SUPPORT_PRODUCT_VERSION="CentOS Stream"'
            },
            {
                name    => '/etc/centos-release',
                content => 'CentOS Stream release 9'
            },
            {
                name    => '/etc/redhat-release',
                link    => 'centos-release'
            },
            {
                name    => '/etc/system-release',
                link    => 'centos-release'
            }
        ],
    },
    'rockylinux-8.5' => {
        name    => 'Rocky Linux',
        version => '8.5 (Green Obsidian)',
        release => 'Rocky Linux 8.5 (Green Obsidian)',
        class   => 'RpmDistro',
        files   => [
            {
                name    => '/etc/os-release',
                content => 'NAME="Rocky Linux"
VERSION="8.5 (Green Obsidian)"
ID="rocky"
ID_LIKE="rhel centos fedora"
VERSION_ID="8.5"
PLATFORM_ID="platform:el8"
PRETTY_NAME="Rocky Linux 8.5 (Green Obsidian)"
ANSI_COLOR="0;32"
CPE_NAME="cpe:/o:rocky:rocky:8:GA"
HOME_URL="https://rockylinux.org/"
BUG_REPORT_URL="https://bugs.rockylinux.org/"
ROCKY_SUPPORT_PRODUCT="Rocky Linux"
ROCKY_SUPPORT_PRODUCT_VERSION="8"'
            },
            {
                name    => '/etc/rocky-release',
                content => 'Rocky Linux release 8.5 (Green Obsidian)'
            },
            {
                name    => '/etc/centos-release',
                link    => 'rocky-release'
            },
            {
                name    => '/etc/redhat-release',
                link    => 'rocky-release'
            },
            {
                name    => '/etc/system-release',
                link    => 'rocky-release'
            }
        ],
    },
    'rockylinux-9' => {
        name    => 'Rocky Linux',
        version => '9.0 (Blue Onyx)',
        release => 'Rocky Linux 9.0 (Blue Onyx)',
        class   => 'RpmDistro',
        files   => [
            {
                name    => '/etc/os-release',
                content => 'NAME="Rocky Linux"
VERSION="9.0 (Blue Onyx)"
ID="rocky"
ID_LIKE="rhel centos fedora"
VERSION_ID="9.0"
PLATFORM_ID="platform:el9"
PRETTY_NAME="Rocky Linux 9.0 (Blue Onyx)"
ANSI_COLOR="0;32"
LOGO="fedora-logo-icon"
CPE_NAME="cpe:/o:rocky:rocky:9::baseos"
HOME_URL="https://rockylinux.org/"
BUG_REPORT_URL="https://bugs.rockylinux.org/"
ROCKY_SUPPORT_PRODUCT="Rocky-Linux-9"
ROCKY_SUPPORT_PRODUCT_VERSION="9.0"
REDHAT_SUPPORT_PRODUCT="Rocky Linux"
REDHAT_SUPPORT_PRODUCT_VERSION="9.0"'
            },
            {
                name    => '/etc/rocky-release',
                content => 'Rocky Linux release 9.0 (Blue Onyx)'
            },
            {
                name    => '/etc/redhat-release',
                link    => 'rocky-release'
            },
            {
                name    => '/etc/system-release',
                link    => 'rocky-release'
            }
        ],
    },
    'oraclelinux-8.6' => {
        name    => 'Oracle Linux Server',
        version => '8.6',
        release => 'Oracle Linux Server 8.6',
        class   => 'RpmDistro',
        files   => [
            {
                name    => '/etc/os-release',
                content => 'NAME="Oracle Linux Server"
VERSION="8.6"
ID="ol"
ID_LIKE="fedora"
VARIANT="Server"
VARIANT_ID="server"
VERSION_ID="8.6"
PLATFORM_ID="platform:el8"
PRETTY_NAME="Oracle Linux Server 8.6"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:oracle:linux:8:6:server"
HOME_URL="https://linux.oracle.com/"
BUG_REPORT_URL="https://bugzilla.oracle.com/"

ORACLE_BUGZILLA_PRODUCT="Oracle Linux 8"
ORACLE_BUGZILLA_PRODUCT_VERSION=8.6
ORACLE_SUPPORT_PRODUCT="Oracle Linux"
ORACLE_SUPPORT_PRODUCT_VERSION=8.6'
            },
            {
                name    => '/etc/oracle-release',
                content => 'Oracle Linux Server release 8.6'
            },
            {
                name    => '/etc/system-release',
                link    => 'oracle-release'
            },
            {
                name    => '/etc/redhat-release',
                content => 'Red Hat Enterprise Linux release 8.6 (Ootpa)'
            },
            {
                name    => '/etc/system-release-cpe',
                content => 'cpe:/o:oracle:linux:8:6:server'
            }
        ],
    },
    'almalinux-kodkod' => {
        name    => 'AlmaLinux',
        version => '9.2',
        release => 'AlmaLinux release 9.2 (Turquoise Kodkod)',
        class   => 'RpmDistro',
        files   => [
            {
                name    => '/etc/os-release',
                content => 'ALMALINUX_MANTISBT_PROJECT="AlmaLinux-9"
ALMALINUX_MANTISBT_PROJECT_VERSION="9.2"
REDHAT_SUPPORT_PRODUCT="AlmaLinux"
REDHAT_SUPPORT_PRODUCT_VERSION="9.2"'
            },
            {
                name    => '/etc/redhat-release',
                content => 'AlmaLinux release 9.2 (Turquoise Kodkod)'
            },
            {
                name    => '/etc/almalinux-release',
                content => 'AlmaLinux release 9.2 (Turquoise Kodkod)'
            }
        ],
    },
);

plan tests =>
    (6 * scalar keys %distros) +
    1;

my $fh;

foreach my $test (keys(%distros)) {
    my $root = tempdir(CLEANUP => 1);

    mkdir "$root/etc";

    foreach my $file (@{$distros{$test}->{files}}) {
        next unless "$file->{name}";
        if ($file->{content}) {
            open $fh, '>', "$root$file->{name}"
                or die "Can't create $file->{name} under $root for $test: $!\n";
            print $fh $file->{content};
            close($fh)
                or die "Can't write to $file->{name} under $root for $test: $!\n";
        } elsif ($file->{link}) {
            my $link = $file->{link} =~ m{^/} ? "$root$file->{link}" : $file->{link};
            system("ln -s '$link' '$root$file->{name}'");
        }
    }

    my $distro;
    lives_ok {
        $distro = LinuxDistro->new($distros{$test}->{options});

        # Tune object to simulate environment
        $distro->{base_folder} = $root;
    } "$test distro object setup";

    if ($distros{$test}->{dies}) {
        throws_ok {
            # Try to detect simulated distro
            $distro->analyze();
        } $distros{$test}->{dies}, "$test distro object failed analysis";
    } else {
        lives_ok {
            # Detect simulated distro
            $distro->analyze();
        } "$test distro object analysis";
    }

    ok(ref($distro) eq $distros{$test}->{class}, "$test distro class matches: found >".ref($distro)."<");
    ok((!defined($distro->{_name}) && !defined($distros{$test}->{name})) || $distro->{_name} eq $distros{$test}->{name}, "$test distro name matches: found >".($distro->{_name}//'>undef<')."<");
    ok((!defined($distro->{_version}) && !defined($distros{$test}->{version})) || $distro->{_version} eq $distros{$test}->{version}, "$test distro version matches: found >".($distro->{_version}//'>undef<')."<");
    ok((!defined($distro->{_release}) && !defined($distros{$test}->{release})) || $distro->{_release} eq $distros{$test}->{release}, "$test distro release matches: found >".($distro->{_release}//'>undef<')."<");
}
