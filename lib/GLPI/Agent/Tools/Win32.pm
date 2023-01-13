package GLPI::Agent::Tools::Win32;

use strict;
use warnings;
use parent 'Exporter';
use utf8;

use threads;
use threads 'exit' => 'threads_only';
use threads::shared;

use Thread::Semaphore;

use UNIVERSAL::require();
use MIME::Base64;
use Encode;
use File::Temp;

use constant KEY_WOW64_64 => 0x100;
use constant KEY_WOW64_32 => 0x200;
use constant KEY_READ     => 0x20019;

################################################################################
#### Needed to support this module under other platforms than MSWin32 ##########
#### Needed to support WinRM RemoteInventory task ##############################
################################################################################
BEGIN {
    use English qw(-no_match_vars);
    # Fake Win32 module loading unless under testing with our oab fakes modules
    if ($OSNAME ne 'MSWin32' && ! grep { $_ =~ qr{t/lib/fake/windows} } @INC) {
        $INC{'Win32/Job.pm'} = "-";
        $INC{'Win32/TieRegistry.pm'} = "-";
    }
}

our $Registry;
################################################################################

use Cwd;
use English qw(-no_match_vars);
use File::Temp qw(:seekable tempfile);
use File::Basename qw(basename);
use Win32::Job;
use Win32::TieRegistry (
    Delimiter   => '/',
    ArrayValues => 0,
);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Expiration;
use GLPI::Agent::Tools::Win32::NetAdapter;
use GLPI::Agent::Version;

my $localCodepage;

our @EXPORT = qw(
    is64bit
    KEY_WOW64_64
    KEY_WOW64_32
    getInterfaces
    getRegistryValue
    getRegistryKey
    getRegistryKeyValue
    getWMIObjects
    getLocalCodepage
    runCommand
    runPowerShell
    FileTimeToSystemTime
    getCurrentService
    getAgentMemorySize
    FreeAgentMem
    getFormatedWMIDateTime
    loadUserHive
    cleanupPrivileges
);

my $_is64bits = undef;
sub is64bit {
    # Cache is64bit() result in a private module variable to avoid a lot of wmi
    # calls and as this value won't change during the service/task lifetime
    return $_is64bits if defined($_is64bits);
    return $_is64bits =
        any { $_->{AddressWidth} eq 64 }
        getWMIObjects(
            class => 'Win32_Processor', properties => [ qw/AddressWidth/ ]
        );
}

sub getLocalCodepage {
    if (!$localCodepage) {
        $localCodepage =
            "cp" .
            getRegistryValue(
                path => 'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Nls/CodePage/ACP'
            );
    }

    return $localCodepage;
}

sub getWMIObjects {

    my $remote = $GLPI::Agent::Tools::remote;
    return $remote->getWMIObjects(@_) if $remote;

    my $win32_ole_dependent_api = {
        array => 1,
        funct => '_getWMIObjects',
        args  => \@_
    };

    return _call_win32_ole_dependent_api($win32_ole_dependent_api);
}

