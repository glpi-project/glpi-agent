#! /bin/bash

set -e

# Check platform we are running on
case "$(uname -sm)" in
    *|Darwin*x86_64)
        echo "GLPI-Agent MacOSX Packaging..."
        ;;
    Darwin*)
        echo "This script only support x86_64 arch" >&2
        exit 2
        ;;
    *)
        echo "This script can only be run under MacOSX system" >&2
        exit 1
        ;;
esac

ROOT="${0%/*}"
cd "$ROOT"
ROOT="`pwd`"

BUILD_PREFIX="/Applications/GLPI-Agent.app"

# We uses munkipkg script to simplify the process
# Thanks to https://github.com/munki/munki-pkg project
if [ ! -e munkipkg ]; then
    echo "Downloading munkipkg script..."
    curl -so munkipkg https://raw.githubusercontent.com/munki/munki-pkg/main/munkipkg
    if [ ! -e munkipkg ]; then
        echo "Failed to download munkipkg script" >&2
        exit 3
    fi
    chmod +x munkipkg
fi

# Needed folder
[ -d build ] || mkdir build
[ -d payload ] || mkdir payload

# Get same perl as for fusioninventory-agent
if [ ! -e macosx-intel.tar ]; then
    echo "Downloading macosx prebuilt perl..."
    curl -so macosx-intel.tar http://prebuilt.fusioninventory.org/perl/macosx-intel.tar
    if [ ! -e macosx-intel.tar ]; then
        echo "Failed to download macosx prebuilt perl" >&2
        exit 4
    fi
fi
rm -rf "payload${BUILD_PREFIX%%/*}"
mkdir -p "payload$BUILD_PREFIX"
tar xf macosx-intel.tar -C "payload$BUILD_PREFIX"
PERLBIN="`pwd`/payload$BUILD_PREFIX/bin/perl"

# Prepare dist package
cd ../..
rm -rf build MANIFEST MANIFEST.bak *.tar.gz
[ -e Makefile ] && make clean
$PERLBIN Makefile.PL

if [ -n "$GITHUB_REF" -a -z "${GITHUB_REF%refs/tags/*}" ]; then
    VERSION="${GITHUB_REF#refs/tags/}"
else
    read Version equals VERSION <<<$( egrep "^VERSION = " Makefile | head -1 )
fi

if [ -z "${VERSION#*-dev}" -a -n "$GITHUB_SHA" ]; then
    VERSION="${VERSION%-dev}-git${GITHUB_SHA:0:8}"
fi

COMMENTS="GLPI Agent v$VERSION,Built by Teclib on $HOSTNAME: $(LANG=C date)"

echo "Preparing sources..."
$PERLBIN Makefile.PL PREFIX="$BUILD_PREFIX" DATADIR="$BUILD_PREFIX/share" \
    SYSCONFDIR="$BUILD_PREFIX/etc" LOCALSTATEDIR="$BUILD_PREFIX/var" \
    INSTALLSITELIB="$BUILD_PREFIX/agent" PERLPREFIX="$BUILD_PREFIX/bin" \
    COMMENTS="$COMMENTS" VERSION="$VERSION"

# Fix shebang
rm -rf inc/ExtUtils
mkdir inc/ExtUtils

cat >inc/ExtUtils/MY.pm <<-EXTUTILS_MY
	package ExtUtils::MY;
	
	use strict;
	require ExtUtils::MM;
	
	our @ISA = qw(ExtUtils::MM);
	
	{
	    package MY;
	    our @ISA = qw(ExtUtils::MY);
	}
	
	sub _fixin_replace_shebang {
	    return '#!$BUILD_PREFIX/bin/perl';
	}
	
	sub DESTROY {}
EXTUTILS_MY

make

echo "Make done."

echo "Installing to payload..."
make install DESTDIR="$ROOT/payload"
echo "Installed."

cd "$ROOT"

