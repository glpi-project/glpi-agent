package
    PerlBuildJob;

use parent 'Exporter';

use ToolchainBuildJob;

use constant {
    PERL_VERSION       => "5.42.0",
    # Tag for dmidecode release on glpi-project/dmidecode
    DMIDECODE_VERSION  => "3.6-update-1",
    # Tag for Glpi-AgentMonitor release on glpi-project/glpi-agentmonitor
    GAMONITOR_VERSION  => "1.4.1",
    PERL_BUILD_STEPS   => 12,
};

our @EXPORT = qw(build_job PERL_VERSION PERL_BUILD_STEPS);

sub build_job {
    my ($arch, $rev, $notest, $dllsuffix) = @_;
### job description for building GLPI Agent

#Available '<..>' macros:
# <package_url>   is placeholder for https://strawberryperl.com/package
# <dist_sharedir> is placeholder for Perl::Dist::Strawberry's distribution sharedir
# <image_dir>     is placeholder for C:\Strawberry-perl-for-GLPI-Agent

    my ($MAJOR, $MINOR) = PERL_VERSION =~ /^(\d+)\.(\d+)\./;

    return {
        app_version     => PERL_VERSION.'.'.$rev, #BEWARE: do not use '.0.0' in the last two version digits
        bits            => $arch eq 'x64' ? 64 : 32,
        app_fullname    => 'Strawberry Perl'.($arch eq 'x64'?' (64-bit)':''),
        app_simplename  => 'strawberry-perl',
        maketool        => 'gmake', # 'dmake' or 'gmake'
        build_job_steps => [

        ### FIRST STEP 0 : Binaries donwloads ##################################
        {
            plugin  => 'Perl::Dist::GLPI::Agent::Step::ToolChain',
            packages => [
                {
                    name        => 'winlibs-x86_64',
                    file        => ToolchainBuildJob::TOOLCHAIN_ARCHIVE(),
                },
                {
                    name        => 'extlibs',
                    file        => 'extlibs.zip',
                    install_to  => 'mingw64',
                }
            ],
        },
        ### NEXT STEP 1 Binaries cleanup #######################################
        {
            plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
            commands => [
                { do => 'movedir', args => [ '<image_dir>/mingw64', '<image_dir>/c' ] },
                { do => 'removefile_recursive', args => [ '<image_dir>/c', qr/.+\.la$/i ] }, # https://rt.cpan.org/Public/Bug/Display.html?id=127184
                { do => 'copyfile', args => [ '<image_dir>/c/bin/mingw32-make.exe', '<image_dir>/c/bin/gmake.exe', 1 ] },
            ],
        },
        ### NEXT STEP 2 Build perl #############################################
        {
            plugin     => 'Perl::Dist::GLPI::Agent::Step::InstallPerlCore',
            url        => 'https://www.cpan.org/src/5.0/perl-'.PERL_VERSION.'.tar.gz',
            cf_email   => 'strawberry-perl@project', #IMPORTANT: keep 'strawberry-perl' before @
            perl_debug => 0,    # can be overridden by --perl_debug=N option
            perl_64bitint => 1, # ignored on 64bit, can be overridden by --perl_64bitint | --noperl_64bitint option
            # Remove not required locale support to fix a locale support issue
            buildoptextra => '-DNO_LOCALE',
            patch => { #DST paths are relative to the perl src root
                'contrib/windows/packaging/agentexe.ico'    => 'win32/agentexe.ico',
                'contrib/windows/packaging/agentexe.rc.tt'  => 'win32/perlexe.rc',
                'contrib/windows/packaging/Makefile.patch'  => 'win32/GNUmakefile',
                'contrib/windows/packaging/makedef.patch'   => 'makedef.pl',
                'config_H.gc'   => {
                    HAS_MKSTEMP             => 'define',
                    HAS_BUILTIN_CHOOSE_EXPR => 'define',
                },
                'config.gc'     => {  # see Step.pm for list of default updates
                    d_builtin_choose_expr => 'define',
                    d_mkstemp             => 'define',
                    osvers                => '10',
                },
            },
            license => { #SRC paths are relative to the perl src root
                'Readme'   => '<image_dir>/licenses/perl/Readme',
                'Artistic' => '<image_dir>/licenses/perl/Artistic',
                'Copying'  => '<image_dir>/licenses/perl/Copying',
            },
        },
        ### NEXT STEP 3 : Sign perl DLL ########################################
        {
            plugin => 'CustomCodeSigning',
            files  => [
                '<image_dir>/perl/bin/perl'.$MAJOR.$MINOR.'.dll',
            ],
        },
        ### NEXT STEP 4 Upgrade CPAN modules ###################################
        {
            plugin => 'Perl::Dist::Strawberry::Step::UpgradeCpanModules',
        },
        ### NEXT STEP 5 Install needed modules with agent dependencies #########
        {
            plugin => 'Perl::Dist::GLPI::Agent::Step::InstallModules',
            modules => [
                # IPC related
                qw/ IPC-Run /,

                # win32 related
                qw/ Win32::API Win32API::Registry Win32::TieRegistry Win32::OLE
                    Win32-Daemon Win32::Job Sys::Syslog /,

                # file related
                qw/ File::Copy::Recursive File::Which /,

                # SSL
                qw/ Net-SSLeay Mozilla::CA IO-Socket-SSL /,

                # network
                # https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/72
                # https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/156#issuecomment-1835573792
                { module => 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/patched_cpan_modules/Socket6-0.29_02.tar.gz' },
                qw/ IO::Socket::IP IO::Socket::INET6 HTTP::Daemon /,
                qw/ HTTP-Server-Simple LWP::Protocol::https LWP::UserAgent /,

                # crypto
                { module => 'https://github.com/g-bougard/Crypt-DES/releases/download/2.07_01/Crypt-DES-2.07_01.tar.gz' }, # Patched Crypt::DES
                qw/ Crypt::Rijndael /,
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
                    Net::IP Data::UUID Archive::Zip /,
                { module => 'https://github.com/g-bougard/win32-unicode/releases/download/0.38_02/Win32-Unicode-0.38_02.tar.gz' }, # Patched Win32::Unicode
                # For Wake-On-LAN task
                #qw/ Net::Write::Layer2 /,
            ],
        },
        ### NEXT STEP 6 ########################################################
        {
            plugin => 'Perl::Dist::Strawberry::Step::FixShebang',
            shebang => '#!perl',
        },
        ### NEXT STEP 7 Clean up ###############################################
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
            ],
        },
        ### NEXT STEP 8 Install modules for test ###############################
        {
            plugin => 'Perl::Dist::GLPI::Agent::Step::InstallModules',
            modules => [ map {
                    {
                        module => $_,
                        skiptest => 1,
                        install_to => 'site',
                    }
                } qw(
                    HTTP::Proxy HTTP::Server::Simple::Authen IO::Capture::Stderr
                    Test::Compile Test::Deep Test::MockModule Test::MockObject
                    Test::NoWarnings
                )
            ],
        },
        ### NEXT STEP 9 : Sign MSI ############################################
        {
            plugin => 'CustomCodeSigning',
            dlls   => [
                '<image_dir>/perl/lib/auto',
                '<image_dir>/perl/vendor/lib/auto',
            ],
        },
        ### NEXT STEP 10 Clean up and finalize perl envirtonment ################
        {
            plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
            commands => [
                { do=>'createdir', args=>[ '<image_dir>/perl/newbin' ] },
                _movebin('libgcc_s_'.($arch eq 'x64' ? 'seh' : 'dw2').'-1.dll'),
                _movebin('libstdc++-6.dll'),
                _movebin('libwinpthread-1.dll'),
                _movebin('perl.exe'),
                _movebin('perl'.$MAJOR.$MINOR.'.dll'),
                # Also move DLLs required by modules
                _movedll('libxml2-16', $dllsuffix),
                _movedll('liblzma-5', $dllsuffix),
                _movedll('libcharset-1', $dllsuffix),
                _movedll('libiconv-2', $dllsuffix),
                _movedll('libcrypto-3', $dllsuffix),
                _movedll('libssl-3', $dllsuffix),
                _movedll('zlib1', $dllsuffix),
                _movedll('libssh2-1', $dllsuffix),
                { do=>'removedir', args=>[ '<image_dir>/perl/bin' ] },
                { do=>'movedir', args=>[ '<image_dir>/perl/newbin', '<image_dir>/perl/bin' ] },
                { do=>'movefile', args=>[ '<image_dir>/c/bin/gmake.exe', '<image_dir>/perl/bin/gmake.exe' ] }, # Needed for tests
                { do=>'removefile_recursive', args=>[ '<image_dir>/perl', qr/\.a$/i ] },
                { do=>'removedir', args=>[ '<image_dir>/bin' ] },
                { do=>'removedir', args=>[ '<image_dir>/c' ] },
                { do=>'removedir', args=>[ '<image_dir>/'.($arch eq 'x64' ? 'x86_64' : 'i686').'-w64-mingw32' ] },
                { do=>'removedir', args=>[ '<image_dir>/include' ] },
                { do=>'removedir', args=>[ '<image_dir>/lib' ] },
                { do=>'removedir', args=>[ '<image_dir>/libexec' ] },
                # Other binaries used by agent
                { do=>'copyfile', args=>[ 'contrib/windows/packaging/tools/x86/hdparm.exe', '<image_dir>/perl/bin' ] },
                { do=>'copyfile', args=>[ 'contrib/windows/packaging/tools/'.$arch.'/7z.exe', '<image_dir>/perl/bin' ] },
                { do=>'copyfile', args=>[ 'contrib/windows/packaging/tools/'.$arch.'/7z.dll', '<image_dir>/perl/bin' ] },
            ],
        },
        ### NEXT STEP 11 Installation with direct github download ##############
        {
            plugin      => 'Perl::Dist::GLPI::Agent::Step::Github',
            downloads   => [
                {
                    name    => 'dmidecode',
                    project	=> 'glpi-project/dmidecode',
                    release => DMIDECODE_VERSION,
                    file    => 'dmidecode.exe',
                    folder  => '<image_dir>/perl/bin',
                },
                {
                    name    => 'GLPI-AgentMonitor',
                    project	=> 'glpi-project/glpi-agentmonitor',
                    release => GAMONITOR_VERSION,
                    file    => 'GLPI-AgentMonitor-'.$arch.'.exe',
                    folder  => '<image_dir>/perl/bin',
                },
            ],
        },
        ### NEXT STEP 12 Run GLPI Agent test suite #############################
        {
            plugin      => 'Perl::Dist::GLPI::Agent::Step::Test',
            disable     => $notest,
            # By default only t/01compile.t is run
            test_files  => [
                #~ qw(t/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t t/*/*/*/*/*.t t/*/*/*/*/*/*.t)
            ],
            skip_tests  => [
                # Fails if not run as administrator
                #~ qw(t/agent/config.t)
            ],
        },
        ### NEXT STEP 13 Finalize environment ##################################
        {
            plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
            commands => [
                # Cleanup modules and files used for tests
                { do=>'removedir', args=>[ '<image_dir>/perl/site/lib' ] },
                { do=>'createdir', args=>[ '<image_dir>/perl/site/lib' ] },
                { do=>'removefile', args=>[ '<image_dir>/perl/bin/gmake.exe' ] },
                # updates for glpi-agent
                { do=>'createdir', args=>[ '<image_dir>/perl/agent' ] },
                { do=>'createdir', args=>[ '<image_dir>/var' ] },
                { do=>'createdir', args=>[ '<image_dir>/logs' ] },
                { do=>'movefile', args=>[ '<image_dir>/perl/bin/perl.exe', '<image_dir>/perl/bin/glpi-agent.exe' ] },
                { do=>'copydir', args=>[ 'lib/GLPI', '<image_dir>/perl/agent/GLPI' ] },
                { do=>'copydir', args=>[ 'lib/GLPI', '<image_dir>/perl/agent/GLPI' ] },
                { do=>'copydir', args=>[ 'etc', '<image_dir>/etc' ] },
                { do=>'createdir', args=>[ '<image_dir>/etc/conf.d' ] },
                { do=>'copydir', args=>[ 'bin', '<image_dir>/perl/bin' ] },
                { do=>'copydir', args=>[ 'share', '<image_dir>/share' ] },
                { do=>'copyfile', args=>[ 'contrib/windows/packaging/setup.pm', '<image_dir>/perl/lib' ] },
            ],
        },
        ### NEXT STEP 14 : Sign MSI ############################################
        {
            plugin => 'CustomCodeSigning',
            files  => [
                '<image_dir>/perl/bin/glpi-agent.exe',
            ],
        },
        ### NEXT STEP 15 Finalize release ######################################
        {
            plugin => 'Perl::Dist::GLPI::Agent::Step::Update',
        },
        ### NEXT STEP 16 Generate Portable Archive #############################
        {
            plugin => 'Perl::Dist::Strawberry::Step::OutputZIP',
        },
        ### NEXT STEP 17 Generate MSI Package ##################################
        {
            plugin => 'Perl::Dist::GLPI::Agent::Step::OutputMSI',
            exclude  => [],
            #BEWARE: msi_upgrade_code is a fixed value for all same arch releases (for ever)
            msi_upgrade_code    => $arch eq 'x64' ? '0DEF72A8-E5EE-4116-97DC-753718E19CD5' : '7F25A9A4-BCAE-4C15-822D-EAFBD752CFEC',
            app_publisher       => "Teclib'",
            url_about           => 'https://glpi-project.org/',
            url_help            => 'https://glpi-project.org/discussions/',
            msi_root_dir        => 'GLPI-Agent',
            msi_main_icon       => 'contrib/windows/packaging/glpi-agent.ico',
            msi_license_rtf     => 'contrib/windows/packaging/gpl-2.0.rtf',
            msi_dialog_bmp      => 'contrib/windows/packaging/GLPI-Agent_Dialog.bmp',
            msi_banner_bmp      => 'contrib/windows/packaging/GLPI-Agent_Banner.bmp',
            msi_debug           => 0,
        },
        ### NEXT STEP 18 : Sign MSI ############################################
        {
            plugin => 'CustomCodeSigning',
            files  => [
                {
                    name        => '<output_basename>.msi',
                    filename    => '<output_dir>/<output_basename>.msi',
                },
            ],
        },
        ],
    }
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
    my ($dll, $suffix) = @_;
    my $file = $dll.$suffix.'.dll';
    return {
        do      => 'movefile',
        args    => [
            '<image_dir>/c/bin/'.$file,
            '<image_dir>/perl/newbin/'.$file
        ]
    };
}

1;
