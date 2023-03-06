package GLPI::Agent::Task::Inventory::Win32::AntiVirus;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use UNIVERSAL::require;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Win32;

use constant    category    => "antivirus";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};
    my $seen;

    # Doesn't works on Win2003 Server
    # On Win7, we need to use SecurityCenter2
    foreach my $instance (qw/SecurityCenter SecurityCenter2/) {
        my $moniker = "winmgmts:{impersonationLevel=impersonate,(security)}!//./root/$instance";

        foreach my $object (getWMIObjects(
                moniker    => $moniker,
                class      => "AntiVirusProduct",
                properties => [ qw/
                    companyName displayName instanceGuid onAccessScanningEnabled
                    productUptoDate versionNumber productState
               / ]
        )) {
            next unless $object;

            my $antivirus = {
                COMPANY  => $object->{companyName},
                NAME     => $object->{displayName},
                GUID     => $object->{instanceGuid},
                VERSION  => $object->{versionNumber},
                ENABLED  => $object->{onAccessScanningEnabled},
                UPTODATE => $object->{productUptoDate}
            };

            if ($object->{productState}) {
                my $hex = dec2hex($object->{productState});
                $logger->debug("Found $antivirus->{NAME} (state=$hex)")
                    if $logger;
                # See http://neophob.com/2010/03/wmi-query-windows-securitycenter2/
                my ($enabled, $uptodate) = $hex =~ /(.{2})(.{2})$/;
                if (defined($enabled) && defined($uptodate)) {
                    $antivirus->{ENABLED}  =  $enabled =~ /^1.$/ ? 1 : 0;
                    $antivirus->{UPTODATE} = $uptodate =~ /^00$/ ? 1 : 0;
                }
            } else {
                $logger->debug("Found $antivirus->{NAME}")
                    if $logger;
            }

            # Also support WMI access to Windows Defender
            if (!$antivirus->{VERSION} && $antivirus->{NAME} =~ /Windows Defender/i) {
                my $defender;
                # Don't try to access Windows Defender class if not enabled as
                # WMI call can fail after a too long time while another antivirus
                # is installed
                if ($antivirus->{ENABLED}) {
                    ($defender) = getWMIObjects(
                        moniker    => 'winmgmts://./root/microsoft/windows/defender',
                        class      => "MSFT_MpComputerStatus",
                        properties => [ qw/AMProductVersion AntivirusEnabled
                            AntivirusSignatureVersion/ ]
                    );
                }
                if ($defender) {
                    $antivirus->{VERSION} = $defender->{AMProductVersion}
                        if $defender->{AMProductVersion};
                    $antivirus->{ENABLED} = 1
                        if defined($defender->{AntivirusEnabled}) && $defender->{AntivirusEnabled} =~ /^1|true$/;
                    $antivirus->{BASE_VERSION} = $defender->{AntivirusSignatureVersion}
                        if $defender->{AntivirusSignatureVersion};
                }
                $antivirus->{COMPANY} = "Microsoft Corporation";
                # Finally try registry for base version
                if (!$antivirus->{BASE_VERSION}) {
                    $defender = _getSoftwareRegistryKeys(
                        'Microsoft/Windows Defender/Signature Updates',
                        [ 'AVSignatureVersion' ]
                    );
                    $antivirus->{BASE_VERSION} = $defender->{'/AVSignatureVersion'}
                        if $defender && $defender->{'/AVSignatureVersion'};
                }
            }

            # Finally try to get version from software installation in registry
            if (!$antivirus->{VERSION} || !$antivirus->{COMPANY}) {
                my $registry = _getAntivirusUninstall($antivirus->{NAME});
                if ($registry) {
                    unless ($antivirus->{VERSION}) {
                        my $version = getRegistryKeyValue($registry, "DisplayVersion");
                        $antivirus->{VERSION} = $version if $version;
                    }
                    unless ($antivirus->{COMPANY}) {
                        my $company = getRegistryKeyValue($registry, "Publisher");
                        $antivirus->{COMPANY} = $company if $company;
                    }
                }
            }

            # avoid duplicates
            next if $seen->{$antivirus->{NAME}}->{$antivirus->{VERSION}||'_undef_'}++;

            # Check for other product datas for update
            if ($antivirus->{NAME} =~ /McAfee/i) {
                _setMcAfeeInfos($antivirus);
            } elsif ($antivirus->{NAME} =~ /Kaspersky/i) {
                _setKasperskyInfos($antivirus);
            } elsif ($antivirus->{NAME} =~ /ESET/i) {
                _setESETInfos($antivirus);
            } elsif ($antivirus->{NAME} =~ /Avira/i) {
                _setAviraInfos($antivirus);
            } elsif ($antivirus->{NAME} =~ /Security Essentials/i) {
                _setMSEssentialsInfos($antivirus);
            } elsif ($antivirus->{NAME} =~ /F-Secure/i) {
                _setFSecureInfos($antivirus);
            } elsif ($antivirus->{NAME} =~ /Bitdefender/i) {
                _setBitdefenderInfos($antivirus,$logger);
            } elsif ($antivirus->{NAME} =~ /Norton|Symantec/i) {
                _setNortonInfos($antivirus);
            } elsif ($antivirus->{NAME} =~ /Trend Micro Security Agent/i) {
                _setTrendMicroSecurityAgentInfos($antivirus);
            }

            $inventory->addEntry(
                section => 'ANTIVIRUS',
                entry   => $antivirus
            );

            $logger->debug2("Added $antivirus->{NAME}".($antivirus->{VERSION}? " v$antivirus->{VERSION}":""))
                if $logger;
        }
    }
}

