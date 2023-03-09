#! /bin/bash

set -e

ROOT="`pwd`"

: ${VERSION:=1.4}
: ${ARCH:=x86_64}

PREPARE="no"

while [ -n "$1" ]
do
    case "$1" in
        --version|-v)
            shift
            VERSION="$1"
            ;;
        --clean)
            rm -rf build appimage-builder-cache
            ;;
        --prepare)
            PREPARE="yes"
            ;;
        --config)
            while [ -n "${2%%-*}" ]
            do
                shift
                [ -z "${1%%/*}" ] && CONFIG="$CONFIG $1" || CONFIG="$CONFIG $ROOT/$1"
            done
            ;;
        --help|-h)
            cat <<HELP
$0 [[-v|--version] VERSION] [--config (CONF.cfg|CERT.(pem|crt)|...)] [--prepare]
    [--clean] [-h|--help]

This tools can be used to prepare a linux AppImage installer environment and eventually
build the AppImage if appimage-builder command is installed.

It need to find official glpi-agent deb files in the current folder.

Set VERSION to the glpi-agent used version.

Typical usage:
$0 --version 1.0 --prepare

It is possible to include configuration related files to be installed under
/etc/glpi-agent/conf.d and have them automatically installed. Files extensions is
restricted to .cfg, .pem or .crt as only these kinds of file could be really useful
for the agent.

Use --prepare option to not try to start appimage-builder command if prepared environment.

Use --clean option to cleanup the environment before preparing.
HELP
            exit 0
            ;;
    esac
    shift
done

if [ -z "$VERSION" ]; then
    echo "Can't prepare AppImage environment without a version" >&2
    exit 2
fi

# Needed folders
[ -d build/AppDir ] || mkdir -p build/AppDir

# Copy our AppImage hook
cp -avf contrib/unix/glpi-agent-appimage-hook build/AppDir

# Create init service file
[ -d build/AppDir/etc/init.d ] || mkdir -p build/AppDir/etc/init.d
cat >build/AppDir/etc/init.d/glpi-agent <<INITD_SCRIPT
#!/bin/sh

installpath=/usr/local/bin
prog=glpi-agent
pidfile=/var/run/glpi-agent.pid

start() {
    echo -n "Starting \$prog: "
    \$installpath/glpi-agent --daemon --pidfile \$pidfile 2>/dev/null
    echo
}

stop() {
    echo -n "Stopping \$prog: "
    kill \$(<\$pidfile) 2>/dev/null
    echo
}

case "\$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        if kill -0 \$(<\$pidfile) 2>/dev/null; then
            echo "\$prog is running"
        else
            echo "\$prog is stopped"
        fi
        ;;
    reload)
        echo -n "Reloading \$prog..."
        kill -HUP \$(<\$pidfile) >/dev/null 2>&1
        echo
        ;;
    restart)
        stop
        start
        ;;
    *)
        echo "Usage: \$0 {start|stop|status|restart|reload}"
        exit 1
        ;;
esac
INITD_SCRIPT

chmod +x build/AppDir/etc/init.d/glpi-agent

# Build local repository with deb packages
[ -d build/local/glpi-agent ] || mkdir -p build/local/glpi-agent
for f in *.deb
do
    cp -avf $f build/local/glpi-agent
done

# Create local debian repository for appimage-builder integration
cd build
dpkg-scanpackages local >local/Packages

cd "$ROOT"

if [ -n "$CONFIG" ]; then
    rm -rf build/AppDir/config
    mkdir build/AppDir/config
    for conf in $CONFIG
    do
        cp -af $conf build/AppDir/config
        FILES="$FILES config/${conf##*/}"
    done
fi

case "$ARCH" in
    x86_64)
        DISTRO_ARCH="amd64"
        DISTRO_URL="http://archive.ubuntu.com/ubuntu/"
        DISTRO_KEY="http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3b4fe6acc0b21f32"
        ;;
    *)
        echo "Unsupported arch for AppImage building" >&2
        exit 1
        ;;
esac

# When running in GH Actions, LOCAL_SOURCE_FILE should be set to used docker path
: ${LOCAL_SOURCE_FILE:=$ROOT/build}

# First insert installer version definitions
cat >build/AppImageBuilder.yml <<APPIMAGEBUILDER_YAML
version: 1

