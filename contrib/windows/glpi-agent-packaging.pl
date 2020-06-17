#!perl

use strict;
use warnings;

use Win32::TieRegistry qw( KEY_READ );

use constant {
    PERL_VERSION        => "5.30.2",
    PACKAGE_REVISION    => "1", #BEWARE: always start with 1
    PROVIDED_BY         => "Teclib Edition",
};

use lib 'lib';
use FusionInventory::Agent::Version;

# HACK: make "use Perl::Dist::GLPI::Agent::Step::Update" works as included plugin
$INC{'Perl/Dist/GLPI/Agent/Step/Update.pm'} = __FILE__;
$INC{'Perl/Dist/GLPI/Agent/Step/OutputMSI.pm'} = __FILE__;

# Perl::Dist::Strawberry doesn't detect WiX 3.11 which is installed on windows github images
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

my $provider = $FusionInventory::Agent::Version::PROVIDER;
my $version = $FusionInventory::Agent::Version::VERSION;
my ($major,$minor,$revision) = $version =~ /^(\d+)\.(\d+)\.?(\d+)?/;
$revision = 0 unless defined($revision);

if ($version =~ /-dev$/ && $ENV{GITHUB_SHA}) {
    my ($github_ref) = $ENV{GITHUB_SHA} =~ /^([0-9a-f]{8})/;
    $version =~ s/-dev$/-git/;
    $version .= ($github_ref || $ENV{GITHUB_SHA});
}

if ($ENV{GITHUB_REF} && $ENV{GITHUB_REF} =~ m|refs/tags/(.+)$|) {
    my $tag = $1;
    if ($revision) {
        $version = $tag =~ /^$major\.$minor\.$revision/ ? $tag : "$major.$minor.$revision-$tag";
    } else {
        $version = $tag =~ /^$major\.$minor/ ? $tag : "$major.$minor-$tag";
    }
}

my $app = Perl::Dist::GLPI::Agent->new(
    _perl_version   => PERL_VERSION,
    _revision       => PACKAGE_REVISION,
    _provider       => $provider,
    _provided_by    => PROVIDED_BY,
    agent_version   => $version,
    agent_fullver   => $major.'.'.$minor.'.'.$revision.'.'.PACKAGE_REVISION,
    agent_msiver    => $major.'.'.$minor.'.'.$revision,
    agent_fullname  => $provider.' Agent',
    agent_rootdir   => $provider.'-Agent',
    agent_regpath   => "Software\\$provider.-Agent",
    service_name    => lc($provider).'-agent',
    msi_sharedir    => 'contrib/windows/packaging',
);

$app->parse_options(
    -job            => "glpi-agent packaging",
    -image_dir      => "C:\\Strawberry-perl-for-$provider-Agent",
    -working_dir    => "C:\\Strawberry-perl-for-$provider-Agent_build",
    -wixbin_dir     => $wixbin_dir,
    -notest_modules,
    -nointeractive,
);

print "Building 64 bits packages...\n";
$app->global->{arch} = 64;
$app->do_job()
    or exit(1);

unless (grep { /^--all$/ } @ARGV) {
    print "Skipping 32 bits packages for now\n";
    exit(0);
}

print "Building 32 bits packages...\n";
$app->global->{arch} = 32;
$app->do_job()
    or exit(1);

print "All packages building processing passed\n";

exit(0);

package
    Perl::Dist::GLPI::Agent::Step::OutputMSI;

use parent 'Perl::Dist::Strawberry::Step::OutputMSI';

use File::Slurp           qw(read_file write_file);
use File::Spec::Functions qw(canonpath catdir catfile);
use File::Basename;
use Data::Dump            qw(pp);
use Template;