sub _getAntivirusUninstall {
    my ($name) = @_;

    return unless $name;

    # Cleanup name from localized chars to keep a clean regex pattern
    my ($pattern) = $name =~ /^([a-zA-Z0-9 ._-]+)/
        or return;
    # Escape dot in pattern
    $pattern =~ s/\./\\./g;
    my $match = qr/^$pattern/i;

    return _getSoftwareRegistryKeys(
        'Microsoft/Windows/CurrentVersion/Uninstall',
        [ 'DisplayName', 'DisplayVersion', 'Publisher' ],
        sub {
            my ($registry) = @_;
            return first {
                $_->{"/DisplayName"} && $_->{"/DisplayName"} =~ $match;
            } grep { ref($_) } values(%{$registry});
        }
    );
}

sub _setMcAfeeInfos {
    my ($antivirus) = @_;

    my %properties = (
        BASE_VERSION    => [ qw(AVDatVersion    AVDatVersionMinor) ],
    );

    my $regvalues = [ map { @{$_} } values(%properties) ];

    my $macafeeReg = _getSoftwareRegistryKeys('McAfee/AVEngine', $regvalues)
        or return;

    # major.minor versions properties
    foreach my $property (keys %properties) {
        my $keys = $properties{$property};
        my $major = $macafeeReg->{'/' . $keys->[0]};
        my $minor = $macafeeReg->{'/' . $keys->[1]};
        $antivirus->{$property} = sprintf("%04d.%04d", hex2dec($major), hex2dec($minor))
            if defined $major && defined $minor;
    }
}

sub _setKasperskyInfos {
    my ($antivirus) = @_;

    my $regvalues = [ qw(LastSuccessfulUpdate LicKeyType LicDaysTillExpiration) ];

    my $kasperskyReg = _getSoftwareRegistryKeys('KasperskyLab/protected', $regvalues)
        or return;

    my $found = first {
        $_->{"Data/"} && $_->{"Data/"}->{"/LastSuccessfulUpdate"}
    } values(%{$kasperskyReg});

    if ($found) {
        my $lastupdate = hex2dec($found->{"Data/"}->{"/LastSuccessfulUpdate"});
        if ($lastupdate && $lastupdate != 0xFFFFFFFF) {
            my @date = localtime($lastupdate);
            # Format BASE_VERSION as YYYYMMDD
            $antivirus->{BASE_VERSION} = sprintf(
                "%04d%02d%02d",$date[5]+1900,$date[4]+1,$date[3]);
        }
        # Set expiration date only if we found a licence key type
        my $keytype = hex2dec($found->{"Data/"}->{"/LicKeyType"});
        if ($keytype) {
            my $expiration = hex2dec($found->{"Data/"}->{"/LicDaysTillExpiration"});
            if (defined($expiration)) {
                my @date = localtime(time+86400*$expiration);
                $antivirus->{EXPIRATION} = sprintf(
                    "%02d/%02d/%04d",$date[3],$date[4]+1,$date[5]+1900);
            }
        }
    }
}

