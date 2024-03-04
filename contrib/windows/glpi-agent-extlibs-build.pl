#!perl

use strict;
use warnings;

use File::Spec;
use Cwd qw(abs_path);
use File::Spec::Functions qw(catfile);

use constant {
    PROVIDED_BY         => "Teclib Edition",
};

use lib 'lib';
use GLPI::Agent::Version;

use lib abs_path(File::Spec->rel2abs('../packaging', __FILE__));
use ToolchainBuildJob;

BEGIN {
    # HACK: make "use Perl::Dist::ToolChain::Step::XXX" works as included plugin
    map { $INC{"Perl/Dist/Strawberry/Step/$_.pm"} = __FILE__ } qw(Control BuildLibrary ToolChain ToolChainUpdate Msys2 Msys2Package BuildPackage PackageZIP);
}

my $provider = $GLPI::Agent::Version::PROVIDER;
my $version = $GLPI::Agent::Version::VERSION;

sub toolchain_builder {
    my ($bits, $notest, $clean) = @_;

    die "32 bits toolchain build not supported\n"
        if $bits == 32;

    my $cpus = 0;
    if (open my $fh, "-|", "wmic cpu get NumberOfCores") {
        while (<$fh>) {
            next unless /^(\d+)/;
            my $count = int($1);
            $cpus = $count if $count > 1;
            last;
        }
        close($fh);
    }

    my $app = Perl::Dist::ToolChain->new(
        _provided_by        => PROVIDED_BY,
        _no_test            => $notest,
        _clean              => $clean,
        arch                => $bits == 32 ? "x86" : "x64",
        _dllsuffix          => '__',
        _cpus               => $cpus,
    );

    # We use same working_dir to share cached download folder in GH Actions
    $app->parse_options(
        -image_dir      => "C:\\Strawberry-perl-for-$provider-Agent",
        -working_dir    => "C:\\Strawberry-perl-for-$provider-Agent_build",
        -nointeractive,
        -norestorepoints,
    );

    return $app;
}

my %do = ();
my $notest = 0;
my $clean  = 0;
while ( @ARGV ) {
    my $arg = shift @ARGV;
    if ($arg eq "--arch") {
        my $arch = shift @ARGV;
        next unless $arch =~ /^x(86|64)$/;
        $do{$arch} = $arch eq "x86" ? 32 : 64 ;
    } elsif ($arg eq "--all") {
        %do = ( x86 => 32, x64 => 64);
    } elsif ($arg eq "--no-test") {
        $notest = 1;
    } elsif ($arg eq "--clean") {
        $clean = 1;
    }
}

# Still select a defaut arch if none has been selected
$do{x64} = 64 unless keys(%do);

foreach my $bits (sort values(%do)) {
    print "Building $bits bits toolchain packages for $provider-Agent $version...\n";
    my $tcb = toolchain_builder($bits, $notest, $clean);
    $tcb->do_job();
    exit(1) unless -e catfile($tcb->global->{debug_dir}, 'global_dump_FINAL.txt');
}

print "All toolchain packages building processing passed\n";

exit(0);

package
    Perl::Dist::ToolChain;

use parent qw(Perl::Dist::Strawberry);

use File::Spec::Functions qw(catdir catfile);
use File::Path qw(make_path remove_tree);
use File::Slurp qw(write_file);

sub ask_about_dirs {}
sub ask_about_restorepoint {}
sub ask_about_build_details {}

sub create_dirs {
    my ($self) = @_;

    # Between builds, only cleanup env_dir and debug_dir
    remove_tree($self->global->{debug_dir});
    remove_tree($self->global->{env_dir});

    # Cleanup image_dir && build_dir when clean option is used
    remove_tree($self->global->{image_dir}) if $self->global->{_clean};
    remove_tree($self->global->{build_dir}) if $self->global->{_clean};

    # Create only if not exists
    map {
        -d $self->global->{$_} or make_path($self->global->{$_}) or die "ERROR: cannot create '".$self->global->{$_}."'\n";
    } qw(
        image_dir
        working_dir
        download_dir
        build_dir
        debug_dir
        output_dir
        env_dir
    );

    # Create temp in env_dir
    make_path(catdir($self->global->{env_dir}, 'temp')) or die "ERROR: cannot create '".$self->global->{env_dir}."/temp'\n";
}

