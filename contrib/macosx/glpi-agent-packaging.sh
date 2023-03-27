#! /bin/bash

# PERL: https://www.perl.org/get.html
# SSL:  https://www.openssl.org/source/
# ZLIB: https://www.zlib.net/
: ${PERL_VERSION:=5.36.0}
: ${OPENSSL_VERSION:=3.1.0}
: ${ZLIB_VERSION:=1.2.13}
: ${ZLIB_SHA256:=b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30}

: ${BUILDER_NAME:="Guillaume Bougard (teclib)"}
: ${BUILDER_MAIL:="gbougard_at_teclib.com"}

: ${APPSIGNID:=}
: ${INSTSINGID:=}
: ${NOTARIZE:=no}

let SIGNED=0

set -e

export LC_ALL=C LANG=C

ROOT="${0%/*}"
cd "$ROOT"
ROOT="`pwd`"

while [ -n "$1" ]
do
    case "$1" in
        clean)
            rm -rf build
            ;;
        --arch|-a)
            shift
            ARCH="$1"
            ;;
        --appsignid|-s)
            shift
            APPSIGNID="$1"
            ;;
        --instsignid|-S)
            shift
            INSTSIGNID="$1"
            ;;
        --notarize|-n)
            shift
            NOTARIZE="$1"
            ;;
        --help|-h)
            cat <<HELP
$0 [-a|--arch] [x86_64|arm64] [-s|--appsignid] [APPSIGNID] [-S|--instsignid] [INSTSIGNID] [-n|--notarize] [yes|no] [-h|--help] [clean]
    -a --arch       Specify target arch: x86_64 or arm64
    -s --appsignid  Give Application key ID to use for application signing
    -S --instsignid Give Installer key ID to use for installer signing
    -h --help       This help
    clean           Clean build environment
HELP
            ;;
    esac
    shift
done

# Check platform we are running on
: ${ARCH:=$(uname -m)}
case "$(uname -s) $ARCH" in
    Darwin*x86_64)
        echo "GLPI-Agent MacOSX Packaging for $ARCH..."
        : ${MACOSX_DEPLOYMENT_TARGET:=10.10}
        OPENSSL_CONFIG="darwin64-x86_64-cc"
        ;;
    Darwin*arm64)
        echo "GLPI-Agent MacOSX Packaging for $ARCH..."
        : ${MACOSX_DEPLOYMENT_TARGET:=11.0}
        OPENSSL_CONFIG="darwin64-arm64-cc"
        # Try to disable annoying warning
        EXTRA_PERL_CCFLAGS="-Wno-compound-token-split-by-macro -Wno-deprecated-declarations"
        ;;
    Darwin*)
        echo "$ARCH support is missing, please report an issue" >&2
        exit 2
        ;;
    *)
        echo "This script can only be run under MacOSX system" >&2
        exit 1
        ;;
esac

export MACOSX_DEPLOYMENT_TARGET

BUILD_PREFIX="/Applications/GLPI-Agent"

# We uses munkipkg script to simplify the process
# Thanks to https://github.com/munki/munki-pkg project
if [ ! -e munkipkg ]; then
    echo "Downloading munkipkg script..."
    curl -so munkipkg https://raw.githubusercontent.com/munki/munki-pkg/main/munkipkg
    if [ ! -e munkipkg ]; then
        echo "Failed to download munkipkg script" >&2
        exit 3
    fi
    # Use our patch to tune productbuild and notarization with other required parameters
    [ -e munkipkg.patch ] && patch < munkipkg.patch
    chmod +x munkipkg
fi

# Needed folder
[ -d build ] || mkdir build
[ -d pkg/payload ] || mkdir -p pkg/payload

cp -a Resources pkg/Resources
cp -a scripts pkg/scripts

# Don't keep dmidecode as not useful on arm64 platform
[ "$ARCH" == "x86_64" ] || rm -f pkg/scripts/dmidecode

