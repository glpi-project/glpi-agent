# <img src="https://raw.githubusercontent.com/glpi-project/glpi-agent/develop/share/html/logo.png" alt="GLPI Agent" width="32" height="32" /> GLPI Agent

[![GLPI Agent CI](https://github.com/glpi-project/glpi-agent/actions/workflows/glpi-agent-ci.yml/badge.svg)](https://github.com/glpi-project/glpi-agent/actions/workflows/glpi-agent-ci.yml)
[![GLPI Agent Packaging](https://github.com/glpi-project/glpi-agent/actions/workflows/glpi-agent-packaging.yml/badge.svg)](https://github.com/glpi-project/glpi-agent/actions/workflows/glpi-agent-packaging.yml)
[![Github All Releases](https://img.shields.io/github/downloads/glpi-project/glpi-agent/total.svg)](#download)
[![Twitter Follow](https://img.shields.io/twitter/follow/GLPI_PROJECT.svg?style=social&label=Follow)](https://twitter.com/GLPI_PROJECT)

## Summary

The GLPI Agent is a generic management agent. It can perform a
certain number of tasks, according to its own execution plan, or on behalf of a
GLPI server acting as a control point.

## Description

This agent is based on a fork of [FusionInventory agent](https://github.com/fusioninventory/fusioninventory-agent) and so works mainly like FusionInventory agent.
It introduces new features and a new protocol to communicate directly with a GLPI server and its native inventory feature. Anyway it also keeps the compatibility with [FusionInventory for GLPI plugin](https://github.com/fusioninventory/fusioninventory-for-glpi).

## Download

* Release: See [our github releases](https://github.com/glpi-project/glpi-agent/releases) for official win32, MacOSX & linux packages.
* Development builds:
    - nightly builds for last 'develop' branch commits: [GLPI-Agent nightly builds](http://nightly.glpi-project.org/glpi-agent)
    - with a github account, you can also access artifacts for any other branches supporting ["GLPI Agent Packaging" workflow](https://github.com/glpi-project/glpi-agent/actions/workflows/glpi-agent-packaging.yml?query=is%3Asuccess+event%3Apush+-branch%3Adevelop)

## Documentation

The GLPI Agent has its [dedicated documentation project](https://github.com/glpi-project/doc-agent) where any contribution will also be appreciated.

The documentation itself is [readable online](https://glpi-agent.readthedocs.io/).

[![Documentation Status](https://readthedocs.org/projects/glpi-agent/badge/?version=latest)](https://glpi-agent.readthedocs.io/en/latest/?badge=latest)

## Dependencies

### Core

Minimum perl version: 5.8

Mandatory Perl modules:

* File::Which
* LWP::UserAgent
* Net::IP
* Text::Template
* UNIVERSAL::require
* XML::LibXML
* Cpanel::JSON::XS

Optional Perl modules:

* Compress::Zlib, for message compression
* HTTP::Daemon, for web interface
* IO::Socket::SSL, for HTTPS support
* LWP::Protocol::https, for HTTPS support
* Proc::Daemon, for daemon mode (Unix only)
* Proc::PID::File, for daemon mode (Unix only)

### Inventory task

Optional Perl modules:

* Net::CUPS, for printers detection
* Parse::EDID, for EDID data parsing
* DateTime, for reliable timezone name extraction

Optional programs:

* dmidecode, for DMI data retrieval
* lspci, for PCI bus scanning
* hdparm, for additional disk drive info retrieval
* monitor-get-edid-using-vbe, monitor-get-edid or get-edid, for EDID data access
* ssh-keyscan, for host SSH public key retrieval

### Network discovery tasks

Mandatory Perl modules:

* Thread::Queue

Optional Perl modules:

* Net::NBName, for NetBios method support
* Net::SNMP, for SNMP method support

Optional programs:

* arp, for arp table lookup method support

### Network inventory tasks

Mandatory Perl modules:

* Net::SNMP
* Thread::Queue

Optional Perl modules:

* Crypt::DES, for SNMPv3 support

### Wake on LAN task

Optional Perl modules:

* Net::Write::Layer2, for ethernet method support

### Deploy task

Mandatory Perl modules:

* Archive::Extract
* Digest::SHA
* File::Copy::Recursive
* JSON::PP
* URI::Escape

Mandatory Perl modules for P2P Support:
* Net::Ping
* Parallel::ForkManager

### MSI Packaging

Tools:

* [dmidecode](https://github.com/glpi-project/dmidecode) modified to be built with mingw32
* hdparm
* [7zip](https://www.7-zip.org/)

Mandatory Perl modules:

* Perl::Dist::Strawberry

### MacOSX Packaging

Tools:

* [dmidecode](https://github.com/glpi-project/dmidecode/tree/macosx) modified to be built on macosx
* [munkipkg](https://github.com/munki/munki-pkg)
* Xcode
* productbuild
* hdiutil

### Public databases

* Pci.ids
* Usb.ids
* SysObject.ids: [sysobject.ids](https://github.com/glpi-project/sysobject.ids)

## Related contribs

See [CONTRIB](CONTRIB.md) to find references to GLPI Agent related scritps/files

## Contacts

Project websites:

* main site: <https://glpi-project.org/>
* forum: <https://forum.glpi-project.org/>
* github: <http://github.com/glpi-project/glpi-agent>

Project Telegram channel:

* https://t.me/glpien

Please report any issues on project [github issue tracker](https://github.com/glpi-project/glpi-agent/issues).

## Active authors

* Guillaume Bougard <gbougard@teclib.com>

Copyright 2006-2010 [OCS Inventory contributors](https://www.ocsinventory-ng.org/)

Copyright 2010-2019 [FusionInventory Team](https://fusioninventory.org)

Copyright 2011-2021 [Teclib Editions](https://www.teclib-edition.com/)

## License

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

This software is licensed under the terms of GPLv2+, see LICENSE file for
details.

## Additional pieces of software

The glpi-injector script is based on fusioninventory-injector script:

* author: Pascal Danek
* copyright: 2005 Pascal Danek

GLPI::Agent::Task::Inventory::Vmsystem
contains code from imvirt:

* url: <http://micky.ibh.net/~liske/imvirt.html>
* author: Thomas Liske <liske@ibh.de>
* copyright: 2008 IBH IT-Service GmbH <http://www.ibh.de/>
* License: GPLv2+

ToolBox HTTP daemon plugin uses flatpickr lightweight and powerful datetime picker js library.
* author: Gregory Petrosyan
* url: <https://flatpickr.js.org/>
* copyright: 2017 Gregory Petrosyan
* License: License MIT
