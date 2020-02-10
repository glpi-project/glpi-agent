#!perl

use strict;
use warnings;

use Win32::TieRegistry qw( KEY_READ );

use constant {
    PERL_VERSION        => "5.30.1",
    PACKAGE_REVISION    => "1", #BEWARE: always start with 1
};

# Perl::Dist::Strawberry doesn't detect WiX 3.11 which is installed on windows githib images
# Algorithm imported from Perl::Dist::Strawberry::Step::OutputMSM_MSI::_detect_wix_dir
my $wixbin_dir;
for my $v (qw/3.0 3.5 3.6 3.11/) {
    my $WIX_REGISTRY_KEY = "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows Installer XML/$v";
    # 0x200 = KEY_WOW64_32KEY
    my $r = Win32::TieRegistry->new($WIX_REGISTRY_KEY => { Access => KEY_READ|0x200, Delimiter => q{/} });
    next unless $r;
    my $d = $r->TiedRef->{'InstallRoot'};
    next unless $d && -d $d && -f "$d/candle.exe" && -f "$d/light.exe";
    $wixbin_dir = $d;
    last;
}

die "Can't find WiX installation root in regitry\n" unless $wixbin_dir;

my $app = Perl::Dist::GLPI::Agent->new(
    _perl_version   => PERL_VERSION,
    _revision       => PACKAGE_REVISION,
);

$app->parse_options(
    -job            => "glpi-agent packaging",
    -image_dir      => "C:\\GLPI-Agent",
    -working_dir    => "C:\\GLPI-Agent_build",
    -wixbin_dir     => $wixbin_dir,
    -notest_modules,
    -nointeractive,
    @ARGV
);

print "Building 64 bits packages...\n";
$app->global->{arch} = 64;
$app->do_job()
    or exit 1;

print "Building 32 bits packages...\n";
$app->global->{arch} = 32;
$app->do_job()
    or exit 1;

print "All packages building processing passed\n";

exit(0);

package
    Perl::Dist::GLPI::Agent;

use parent qw(Perl::Dist::Strawberry);

use lib 'lib';
use FusionInventory::Agent::Version;

my $VERSION = $FusionInventory::Agent::Version::VERSION;
my $PROVIDER = $FusionInventory::Agent::Version::PROVIDER;

sub build_job_pre {
    my ($self) = @_;
    $self->SUPER::build_job_pre();

    # Fix output basename
    $self->global->{output_basename} = $PROVIDER."-Agent-".$VERSION;
}

sub build_job_post {
    my ($self) = @_;
    $self->SUPER::build_job_post();
}

sub load_jobfile {
    my ($self) = @_;

    return $self->__job();
}

sub is64bit {
    my ($self) = @_;
    return $self->global->{arch} == 64;
}

sub __tools {
    my ($self, $tool) = @_;
    my $arch = $self->global->{arch};
    return '<package_url>/kmx/'.$arch.'_tools/'.$arch.'bit_'.$tool.'.zip';
}

sub __gcctoolchain {
    my ($self) = @_;
    my $arch = $self->global->{arch};
    return '<package_url>/kmx/'.$arch.'_gcctoolchain/mingw64-w'.$arch.'-gcc8.3.0_20190316.zip';
}

sub __gcclib {
    my ($self, $date, $lib) = @_;
    my $arch = $self->global->{arch};
    return '<package_url>/kmx/'.$arch.'_libs/gcc83-'.$date.'/'.$arch.'bit_'.$lib.
        '-bin_'.($date eq '2020Q1' ? '20200207' : '20190522').'.zip';
}

sub __perl_source_url {
    my ($self) = @_;
    return 'http://cpan.metacpan.org/authors/id/S/SH/SHAY/' .
        'perl-'.$self->global->{_perl_version}.'.tar.gz';
}

sub __job {
    my ($self) = @_;
### job description for building GLPI Agent

#Available '<..>' macros:
# <package_url>   is placeholder for http://strawberryperl.com/package
# <dist_sharedir> is placeholder for Perl::Dist::Strawberry's distribution sharedir
# <image_dir>     is placeholder for c:\strawberry
    return {
        app_version     => $self->global->{_perl_version}.'.'.$self->global->{_revision}, #BEWARE: do not use '.0.0' in the last two version digits
        bits            => $self->global->{arch},
        beta            => 0,
        app_fullname    => 'Strawberry Perl'.($self->is64bit?' (64-bit)':''),
        app_simplename  => 'strawberry-perl',
        maketool        => 'gmake', # 'dmake' or 'gmake'
        build_job_steps => [ $self->__job_steps() ],
    }
}

