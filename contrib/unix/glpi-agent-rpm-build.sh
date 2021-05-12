#! /bin/sh

: ${UNITDIR:=/usr/lib/systemd/system}
: ${OTHER_OPTS:=}

while [ -n "$1" ]
do
    case "$1" in
        --dist)
            shift
            DIST="$1"
            ;;
        --rev)
            shift
            REV="$1"
            ;;
        --nodeps)
            [ -n "$OTHER_OPTS" ] && OTHER_OPTS="$OTHER_OPTS "
            OTHER_OPTS="${OTHER_OPTS}--nodeps"
            ;;
        --define|-D)
            shift
            [ -n "$OTHER_OPTS" ] && OTHER_OPTS="$OTHER_OPTS "
            OTHER_OPTS="${OTHER_OPTS}-D '$1'"
            ;;
    esac
    shift
done

: ${DIST:=$( rpm --eval "%{?dist}" 2>/dev/null )}
DIST=${DIST#.}

if [ ! -e lib -a ! -e tools/make-release.sh ]; then
    echo "This script MUST be run from the root of glpi-agent sources" >&2
    exit 1
fi

VER=${GITHUB_REF#refs/tags/}
if [ -n "${GITHUB_REF%refs/tags/*}" -o -z "$VER" ]; then
    VER=$(perl -Ilib -MFusionInventory::Agent::Version -e '$v = $FusionInventory::Agent::Version::VERSION; $v =~ s/-.*//; print $v')
fi
if [ -z "$REV" ]; then
    REV=$([ -n "$GITHUB_SHA" ] && echo $GITHUB_SHA| cut -c 1-8 || git log --pretty=format:%h -n 1)
    [ -n "$REV" ] && REV="git$REV" || REV=1
fi

[ -z "$DIST" ] && unset DISTRO || DISTRO=".$DIST"
rm -f glpi-agent-$VER-$REV$DISTRO.tar.gz
echo "Preparing glpi-agent-$VER-$REV$DISTRO ..."
tools/make-release.sh --no-git $VER-$REV$DISTRO

echo "Checking if a dedicated dist script exists..."
[ -n "$DIST" -a -x contrib/unix/rpmbuild.$DIST.sh ] && source contrib/unix/rpmbuild.$DIST.sh

perl Makefile.PL
rm -f MANIFEST
make manifest
make dist DISTVNAME=glpi-agent-$VER-$REV$DISTRO

SRCDIR=`rpm --eval "%{_sourcedir}"`
[ -d "$SRCDIR" ] || mkdir -p "$SRCDIR"
rm -f $SRCDIR/*.tar.gz
cp glpi-agent-$VER-$REV$DISTRO.tar.gz "$SRCDIR"

# Prepare rpmbuild options
BUILD_OPTS="-D 'rev $REV'"
[ -n "$DISTRO" ]     && BUILD_OPTS="$BUILD_OPTS -D 'dist $DISTRO'"
[ -n "$UNITDIR" ]    && BUILD_OPTS="$BUILD_OPTS -D '_unitdir $UNITDIR'"

echo "Running 'rpmbuild -ba $BUILD_OPTS $OTHER_OPTS contrib/unix/glpi-agent.spec' ..."
eval "rpmbuild -ba $BUILD_OPTS $OTHER_OPTS contrib/unix/glpi-agent.spec"

# Output rpms path for GH Actions uploads
RPMDIR=`rpm --eval "%{_rpmdir}"`
SRPMDIR=`rpm --eval "%{_srcrpmdir}"`
echo "::set-output name=rpmdir:: $RPMDIR"
echo "::set-output name=srpmdir:: $SRPMDIR"
for rpm in $(eval "rpmspec -q $BUILD_OPTS contrib/unix/glpi-agent.spec")
do
    BASE=${rpm%-$VER-$REV*}
    ARCH=${rpm##*.}
    echo "::set-output name=$BASE-rpm:: $RPMDIR/$ARCH/$rpm.rpm"
done
