package
    ToolchainBuildJob;

use parent 'Exporter';

use constant {
    # Toolchain setup
    TOOLCHAIN_BASE_URL  => 'https://github.com/brechtsanders/winlibs_mingw/releases/download',
    TOOLCHAIN_VERSION   => '13.3.0posix-11.0.1-msvcrt-r1',
    TOOLCHAIN_ARCHIVE   => 'winlibs-x86_64-posix-seh-gcc-13.3.0-mingw-w64msvcrt-11.0.1-r1.zip',
};

sub toolchain_build_steps {
    my ($arch) = @_;

    return {
        app_simplename  => "extlibs",
        app_version     => sprintf("%d.%d.%d.%d", (localtime)[5 ,7 ,2 ,1]),
        bits            => $arch eq 'x64' ? 64 : 32,
        build_job_steps => [
            ### FIRST STEP 0 : Toolchain download & install ####################
            {
                plugin              => 'Perl::Dist::Strawberry::Step::ToolChain',
                install_packages    => {
                    'gcc-toolchain' => {
                        url         => TOOLCHAIN_BASE_URL . "/" . TOOLCHAIN_VERSION . "/" . TOOLCHAIN_ARCHIVE,
                    }
                }
            },
            ### NEXT STEP 1 : Toolchain update #################################
            {
                plugin          => 'Perl::Dist::Strawberry::Step::ToolChainUpdate',
                commands        => [
                    { do => 'copyfile', args => [ '<build_dir>/mingw64/bin/mingw32-make.exe', '<build_dir>/mingw64/bin/make.exe' , 1 ] },
                    { do => 'copyfile', args => [ '<build_dir>/mingw64/bin/mingw32-make.exe', '<build_dir>/mingw64/bin/gmake.exe', 1 ] },
                ],
            },
            ### NEXT STEP 2 : Msys2-base download ##############################
            {
                plugin          => 'Perl::Dist::Strawberry::Step::Msys2',
                name            => 'msys2-base',
                version         => '20241208',
                folder          => '2024-12-08',
                url             => 'https://github.com/msys2/msys2-installer/releases/download/<folder>/<name>-x86_64-<version>.tar.xz',
                dest            => 'msys64',
            },
            ### NEXT STEP 3 : Msys2-base update ################################
            {
                plugin          => 'Perl::Dist::Strawberry::Step::Msys2Package',
                name            => 'msys2-utils',
                install         => [ qw( patch diffutils ) ],
                skip_if_file    => 'usr/bin/patch.exe',
                dest            => 'msys64',
            },
            ### NEXT STEP 4 : Toolchain check ##################################
            {
                plugin      => 'Perl::Dist::Strawberry::Step::Control',
                commands    => [
                    { title => 'GCC',   run => 'gcc',   args => [ '--version' ] },
                    { title => 'AR',    run => 'ar' ,   args => [ '--version' ] },
                    { title => 'MAKE',  run => 'make',  args => [ '-v'        ] },
                    { title => 'BASH',  run => 'bash',  args => [ '--version' ] },
                    { title => 'PATCH', run => 'patch', args => [ '--version' ] },
                    { title => 'UNAME', run => 'uname', args => [ '--version' ] },
                    { title => 'DIFF',  run => 'diff',  args => [ '--version' ] },
                ],
            },
            ### NEXT STEP 5 : Build zlib library ###############################
            {
                plugin  => 'Perl::Dist::Strawberry::Step::BuildLibrary',
                name    => 'zlib',
                version => '1.3.1',
                url     => 'https://www.zlib.net/<name>-<version>.tar.gz',
                skip_configure  => 1,
                build_in_srcdir => 1,
                skip_test       => 1,
                skip_if_file    => 'bin/zlib1__.dll',
                make_use_cpus   => 1,
                make_opts       => [
                    '-f<src>/win32/Makefile.gcc',
                    'libz.a', 'zlib1__.dll', 'libz.dll.a', 'SHAREDLIB=zlib1__.dll'
                ],
                install_opts    => [
                    '-f<src>/win32/Makefile.gcc',
                    'install',
                    'SHAREDLIB=zlib1__.dll', 'SHARED_MODE=1', 'prefix=<prefix>',
                    'BINARY_PATH=<prefix>/bin', 'INCLUDE_PATH=<prefix>/include', 'LIBRARY_PATH=<prefix>/lib'
                ],
            },
            ### NEXT STEP 6 : Build xz library #################################
            {
                plugin  => 'Perl::Dist::Strawberry::Step::BuildLibrary',
                name    => 'xz',
                version => '5.6.4',
                url     => 'https://github.com/tukaani-project/<name>/releases/download/v<version>/<name>-<version>.tar.gz',
                skip_if_file    => 'bin/liblzma-5__.dll',
                skip_test       => 1,
                configure_help  => 1,
                patch_libtool   => 1,
                configure_opts  => [
                    '--host=x86_64-w64-mingw32', '--build=x86_64-w64-mingw32', '--srcdir=<src>', '--prefix=<prefix>',
                    '--enable-static=no', '--enable-shared=yes', '--disable-dependency-tracking',
                    # We only need lzma DLL
                    '--disable-xz', '--disable-doc', '--disable-scripts', '--disable-xzdec', '--disable-microlzma',
                    '--disable-lzmadec', '--disable-lzmainfo', '--disable-lzma-links', '--disable-lzip-decoder',
                ],
                make_use_cpus   => 1,
                install_opts    => [ 'install', 'doc_DATA='],
            },
            ### NEXT STEP 7 : Build libiconv library ###########################
            {
                plugin  => 'Perl::Dist::Strawberry::Step::BuildLibrary',
                name    => 'libiconv',
                version => '1.18',
                url     => 'https://ftp.gnu.org/gnu/<name>/<name>-<version>.tar.gz',
                skip_if_file    => 'bin/libiconv-2__.dll',
                skip_test       => 1,
                configure_help  => 1,
                patch_libtool   => 1,
                pre_configure   => [
                    # Fix srclib/relocate.c as libtool wrongly format INSTALLDIR
                    ['sed', '-ri', '-e', 's/^\s*const char \*orig_installdir = INSTALLDIR;/const char *orig_installdir = INSTALLPREFIX "\/lib";/', '<src>/srclib/relocatable.c'],
                ],
                configure_opts  => [
                    '--host=x86_64-w64-mingw32', '--build=x86_64-w64-mingw32', '--srcdir=<src>', '--prefix=<prefix>',
                    '--enable-static=no', '--enable-shared=yes', '--disable-dependency-tracking', '--without-libiconv-prefix',
                    '--without-libintl-prefix', '--disable-rpath', '--disable-nls', '--disable-silent-rules',
                    'CFLAGS=-O2 -I<prefix>/include -mms-bitfields', 'LDFLAGS=-L<prefix>/lib',
                ],
                patches         => [
                    'https://github.com/msys2/MINGW-packages/raw/master/mingw-w64-libiconv/0002-fix-cr-for-awk-in-configure.all.patch',
                    'https://github.com/msys2/MINGW-packages/raw/master/mingw-w64-libiconv/0003-add-cp65001-as-utf8-alias.patch',
                    'https://github.com/msys2/MINGW-packages/raw/master/mingw-w64-libiconv/fix-pointer-buf.patch',
                ],
                post_configure  => [
                    # We don't need to install man pages & binaries
                    ['sed', '-ri', '-e', 's/cd man /#cd man /', '-e', 's/cd src /#cd src /', 'Makefile'],
                ],
                make_use_cpus   => 1,
                install_opts    => [ 'install-strip' ],
                # Inspired by https://github.com/brechtsanders/winlibs_recipes/blob/main/recipes/libiconv.winlib
                install_file    => {
                    '<install_prefix>/lib/pkgconfig/iconv.pc' => [
                        "prefix=<prefix>",
                        "exec_prefix=\${prefix}",
                        "includedir=\${prefix}/include",
                        "libdir=\${prefix}/lib",
                        "",
                        "Name: iconv",
                        "Description: iconv() implementation for use on systems which don't have one",
                        "Version: <version>",
                        "Cflags: ",
                        "Libs: -liconv",
                    ],
                },
            },
            ### NEXT STEP 8 : Build openssl library ############################
            {
                plugin  => 'Perl::Dist::Strawberry::Step::BuildLibrary',
                name    => 'openssl',
                version => '3.4.1',
                url     => 'https://github.com/openssl/openssl/releases/download/<name>-<version>/<name>-<version>.tar.gz',
                skip_if_file    => 'bin/openssl.exe',
                skip_test       => 1,
                configure_help  => 1,
                skip_configure  => 1,
                pre_configure   => [
                    # Fix libname
                    ['sed', '-ri', '-e', 's/"-x64"/"<dllsuffix>"/', '<src>/Configurations/platform/mingw.pm'],
                    ['sed', '-ri', '-e', 's/^LIBRARY  *\$libname/LIBRARY  \${libname}<dllsuffix>/', '<src>/util/mkdef.pl'],
                ],
                post_configure  => [
                    # openssl Configure script is a perl script
                    [
                        'perl', '<src>/Configure', '--release', 'shared', 'zlib-dynamic', 
                        'enable-rfc3779', 'enable-camellia', 'enable-capieng',
                        'enable-idea', 'enable-mdc2', 'enable-rc5',
                        'enable-static-engine', 'no-module', 'no-tests',
                        'no-legacy', 'no-makedepend', 'no-docs',
                        '--prefix=<prefix>', '--libdir=lib',
                        '--openssldir=ssl',
                        '--with-zlib-lib=zlib1<dllsuffix>',
                        '--with-zlib-include=<prefix>/include',
                        '-DOPENSSLBIN="\\"<prefix>/bin\\""',
                        '-DLIBZ="\\"zlib1<dllsuffix>\\""',
                        'mingw64',
                    ],
                ],
                make_use_cpus   => 1,
                install_opts    => [ 'install_runtime', 'install_dev' ],
            },
            ### NEXT STEP 9 : Build libxml2 library ############################
            {
                plugin  => 'Perl::Dist::Strawberry::Step::BuildLibrary',
                name    => 'libxml2',
                version => '2.13.6',
                url     => 'https://download.gnome.org/sources/<name>/2.13/<name>-<version>.tar.xz',
                skip_if_file    => 'bin/libxml2-2__.dll',
                skip_test       => 1,
                configure_help  => 1,
                patch_libtool   => 1,
                configure_opts  => [
                    '--host=x86_64-w64-mingw32', '--build=x86_64-w64-mingw32', '--srcdir=<src>', '--prefix=<prefix>',
                    '--enable-static=no', '--enable-shared=yes', '--disable-dependency-tracking',
                    '--without-python', '--with-modules', '--with-threads=win32',
                    '--with-iconv=<prefix>', '--with-zlib=<prefix>', '--with-lzma=<prefix>',
                    'CFLAGS=-O2 -I<prefix>/include -D__USE_MINGW_ANSI_STDIO=1', 'LDFLAGS=-L<prefix>/lib',
                ],
                post_configure  => [
                    # Avoid to use not required Makefile like documentation
                    ['sed', '-ri', '-e', 's/^SUBDIRS = include . doc example xstc/SUBDIRS = include ./', 'Makefile'],
                ],
                make_use_cpus   => 1,
                make_opts       => [ 'libxml2.la' ],
                install_opts    => [ 'install', 'bin_PROGRAMS=', 'noinst_LTLIBRARIES=', 'cmake_DATA=', 'dist_m4data_DATA=', 'examples_DATA=' ],
            },
            ### NEXT STEP 10 : Build libssh2 library ###########################
            {
                plugin  => 'Perl::Dist::Strawberry::Step::BuildLibrary',
                name    => 'libssh2',
                version => '1.11.1',
                url     => 'https://www.libssh2.org/download/<name>-<version>.tar.xz',
                skip_if_file    => 'bin/libssh2-1__.dll',
                skip_test       => 1,
                configure_help  => 1,
                patch_libtool   => 1,
                configure_opts  => [
                    '--host=x86_64-w64-mingw32', '--build=x86_64-w64-mingw32', '--srcdir=<src>', '--prefix=<prefix>',
                    '--enable-static=no', '--enable-shared=yes', '--disable-dependency-tracking',
                    '--disable-examples-build',
                ],
                make_use_cpus   => 1,
                install_opts    => [ 'install', 'dist_man_MANS=' ],
            },
            ### NEXT STEP 11 : Few cleanup #####################################
            {
                plugin          => 'Perl::Dist::Strawberry::Step::ToolChainUpdate',
                commands        => [
                    { do => 'removefile', args=>[ '<image_dir>/c/bin/c_rehash' ] },
                ],
            },
            ### NEXT STEP 12 : Make zips #######################################
            {
                plugin  => 'Perl::Dist::Strawberry::Step::PackageZIP',
            },
        ]
    };
}

1;
