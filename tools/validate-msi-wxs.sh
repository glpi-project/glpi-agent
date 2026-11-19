#! /bin/sh

set -e

if [ ! -e Makefile.PL ] || ! grep -q GLPI-Agent Makefile.PL; then
    echo "You must run this script from base of glpi-agent sources"
    exit 1
fi

[ -d "build/windows/lib" ] || mkdir -p build/windows/lib

if [ ! -d "build/windows/lib/Perl-Dist-Strawberry" ]; then
    rm -f build/windows/lib/Perl-Dist-Strawberry-master.zip
    curl -s -L -o build/windows/lib/Perl-Dist-Strawberry-master.zip https://github.com/g-bougard/Perl-Dist-Strawberry/archive/refs/heads/master.zip
    if [ ! -s "build/windows/lib/Perl-Dist-Strawberry-master.zip" ]; then
        echo "Failed to download Perl-Dist-Strawberry archive"
        exit 2
    fi
    unzip -q build/windows/lib/Perl-Dist-Strawberry-master.zip -d build/windows/lib
    mv -f build/windows/lib/Perl-Dist-Strawberry-master build/windows/lib/Perl-Dist-Strawberry

    # Patch our Perl-Dist-Strawberry folder to work in our context without unused hard-coded requirements
    sed -ri -e 's/\$self->global->\{dist_sharedir}/# \$self->global->{dist_sharedir}/' build/windows/lib/Perl-Dist-Strawberry/lib/Perl/Dist/Strawberry.pm
fi

exec perl -It/lib/fake/windows -Ibuild/windows/lib/Perl-Dist-Strawberry/lib contrib/windows/glpi-agent-packaging.pl --arch x64 --no-build --code-signing=no --no-test
