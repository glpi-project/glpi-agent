#!perl

use strict;
use warnings;

use Win32::TieRegistry qw( KEY_READ );
use File::Spec;
use Cwd qw(abs_path);
use File::Spec::Functions qw(catfile);
use Data::UUID;

use constant {
    PACKAGE_REVISION    => "1", #BEWARE: always start with 1
    PROVIDED_BY         => "Teclib Edition",
};

use lib abs_path(File::Spec->rel2abs('../packaging', __FILE__));

use CustomCodeSigning;
use PerlBuildJob;

use lib 'lib';
use GLPI::Agent::Version;

# HACK: make "use Perl::Dist::GLPI::Agent::Step::XXX" works as included plugin
map { $INC{"Perl/Dist/GLPI/Agent/Step/$_.pm"} = __FILE__ } qw(Update OutputMSI Test ToolChain InstallPerlCore InstallModules Github BuildModule);

# Perl::Dist::Strawberry doesn't detect WiX 3.11 which is installed on windows github images
# Algorithm imported from Perl::Dist::Strawberry::Step::OutputMSM_MSI::_detect_wix_dir
my $wixbin_dir;
if (grep { /^--no-build$/i } @ARGV) {
    mkdir "build/windows/wixbin" unless -d "build/windows/wixbin";
    system("touch build/windows/wixbin/candle.exe");
    system("touch build/windows/wixbin/light.exe");
} else {
    for my $v (qw/3.14 3.11 3.6 3.5 3.0/) {
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
}

my $provider = $GLPI::Agent::Version::PROVIDER;
my $version = $GLPI::Agent::Version::VERSION;
my ($versiontag) = $version =~ /^[0-9.]+-(.*)$/;
my ($major,$minor,$revision) = $version =~ /^(\d+)\.(\d+)\.?(\d+)?/;
$revision = 0 unless defined($revision);

if ($ENV{GITHUB_SHA}) {
    my ($github_ref) = $ENV{GITHUB_SHA} =~ /^([0-9a-f]{8})/;
    $version =~ s/-.*$//;
    $version .= "-git".($github_ref // $ENV{GITHUB_SHA});
    $versiontag = "git".($github_ref // $ENV{GITHUB_SHA});
}

if ($ENV{GITHUB_REF} && $ENV{GITHUB_REF} =~ m|refs/tags/(.+)$|) {
    my $github_tag = $1;
    $versiontag = '';
    if ($revision) {
        $version = $github_tag;
        if ($github_tag =~ /^$major\.$minor\.$revision-(.*)$/) {
            $versiontag = $1;
        } elsif ($github_tag ne "$major.$minor.$revision") {
            $version = "$major.$minor.$revision-$github_tag";
            $versiontag = $github_tag;
        }
    } else {
        $version = $github_tag;
        if ($github_tag =~ /^$major\.$minor-(.*)$/) {
            $versiontag = $1;
        } elsif ($github_tag ne "$major.$minor") {
            $version = "$major.$minor-$github_tag";
            $versiontag = $github_tag;
        }
    }
}

sub build_app {
    my ($arch, $notest, $sign, $skip_build) = @_;

    my $package_rev = $ENV{PACKAGE_REVISION} || PACKAGE_REVISION;

    my $app = Perl::Dist::GLPI::Agent->new(
        _perl_version   => PERL_VERSION,
        _revision       => $package_rev,
        _provider       => $provider,
        _provided_by    => PROVIDED_BY,
        _no_test        => $notest,
        agent_version   => $version,
        agent_fullver   => $major.'.'.$minor.'.'.$revision.'.'.$package_rev,
        agent_vernum    => $major.'.'.$minor.($revision ? '.'.$revision : ''),
        agent_vertag    => $versiontag // '',
        agent_fullname  => $provider.' Agent',
        agent_rootdir   => $provider.'-Agent',
        agent_localguid => Data::UUID->new()->create_str(),
        agent_regpath   => "Software\\$provider-Agent",
        service_name    => lc($provider).'-agent',
        msi_sharedir    => 'contrib/windows/packaging',
        arch            => $arch,
        _dllsuffix      => $arch eq "x86" ? '_' : '__',
        _restore_step   => PERL_BUILD_STEPS,
        codesigning     => $sign,
        cpan_url        => 'https://www.cpan.org/',
        skip_build      => $skip_build,
    );

    $app->parse_options(
        -job            => "glpi-agent packaging",
        -image_dir      => $skip_build ? "build/windows/image"   : "C:\\Strawberry-perl-for-$provider-Agent",
        -working_dir    => $skip_build ? "build/windows/working" : "C:\\Strawberry-perl-for-$provider-Agent_build",
        -wixbin_dir     => $skip_build ? "build/windows/wixbin"  : $wixbin_dir,
        -notest_modules,
        -nointeractive,
        -restorepoints,
    );

    return $app;
}

my %do = ();
my $notest = 0;
my $sign   = 0;
my $skip_build = 0;
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
    } elsif ($arg =~ /^--code-signing=(.*)$/) {
        $sign = 1 if $1 =~ /^yes|1$/i;
    } elsif ($arg eq "--no-build") {
        $skip_build = 1;
    } else {
        warn "Unsupported option: $arg\n";
    }
}

# Still select a defaut arch if none has been selected
$do{x64} = 64 unless keys(%do);

die "32 bits packaging build no more supported\n"
    if $do{x86};

foreach my $arch (sort keys(%do)) {
    print "Building $arch packages...\n";
    my $app = build_app($arch, $notest, $sign, $skip_build);
    $app->do_job();
    # global_dump_FINAL.txt must exist in debug_dir if all steps have been passed
    exit(1) unless -e catfile($app->global->{debug_dir}, 'global_dump_FINAL.txt');
}

print "All packages building processing passed\n";

exit(0);

package
    Perl::Dist::GLPI::Agent::Step::ToolChain;

use parent 'Perl::Dist::Strawberry::Step::BinaryToolsAndLibs';

use File::Spec::Functions qw(catfile catdir);

sub run {
    my ($self) = @_;

    foreach my $p (@{$self->{config}->{packages}}) {
        $self->_install($p);
        $self->boss->message(5, "pkg='$p->{name}'");
    }
}

sub _install {
    my ($self, $pkg) = @_;
    my $name = $pkg->{name};
    $self->boss->message(1, "installing package '$name'\n");

    my $file       = $pkg->{file};
    my $install_to = $pkg->{install_to} || '';

    # Unpack the archive
    my $tgz = catfile($self->global->{download_dir}, $file);
    my $tgt = catdir($self->global->{image_dir}, $install_to);
    $self->_extract($tgz, $tgt);
}

package
    Perl::Dist::GLPI::Agent::Step::InstallPerlCore;

use parent 'Perl::Dist::Strawberry::Step::InstallPerlCore';

use Text::Patch;
use File::Copy qw(copy);
use File::Slurp;
use Text::Diff;
use File::Spec;

sub _update_config_gc {
    my ($self, $fname, $update_hash) = @_;

    die "update hash arg is not a hash ref"
      if not ref($update_hash) =~ /HASH/;

    open my $fh, $fname or die "Unable to open $fname, $!";

    my @lines = (<$fh>);
    close $fh;

    my %data;
    my @output;
    my @perl_lines; #  lines starting with PERL

    while (defined(my $line = shift @lines)) {
        $line =~ s/[\r\n]+$//;
        if ($line =~ /^#/) {
            #  headers stay as they are
            push @output, $line;
        }
        elsif ($line =~ /^PERL/) {
            push @perl_lines, $line;
        }
        elsif ($line =~ m/^([\w]+)=(.*)$/) {
            $data{$1} = length($2) ? $2 : "''";
        }
    }

    my $default_config_hash = $self->_get_default_config_hash;
    @data{keys %$default_config_hash} = values %$default_config_hash;

    # fix up quoting of values
    foreach my $val (values %$update_hash) {
        next if $val =~ /^'/;  # assumes symmetry, i.e. opening and closing
        $val = "'$val'";
    }

    @data{keys %$update_hash} = values %$update_hash;

    my (@ucfirst_lines, @lcfirst_lines);
    foreach my $key (grep {/^[A-Z]/} keys %data) {
        push @ucfirst_lines, "$key=$data{$key}";
    }
    foreach my $key (grep {/^[_a-z]/} keys %data) {
        push @lcfirst_lines, "$key=$data{$key}";
    }
    push @output, (sort @ucfirst_lines), (sort @lcfirst_lines), @perl_lines;

    # long name but otherwise we interfere with patch backups
    rename $fname, "$fname.orig.before_hash_update" or die $!;
    open my $ofh, ">:raw", $fname or die "Unable to open $fname to write to, $!";
    map { print $ofh $_, "\n" } @output;
    $ofh->close;
}

sub _patch_dir {
    my ($self, $new, $dir) = @_;

    $self->boss->message(5, "_patch_file: applying DIFF on dir '$dir'\n");
    my $wd = $self->_push_dir($dir);
    system("patch --binary -i \"$new\" -p1") == 0
        or die "patch '$new' FAILED";
}

sub _patch_file {
    my ($self, $new, $dst, $dir, $tt_vars, $no_backup) = @_;

    # We only need to replace patch case
    return $self->SUPER::_patch_file($new, $dst, $dir, $tt_vars, $no_backup)
        unless $new =~ /\.(diff|patch)$/;

    return $self->_patch_dir(File::Spec->rel2abs($new), $dir)
        if $dst =~ /\*$/;

    $self->boss->message(5, "_patch_file: applying patch on '$dst'\n");
    copy($dst, "$dst.backup") if !$no_backup && -f $dst && !-f "$dst.backup";
    my $diff = read_file($new);
    my $indata = read_file($dst);
    my $outdata = patch($indata, $diff, STYLE=>"Unified");

    my $r = $self->_unset_ro($dst);
    write_file($dst, $outdata);
    $self->_restore_ro($dst, $r);

    write_file("$dst.diff", diff("$dst.backup", $dst)) if -f "$dst.backup";
}

package
    Perl::Dist::GLPI::Agent::Step::BuildModule;

use parent 'Perl::Dist::Strawberry::Step';

use File::Spec::Functions qw(catfile catdir);
use File::Slurp           qw(read_file);
use File::Path            qw(make_path);

use Perl::Dist::Strawberry::Step::FilesAndDirs;

sub check {
    my $self = shift;
    $self->SUPER::check(@_);
    my $m = $self->{config}->{module};
    die "ERROR: param 'module' not defined" unless defined $m;
    die "ERROR: param 'module' has to be a module name string" if ref($m);
}

sub _buildlib {
    my ($self) = @_;

    my $folder = catdir($self->global->{build_dir}, $self->_resolve($self->{config}->{buildlib_folder}//''));
    make_path($folder) unless -d $folder;
    my $wd = $self->_push_dir($folder);

    return $self->_commands('buildlib', $self->{config}->{buildlib});
}

sub run {
    my ($self) = @_;

    if ($self->{config}->{skip_if_file}) {
        my $file = $self->_resolve($self->{config}->{skip_if_file});
        if (-e $file) {
            $self->boss->message(2, "* skipping as still built");
            return;
        }
    }

    my $name = $self->{config}->{module}
        or die "ERROR: Missing module name";
    $self->boss->message(1, "installing module '$name'\n");

    my $url = $self->{config}->{url}
        or die "ERROR: Missing module url";
    my $install_to = $self->{config}->{install_to} // ''; # relative to build_dir

    # Download the file
    $url = $self->_resolve($url);
    my $tgz = $self->boss->mirror_url($url, $self->global->{download_dir});

    # Unpack the archive
    my $tgt = catdir($self->global->{build_dir}, $install_to);

    $self->_extract($tgz, $tgt);

    $self->{config}->{buildlib} and $self->_buildlib()
        or die "ERROR: buildlib failure\n";

    my $folder = catdir($self->global->{build_dir}, $self->_resolve($self->{config}->{folder}//''));
    my $wd = $self->_push_dir($folder);

    my $swig_lib = catdir($self->global->{image_dir}, 'c', 'lib', 'swig');
    $self->{config}->{swig} and $self->_commands('swig', $self->{config}->{swig}, undef, { SWIG_LIB => $swig_lib })
        or die "ERROR: swig failure\n";

    # Find perl opts to resolve it in build command
    if ($self->{config}->{build}) {
        foreach my $o (qw(opts ldopts libdll)) {
            if ($self->{config}->{$o}) {
                my $result = $self->_commands('_'.$o, $self->{config}->{$o}, "get")
                    or die "ERROR: _$o failure\n";
                $self->{config}->{"_$o"} = $result;
            }
        }
    }

    $self->{config}->{build} and $self->_commands('build', $self->{config}->{build})
        or die "ERROR: build failure\n";

    if (ref($self->{config}->{install}) eq 'ARRAY') {
        my $install = Perl::Dist::Strawberry::Step::FilesAndDirs->new();
        $install->{boss} = $self->{boss};
        $install->{config}->{commands} = [
            map {
                my $cmd = $_;
                {
                    do      => $cmd->{do},
                    args    => [ map { $self->_resolve($_) } @{$cmd->{args}} ],
                }
            } @{$self->{config}->{install}}
        ];
        $install->run()
            or die "ERROR: Failed to install $name\n";
    }

    $self->boss->message(5, "pkg='$name'");
}

sub _resolve {
    my ($self, $string) = @_;
    map { $self->{config}->{$_} && $string =~ s/<$_>/$self->{config}->{$_}/g } qw(
        module version folder src absolute_src dllsuffix prefix install_prefix _libdll _opts _ldopts
    );
    return $string;
}

sub _commands {
    my ($self, $stage, $commands, $output, $env) = @_;

    $self->boss->message(2, "* $stage commands run stage");

    foreach my $cmdref (@{$commands}) {
        my @command;
        if (ref($cmdref)) {
            @command = map { $self->_resolve($_) } @{$cmdref};
        } else {
            @command = split(/\s+/, $self->_resolve($cmdref));
        }

        $self->boss->message(2, "* running: @command");

        my $file = catfile($self->global->{debug_dir}, $stage."_output.txt");
        if ($output) {
            $self->execute_special(\@command, $file, undef, $env)
                and return 0;
            return read_file($file);
        } else {
            $self->execute_special(\@command, $file, undef, $env)
                and return 0;
        }
    }

    return 1;
}

package
    Perl::Dist::GLPI::Agent::Step::Github;

use parent 'Perl::Dist::Strawberry::Step';

sub run {
    my ($self) = @_;

    foreach my $s (@{$self->{config}->{downloads}}) {
        $self->_download($s);
        $self->boss->message(5, "downloaded='$s->{name}'");
    }
}

sub _download {
    my ($self, $src) = @_;
    my $name    = $src->{name};
    my $project = $src->{project};
    my $release = $src->{release};
    my $folder  = $self->boss->resolve_name($src->{folder});
    my $url     = "https://github.com/$project/releases/download/$release/".$src->{file};

    $self->boss->message(1, "installing $name $release from github $project\n");

    $self->boss->mirror_url($url, $folder);
}

package
    Perl::Dist::GLPI::Agent::Step::Test;

use parent 'Perl::Dist::Strawberry::Step';

use File::Spec::Functions qw(catfile catdir);
use File::Glob qw(:glob);

sub run {
    my $self = shift;

    # Update PATH to include perl/bin for DLLs loading
    my $binpath = catfile($self->global->{image_dir}, 'perl/bin');
    $ENV{PATH} .= ":$binpath";

    # Without defined modules, run the tests
    my $perlbin = catfile($binpath, 'perl.exe');

    my $makefile_pl_cmd = [ $perlbin, "Makefile.PL"];
    $self->boss->message(2, "Test: gonna run perl Makefile.PL");
    my $rv = $self->execute_standard($makefile_pl_cmd);
    die "ERROR: TEST, perl Makefile.PL\n" unless (defined $rv && $rv == 0);
}

sub test {
    my $self = shift;

    # Update PATH to include perl/bin for DLLs loading
    my $binpath = catfile($self->global->{image_dir}, 'perl/bin');
    $ENV{PATH} .= ":$binpath";

    # Without defined modules, run the tests
    my $makebin = catfile($binpath, 'gmake.exe');

    my @test_files = qw(t/01compile.t);
    @test_files = map { bsd_glob($_) } @{$self->{config}->{test_files}}
        if ref($self->{config}->{test_files}) && @{$self->{config}->{test_files}};
    if (@test_files && ref($self->{config}->{skip_tests}) && @{$self->{config}->{skip_tests}}) {
        my %skip_tests = map { $_ => 1 } @{$self->{config}->{skip_tests}};
        @test_files = grep { not $skip_tests{$_} } @test_files;
    }

    # Only test files compilation
    my $make_test_cmd = [ $makebin, "test" ];
    push @{$make_test_cmd}, "TEST_FILES=@test_files" if @test_files;
    $self->boss->message(2, "Test: gonna run gmake test");
    my $rv = $self->execute_standard($make_test_cmd);
    die "ERROR: TEST, make test\n" unless (defined $rv && $rv == 0);
}

package
    Perl::Dist::GLPI::Agent::Step::InstallModules;

use parent 'Perl::Dist::Strawberry::Step::InstallModules';

sub _install_module {
    my ($self, %args) = @_;
    my ($distlist, $rv) = $self->SUPER::_install_module(%args);
    # Fail ASAP on module installation failure
    die "ERROR: INSTALL MODULE failed\n" unless (defined $rv && $rv == 0);
    return ($distlist, $rv);
}

package
    Perl::Dist::GLPI::Agent::Step::OutputMSI;

use parent 'Perl::Dist::Strawberry::Step::OutputMSI';

use File::Slurp           qw(read_file write_file);
use File::Spec::Functions qw(canonpath catdir catfile);
use File::Basename;
use Data::Dump            qw(pp);
use Template;
use XML::LibXML;

use constant _dir_id_match => { qw(
    perl                                                     d_perl
    perl\bin                                                 d_perl_bin
    var                                                      d_var
    logs                                                     d_logs
    etc                                                      d_etc
)};

# /perl/bin/glpi-agent.exe is here for testing on linux when --no-build is used
use constant _file_feature_match => { qw(
    perl\bin\glpi-agent.exe                                 feat_AGENT
    /perl/bin/glpi-agent.exe                                feat_AGENT

    glpi-netdiscovery.bat                                   feat_NETINV
    glpi-netinventory.bat                                   feat_NETINV
    perl\bin\glpi-netdiscovery                              feat_NETINV
    perl\bin\glpi-netinventory                              feat_NETINV

    perl\bin\7z.exe                                         feat_DEPLOY
    perl\bin\7z.dll                                         feat_DEPLOY

    glpi-esx.bat                                            feat_ESX
    perl\bin\glpi-esx                                       feat_ESX

    glpi-wakeonlan.bat                                      feat_WOL
    perl\bin\glpi-wakeonlan                                 feat_WOL
)};

use constant _feature_rematch => {
    feat_NETINV     => qr/^perl\\agent\\glpi\\agent\\(snmp|task\\net|tools\\snmp|http\\server\\toolbox)/i,
    feat_DEPLOY     => qr/^perl\\agent\\glpi\\agent\\(task\\deploy|tools\\archive)/i,
    feat_COLLECT    => qr/^perl\\agent\\glpi\\agent\\task\\collect/i,
    feat_ESX        => qr/^perl\\agent\\glpi\\agent\\(soap\\vmware|task\\esx)/i,
    feat_WOL        => qr/^perl\\agent\\glpi\\agent\\task\\wakeonlan/i,
};

sub run {
    my $self = shift;

    my $bat = "contrib/windows/packaging/template.bat.tt";
    my $t = Template->new(ABSOLUTE=>1);

    # Re-install dedicated bat files not using config file
    foreach my $f (qw(agent)) {
        my $dest = catfile($self->global->{image_dir}, 'glpi-'.$f.'.bat');
        my $tag = { tag => $f, msi => 1 };
        $t->process($bat, $tag, $dest) || die $t->error();
    }

    my $bdir = catdir($self->global->{build_dir}, 'msi');

    my $msi_guid = $self->{data_uuid}->create_str(); # get random GUID

    # create WXS parts to be inserted into MSI_main.wxs.tt
    my $xml_env = $self->_generate_wxml_for_environment();
    my ($xml_start_menu, $xml_start_menu_icons) = $self->_generate_wxml_for_start_menu();
    my ($xml_msi, $id_list_msi) = $self->_generate_wxml_for_directory($self->global->{image_dir});
    #debug:
    write_file("$bdir/debug.xml_msi.xml", $xml_msi);
    write_file("$bdir/debug.xml_start_menu.xml", $xml_start_menu);
    write_file("$bdir/debug.xml_start_menu_icons.xml", $xml_start_menu_icons);

    # prepare MSI filenames
    my $output_basename = $self->global->{output_basename} // 'perl-output';
    my $msi_file = catfile($self->global->{output_dir}, "$output_basename.msi");
    my $wixpdb_file = catfile($self->global->{output_dir}, "$output_basename.wixpdb");

    # compute msi_version which has to be 3-numbers (otherwise major upgrade feature does not work)
    my ($v1, $v2, $v3, $v4) = split /\./, $self->global->{app_version};
    $v3 = $v3*1000 + $v4 if defined $v4; #turn 5.14.2.1 to 5.12.2001

    # resolve values (only scalars) from config
    for (keys %{$self->{config}}) {
        if (defined $self->{config}->{$_} && !ref $self->{config}->{$_}) {
            $self->{config}->{$_} = $self->boss->resolve_name($self->{config}->{$_});
        }
    }
    my %vars = (
        # global info taken from 'boss'
        %{$self->global},
        # OutputMSI config info
        %{$self->{config}},
        # the following items are computed
        msi_product_guid => $msi_guid,
        msi_version      => sprintf("%d.%d.%d", $v1, $v2, $v3), # e.g. 5.12.2001
        msi_upgr_version => sprintf("%d.%d.%d", $v1, $v2, 0),   # e.g. 5.12.0
        # WXS data
        xml_msi_dirtree     => $xml_msi,
        xml_env             => $xml_env,
        xml_startmenu       => $xml_start_menu,
        xml_startmenu_icons => $xml_start_menu_icons,
    );

    # Use our MSI templates
    my $f2 = catfile($self->global->{msi_sharedir}, 'MSI_main-v2.wxs.tt');
    my $f3 = catfile($self->global->{msi_sharedir}, 'Variables-v2.wxi.tt');
    my $f4 = catfile($self->global->{msi_sharedir}, 'MSI_strings.wxl.tt');
    write_file(catfile($self->global->{debug_dir}, 'TTvars_OutputMSI_'.time.'.txt'), pp(\%vars)); #debug dump
    $t->process($f2, \%vars, catfile($bdir, 'MSI_main-v2.wxs')) || die $t->error();
    $t->process($f3, \%vars, catfile($bdir, 'Variables-v2.wxi')) || die $t->error();
    $t->process($f4, \%vars, catfile($bdir, 'MSI_strings.wxl')) || die $t->error();

    # Validate generated wxs
    $self->_validate_wxs(catfile($bdir, 'MSI_main-v2.wxs'));

    return if $self->global->{skip_build};

    my $rv;
    my $candle_exe = $self->{candle_exe};
    my $light_exe = $self->{light_exe};

    my $candle2_cmd = [$candle_exe, "$bdir\\MSI_main-v2.wxs", '-out', "$bdir\\MSI_main.wixobj", '-v', '-ext', 'WixUtilExtension'];
    # Set arch option if necessary
    push @{$candle2_cmd}, '-arch', 'x64' if $self->global->{arch} eq 'x64';
    my $light2_cmd  = [$light_exe,  "$bdir\\MSI_main.wixobj", '-out', $msi_file, '-pdbout', "$bdir\\MSI_main.wixpdb", '-loc', "$bdir\\MSI_strings.wxl",
        qw/-ext WixUIExtension -ext WixUtilExtension -sice:ICE61/];

    # backup already existing <output_dir>/*.msi
    $self->backup_file($msi_file);

    $self->boss->message(2, "MSI: gonna run $candle2_cmd->[0]");
    $rv = $self->execute_standard($candle2_cmd, catfile($self->global->{debug_dir}, "MSI_candle.log.txt"));
    die "ERROR: MSI candle" unless(defined $rv && $rv == 0);

    $self->boss->message(2, "MSI: gonna run $light2_cmd->[0]");
    $rv = $self->execute_standard($light2_cmd, catfile($self->global->{debug_dir}, "MSI_light.log.txt"));
    die "ERROR: MSI light" unless(defined $rv && $rv == 0);

    #store results
    $self->{data}->{output}->{msi} = $msi_file;
    $self->{data}->{output}->{msi_sha1} = $self->sha1_file($msi_file); # will change after we sign MSI
    $self->{data}->{output}->{msi_guid} = $msi_guid;

}

sub _validate_wxs {
    my ($self, $xml) = @_;

    my $failure = 0;
    my %found;

    warn "    INFO: WXS file valdation: $xml\n";

    my $parser = XML::LibXML->new(
        load_ext_dtd    => 0,
        no_network      => 1,
        no_blanks       => 1,
        pedantic_parser => 1,
    )
        or die "ERROR: WXS xml parser not available\n";

    my $dom = $parser->load_xml(location => $xml)
        or die "ERROR: WXS failed to parse file: $xml\n";

    die "ERROR: WXS invalid xml: $xml".(ref($dom) ? " - ".ref($dom) : "")."\n"
        unless ref($dom) eq "XML::LibXML::Document";

    my $root = $dom->documentElement();

    # Software\GLPI-Agent\Installer\Version is only defined for scripts and so
    # can't be set on command line
    my %config = (
        'Software\GLPI-Agent\Installer' => [ "Version" ],
    );

    foreach my $node ($root->getElementsByTagName("RegistrySearch")) {
        my $key = $node->getAttribute("Key");
        my $name = $node->getAttribute("Name");
        #~ warn "$key: $name\n";
        push @{$config{$key}}, $name;
    }
    die "ERROR: WXS no RegistrySearch node found: $xml\n"
        unless keys(%config);

    my @RegistryKey = $root->getElementsByTagName("RegistryKey")
        or die "ERROR: WXS no RegistryKey node found: $xml\n";

    foreach my $regkey (@RegistryKey) {
        my $found = 0;
        my $key = $regkey->getAttribute("Key");
        foreach my $regvalue ($regkey->childNodes()) {
            my $tag = $regvalue->nodeName;
            unless ($tag && $tag eq "RegistryValue") {
                warn "    WARNING: Unexpected $tag node under $key RegistryKey: ".$regvalue->toString()."\n";
                $failure++;
                next;
            }
            my $name = $regvalue->getAttribute("Name");
            unless ($name && $name =~ /^[a-z][0-9a-z-]*$/i) {
                warn "    WARNING: Unexpected Name attribut under $key RegistryKey: ".$regvalue->toString()."\n";
                $failure++;
                next;
            }
            unless (grep { $_ eq $name } @{$config{$key}}) {
                warn "    WARNING: Unexpected option support under $key RegistryKey: ".$regvalue->toString()."\n";
                $failure++;
                next;
            }
            $found++;
            $found{$name} = 1;
        }
        unless ($found && $config{$key} && $found == @{$config{$key}}) {
            if ($found > @{$config{$key}}) {
                my $options = join(", ", sort keys(%found));
                warn "    WARNING: Too much RegistryKey option definitions found: $options\n";
                $failure++;
            } else {
                my $options = join(", ", grep { !$found{$_} } @{$config{$key}});
                warn "    WARNING: Missing RegistryKey option definitions: $options\n";
                $failure++;
            }
        }
        warn "    INFO: WXS defines $found options under $key\n";
    }

    # Compare with configuration parameters from lib/GLPI/Agent/Config.pm
    # But first set configuration option not supported in msi installation
    my %not_in_windows = map { $_ => 1 } qw(
        assetname-support
        color
        force
        logfacility
        remote-scheduling
    );

    my $cfg_module;
    open $cfg_module, "<", "lib/GLPI/Agent/Config.pm"
        or die "    ERROR: WXS Can't read Config module: $!\n";
    my @default;
    my $default;
    while (my $line = <$cfg_module>) {
        next if !$default && $line =~ /^my \$default = \{$/ && ++$default;
        next unless $default; # Wait to find $default definition
        last if $line =~ /^};$/; # Leave when $default definition has been read
        unless ($line =~ /^\s+'([0-9a-z-]+)'\s*=>/) {
            warn "    WARNING: Unexpected \$default entry: $1\n";
            $failure++;
            next;
        }
        my $option = $1;
        next if $found{$option} || $not_in_windows{$option};
        warn "    WARNING: Missing option support: $option\n";
        $failure++;
    }
    close($cfg_module);

    die "ERROR: WXS validation failure\n" if $failure == 1;
    die "ERROR: WXS validation failures: $failure\n" if $failure;

    warn "    INFO: WXS file looks good\n";
}

sub _tree2xml {
    my ($self, $root, $mark, $not_root) = @_;

    my ($component_id, $component_guid, $dir_id);
    my $result = "";
    my $ident = "      " . "  " x $root->{depth};

    # dir-start
    if ($not_root && $root->{mark} eq $mark) {
        $dir_id = $self->_gen_dir_id($root->{short_name});
        my $dir_basename = basename($root->{full_name});
        my $dir_shortname = $self->_get_short_basename($root->{full_name});
        $result .= $ident . qq[<Directory Id="$dir_id" Name="$dir_basename" ShortName="$dir_shortname">\n];
    } elsif (!defined($not_root)) {
        $dir_id = "d_install";
    }

    my @f = grep { $_->{mark} eq $mark } @{$root->{files}};
    my @d = grep { $_->{mark} eq $mark } @{$root->{dirs}};
    my $feat = "feat_$mark";

    if (defined $dir_id) {
        ($component_id, $component_guid) = $self->_gen_component_id($root->{short_name}."create");
        # put KeyPath to the component as Directory does not have KeyPath attribute
        # if a Component has KeyPath="yes", then the directory this component is installed to becomes a key path
        # see: http://stackoverflow.com/questions/10358989/wix-using-keypath-on-components-directories-files-registry-etc-etc

        # Fix directory feature
        my $image_dir = canonpath($self->global->{image_dir});
        (my $short_name = canonpath($root->{short_name})) =~ s/^\Q$image_dir\E[\\]*//;
        my ($this_feat) = grep { $short_name =~ _feature_rematch->{$_} } keys(%{&_feature_rematch});
        $feat = $this_feat if defined($this_feat);

        $result .= $ident ."  ". qq[<Component Id="$component_id" Guid="{$component_guid}" KeyPath="yes" Feature="$feat">\n];
        if ($dir_id eq 'd_install') {
            $result .= $ident ."    ". qq[  <CreateFolder>\n];
            $result .= $ident ."    ". qq[    <util:PermissionEx GenericAll="yes" User="CREATOR OWNER" />\n];
            $result .= $ident ."    ". qq[    <util:PermissionEx GenericAll="yes" User="LocalSystem" />\n];
            $result .= $ident ."    ". qq[    <util:PermissionEx GenericAll="yes" User="Administrators" />\n];
            $result .= $ident ."    ". qq[    <util:PermissionEx GenericWrite="no" GenericExecute="yes" GenericRead="yes" User="AuthenticatedUser" />\n];
            $result .= $ident ."    ". qq[  </CreateFolder>\n];
        } else {
            $result .= $ident ."  ". qq[    <CreateFolder />\n];
        }
        if ($dir_id eq 'd_var') {
            $result .= $ident ."  ". qq[    <util:RemoveFolderEx On="uninstall" Property="UNINSTALL_VAR" />\n];
        } elsif ($dir_id eq 'd_etc') {
            $result .= $ident ."  ". qq[    <util:RemoveFolderEx On="uninstall" Property="UNINSTALL_ETC" />\n];
        } elsif ($dir_id eq 'd_logs') {
            $result .= $ident ."  ". qq[    <util:RemoveFolderEx On="uninstall" Property="UNINSTALL_LOG" />\n];
        } else {
            $result .= $ident ."  ". qq[    <RemoveFolder Id="rm.$dir_id" On="uninstall" />\n];
        }
        $result .= $ident ."  ". qq[</Component>\n];
    }

    if (scalar(@f) > 0) {
        for my $f (@f) {
            my $file_id = $self->_gen_file_id($f->{short_name});
            my $file_basename = basename($f->{full_name});
            my $file_shortname = $self->_get_short_basename($f->{full_name});
            ($component_id, $component_guid) = $self->_gen_component_id($file_shortname."files");
            # Eventually fix file feature
            my $this_feat = _file_feature_match->{$f->{short_name}};
            unless ($this_feat) {
                ($this_feat) = grep { $f->{short_name} =~ _feature_rematch->{$_} } keys(%{&_feature_rematch});
                $this_feat = $feat unless $this_feat;
            }
            my $vital = $this_feat eq "feat_AGENT" ? ' Vital="yes"' : "";
            # in 1file/component scenario set KeyPath on file, not on Component
            # see: http://stackoverflow.com/questions/10358989/wix-using-keypath-on-components-directories-files-registry-etc-etc
            $result .= $ident ."  ". qq[<Component Id="$component_id" Guid="{$component_guid}" Feature="$this_feat">\n];
            $result .= $ident ."  ". qq[  <File Id="$file_id" Name="$file_basename" ShortName="$file_shortname" Source="$f->{full_name}" KeyPath="yes"$vital />\n];
            # Only add service setup on feat_AGENT
            if ($this_feat eq "feat_AGENT") {
                my $servicename = $self->global->{service_name};
                $result .= $ident ."  ". qq[  <ServiceInstall Name="$servicename" Start="auto"\n];
                $result .= $ident ."  ". qq[                  ErrorControl="normal" DisplayName="!(loc.ServiceDisplayName)" Description="!(loc.ServiceDescription)" Interactive="no"\n];
                $result .= $ident ."  ". qq[                  Type="ownProcess" Arguments='-I"[INSTALLDIR]perl\\agent" -I"[INSTALLDIR]perl\\site\\lib" -I"[INSTALLDIR]perl\\vendor\\lib" -I"[INSTALLDIR]perl\\lib" "[INSTALLDIR]perl\\bin\\glpi-win32-service"'>\n];
                $result .= $ident ."  ". qq[    <util:ServiceConfig FirstFailureActionType="restart" SecondFailureActionType="restart" ThirdFailureActionType="restart" RestartServiceDelayInSeconds="60" />\n];
                $result .= $ident ."  ". qq[  </ServiceInstall>\n];
                $result .= $ident ."  ". qq[  <ServiceControl Id="SetupService" Name="$servicename" Start="install" Stop="both" Remove="both" Wait="yes" />\n];
            } elsif ($file_id eq "f_agentmonitor_exe") {
                my $regpath = "Software\\Microsoft\\Windows\\CurrentVersion\\Run";
                # Install GLPI-AgentMonitor only when required
                $result .= $ident ."  ". qq[  <Condition>AGENTMONITOR=1 AND EXECMODE=1</Condition>\n];
                # Add registry entry dedicated to GLPI-AgentMonitor autorun
                $result .= $ident ."  ". qq[  <RegistryValue Root="HKLM" Key="$regpath" Name="GLPI-AgentMonitor" Type="string" Value="[#f_agentmonitor_exe]" />\n];
                # Add Start menu shortcut for GLPI-AgentMonitor
                $result .= $ident ."  ". qq[  <Shortcut Id="AgentMonitorStartMenu" Advertise="yes" Directory="ProgramMenuFolder" Name="GLPI Agent Monitor" WorkingDirectory="d_perl_bin" Icon="agentmonitor.ico" />\n];
            }
            # Add dedicated component for registry just after feat_AGENT
            if ($this_feat eq "feat_AGENT") {
                my $installversion = $self->global->{agent_version};
                my $regpath = "Software\\".$self->global->{_provider}."-Agent";
                ($component_id, $component_guid) = $self->_gen_component_id("registry");
                $result .= $ident ."  ". qq[</Component>\n];
                $result .= $ident ."  ". qq[<Component Id="$component_id" Guid="{$component_guid}" Feature="$this_feat">\n];
                $result .= $ident ."  ". qq[  <RegistryKey Root="HKLM" Key="$regpath">\n];

                # By convention, msi command line options are in upper case and dash are replace by underscore
                foreach my $key (qw(
                    additional-content
                    backend-collect-timeout
                    ca-cert-dir
                    ca-cert-file
                    conf-reload-interval
                    debug
                    delaytime
                    esx-itemtype
                    features
                    full-inventory-postpone
                    glpi-version
                    html
                    httpd-ip
                    httpd-port
                    httpd-trust
                    itemtype
                    json
                    lazy
                    listen
                    local
                    logfile
                    logfile-maxsize
                    logger
                    no-category
                    no-compression
                    no-httpd
                    no-p2p
                    no-ssl-check
                    no-task
                    oauth-client-id
                    oauth-client-secret
                    password
                    proxy
                    remote
                    remote-workers
                    required-category
                    scan-homedirs
                    scan-profiles
                    server
                    snmp-retries
                    ssl-cert-file
                    ssl-fingerprint
                    ssl-key-file
                    ssl-keystore
                    tag
                    tasks
                    timeout
                    user
                    vardir
                )) {
                    my $option = uc($key);
                    $option =~ s/-/_/g;
                    $result .= $ident ."  ". qq[    <RegistryValue Name="$key" Type="string" Value="[$option]" />\n];
                }
                $result .= $ident ."  ". qq[  </RegistryKey>\n];
                # Installer dedicated options
                $result .= $ident ."  ". qq[  <RegistryKey Root="HKLM" Key="$regpath\\Installer">\n];
                foreach my ($key, $option) (qw(
                    InstallDir              INSTALLDIR
                    ExecMode                EXECMODE
                    QuickInstall            QUICKINSTALL
                    AddFirewallException    ADD_FIREWALL_EXCEPTION
                    RunNow                  RUNNOW
                    TaskFrequency           TASK_FREQUENCY
                    TaskMinuteModifier      TASK_MINUTE_MODIFIER
                    TaskHourlyModifier      TASK_HOURLY_MODIFIER
                    TaskDailyModifier       TASK_DAILY_MODIFIER
                    AgentMonitor            AGENTMONITOR
                )) {
                    $result .= $ident ."  ". qq[    <RegistryValue Name="$key" Type="string" Value="[$option]" />\n];
                }
                # Add registry entry dedicated to deployment vbs check
                $result .= $ident ."  ". qq[    <RegistryValue Name="Version" Type="string" Value="$installversion" />\n];
                $result .= $ident ."  ". qq[  </RegistryKey>\n];
                # Handle Agent-Monitor options with type
                $result .= $ident ."  ". qq[  <RegistryKey Root="HKLM" Key="$regpath\\Monitor">\n];
                foreach my ($key, $option) ((
                    "NewTicket-URL"         => [ "string",  "AGENTMONITOR_NEWTICKET_URL" ],
                    "NewTicket-Screenshot"  => [ "integer", "AGENTMONITOR_NEWTICKET_SCREENSHOT" ],
                )) {
                    $result .= $ident ."  ". qq[    <RegistryValue Name="$key" Type="$option->[0]" Value="[$option->[1]]" />\n];
                }
                $result .= $ident ."  ". qq[  </RegistryKey>\n];
            }
            $result .= $ident ."  ". qq[</Component>\n];
        }
    }

    $result .= $self->_tree2xml($_, $mark, 1) for (@d);
    $result .= $ident . qq[</Directory>\n] if $not_root && $root->{mark} eq $mark;

    return $result;
}

sub _gen_dir_id {
    my ($self, $dir) = @_;
    return _dir_id_match->{lc($dir)} // "d" . $self->{id_counter}++;
}

sub _gen_file_id {
  my ($self, $file) = @_;
  my $r;
  $r = "f_agent_exe"  if lc($file) eq 'perl\bin\glpi-agent.exe';
  $r = "f_agentmonitor_exe"  if $file =~ /perl\\bin\\glpi-agentmonitor-x(86|64).exe/i;
  $r = "f_glpiagent"  if lc($file) eq 'glpi-agent.bat';
  return  $r // "f" . $self->{id_counter}++;
}

package
    Perl::Dist::GLPI::Agent::Step::Update;

use parent 'Perl::Dist::Strawberry::Step';

use File::Spec::Functions qw(catfile);
use Template;

sub run {
    my $self = shift;

    my $bat = "contrib/windows/packaging/template.bat.tt";
    my $version = "contrib/windows/packaging/Version.pm.tt";

    my $t = Template->new(ABSOLUTE=>1);

    $self->boss->message(2, "gonna update installation");

    # Install dedicated bat files
    foreach my $f (qw(agent esx injector inventory netdiscovery netinventory remote wakeonlan)) {
        my $dest = catfile($self->global->{image_dir}, 'glpi-'.$f.'.bat');
        my $tag = { tag => $f };
        $t->process($bat, $tag, $dest) || die $t->error();
    }

    my @comments = (
        "Provided by ".($ENV{PROVIDED_BY}||$self->global->{_provided_by}),
        "Installer built on ".scalar(gmtime())." UTC",
        "Built with Strawberry Perl ".$self->global->{_perl_version},
    );
    push @comments, "Built on github actions windows image for $ENV{GITHUB_REPOSITORY} repository"
        if $ENV{GITHUB_WORKSPACE};

    # Update Version.pm
    my $vars = {
        version  => $self->global->{agent_version},
        provider => $self->global->{_provider},
        comments => \@comments,
    };

    my $dest = catfile($self->global->{image_dir}, 'perl/agent/GLPI/Agent/Version.pm');
    $t->process($version, $vars, $dest) || die $t->error();
}

package
    Perl::Dist::GLPI::Agent;

use parent qw(Perl::Dist::Strawberry);

use File::Path qw(remove_tree make_path);
use File::Spec::Functions qw(canonpath catdir);
use File::Glob qw(:glob);
use Time::HiRes qw(usleep);
use PerlBuildJob;

sub make_restorepoint {
    my ($self, $text) = @_;

    my $step = $self->global->{_restore_step};

    # Save a restorepoint only on the expected step
    return $self->message(3, "skipping restorepoint '$text'\n")
        unless $text =~ m{step:$step/};

    $self->SUPER::make_restorepoint($text);
}

sub create_dirs {
    my $self = shift;

    # Make a first pass on removing expected dirs as this may fail for unknown reason
    foreach my $global (qw(image_dir build_dir debug_dir env_dir)) {
        my $dir = $self->global->{$global}
            or next;
        if (-d $dir) {
            my $delete = '';
            if ($global eq 'build_dir') {
                $delete = catdir($dir, "msi");
                next unless -d $delete;
            } else {
                $delete = $dir;
            }

            remove_tree($delete) or die "ERROR: cannot delete '$delete'\n";

            # We may have some issue with fs synchro, be ready to wait a little
            my $timeout = time + 10;
            while ($delete && -d $delete && time < $timeout) {
                usleep(100000);
            }
        }
        -d $dir or make_path($dir) or die "ERROR: cannot create '$dir'\n";
    }

    my $wdir = $self->global->{working_dir};
    unless (-d $wdir) {
        make_path($wdir) or die "ERROR: cannot create '$wdir'\n";
    }

    make_path(catdir($self->global->{env_dir}, 'temp'));
    make_path(catdir($self->global->{env_dir}, 'AppDataRoaming'));
    make_path(catdir($self->global->{env_dir}, 'AppDataLocal'));
    make_path(catdir($self->global->{env_dir}, 'UserProfile'));

    # Create only if not exists
    -d $self->global->{restore_dir} or make_path($self->global->{restore_dir}) or die "ERROR: cannot create '".$self->global->{restore_dir}."'\n";
    -d $self->global->{output_dir}  or make_path($self->global->{output_dir})  or die "ERROR: cannot create '".$self->global->{output_dir}."'\n";
}

sub ask_about_restorepoint {
    my ($self, $image_dir, $bits) = @_;
    my @points;
    for my $pp (sort(bsd_glob($self->global->{restore_dir}."/*.pp"))) {
        my $d = eval { do($pp) };
        warn "SKIPPING/1 $pp\n" and next unless defined $d && ref($d) eq 'HASH';
        warn "SKIPPING/2 $pp\n" and next unless defined $d->{build_job_steps};
        warn "SKIPPING/3 $pp\n" and next unless defined $d->{restorepoint_info};
        warn "SKIPPING/4 $pp\n" and next unless $d->{restorepoint_zip_image_dir} && -f $d->{restorepoint_zip_image_dir};
        warn "SKIPPING/5 $pp\n" and next unless $d->{restorepoint_zip_debug_dir} && -f $d->{restorepoint_zip_debug_dir};
        warn "SKIPPING/6 $pp\n" and next unless canonpath($d->{image_dir}) eq canonpath($image_dir);
        warn "SKIPPING/7 $pp\n" and next unless $d->{bits} == $bits;
        push @points, $d;
    }
    # Select the restore point at expected step
    my $step = $self->global->{_restore_step};
    my ($restorepoint) = grep { $_->{build_job_steps}->[$step]->{done} && ! $_->{build_job_steps}->[$step+1]->{done} } @points;
    return $restorepoint;
}

sub create_buildmachine {
    my ($self, $job, $restorepoint) = @_;

    $self->SUPER::create_buildmachine($job, $restorepoint);

    my $provider = $self->global->{_provider};
    my $version = $self->global->{agent_version};
    my $arch = $self->global->{arch};

    # Fix output basename
    $self->global->{output_basename} = "$provider-Agent-$version-$arch" ;
}

sub load_jobfile {
    my ($self) = @_;

    return build_job(
        $self->global->{arch},
        $self->global->{_revision},
        $self->global->{_no_test},
        $self->global->{_dllsuffix},
        $self->global->{skip_build},
    );
}