# Perl build configuration
[ -e ~/.curlrc ] && egrep -q '^insecure' ~/.curlrc || echo insecure >>~/.curlrc
OPENSSL_CONFIG_OPTS="zlib --with-zlib-include='$ROOT/build/zlib' --with-zlib-lib='$ROOT/build/zlib/zlib.a'"
CPANM_OPTS="--build-args=\"OTHERLDFLAGS='-Wl,-search_paths_first'\""
SHASUM="$( which shasum 2>/dev/null )"

SYSROOT="$(xcrun --sdk macosx --show-sdk-path)"
SDKFLAGS="-arch $ARCH -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET -isysroot $SYSROOT -isystem $SYSROOT"

unset LOCAL_ARCH
if [ "$ARCH" != "$(uname -m)" ]; then
    LOCAL_ARCH="$(uname -m)"
    SDK_TARGET="$ARCH-apple-macos${MACOSX_DEPLOYMENT_TARGET%.0}"
    echo "LOCAL ARCH: $LOCAL_ARCH - TARGET: $SDK_TARGET"
    SDKFLAGS="-target $SDK_TARGET $SDKFLAGS"
fi

build_static_zlib () {
    cd "$ROOT"
    echo ======== Build zlib $ZLIB_VERSION
    ARCHIVE="zlib-$ZLIB_VERSION.tar.gz"
    ZLIB_URL="https://www.zlib.net/$ARCHIVE"
    [ -e "$ARCHIVE" ] || curl -so "$ARCHIVE" "$ZLIB_URL"
    read SHA256 x <<<$( $SHASUM -a 256 $ARCHIVE )
    if [ "$SHA256" == "$ZLIB_SHA256" ]; then
        echo "Zlib $ZLIB_VERSION ready for building..."
    else
        echo "Can't build Zlib $ZLIB_VERSION, source archive sha256 digest mismatch"
        exit 1
    fi
    [ -d "zlib-$ZLIB_VERSION" ] || tar xzf "$ARCHIVE"
    [ -d "$ROOT/build/zlib" ] || mkdir -p "$ROOT/build/zlib"
    cd "$ROOT/build/zlib"
    [ -e Makefile ] || CFLAGS="$SDKFLAGS" \
        ../../zlib-$ZLIB_VERSION/configure --static --libdir="$PWD" --includedir="$PWD"
    make libz.a
}

build_perl () {
    cd "$ROOT"
    echo ======== Build perl $PERL_VERSION
    PERL_ARCHIVE="perl-$PERL_VERSION.tar.gz"
    PERL_URL="https://www.cpan.org/src/5.0/$PERL_ARCHIVE"
    [ -e "$PERL_ARCHIVE" ] || curl -so "$PERL_ARCHIVE" "$PERL_URL"

    # Eventually verify archive
    if [ -n "$SHASUM" ]; then
        [ -e "$PERL_ARCHIVE.sha1" ] || curl -so "$PERL_ARCHIVE.sha1.txt" "$PERL_URL.sha1.txt"
        read SHA1 x <<<$( $SHASUM $PERL_ARCHIVE )
        if [ "$SHA1" == "$(cat $PERL_ARCHIVE.sha1.txt)" ]; then
            echo "Perl $PERL_VERSION ready for building..."
        else
            echo "Can't build perl $PERL_VERSION, source archive sha1 digest mismatch"
            exit 1
        fi
    fi

    PATCHPERL_URL="https://raw.githubusercontent.com/gugod/patchperl-packing/master/patchperl"
    [ -e patchperl ] || curl -so patchperl  "$PATCHPERL_URL"
    cd build
    [ -d "perl-$PERL_VERSION" ] || tar xzf "../$PERL_ARCHIVE"
    cd "perl-$PERL_VERSION"
    if [ ! -e patchperl ]; then
        cp -a ../../patchperl .
        chmod +x patchperl
        chmod -R +w .
        ./patchperl
    fi
    if [ ! -e Makefile ]; then
        rm -f config.sh Policy.sh
        ./Configure -de -Dprefix=$BUILD_PREFIX -Duserelocatableinc -DNDEBUG    \
            -Dman1dir=none -Dman3dir=none -Dusethreads -UDEBUGGING             \
            -Dusemultiplicity -Duse64bitint -Duse64bitall -Darch=$ARCH         \
            -Aeval:privlib=.../../lib -Aeval:scriptdir=.../../bin              \
            -Aeval:vendorprefix=.../.. -Aeval:vendorlib=.../../agent           \
            -Accflags="$SDKFLAGS $EXTRA_PERL_CCFLAGS"                          \
            -Aldflags="$SDKFLAGS" -Alddlflags="$SDKFLAGS"                      \
            -Dcf_by="$BUILDER_NAME" -Dcf_email="$BUILDER_MAIL" -Dperladmin="$BUILDER_MAIL"
    fi
    make -j4
    make install.perl DESTDIR="$ROOT/build"
}

