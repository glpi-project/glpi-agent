#! /bin/bash

set -e

# pbuilder is mandatory
if [ -z "$( which pbuilder 2>&1 )" ]; then
	echo "You need pbuilder software, please install it before continuing" >&2
	exit 1
fi

# sudo must be enabled
if ! sudo /bin/true ; then
	echo "You need to enable sudo" >&2
	exit 1
fi

# Initialize pbuilder environment
if [ ! -e "/var/cache/pbuilder/base.tgz" ]; then
	sudo pbuilder create
fi

# Check options
while [ -n "$1" ]
do
	case "$1" in
		--update)
			sudo pbuilder --update
			;;
	esac
	shift
done

# Prepare source
[ -e Makefile ] && { perl Makefile.PL ; make purge ; }
rm -f MANIFEST META.yml
perl Makefile.PL
make manifest

DEBIAN_VERSION=$( dpkg-parsechangelog -S Version | cut -d':' -f2 )
make dist DISTVNAME="GLPI-Agent-$DEBIAN_VERSION"

# Extract version from Makefile
VERSION=$( egrep '^VERSION = ' Makefile | cut -d'=' -f2 | tr -d ' ' )
ORIG_VERSION="${DEBIAN_VERSION%-*}"

# Move package to the expected place
rm -f ../glpi-agent_$VERSION*
mv -vf GLPI-Agent-$DEBIAN_VERSION.tar.gz ../glpi-agent_$ORIG_VERSION.orig.tar.gz

# Set a builderid
PBUILDER_BASE_SHA1=$( sha1sum /var/cache/pbuilder/base.tgz 2>/dev/null )
if [ -n "$PBUILDER_BASE_SHA1" ]; then
	BUILDERID=${PBUILDER_BASE_SHA1:0:8}
else
	UUID=$(uuidgen -t 2>/dev/null)
	BUILDERID=${UUID%%-*}
fi
: ${BUILDERID:=$HOSTNAME}
export BUILDERID

set +e
echo "Building Debian package... BUILDERID=$BUILDERID"
pdebuild --use-pdebuild-internal

dh_clean

# Fix modified files
echo "Reverting files to cleanup sources"
tar xvf ../glpi-agent_$ORIG_VERSION.orig.tar.gz \
	--strip-components=1 \
	GLPI-Agent-$DEBIAN_VERSION/lib/setup.pm \
	GLPI-Agent-$DEBIAN_VERSION/lib/FusionInventory/Agent/Version.pm \
	GLPI-Agent-$DEBIAN_VERSION/etc/agent.cfg