sub __job_steps {
    my ($self) = @_;
    my ($PERL_MAJORMINOR) = $self->global->{_perl_version} =~ /^(\d+\.\d+)\./;
    return
    ### NEXT STEP ###########################
    {
        plugin  => 'Perl::Dist::Strawberry::Step::BinaryToolsAndLibs',
        install_packages => {
            #tools
            'dmake'         => $self->__tools('dmake-warn_20170512'),
            'pexports'      => $self->__tools('pexports-0.47-bin_20170426'),
            'patch'         => $self->__tools('patch-2.5.9-7-bin_20100110_UAC'),
            #gcc, gmake, gdb & co.
            'gcc-toolchain' => { url=>$self->__gcctoolchain(), install_to=>'c' },
            'gcc-license'   => $self->__gcctoolchain(),
            #libs
            'bzip2'         => $self->__gcclib('2019Q2','bzip2-1.0.6'),
            'db'            => $self->__gcclib('2019Q2','db-6.2.38'),
            'expat'         => $self->__gcclib('2019Q2','expat-2.2.6'),
            'fontconfig'    => $self->__gcclib('2019Q2','fontconfig-2.13.1'),
            'freeglut'      => $self->__gcclib('2019Q2','freeglut-3.0.0'),
            'freetype'      => $self->__gcclib('2019Q2','freetype-2.10.0'),
            'gdbm'          => $self->__gcclib('2019Q2','gdbm-1.18'),
            'giflib'        => $self->__gcclib('2019Q2','giflib-5.1.9'),
            'gmp'           => $self->__gcclib('2019Q2','gmp-6.1.2'),
            'graphite2'     => $self->__gcclib('2019Q2','graphite2-1.3.13'),
            'harfbuzz'      => $self->__gcclib('2019Q2','harfbuzz-2.3.1'),
            'jpeg'          => $self->__gcclib('2019Q2','jpeg-9c'),
            'libffi'        => $self->__gcclib('2020Q1','libffi-3.3'),
            'libgd'         => $self->__gcclib('2019Q2','libgd-2.2.5'),
            'liblibiconv'   => $self->__gcclib('2019Q2','libiconv-1.16'),
            'libidn2'       => $self->__gcclib('2019Q2','libidn2-2.1.1'),
            'liblibpng'     => $self->__gcclib('2019Q2','libpng-1.6.37'),
            'liblibssh2'    => $self->__gcclib('2019Q2','libssh2-1.8.2'),
            'libunistring'  => $self->__gcclib('2019Q2','libunistring-0.9.10'),
            'liblibxml2'    => $self->__gcclib('2019Q2','libxml2-2.9.9'),
            'liblibXpm'     => $self->__gcclib('2019Q2','libXpm-3.5.12'),
            'liblibxslt'    => $self->__gcclib('2019Q2','libxslt-1.1.33'),
            'mpc'           => $self->__gcclib('2019Q2','mpc-1.1.0'),
            'mpfr'          => $self->__gcclib('2019Q2','mpfr-4.0.2'),
            'openssl'       => $self->__gcclib('2020Q1','openssl-1.1.1d'),
            'readline'      => $self->__gcclib('2019Q2','readline-8.0'),
            't1lib'         => $self->__gcclib('2019Q2','t1lib-5.1.2'),
            'termcap'       => $self->__gcclib('2019Q2','termcap-1.3.1'),
            'tiff'          => $self->__gcclib('2019Q2','tiff-4.0.10'),
            'xz'            => $self->__gcclib('2019Q2','xz-5.2.4'),
            'zlib'          => $self->__gcclib('2019Q2','zlib-1.2.11'),
        },
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
       commands => [
         { do=>'removefile', args=>[ '<image_dir>/c/i686-w64-mingw32/lib/libglut.a', '<image_dir>/c/i686-w64-mingw32/lib/libglut32.a' ] }, #XXX-32bit only workaround
         { do=>'movefile',   args=>[ '<image_dir>/c/lib/libdb-6.1.a', '<image_dir>/c/lib/libdb.a' ] }, #XXX ugly hack
         { do=>'removefile', args=>[ '<image_dir>/c/bin/gccbug', '<image_dir>/c/bin/ld.gold.exe', '<image_dir>/c/bin/ld.bfd.exe' ] },
         { do=>'removefile_recursive', args=>[ '<image_dir>/c', qr/.+\.la$/i ] }, # https://rt.cpan.org/Public/Bug/Display.html?id=127184
       ],
    },
    ### NEXT STEP ###########################
    {
        plugin     => 'Perl::Dist::Strawberry::Step::InstallPerlCore',
        url        => $self->__perl_source_url(),
        cf_email   => 'strawberry-perl@project', #IMPORTANT: keep 'strawberry-perl' before @
        perl_debug => 0,    # can be overridden by --perl_debug=N option
        perl_64bitint => 1, # ignored on 64bit, can be overridden by --perl_64bitint | --noperl_64bitint option
        buildoptextra => '-D__USE_MINGW_ANSI_STDIO',
        patch => { #DST paths are relative to the perl src root
            '<dist_sharedir>/msi/files/perlexe.ico'             => 'win32/perlexe.ico',
            '<dist_sharedir>/perl-'.$PERL_MAJORMINOR.'/win32_config.gc.tt'      => 'win32/config.gc',
            '<dist_sharedir>/perl-'.$PERL_MAJORMINOR.'/perlexe.rc.tt'           => 'win32/perlexe.rc',
            '<dist_sharedir>/perl-'.$PERL_MAJORMINOR.'/win32_config_H.gc'       => 'win32/config_H.gc', # enables gdbm/ndbm/odbm
        },
        license => { #SRC paths are relative to the perl src root
            'Readme'   => '<image_dir>/licenses/perl/Readme',
            'Artistic' => '<image_dir>/licenses/perl/Artistic',
            'Copying'  => '<image_dir>/licenses/perl/Copying',
        },
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::UpgradeCpanModules',
        exceptions => [
          # possible 'do' options: ignore_testfailure | skiptest | skip - e.g. 
          #{ do=>'ignore_testfailure', distribution=>'ExtUtils-MakeMaker-6.72' },
          #{ do=>'ignore_testfailure', distribution=>qr/^IPC-Cmd-/ },
          { do=>'ignore_testfailure', distribution=>qr/^Net-Ping-/ }, # 2.72 fails
        ]
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        modules => [
            { module=>'Path::Tiny', ignore_testfailure=>1 }, #XXX-TODO 5.30 t/zzz-spec.t fails https://github.com/dagolden/Path-Tiny/issues/228
            'TAP::Harness::Restricted', #to be able to skip only some tests
            # IPC related
            { module=>'IPC-Run', skiptest=>1 }, #XXX-TODO trouble with 'Terminating on signal SIGBREAK(21)' https://metacpan.org/release/IPC-Run
            { module=>'IPC-System-Simple', ignore_testfailure=>1 }, #XXX-TODO t/07_taint.t fails https://metacpan.org/release/IPC-System-Simple
            qw/ IPC-Run3 /,

            { module=>'LWP::UserAgent', skiptest=>1 }, # XXX-HACK: 6.08 is broken

            # install cpanm as soon as possible
            qw/ App::cpanminus /,

            #removed from core in 5.20
            qw/ Module::Build /,
            { module=>'Archive::Extract',  ignore_testfailure=>1 }, #XXX-TODO-5.28/64bit

            # win32 related
            qw/Win32API::Registry Win32::TieRegistry/,
            { module=>'Win32::OLE',         ignore_testfailure=>1 }, #XXX-TODO: ! Testing Win32-OLE-0.1711 failed
            { module=>'Win32::API',         ignore_testfailure=>1 }, #XXX-TODO: https://rt.cpan.org/Public/Bug/Display.html?id=107450
            qw/ Win32-Daemon /,
            qw/ Win32::Job /,
            qw/ Sys::Syslog /,

            # compression
            { module=>'Archive::Zip', ignore_testfailure=>1 }, #XXX-TODO t/25_traversal.t
            qw/ IO-Compress-Lzma Compress-unLZMA /,

            # file related
            { module=>'File::Copy::Recursive', ignore_testfailure=>1 }, #XXX-TODO-5.28
            qw/ File-Which /,
            qw/ IO::All /,

            # SSL & SSH & telnet
            { module=>'Net-SSLeay', ignore_testfailure=>1 }, # openssl-1.1.1 related
            'Mozilla::CA', # optional dependency of IO-Socket-SSL
            { module=>'IO-Socket-SSL', skiptest=>1, env=>{ 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/nonblock.t t/mitm.t t/verify_fingerprint.t t/session_ticket.t t/sni_verify.t' } },

            # network
            qw/ IO::Socket::IP IO::Socket::INET6 /,
            qw/ HTTP-Server-Simple /,
            qw/ LWP::UserAgent /,
            { module=>'LWP::Protocol::https', env=>{ 'HARNESS_SUBCLASS'=>'TAP::Harness::Restricted', 'HARNESS_SKIP'=>'t/https_proxy.t' } }, #https://rt.perl.org/Ticket/Display.html?id=132863
            { module=>'<package_url>/kmx/perl-modules-patched/Crypt-SSLeay-0.72_patched.tar.gz' }, #XXX-FIXME

            # XML & co.
            qw/ XML-LibXML XML-Parser /,

            # crypto
            qw/ CryptX Crypt::OpenSSL::Bignum Crypt::OpenSSL::DSA Crypt-OpenSSL-RSA Crypt-OpenSSL-Random Crypt-OpenSSL-X509 /,
            'KMX/Crypt-OpenSSL-AES-0.05.tar.gz', #XXX-FIXME patched https://metacpan.org/pod/Crypt::OpenSSL::AES  https://rt.cpan.org/Public/Bug/Display.html?id=77605
            qw/ Crypt::CBC Crypt::Blowfish Crypt::CAST5_PP Crypt::DES Crypt::DES_EDE3 Crypt::DSA Crypt::IDEA Crypt::Rijndael Crypt::Twofish Crypt::Serpent Crypt::RC6 /,
            qw/ Digest-MD2 Digest-MD5 Digest-SHA Digest-SHA1 Crypt::RIPEMD160 Digest::Whirlpool Digest::HMAC Digest::CMAC /,
            'Alt::Crypt::RSA::BigInt',  #hack Crypt-RSA without Math::PARI - https://metacpan.org/release/Crypt-RSA
            qw/ Crypt-DSA Crypt::DSA::GMP /,

            qw/ Bytes::Random::Secure Crypt::OpenPGP /,

            # date/time
            { module=>'Test2::Plugin::NoWarnings', ignore_testfailure=>1 }, #otherwise DateTime fails
            qw/ DateTime Date::Format DateTime::Format::DateParse DateTime::TimeZone::Local::Win32 /,

            # par & ppm
            qw/ PAR PAR::Dist::FromPPD PAR::Dist::InstallPPD PAR::Repository::Client /,
            # The build path in ppm.xml is derived from $ENV{TMP}. So set TMP to a dedicated location inside of the
            # distribution root to prevent it being locked to the temp directory of the build machine.
            { module=>'<package_url>/kmx/perl-modules-patched/PPM-11.11_04.tar.gz', env=>{ TMP=>'<image_dir>\ppm' } }, #XXX-FIXME

            # misc
            { module=>'Unicode::UTF8', ignore_testfailure=>1 }, #XXX-TODO-5.28

            # GLPI-Agent deps
            qw/ File::Which Text::Template UNIVERSAL::require XML::TreePP XML::XPath /,
            qw/ Memoize Time::HiRes Compress::Zlib Win32::Unicode::File /,
            qw/ Parse::EDID JSON::PP YAML::Tiny Parallel::ForkManager URI::Escape /,
            qw/ Net::NBName Thread::Queue Thread::Semaphore /,
            qw/ Net::SNMP Net::SNMP::Security::USM Net::SNMP::Transport::IPv4::TCP
                Net::SNMP::Transport::IPv6::TCP Net::SNMP::Transport::IPv6::UDP /,
            # For Wake-On-LAN task
            #qw/ Net::Write::Layer2 /,
        ],
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::FixShebang',
        shebang => '#!perl',
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
       commands => [
         # directories
         { do=>'createdir', args=>[ '<image_dir>/cpan' ] },
         { do=>'createdir', args=>[ '<image_dir>/cpan/sources' ] },
         { do=>'createdir', args=>[ '<image_dir>/win32' ] },
         # templated files
         { do=>'apply_tt', args=>[ '<dist_sharedir>/config-files/CPAN_Config.pm.tt', '<image_dir>/perl/lib/CPAN/Config.pm', {}, 1 ] }, #XXX-temporary empty tt_vars, no_backup=1
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/README.txt.tt', '<image_dir>/README.txt' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/DISTRIBUTIONS.txt.tt', '<image_dir>/DISTRIBUTIONS.txt' ] },
         # fixed files
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/licenses/License.rtf', '<image_dir>/licenses/License.rtf' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/relocation.pl.bat',    '<image_dir>/relocation.pl.bat' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/update_env.pl.bat',    '<image_dir>/update_env.pl.bat' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/win32/cpan.ico',       '<image_dir>/win32/cpan.ico' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/win32/onion.ico',      '<image_dir>/win32/onion.ico' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/win32/perldoc.ico',    '<image_dir>/win32/perldoc.ico' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/win32/perlhelp.ico',   '<image_dir>/win32/perlhelp.ico' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/win32/strawberry.ico', '<image_dir>/win32/strawberry.ico' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/win32/win32.ico',      '<image_dir>/win32/win32.ico' ] },
         { do=>'copyfile', args=>[ '<dist_sharedir>/extra-files/win32/metacpan.ico',   '<image_dir>/win32/metacpan.ico' ] },
         # URLs
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/CPAN Module Search.url.tt',                  '<image_dir>/win32/CPAN Module Search.url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/MetaCPAN Search Engine.url.tt',              '<image_dir>/win32/MetaCPAN Search Engine.url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Learning Perl (tutorials, examples).url.tt', '<image_dir>/win32/Learning Perl (tutorials, examples).url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Live Support (chat).url.tt',                 '<image_dir>/win32/Live Support (chat).url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Perl Documentation.url.tt',                  '<image_dir>/win32/Perl Documentation.url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Strawberry Perl Release Notes.url.tt',       '<image_dir>/win32/Strawberry Perl Release Notes.url' ] },
         { do=>'apply_tt', args=>[ '<dist_sharedir>/extra-files/win32/Strawberry Perl Website.url.tt',             '<image_dir>/win32/Strawberry Perl Website.url' ] },
         # cleanup (remove unwanted files/dirs)
         { do=>'removefile', args=>[ '<image_dir>/perl/vendor/lib/Crypt/._test.pl', '<image_dir>/perl/vendor/lib/DBD/testme.tmp.pl' ] },
         { do=>'removefile', args=>[ '<image_dir>/perl/bin/nssm_32.exe.bat', '<image_dir>/perl/bin/nssm_64.exe.bat' ] },
         { do=>'removefile_recursive', args=>[ '<image_dir>/perl', qr/.+\.dll\.AA[A-Z]$/i ] },
         { do=>'removedir', args=>[ '<image_dir>/perl/bin/freeglut.dll' ] }, #XXX OpenGL garbage
         # cleanup cpanm related files
         { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread-64int' ] },
         { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread' ] },
         { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x64-multi-thread' ] },
       ],
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::CreateRelocationFile',
       reloc_in  => '<dist_sharedir>/relocation/relocation.txt.initial',
       reloc_out => '<image_dir>/relocation.txt',
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputZIP', # no options needed
    },
    ### NEXT STEP ###########################
    {
       disable => $ENV{SKIP_MSI_STEP}, ### hack
       plugin => 'Perl::Dist::Strawberry::Step::OutputMSI',
       exclude  => [
           #'dirname\subdir1\subdir2',
           #'dirname\file.pm',
           'relocation.pl.bat',
           'update_env.pl.bat',
       ],
       #BEWARE: msi_upgrade_code is a fixed value for all same arch releases (for ever)
       msi_upgrade_code    => $self->is64bit ? '0DEF72A8-E5EE-4116-97DC-753718E19CD5' : '7F25A9A4-BCAE-4C15-822D-EAFBD752CFEC', 
       app_publisher       => 'strawberryperl.com project',
       url_about           => 'http://strawberryperl.com/',
       url_help            => 'http://strawberryperl.com/support.html',
       msi_root_dir        => 'Strawberry',
       msi_main_icon       => '<dist_sharedir>\msi\files\strawberry.ico',
       msi_license_rtf     => '<dist_sharedir>\msi\files\License-short.rtf',
       msi_dialog_bmp      => '<dist_sharedir>\msi\files\StrawberryDialog.bmp',
       msi_banner_bmp      => '<dist_sharedir>\msi\files\StrawberryBanner.bmp',
       msi_debug           => 0,

       start_menu => [ # if "description" is missing it will be set to the same value as "name"
         { type=>'shortcut', name=>'Perl (command line)', icon=>'<dist_sharedir>\msi\files\perlexe.ico', description=>'Quick way to get to the command line in order to use Perl', target=>'[SystemFolder]cmd.exe', workingdir=>'PersonalFolder' },
         { type=>'shortcut', name=>'Strawberry Perl Release Notes', icon=>'<dist_sharedir>\msi\files\strawberry.ico', target=>'[d_win32]Strawberry Perl Release Notes.url', workingdir=>'d_win32' },
         { type=>'shortcut', name=>'Strawberry Perl README', target=>'[INSTALLDIR]README.txt', workingdir=>'INSTALLDIR' },
         { type=>'folder',   name=>'Tools', members=>[
              { type=>'shortcut', name=>'CPAN Client', icon=>'<dist_sharedir>\msi\files\cpan.ico', target=>'[d_perl_bin]cpan.bat', workingdir=>'d_perl_bin' },
              { type=>'shortcut', name=>'Create local library areas', icon=>'<dist_sharedir>\msi\files\strawberry.ico', target=>'[d_perl_bin]llw32helper.bat', workingdir=>'d_perl_bin' },
         ] },
         { type=>'folder', name=>'Related Websites', members=>[
              { type=>'shortcut', name=>'CPAN Module Search', icon=>'<dist_sharedir>\msi\files\cpan.ico', target=>'[d_win32]CPAN Module Search.url', workingdir=>'d_win32' },
              { type=>'shortcut', name=>'MetaCPAN Search Engine', icon=>'<dist_sharedir>\msi\files\metacpan.ico', target=>'[d_win32]MetaCPAN Search Engine.url', workingdir=>'d_win32' },
              { type=>'shortcut', name=>'Perl Documentation', icon=>'<dist_sharedir>\msi\files\perldoc.ico', target=>'[d_win32]Perl Documentation.url', workingdir=>'d_win32' },
              { type=>'shortcut', name=>'Strawberry Perl Website', icon=>'<dist_sharedir>\msi\files\strawberry.ico', target=>'[d_win32]Strawberry Perl Website.url', workingdir=>'d_win32' },
              { type=>'shortcut', name=>'Learning Perl (tutorials, examples)', icon=>'<dist_sharedir>\msi\files\perldoc.ico', target=>'[d_win32]Learning Perl (tutorials, examples).url', workingdir=>'d_win32' },
              { type=>'shortcut', name=>'Live Support (chat)', icon=>'<dist_sharedir>\msi\files\onion.ico', target=>'[d_win32]Live Support (chat).url', workingdir=>'d_win32' },
         ] },
       ],
       env => {
         #TERM => "dumb",
       },
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::InstallModules',
        # modules specific to portable edition
        modules => [ 'Portable' ],
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::SetupPortablePerl', # no options needed
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
        commands => [ # files and dirs specific to portable edition
            { do=>'removefile', args=>[ '<image_dir>/README.txt', '<image_dir>/perl2.reloc.txt', '<image_dir>/perl1.reloc.txt', '<image_dir>/relocation.txt',
                                        '<image_dir>/update_env.pl.bat', '<image_dir>/relocation.pl.bat' ] },
            { do=>'createdir',  args=>[ '<image_dir>/data' ] },
            { do=>'apply_tt',   args=>[ '<dist_sharedir>/portable/portable.perl.tt',       '<image_dir>/portable.perl', {
                gcchost => $self->is64bit ? 'x86_64-w64-mingw32' : 'i686-w64-mingw32',
                gccver=>'8.3.0'} ]
            },
            { do=>'copyfile',   args=>[ '<dist_sharedir>/portable/portableshell.bat',      '<image_dir>/portableshell.bat' ] },
            { do=>'apply_tt',   args=>[ '<dist_sharedir>/portable/README.portable.txt.tt', '<image_dir>/README.txt' ] },
            # cleanup cpanm related files
            { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread-64int' ] },
            { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread' ] },
            { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x64-multi-thread' ] },
       ],
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputPortableZIP', # no options needed
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::CreateReleaseNotes', # no options needed
    },
    ### NEXT STEP ###########################
    {
       plugin => 'Perl::Dist::Strawberry::Step::OutputLogZIP', # no options needed
    };
}