# 1. Zlib is needed at least later to build openssl
build_static_zlib

# 2. build perl
build_perl

cd "$ROOT"

# 3. Include new perl in script PATH
echo "Using perl $PERL_VERSION..."
export PATH="$ROOT/build$BUILD_PREFIX/bin:$PATH"

echo ========
perl --version
echo ========

# 4. Download and Build OpenSSL
if [ ! -d "build/openssl-$OPENSSL_VERSION" ]; then
    echo ======== Build openssl $OPENSSL_VERSION
    ARCHIVE="openssl-$OPENSSL_VERSION.tar.gz"
    OPENSSL_URL="https://www.openssl.org/source/$ARCHIVE"
    [ -e "$ARCHIVE" ] || curl -so "$ARCHIVE" "$OPENSSL_URL"

    # Eventually verify archive
    if [ -n "$SHASUM" ]; then
        [ -e "$ARCHIVE.sha256" ] || curl -so "$ARCHIVE.sha256" "$OPENSSL_URL.sha256"
        read SHA256 x <<<$( $SHASUM -a 256 $ARCHIVE )
        read EXPECTED x <<<$( cat $ARCHIVE.sha256 )
        if [ "$SHA256" == "$EXPECTED" ]; then
            echo "OpenSSL $OPENSSL_VERSION ready for building..."
        else
            echo "Can't build OpenSSL $OPENSSL_VERSION, source archive sha256 digest mismatch"
            exit 1
        fi
    fi

    # Uncompress OpenSSL
    if [ ! -d "openssl-$OPENSSL_VERSION" ]; then
        rm -rf "openssl-$OPENSSL_VERSION"
        tar xzf $ARCHIVE
    fi

    [ -e "$ROOT/zlib-$ZLIB_VERSION/zlib.h" ] \
        && cp -f "$ROOT/zlib-$ZLIB_VERSION/zlib.h" "$ROOT/zlib-$ZLIB_VERSION/zconf.h" "$ROOT/openssl-$OPENSSL_VERSION/include"

    # Build OpenSSL under dedicated folder. This is only possible starting with OpenSSL v1.1.0
    [ -d build/openssl ] || mkdir -p build/openssl
    cd build/openssl

    CFLAGS="$SDKFLAGS -Wno-deprecated-declarations" \
    ../../openssl-$OPENSSL_VERSION/Configure $OPENSSL_CONFIG no-autoerrinit no-shared \
        --prefix="/openssl" $OPENSSL_CONFIG_OPTS
    make

    # Only install static lib from build folder
    make install_sw DESTDIR="$ROOT/build/openssl-$OPENSSL_VERSION"

    # Copy libz.a if previously built to lately be included in Net::SSLeay building
    [ -e "$ROOT/build/zlib/libz.a" ] && \
        cp -f "$ROOT/build/zlib/libz.a" "$ROOT/build/openssl-$OPENSSL_VERSION/openssl/lib"
    [ -e "$ROOT/zlib-$ZLIB_VERSION/zlib.h" ] \
        && cp -f "$ROOT/zlib-$ZLIB_VERSION/zlib.h" "$ROOT/zlib-$ZLIB_VERSION/zconf.h" "$ROOT/build/openssl-$OPENSSL_VERSION/openssl/include"
