# Testing the Linux Installer Locally

This guide explains how to build the self-extracting Perl installer script
and how to exercise the new APT/DPKG lock-contention and broken-dpkg-state
preflight checks introduced by fix #1136.

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Debian/Ubuntu host or VM | Tests below require `dpkg`, `apt`, and `flock` |
| Perl ≥ 5.10 | `perl --version` |
| `bash` | for `make-linux-installer.sh` |
| Root / sudo access | `apt install` requires root |
| Built `.deb` packages **or** packages downloaded from a release | See *Build the installer* below |

### Install Perl test dependencies (once)

```bash
sudo apt install -y libuniversal-require-perl \
                    libtest-exception-perl \
                    libtest-nowarnings-perl
```

---

## 1. Run the existing unit tests

These tests cover distro detection and do **not** require packages or root:

```bash
cd /path/to/glpi-agent
perl t/installer/linux-perl-installer.t
```

Expected output: `91 tests passed, no warnings`.

---

## 2. Build the self-extracting installer script

`contrib/unix/make-linux-installer.sh` concatenates all installer Perl modules
into a single self-contained script.

### With real `.deb` packages

Download release packages (replace `X.Y` with the version you want to test):

```bash
VERSION=X.Y
wget https://github.com/glpi-project/glpi-agent/releases/download/${VERSION}/glpi-agent_${VERSION}_all.deb
```

Then build:

```bash
cd contrib/unix
bash make-linux-installer.sh \
  --version "${VERSION}" \
  --distro  debian \
  --deb     ../../glpi-agent_${VERSION}_all.deb
```

The resulting script is written to the repository root as
`glpi-agent-${VERSION}-debian-installer.pl`.

### Without packages (skeleton / syntax test only)

```bash
cd contrib/unix
bash make-linux-installer.sh --version 1.99-test --distro debian
```

This produces a valid, executable script with an empty package archive — useful
for checking that the concatenation and Perl syntax are correct.

---

## 3. Run the installer (normal happy path)

```bash
sudo perl glpi-agent-${VERSION}-debian-installer.pl \
  --type    typical \
  --server  https://your-glpi-server/
```

You should see `apt install` output (stdout only — stderr remains suppressed via
`2>/dev/null` as in the original code) and the agent starting as a service.

---

## 4. Simulate APT/DPKG lock contention

This verifies that `_wait_for_apt_lock` detects and reports lock contention
and eventually times out with a clear message.

### Simulate a held dpkg frontend lock

```bash
# Terminal 1 — hold the lock for 60 seconds
sudo flock /var/lib/dpkg/lock-frontend sleep 60 &

# Terminal 2 — run the installer; it should print wait messages every 10 s
sudo perl glpi-agent-${VERSION}-debian-installer.pl --type typical
```

Expected output every 10 seconds (up to 300 s total):

```
APT/DPKG is currently locked by another process.
Waiting up to 300s for the lock to be released...
Still waiting for APT/DPKG lock to be released... (10s / 300s)
Still waiting for APT/DPKG lock to be released... (20s / 300s)
...
```

After killing the lock holder (`kill %1` in Terminal 1) the installer
continues normally. If the lock is held for the full 300 s the installer
exits non-zero with:

```
APT/DPKG lock still held after 300s.
To identify the locking process, run:
  fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock
Stop that process, then retry the installation.
```

### Quick timeout test (reduce wait in a one-off run)

Edit `DebDistro.pm` temporarily and set `$APT_LOCK_WAIT_MAX = 20`, rebuild the
installer with `make-linux-installer.sh`, hold the lock, and confirm the
installer fails within ~30 seconds.

---

## 5. Simulate a broken dpkg state

This verifies that `_check_dpkg_state` catches inconsistencies before touching
`apt`.

### Method A — leave a package half-configured

```bash
# Unpack without configuring (intentionally broken)
sudo dpkg --unpack /tmp/some-package.deb

# Now run the installer — it should abort immediately
sudo perl glpi-agent-${VERSION}-debian-installer.pl --type typical
```

Expected output:

```
WARNING: dpkg has reported package inconsistencies:
  <dpkg --audit output lines here>
Fix the broken packages before retrying:
  sudo dpkg --configure -a
  sudo apt --fix-broken install
Inconsistent dpkg state detected, aborting installation
```

Exit code is non-zero (`echo $?` → non-zero).

### Method B — simulate dpkg --audit output without actually breaking anything

To exercise the error path without modifying any real packages, temporarily
install a package in the "unpack-only" state and then clean up:

```bash
# Download any small package without installing it
apt-get download hello 2>/dev/null || apt-get download base-files

# Unpack it without running its postinst (leaves it half-configured)
sudo dpkg --unpack ./hello_*.deb 2>/dev/null || sudo dpkg --unpack ./base-files_*.deb

# Run the installer — it should abort immediately with the dpkg audit error
sudo perl glpi-agent-${VERSION}-debian-installer.pl --type typical

# Clean up the intentionally broken state
sudo dpkg --configure -a
sudo apt --fix-broken install -y
```

---

## 6. Verify the success path is unchanged

After all the tests above, confirm a clean install still works end-to-end:

```bash
# Ensure dpkg state is clean first
sudo dpkg --configure -a
sudo apt --fix-broken install -y

# Install
sudo perl glpi-agent-${VERSION}-debian-installer.pl \
  --type   typical \
  --server https://your-glpi-server/ \
  --runnow
```

The installer should proceed without any lock or audit messages and the agent
should run its first inventory immediately.