sub load_jobfile {
    my ($self) = @_;

    return ToolchainBuildJob::toolchain_build_steps($self->global->{arch});
}

sub prepare_build_ENV {
    my ($self) = @_;

    my @path = split /;/ms, $ENV{PATH};
    my @winlibs_path = (
        catdir($self->global->{build_dir}, qw/mingw64 bin/),
    );
    my @mingw_path = (
        catdir($self->global->{build_dir}, qw/msys64/),
        catdir($self->global->{build_dir}, qw/msys64 usr bin/),
    );

    my @new_path = (@mingw_path, @winlibs_path);
    foreach my $p (@path) {
        next if not -d $p; # Strip any path that doesn't exist
        # Strip any path outside of the windows directories. This is done by testing for kernel32.dll and win.ini
        next if ! (-f catfile( $p, 'kernel32.dll' ) || -f catfile( $p, 'win.ini' ));
        # Strip any path related to locally installed strawberry perl environment
        next if $p =~ /Strawberry/;
        push @new_path, $p;
    }
    $self->global->{build_ENV} = {
        LIB             => undef,
        INCLUDE         => undef,
        TEMP            => catdir($self->global->{env_dir}, 'temp'),
        TMP             => catdir($self->global->{env_dir}, 'temp'),
        COMPUTERNAME    => 'buildmachine',
        USERNAME        => 'builduser',
        TERM            => 'dumb',
        LANG            => 'en_US.UTF-8',
        PATH            => join(';', @new_path),
        MINGW_PATH      => join(';', @mingw_path),
        WINLIBS_PATH    => join(';', @winlibs_path),
        MSYSTEM         => 'MINGW64',
        BINARY_PATH     => 'bin',
        LIBRARY_PATH    => 'lib',
        INCLUDE_PATH    => 'include',
        CHERE_INVOKING  => 1,
        CHOST           => 'x86_64-w64-mingw32', # Required to build zlib
    };

    # Create batch file '<debug_dir>/cmd_with_env.bat' for debugging #XXX-FIXME maybe move this somewhere else
    my $env = $self->global->{build_ENV};
    my $set_env = '';
    $set_env .= "set $_=" . (defined $env->{$_} ? $env->{$_} : '') . "\n" for (sort keys %$env);
    write_file(catfile($self->global->{debug_dir}, 'cmd_with_env.bat'), "\@echo off\n\n$set_env\ncmd /K\n");
}

package
    Perl::Dist::Strawberry::Step::ToolChain;

use parent qw(Perl::Dist::Strawberry::Step::BinaryToolsAndLibs);

use File::Spec::Functions qw(catdir);

sub _extract {
    my ($self, $from) = @_;

    return $self->SUPER::_extract($from, $self->global->{build_dir})
        unless -d catdir($self->global->{build_dir}, 'mingw64');

    $self->boss->message(2, "* toolchain still installed");
}

package
    Perl::Dist::Strawberry::Step::ToolChainUpdate;

use parent qw(Perl::Dist::Strawberry::Step::FilesAndDirs);

use File::Spec::Functions qw(catdir);

sub _resolve_args {
    my ($self, $args) = @_;

    my @args;
    foreach my $arg (@{$args}) {
        map {
            my $var = $self->global->{$_};
            $arg =~ s/<$_>/$var/g
        } qw( image_dir build_dir working_dir );
        push @args, $arg;
    }

    return \@args;
}

sub run {
    my ($self) = @_;

    foreach my $command (@{$self->{config}->{commands}}) {
        $command->{args} = $self->_resolve_args($command->{args});
    }

    return $self->SUPER::run(@_);
}

package
    Perl::Dist::Strawberry::Step::Control;

use parent qw(Perl::Dist::Strawberry::Step);

sub run {
    my ($self) = @_;

    foreach my $cmd (@{$self->{config}->{commands}}) {
        $self->boss->message(2, "#### $cmd->{title}") if $cmd->{title};
        $self->execute_special([ $cmd->{run}, @{$cmd->{args} || []} ])
            and die "failed to run  $cmd->{title}\n";
    }

    return 1;
}

package
    Perl::Dist::Strawberry::Step::Msys2;

use parent qw(Perl::Dist::Strawberry::Step);

use File::Spec::Functions qw(catdir catfile);

sub _resolve {
    my ($self, $string) = @_;
    map { $self->{config}->{$_} && $string =~ s/<$_>/$self->{config}->{$_}/g } qw(
        name version folder src absolute_src dllsuffix prefix install_prefix
    );
    return $string;
}