fi

export OPENSSL_PREFIX="$ROOT/build/openssl-$OPENSSL_VERSION/openssl"

# openssl binary is only used to output its version while Net::SSLeay is checking for it
# but it will fail if it is built for a different ARCH, so just replace it with what is
# expected by Net::SSLeay
if [ -n "$LOCAL_ARCH" ]; then
    cat >$OPENSSL_PREFIX/bin/openssl <<-OPENSSL
    #!/bin/sh
    echo OpenSSL $OPENSSL_VERSION
OPENSSL
    chmod +x $OPENSSL_PREFIX/bin/openssl
fi

# 5. Install cpanm
cd "$ROOT"
echo "Install cpanminus"
if [ ! -e "build$BUILD_PREFIX/bin/cpanm" ]; then
    CPANM_URL="https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm"
    curl -so build$BUILD_PREFIX/bin/cpanm "$CPANM_URL"
    chmod +x build$BUILD_PREFIX/bin/cpanm
fi

# 6. Still install modules needing compilation
while read modules
do
    [ -z "${modules%%#*}" ] && continue
    echo ======== Install $modules
    cpanm --notest -v --no-man-pages $CPANM_OPTS $modules
done <<MODULES
Module::Install
Sub::Identify Params::Validate HTML::Parser Compress::Zlib Digest::SHA
Net::SSLeay
MODULES

# Try the library only for local arch builds
if [ -z "$LOCAL_ARCH" ]; then
    echo ======== SSL check
    perl -e 'use Net::SSLeay; print Net::SSLeay::SSLeay_version(0)," (", sprintf("0x%x",Net::SSLeay::SSLeay()),") installed with perl $^V\n";'
    echo ========
fi

# Prepare glpi-agent sources
cd ../..
rm -rf build MANIFEST MANIFEST.bak *.tar.gz
[ -e Makefile ] && make clean
perl Makefile.PL

# Install required agent modules
cpanm --notest -v --installdeps --no-man-pages $CPANM_OPTS .

echo '===== Installing more perl module deps ====='
cpanm --notest -v --no-man-pages  $CPANM_OPTS LWP::Protocol::https             \
    HTTP::Daemon Proc::Daemon Archive::Extract File::Copy::Recursive JSON::PP  \
    URI::Escape Net::Ping Parallel::ForkManager Net::SNMP Net::NBName DateTime \
    Thread::Queue Parse::EDID YAML::Tiny Data::UUID Cpanel::JSON::XS
# Crypt::DES Crypt::Rijndael are commented as Crypt::DES fails to build on MacOSX
# Net::Write::Layer2 depends on Net::PCAP but it fails on MacOSX

rm -rf "$ROOT/pkg/payload${BUILD_PREFIX%%/*}"
mkdir -p "$ROOT/pkg/payload$BUILD_PREFIX"

echo ======== Clean installation
rsync -a --exclude=.packlist --exclude='*.pod' --exclude=.meta --delete --force \
    "$ROOT/build$BUILD_PREFIX/lib/" "$ROOT/pkg/payload$BUILD_PREFIX/lib/"
rm -rf "$ROOT/pkg/payload$BUILD_PREFIX/lib/pods"
mkdir "$ROOT/pkg/payload$BUILD_PREFIX/bin"
cp -a "$ROOT/build$BUILD_PREFIX/bin/perl" "$ROOT/pkg/payload$BUILD_PREFIX/bin/perl"

# Finalize sources
if [ -n "$GITHUB_REF" -a -z "${GITHUB_REF%refs/tags/*}" ]; then
    VERSION="${GITHUB_REF#refs/tags/}"