sub _setESETInfos {
    my ($antivirus) = @_;

    my $esetReg = _getSoftwareRegistryKeys(
        'ESET/ESET Security/CurrentVersion/Info',
        [ qw(ProductVersion ScannerVersion ProductName AppDataDir) ]
    );
    return unless $esetReg;

    unless ($antivirus->{VERSION}) {
        $antivirus->{VERSION} = $esetReg->{"/ProductVersion"}
            if $esetReg->{"/ProductVersion"};
    }

    $antivirus->{BASE_VERSION} = $esetReg->{"/ScannerVersion"}
        if $esetReg->{"/ScannerVersion"};
    $antivirus->{NAME} = $esetReg->{"/ProductName"}
        if $esetReg->{"/ProductName"};

    # Look at license file
    if ($esetReg->{"/AppDataDir"} && has_folder($esetReg->{"/AppDataDir"}.'/License')) {
        my $license = $esetReg->{"/AppDataDir"}.'/License/license.lf';
        my @content = getAllLines( file => $license );
        my $string = join('', map { getSanitizedString($_) } @content);
        # License.lf file seems to be a signed UTF-16 XML. As getSanitizedString()
        # calls should have transform UTF-16 as UTF-8, we should extract
        # wanted node and parse it as XML
        my ($xml) = $string =~ /(<ESET\s.*<\/ESET>)/;
        if ($xml) {
            my $expiration;
            eval {
                GLPI::Agent::XML->require();
                my $tree = GLPI::Agent::XML->new(string => $xml)->dump_as_hash();
                $expiration = $tree->{ESET}->{PRODUCT_LICENSE_FILE}->{LICENSE}->{ACTIVE_PRODUCT}->{-EXPIRATION_DATE};
            };
            # Extracted expiration is like: 2018-11-17T12:00:00Z
            if ($expiration && $expiration =~ /^(\d{4})-(\d{2})-(\d{2})T/) {
                $antivirus->{EXPIRATION} = sprintf("%02d/%02d/%04d",$3,$2,$1);
            }
        }
    }
}

sub _setAviraInfos {
    my ($antivirus) = @_;

    my ($aviraInfos) = getWMIObjects(
        moniker    => 'winmgmts://./root/CIMV2/Applications/Avira_AntiVir',
        class      => "License_Info",
        properties => [ qw/License_Expiration/ ]
    );
    if($aviraInfos && $aviraInfos->{License_Expiration}) {
        my ($expiration) = $aviraInfos->{License_Expiration} =~ /^(\d+\.\d+\.\d+)/;
        if ($expiration) {
            $expiration =~ s/\./\//g;
            $antivirus->{EXPIRATION} = $expiration;
        }
    }

    my $aviraReg = _getSoftwareRegistryKeys(
        'Avira/Antivirus',
        [ qw(VdfVersion) ]
    );
    return unless $aviraReg;

    $antivirus->{BASE_VERSION} = $aviraReg->{"/VdfVersion"}
        if $aviraReg->{"/VdfVersion"};
}

sub _setMSEssentialsInfos {
    my ($antivirus) = @_;

    my $mseReg = _getSoftwareRegistryKeys(
        'Microsoft/Microsoft Antimalware/Signature Updates',
        [ 'AVSignatureVersion' ]
    );
    return unless $mseReg;

    $antivirus->{BASE_VERSION} = $mseReg->{"/AVSignatureVersion"}
        if $mseReg->{"/AVSignatureVersion"};
}

