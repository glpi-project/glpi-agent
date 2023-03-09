#! /bin/bash

HERE="`pwd`"

cd "${0%/*}"

: ${VERSION:=1.4}
: ${DISTRO:=linux}

while [ -n "$1" ]
do
    case "$1" in
        --version|-v)
            shift
            VERSION="$1"
            ;;
        --distro)
            shift
            DISTRO="$1"
            ;;
        --config)
            while [ -n "${2%%-*}" ]
            do
                shift
                [ -z "${1%%/*}" ] && CONFIG="$CONFIG $1" || CONFIG="$CONFIG $HERE/$1"
            done
            ;;
        --rpm)
            while [ -n "${2%%-*}" ]
            do
                shift
                [ -z "${1%%/*}" ] && RPMS="$RPMS $1" || RPMS="$RPMS $HERE/$1"
            done
            ;;
        --deb)
            while [ -n "${2%%-*}" ]
            do
                shift
                [ -z "${1%%/*}" ] && DEBS="$DEBS $1" || DEBS="$DEBS $HERE/$1"
            done
            ;;
        --deps)
            while [ -n "${2%%-*}" ]
            do
                shift
                [ -z "${1%%/*}" ] && DEPS="$DEPS $1" || DEBS="$DEPS $HERE/$1"
            done
            ;;
        --snap)
            shift
            [ -z "${1%%/*}" ] && SNAP="$1" || SNAP="$HERE/$1"
            ;;
        --help|-h)
            cat <<HELP
$0 [[-v|--version] VERSION] [--distro NAME] [--rpm (PKG.rpm|...)] [--deb (PKG.deb|...)]
    [--snap PKG.snap] [--deps (PKG.rpm|PKG.deb|...)] [--config (CONF.cfg|CERT.(pem|crt)|...)]
    [-h|--help]

This tools can be used to prepare a linux installer.

Set VERSION to the glpi-agent used version.
NAME defaults to "linux" but can be set to anything if the installer is more specific.
NAME will only be used to set the final installer file name as:
  glpi-agent-VERSION-NAME-installer.pl

PKG.rpm is a list of rpm packages to include.
PKG.deb is a list of deb packages to include.
PKG.snap is the snap package to include.

Typical usage:
$0 --version $VERSION --rpm glpi-agent-$VERSION.noarch.rpm glpi-agent-task-network-$VERSION.noarch.rpm \
  --deb glpi-agent_${VERSION}_all.deb glpi-agent-task-network_${VERSION}_all.deb --snap glpi-agent_${VERSION}_amd64.snap

When creating a dedicated installer, it is possible to make it fully offline by adding
packages as dependencies. They will be automatically installed with the agent:
$0 --version $VERSION --distro centos7 --rpm glpi-agent-$VERSION.noarch.rpm \
  --deps perl-Net-CUPS-0.61-13.el7.x86_64 perl-Parse-EDID-1.0.7-1.el7.noarch

It is also possible to include configuration related files to be installed under
/etc/glpi-agent/conf.d and have then automatically installed. Files extensions is
restricted to .cfg, .pem or .crt as only these kinds of file could be really useful
for the agent.

HELP
            exit 0
            ;;
    esac
    shift
done

if [ -z "$VERSION" ]; then
    echo "Can't make installer without a version" >&2
    exit 2
fi

[ -d build ] || mkdir build
cd build

unset FILES

if [ -n "$RPMS" ]; then
    [ -d pkg ] || mkdir pkg
    rm -rf pkg/rpm
    mkdir pkg/rpm
    for rpm in $RPMS
    do
        cp -af $rpm pkg/rpm
        FILES="$FILES pkg/rpm/${rpm##*/}"
    done
fi

if [ -n "$DEBS" ]; then
    [ -d pkg ] || mkdir pkg
    rm -rf pkg/deb
    mkdir pkg/deb
    for deb in $DEBS
    do
        cp -af $deb pkg/deb
        FILES="$FILES pkg/deb/${deb##*/}"
    done
fi

if [ -n "$DEPS" ]; then
    for dep in $DEPS
    do
        case "$dep" in
            *.rpm)
                DEST=pkg/rpm/deps
                ;;
            *.deb)
                DEST=pkg/rpm/deps
                ;;
            *)
                continue
                ;;
        esac
        [ -d "$DEST" ] || mkdir $DEST
        cp -af $dep $DEST
        FILES="$FILES $DEST/${dep##*/}"
    done
fi

if [ -n "$SNAP" ]; then
    [ -d pkg ] || mkdir pkg
    rm -rf pkg/snap
    mkdir pkg/snap
    cp -af $SNAP pkg/snap
    FILES="$FILES pkg/snap/${SNAP##*/}"
fi

if [ -n "$CONFIG" ]; then
    rm -rf config
    mkdir config
    for conf in $CONFIG
    do
        cp -af $conf config
        FILES="$FILES config/${conf##*/}"
    done
fi

# Build script

# First insert installer version definitions
cat >glpi-agent-linux-installer.pl <<INSTALLER_VERSION_MODULE
#! /usr/bin/perl

package
    InstallerVersion;

BEGIN {
    \$INC{"InstallerVersion.pm"} = __FILE__;
}

use constant VERSION => "$VERSION";
use constant DISTRO  => "$DISTRO";

INSTALLER_VERSION_MODULE

# Add libs
for lib in Getopt LinuxDistro RpmDistro DebDistro SnapInstall Archive
do
    egrep -v "^1;$" ../installer/$lib.pm >>glpi-agent-linux-installer.pl
done

# Add files to Archive lib
cat >>glpi-agent-linux-installer.pl <<ARCHIVE_DEF

@files = (
ARCHIVE_DEF

if [ -n "$FILES" ]; then
    for file in $FILES
    do
        [ -s "$file" ] || continue
        cat >>glpi-agent-linux-installer.pl <<ARCHIVE_DEF
    [ "$file" => $(stat --printf=%s $file) ],
ARCHIVE_DEF
    done
fi

cat >>glpi-agent-linux-installer.pl <<ARCHIVE_DEF
);

ARCHIVE_DEF

# Cleanup base script
sed -e 's/^use lib.*/# Auto-generated glpi-agent v$VERSION linux installer/' \
    -e 's/^#!.*/package main;/' \
    ../glpi-agent-linux-installer.pl >>glpi-agent-linux-installer.pl

if [ -n "$FILES" ]; then
    cat >>glpi-agent-linux-installer.pl <<ARCHIVE_DEF

__DATA__
ARCHIVE_DEF
    for file in $FILES
    do
        [ -s "$file" ] || continue
        cat $file >>glpi-agent-linux-installer.pl
    done
fi

if ! perl -c glpi-agent-linux-installer.pl 2>/dev/null; then
    echo "Failed to build installer:"
    perl -c glpi-agent-linux-installer.pl
    exit 1
fi

# install script
chmod +x glpi-agent-linux-installer.pl
cp -a glpi-agent-linux-installer.pl $HERE/glpi-agent-$VERSION-$DISTRO-installer.pl

cd ..
rm -rf build
