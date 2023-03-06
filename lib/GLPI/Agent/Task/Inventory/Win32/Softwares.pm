package GLPI::Agent::Task::Inventory::Win32::Softwares;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Win32;
use GLPI::Agent::Tools::Win32::Constants;

use constant    category    => "software";

my $seen = {};

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $is64bit = is64bit();

    my $softwares64 = _getSoftwaresList( is64bit => $is64bit ) || [];
    foreach my $software (@$softwares64) {
        _addSoftware(inventory => $inventory, entry => $software);
    }

    _processMSIE(
        inventory => $inventory,
        is64bit   => $is64bit
    );

    my $userprofiles;
    if ($params{scan_profiles}) {
        GLPI::Agent::Tools::Win32::Users->require();
        $userprofiles = [ GLPI::Agent::Tools::Win32::Users::getSystemUserProfiles() ];
        _loadUserSoftware(
            inventory => $inventory,
            profiles  => $userprofiles,
            is64bit   => $is64bit,
            logger    => $logger
        );
    } else {
        $logger->debug(
            "'scan-profiles' configuration parameter disabled, " .
            "ignoring software in user profiles"
        );
    }

    if ($is64bit) {
        my $softwares32 = _getSoftwaresList(
            path    => "HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/Microsoft/Windows/CurrentVersion/Uninstall",
            is64bit => 0
        ) || [];
        foreach my $software (@$softwares32) {
            _addSoftware(inventory => $inventory, entry => $software);
        }

        _processMSIE(
            inventory => $inventory,
            is64bit   => 0
        );

        _loadUserSoftware(
            inventory => $inventory,
            profiles  => $userprofiles,
            is64bit   => 0,
            logger    => $logger
        ) if $params{scan_profiles};
    }

    # Cleanup privileges if we had to load user profiles
    GLPI::Agent::Tools::Win32::cleanupPrivileges()
        if $params{scan_profiles};

    my $hotfixes = _getHotfixesList(is64bit => $is64bit);
    foreach my $hotfix (@$hotfixes) {
        # skip fixes already found in generic software list,
        # without checking version information
        next if $seen->{$hotfix->{NAME}};
        _addSoftware(inventory => $inventory, entry => $hotfix);
    }

    # Lookup for UWP/Windows Store packages
    my ($operatingSystem) = getWMIObjects(
        class      => 'Win32_OperatingSystem',
        properties => [ qw/Version/ ]
    );
    if ($operatingSystem->{Version}) {
        my ($osversion) = $operatingSystem->{Version} =~ /^(\d+\.\d+)/;
        if ($osversion && $osversion > 6.1) {
            my $packages = _getAppxPackages(logger => $logger);
            if ($packages) {
                foreach my $package (@{$packages}) {
                    _addSoftware(inventory => $inventory, entry => $package);
                }
            }
        }
    }

    # Reset seen hash so we can see softwares in later same run inventory
    $seen = {};
}

sub _loadUserSoftware {
    my (%params) = @_;

    return unless $params{profiles};

    my $inventory = $params{inventory};
    my $is64bit   = $params{is64bit};
    my $logger    = $params{logger};

    foreach my $profile (@{$params{profiles}}) {
        my $sid = $profile->{SID}
            or next;
        my ($userid) = $sid =~ /-(\d+)$/;

        my $userhive;
        unless ($profile->{LOADED}) {
            my $ntuserdat = $profile->{PATH}."/NTUSER.DAT";
            # This call involves we use cleanupPrivileges before leaving
            $userhive = loadUserHive(sid => $sid, file => $ntuserdat);
        }

        my $username = GLPI::Agent::Tools::Win32::Users::getProfileUsername($profile)
            or next;

        my $profileSoft = "HKEY_USERS/$sid/SOFTWARE/";
        $profileSoft .= is64bit() && !$is64bit ?
                "Wow6432Node/Microsoft/Windows/CurrentVersion/Uninstall" :
                "Microsoft/Windows/CurrentVersion/Uninstall";

        my $softwares = _getSoftwaresList(
            path      => $profileSoft,
            is64bit   => $is64bit,
            userid    => $userid,
            username  => $username
        ) || [];
        next unless @$softwares;
        my $nbUsers = scalar(@$softwares);
        $logger->debug2('_loadUserSoftwareFromHKey_Users('.$sid.') : add of ' . $nbUsers . ' softwares in inventory');
        foreach my $software (@$softwares) {
            _addSoftware(inventory => $inventory, entry => $software);
        }
    }
}