sub _setFSecureInfos {
    my ($antivirus) = @_;

    my $fsecReg = _getSoftwareRegistryKeys(
        'F-Secure/Ultralight/Updates/aquarius',
        [ qw(file_set_visible_version) ]
    );
    return unless $fsecReg;

    my $found = first { $_->{"/file_set_visible_version"} } values(%{$fsecReg});

    $antivirus->{BASE_VERSION} = $found->{"/file_set_visible_version"}
        if $found->{"/file_set_visible_version"};

    # Try to find license "expiry_date" from a specific json file
    $fsecReg = _getSoftwareRegistryKeys(
        'F-Secure/CCF/DLLHoster/100/Plugins/CosmosService',
        [ qw(DataPath) ]
    );
    return unless $fsecReg;

    my $path = $fsecReg->{"/DataPath"};
    return unless $path && has_folder($path);

    # This is the full path for the expected json file
    $path .= "\\safe.S-1-5-18.local.cosmos";
    return unless has_file($path);

    my $infos = getAllLines(file => $path);
    return unless $infos;

    JSON::PP->require();
    my @licenses;
    eval {
        $infos = JSON::PP::decode_json($infos);
        @licenses = @{$infos->{local}->{windows}->{secl}->{subscription}->{license_table}};
    };
    return unless @licenses;

    my $expiry_date;
    # In the case more than one license is found, assume we need the one with appid=2
    foreach my $license (@licenses) {
        $expiry_date = $license->{expiry_date}
            if $license->{expiry_date};
        last if $expiry_date && $license->{appid} && $license->{appid} == 2;
    }
    return unless $expiry_date;

    my @date = localtime($expiry_date);
    $antivirus->{EXPIRATION} = sprintf("%02d/%02d/%04d",$date[3],$date[4]+1,$date[5]+1900);
}

sub _setBitdefenderInfos {
    my ($antivirus) = @_;

    my $bitdefenderReg = _getSoftwareRegistryKeys(
        'BitDefender/About',
        [ qw(ProductName ProductVersion) ]
    );

    return unless $bitdefenderReg;

    $antivirus->{VERSION} = $bitdefenderReg->{"/ProductVersion"}
        if $bitdefenderReg->{"/ProductVersion"};
    $antivirus->{NAME} = $bitdefenderReg->{"/ProductName"}
        if $bitdefenderReg->{"/ProductName"};

    my $path = _getSoftwareRegistryKeys(
        'BitDefender',
        [ 'Bitdefender Scan Server' ],
        sub { $_[0]->{"/Bitdefender Scan Server"} }
    );
    if ($path && has_folder($path)) {
        my $handle = getDirectoryHandle( directory => $path );
        if ($handle) {
            my ($major,$minor) = (0,0);
            while (my $entry = readdir($handle)) {
                next unless $entry =~ /Antivirus_(\d+)_(\d+)/;
                next unless (has_folder("$path/$entry/Plugins") && has_file("$path/$entry/Plugins/update.txt"));
                next if ($1 < $major || ($1 == $major && $2 < $minor));
                ($major,$minor) = ($1, $2);
                my %update = map { /^([^:]+):\s*(.*)$/ }
                    getAllLines(file => "$path/$entry/Plugins/update.txt");
                $antivirus->{BASE_VERSION} = $update{"Signature number"}
                    if $update{"Signature number"};
            }
        }
    }

    my $surveydata = _getSoftwareRegistryKeys(
        'BitDefender/Install',
        [ 'SurveyDataInfo' ],
        sub { $_[0]->{"/SurveyDataInfo"} }
    );
    if ($surveydata) {
        JSON::PP->require();
        my $datas;
        eval {
            $datas = JSON::PP::decode_json($surveydata);
        };
        if (defined($datas->{days_left})) {
            my @date = localtime(time+86400*$datas->{days_left});
            $antivirus->{EXPIRATION} = sprintf("%02d/%02d/%04d",$date[3],$date[4]+1,$date[5]+1900);
        }
    }
}