sub run {
    my ($self) = @_;

    $self->boss->message(2, "#### $self->{config}->{name} v$self->{config}->{version}");

    my $folder = $self->_resolve($self->{config}->{dest} || "<name>-<version>");
    my $dst = catdir($self->global->{build_dir}, $folder);
    my $log = catfile($self->global->{debug_dir}, "$self->{config}->{name}.log.txt");
    if (-d $dst) {
        $self->boss->message(2, "* $folder still extracted: skipping archive download and extraction");
    } else {
        # Download library archive
        my $url = $self->_resolve($self->{config}->{url});
        $self->boss->message(2, "* archive url: $url");
        my $archive = $self->boss->mirror_url($url, $self->global->{download_dir});
        $self->_extract($archive, $self->global->{build_dir});
        $self->boss->message(2, "* running shell to initialize msys64 environment and install patch");
        # Initialize msys64 environment and synchronize pacman db command at the same time
        $self->execute_special(
            [catfile($self->global->{build_dir}, 'msys64', 'msys2_shell.cmd'), '-no-start', '-defterm', '-c', 'pacman -Sy'],
            $log
        ) and die "msys2 initialization failure\n";
    }
}

package
    Perl::Dist::Strawberry::Step::Msys2Package;

use parent qw(Perl::Dist::Strawberry::Step);

use File::Spec::Functions qw(catfile);

sub run {
    my ($self) = @_;

    if ($self->{config}->{skip_if_file}) {
        my $file = catfile($self->global->{build_dir}, $self->{config}->{dest}, $self->{config}->{skip_if_file});
        if (-e $file) {
            $self->boss->message(2, "* skipping as still done");
            return;
        }
    }

    foreach my $pkg (@{$self->{config}->{install}}) {
        $self->boss->message(2, "#### Installing $pkg");

        my $log = catfile($self->global->{debug_dir}, "$self->{config}->{name}-$pkg.log.txt");
        $self->execute_special(
            [catfile($self->global->{build_dir}, 'msys64', 'msys2_shell.cmd'), '-no-start', '-defterm', '-c', 'pacman -S --noconfirm '.$pkg],
            $log
        ) and die "$self->{config}->{name} installation failure\n";
    }
}

package
    Perl::Dist::Strawberry::Step::BuildLibrary;

use parent qw(Perl::Dist::Strawberry::Step::Msys2);

use File::Spec::Functions qw(catdir catfile);
use File::Path qw(make_path remove_tree);
use File::Find;

use Archive::Tar;
use IO::Uncompress::UnXz;

# Fix native implementation to ignore symlink, at least required par libxml2 archive
sub _extract {
    my ($self, $from, $to) = @_;

    return $self->SUPER::_extract($from, $to)
        unless $from =~ /\.(tar\.gz|tgz|tar\.xz|tar\.bz2|tbz|tar)$/i;

    File::Path::mkpath($to);
    my $wd = $self->_push_dir($to);

    my @filelist;

    $self->boss->message( 2, "* extracting '$from'" );

    local $Archive::Tar::CHMOD = 0;
    local $Archive::Tar::RESOLVE_SYMLINK = 'none';

    my $tar;
    if ($from !~ /xz$/) {
        $tar = Archive::Tar->new($from, 1)
            or die "Can't read archive: $!\n";
    } else {
        my $xz = IO::Uncompress::UnXz->new($from, BlockSize => 16_384);
        $tar = Archive::Tar->new($xz)
            or die "Can't read archive: $!\n";
    }

    foreach my $file ($tar->get_files()) {
        if (!$file->is_file && !$file->is_dir) {
            $self->boss->message( 3, "* skipping '".$file->name."'" );
        } else {
            $file->extract()
                or die "Failed to extract '".$file->name."': $!\n";
        }
    }
}

