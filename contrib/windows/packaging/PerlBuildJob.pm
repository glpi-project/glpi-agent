package
    PerlBuildJob;

use parent 'Exporter';

use constant {
    PERL_VERSION       => "5.38.2",
    PERL_BUILD_STEPS   => 7,
    # Always include / at the end of EXTLIBS_BASE_URL
    EXTLIBS_BASE_URL   => 'https://github.com/StrawberryPerl/build-extlibs/releases/download/',
    toolchain          => 'dev_gcc13.1_20230606',
    toolchain_date     => '20230606'
};

our @EXPORT = qw(build_job PERL_VERSION PERL_BUILD_STEPS EXTLIBS_BASE_URL);

my $ARCH = 'x64';

sub build_job {
    my ($arch, $rev) = @_;
### job description for building GLPI Agent

#Available '<..>' macros:
# <package_url>   is placeholder for https://strawberryperl.com/package
# <dist_sharedir> is placeholder for Perl::Dist::Strawberry's distribution sharedir
# <image_dir>     is placeholder for C:\Strawberry-perl-for-GLPI-Agent

    $ARCH = $arch;

    return {
        app_version     => PERL_VERSION.'.'.$rev, #BEWARE: do not use '.0.0' in the last two version digits
        bits            => $arch eq 'x64' ? 64 : 32,
        app_fullname    => 'Strawberry Perl'.($arch eq 'x64'?' (64-bit)':''),
        app_simplename  => 'strawberry-perl',
        maketool        => 'gmake', # 'dmake' or 'gmake'
        build_job_steps => [ _build_steps() ],
    }
}

