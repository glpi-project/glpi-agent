#! /bin/bash

set -e

TAG="${GITHUB_REF#*refs/tags/}"
VERSION="$TAG"

while [ -n "$1" ]
do
    case "$1" in
        --version|-v)
            shift
            VERSION="$1"
            ;;
        --tag|-t)
            shift
            TAG="$1"
            ;;
    esac
    shift
done

if [ -z "$TAG" -o "$TAG" == "$GITHUB_REF" ]; then
    echo "GITHUB_REF is not referecing a tag" >&2
    exit 1
fi

if [ "${TAG#*-}" == "$TAG" ]; then
    DEBREV="-1"
    RPMREV="-1"
fi

cat >release-description.md <<DESCRIPTION
Here you can download GLPI-Agent v$VERSION packages.

## Windows
Arch | Windows installer | Windows portable archive
---|:---|:---
64 bits | [GLPI-Agent-$VERSION-x64.msi](../../releases/download/$TAG/GLPI-Agent-$VERSION-x64.msi) | [glpi-agent-$VERSION-x64.zip](../../releases/download/$TAG/glpi-agent-$VERSION-x64.zip)
32 bits | [GLPI-Agent-$VERSION-x86.msi](../../releases/download/$TAG/GLPI-Agent-$VERSION-x86.msi) | [glpi-agent-$VERSION-x86.zip](../../releases/download/$TAG/glpi-agent-$VERSION-x86.zip)

## MacOSX

### MacOSX - Intel
Arch | Package
---|:---
x86_64 | PKG: [GLPI-Agent-${VERSION}_x86_64.pkg](../../releases/download/$TAG/GLPI-Agent-${VERSION}_x86_64.pkg)
x86_64 | DMG: [GLPI-Agent-${VERSION}_x86_64.dmg](../../releases/download/$TAG/GLPI-Agent-${VERSION}_x86_64.dmg)

### MacOSX - Apple Silicon
Arch | Package
---|:---
arm64 | PKG: [GLPI-Agent-${VERSION}_arm64.pkg](../../releases/download/$TAG/GLPI-Agent-${VERSION}_arm64.pkg)
arm64 | DMG: [GLPI-Agent-${VERSION}_arm64.dmg](../../releases/download/$TAG/GLPI-Agent-${VERSION}_arm64.dmg)

## Linux

### Linux installer
Linux installer for redhat/centos/debian/ubuntu (<2Mb):
[glpi-agent-${VERSION}-linux-installer.pl](../../releases/download/$TAG/glpi-agent-${VERSION}-linux-installer.pl)

Linux installer for redhat/centos/debian/ubuntu, including snap install support (~20Mb):
[glpi-agent-${VERSION}-with-snap-linux-installer.pl](../../releases/download/$TAG/glpi-agent-${VERSION}-with-snap-linux-installer.pl)

### Snap package for amd64
[glpi-agent_${VERSION}_amd64.snap](../../releases/download/$TAG/glpi-agent_${VERSION}_amd64.snap)

### Debian/Ubuntu packages
Better use [glpi-agent-${VERSION}-linux-installer.pl](../../releases/download/$TAG/glpi-agent-${VERSION}-linux-installer.pl) when possible.
Related agent task |Package
---|:---
Inventory| [glpi-agent_${VERSION}${DEBREV}_all.deb](../../releases/download/$TAG/glpi-agent_${VERSION}${DEBREV}_all.deb)
NetInventory | [glpi-agent-task-network_${VERSION}${DEBREV}_all.deb](../../releases/download/$TAG/glpi-agent-task-network_${VERSION}${DEBREV}_all.deb)
ESX | [glpi-agent-task-esx_${VERSION}${DEBREV}_all.deb](../../releases/download/$TAG/glpi-agent-task-esx_${VERSION}${DEBREV}_all.deb)
Collect | [glpi-agent-task-collect_${VERSION}${DEBREV}_all.deb](../../releases/download/$TAG/glpi-agent-task-collect_${VERSION}${DEBREV}_all.deb)
Deploy | [glpi-agent-task-deploy_${VERSION}${DEBREV}_all.deb](../../releases/download/$TAG/glpi-agent-task-deploy_${VERSION}${DEBREV}_all.deb)

### RPM packages
RPM packages are arch independents and installation may require some repository setups, better use [glpi-agent-${VERSION}-linux-installer.pl](../../releases/download/$TAG/glpi-agent-${VERSION}-linux-installer.pl) when possible.
Task |Packages
---|:---
Inventory| [glpi-agent-${VERSION}${RPMREV}.noarch.rpm](../../releases/download/$TAG/glpi-agent-${VERSION}${RPMREV}.noarch.rpm)
NetInventory | [glpi-agent-task-network-${VERSION}${RPMREV}.noarch.rpm](../../releases/download/$TAG/glpi-agent-task-network-${VERSION}${RPMREV}.noarch.rpm)
ESX | [glpi-agent-task-esx-${VERSION}${RPMREV}.noarch.rpm](../../releases/download/$TAG/glpi-agent-task-esx-${VERSION}${RPMREV}.noarch.rpm)
Collect | [glpi-agent-task-collect-${VERSION}${RPMREV}.noarch.rpm](../../releases/download/$TAG/glpi-agent-task-collect-${VERSION}${RPMREV}.noarch.rpm)
Deploy | [glpi-agent-task-deploy-${VERSION}${RPMREV}.noarch.rpm](../../releases/download/$TAG/glpi-agent-task-deploy-${VERSION}${RPMREV}.noarch.rpm)
WakeOnLan | [glpi-agent-task-wakeonlan-${VERSION}${RPMREV}.noarch.rpm](../../releases/download/$TAG/glpi-agent-task-wakeonlan-${VERSION}${RPMREV}.noarch.rpm)
Cron | [glpi-agent-cron-${VERSION}${RPMREV}.noarch.rpm](../../releases/download/$TAG/glpi-agent-cron-${VERSION}${RPMREV}.noarch.rpm)
DESCRIPTION
