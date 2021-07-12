package FusionInventory::Agent::Task::Inventory::Win32::Softwares;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use File::Basename;
use File::Temp;
use UNIVERSAL::require;
use Encode qw(decode);

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Win32;
use FusionInventory::Agent::Tools::Win32::Constants;
use FusionInventory::Agent::Tools::Win32::LoadIndirectString;

use constant    category    => "software";

our $runAfter = ["FusionInventory::Agent::Task::Inventory::Win32::Hardware"];

my $seen = {};

sub isEnabled {
    return 1;
}

sub isEnabledForRemote {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};
    my $remotewmi = $inventory->getRemote();

    my $is64bit = is64bit();

    my $softwares64 = _getSoftwaresList( is64bit => $is64bit ) || [];
    foreach my $software (@$softwares64) {
        _addSoftware(inventory => $inventory, entry => $software);
    }

    _processMSIE(
        inventory => $inventory,
        is64bit   => $is64bit
    );

    if ($params{scan_profiles}) {
        _loadUserSoftware(
            inventory => $inventory,
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
            is64bit   => 0,
            logger    => $logger
        ) if $params{scan_profiles};
    }

    my $hotfixes = _getHotfixesList(is64bit => $is64bit);
    foreach my $hotfix (@$hotfixes) {
        # skip fixes already found in generic software list,
        # without checking version information
        next if $seen->{$hotfix->{NAME}};
        _addSoftware(inventory => $inventory, entry => $hotfix);
    }

    # Lookup for UWP/Windows Store packages (not supported by WMI task)
    my ($osversion) = $inventory->getHardware('OSVERSION') =~ /^(\d+\.\d+)/;
    if (!$remotewmi && $osversion && $osversion > 6.1) {
        my $packages = _getAppxPackages( logger => $logger ) || [];
        foreach my $package (@{$packages}) {
            _addSoftware(inventory => $inventory, entry => $package);
        }
    }

    # Reset seen hash so we can see softwares in later same run inventory
    $seen = {};
}

sub _loadUserSoftware {
    my (%params) = @_;

    my $userList = _getUsersFromRegistry(%params);
    return unless $userList;

    my $inventory = $params{inventory};
    my $is64bit   = $params{is64bit};
    my $logger    = $params{logger};

    foreach my $profileName (keys %$userList) {
        my $userName = $userList->{$profileName}
            or next;

        my $profileSoft = "HKEY_USERS/$profileName/SOFTWARE/";
        $profileSoft .= is64bit() && !$is64bit ?
                "Wow6432Node/Microsoft/Windows/CurrentVersion/Uninstall" :
                "Microsoft/Windows/CurrentVersion/Uninstall";

        my $softwares = _getSoftwaresList(
            path      => $profileSoft,
            is64bit   => $is64bit,
            userid    => $profileName,
            username  => $userName
        ) || [];
        next unless @$softwares;
        my $nbUsers = scalar(@$softwares);
        $logger->debug2('_loadUserSoftwareFromHKey_Users() : add of ' . $nbUsers . ' softwares in inventory');
        foreach my $software (@$softwares) {
            _addSoftware(inventory => $inventory, entry => $software);
        }
    }
}

sub _getUsersFromRegistry {
    my (%params) = @_;

    my $profileList = getRegistryKey(
        path => 'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows NT/CurrentVersion/ProfileList',
        wmiopts => { # Only used for remote WMI optimization
            values  => [ qw/ProfileImagePath Sid/ ],
        }
    );

    next unless $profileList;

    my $userList;
    foreach my $profileName (keys %$profileList) {
        next unless $profileName =~ m{/$};
        next unless length($profileName) > 10;

        my $profilePath = $profileList->{$profileName}{'/ProfileImagePath'};
        my $sid = $profileList->{$profileName}{'/Sid'};
        next unless $sid;
        next unless $profilePath;
        my $user = basename($profilePath);
        $profileName =~ s|/$||;
        $userList->{$profileName} = $user;
    }

    return $userList;
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

    return unless ($OSNAME eq 'MSWin32');

    return unless (ref($key) eq "Win32::TieRegistry");

    my @lastWrite = FileTimeToSystemTime($key->Information("LastWrite"));

    return unless (@lastWrite > 3);

    return sprintf("%04s%02s%02s",$lastWrite[0],$lastWrite[1],$lastWrite[3]);
}

