#! /bin/sh

# This script prepares a release by:
#  - creating a dedicated release branch
#  - updating IDS files in a separate commit
#  - updating agent Version.pm and Changes file in a version commit
#  - tagging the version commit
#  - merging the release branch
#  - deleting the release branch

set -e

while [ -n "$1" ]
do
    case "$1" in
        --help|-h) cat <<HELP
Usage:
    make-release.sh [-h|--help] [--no-merge|--devel] <VERSION>

    Prepare the GLPI Agent sources for the <VERSION> release. By default, it also
    prepare the current git repository with the necessary commits and merge. But
    you always have to push the sources to publish your repository.

Options:
    -h --help           Show the help
    --no-merge --devel  Don't merge the created release branch
    --no-git            Don't use git command to create commits, tag and merge
    --debrev N          Set debian package revision to N (defaults=1)
HELP
            ;;
        --no-merge|--devel)
            MERGE="no"
            ;;
        --no-git)
            GIT="no"
            ;;
        --debrev)
            shift
            DEBREV="-$1"
            ;;
        -*)
            echo "Ignored option '$1'" >&2
            ;;
        *)
            VERSION="$1"
            ;;
    esac
    shift
done

if [ -z "$VERSION" ]; then
    echo "No version provided argument" >&2
    exit 1
fi

# Be sure to run from parent folder
cd "${0%make-release.sh}.."

if [ "$GIT" != "no" ]; then
    BRANCH="$(git rev-parse --abbrev-ref HEAD)"

    # Verify we are on develop branch or still on the right branch
    if [ "$BRANCH" != "develop" -a "$BRANCH" != "release/$VERSION" ]; then
        echo "Not on the develop branch" >&2
        exit 2
    fi

    echo
    echo ----
    if [ "$BRANCH" = "develop" ] && ! git checkout -b release/$VERSION; then
        echo "Can't create dedicated release branch" >&2
        exit 3
    fi
fi

# 1. Update pci.ids, usb.ids & sysobject.ids (and possibly Changes)
tools/updatePciids.pl
tools/updateUsbids.pl
tools/updateSysobjectids.pl

# 2. Make a commit for IDS files update
if [ "$GIT" != "no" ]; then
    if git status -s | egrep -q "share/(pci|usb|sysobject)\.ids$"; then
        git commit -a -m "feat: Updated IDS files"
    fi
fi

# 3. Update sources version
cat >lib/GLPI/Agent/Version.pm <<VERSION
package GLPI::Agent::Version;

use strict;
use warnings;

our \$VERSION = "$VERSION";
our \$PROVIDER = "GLPI";
our \$COMMENTS = [];

1;

__END__

=head1 NAME

GLPI::Agent::Version - GLPI Agent version

=head1 DESCRIPTION

This module has the only purpose to simplify the way the agent is released. This
file could be automatically generated and overridden during packaging.

It permits to re-define agent VERSION and agent PROVIDER during packaging so
any distributor can simplify his distribution process and permit to identify
clearly the origin of the agent.

It also permits to put build comments in \$COMMENTS. Each array ref element will
be reported in output while using --version option. This will be also seen in logs.
The idea is to authorize the provider to put useful information needed while
agent issue is reported.
One very useful information should be first defined like in that example:

our \$COMMENTS = [
    "Based on GLPI Agent $VERSION"
];
VERSION

# Compute next release minor version for replacement in few scripts
MAJORVERSION=${VERSION%%.*}
MINORVERSION=${VERSION%%-*}
MINORVERSION=${MINORVERSION#*.}
NEXTMINOR=$((MINORVERSION+1))

# Also update SetupVersion in VBS
sed -ri -e "s/^SetupVersion = .*$/SetupVersion = \"$VERSION\"/" \
    -e "s/^'SetupVersion = .*$/'SetupVersion = \"$MAJORVERSION.$NEXTMINOR-gitABCDEFGH\"/" \
    contrib/windows/glpi-agent-deployment.vbs

# Update default version in scripts
sed -ri -e "s/^: \$\{VERSION:=.*\}$/: \${VERSION:=$VERSION}/" \
    contrib/unix/make-linux-appimage.sh \
    contrib/unix/make-linux-installer.sh
sed -ri -e "s/VERSION => .*$/VERSION => \"$MAJORVERSION.$NEXTMINOR-dev\";/" \
    contrib/unix/installer/InstallerVersion.pm

# 4. Update tasks version if required
perl -Itools -MChangelog -e '
    my @tasks = qw(
        Inventory NetDiscovery NetInventory Collect ESX Deploy WakeOnLan RemoteInventory
    );
    my @plugins = qw(
        ToolBox BasicAuthentication Proxy SSL Test
    );
    my $count = 0;
    my $Changes = Changelog->new( file => "Changes" );
    foreach my $task (@tasks) {
        $count += $Changes->task_version_update($task);
    }
    foreach my $plugin (@plugins) {
        $count += $Changes->httpd_plugin_version_update($plugin);
    }
    $Changes->write() if $count;
'

# 5. Update changelog version and release date
RELEASE_DATE=$(LANG=C date +"%a, %d %b %Y")
sed -ri -e "s/.* not released yet/$VERSION $RELEASE_DATE/" Changes

# Update version in Makefile.PL
sed -ri -e "s/^version '.*';$/version '$VERSION';/" Makefile.PL

# Update debian changelog with new entry log using current git user
export DEBFULLNAME="$(git config --get user.name)"
export DEBEMAIL="$(git config --get user.email)"
: ${DEBFULLNAME:=$(git log --pretty=format:"%an" -n 1)}
: ${DEBEMAIL:=$(git log --pretty=format:"%ae" -n 1)}
if [ -n "$DEBFULLNAME" -a -n "$DEBEMAIL" ]; then
    CURRENT=$(dpkg-parsechangelog -S version)
    EPOCH=${CURRENT%%:*}
    if [ "${VERSION%-*}" = "$VERSION" -a -z "$DEBREV" ]; then
        DEBREV="-1"
    fi
    dch -b -D unstable --newversion "$EPOCH:$VERSION$DEBREV" "New upstream release $VERSION"
else
    echo "No github user or email set, aborting" >&2
    exit 1
fi

if [ "$GIT" = "no" ]; then
    exit 0
fi

# 6. Make release commit
git commit -a -m "feat: GLPI Agent $VERSION release"

if [ "$MERGE" = "no" ]; then
    echo
    echo ----
    echo "Skipping tagging to $VERSION"
    echo "Skipping merging in develop"
    echo "You have now to handle manually release/$VERSION branch"
    exit 0
fi

# 7. Make tag on commit
git tag $VERSION

echo
echo ----
# 8. Make release branch merge into develop
git checkout develop
git merge --no-ff release/$VERSION -m "Merge $VERSION release branch into develop"

# 9. Delete release branch
git branch -d release/$VERSION

# 10. Output publishing instructions
cat <<PUBLISHING

----
To publish $VERSION release, you should:
 - review the log         : git log -p
 - push the develop branch: git push

PUBLISHING
