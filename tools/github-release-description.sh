#! /bin/bash

set -e

TAG="${GITHUB_REF#*refs/tags/}"

if [ -z "$TAG" -o "$TAG" == "$GITHUB_REF" ]; then
    echo "GITHUB_REF is not referecing a tag" >&2
    exit 1
fi

if [ "${TAG#*-}" == "$TAG" ]; then
    DEBREV="-1"
fi

cat >release-description.md <<DESCRIPTION
Here you can download GLPI-Agent v$TAG packages.

## Windows
Arch | Windows installer | Windows portable archive
---|:---|:---
64 bits | [GLPI-Agent-$TAG-x64.msi](../../releases/download/$TAG/GLPI-Agent-$TAG-x64.msi) | [glpi-agent-$TAG-x64.zip](../../releases/download/$TAG/glpi-agent-$TAG-x64.zip)
32 bits | [GLPI-Agent-$TAG-x86.msi](../../releases/download/$TAG/GLPI-Agent-$TAG-x86.msi) | [glpi-agent-$TAG-x86.zip](../../releases/download/$TAG/glpi-agent-$TAG-x86.zip)

## MacOSX
Arch | Package
---|:---
x86_64 | PKG: [GLPI-Agent-${TAG}_x86_64.pkg](../../releases/download/$TAG/GLPI-Agent-${TAG}_x86_64.pkg)
x86_64 | DMG: [GLPI-Agent-${TAG}_x86_64.dmg](../../releases/download/$TAG/GLPI-Agent-${TAG}_x86_64.dmg)

## Linux

### Snap package for amd64
[glpi-agent_${TAG}_amd64.snap](../../releases/download/$TAG/glpi-agent_${TAG}_amd64.snap)

### Debian/Ubuntu packages
Related agent task |Package
---|:---
Inventory| [glpi-agent_${TAG}${DEBREV}_all.deb](../../releases/download/$TAG/glpi-agent_${TAG}${DEBREV}_all.deb)
NetInventory | [glpi-agent-task-network_${TAG}${DEBREV}_all.deb](../../releases/download/$TAG/glpi-agent-task-network_${TAG}${DEBREV}_all.deb)
ESX | [glpi-agent-task-esx_${TAG}${DEBREV}_all.deb](../../releases/download/$TAG/glpi-agent-task-esx_${TAG}${DEBREV}_all.deb)
Collect | [glpi-agent-task-collect_${TAG}${DEBREV}_all.deb](../../releases/download/$TAG/glpi-agent-task-collect_${TAG}${DEBREV}_all.deb)
Deploy | [glpi-agent-task-deploy_${TAG}${DEBREV}_all.deb](../../releases/download/$TAG/glpi-agent-task-deploy_${TAG}${DEBREV}_all.deb)

DESCRIPTION