AppDir:
  app_info:
    id: org.glpi_project.glpi_agent
    name: glpi-agent
    icon: glpi-agent
    version: '$VERSION'
    exec: usr/bin/perl
    exec_args: "\$APPDIR/glpi-agent-appimage-hook \$@"

  apt:
    arch: $DISTRO_ARCH
    sources:
      - sourceline: 'deb [arch=$DISTRO_ARCH] $DISTRO_URL bionic main restricted universe multiverse'
        key_url: '$DISTRO_KEY'
      - sourceline: 'deb [arch=$DISTRO_ARCH] $DISTRO_URL bionic-updates main restricted universe multiverse'
      - sourceline: 'deb [arch=$DISTRO_ARCH] $DISTRO_URL bionic-backports main restricted universe multiverse'
      - sourceline: 'deb [trusted=yes] copy:$LOCAL_SOURCE_FILE local/'

    include:
      - perl
      - glpi-agent
      - glpi-agent-task-collect
      - glpi-agent-task-deploy
      - glpi-agent-task-esx
      - glpi-agent-task-network
      - libcrypt-rijndael-perl

  after_bundle: |
    find build/AppDir -type f -name '*.pod' -delete; \
    sed -ri 's|/usr/share/glpi-agent|\$ENV{APPDIR}/usr/share/glpi-agent|' build/AppDir/usr/share/glpi-agent/lib/setup.pm build/AppDir/usr/bin/glpi-*; \
    rm -f build/AppDir/usr/bin/{GET,POST,HEAD}

  files:
    exclude:
      - usr/sbin/update-*
      - usr/bin/c*
      - usr/bin/d*
      - usr/bin/e*
      - usr/bin/h*
      - usr/bin/i*
      - usr/bin/j*
      - usr/bin/lib*
      - usr/bin/lwp-*
      - usr/bin/o*
      - usr/bin/s*
      - usr/bin/u*
      - usr/bin/x*
      - usr/bin/z*
      - usr/bin/pci*
      - usr/bin/pod*
      - usr/bin/pi*
      - usr/bin/pl*
      - usr/bin/pr*
      - usr/bin/pt*
      - usr/bin/perl?*
      - usr/share/man
      - usr/share/doc*
      - usr/lib/*/libperl.so.*
      - usr/share/perl/*/perl5db.pl
      - usr/share/pkgconfig
      - usr/share/misc
      - usr/share/perl-openssl-defaults
      - var/lib/usbutils

  runtime:
    env:
      LANG: C
      APPDIR_LIBRARY_PATH: \$APPDIR/lib/x86_64-linux-gnu:\$APPDIR/usr/lib/x86_64-linux-gnu
      PERL5LIB: \$APPDIR/usr/share/glpi-agent/lib:\$APPDIR/usr/lib/x86_64-linux-gnu/perl5/5.26:\$APPDIR/usr/share/perl5:\$APPDIR/usr/lib/x86_64-linux-gnu/perl/5.26:\$APPDIR/usr/share/perl/5.26:\$APPDIR/usr/lib/x86_64-linux-gnu/perl-base

AppImage:
  update-information: None
  sign-key: None
  arch: $ARCH

APPIMAGEBUILDER_YAML

mkdir -p build/AppDir/usr/share/metainfo
# First insert installer version definitions
cat >build/AppDir/usr/share/metainfo/org.glpi_project.glpi_agent.appdata.xml <<METAINFO
<?xml version="1.0" encoding="UTF-8"?>
<component>
  <id>org.glpi_project.glpi_agent</id>
  <name>glpi-agent</name>
  <summary>glpi-agent is an application essentially designed to keep track of computer inventory submitting it to a GLPI server.</summary>
  <metadata_license>FSFAP</metadata_license>
  <project_license>GPL-2.0-or-later</project_license>
  <description>
    <p>
      glpi-agent is an application designed to help a network  or system administrator to keep track of the hardware and software configurations of devices.
      This agent can collect information from:
      <ol>
        <li>local machine (Inventory)</li>
        <li>network using SNMP</li>
        <li>VMware ESX or vCenter server</li>
        <li>remote computer</li>
      </ol>
    </p>
  </description>
  <launchable type="service">glpi-agent</launchable>
  <icon type="local" width="144" height="144">/usr/share/icons/144x144/glpi-agent.png</icon>
  <categories>
    <category>System</category>
  </categories>
</component>
METAINFO

# Make icons and copy logo
if [ ! -e "build/AppDir/usr/share/icons/144x144/glpi-agent.png" ]; then
    mkdir -p "build/AppDir/usr/share/icons/144x144"
    cp -a "share/html/logo.png" "build/AppDir/usr/share/icons/144x144/glpi-agent.png"
fi

if [ "$PREPARE" == "yes" ]; then
    echo "AppImage building environment prepared"
    exit 0
fi

if ! type appimage-builder >/dev/null 2>&1; then
    echo "appimage-builder command not installed" >&2
    exit 1
fi

appimage-builder --appdir build/AppDir --recipe build/AppImageBuilder.yml

ls -l *.AppImage