sub _getWMIObjects {
    my (%params) = (
        moniker => 'winmgmts:{impersonationLevel=impersonate,(security)}!//./',
        @_
    );

    GLPI::Agent::Logger->require();

    my $logthat = "";
    my $logger  = $params{logger} || GLPI::Agent::Logger->new();

    my $expiration = getExpirationTime();

    my $WMIService = Win32::OLE->GetObject($params{moniker});
    # Support alternate moniker if provided and main failed to open
    if (!defined($WMIService) && $params{altmoniker}) {
        $WMIService = Win32::OLE->GetObject($params{altmoniker});
    }

    return unless (defined($WMIService));

    my $Instances;
    if ($params{query}) {
        $logthat = "$params{query} WMI query";
        $logger->debug2("Doing $logthat") if $logger;
        $Instances = $WMIService->ExecQuery($params{query});
    } else {
        $logthat = "$params{class} class WMI objects";
        $logger->debug2("Looking for $logthat") if $logger;
        $Instances = $WMIService->InstancesOf($params{class});
    }

    return unless $Instances;

    my @objects;
    foreach my $instance ( in $Instances ) {
        my $object;

        if (time >= $expiration) {
            $logger->info("Timeout reached on $logthat") if $logger;
            last;
        }

        # Handle Win32::OLE object method, see _getLoggedUsers() method in
        # GLPI::Agent::Task::Inventory::Win32::Users as example to
        # use or enhance this feature
        if ($params{method}) {
            my @invokes = ( $params{method} );
            my %results = ();

            # Prepare Invoke params for known requested types
            foreach my $name (@{$params{params}}) {
                my ($type, $default) = @{$params{$name}}
                    or next;
                my $variant;
                if ($type eq 'string') {
                    Win32::OLE::Variant->use(qw/VT_BYREF VT_BSTR/);
                    eval {
                        $variant = VT_BYREF()|VT_BSTR();
                    };
                }
                eval {
                    $results{$name} = Win32::OLE::Variant::Variant($variant, $default);
                };
                push @invokes, $results{$name};
            }

            # Invoke the method saving the result so we can also bind it
            eval {
                $results{$params{method}} = $instance->Invoke(@invokes);
            };

            # Bind results to object to return
            foreach my $name (keys(%{$params{binds}})) {
                next unless (defined($results{$name}));
                my $bind = $params{binds}->{$name};
                eval {
                    $object->{$bind} = $results{$name}->Get();
                };
                if (defined $object->{$bind} && !ref($object->{$bind})) {
                    utf8::upgrade($object->{$bind});
                }
            }
        }
        foreach my $property (@{$params{properties}}) {
            if (defined $instance->{$property} && !ref($instance->{$property})) {
                # string value
                $object->{$property} = $instance->{$property};
                # despite CP_UTF8 usage, Win32::OLE downgrades string to native
                # encoding, if possible, ie all characters have code <= 0x00FF:
                # http://code.activestate.com/lists/perl-win32-users/Win32::OLE::CP_UTF8/
                utf8::upgrade($object->{$property});
            } elsif (defined $instance->{$property}) {
                # list value
                $object->{$property} = $instance->{$property};
            } else {
                $object->{$property} = undef;
            }
        }
        push @objects, $object;
    }

    return @objects;
}

sub getRegistryValue {
    my (%params) = @_;

    if (!$params{path}) {
        $params{logger}->error(
            "No registry value path provided"
        ) if $params{logger};
        return;
    }

    my $remote = $GLPI::Agent::Tools::remote;
    return $remote->getRemoteRegistryValue(%params) if $remote;

    my ($root, $keyName, $valueName);
    if ($params{path} =~ m{^(HKEY_\w+.*)/([^/]+)/([^/]+)} ) {
        $root      = $1;
        $keyName   = $2;
        $valueName = $3;
    } else {
        $params{logger}->error(
            "Failed to parse '$params{path}'. Does it start with HKEY_?"
        ) if $params{logger};
        return;
    }

    # Handle differently paths including /**/ pattern
    if ($root =~ m/\/\*\*(?:\/.*|)$/ || $keyName eq '**') {
        return _getRegistryDynamic(
            logger    => $params{logger},
            path      => "$root/$keyName",
            valueName => $valueName,
            withtype  => $params{withtype}
        );
    }

    my $key = _getRegistryKey(
        logger  => $params{logger},
        root    => $root,
        keyName => $keyName
    );

    return unless (defined($key));

    if ($valueName eq '*') {
        my %ret;
        foreach (grep { m|^/| } keys %$key) {
            s{^/}{};
            $ret{$_} = getRegistryKeyValue($key, $_, $params{withtype});
        }
        return \%ret;
    } else {
        return getRegistryKeyValue($key, $valueName, $params{withtype});
    }
}

sub getRegistryKeyValue {
    my ($key, $valueName, $withType) = @_;

    Win32API::Registry->require()
        # Only really required for tests
        or return $withType ? [ $key->{"/$valueName"}, $key->{"/$valueName"} =~ /^0x/ ? 4 : 1 ] : $key->{"/$valueName"};

    my ($valType, $valData, $dLen) = (0, "", 0);

    my $valueNameW = encode("UTF16-LE", $valueName);

    Win32API::Registry::RegQueryValueExW($key->Handle, $valueNameW, [], $valType, $valData, $dLen)
        # Only really required for tests
        or return $withType ? [ $key->{"/$valueName"}, $key->{"/$valueName"} =~ /^0x/ ? 4 : 1 ] : $key->{"/$valueName"};

    # Only REG_SZ really needs to be handled in our context
    my $value;
    if ($valType eq Win32::TieRegistry::REG_SZ() || $valType eq Win32::TieRegistry::REG_EXPAND_SZ()) {
        substr($valData, -1) = "" if substr($valData,-1) eq "\0";
        $value = decode("UTF16-LE", $valData);
    } elsif ($valType eq Win32::TieRegistry::REG_MULTI_SZ()) {
        substr($valData, -1) = "" if substr($valData,-1) eq "\0";
        $value = [ map { decode("UTF16-LE", $_) } split (/\0/, $valData) ];
    } else {
        $value = $key->{"/$valueName"};
    }

    return $withType ? [ $value, $valType ] : $value;
}

