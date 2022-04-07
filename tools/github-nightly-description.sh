#! /bin/bash

set -e

unset HEADER

while [ -n "$1" ]
do
    case "$1" in
        --version|-v)
            shift
            VERSION="$1"
            ;;
        --header)
            HEADER="yes"
            ;;
        --date)
            shift
            DATE="$1"
            ;;
    esac
    shift
done

if [ -z "$VERSION" ]; then
    echo "VERSION not provided" >&2
    exit 1
fi

if [ -z "$DATE" ]; then
    DATE="$( date -u +'%F %H:%M:%S UTC' )"
fi

if [ -n "$HEADER" ]; then
    cat <<HEADER
---
layout: default
title: GLPI-Agent Nightly Builds
---

HEADER
fi

cat <<DESCRIPTION
# GLPI-Agent v$VERSION nightly build

Built on $DATE

## Windows <a href="#windows-${VERSION//./-}">#</a> {#windows-${VERSION//./-}}

Arch | Windows installer | Windows portable archive
---|:---|:---
64 bits | [GLPI-Agent-$VERSION-x64.msi](GLPI-Agent-$VERSION-x64.msi) | [GLPI-Agent-$VERSION-x64.zip](GLPI-Agent-$VERSION-x64.zip)
32 bits | [GLPI-Agent-$VERSION-x86.msi](GLPI-Agent-$VERSION-x86.msi) | [GLPI-Agent-$VERSION-x86.zip](GLPI-Agent-$VERSION-x86.zip)

## MacOSX <a href="#macosx-${VERSION//./-}">#</a> {#macosx-${VERSION//./-}}

### MacOSX - Intel

Arch | Package
---|:---
x86_64 | PKG: [GLPI-Agent-${VERSION}_x86_64.pkg](GLPI-Agent-${VERSION}_x86_64.pkg)
x86_64 | DMG: [GLPI-Agent-${VERSION}_x86_64.dmg](GLPI-Agent-${VERSION}_x86_64.dmg)

### MacOSX - Apple Silicon

Arch | Package
---|:---
arm64 | PKG: [GLPI-Agent-${VERSION}_arm64.pkg](GLPI-Agent-${VERSION}_arm64.pkg)
arm64 | DMG: [GLPI-Agent-${VERSION}_arm64.dmg](GLPI-Agent-${VERSION}_arm64.dmg)

## Linux <a href="#linux-${VERSION//./-}">#</a> {#linux-${VERSION//./-}}

### Linux installer

Linux installer for redhat/centos/debian/ubuntu|Size
---|---
[glpi-agent-${VERSION}-linux-installer.pl](glpi-agent-${VERSION}-linux-installer.pl)|~2Mb

<p/>

Linux installer for redhat/centos/debian/ubuntu, including snap install support|Size
---|---
[glpi-agent-${VERSION}-with-snap-linux-installer.pl](glpi-agent-${VERSION}-with-snap-linux-installer.pl)|~20Mb

### Snap package for amd64

[glpi-agent_${VERSION}_amd64.snap](glpi-agent_${VERSION}_amd64.snap)

### AppImage Linux installer for x86-64

[glpi-agent-${VERSION}-x86_64.AppImage](glpi-agent-${VERSION}-x86_64.AppImage)

### Debian/Ubuntu packages

Better use [glpi-agent-${VERSION}-linux-installer.pl](glpi-agent-${VERSION}-linux-installer.pl) when possible.

Related agent task |Package
---|:---
Inventory| [glpi-agent_${VERSION}_all.deb](glpi-agent_${VERSION}_all.deb)
NetInventory | [glpi-agent-task-network_${VERSION}_all.deb](glpi-agent-task-network_${VERSION}_all.deb)
ESX | [glpi-agent-task-esx_${VERSION}_all.deb](glpi-agent-task-esx_${VERSION}_all.deb)
Collect | [glpi-agent-task-collect_${VERSION}_all.deb](glpi-agent-task-collect_${VERSION}_all.deb)
Deploy | [glpi-agent-task-deploy_${VERSION}_all.deb](glpi-agent-task-deploy_${VERSION}_all.deb)

### RPM packages

RPM packages are arch independents and installation may require some repository setups, better use [glpi-agent-${VERSION}-linux-installer.pl](glpi-agent-${VERSION}-linux-installer.pl) when possible.

Task |Packages
---|:---
Inventory| [glpi-agent-${VERSION}.noarch.rpm](glpi-agent-${VERSION}.noarch.rpm)
NetInventory | [glpi-agent-task-network-${VERSION}.noarch.rpm](glpi-agent-task-network-${VERSION}.noarch.rpm)
ESX | [glpi-agent-task-esx-${VERSION}.noarch.rpm](glpi-agent-task-esx-${VERSION}.noarch.rpm)
Collect | [glpi-agent-task-collect-${VERSION}.noarch.rpm](glpi-agent-task-collect-${VERSION}.noarch.rpm)
Deploy | [glpi-agent-task-deploy-${VERSION}.noarch.rpm](glpi-agent-task-deploy-${VERSION}.noarch.rpm)
WakeOnLan | [glpi-agent-task-wakeonlan-${VERSION}.noarch.rpm](glpi-agent-task-wakeonlan-${VERSION}.noarch.rpm)
Cron | [glpi-agent-cron-${VERSION}.noarch.rpm](glpi-agent-cron-${VERSION}.noarch.rpm)

<p><a href='#content'>Back to top</a></p>
---

DESCRIPTION