sub run {
    my ($self) = @_;

    $self->boss->message(2, "#### $self->{config}->{name} v$self->{config}->{version}");
    if ($self->{config}->{skip}) {
        $self->boss->message(2, "* skipping");
        return;
    }

    if ($self->{config}->{skip_if_file}) {
        my $file = catfile($self->global->{image_dir}, 'c', $self->{config}->{skip_if_file});
        if (-e $file) {
            $self->boss->message(2, "* skipping as still built");
            return;
        }
    }

    my $folder = $self->_resolve($self->{config}->{dest} || "<name>-<version>");
    my $src = catdir($self->global->{build_dir}, $folder);
    remove_tree($src)
        if $self->{config}->{always_extract} && -d $src;
    # We always have to extract if patches need to be applied
    if (-d $src && (!$self->{config}->{patches} || !@{$self->{config}->{patches}})) {
        $self->boss->message(2, "* $folder still extracted: skipping archive download and extraction");
    } else {
        # Download library archive
        my $url = $self->_resolve($self->{config}->{url});
        $self->boss->message(2, "* archive url: $url");
        my $archive = $self->boss->mirror_url($url, $self->global->{download_dir});
        $self->_extract($archive, $self->global->{build_dir});
    }

    my $libpath = $src;
    unless ($self->{config}->{build_in_srcdir}) {
        $libpath = catdir($self->global->{build_dir}, $self->{config}->{name});
        remove_tree($libpath) if $libpath;
        make_path($libpath) or die "ERROR: cannot create '".$libpath."'\n";
    }

    # Updates for _resolve method
    $self->{config}->{src} = "../$folder";
    $self->{config}->{absolute_src} = "/c/Strawberry-perl-for-GLPI-Agent_build/build/$folder";
    $self->{config}->{dllsuffix} = $self->global->{_dllsuffix} unless $self->{config}->{dllsuffix};
    $self->{config}->{install_prefix} = catdir($self->global->{image_dir}, "c");
    $self->{config}->{prefix} = $self->{config}->{install_prefix};
    $self->{config}->{prefix} =~ s{\\}{/}g;

    if ($self->{config}->{patches} && @{$self->{config}->{patches}}) {
        my $wd = $self->_push_dir($src);
        foreach my $url (@{$self->{config}->{patches}}) {
            $url = $self->_resolve($url);
            my $patch = $self->boss->mirror_url($url, $self->global->{download_dir});
            my ($patch_name) = $url =~ m|.*/([^/]+)$|;
            $self->boss->message(2, "* applying patch: $patch_name");
            my $option = $self->{config}->{patches_option} || '-p1';
            $self->execute_special(
                [catfile($self->global->{build_dir}, 'msys64', 'msys2_shell.cmd'), '-no-start', '-defterm', '-c', "patch $option < ../../download/$patch_name"],
            ) and die "Unable to apply $self->{config}->{name} patch\n";
        }
    }

    my $wd = $self->_push_dir($libpath);
    $self->{config}->{pre_configure} and $self->_commands('pre_configure', $self->{config}->{pre_configure})
        and die "pre configure failure\n";
    $self->{config}->{skip_configure} or $self->_configure()
        and die "sources configuration failure\n";
    $self->_patch_libtool($libpath) if $self->{config}->{patch_libtool};
    $self->{config}->{post_configure} and $self->_commands('post_configure', $self->{config}->{post_configure})
        and die "post configure failure\n";

    $self->boss->message(2, "* make/build stage");

    $self->_make(undef, $self->{config}->{make_opts})
        and die "make failure\n";
    $self->{config}->{post_make} and $self->_commands('post_make', $self->{config}->{post_make})
        and die "post make failure\n";
    $self->global->{_no_test} or $self->{config}->{skip_test} or $self->_make('test')
        and die "test failure\n";

    $self->boss->message(2, "* make/install stage");

    my $install = $self->{config}->{install_opts} && @{$self->{config}->{install_opts}} ? '' : 'install';
    $self->_make( $install, $self->{config}->{install_opts})
        and die "install failure\n";
    $self->{config}->{install_file} and $self->_install_file();
    $self->{config}->{post_install} and $self->_commands('post_install', $self->{config}->{post_install})
        and die "post install failure\n";
}

sub _configure {
    my ($self) = @_;

    $self->boss->message(2, "* source configure stage");

    my @command = ('bash', $self->_resolve('<src>/configure'));
    $self->execute_special([@command, '--help'], catfile($self->global->{debug_dir}, $self->_resolve("<name>-<version>-configure-help.txt")))
        if $self->{config}->{configure_help};

    push @command, map { $self->_resolve($_) } @{$self->{config}->{configure_opts}}
        if $self->{config}->{configure_opts};

    my $log = catfile($self->global->{debug_dir}, $self->_resolve("<name>-<version>-configure.log.txt"));

    $self->boss->message(2, "* running: @command");
    $self->execute_special(\@command, $log);
}