sub _getRegistryValueFromWMI {
    my (%params) = @_;

    my $value = $params{value}
        or return;
    my $registry = _getWMIRegistry()
        or return;

    my ($hKey, $subKey) = $params{key} =~ m{^(HKEY_[^/]+)/(.+)$};
    return unless $hKey && $subKey;

    # subkey path must be win32 conform
    $subKey =~ s|/|\\|g;

    Win32::OLE->use('in');

    Win32API::Registry->require();

    Win32::OLE::Variant->require();
    Win32::OLE::Variant->use(qw/VT_BYREF VT_ARRAY VT_VARIANT/);

    # Using a hashref here is just a convenient way for debugging and keep
    # computed values between evals
    my $ret = {
        path => $subKey
    };

    eval {
        # Get expected hKey valeur from registry constants
        $ret->{hKey} = Win32API::Registry::regConstant($hKey);

        # Uses registry enumeration to list values and their type
        my $type  = VT_BYREF()|VT_ARRAY()|VT_VARIANT();
        my $vars  = Win32::OLE::Variant->new($type,[1,1]);
        my $types = Win32::OLE::Variant->new($type,[1,1]);
        $ret->{err} = $registry->EnumValues($ret->{hKey}, $subKey, $vars, $types);

        # Find expected value in the list and keep its type but skip when
        # no values are found to avoid crashing
        if ($vars->Dim()){
            my @types = in( $types->Copy->Value() );
            foreach my $var ( in( $vars->Copy->Value() ) ) {
                my $type = shift @types;
                next unless $var && $var eq $value;
                $ret->{value} = $var;
                $ret->{type}  = $type;
                last;
            }
        }
    };

    return unless $ret->{err} == 0 && $ret->{value};

    return _getRegistryKeyValueFromWMI(%{$ret});
}

sub getRegistryKey {
    my (%params) = @_;

    my $logger = $params{logger};

    if (!$params{path}) {
        $logger->error("No registry key path provided") if $logger;
        return;
    }

    my ($root, $keyName);
    if ($params{path} =~ m{^(HKEY_\w+.*)/([^/]+)} ) {
        $root      = $1;
        $keyName   = $2;
    } else {
        $logger->error("Failed to parse '$params{path}'. Does it start with HKEY_?")
            if $logger;
        return;
    }

    my $remote = $GLPI::Agent::Tools::remote;
    return $remote->getRemoteRegistryKey(%params) if $remote;

    return _getRegistryKey(
        logger  => $logger,
        root    => $root,
        keyName => $keyName
    );
}

sub _getRegistryRoot {
    my (%params) = @_;

    return unless $Registry;

    ## no critic (ProhibitBitwise)
    my $rootKey = is64bit() ?
        $Registry->Open($params{root}, { Access=> KEY_READ | KEY_WOW64_64 } ) :
        $Registry->Open($params{root}, { Access=> KEY_READ } )                ;

    if (!$rootKey) {
        $params{logger}->error(
            "Can't open $params{root} key: $EXTENDED_OS_ERROR"
        ) if $params{logger};
        return;
    }
    return $rootKey;
}

sub _getRegistryKey {
    my (%params) = @_;

    my $rootKey = _getRegistryRoot(%params)
        or return;

    my $key = $rootKey->Open($params{keyName});

    return $key;
}

sub loadUserHive {
    my (%params) = @_;

    return unless $params{sid} && $params{file} && has_file($params{file});

    my $remote = $GLPI::Agent::Tools::remote;
    return $remote->loadRemoteUserHive(%params) if $remote;

    my $rootKey = _getRegistryRoot(root => 'HKEY_USERS')
        or return;

    # Don't load if still found
    return if $rootKey->Open($params{sid});

    # Get required privilege
    Win32API::Registry::AllowPriv(Win32API::Registry::SE_RESTORE_NAME(), 1)
        or return;

    return $rootKey->Load( $params{file}, $params{sid}, { Access => KEY_READ } );
}

sub cleanupPrivileges {

    # When doing remote inventories, we better need to unload loaded hives
    my $remote = $GLPI::Agent::Tools::remote;
    return $remote->unloadRemoteLoadedUserHives() if $remote;

    # Unset required privilege for Users hive loading
    Win32API::Registry::AllowPriv(Win32API::Registry::SE_RESTORE_NAME(), 0);
}