sub run {
    my $self = shift;

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
        msi_random_upgrade_code => $self->{data_uuid}->create_str(), # get random GUID
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
    my $t = Template->new(ABSOLUTE=>1);
    write_file(catfile($self->global->{debug_dir}, 'TTvars_OutputMSI_'.time.'.txt'), pp(\%vars)); #debug dump
    $t->process($f2, \%vars, catfile($bdir, 'MSI_main-v2.wxs')) || die $t->error();
    $t->process($f3, \%vars, catfile($bdir, 'Variables-v2.wxi')) || die $t->error();
    $t->process($f4, \%vars, catfile($bdir, 'MSI_strings.wxl')) || die $t->error();

    my $rv;
    my $candle_exe = $self->{candle_exe};
    my $light_exe = $self->{light_exe};

    my $candle2_cmd = [$candle_exe, "$bdir\\MSI_main-v2.wxs", '-out', "$bdir\\MSI_main.wixobj", '-v', '-ext', 'WixUIExtension'];
    # Set arch option if necessary
    push @{$candle2_cmd}, '-arch', 'x64' if $self->global->{arch} == 64;
    my $light2_cmd  = [$light_exe,  "$bdir\\MSI_main.wixobj", '-out', $msi_file, '-pdbout', "$bdir\\MSI_main.wixpdb", '-loc', "$bdir\\MSI_strings.wxl",
        qw/-ext WixUIExtension -ext WixUtilExtension -sice:ICE38 -sice:ICE43 -sice:ICE61/];

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

sub _get_dir_feature {
    my ($self, $dir_id) = @_;

    if ($dir_id =~ /^d_netinv/) {
        return "feat_NETINV";
    } elsif ($dir_id =~ /^d_deploy/) {
        return "feat_DEPLOY";
    } elsif ($dir_id =~ /^d_collect/) {
        return "feat_COLLECT";
    } elsif ($dir_id =~ /^d_esx/) {
        return "feat_ESX";
    } elsif ($dir_id =~ /^d_wol/) {
        return "feat_WOL";
    }

    return "feat_MSI";
}

sub _get_file_feature {
    my ($self, $file) = @_;

    if ($file =~ /^glpi-net.*|NetDiscovery\.pm|NetInventory\.pm|Hardware\.pm|SNMP\.pm$/) {
        return "feat_NETINV";
    } elsif ($file =~ /^Deploy\.pm$/) {
        return "feat_DEPLOY";
    } elsif ($file =~ /^Collect\.pm$/) {
        return "feat_COLLECT";
    } elsif ($file =~ /^glpi-esx.*|ESX\.pm$/) {
        return "feat_ESX";
    } elsif ($file =~ /^glpi-wakeonlan.*|WakeOnLan\.pm$/) {
        return "feat_WOL";
    }

    # Don't return anything to keep the feature of parent folder
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
        $feat = $self->_get_dir_feature($dir_id);
        $result .= $ident ."  ". qq[<Component Id="$component_id" Guid="{$component_guid}" KeyPath="yes" Feature="$feat">\n];
        $result .= $ident ."  ". qq[    <CreateFolder />\n];
        if ($dir_id eq 'd_var') {
            $result .= $ident ."  ". qq[    <util:RemoveFolderEx On="uninstall" Property="UNINSTALL_VAR" />\n];
        } elsif ($dir_id eq 'd_etc') {
            $result .= $ident ."  ". qq[    <util:RemoveFolderEx On="uninstall" Property="UNINSTALL_ETC" />\n];
        } elsif ($dir_id eq 'd_log') {
            $result .= $ident ."  ". qq[    <util:RemoveFolderEx On="uninstall" Property="UNINSTALL_LOG" />\n];
        } else {
            $result .= $ident ."  ". qq[    <RemoveFolder Id="rm.$dir_id" On="uninstall" />\n];
        }
        $result .= $ident ."  ". qq[</Component>\n];
        # Also add virtual folder properties under d_install
        if ($dir_id eq 'd_install') {
            foreach my $id (qw(_LOCALDIR)) {
                $result .= $ident ."  ". qq[<Directory Id="$id">\n];
                ($component_id, $component_guid) = $self->_gen_component_id(lc($id).".create");
                $result .= $ident ."    ". qq[<Component Id="$component_id" Guid="{$component_guid}" KeyPath="yes" Feature="$feat">\n];
                $result .= $ident ."    ". qq[    <CreateFolder />\n];
                $result .= $ident ."    ". qq[    <RemoveFolder Id="rm."] .lc($id). qq[" On="uninstall" />\n];
                $result .= $ident ."    ". qq[</Component>\n];
                $result .= $ident ."  ". qq[</Directory>\n];
            }
        }
    }

    if (scalar(@f) > 0) {
        for my $f (@f) {
            my $file_id = $self->_gen_file_id($f->{short_name});
            my $file_basename = basename($f->{full_name});
            my $file_shortname = $self->_get_short_basename($f->{full_name});
            ($component_id, $component_guid) = $self->_gen_component_id($file_shortname."files");
            my $this_feat = $self->_get_file_feature($f->{short_name}) || $feat;
            # in 1file/component scenario set KeyPath on file, not on Component
            # see: http://stackoverflow.com/questions/10358989/wix-using-keypath-on-components-directories-files-registry-etc-etc
            $result .= $ident ."  ". qq[<Component Id="$component_id" Guid="{$component_guid}" Feature="$this_feat">\n];
            $result .= $ident ."  ". qq[  <File Id="$file_id" Name="$file_basename" ShortName="$file_shortname" Source="$f->{full_name}" KeyPath="yes" />\n]; # XXX-TODO consider ReadOnly="yes"
            # Add service definition on glpi-agent.exe
            if ($f->{short_name} =~ /glpi-agent\.exe$/) {
                my $servicename = $self->global->{service_name};
                my $regpath = "Software\\".$self->global->{_provider}."-Agent";
                $result .= $ident ."  ". qq[  <ServiceInstall Name="$servicename" Start="auto"\n];
                $result .= $ident ."  ". qq[                  ErrorControl="normal" DisplayName="!(loc.ServiceDisplayName)" Description="!(loc.ServiceDescription)" Interactive="no"\n];
                $result .= $ident ."  ". qq[                  Type="ownProcess" Arguments='-I"[INSTALLDIR]perl\\agent" "[INSTALLDIR]perl\\bin\\glpi-win32-service"'>\n];
                $result .= $ident ."  ". qq[  </ServiceInstall>\n];
                $result .= $ident ."  ". qq[  <ServiceControl Id="SetupService" Name="$servicename" Stop="both" Start="install" Remove="both" Wait="no" />\n];
                $result .= $ident ."  ". qq[  <RegistryKey Root="HKLM" Key="$regpath">\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="debug" Type="string" Value="[DEBUG]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="local" Type="string" Value="[LOCAL]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="logfile" Type="string" Value="[LOGFILE]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="server" Type="string" Value="[SERVER]" />\n];
                $result .= $ident ."  ". qq[  </RegistryKey>\n];
            }
            $result .= $ident ."  ". qq[</Component>\n];
        }
    }

    $result .= $self->_tree2xml($_, $mark, 1) for (@d);
    $result .= $ident . qq[</Directory>\n] if $not_root && $root->{mark} eq $mark;

    return $result;
}

my %dir_id_match = qw(
    perl            d_perl
    perl\bin        d_perl_bin
    var             d_var
    log             d_log
    etc             d_etc
    perl\agent\fusioninventory\agent\task\netinventory  d_netinventory_task
    perl\agent\fusioninventory\agent\task\netdiscovery  d_netinv_discovery_task
    perl\agent\fusioninventory\agent\snmp               d_netinv_snmp
    perl\agent\fusioninventory\agent\snmp\device        d_netinv_device
    perl\agent\fusioninventory\agent\snmp\mibsupport    d_netinv_mibsupport
    perl\agent\fusioninventory\agent\tools\hardware     d_netinv_hardware
    perl\agent\fusioninventory\agent\task\deploy        d_deploy
    perl\agent\fusioninventory\agent\task\deploy\actionprocessor        d_deploy_ap
    perl\agent\fusioninventory\agent\task\deploy\actionprocessor\action d_deploy_action
    perl\agent\fusioninventory\agent\task\deploy\checkprocessor         d_deploy_cp
    perl\agent\fusioninventory\agent\task\deploy\datastore              d_deploy_ds
    perl\agent\fusioninventory\agent\task\deploy\usercheck              d_deploy_uc
    perl\agent\fusioninventory\agent\task\collect       d_collect
    perl\agent\fusioninventory\agent\task\esx           d_esx_task
    perl\agent\fusioninventory\agent\soap               d_esx_soap
    perl\agent\fusioninventory\agent\soap\vmware        d_esx_vmware
    perl\agent\fusioninventory\agent\task\wakeonlan     d_wol
);

sub _gen_dir_id {
    my ($self, $dir) = @_;
    return $dir_id_match{lc($dir)} // "d" . $self->{id_counter}++;
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
    foreach my $f (qw(agent esx injector inventory netdiscovery netinventory wakeonlan wmi)) {
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

    my $dest = catfile($self->global->{image_dir}, 'perl/agent/FusionInventory/Agent/Version.pm');
    $t->process($version, $vars, $dest) || die $t->error();

    # Update default conf to include conf.d folder
    open CONF, ">>", catfile($self->global->{image_dir}, 'etc/agent.cfg')
        or die "Can't open default conf: $!\n";
    print CONF "include 'conf.d/'\n";
    close(CONF);
}

package
    Perl::Dist::GLPI::Agent;

use parent qw(Perl::Dist::Strawberry);

sub build_job_pre {
    my ($self) = @_;
    $self->SUPER::build_job_pre();

    my $provider = $self->global->{_provider};
    my $version = $self->global->{agent_version};
    my $arch = $self->global->{arch} eq "64" ? "x64" : "x86" ;

    # Fix output basename
    $self->global->{output_basename} = "$provider-Agent-$version-$arch" ;
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
    my ($self, $quarter, $lib, $date) = @_;
    my $arch = $self->global->{arch};
    unless ($date) {
        my %date = qw( 2019Q2 20190522 2020Q1 20200207 );
        $date = $date{$quarter};
    }
    return '<package_url>/kmx/'.$arch.'_libs/gcc83-'.$quarter.'/'.$arch.'bit_'.$lib.
        '-bin_'.$date.'.zip';
}

sub __perl_source_url {
    my ($self) = @_;
    return 'http://cpan.metacpan.org/authors/id/S/SH/SHAY/' .
        'perl-'.$self->global->{_perl_version}.'.tar.gz';
}

sub __movedll {
    my ($self, $dll) = @_;
    return {
        do      => 'movefile',
        args    => [
            '<image_dir>/c/bin/'.$dll,
            '<image_dir>/perl/bin/'.$dll
        ]
    };
}

sub __movebin {
    my ($self, $bin) = @_;
    return {
        do      => 'movefile',
        args    => [
            '<image_dir>/perl/bin/'.$bin,
            '<image_dir>/perl/newbin/'.$bin
        ]
    };
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
    my ($MAJOR, $MINOR) = $self->global->{_perl_version} =~ /^(\d+)\.(\d+)\./;
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
            'freeglut'      => $self->__gcclib('2020Q1','freeglut-2.8.1', '20200209'),
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
            '<dist_sharedir>/perl-'.$MAJOR.'.'.$MINOR.'/win32_config.gc.tt'      => 'win32/config.gc',
            '<dist_sharedir>/perl-'.$MAJOR.'.'.$MINOR.'/perlexe.rc.tt'           => 'win32/perlexe.rc',
            '<dist_sharedir>/perl-'.$MAJOR.'.'.$MINOR.'/win32_config_H.gc'       => 'win32/config_H.gc', # enables gdbm/ndbm/odbm
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
            # IPC related
            { module=>'IPC-Run', skiptest=>1 }, #XXX-TODO trouble with 'Terminating on signal SIGBREAK(21)' https://metacpan.org/release/IPC-Run

            { module=>'LWP::UserAgent', skiptest=>1 }, # XXX-HACK: 6.08 is broken

            #removed from core in 5.20
            { module=>'Archive::Extract',  ignore_testfailure=>1 }, #XXX-TODO-5.28/64bit

            # win32 related
            qw/Win32API::Registry Win32::TieRegistry/,
            { module=>'Win32::OLE',         ignore_testfailure=>1 }, #XXX-TODO: ! Testing Win32-OLE-0.1711 failed
            { module=>'Win32::API',         ignore_testfailure=>1 }, #XXX-TODO: https://rt.cpan.org/Public/Bug/Display.html?id=107450
            qw/ Win32-Daemon /,
            qw/ Win32::Job /,
            qw/ Sys::Syslog /,

            # file related
            { module=>'File::Copy::Recursive', ignore_testfailure=>1 }, #XXX-TODO-5.28
            qw/ File-Which /,

            # SSL & SSH & telnet
            { module=>'Net-SSLeay', ignore_testfailure=>1 }, # openssl-1.1.1 related
            'Mozilla::CA', # optional dependency of IO-Socket-SSL
            { module=>'IO-Socket-SSL', skiptest=>1 },

            # network
            qw/ IO::Socket::IP IO::Socket::INET6 /,
            qw/ HTTP-Server-Simple /,
            { module=>'LWP::Protocol::https', skiptest=>1 },
            { module=>'<package_url>/kmx/perl-modules-patched/Crypt-SSLeay-0.72_patched.tar.gz' }, #XXX-FIXME

            # XML & co.
            qw/ XML-Parser /,

            # crypto
            qw/ CryptX /,
            qw/ Crypt::DES Crypt::Rijndael /,
            qw/ Digest-MD5 Digest-SHA Digest-SHA1 Digest::HMAC /,

            # date/time
            qw/ DateTime Date::Format DateTime::TimeZone::Local::Win32 /,

            # misc
            { module=>'Unicode::UTF8', ignore_testfailure=>1 }, #XXX-TODO-5.28

            # GLPI-Agent deps
            qw/ File::Which Text::Template UNIVERSAL::require XML::TreePP XML::XPath /,
            qw/ Memoize Time::HiRes Compress::Zlib Win32::Unicode::File /,
            qw/ Parse::EDID JSON::PP YAML::Tiny Parallel::ForkManager URI::Escape /,
            qw/ Net::NBName Thread::Queue Thread::Semaphore /,
            qw/ Net::SNMP Net::SNMP::Security::USM Net::SNMP::Transport::IPv4::TCP
                Net::SNMP::Transport::IPv6::TCP Net::SNMP::Transport::IPv6::UDP /,
            qw/ Net::IP Archive::Zip /,
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
            # cleanup (remove unwanted files/dirs)
            { do=>'removefile', args=>[ '<image_dir>/perl/vendor/lib/Crypt/._test.pl', '<image_dir>/perl/vendor/lib/DBD/testme.tmp.pl' ] },
            { do=>'removefile_recursive', args=>[ '<image_dir>/perl', qr/.+\.dll\.AA[A-Z]$/i ] },
            # cleanup cpanm related files
            { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread-64int' ] },
            { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x86-multi-thread' ] },
            { do=>'removedir', args=>[ '<image_dir>/perl/site/lib/MSWin32-x64-multi-thread' ] },
            # updates for glpi-agent
            { do=>'createdir', args=>[ '<image_dir>/perl/agent' ] },
            { do=>'createdir', args=>[ '<image_dir>/perl/newbin' ] },
            { do=>'createdir', args=>[ '<image_dir>/var' ] },
            $self->__movebin('libgcc_s_'.($self->is64bit?'seh':'dw2').'-1.dll'),
            $self->__movebin('libstdc++-6.dll'),
            $self->__movebin('libwinpthread-1.dll'),
            $self->__movebin('perl.exe'),
            $self->__movebin('perl'.$MAJOR.$MINOR.'.dll'),
            { do=>'removedir', args=>[ '<image_dir>/perl/bin' ] },
            { do=>'movedir', args=>[ '<image_dir>/perl/newbin', '<image_dir>/perl/bin' ] },
            $self->__movedll('libbz2-1__.dll'),
            $self->__movedll('libcrypto-1_1'.($self->is64bit?'-x64__':'').'.dll'),
            $self->__movedll('libexpat-1__.dll'),
            $self->__movedll('liblzma-5__.dll'),
            $self->__movedll('libssl-1_1'.($self->is64bit?'-x64__':'').'.dll'),
            $self->__movedll('zlib1__.dll'),
            { do=>'copyfile', args=>[ 'contrib/windows/packaging/dmidecode.exe', '<image_dir>/perl/bin' ] },
            { do=>'copyfile', args=>[ '<image_dir>/perl/bin/perl.exe', '<image_dir>/perl/bin/glpi-agent.exe' ] },
            { do=>'removedir', args=>[ '<image_dir>/bin' ] },
            { do=>'removedir', args=>[ '<image_dir>/c' ] },
            { do=>'removedir', args=>[ '<image_dir>/'.($self->is64bit?'x86_64':'i686').'-w64-mingw32' ] },
            { do=>'removedir', args=>[ '<image_dir>/include' ] },
            { do=>'removedir', args=>[ '<image_dir>/lib' ] },
            { do=>'removedir', args=>[ '<image_dir>/libexec' ] },
            { do=>'removedir', args=>[ '<image_dir>/licenses' ] },
            { do=>'removefile', args=>[ '<image_dir>/etc/gdbinit' ] },
            { do=>'copydir', args=>[ 'lib/FusionInventory', '<image_dir>/perl/agent/FusionInventory' ] },
            { do=>'copydir', args=>[ 'etc', '<image_dir>/etc' ] },
            { do=>'createdir', args=>[ '<image_dir>/etc/conf.d' ] },
            { do=>'copydir', args=>[ 'bin', '<image_dir>/perl/bin' ] },
            { do=>'copydir', args=>[ 'share', '<image_dir>/share' ] },
            { do=>'copyfile', args=>[ 'contrib/windows/packaging/setup.pm', '<image_dir>/perl/lib' ] },
            { do=>'removefile_recursive', args=>[ '<image_dir>/perl', qr/^\.packlist$/i ] },
            { do=>'removefile_recursive', args=>[ '<image_dir>/perl', qr/\.pod$/i ] },
        ],
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::GLPI::Agent::Step::Update',
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::OutputZIP', # no options needed
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::GLPI::Agent::Step::OutputMSI',
        exclude  => [
            #'dirname\subdir1\subdir2',
            #'dirname\file.pm',
        ],
        #BEWARE: msi_upgrade_code is a fixed value for all same arch releases (for ever)
        msi_upgrade_code    => $self->is64bit ? '0DEF72A8-E5EE-4116-97DC-753718E19CD5' : '7F25A9A4-BCAE-4C15-822D-EAFBD752CFEC', 
        app_publisher       => 'GLPI Project',
        url_about           => 'https://glpi-project.org/',
        url_help            => 'https://glpi-project.org/discussions/',
        msi_root_dir        => 'GLPI-Agent',
        msi_main_icon       => 'contrib/windows/packaging/glpi-agent.ico',
        msi_license_rtf     => 'contrib/windows/packaging/gpl-2.0.rtf',
        msi_dialog_bmp      => 'contrib/windows/packaging/GLPI-Agent_Dialog.bmp',
        msi_banner_bmp      => 'contrib/windows/packaging/GLPI-Agent_Banner.bmp',
        msi_debug           => 0,
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
