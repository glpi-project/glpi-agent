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

# HACK: make "use Perl::Dist::GLPI::Agent::Step::XXX" works as included plugin
map { $INC{"Perl/Dist/GLPI/Agent/Step/$_.pm"} = __FILE__ } qw(Update OutputMSI Test);

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

sub build_app {
    my $bits = shift;

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
        agent_regpath   => "Software\\$provider-Agent",
        service_name    => lc($provider).'-agent',
        msi_sharedir    => 'contrib/windows/packaging',
        bits            => $bits,
        arch            => $bits == 32 ? "x86" : "x64",
        _restore_step   => 8,
    );

    $app->parse_options(
        -job            => "glpi-agent packaging",
        -image_dir      => "C:\\Strawberry-perl-for-$provider-Agent",
        -working_dir    => "C:\\Strawberry-perl-for-$provider-Agent_build",
        -wixbin_dir     => $wixbin_dir,
        -notest_modules,
        -nointeractive,
        -restorepoints,
    );

    return $app;
}

print "Building 64 bits packages...\n";
my $app = build_app(64);
$app->do_job()
    or exit(1);

unless (grep { /^--all$/ } @ARGV) {
    print "Skipping 32 bits packages for now\n";
    exit(0);
}

print "Building 32 bits packages...\n";
$app = build_app(32);
$app->do_job()
    or exit(1);

print "All packages building processing passed\n";

exit(0);

package
    Perl::Dist::GLPI::Agent::Step::Test;

use parent 'Perl::Dist::Strawberry::Step';

use File::Spec::Functions qw(catfile catdir);

sub run {
    my $self = shift;

    # If modules are defined, just install the modules
    if ($self->{config}->{modules}) {
        my @list = map {
            {
                module => $_,
                skiptest => 1,
                install_to => 'site',
            }
        } @{$self->{config}->{modules}};
        $self->install_modlist(@list) or die "FAILED to install test modules\n";
        return;
    }

    # Without modules set, run the tests
    my $perlbin = catfile($self->global->{image_dir}, 'perl/bin/perl.exe');

    my $makefile_pl_cmd = [ $perlbin, "Makefile.PL"];
    $self->boss->message(2, "Test: gonna run perl Makefile.PL");
    my $rv = $self->execute_standard($makefile_pl_cmd, catfile($self->global->{debug_dir}, "Agent-Tests-Makefile.log.txt"));
    die "ERROR: TEST, perl Makefile.PL\n" unless(defined $rv && $rv == 0);

    my $make_test_cmd = [ "gmake", "test" ];
    $self->boss->message(2, "Test: gonna run gmake test");
    $rv = $self->execute_standard($make_test_cmd, catfile($self->global->{debug_dir}, "Agent-Tests-make-test.log.txt"));
    die "ERROR: TEST, make test\n" unless(defined $rv && $rv == 0);
}

sub test {}

package
    Perl::Dist::GLPI::Agent::Step::OutputMSI;

use parent 'Perl::Dist::Strawberry::Step::OutputMSI';

use File::Slurp           qw(read_file write_file);
use File::Spec::Functions qw(canonpath catdir catfile);
use File::Basename;
use Data::Dump            qw(pp);
use Template;

use constant _dir_id_match => { qw(
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
)};

