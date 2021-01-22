#! /bin/bash

set -e

TAG="${GITHUB_REF#*refs/tags/}"

if [ -z "$TAG" -o "$TAG" == "$GITHUB_REF" ]; then
    echo "GITHUB_REF is not referecing a tag" >&2
    exit 1
fi

cat >release-description.md <<DESCRIPTION
Here you can download GLPI-Agent v$TAG packages.

## Windows
Arch | Windows installer | Windows portable archive
---|:---|:---
64 bits | [GLPI-Agent-$TAG-x64.msi](../../releases/download/$TAG/GLPI-Agent-$TAG-x64.msi) | [glpi-agent-$TAG-x64.zip](../../releases/download/$TAG/glpi-agent-$TAG-x64.zip)
32 bits | [GLPI-Agent-$TAG-x86.msi](../../releases/download/$TAG/GLPI-Agent-$TAG-x86.msi) | [glpi-agent-$TAG-x86.zip](../../releases/download/$TAG/glpi-agent-$TAG-x86.zip)

## MacOSX x86_64
Arch | Package
---|:---
x86_64 PKG | [GLPI-Agent-$TAG.pkg](../../releases/download/$TAG/GLPI-Agent-$TAG.pkg)
x86_64 DMG | [GLPI-Agent-$TAG.dmg](../../releases/download/$TAG/GLPI-Agent-$TAG.dmg)

## Linux
Packaging | Arch | Package
---|---|:---
snap | amd64 | [glpi-agent_${TAG}_amd64.snap](../../releases/download/$TAG/glpi-agent_${TAG}_amd64.snap)

DESCRIPTION