sub _getSoftwaresList {
    my (%params) = @_;

    my $softwares = getRegistryKey(
        path    => "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall",
        wmiopts => { # Only used for remote WMI optimization
            values  => [ qw/
                DisplayName Comments HelpLink ReleaseType DisplayVersion
                Publisher URLInfoAbout UninstallString InstallDate MinorVersion
                MajorVersion NoRemove SystemComponent
                / ]
        },
        %params
    );

    my @list;

    return unless $softwares;

    foreach my $rawGuid (keys %$softwares) {
        # skip variables
        next if $rawGuid =~ m{^/};

        # only keep subkeys with more than 1 value
        my $data = $softwares->{$rawGuid};
        next unless keys %$data > 1;

        my $guid = $rawGuid;
        $guid =~ s/\/$//; # drop the tailing /

        my $software = {
            FROM             => "registry",
            NAME             => encodeFromRegistry($data->{'/DisplayName'}) ||
                                encodeFromRegistry($guid), # folder name
            COMMENTS         => encodeFromRegistry($data->{'/Comments'}),
            HELPLINK         => encodeFromRegistry($data->{'/HelpLink'}),
            RELEASE_TYPE     => encodeFromRegistry($data->{'/ReleaseType'}),
            VERSION          => encodeFromRegistry($data->{'/DisplayVersion'}),
            PUBLISHER        => encodeFromRegistry($data->{'/Publisher'}),
            URL_INFO_ABOUT   => encodeFromRegistry($data->{'/URLInfoAbout'}),
            UNINSTALL_STRING => encodeFromRegistry($data->{'/UninstallString'}),
            INSTALLDATE      => _dateFormat($data->{'/InstallDate'}),
            VERSION_MINOR    => hex2dec($data->{'/MinorVersion'}),
            VERSION_MAJOR    => hex2dec($data->{'/MajorVersion'}),
            NO_REMOVE        => hex2dec($data->{'/NoRemove'}),
            ARCH             => $params{is64bit} ? 'x86_64' : 'i586',
            GUID             => $guid,
            USERNAME         => $params{username},
            USERID           => $params{userid},
            SYSTEM_CATEGORY  => $data->{'/SystemComponent'} && hex2dec($data->{'/SystemComponent'}) ?
                CATEGORY_SYSTEM_COMPONENT : CATEGORY_APPLICATION
        };

        # Workaround for #415
        $software->{VERSION} =~ s/[\000-\037].*// if $software->{VERSION};

        # Set install date to last registry key update time
        if (!defined($software->{INSTALLDATE})) {
            $software->{INSTALLDATE} = _dateFormat(_keyLastWriteDateString($data));
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

    # Will use key last write date as INSTALLDATE
    my $installedkey = getRegistryKey(
        path   => is64bit() && !$params{is64bit} ?
            "HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/Microsoft/Internet Explorer" :
            "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Internet Explorer",
        wmiopts => { # Only used for remote WMI optimization
            values  => [ qw/svcVersion Version/ ],
            subkeys => 0
        }
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
        path => "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Microsoft SQL Server/" . $sqlinstanceValue . "/Setup"
    );
    return unless ($sqlinstanceVersions && $sqlinstanceVersions->{'/Version'});

    return unless $sqlinstanceVersions->{'/Version'} eq $softwareVersion;

    # If software version match instance one
    return $sqlinstanceVersions->{'/Edition'};
}

sub _getAppxPackages {
    my (%params) = @_;

    return unless canRun('powershell');

    XML::XPath->require();

    # Don't validate XML against DTD, parsing may fail if a proxy is active
    $XML::XPath::ParseParamEnt = 0;

    my $logger    = $params{logger};

    my @lines;
    {
        # Temp file will be deleted out of this scope
        my $fh = File::Temp->new(
            TEMPLATE    => 'get-appxpackage-XXXXXX',
            SUFFIX      => '.ps1'
        );
        print $fh <DATA>;
        close($fh);
        my $file = $fh->filename;

        return unless ($file && -f $file);

        @lines = getAllLines(
            command => "powershell -NonInteractive -ExecutionPolicy ByPass -File $file",
            %params
        );
    }

    my ($list, $package);
    my %manifest_mapping = qw(
        DisplayName             DISPLAYNAME
        Description             COMMENTS
        PublisherDisplayName    PUBLISHERDISPLAYNAME
    );

    foreach my $line (@lines) {
        chomp($line);

        # Add package on empty line
        if (!$line && $package && $package->{NAME}) {
            push @{$list}, $package;
            undef $package;
            next;
        }

        my ($key, $value) = $line =~ /^([A-Z_]+):\s*(.*)\s*$/;
        next unless ($key && defined($value));
        $package->{$key} = decode('UTF-8', $value);

        # Read manifest
        if ($key eq 'FOLDER' && $value && -d $value) {
            my $xml = $value . '/appxmanifest.xml';
            if (-f $xml) {
                my $xpp = XML::XPath->new(filename => $xml)
                    or next;
                foreach my $property (keys(%manifest_mapping)) {
                    my $key = $manifest_mapping{$property};
                    my $value = $xpp->getNodeText("/Package/Properties/$property")
                        or next;
                    $package->{$key} = $value;
                }
            }
        }
    }

    # Add last package if still not added
    push @{$list}, $package if ($package && $package->{NAME});

    # Extract publishers
    my $publishers = _parsePackagePublishers($list);

    # Cleanup list and fix localized strings
    foreach my $package (@{$list}) {
        my $name  = $package->{NAME};
        my $pubid = delete $package->{PUBLISHERID};
        $package->{PUBLISHER} = $publishers->{$pubid}
            if ($pubid && $publishers->{$pubid});

        if (!$package->{PUBLISHER} && $name =~ /^Microsoft/i) {
            $package->{PUBLISHER} = "Microsoft Corp.";
        } elsif (!$package->{PUBLISHER}) {
            $logger->debug2("no publisher found for $name package") if $logger;
        }

        my $pkgname = delete $package->{PACKAGE};

        my $installdate = delete $package->{INSTALLDATE};
        if ($installdate) {
            my ($date) = $installdate =~ m|^([0-9/]+)|;
            $installdate = _dateFormat($date);
            $package->{INSTALLDATE} = $installdate if $installdate;
        }

        my $dn = delete $package->{DISPLAYNAME};
        if ($dn && $dn =~ /^ms-resource:/) {
            my $res = SHLoadIndirectString(_canonicalResourceURI(
                $pkgname, $package->{FOLDER}, $dn
            ));
            $logger->debug2("$name package name " . ($res ?
                    "resolved to '$res'" : "can't be resolved from '$dn'"))
                if $logger;
            $dn = $res;
        }
        if (!$dn) {
            $dn = _canonicalPackageName($package->{NAME});
        }
        $package->{NAME} = $dn if $dn;

        my $comments = delete $package->{COMMENTS};
        if ($comments && $comments =~ /^ms-resource:/) {
            my $res = SHLoadIndirectString(_canonicalResourceURI(
                $pkgname, $package->{FOLDER}, $comments
            ));
            $logger->debug2("$name package comments " . ($res ?
                    "resolved to '$res'" : "can't be resolved from '$comments'"))
                if $logger;
            $comments = $res;
        }
        $package->{COMMENTS} = $comments if $comments;

        $package->{FROM} = 'uwp';
    }

    return $list;
}

sub _canonicalPackageName {
    my ($name) = @_;
    # Fix up name for well-know cases if the case display name is missing
    if ($name =~ /^Microsoft\.NET\./i) {
        $name =~ s/\./ /g;
        $name =~ s/Microsoft NET/Microsoft .Net/;
    } elsif ($name =~ /^(Microsoft|windows)\./i) {
        $name =~ s/\./ /g;
    }
    return $name;
}

sub _canonicalResourceURI {
    my ($package, $folder, $resource) = @_;
    my $file = $folder.'\resources.pri';
    my $base = -f $file ? $file : $package;
    my ($prefix, $respath) = $resource =~ /^(ms-resource:)(.*)$/
        or return;
    if ($respath =~ m|^//|) {
        # Keep resource as is
    } elsif ($respath =~ m|^/|) {
        $resource = $prefix.'//'.$respath;
    } else {
        $resource = $prefix.'///'.($respath =~ /resources/i ? '':'resources/').$respath;
    }
    return '@{'.$base.'?'.$resource.'}';
}

sub _parsePackagePublishers {
    my $list = shift(@_);

    my %publishers = qw(
        tf1gferkr813w       AutoDesk
    );

    my @localized_publisher_packages = ();

    foreach my $package (@{$list}) {
        my $publisher = delete $package->{PUBLISHERDISPLAYNAME};
        my $pubid     = $package->{PUBLISHERID}
            or next;
        next unless $publisher;
        next if ($publishers{$pubid} && $publishers{$pubid} !~ /^ms-resource:/);
        if ($publisher =~ /^ms-resource:/) {
            push @localized_publisher_packages, $package;
        }
        $publishers{$pubid} = $publisher;
    }

    # Fix publishers with ms-resource:
    foreach my $package (@localized_publisher_packages) {
        my $pubid = $package->{PUBLISHERID}
            or next;
        next if ($publishers{$pubid} && $publishers{$pubid} !~ /^ms-resource:/);
        my $string = SHLoadIndirectString(_canonicalResourceURI(
            $package->{PACKAGE}, $package->{FOLDER}, $publishers{$pubid}
        ));
        if ($string) {
            $publishers{$pubid} = $string;
        } else {
            delete $publishers{$pubid};
        }
    }

    return \%publishers;
}

1;

__DATA__
# Script PowerShell
[Windows.Management.Deployment.PackageManager,Windows.Management.Deployment,ContentType=WindowsRuntime] >$null

$packages = New-Object Windows.Management.Deployment.PackageManager

foreach ( $package in $packages.FindPackages() )
{
    # Check install state for each user and break if an installation is found
    $state = "Installed"
    foreach ( $user in $packages.FindUsers($package.Id.FullName) )
    {
        $state = $user.InstallState
        if ($user.InstallState -Like "Installed") {
            break
            $p = $packages.FindPackageForUser($user.UserSecurityId, $package.Id.FullName)
            if ($p.InstalledLocation.DateCreated -NotLike "") {
                $installedDate = $p.InstalledLocation.DateCreated
                break
            }
        }
    }
    if ($state -NotLike "Installed") { continue }

    # Use installeddate if found otherwise use installation folder creation date
    $installedDate = ""
    if ($package.InstalledDate -NotLike "") {
        $installedDate = $package.InstalledDate
    } elseif ($package.InstalledLocation.DateCreated -NotLike "") {
        $installedDate = $package.InstalledLocation.DateCreated
    }

    Write-host "NAME: $($package.Id.Name)"
    Write-host "PACKAGE: $($package.Id.FullName)"
    Write-host "ARCH: $($package.Id.Architecture.ToString().ToLowerInvariant())"
    Write-host "VERSION: $($package.Id.Version.Major).$($package.Id.Version.Minor).$($package.Id.Version.Build).$($package.Id.Version.Revision)"
    Write-host "FOLDER: $($package.InstalledLocation.Path)"
    if ($installedDate -NotLike "") {
        Write-host "INSTALLDATE: $($installedDate)"
    }
    Write-host "PUBLISHER: $($package.Id.Publisher)"
    Write-host "PUBLISHERID: $($package.Id.PublisherId)"
    Write-host "SYSTEM_CATEGORY: $($package.SignatureKind.ToString().ToLowerInvariant())"
    Write-Host
}