sub _dateFormat {
    my ($date) = @_;

    ## no critic (ExplicitReturnUndef)
    return undef unless $date;

    if ($date =~ /^(\d{4})(\d{1})(\d{2})$/) {
        return "$3/0$2/$1";
    }

    if ($date =~ /^(\d{4})(\d{2})(\d{2})$/) {
        return "$3/$2/$1";
    }

    # Re-order "M/D/YYYY" as "DD/MM/YYYY"
    if ($date =~ /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/) {
        return sprintf("%02d/%02d/%04d", $2, $1, $3);
    }

    return undef;
}

sub _keyLastWriteDateString {
    my ($key) = @_;

    return unless OSNAME eq 'MSWin32';

    return unless (ref($key) eq "Win32::TieRegistry");

    my @lastWrite = FileTimeToSystemTime($key->Information("LastWrite"));

    return unless (@lastWrite > 3);

    return sprintf("%04s%02s%02s",$lastWrite[0],$lastWrite[1],$lastWrite[3]);
}

sub _getSoftwaresList {
    my (%params) = @_;

    my $softwares = getRegistryKey(
        path    => "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall",
        # Important for remote inventory optimization
        required    => [ qw/
            DisplayName Comments HelpLink ReleaseType DisplayVersion
            Publisher URLInfoAbout UninstallString InstallDate MinorVersion
            MajorVersion NoRemove SystemComponent
            /
        ],
        %params
    );

    my @list;

    return unless $softwares;

    my %mapping = qw(
        NAME                DisplayName
        COMMENTS            Comments
        HELPLINK            HelpLink
        RELEASE_TYPE        ReleaseType
        VERSION             DisplayVersion
        PUBLISHER           Publisher
        URL_INFO_ABOUT      URLInfoAbout
        UNINSTALL_STRING    UninstallString
    );

    my @subKeys = map { /^(.*)\/$/ } grep { m{/$} } keys(%{$softwares})
        or return;
    foreach my $guid (@subKeys) {
        # only keep subkeys with more than 1 value
        my $data = $softwares->{$guid."/"}
            or next;
        my %infos = $data->Information;
        # Just to support related test
        %infos = ( CntValues => scalar(grep { /^\// } keys(%{$data})) )
            unless exists($infos{CntValues});
        next unless $infos{CntValues} > 1;

        my $software = {
            FROM             => "registry",
            NAME             => $guid, # subkey name as default
            INSTALLDATE      => _dateFormat($data->{'/InstallDate'}),
            VERSION_MINOR    => hex2dec($data->{'/MinorVersion'}),
            VERSION_MAJOR    => hex2dec($data->{'/MajorVersion'}),
            NO_REMOVE        => hex2dec($data->{'/NoRemove'}),
            ARCH             => $params{is64bit} ? 'x86_64' : 'i586',
            GUID             => $guid,
            SYSTEM_CATEGORY  => $data->{'/SystemComponent'} && hex2dec($data->{'/SystemComponent'}) ?
                CATEGORY_SYSTEM_COMPONENT : CATEGORY_APPLICATION
        };

        foreach my $key (keys(%mapping)) {
            my $value = getRegistryKeyValue($data, $mapping{$key})
                or next;
            $software->{$key} = $value;
        }

        $software->{USERID} = $params{userid} if $params{userid};
        $software->{USERNAME} = $params{username} if $params{username};

        # Workaround for #415 (may be no more useful since using getRegistryKeyValue() api)
        $software->{VERSION} =~ s/[\000-\037].*// if $software->{VERSION};

        # Set install date to last registry key update time
        if (!defined($software->{INSTALLDATE})) {
            my $installdate = _dateFormat(_keyLastWriteDateString($data));
            $software->{INSTALLDATE} = $installdate if $installdate;
        }

        #----- SQL Server -----
        # Versions >= SQL Server 2008 (tested with 2008/R2/2012/2016) : "SQL Server xxxx Database Engine Services"
        if ($software->{NAME} =~ /^(SQL Server.*)(\sDatabase Engine Services)/) {
            my $sqlEditionValue = _getSqlEdition(
                softwareversion => $software->{VERSION}
            );
            if ($sqlEditionValue) {
                $software->{NAME} = $1." ".$sqlEditionValue.$2;
            }
        # Versions = SQL Server 2005 : "Microsoft SQL Server xxxx"
        # "Uninstall" registry key does not contains Version : use default named instance.
        } elsif ($software->{NAME} =~ /^(Microsoft SQL Server 200[0-9])$/ and defined($software->{VERSION})) {
            my $sqlEditionValue = _getSqlEdition(
                softwareversion => $software->{VERSION}
            );
            if ($sqlEditionValue) {
                $software->{NAME} = $1." ".$sqlEditionValue;
            }
        }
        #----------

        push @list, $software;
    }

    # It's better to return ref here as the array can be really large
    return \@list;
}

sub _getHotfixesList {
    my (%params) = @_;

    my $list;

    foreach my $object (getWMIObjects(
        class      => 'Win32_QuickFixEngineering',
        properties => [ qw/HotFixID Description InstalledOn/  ]
    )) {

        my $releaseType;
        if ($object->{Description} && $object->{Description} =~ /^(Security Update|Hotfix|Update)/) {
            $releaseType = $1;
        }
        my $systemCategory = !$releaseType       ? CATEGORY_UPDATE :
            ($releaseType =~ /^Security Update/) ? CATEGORY_SECURITY_UPDATE :
            $releaseType =~ /^Hotfix/            ? CATEGORY_HOTFIX :
                                                   CATEGORY_UPDATE ;

        next unless $object->{HotFixID} =~ /KB(\d{4,10})/i;
        push @$list, {
            NAME         => $object->{HotFixID},
            COMMENTS     => $object->{Description},
            INSTALLDATE  => _dateFormat($object->{InstalledOn}),
            FROM         => "WMI",
            RELEASE_TYPE => $releaseType,
            ARCH         => $params{is64bit} ? 'x86_64' : 'i586',
            SYSTEM_CATEGORY => $systemCategory
        };

    }

    return $list;
}

sub _addSoftware {
    my (%params) = @_;

    my $entry = $params{entry};

    # avoid duplicates
    return if $seen->{$entry->{NAME}}->{$entry->{ARCH}}{$entry->{VERSION} || '_undef_'}++;

    $params{inventory}->addEntry(section => 'SOFTWARES', entry => $entry);
}

sub _processMSIE {
    my (%params) = @_;

    my $name = $params{is64bit} ?
        "Internet Explorer (64bit)" : "Internet Explorer";

    my $path = is64bit() && !$params{is64bit} ?
        "HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/Microsoft/Internet Explorer" :
        "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Internet Explorer";

    # Will use key last write date as INSTALLDATE, but it only works when run locally
    my $installedkey = getRegistryKey(
        path        => $path,
        # Important for remote inventory optimization
        required    => [ qw/svcVersion Version/ ],
        maxdepth    => 0,
    );

    my $version = $installedkey->{"/svcVersion"} || $installedkey->{"/Version"};

    return unless $version; # Not installed

    _addSoftware(
        inventory => $params{inventory},
        entry     => {
            FROM        => "registry",
            ARCH        => $params{is64bit} ? 'x86_64' : 'i586',
            NAME        => $name,
            VERSION     => $version,
            PUBLISHER   => "Microsoft Corporation",
            INSTALLDATE => _dateFormat(_keyLastWriteDateString($installedkey))
        }
    );
}

# List of SQL Instances
sub _getSqlEdition {
    my (%params) = @_;

    my $softwareVersion = $params{softwareversion};

    # Registry access for SQL Instances
    my $sqlinstancesList = getRegistryKey(
        path => "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Microsoft SQL Server/Instance Names/SQL"
    );
    return unless $sqlinstancesList;

    # List of SQL Instances
    my $sqlinstanceEditionValue;
    foreach my $sqlinstanceName (keys %$sqlinstancesList) {
        my $sqlinstanceValue = $sqlinstancesList->{$sqlinstanceName};
        # Get version and edition for each instance
        $sqlinstanceEditionValue = _getSqlInstancesVersions(
            SOFTVERSION => $softwareVersion,
            VALUE       => $sqlinstanceValue
        );
        last if $sqlinstanceEditionValue;
    }
    return $sqlinstanceEditionValue;
}

# SQL Instances versions
# Return version and edition for each instance
sub _getSqlInstancesVersions {
    my (%params) = @_;

    my $softwareVersion  = $params{SOFTVERSION};
    my $sqlinstanceValue = $params{VALUE};

    my $sqlinstanceVersions = getRegistryKey(
        path => "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Microsoft SQL Server/" . $sqlinstanceValue . "/Setup",
        # Important for remote inventory optimization
        required    => [ qw/Version Edition/ ],
    );
    return unless ($sqlinstanceVersions && $sqlinstanceVersions->{'/Version'});

    return unless $sqlinstanceVersions->{'/Version'} eq $softwareVersion;

    # If software version match instance one
    return $sqlinstanceVersions->{'/Edition'};
}

my $appxscript = _appxscript();
sub _appxscript {
    return $appxscript if $appxscript;
    # Compress appx powershell script as much as possible as we are limited to ~ 8000 characters
    my $script = '';
    foreach my $line (<DATA>) {
        $line =~ s/^\s+//;
        next if length($line) == 0 || $line =~ /^#/;
        $script .= $line;
    }
    close(DATA);
    return $script;
}

sub _getAppxPackages {
    my (%params) = @_;

    return unless canRun('powershell');

    my $logger = $params{logger};
    my @lines  = runPowerShell(
        script  => $appxscript,
        file    => $params{file}, # for tests
        logger  => $logger
    );

    my $list = [];
    my $package = {
        FROM    => 'uwp'
    };

    foreach my $line (@lines) {

        # Add package on empty line
        if (!$line && $package->{NAME}) {
            push @{$list}, $package;
            $package = { FROM => 'uwp' };
            next;
        }

        my ($key, $value) = $line =~ /^([A-Z_]+):\s*(.*)\s*$/;
        next unless $key && defined($value) && length($value);

        # Cleanup
        if ($key eq 'NAME') {
            $value = _canonicalPackageName($value);
        } elsif ($key eq 'INSTALLDATE') {
            my ($date) = $value =~ m|^([0-9/]+)|;
            my $installdate = _dateFormat($date);
            $value = $installdate if $installdate;
        }

        $package->{$key} = $value;
    }

    # Add last package if still not added
    push @{$list}, $package if $package->{NAME};

    $logger->debug2("Found ".scalar(@{$list})." uwp packages") if $logger;

    # Extract publishers
    my $publishers = _parsePackagePublishers($list);

    # Fix publisher if necessary
    foreach my $package (@{$list}) {
        my $pubid = delete $package->{PUBID}
            or next;
        $package->{PUBLISHER} = $publishers->{$pubid}
            if $publishers->{$pubid};
    }

    return $list;
}

sub _canonicalPackageName {
    my ($name) = @_;
    # Fix up name for well-know cases if the case display name is missing
    if ($name =~ /^(Microsoft|windows)\./i) {
        $name =~ s/([^0-9])\./$1 /g;
    }
    return $name;
}

sub _parsePackagePublishers {
    my $list = shift(@_);

    my %publishers = qw(
        tf1gferkr813w       AutoDesk
    );

    foreach my $package (@{$list}) {
        my $publisher = $package->{PUBLISHER}
            or next;
        my $pubid     = $package->{PUBID}
            or next;
        next if $publishers{$pubid};
        $publishers{$pubid} = $publisher;
    }

    return \%publishers;
}

1;

__DATA__
# Script PowerShell
[Windows.Management.Deployment.PackageManager,Windows.Management.Deployment,ContentType=WindowsRuntime] >$null

# Setup encoding to UTF-8
$PreviousEncoding = [console]::OutputEncoding
$OutputEncoding   = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

# $CSharpSHLoadIndirectString code from https://github.com/skycommand/AdminScripts/blob/master/AppX/Inventory%20AppX%20Packages.ps1
$CSharpSHLoadIndirectString = @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public class IndirectStrings
{
    [DllImport("shlwapi.dll", BestFitMapping = false, CharSet = CharSet.Unicode, ExactSpelling = true, SetLastError = false, ThrowOnUnmappableChar = true)]
    internal static extern int SHLoadIndirectString(string pszSource, StringBuilder pszOutBuf, uint cchOutBuf, IntPtr ppvReserved);

    public static string GetIndirectString(string indirectString)
    {
        StringBuilder lptStr = new StringBuilder(1024);
        int returnValue = SHLoadIndirectString(indirectString, lptStr, (uint)lptStr.Capacity, IntPtr.Zero);

        return returnValue == 0 ? lptStr.ToString() : "";
    }
}
'@

# Add the IndirectStrings type to PowerShell
Add-Type -TypeDefinition $CSharpSHLoadIndirectString -Language CSharp

function canonicalResourceURI {
    param (
        $pkg,
        $res,
        $rec = 10
    )

    # Just a security for recursive call
    if (--$rec -eq 0) { Return "" }

    if ($res -match '^@') {
        $res = [IndirectStrings]::GetIndirectString($res)
        $res = canonicalResourceURI $pkg $res $rec
    } elseif ($res -match '^ms-resource:(?<Path>.*)$') {
        $path = $Matches.Path
        if ($path -match '^//') {
            $res = $path
        } elseif ($path -match '^/') {
            $res = "//$res"
        } elseif ($path -match 'resources') {
            $res = "///$path"
        } else {
            $res = "///resources/$path"
        }
        $res = "?ms-resource:$res"
        $res = canonicalResourceURI $pkg "@{$pkg$res}" $rec
    }
    Return $res
}

function out {
    param ($n, $v)
    if ($v -NotLike "") {
        Write-Host "${n}: $v"
    }
}

$pkgs = New-Object Windows.Management.Deployment.PackageManager

foreach ($pkg in $pkgs.FindPackages()) {
    $id = $pkg.Id
    $fname = $id.FullName

    # Skip package not really installed
    $user = $pkgs.FindUsers($fname) | Where-Object { $_.InstallState -eq "Installed" } | Select-Object -First 1
    if (!$user) { continue }

    $iloc = $pkg.InstalledLocation

    # Use installeddate if available or the installation folder creation date
    $date = $pkg.InstalledDate
    if ($date -Like "") {
        $date = $iloc.DateCreated
    }

    $manifest = Get-AppxPackageManifest -Package $fname -User $user.UserSecurityId

    $prop = $manifest.Package.Properties

    $name = canonicalResourceURI $fname $prop.DisplayName
    if ($name -Like "") {
        $name = $id.Name
    }

    $pub = canonicalResourceURI $fname $prop.PublisherDisplayName
    if ($pub -Like "") {
        $pub = $id.Publisher
    }

    $comments = canonicalResourceURI $fname $prop.Description

    $v = $id.Version
    # Output is indeed compressed while preparing $appxscript during perl module startup
    out "NAME" $name
    out "PUBLISHER" $pub
    out "PUBID" $id.PublisherId
    out "COMMENTS" $comments
    out "ARCH" $id.Architecture.ToString().ToLowerInvariant()
    out "VERSION" "$($v.Major).$($v.Minor).$($v.Build).$($v.Revision)"
    out "FOLDER" $iloc.Path
    out "INSTALLDATE" $date
    out "SYSTEM_CATEGORY" $pkg.SignatureKind.ToString().ToLowerInvariant()
    Write-Host
}

# Restore encoding
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = $PreviousEncoding