else
    read Version equals VERSION <<<$( egrep "^VERSION = " Makefile | head -1 )
fi

if [ -z "${VERSION#*-dev}" -a -n "$GITHUB_SHA" ]; then
    VERSION="${VERSION%-dev}-git${GITHUB_SHA:0:8}"
fi

COMMENTS="Built by Teclib on $HOSTNAME: $(LANG=C date)"

echo "Preparing sources..."
perl Makefile.PL PREFIX="$BUILD_PREFIX" DATADIR="$BUILD_PREFIX/share"   \
    SYSCONFDIR="$BUILD_PREFIX/etc" LOCALSTATEDIR="$BUILD_PREFIX/var"    \
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
make install DESTDIR="$ROOT/pkg/payload"
echo "Installed."

# Don't keep .packlist file generated during installation
rm -rf $ROOT/pkg/payload$BUILD_PREFIX/agent/auto

# Cleanup unused static library
find $ROOT/pkg/payload$BUILD_PREFIX -name libperl.a -delete

cd "$ROOT"

# Cleanup fat-files from not targeted arch
if [ "$ARCH" == "arm64" -a -n "$LOCAL_ARCH" ]; then
    let COUNT=1
    echo "===== Filtering $LOCAL_ARCH arch from binaries ====="
    while read file
    do
        printf "%02d: " $((COUNT++))
        ditto -arch $ARCH "$file" "$file.arm64"
        mv -f "$file.arm64" "$file"
        lipo -info "$file"
    done <<CHECK_ARCH
pkg/payload/Applications/GLPI-Agent/bin/perl
$(find pkg/payload -name '*.bundle')
CHECK_ARCH
fi

# Create conf.d and fix default conf
[ -d "pkg/payload$BUILD_PREFIX/etc/conf.d" ] || mkdir -p "pkg/payload$BUILD_PREFIX/etc/conf.d"
AGENT_CFG="pkg/payload$BUILD_PREFIX/etc/agent.cfg"
sed -i .1.bak -Ee "s/^scan-homedirs *=.*/scan-homedirs = 1/" $AGENT_CFG
sed -i .2.bak -Ee "s/^scan-profiles *=.*/scan-profiles = 1/" $AGENT_CFG
sed -i .3.bak -Ee "s/^httpd-trust *=.*/httpd-trust = 127.0.0.1/" $AGENT_CFG
sed -i .4.bak -Ee "s/^logger *=.*/logger = File/" $AGENT_CFG
sed -i .5.bak -Ee "s/^#?logfile *=.*/logfile = \/var\/log\/glpi-agent.log/" $AGENT_CFG
sed -i .6.bak -Ee "s/^#?logfile-maxsize *=.*/logfile-maxsize = 10/" $AGENT_CFG
sed -i .7.bak -Ee "s/^#?include \"conf\.d\/\"/include \"conf.d\"/" $AGENT_CFG
rm -f $AGENT_CFG*.bak

echo "Create build-info.plist..."
cat >pkg/build-info.plist <<-BUILD_INFO
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
	    <key>distribution_style</key>
	    <true/>
	    <key>identifier</key>
	    <string>org.glpi-project.glpi-agent</string>
	    <key>install_location</key>
	    <string>/</string>
	    <key>name</key>
	    <string>GLPI-Agent-${VERSION}_$ARCH.pkg</string>
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
BUILD_INFO
if [ -n "$INSTSIGNID" ]; then
    cat >>pkg/build-info.plist <<-BUILD_INFO
	    <key>signing_info</key>
	    <dict>
	        <key>identity</key>
	        <string>$INSTSIGNID</string>
BUILD_INFO
if [ -n "$KEYCHAIN" ]; then
    cat >>pkg/build-info.plist <<-BUILD_INFO
	        <key>keychain</key>
	        <string>$KEYCHAIN</string>