use constant _file_feature_match => { qw(
    perl\bin\glpi-agent.exe                                 feat_AGENT

    glpi-netdiscovery.bat                                   feat_NETINV
    glpi-netinventory.bat                                   feat_NETINV
    perl\bin\glpi-netdiscovery                              feat_NETINV
    perl\bin\glpi-netinventory                              feat_NETINV
    perl\agent\FusionInventory\Agent\Task\NetInventory.pm   feat_NETINV
    perl\agent\FusionInventory\Agent\Task\NetDiscovery.pm   feat_NETINV
    perl\agent\FusionInventory\Agent\Tools\Hardware.pm      feat_NETINV
    perl\agent\FusionInventory\Agent\Tools\SNMP.pm          feat_NETINV
    perl\agent\FusionInventory\Agent\SNMP.pm                feat_NETINV

    perl\agent\FusionInventory\Agent\Task\Deploy.pm         feat_DEPLOY
    perl\bin\7z.exe                                         feat_DEPLOY
    perl\bin\7z.dll                                         feat_DEPLOY

    perl\agent\FusionInventory\Agent\Task\Collect.pm        feat_COLLECT

    glpi-esx.bat                                            feat_ESX
    perl\bin\glpi-esx                                       feat_ESX
    perl\agent\FusionInventory\Agent\Task\ESX.pm            feat_ESX

    glpi-wakeonlan.bat                                      feat_WOL
    perl\bin\glpi-wakeonlan                                 feat_WOL
    perl\agent\FusionInventory\Agent\Task\WakeOnLan.pm      feat_WOL
)};

