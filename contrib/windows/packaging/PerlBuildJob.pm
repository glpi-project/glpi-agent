package
    PerlBuildJob;

use parent 'Exporter';

use constant {
    PERL_VERSION       => "5.36.0",
    PERL_BUILD_STEPS   => 8,
};

our @EXPORT = qw(build_job PERL_VERSION PERL_BUILD_STEPS);

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
                'dmake'         => _tools('dmake-warn_20170512'),
                'pexports'      => _tools('pexports-0.47-bin_20170426'),
                'patch'         => _tools('patch-2.5.9-7-bin_20100110_UAC'),
                #gcc, gmake, gdb & co.
                'gcc-toolchain' => { url=>_gcctoolchain(), install_to=>'c' },
                'gcc-license'   => _gcctoolchainlicense(),
                #libs
                'bzip2'         => _gcclib('2019Q2','bzip2-1.0.6'),
                'db'            => _gcclib('2019Q2','db-6.2.38'),
                'expat'         => _gcclib('2019Q2','expat-2.2.6'),
                'fontconfig'    => _gcclib('2019Q2','fontconfig-2.13.1'),
                'freeglut'      => _gcclib('2020Q1','freeglut-2.8.1', '20200209'),
                'freetype'      => _gcclib('2019Q2','freetype-2.10.0'),
                'gdbm'          => _gcclib('2019Q2','gdbm-1.18'),
                'giflib'        => _gcclib('2019Q2','giflib-5.1.9'),
                'gmp'           => _gcclib('2019Q2','gmp-6.1.2'),
                'graphite2'     => _gcclib('2019Q2','graphite2-1.3.13'),
                'harfbuzz'      => _gcclib('2019Q2','harfbuzz-2.3.1'),
                'jpeg'          => _gcclib('2019Q2','jpeg-9c'),
                'libffi'        => _gcclib('2020Q1','libffi-3.3'),
                'libgd'         => _gcclib('2019Q2','libgd-2.2.5'),
                'liblibiconv'   => _gcclib('2019Q2','libiconv-1.16'),
                'libidn2'       => _gcclib('2019Q2','libidn2-2.1.1'),
                'liblibpng'     => _gcclib('2019Q2','libpng-1.6.37'),
                'liblibssh2'    => _gcclib('2019Q2','libssh2-1.8.2'),
                'libunistring'  => _gcclib('2019Q2','libunistring-0.9.10'),
                'liblibxml2'    => _gcclib('2019Q2','libxml2-2.9.9'),
                'liblibXpm'     => _gcclib('2019Q2','libXpm-3.5.12'),
                'liblibxslt'    => _gcclib('2019Q2','libxslt-1.1.33'),
                'mpc'           => _gcclib('2019Q2','mpc-1.1.0'),
                'mpfr'          => _gcclib('2019Q2','mpfr-4.0.2'),
                'openssl'       => _gcclib('2021Q1','openssl-1.1.1i'),
                'readline'      => _gcclib('2019Q2','readline-8.0'),
                't1lib'         => _gcclib('2019Q2','t1lib-5.1.2'),
                'termcap'       => _gcclib('2019Q2','termcap-1.3.1'),
                'tiff'          => _gcclib('2019Q2','tiff-4.0.10'),
                'xz'            => _gcclib('2019Q2','xz-5.2.4'),
                'zlib'          => _gcclib('2019Q2','zlib-1.2.11'),
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
            ],
        },
        ### NEXT STEP 2 Build perl #############################################
        {
            plugin     => 'Perl::Dist::Strawberry::Step::InstallPerlCore',
            url        => _perl_source_url(),
            cf_email   => 'strawberry-perl@project', #IMPORTANT: keep 'strawberry-perl' before @
            perl_debug => 0,    # can be overridden by --perl_debug=N option
            perl_64bitint => 1, # ignored on 64bit, can be overridden by --perl_64bitint | --noperl_64bitint option
            buildoptextra => '-D__USE_MINGW_ANSI_STDIO',
            patch => { #DST paths are relative to the perl src root
                'contrib/windows/packaging/agentexe.ico'        => 'win32/agentexe.ico',
                'contrib/windows/packaging/win32_config.gc.tt'  => 'win32/config.gc',
                'contrib/windows/packaging/agentexe.rc.tt'      => 'win32/perlexe.rc',
                'contrib/windows/packaging/win32_config_H.gc'   => 'win32/config_H.gc',
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
                    Parse::EDID Cpanel::JSON::XS JSON::PP YAML::Tiny Parallel::ForkManager
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
            ],
        };
}

sub _is64bit {
    return $ARCH eq 'x64' ? 1 : 0;
}

sub _bits {
    return $ARCH eq 'x64' ? 64 : 32;
}

sub _perl_source_url {
    return 'https://www.cpan.org/src/5.0/perl-'.PERL_VERSION.'.tar.gz'
}

sub _tools {
    my ($tool) = @_;
    my $bits = _bits();
    return '<package_url>/kmx/'.$bits.'_tools/'.$bits.'bit_'.$tool.'.zip';
}

sub _gcctoolchain {
    my $bits = _bits();
    return '<package_url>/kmx/'.$bits.'_gcctoolchain/mingw64-w'.$bits.'-gcc8.3.0_20190316.zip';
}

sub _gcctoolchainlicense {
    my $bits = _bits();
    return '<package_url>/kmx/'.$bits.'_gcctoolchain/mingw64-w'.$bits.'-gcc8.3.0_20190316-lic.zip';
}

sub _gcclib {
    my ($quarter, $lib, $date) = @_;
    my $bits = _bits();
    unless ($date) {
        my %date = qw( 2019Q2 20190522 2020Q1 20200207 2020Q3 20200712 2021Q1 20210124);
        $date = $date{$quarter};
    }
    return '<package_url>/kmx/'.$bits.'_libs/gcc83-'.$quarter.'/'.$bits.'bit_'.$lib.'-bin_'.$date.'.zip';
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