sub _make {
    my ($self, $what, $opts) = @_;

    my $log = catfile($self->global->{debug_dir}, $self->_resolve("<name>-<version>-make").(defined($what) ? "-install" : "").".log.txt");

    my @command = ('make');
    if ($what) {
        push @command, $what;
    } elsif (!defined($what) && $self->{config}->{make_use_cpus} && $self->global->{_cpus}) {
        push @command, "-j".$self->global->{_cpus};
    }
    push @command, map { $self->_resolve($_) } @{$opts} if $opts;

    $self->boss->message(2, "* running: @command");

    $self->execute_special(\@command, $log);
}

sub _commands {
    my ($self, $stage, $commands) = @_;

    $self->boss->message(2, "* $stage commands run stage");

    foreach my $cmdref (@{$commands}) {
        my @command;
        if (ref($cmdref)) {
            @command = map { $self->_resolve($_) } @{$cmdref};
        } else {
            @command = split(/\s+/, $self->_resolve($cmdref));
        }

        $self->boss->message(2, "* running: @command");

        $self->execute_special(\@command)
            and return 1;
    }
}

sub _install_file {
    my ($self) = @_;

    $self->boss->message(2, "* file install stage");

    my $fh;

    while (my ($key, $lines) = each %{$self->{config}->{install_file}}) {
        my $file = $self->_resolve($key);

        $self->boss->message(2, "* installing: $file");

        open $fh, ">", $file
            or die "install file failure: $!\n";
        print $fh map { $self->_resolve($_)."\n" } @{$lines};
        close($fh)
            or die "install file failure: $!\n";
    }

    return 0;
}

sub _patch_libtool {
    my ($self, $source) = @_;

    my $dllsuffix = $self->{config}->{dllsuffix} || $self->global->{_dllsuffix};
    File::Find::find(
        {
            wanted => sub {
                return unless /libtool/ && -f $File::Find::name;
                my $fh;
                open($fh, '<', $File::Find::name)
                    or die "Can't open $File::Find::name for reading: $!\n";
                my @lines = <$fh>;
                close($fh);

                # Adapted from StrawberryPerl related script
                @lines = map {
                    s|^\s*shrext_cmds=.\.dll.$|shrext_cmds='$dllsuffix.dll'|;
                    s|^\s*\(library_names_spec=".\`echo .\$\{libname\}\)|$1$dllsuffix|;
                    s|EGREP[-e ]*'file format pe-i386(\.\*architecture: i386)?' >|EGREP 'file format pe-(i386\|x86-64)(.*architecture: i386)?' >|;
                    s|EGREP[-e ]*'file format (pe-i386(\.\*architecture: i386)?\|pe-arm-wince\|pe-x86-64)' >|EGREP 'file format (pei\*-i386(\.\*architecture:\ i386)?\|pe-arm-wince\|pe-x86-64)' >|;
                    s|deplibs_check_method=['"]file_magic file format pei\*-i386(\.\*architecture: i386)?['"]|deplibs_check_method="file_magic file format pe-(i386\|x86-64)(.*architecture: i386)?" |;
                    s|deplibs_check_method=['"]file_magic file format pe-i386(\.\*architecture: i386)?['"]|deplibs_check_method="file_magic file format pe-(i386\|x86-64)(.*architecture: i386)?" |;
                    $_;
                } @lines;

                open($fh, '>', $File::Find::name)
                    or die "Can't open $File::Find::name for writing: $!\n";
                print $fh @lines;
                close($fh);

                $self->boss->message(2, "* patched $File::Find::name");
            },
            no_chdir => 1
        },
        $source
    );
}

package
    Perl::Dist::Strawberry::Step::PackageZIP;

use base 'Perl::Dist::Strawberry::Step';

use File::Spec::Functions qw(catdir catfile);

sub run {
    my ($self) = @_;

    my $zip_src  = catdir($self->global->{image_dir}, "c");
    my $zip_file = catfile($self->global->{download_dir}, $self->global->{app_simplename}.".zip");

    $self->boss->message(2, "gonna create '$zip_file'"); 

    # backup already existing zip_file;  
    $self->backup_file($zip_file);

    # do zip, 9 as max. compression  
    $self->boss->zip_dir($zip_src, $zip_file, 9);
}