BUILD_INFO
fi
    cat >>pkg/build-info.plist <<-BUILD_INFO
	        <key>timestamp</key>
	        <true/>
	    </dict>
BUILD_INFO
fi
if [ -n "$NOTARIZE_USER" -a -n "$NOTARIZE_PASSWORD" -a "$NOTARIZE" == "yes" ]; then
    cat >>pkg/build-info.plist <<-BUILD_INFO
	    <key>notarization_info</key>
	    <dict>
	        <key>username</key>
	        <string>$NOTARIZE_USER</string>
	        <key>password</key>
	        <string>$NOTARIZE_PASSWORD</string>
	    </dict>
BUILD_INFO
fi
cat >>pkg/build-info.plist <<-BUILD_INFO
	</dict>
	</plist>
BUILD_INFO

cat >pkg/product-requirements.plist <<-REQUIREMENTS
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
	    <key>os</key>
	    <array>
	        <string>$MACOSX_DEPLOYMENT_TARGET</string>
	    </array>
	    <key>arch</key>
	    <array>
	        <string>$ARCH</string>
	    </array>
	</dict>
	</plist>
REQUIREMENTS

# Code signing
if [ -n "$APPSIGNID" ]; then
    echo "Signing code..."
    while read file
    do
        [ -e "$file" ] || continue
        codesign --options runtime -s "$APPSIGNID" --timestamp "$file" \
            && let ++SIGNED
    done <<CODE_SIGNING
pkg/payload/Applications/GLPI-Agent/bin/perl
pkg/scripts/dmidecode
$(find pkg/payload -name '*.bundle')
CODE_SIGNING
    echo "Signed files: $SIGNED"
fi

PKG="GLPI-Agent-${VERSION}_$ARCH.pkg"
DMG="GLPI-Agent-${VERSION}_$ARCH.dmg"

echo "Prepare distribution installer..."
cat >pkg/Distribution.xml <<-CUSTOM
	<?xml version="1.0" encoding="utf-8" standalone="no"?>
	<installer-gui-script minSpecVersion="2">
	    <title>GLPI-Agent $VERSION ($ARCH)</title>
	    <pkg-ref id="org.glpi-project.glpi-agent" version="$VERSION" onConclusion="none">$PKG</pkg-ref>
	    <license file="License.txt" mime-type="text/plain" />
	    <background file="background.png" uti="public.png" alignment="bottomleft"/>
	    <background-darkAqua file="background.png" uti="public.png" alignment="bottomleft"/>
	    <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>
	    <options customize="never" require-scripts="false" hostArchitectures="$ARCH"/>
	    <choices-outline>
	        <line choice="default">
	            <line choice="org.glpi-project.glpi-agent"/>
	        </line>
	    </choices-outline>
	    <choice id="default"/>
	    <choice id="org.glpi-project.glpi-agent" visible="false">
	        <pkg-ref id="org.glpi-project.glpi-agent"/>
	    </choice>
	    <os-version min="$MACOSX_DEPLOYMENT_TARGET" />
	</installer-gui-script>
CUSTOM

echo "Build package"
./munkipkg pkg

mv -vf "pkg/build/$PKG" "build/$PKG"

# Signature check
[ -n "$INSTSIGNID" ] && pkgutil --check-signature "build/$PKG"

# Notarization check
[ -n "$NOTARIZE_USER" -a -n "$NOTARIZE_PASSWORD" -a "$NOTARIZE" == "yes" ] && xcrun stapler validate "build/$PKG"

rm -f "build/$DMG"
echo "Create DMG"
hdiutil create -volname "GLPI-Agent $VERSION ($ARCH) installer" -fs "HFS+" -srcfolder "build/$PKG" "build/$DMG"

# Sign dmg file
if [ -n "$APPSIGNID" ]; then
    echo "Signing DMG..."
    codesign -s "$APPSIGNID" --timestamp "build/$DMG"
    #pkgutil --check-signature "build/$DMG"
fi

ls -l build/*.pkg build/*.dmg