# Create conf.d and fix default conf
[ -d "payload$BUILD_PREFIX/etc/conf.d" ] || mkdir -p "payload$BUILD_PREFIX/etc/conf.d"
AGENT_CFG="payload$BUILD_PREFIX/etc/agent.cfg"
sed -i .1.bak -Ee "s/^scan-homedirs *=.*/scan-homedirs = 1/" $AGENT_CFG
sed -i .2.bak -Ee "s/^scan-profiles *=.*/scan-profiles = 1/" $AGENT_CFG
sed -i .3.bak -Ee "s/^httpd-trust *=.*/httpd-trust = 127.0.0.1/" $AGENT_CFG
sed -i .4.bak -Ee "s/^logger *=.*/logger = File/" $AGENT_CFG
sed -i .5.bak -Ee "s/^#?logfile *=.*/logfile = \/var\/log\/glpi-agent.log/" $AGENT_CFG
sed -i .6.bak -Ee "s/^#?logfile-maxsize *=.*/logfile-maxsize = 10/" $AGENT_CFG
sed -i .7.bak -Ee "s/^#?include \"conf\.d\/\"/include \"conf.d\"/" $AGENT_CFG
rm -f $AGENT_CFG*.bak

echo "Create build-info.plist..."
cat >build-info.plist <<-BUILD_INFO
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>distribution_style</key>
		<false/>
		<key>identifier</key>
		<string>org.glpi-project.glpi-agent</string>
		<key>install_location</key>
		<string>/</string>
		<key>name</key>
		<string>GLPI-Agent-$VERSION.pkg</string>
		<key>ownership</key>
		<string>recommended</string>
		<key>postinstall_action</key>
		<string>none</string>
		<key>preserve_xattr</key>
		<false/>
		<key>suppress_bundle_relocation</key>
		<true/>
		<key>version</key>
		<string>$VERSION</string>
	</dict>
	</plist>
BUILD_INFO

cat >product-requirements.plist <<-REQUIREMENTS
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
	    <key>os</key>
	    <array>
	        <string>10.10</string>
	    </array>
	    <key>arch</key>
	    <array>
	        <string>x86_64</string>
	    </array>
	</dict>
	</plist>
REQUIREMENTS

echo "Build package"
./munkipkg .

PKG="GLPI-Agent-$VERSION.pkg"
DMG="GLPI-Agent-$VERSION.dmg"

echo "Prepare distribution installer..."
cat >Distribution.xml <<-CUSTOM
	<?xml version="1.0" encoding="utf-8" standalone="no"?>
	<installer-gui-script minSpecVersion="2">
	    <title>GLPI-Agent $VERSION</title>
	    <pkg-ref id="org.glpi-project.glpi-agent" version="$VERSION" onConclusion="none">$PKG</pkg-ref>
	    <license file="License.txt" mime-type="text/plain" />
	    <background file="background.png" uti="public.png" alignment="bottomleft"/>
	    <background-darkAqua file="background.png" uti="public.png" alignment="bottomleft"/>
	    <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>
	    <options customize="never" require-scripts="false" hostArchitectures="x86_64"/>
	    <choices-outline>
	        <line choice="default">
	            <line choice="org.glpi-project.glpi-agent"/>
	        </line>
	    </choices-outline>
	    <choice id="default"/>
	    <choice id="org.glpi-project.glpi-agent" visible="false">
	        <pkg-ref id="org.glpi-project.glpi-agent"/>
	    </choice>
	    <os-version min="10.10" />
	</installer-gui-script>
CUSTOM
productbuild --product product-requirements.plist --distribution Distribution.xml \
    --package-path "build" --resources "Resources" "build/Dist-$PKG"
mv -vf "build/Dist-$PKG" "build/$PKG"

if [ -e "build/$PKG" ]; then
    rm -f "build/$DMG"
    echo "Create DMG"
    hdiutil create -fs "HFS+" -srcfolder "build/$PKG" "build/$DMG"
fi

ls -l build/*