sub run {
    my $self = shift;

    my $bat = "contrib/windows/packaging/template.bat.tt";
    my $t = Template->new(ABSOLUTE=>1);

    # Re-install dedicated bat files not using config file
    foreach my $f (qw(agent wmi)) {
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
    write_file(catfile($self->global->{debug_dir}, 'TTvars_OutputMSI_'.time.'.txt'), pp(\%vars)); #debug dump
    $t->process($f2, \%vars, catfile($bdir, 'MSI_main-v2.wxs')) || die $t->error();
    $t->process($f3, \%vars, catfile($bdir, 'Variables-v2.wxi')) || die $t->error();
    $t->process($f4, \%vars, catfile($bdir, 'MSI_strings.wxl')) || die $t->error();

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
                $result .= $ident ."    ". qq[  <CreateFolder />\n];
                $result .= $ident ."    ". qq[  <RemoveFolder Id="rm.] .lc($id). qq[" On="uninstall" />\n];
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
            # Get specific file feature or take the one from the parent folder or even the default one
            my $this_feat = _file_feature_match->{$f->{short_name}} || $feat;
            my $vital = $this_feat eq "feat_AGENT" ? ' Vital="yes"' : "";
            # in 1file/component scenario set KeyPath on file, not on Component
            # see: http://stackoverflow.com/questions/10358989/wix-using-keypath-on-components-directories-files-registry-etc-etc
            $result .= $ident ."  ". qq[<Component Id="$component_id" Guid="{$component_guid}" Feature="$this_feat">\n];
            $result .= $ident ."  ". qq[  <File Id="$file_id" Name="$file_basename" ShortName="$file_shortname" Source="$f->{full_name}" KeyPath="yes"$vital />\n];
            # Add service, registry and firewall definitions on feat_AGENT
            if ($this_feat eq "feat_AGENT") {
                my $servicename = $self->global->{service_name};
                my $regpath = "Software\\".$self->global->{_provider}."-Agent";
                $result .= $ident ."  ". qq[  <ServiceInstall Name="$servicename" Start="auto"\n];
                $result .= $ident ."  ". qq[                  ErrorControl="normal" DisplayName="!(loc.ServiceDisplayName)" Description="!(loc.ServiceDescription)" Interactive="no"\n];
                $result .= $ident ."  ". qq[                  Type="ownProcess" Arguments='-I"[INSTALLDIR]perl\\agent" "[INSTALLDIR]perl\\bin\\glpi-win32-service"'>\n];
                $result .= $ident ."  ". qq[    <util:ServiceConfig FirstFailureActionType="restart" SecondFailureActionType="restart" ThirdFailureActionType="restart" RestartServiceDelayInSeconds="60" />\n];
                $result .= $ident ."  ". qq[  </ServiceInstall>\n];
                $result .= $ident ."  ". qq[  <ServiceControl Id="SetupService" Name="$servicename" Start="install" Stop="both" Remove="both" Wait="yes" />\n];
                $result .= $ident ."  ". qq[  <RegistryKey Root="HKLM" Key="$regpath">\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="debug" Type="string" Value="[DEBUG]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="local" Type="string" Value="[LOCAL]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="logger" Type="string" Value="[LOGGER]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="logfile" Type="string" Value="[LOGFILE]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="logfile-maxsize" Type="string" Value="[LOGFILE_MAXSIZE]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="server" Type="string" Value="[SERVER]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="no-httpd" Type="string" Value="[NO_HTTPD]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="httpd-ip" Type="string" Value="[HTTPD_IP]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="httpd-port" Type="string" Value="[HTTPD_PORT]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="httpd-trust" Type="string" Value="[HTTPD_TRUST]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="tag" Type="string" Value="[TAG]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="scan-homedirs" Type="string" Value="[SCAN_HOMEDIRS]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="scan-profiles" Type="string" Value="[SCAN_PROFILES]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="no-p2p" Type="string" Value="[NO_P2P]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="timeout" Type="string" Value="[TIMEOUT]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="delaytime" Type="string" Value="[DELAYTIME]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="backend-collect-timeout" Type="string" Value="[BACKEND_COLLECT_TIMEOUT]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="no-task" Type="string" Value="[NO_TASK]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="no-category" Type="string" Value="[NO_CATEGORY]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="html" Type="string" Value="[HTML]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="lazy" Type="string" Value="[LAZY]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="conf-reload-interval" Type="string" Value="[CONF_RELOAD_INTERVAL]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="no-ssl-check" Type="string" Value="[NO_SSL_CHECK]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="user" Type="string" Value="[USER]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="password" Type="string" Value="[PASSWORD]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="proxy" Type="string" Value="[PROXY]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="tasks" Type="string" Value="[TASKS]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="ca-cert-dir" Type="string" Value="[CA_CERT_DIR]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="ca-cert-file" Type="string" Value="[CA_CERT_FILE]" />\n];
                $result .= $ident ."  ". qq[  </RegistryKey>\n];
                $result .= $ident ."  ". qq[  <RegistryKey Root="HKLM" Key="Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\[ProductCode]">\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="[ProductName]: ExecMode" Type="string" Value="[EXECMODE]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="[ProductName]: QuickInstall" Type="string" Value="[QUICKINSTALL]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="[ProductName]: AddFirewallException" Type="string" Value="[ADD_FIREWALL_EXCEPTION]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="[ProductName]: RunNow" Type="string" Value="[RUNNOW]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="[ProductName]: TaskFrequency" Type="string" Value="[TASK_FREQUENCY]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="[ProductName]: TaskMinuteModifier" Type="string" Value="[TASK_MINUTE_MODIFIER]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="[ProductName]: TaskHourlyModifier" Type="string" Value="[TASK_HOURLY_MODIFIER]" />\n];
                $result .= $ident ."  ". qq[    <RegistryValue Name="[ProductName]: TaskDailyModifier" Type="string" Value="[TASK_DAILY_MODIFIER]" />\n];
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

use File::Path qw(remove_tree);
use File::Spec::Functions qw(canonpath);
use File::Glob qw(:glob);
use Time::HiRes qw(usleep);

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
        remove_tree($dir) if -d $dir;

        # We may have some issue with fs synchro, be ready to wait a little
        my $timeout = time + 10;
        while (-d $dir && time < $timeout) {
            usleep(100000);
        }
    }

    $self->SUPER::create_dirs();
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

sub build_job_pre {
    my ($self) = @_;
    $self->SUPER::build_job_pre();

    my $provider = $self->global->{_provider};
    my $version = $self->global->{agent_version};
    my $arch = $self->global->{arch};

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
    return $self->global->{bits} == 64;
}

sub __tools {
    my ($self, $tool) = @_;
    my $bits = $self->global->{bits};
    return '<package_url>/kmx/'.$bits.'_tools/'.$bits.'bit_'.$tool.'.zip';
}

sub __gcctoolchain {
    my ($self) = @_;
    my $bits = $self->global->{bits};
    return '<package_url>/kmx/'.$bits.'_gcctoolchain/mingw64-w'.$bits.'-gcc8.3.0_20190316.zip';
}

sub __gcclib {
    my ($self, $quarter, $lib, $date) = @_;
    my $bits = $self->global->{bits};
    unless ($date) {
        my %date = qw( 2019Q2 20190522 2020Q1 20200207 );
        $date = $date{$quarter};
    }
    return '<package_url>/kmx/'.$bits.'_libs/gcc83-'.$quarter.'/'.$bits.'bit_'.$lib.
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
        bits            => $self->global->{bits},
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
            'contrib/windows/packaging/agentexe.ico'                             => 'win32/agentexe.ico',
            '<dist_sharedir>/perl-'.$MAJOR.'.'.$MINOR.'/win32_config.gc.tt'      => 'win32/config.gc',
            'contrib/windows/packaging/agentexe.rc.tt'                           => 'win32/perlexe.rc',
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
            { do=>'removedir', args=>[ '<image_dir>/licenses' ] },
            { do=>'removefile', args=>[ '<image_dir>/etc/gdbinit' ] },
            { do=>'removefile_recursive', args=>[ '<image_dir>/perl', qr/^\.packlist$/i ] },
            { do=>'removefile_recursive', args=>[ '<image_dir>/perl', qr/\.pod$/i ] },
            { do=>'removefile_recursive', args=>[ '<image_dir>/perl', qr/\.a$/i ] },
        ],
    },
    ### NEXT STEP ###########################
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
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
        commands => [
            { do=>'removedir', args=>[ '<image_dir>/bin' ] },
            { do=>'removedir', args=>[ '<image_dir>/c' ] },
            { do=>'removedir', args=>[ '<image_dir>/'.($self->is64bit?'x86_64':'i686').'-w64-mingw32' ] },
            { do=>'removedir', args=>[ '<image_dir>/include' ] },
            { do=>'removedir', args=>[ '<image_dir>/lib' ] },
            { do=>'removedir', args=>[ '<image_dir>/libexec' ] },
        ],
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::GLPI::Agent::Step::Test',
    },
    ### NEXT STEP ###########################
    {
        plugin => 'Perl::Dist::Strawberry::Step::FilesAndDirs',
        commands => [
            { do=>'removedir', args=>[ '<image_dir>/perl/site/lib' ] },
            { do=>'createdir', args=>[ '<image_dir>/perl/site/lib' ] },
            # updates for glpi-agent
            { do=>'createdir', args=>[ '<image_dir>/perl/agent' ] },
            { do=>'createdir', args=>[ '<image_dir>/perl/newbin' ] },
            { do=>'createdir', args=>[ '<image_dir>/var' ] },
            { do=>'createdir', args=>[ '<image_dir>/log' ] },
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
            { do=>'copyfile', args=>[ 'contrib/windows/packaging/tools/x86/dmidecode.exe', '<image_dir>/perl/bin' ] },
            { do=>'copyfile', args=>[ 'contrib/windows/packaging/tools/x86/hdparm.exe', '<image_dir>/perl/bin' ] },
            { do=>'copyfile', args=>[ 'contrib/windows/packaging/tools/'.($self->is64bit?'x64':'x86').'/7z.exe', '<image_dir>/perl/bin' ] },
            { do=>'copyfile', args=>[ 'contrib/windows/packaging/tools/'.($self->is64bit?'x64':'x86').'/7z.dll', '<image_dir>/perl/bin' ] },
            { do=>'movefile', args=>[ '<image_dir>/perl/bin/perl.exe', '<image_dir>/perl/bin/glpi-agent.exe' ] },
            { do=>'copydir', args=>[ 'lib/FusionInventory', '<image_dir>/perl/agent/FusionInventory' ] },
            { do=>'copydir', args=>[ 'etc', '<image_dir>/etc' ] },
            { do=>'createdir', args=>[ '<image_dir>/etc/conf.d' ] },
            { do=>'copydir', args=>[ 'bin', '<image_dir>/perl/bin' ] },
            { do=>'copydir', args=>[ 'share', '<image_dir>/share' ] },
            { do=>'copyfile', args=>[ 'contrib/windows/packaging/setup.pm', '<image_dir>/perl/lib' ] },
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
    };
}