sub _build_steps {
    my ($MAJOR, $MINOR) = PERL_VERSION =~ /^(\d+)\.(\d+)\./;
    return
        ### FIRST STEP 0 : Binaries donwloads ##################################
        {
            plugin  => 'Perl::Dist::Strawberry::Step::BinaryToolsAndLibs',
            install_packages => {
                #tools
                'patch'         => _tools('patch', '2.7.5', '20230420'),
                #gcc, gmake, gdb & co.
                'gcc-toolchain' => { url=>_gcctoolchain(), install_to=>'c' },
                #libs
                'bzip2'         => _gcclib('bzip2-1.0.6'),
                'db'            => _gcclib('db-6.2.38'),
                'expat'         => _gcclib('expat-2.2.6'),
                'fontconfig'    => _gcclib('fontconfig-2.13.1'),
                'freeglut'      => _gcclib('freeglut-3.4.0'),
                'freetype'      => _gcclib('freetype-2.10.0'),
                'gdbm'          => _gcclib('gdbm-1.19'),
                'giflib'        => _gcclib('giflib-5.1.9'),
                'gmp'           => _gcclib('gmp-6.2.1'),
                'graphite2'     => _gcclib('graphite2-1.3.13'),
                'harfbuzz'      => _gcclib('harfbuzz-2.3.1'),
                'jpeg'          => _gcclib('jpeg-9c'),
                'libffi'        => _gcclib('libffi-3.2.1'),
                'libgd'         => _gcclib('libgd-2.3.3'),
                'libiconv'      => _gcclib('libiconv-1.17'),
                'libidn2'       => _gcclib('libidn2-2.1.1'),
                'libpng'        => _gcclib('libpng-1.6.37'),
                'libssh2'       => _gcclib('libssh2-1.10.0'),
                'libunistring'  => _gcclib('libunistring-1.1'),
                'libxml2'       => _gcclib('libxml2-2.10.4'),
                'libXpm'        => _gcclib('libXpm-3.5.12'),
                'libxslt'       => _gcclib('libxslt-1.1.37'),
                'mpc'           => _gcclib('mpc-1.3.1'),
                'mpfr'          => _gcclib('mpfr-4.2.0'),
                'openssl'       => _gcclib('openssl-1.1.1q'),
                'readline'      => _gcclib('readline-8.2'),
                't1lib'         => _gcclib('t1lib-5.1.2'),
                'termcap'       => _gcclib('termcap-1.3.1'),
                'tiff'          => _gcclib('tiff-4.5.0'),
                'xz'            => _gcclib('xz-5.2.4'),
                'zlib'          => _gcclib('zlib-1.2.11'),
            },
        },
        ### NEXT STEP 1 Binaries cleanup #######################################
        {
            plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
            commands => [
                { do=>'removefile', args=>[ '<image_dir>/c/i686-w64-mingw32/lib/libglut.a', '<image_dir>/c/i686-w64-mingw32/lib/libglut32.a' ] }, #XXX-32bit only workaround
                { do=>'movefile',   args=>[ '<image_dir>/c/lib/libdb-6.1.a', '<image_dir>/c/lib/libdb.a' ] }, #XXX ugly hack
                { do=>'removefile', args=>[ '<image_dir>/c/bin/gccbug', '<image_dir>/c/bin/ld.gold.exe', '<image_dir>/c/bin/ld.bfd.exe' ] },
                { do=>'removefile_recursive', args=>[ '<image_dir>/c', qr/.+\.la$/i ] }, # https://rt.cpan.org/Public/Bug/Display.html?id=127184
                { do=>'make_rw', args=>[ '<image_dir>/c/include/db.h' ] },     #  band-aid for ro flag on db headers
                { do=>'make_rw', args=>[ '<image_dir>/c/include/db_cxx.h' ] },
            ],
        },
        ### NEXT STEP 2 Build perl #############################################
        {
            plugin     => 'Perl::Dist::Strawberry::Step::InstallPerlCore',
            url        => _perl_source_url(),
            cf_email   => 'strawberry-perl@project', #IMPORTANT: keep 'strawberry-perl' before @
            perl_debug => 0,    # can be overridden by --perl_debug=N option
            perl_64bitint => 1, # ignored on 64bit, can be overridden by --perl_64bitint | --noperl_64bitint option
            patch => { #DST paths are relative to the perl src root
                'contrib/windows/packaging/agentexe.ico'        => 'win32/agentexe.ico',
                'contrib/windows/packaging/agentexe.rc.tt'      => 'win32/perlexe.rc',
                'config_H.gc'                                 => {
                    HAS_MKSTEMP => 'define',
                    HAS_BUILTIN_CHOOSE_EXPR => 'define',
                    HAS_SYMLINK             => 'define',
                },
                'config.gc'                                 => {  # see Step.pm for list of default updates
                    d_builtin_choose_expr => 'define',
                    d_mkstemp             => 'define',
                    d_symlink             => 'define', # many cpan modules fail tests when defined
                    osvers                => '10',
                },
            },
            license => { #SRC paths are relative to the perl src root
                'Readme'   => '<image_dir>/licenses/perl/Readme',
                'Artistic' => '<image_dir>/licenses/perl/Artistic',
                'Copying'  => '<image_dir>/licenses/perl/Copying',
            },
        },
        ### NEXT STEP 3 Upgrade CPAN modules ###################################
        {
            plugin => 'Perl::Dist::Strawberry::Step::UpgradeCpanModules',
            exceptions => [
                # possible 'do' options: ignore_testfailure | skiptest | skip - e.g.
                #{ do=>'ignore_testfailure', distribution=>'ExtUtils-MakeMaker-6.72' },
                #{ do=>'ignore_testfailure', distribution=>qr/^IPC-Cmd-/ },
                { do=>'ignore_testfailure', distribution=>qr/^Net-Ping-/ }, # 2.72 fails
                { do=>'skip', distribution => qr/^Filter-/ }, # 1.61 fails
            ]
        },
        ### NEXT STEP 4 Install needed modules with agent dependencies #########
        {
            plugin => 'Perl::Dist::GLPI::Agent::Step::InstallModules',
            modules => [
                # IPC related
                qw/ IPC-Run /,

                # win32 related
                qw/ Win32::API Win32API::Registry Win32::TieRegistry Win32::OLE
                    Win32-Daemon Win32::Job Sys::Syslog /,

                # compression
                qw/ Archive::Extract /,

                # file related
                qw/ File::Copy::Recursive File::Which /,

                # SSL
                qw/ Net-SSLeay Mozilla::CA IO-Socket-SSL /,

                # network
                # https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/72
                { module => 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/dev_20230318/Socket6-0.29_01.tar.gz' },
                qw/ IO::Socket::IP IO::Socket::INET6 HTTP::Daemon /,
                qw/ HTTP-Server-Simple LWP::Protocol::https LWP::UserAgent /,

                # crypto
                qw/ Crypt::DES Crypt::Rijndael /,
                qw/ Digest-SHA /,
                qw/ Digest-MD5 Digest-SHA1 Digest::HMAC /, # Required for SNMP v3 authentication

                # date/time
                qw/ DateTime DateTime::TimeZone::Local::Win32 /,

                # GLPI-Agent deps
                qw/ Text::Template UNIVERSAL::require UNIVERSAL::isa Net::SSH2
                    XML::LibXML Memoize Time::HiRes Compress::Zlib
                    Parse::EDID Cpanel::JSON::XS YAML::Tiny Parallel::ForkManager
                    URI::Escape Net::NBName Thread::Queue Thread::Semaphore
                    Net::SNMP Net::SNMP::Security::USM Net::SNMP::Transport::IPv4::TCP
                    Net::SNMP::Transport::IPv6::TCP Net::SNMP::Transport::IPv6::UDP
                    Net::IP Win32::Unicode::File Data::UUID Archive::Zip /,
                # For Wake-On-LAN task
                #qw/ Net::Write::Layer2 /,
            ],
        },
        ### NEXT STEP 5 ########################################################
        {
            plugin => 'Perl::Dist::Strawberry::Step::FixShebang',
            shebang => '#!perl',
        },
        ### NEXT STEP 6 Clean up ###############################################
        {
            plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
            commands => [
                # cleanup (remove unwanted files/dirs)
                { do=>'removefile', args=>[ '<image_dir>/perl/vendor/lib/Crypt/._test.pl', '<image_dir>/perl/vendor/lib/DBD/testme.tmp.pl' ] },
                { do=>'removefile_recursive', args=>[ '<image_dir>/perl', qr/.+\.dll\.AA[A-Z]$/i ] },
                # cleanup cpanm related files
                { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread-64int' ] },
                { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread' ] },
                { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x64-multi-thread' ] },
                { do=>'removedir', args=>[ '<image_dir>/licenses' ] },
                { do=>'removefile', args=>[ '<image_dir>/etc/gdbinit' ] },
                { do=>'removefile_recursive', args=>[ '<image_dir>/perl', qr/^\.packlist$/i ] },
                { do=>'removefile_recursive', args=>[ '<image_dir>/perl', qr/\.pod$/i ] },
                { do=>'removefile_recursive', args=>[ '<image_dir>/perl', qr/\.a$/i ] },
            ],
        },
        ### NEXT STEP 7 Install modules for test ###############################
        {
            plugin => 'Perl::Dist::GLPI::Agent::Step::Test',
            modules => [
                qw(
                    HTTP::Proxy HTTP::Server::Simple::Authen IO::Capture::Stderr
                    Test::Compile Test::Deep Test::MockModule Test::MockObject
                    Test::NoWarnings
                )
            ],
        },
        ### NEXT STEP 8 Clean up and finalize perl envirtonment ################
        {
            plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
            commands => [
                { do=>'createdir', args=>[ '<image_dir>/perl/newbin' ] },
                _movebin('libgcc_s_'.(_is64bit()?'seh':'dw2').'-1.dll'),
                _movebin('libstdc++-6.dll'),
                _movebin('libwinpthread-1.dll'),
                _movebin('perl.exe'),
                _movebin('perl'.$MAJOR.$MINOR.'.dll'),
                # Also move DLLs required by modules
                _movedll('libxml2-2'),
                _movedll('liblzma-5'),
                _movedll('libiconv-2'),
                _movedll('libcrypto-1_1'.(_is64bit()?'-x64':'')),
                _movedll('libssl-1_1'.(_is64bit()?'-x64':'')),
                _movedll('zlib1'),
                _movedll('libssh2-1'),
                { do=>'removedir', args=>[ '<image_dir>/perl/bin' ] },
                { do=>'movedir', args=>[ '<image_dir>/perl/newbin', '<image_dir>/perl/bin' ] },
                { do=>'movefile', args=>[ '<image_dir>/c/bin/gmake.exe', '<image_dir>/perl/bin/gmake.exe' ] }, # Needed for tests
                { do=>'removedir', args=>[ '<image_dir>/bin' ] },
                { do=>'removedir', args=>[ '<image_dir>/c' ] },
                { do=>'removedir', args=>[ '<image_dir>/'.(_is64bit()?'x86_64':'i686').'-w64-mingw32' ] },
                { do=>'removedir', args=>[ '<image_dir>/include' ] },
                { do=>'removedir', args=>[ '<image_dir>/lib' ] },
                { do=>'removedir', args=>[ '<image_dir>/libexec' ] },
                # Other binaries used by agent
                { do=>'copyfile', args=>[ 'contrib/windows/packaging/tools/x86/dmidecode.exe', '<image_dir>/perl/bin' ] },
                { do=>'copyfile', args=>[ 'contrib/windows/packaging/tools/x86/hdparm.exe', '<image_dir>/perl/bin' ] },
                { do=>'copyfile', args=>[ 'contrib/windows/packaging/tools/'.$ARCH.'/7z.exe', '<image_dir>/perl/bin' ] },
                { do=>'copyfile', args=>[ 'contrib/windows/packaging/tools/'.$ARCH.'/7z.dll', '<image_dir>/perl/bin' ] },
                { do=>'copyfile', args=>[ 'contrib/windows/packaging/tools/'.$ARCH.'/GLPI-AgentMonitor-'.$ARCH.'.exe', '<image_dir>/perl/bin' ] },
            ],
        };
}

sub _is64bit {
    return $ARCH eq 'x64' ? 1 : 0;
}

sub _perl_source_url {
    return 'https://www.cpan.org/src/5.0/perl-'.PERL_VERSION.'.tar.gz'
}

sub _package_url {
    my ($folder, $file) = @_;
    return '<package_url>' . $folder . '/' . $file;
}

sub _tools {
    my ($tool, $version, $date) = @_;
    $date = toolchain_date unless $date;
    my $folder = $date eq '20230420' ? 'dev_gcc10.3_20230313' : toolchain_date;
    return _package_url($folder, '64bit_' . $tool . '-' . $version . '-bin_' . $date . '.zip');
}

sub _gcctoolchain {
    return _package_url(toolchain, 'winlibs_gcc13.1r5.zip');
}

sub _gcclib {
    my ($lib) = @_;
    return _package_url(toolchain, '64bit_' . $lib . '-bin_' . toolchain_date . '.zip');
}

sub _movebin {
    my ($bin) = @_;
    return {
        do      => 'movefile',
        args    => [
            '<image_dir>/perl/bin/'.$bin,
            '<image_dir>/perl/newbin/'.$bin
        ]
    };
}

sub _movedll {
    my ($dll, $to) = @_;
    my $file = $dll.(_is64bit()?'__':'_').'.dll';
    return {
        do      => 'movefile',
        args    => [
            '<image_dir>/c/bin/'.$file,
            '<image_dir>/perl/newbin/'.$file
        ]
    };
}

1;