sub _setNortonInfos {
    my ($antivirus) = @_;

    # ref: https://support.symantec.com/en_US/article.TECH251363.html
    my $nortonReg = _getSoftwareRegistryKeys(
        'Norton/{0C55C096-0F1D-4F28-AAA2-85EF591126E7}',
        [ qw(PRODUCTVERSION) ]
    );
    if ($nortonReg && $nortonReg->{PRODUCTVERSION}) {
        $antivirus->{VERSION} = $nortonReg->{PRODUCTVERSION};
    }

    # Lookup for BASE_VERSION as CurDefs in definfo.dat insome places
    # See also https://support.symantec.com/en_US/article.TECH237037.html
    my @datadirs = (
        'C:/ProgramData/Symantec/Symantec Endpoint Protection/CurrentVersion/Data',
        'C:/Documents and Settings/All Users/Application Data/Symantec/Symantec Endpoint Protection/CurrentVersion/Data',
    );

    $nortonReg = _getSoftwareRegistryKeys(
        'Norton/{0C55C096-0F1D-4F28-AAA2-85EF591126E7}/Common Client/PathExpansionMap',
        [ qw(DATADIR) ]
    );
    if ($nortonReg && $nortonReg->{DATADIR}) {
        $nortonReg->{DATADIR} =~ s|\\|/|g;
        unshift @datadirs, $nortonReg->{DATADIR}
            if has_folder($nortonReg->{DATADIR});
    }

    # Extract BASE_VERSION from the first found valid definfo.dat file
    foreach my $datadir (@datadirs) {
        my ($defdir) = grep { has_folder($datadir.'/'.$_) } qw(Definitions/SDSDefs Definitions/VirusDefs);
        next unless $defdir;
        my $definfo = $datadir . '/' . $defdir . "/definfo.dat";
        next unless has_file($definfo);
        my ($curdefs) = grep { /^CurDefs=/ } getAllLines( file => $definfo );
        if ($curdefs && $curdefs =~ /^CurDefs=(.*)$/) {
            $antivirus->{BASE_VERSION} = $1;
            last;
        }
    }
}

sub _setTrendMicroSecurityAgentInfos {
    my ($antivirus) = @_;

    my $SecurityAgentReg = _getSoftwareRegistryKeys(
        'TrendMicro/PC-cillinNTCorp/CurrentVersion/Misc.',
        [ qw(InternalNonCrcPatternVer TmListen_Ver) ]
    );
    if ($SecurityAgentReg) {
        $antivirus->{COMPANY} = "Trend Micro Inc.";
        $antivirus->{VERSION} = $SecurityAgentReg->{TmListen_Ver}
            if $SecurityAgentReg->{TmListen_Ver};
        if ($SecurityAgentReg->{InternalNonCrcPatternVer}) {
            my $version = hex($SecurityAgentReg->{InternalNonCrcPatternVer});
            my ($major, $minor, $rev) = (
                $version/100000,
                $version%100000/100,
                $version%100
            );
            $antivirus->{BASE_VERSION} = sprintf("%d.%03d.%02d", $major, $minor, $rev)
                if $major;
        }
    }
}

sub _getSoftwareRegistryKeys {
    my ($base, $values, $callback) = @_;

    my $reg;
    if (is64bit()) {
        $reg = getRegistryKey(
            path => 'HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/'.$base,
            # Important for remote inventory optimization
            required    => $values,
        );
        if ($reg) {
            if ($callback) {
                my $filter = &{$callback}($reg);
                return $filter if $filter;
            } else {
                return $reg;
            }
        }
    }

    $reg = getRegistryKey(
        path => 'HKEY_LOCAL_MACHINE/SOFTWARE/'.$base,
        # Important for remote inventory optimization
        required    => $values,
    );
    return ($callback && $reg) ? &{$callback}($reg) : $reg;
}

1;
