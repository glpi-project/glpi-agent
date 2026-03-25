# GLPI Agent — Linux Installer Developer Guide

This directory contains the scripts and Perl modules that make up the
self-extracting Linux installer for GLPI Agent, as well as helper scripts for
building Debian and RPM packages.

---

## Directory overview

| File / directory | Purpose |
|------------------|---------|
| `make-linux-installer.sh` | Builds the self-extracting `glpi-agent-*-installer.pl` script |
| `installer/` | Perl modules embedded into the installer (`LinuxDistro`, `DebDistro`, `RpmDistro`, `SnapInstall`, …) |
| `install-deb.sh` | Unattended Debian/Ubuntu installation helper (downloads and installs from a release) |
| `install-deb-README.md` | Documentation for `install-deb.sh` |
| `glpi-agent.spec` / `glpi-agent-iec61850.spec` | RPM spec files |
| `glpi-agent-rpm-build.sh` | Builds RPM packages |
| `glpi-agent.service` | systemd unit file |
| `glpi-agent.cron` | cron job template |
| `glpi-agent-appimage-hook` | AppImage post-build hook |
| `make-linux-appimage.sh` | Builds the AppImage release artifact |
| `glpi-agent-portable.sh` | Portable (no-install) launcher wrapper |

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Debian/Ubuntu, Fedora/RHEL, or compatible host | Or a VM / container |
| Perl ≥ 5.10 | `perl --version` |
| `bash` | For `make-linux-installer.sh` |
| Root / sudo access | `apt`/`dnf`/`rpm` require root at install time |
| `.deb` or `.rpm` packages | Download from a release or build locally (see below) |

### Install Perl test dependencies (Debian/Ubuntu, once)

```bash
sudo apt install -y libuniversal-require-perl \
                    libtest-exception-perl \
                    libtest-nowarnings-perl
```

---

## Building the self-extracting installer

`make-linux-installer.sh` concatenates all installer Perl modules into a single
executable script and optionally embeds distribution packages inside it.

### Syntax

```
bash make-linux-installer.sh [--version VERSION] [--distro NAME]
     [--deb PKG.deb ...] [--rpm PKG.rpm ...] [--snap PKG.snap]
     [--deps DEP ...] [--config FILE ...]
```

### With real packages (recommended for release testing)

Download the packages for the version you want to test:

```bash
VERSION=1.16
wget https://github.com/glpi-project/glpi-agent/releases/download/${VERSION}/glpi-agent_${VERSION}_all.deb
```

Then build the installer:

```bash
cd contrib/unix
bash make-linux-installer.sh \
  --version "${VERSION}" \
  --distro  debian \
  --deb     ../../glpi-agent_${VERSION}_all.deb
```

The resulting script is written to the repository root as
`glpi-agent-${VERSION}-debian-installer.pl`.

To bundle multiple packages (e.g. also include the network task):

```bash
bash make-linux-installer.sh \
  --version "${VERSION}" \
  --distro  debian \
  --deb     ../../glpi-agent_${VERSION}_all.deb \
            ../../glpi-agent-task-network_${VERSION}_all.deb
```

---

## Running the installer

### Basic install (service mode)

```bash
sudo perl glpi-agent-${VERSION}-linux-installer.pl \
  --type   typical \
  --server https://your-glpi-server/
```

### Common options

| Option | Description |
|--------|-------------|
| `--type typical` | Install the base agent only (default) |
| `--type all` | Install all task packages |
| `--type network` | Install base agent + network tasks |
| `--server URL` | GLPI server URL |
| `--no-question` | Non-interactive / silent mode |
| `--runnow` | Trigger an inventory immediately after install |
| `--cron` | Install as an hourly cron job instead of a service |
| `--verbose` | Show detailed progress output |

### Uninstall

```bash
sudo perl glpi-agent-${VERSION}-linux-installer.pl --uninstall
```

---

## Running the unit tests

The test suite lives in `t/installer/` and covers distro detection for all
supported Linux distributions. It does **not** require packages, root, or
network access.

```bash
cd /path/to/glpi-agent
perl t/installer/linux-perl-installer.t
```

Expected output: all tests pass with no warnings.

---

## Iterating on installer module changes

The Perl modules under `installer/` are embedded verbatim into the final script
by `make-linux-installer.sh`. The development loop is:

1. Edit a module (e.g. `installer/DebDistro.pm`)
2. Check syntax: `perl -I contrib/unix/installer -c contrib/unix/installer/DebDistro.pm`
3. Run unit tests: `perl t/installer/linux-perl-installer.t`
4. Rebuild the installer script: `bash contrib/unix/make-linux-installer.sh --version 1.99-dev`
5. Test the rebuilt script on a Debian/Ubuntu system