sub _getRegistryDynamic {
    my (%params) = @_;

    my %ret;
    my $valueName = $params{valueName};

    my @rootparts = split(/\/+\*\*\/+/, $params{path}.'/', 2);
    my $first = shift(@rootparts);
    my $second = shift(@rootparts) || '';
    $first .= '/';
    $second = '/'.$second;
    $second =~ s|/*$||;

    my $rootSub = _getRegistryRoot(
        root    => $first,
        logger  => $params{logger}
    );
    return unless defined($rootSub);

    foreach my $sub ($rootSub->SubKeyNames) {
        if ($second =~ m/\/+\*\*(?:\/.*|)/) {
            my $subret = _getRegistryDynamic(
                logger    => $params{logger},
                path      => $first.$sub.$second,
                valueName => $valueName,
                withtype  => $params{withtype}
            );
            next unless defined($subret);
            my ($subkey) = $second =~ /^([^*]+)\*\*(?:\/.*|)$/;
            foreach my $subretkey (keys %$subret) {
                $ret{$sub.$subkey.$subretkey} = $subret->{$subretkey};
            }
        } else {
            my $key = _getRegistryRoot(
                root    => $first.$sub.$second,
                logger  => $params{logger}
            );
            next unless defined($key);

            if ($valueName eq '*') {
                foreach (grep { m|^/| } keys %$key) {
                    s{^/}{};
                    $ret{$sub.$second."/".$_} = getRegistryKeyValue($key, $_, $params{withtype});
                }
            } elsif (exists($key->{"/$valueName"})) {
                $ret{$sub.$second."/".$valueName} = getRegistryKeyValue($key, $valueName, $params{withtype});
            }
        }
    }
    return \%ret;
}

sub runCommand {
    my (%params) = (
        timeout => 3600 * 2,
        @_
    );

    my $job = Win32::Job->new();

    my $buff = File::Temp->new();

    my $winCwd = Cwd::getcwd();
    $winCwd =~ s{/}{\\}g;

    my $provider = lc($GLPI::Agent::Version::PROVIDER);
    my $template = $ENV{TEMP}."\\".$provider."XXXXXXXXXXX";
    my ($fh, $filename) = File::Temp::tempfile( $template, SUFFIX => '.bat');
    print $fh "cd \"".$winCwd."\"\r\n";
    print $fh $params{command}."\r\n";
    print $fh "exit %ERRORLEVEL%\r\n";
    close $fh;

    my $args = {
        stdout    => $buff,
        stderr    => $buff,
        no_window => 1
    };

    $job->spawn(
        "$ENV{SYSTEMROOT}\\system32\\cmd.exe",
        "start /wait cmd /c $filename",
        $args
    );

    $job->run($params{timeout});
    unlink($filename);

    $buff->seek(0, SEEK_SET);

    my $exitcode;

    my ($status) = $job->status();
    foreach my $pid (%$status) {
        $exitcode = $status->{$pid}{exitcode};
        last;
    }

    return ($exitcode, $buff);
}

sub runPowerShell {
    my (%params) = @_;

    my $script = delete $params{script}
        or return;

    my ($fh, $psOption);
    if ($GLPI::Agent::Tools::remote) {
        $psOption = "-encodedCommand " . encode_base64(encode("UTF16-LE", $script), "");
    } else {
        # Keeps File::Temp object in %params so temporary file is removed while leaving
        $fh = File::Temp->new(
            TEMPLATE    => 'get-appxpackage-XXXXXX',
            SUFFIX      => '.ps1'
        );
        print $fh $script;
        close( $fh);
        my $file = $fh->filename;
        return unless $file && -f $file;
        $psOption = "-File $file";
    }

    return map { decode("UTF-8", $_) } getAllLines(
        command => "powershell -NonInteractive -ExecutionPolicy Unrestricted $psOption",
        %params
    );
}

sub getInterfaces {
    my (%params) = @_;

    my @configurations;

    foreach my $object (getWMIObjects(
        class      => 'Win32_NetworkAdapterConfiguration',
        properties => [ qw/
            Index InterfaceIndex Description IPEnabled DHCPServer MACAddress MTU
            DefaultIPGateway DNSServerSearchOrder IPAddress IPSubnet
            DNSDomain SettingID
            /
        ]
    )) {

        my $configuration = {
            DESCRIPTION => $object->{Description},
            STATUS      => $object->{IPEnabled} =~ /^1|true$/i ? "Up" : "Down",
            IPDHCP      => $object->{DHCPServer},
            MACADDR     => $object->{MACAddress},
            MTU         => $object->{MTU},
            GUID        => $object->{SettingID},
            DNSDomain   => $object->{DNSDomain}
        };

        if (my $gw = $object->{DefaultIPGateway}) {
            if (ref($gw) eq 'ARRAY') {
                $configuration->{IPGATEWAY} = $gw->[0];
            } elsif (!ref($gw)) {
                $configuration->{IPGATEWAY} = $gw;
            }
        }

        if (my $dns = $object->{DNSServerSearchOrder}) {
            if (ref($dns) eq 'ARRAY') {
                $configuration->{dns} = $dns->[0];
            } elsif (!ref($dns)) {
                $configuration->{dns} = $dns;
            }
        }

        if ($object->{IPAddress} && ref($object->{IPAddress}) eq 'ARRAY') {
            foreach my $address (@{$object->{IPAddress}}) {
                my $prefix = shift @{$object->{IPSubnet}};
                push @{$configuration->{addresses}}, [ $address, $prefix ];
            }
        }

        # XP compatibility
        my $indexKey = defined($object->{InterfaceIndex}) ? 'InterfaceIndex' : 'Index';

        $configurations[$object->{$indexKey}] = $configuration;
    }

    # For Win8 or Above
    my @networkAdapter = getWMIObjects(
        moniker    => 'winmgmts://./root/StandardCimv2',
        class      => 'MSFT_NetAdapter',
        properties => [ qw/InterfaceIndex PnPDeviceID Speed HardwareInterface InterfaceGuid InterfaceDescription InterfaceType/ ]
    );

    if (!@networkAdapter) {
        # Legacy for Win<8
        @networkAdapter = getWMIObjects(
            class      => 'Win32_NetworkAdapter',
            properties => [ qw/Index InterfaceIndex PNPDeviceID Speed PhysicalAdapter GUID/ ]
        );
    }

    my @interfaces;

    foreach my $wmiNetAdapter (@networkAdapter) {
        my $netAdapter = GLPI::Agent::Tools::Win32::NetAdapter->new(
            WMI             => $wmiNetAdapter,
            configurations  => \@configurations
        ) or next;

        push @interfaces, $netAdapter->getInterfaces();
    }

    # Also try to include connected vpn
    my $count = 0;
    my $interfaces = getRegistryKey(
        path => 'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces',
        # Important for remote inventory optimization
        required    => [ qw/DhcpIPAddress DhcpSubnetMask VPNInterface/ ],
    );
    foreach my $interface (keys(%{$interfaces})) {
        my ($guid) = $interface =~ m{^(\{........-....-....-....-............\})/$}
            or next;
        next unless $interfaces->{$interface}->{VPNInterface};
        # This vpn interface is still well-known
        next if grep { $_->{GUID} && uc($_->{GUID}) eq uc($guid) } @configurations;
        my $vpn = {
            DESCRIPTION => "vpn".$count,
            TYPE        => "ethernet",
            VIRTUALDEV  => 1,
            STATUS      => "up"
        };
        my $ip = $interfaces->{$interface}->{DhcpIPAddress}
            or next;
        # Skip vpn if not running
        next if $ip eq '0.0.0.0';
        $vpn->{IPADDRESS} = $ip;
        $vpn->{IPMASK} = $interfaces->{$interface}->{DhcpSubnetMask}
            if $interfaces->{$interface}->{DhcpSubnetMask};

        # Also try to update vpn name but we may not have access to it if not in the right context
        my ($vpnConnection) = getWMIObjects(
            moniker    => 'winmgmts:{impersonationLevel=impersonate,(security)}!//./Root/Microsoft/Windows/RemoteAccess/Client',
            query      => "SELECT * FROM PS_VpnConnection WHERE Guid = '".uc($guid)."' OR Guid = '".lc($guid)."'",
            properties => [ qw/Name/ ]
        );
        $vpn->{DESCRIPTION} = $vpnConnection->{Name}
            if $vpnConnection && $vpnConnection->{Name};

        push @interfaces, $vpn;
        $count++;
    }

    return @interfaces;
}

sub FileTimeToSystemTime {
    # Inspired by Win32::FileTime module
    my $time = shift;

    return unless defined($time);

    my $SystemTime = pack( 'SSSSSSSS', 0, 0, 0, 0, 0, 0, 0, 0 );

    # Load Win32::API as late as possible
    Win32::API->require() or return;

    my @times;
    eval {
        my $FileTimeToSystemTime = Win32::API->new(
            'kernel32',
            'FileTimeToSystemTime',
            [ 'P', 'P' ],
            'I'
        );

        $FileTimeToSystemTime->Call( $time, $SystemTime );
        @times = unpack( 'SSSSSSSS', $SystemTime );
    };

    return @times;
}

sub _getCurrentProcessId {

    # Load Win32::API as late as possible
    Win32::API->require() or return;

    # Get current thread handle
    my $thread;
    eval {
        my $apiGetCurrentThread = Win32::API->new(
            'kernel32',
            'GetCurrentThread',
            [],
            'I'
        );
        $thread = $apiGetCurrentThread->Call();
    };
    return unless (defined($thread));

    # Get system ProcessId for current thread
    my $thread_pid;
    eval {
        my $apiGetProcessIdOfThread = Win32::API->new(
            'kernel32',
            'GetProcessIdOfThread',
            [ 'I' ],
            'I'
        );
        $thread_pid = $apiGetProcessIdOfThread->Call($thread);
    };
    return $thread_pid;
}

sub getCurrentService {

    # Load Win32::API as late as possible
    Win32::API->require() or return;

    # Get current ProcessId
    my $pid = _getCurrentProcessId();
    return unless (defined($pid));

    my ($current) = getWMIObjects(
        query       => 'SELECT * FROM Win32_Service where ProcessId  = '.$pid,
        properties  => [ qw/Name DisplayName/ ]
    );
    return $current;
}

sub getAgentMemorySize {

    # Load Win32::API as late as possible
    Win32::API->require() or return;

    # Get current thread ProcessId
    my $thread_pid = _getCurrentProcessId();
    return -1 unless (defined($thread_pid));

    # Get Process Handle
    my $ph;
    eval {
        my $apiOpenProcess = Win32::API->new(
            'kernel32',
            'OpenProcess',
            [ 'I', 'I', 'I' ],
            'I'
        );
        $ph = $apiOpenProcess->Call(0x400, 0, $thread_pid);
    };
    return -1 unless (defined($ph));

    my ($size, $pages) = ( -1, 0 );
    eval {
        # memory usage is bundled up in ProcessMemoryCounters structure
        # populated by GetProcessMemoryInfo() win32 call
        Win32::API::Struct->typedef('PROCESS_MEMORY_COUNTERS', qw(
            DWORD  cb;
            DWORD  PageFaultCount;
            SIZE_T PeakWorkingSetSize;
            SIZE_T WorkingSetSize;
            SIZE_T QuotaPeakPagedPoolUsage;
            SIZE_T QuotaPagedPoolUsage;
            SIZE_T QuotaPeakNonPagedPoolUsage;
            SIZE_T QuotaNonPagedPoolUsage;
            SIZE_T PagefileUsage;
            SIZE_T PeakPagefileUsage;
        ));

        # initialize PROCESS_MEMORY_COUNTERS structure
        my $mem_counters = Win32::API::Struct->new( 'PROCESS_MEMORY_COUNTERS' );
        foreach my $key (qw/cb PageFaultCount PeakWorkingSetSize WorkingSetSize
            QuotaPeakPagedPoolUsage QuotaPagedPoolUsage QuotaPeakNonPagedPoolUsage
            QuotaNonPagedPoolUsage PagefileUsage PeakPagefileUsage/) {
                 $mem_counters->{$key} = 0;
        }
        my $cb = $mem_counters->sizeof();

        # Request GetProcessMemoryInfo API and call it to find current process memory
        my $apiGetProcessMemoryInfo = Win32::API->new(
            'psapi',
            'BOOL GetProcessMemoryInfo(
                HANDLE hProc,
                LPPROCESS_MEMORY_COUNTERS ppsmemCounters, DWORD cb
            )'
        );
        if ($apiGetProcessMemoryInfo->Call($ph, $mem_counters, $cb)) {
            # Uses WorkingSetSize and PagefileUsage
            $size = $mem_counters->{WorkingSetSize};
            $pages = $mem_counters->{PagefileUsage};
        }
    };

    # Don't forget to close Process Handle
    eval {
        my $apiCloseHandle = Win32::API->new(
            'kernel32',
            'CloseHandle',
            'I',
            'I'
        );
        $ph = $apiCloseHandle->Call($ph);
    };

    return $size, $pages;
}

sub FreeAgentMem {

    # Load Win32::API as late as possible
    Win32::API->require() or return;

    eval {
        # Get current process handle
        my $apiGetCurrentProcess = Win32::API->new(
            'kernel32',
            'HANDLE GetCurrentProcess()'
        );
        my $proc = $apiGetCurrentProcess->Call();

        # Call SetProcessWorkingSetSize with magic parameters for freeing our memory
        my $apiSetProcessWorkingSetSize = Win32::API->new(
            'kernel32',
            'SetProcessWorkingSetSize',
            [ 'I', 'I', 'I' ],
            'I'
        );
        $apiSetProcessWorkingSetSize->Call( $proc, -1, -1 );
    };
}

my $worker ;
my $worker_semaphore;
my $worker_lasterror = [];

my @win32_ole_calls : shared;

sub start_Win32_OLE_Worker {

    unless (defined($worker)) {

        # Handle thread KILL signal
        $SIG{KILL} = sub { threads->exit(); };

        # Request a semaphore on which worker blocks immediatly
        Thread::Semaphore->require();
        $worker_semaphore = Thread::Semaphore->new(0);

        # Start a worker thread
        $worker = threads->create( \&_win32_ole_worker );
    }

    return $worker;
}

sub setupWorkerLogger {
    my (%params) = @_;

    # Just create a new Logger object in worker to update default module configuration
    return defined(GLPI::Agent::Logger->new(%params))
        unless (defined($worker));

    return _call_win32_ole_dependent_api({
        funct => 'setupWorkerLogger',
        args  => [ %params ]
    });
}

sub getLastError {

    return @{$worker_lasterror}
        unless (defined($worker));

    return _call_win32_ole_dependent_api({
        funct => 'getLastError',
        array => 1,
        args  => []
    });
}

my %known_ole_errors = (
    scalar(0x80041003)  => "Access denied as the current or specified user name and password were not valid or authorized to make the connection.",
    scalar(0x8004100E)  => "Invalid namespace",
    scalar(0x80041064)  => "User credentials cannot be used for local connections",
    scalar(0x80070005)  => "Access denied",
    scalar(0x800706BA)  => "The RPC server is unavailable",
);

sub _keepOleLastError {

    my $lasterror = Win32::OLE->LastError();
    if ($lasterror) {
        my $error = 0x80000000 | ($lasterror & 0x7fffffff);
        # Don't report not accurate and not failure error
        if ($error != 0x80004005 && $error != 0x80020003) {
            $worker_lasterror = [ $error, $known_ole_errors{$error} ];
            my $logger = GLPI::Agent::Logger->new();
            $logger->debug("Win32::OLE ERROR: ".($known_ole_errors{$error}||$lasterror));
        }
    } else {
        $worker_lasterror = [];
    }
}

sub _win32_ole_worker {
    # Load Win32::OLE as late as possible in a dedicated worker
    Win32::OLE->require() or return;
    # We re-initialize Win32::OLE to later support Events
    Win32::OLE->Uninitialize();
    Win32::OLE->Initialize(Win32::OLE::COINIT_OLEINITIALIZE());
    Win32::OLE::Variant->require() or return;
    Win32::OLE->Option(CP => Win32::OLE::CP_UTF8());

    while (1) {
        # Always block until semaphore is made available by main thread
        $worker_semaphore->down();

        my ($call, $result);
        {
            lock(@win32_ole_calls);
            $call = shift @win32_ole_calls
                if (@win32_ole_calls);
        }

        if (defined($call)) {
            lock($call);

            # Handle call expiration
            setExpirationTime(%$call);

            # Found requested private function and call it as expected
            my $funct;
            eval {
                no strict 'refs'; ## no critic (ProhibitNoStrict)
                $funct = \&{$call->{'funct'}};
            };
            if (exists($call->{'array'}) && $call->{'array'}) {
                my @results = &{$funct}(@{$call->{'args'}});
                $result = \@results;
            } else {
                $result = &{$funct}(@{$call->{'args'}});
            }

            # Keep Win32::OLE error for later reporting
            _keepOleLastError() unless $funct == \&getLastError;

            # Share back the result
            $call->{'result'} = shared_clone($result);

            # Reset expiration
            setExpirationTime();

            # Signal main thread result is available
            cond_signal($call);
        }
    }
}

sub _call_win32_ole_dependent_api {
    my ($call) = @_
        or return;

    # Reset timeout as shared between threads
    my $now = time;
    my $expiration = getExpirationTime() || $now + 180;

    # Reduce expiration time by 10% of the remaining time to leave a chance to
    # the caller to compute any result. By default, the reducing should be 2 seconds.
    $expiration -= int(($expiration - $now) * 0.01) + 1;

    # Be sure expiration is kept in the future by 10 seconds
    $expiration = $now + 10 unless $expiration > $now;
    $call->{expiration} = $expiration;

    if (defined($worker)) {
        # Share the expect call
        my $call = shared_clone($call);
        my $result;

        if (defined($call)) {
            # Be sure the worker block
            $worker_semaphore->down_nb();

            # Lock list calls before releasing semaphore so worker waits
            # on it until we start cond_timedwait for signal on $call
            lock(@win32_ole_calls);
            push @win32_ole_calls, $call;

            # Release semaphore so the worker can continue its job
            $worker_semaphore->up();

            # Now, wait for worker result, leaving a 1 second grace delay to
            # give worker a chance to handle the timeout by itself
            $expiration ++ ;
            while (!exists($call->{'result'})) {
                last if (!cond_timedwait($call, $expiration, @win32_ole_calls));
            }

            # Be sure to always block worker on semaphore from now
            $worker_semaphore->down_nb();

            if (exists($call->{'result'})) {
                $result = $call->{'result'};
            } elsif (time < $expiration) {
                # Worker is failing: get back to mono-thread and pray
                $worker->detach() if (defined($worker) && !$worker->is_detached());
                $worker = undef;
                return _call_win32_ole_dependent_api(@_);
            }
        }

        return (exists($call->{'array'}) && $call->{'array'}) ?
            @{$result || []} : $result ;
    } else {
        # Load Win32::OLE as late as possible
        Win32::OLE->require() or return;
        Win32::OLE::Variant->require() or return;
        Win32::OLE->Option(CP => Win32::OLE::CP_UTF8());

        # Handle call expiration
        setExpirationTime(%$call);

        # We come here from worker or if we failed to start worker
        my $funct;
        eval {
            no strict 'refs'; ## no critic (ProhibitNoStrict)
            $funct = \&{$call->{'funct'}};
        };

        if (exists($call->{'array'}) && $call->{'array'}) {
            my @results = &{$funct}(@{$call->{'args'}});

            # Keep Win32::OLE error for later reporting
            _keepOleLastError() unless $funct == \&getLastError;

            # Reset expiration
            setExpirationTime();
            return @results;
        } else {
            my $result = &{$funct}(@{$call->{'args'}});

            # Keep Win32::OLE error for later reporting
            _keepOleLastError() unless $funct == \&getLastError;

            # Reset expiration
            setExpirationTime();
            return $result;
        }
    }
}

sub newPoller {
    return Thread::Semaphore->new(0);
}

sub setPoller {
    my ($poller) = @_;
    $poller->up();
}

sub getPoller {
    my ($poller) = @_;
    return $poller->down_nb();
}

sub getFormatedWMIDateTime {
    my ($datetime) = @_;

    return $datetime if $datetime && $datetime =~ m|^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$|;

    return unless $datetime &&
        $datetime =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\.\d{6}.(\d{3})$/;

    # Timezone in $7 is ignored

    return getFormatedDate($1, $2, $3, $4, $5, $6);
}

END {
    # Just detach worker
    $worker->detach() if (defined($worker) && !$worker->is_detached());
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::Win32 - Windows generic functions

=head1 DESCRIPTION

This module provides some Windows-specific generic functions.

=head1 FUNCTIONS

=head2 is64bit()

Returns true if the OS is 64bit or false.

=head2 getLocalCodepage()

Returns the local codepage.

=head2 getWMIObjects(%params)

Returns the list of objects from given WMI class or from a query, with given
properties, properly encoded.

=over

=item moniker a WMI moniker (default: winmgmts:{impersonationLevel=impersonate,(security)}!//./)

=item altmoniker another WMI moniker to use if first failed (none by default)

=item class a WMI class, not used if query parameter is also given

=item properties a list of WMI properties

=item query a WMI request to execute, if specified, class parameter is not used

=item method an object method to call, in that case, you will also need the
following parameters:

=item params a list ref to the parameters to use fro the method. This list contains
string as key to other parameters defining the call. The key names should not
match any exiting parameter definition. Each parameter definition must be a list
of the type and default value.

=item binds a hash ref to the properties to bind to the returned object

=back

=head2 encodeFromRegistry($string)

Ensure given registry content is properly encoded to utf-8.

=head2 getRegistryValue(%params)

Returns a value from the registry.

=over

=item path a string in hive/key/value format

E.g: HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows NT/CurrentVersion/ProductName

=item logger

=back

=head2 getRegistryKey(%params)

Returns a key from the registry. If key name is '*', all the keys of the path are returned as a hash reference.

=over

=item path a string in hive/key format

E.g: HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows NT/CurrentVersion

=item logger

=back

=head2 runCommand(%params)

Returns a command in a Win32 Process

=over

=item command the command to run

=item timeout a time in second, default is 3600*2

=back

Return an array

=over

=item exitcode the error code, 293 means a timeout occurred

=item fd a file descriptor on the output

=back

=head2 getInterfaces()

Returns the list of network interfaces.

=head2 FileTimeToSystemTime()

Returns an array of a converted FILETIME datetime value with following order:
    ( year, month, wday, day, hour, minute, second, msecond )

=head2 start_Win32_OLE_Worker()

Under win32, just start a worker thread handling Win32::OLE dependent
APIs like is64bit() & getWMIObjects(). This is sometime needed to avoid
perl crashes.
