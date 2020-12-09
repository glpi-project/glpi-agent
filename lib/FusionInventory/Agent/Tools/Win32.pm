package FusionInventory::Agent::Tools::Win32;

use strict;
use warnings;
use parent 'Exporter';
use utf8;

use threads;
use threads 'exit' => 'threads_only';
use threads::shared;

use Thread::Semaphore;

use UNIVERSAL::require();

use constant KEY_WOW64_64 => 0x100;
use constant KEY_WOW64_32 => 0x200;

use Cwd;
use Encode;
use English qw(-no_match_vars);
use File::Temp qw(:seekable tempfile);
use File::Basename qw(basename);
use Win32::Job;
use Win32::TieRegistry (
    Delimiter   => '/',
    ArrayValues => 0,
    qw/KEY_READ/
);

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Expiration;
use FusionInventory::Agent::Tools::Win32::NetAdapter;
use FusionInventory::Agent::Version;

my $localCodepage;

our @EXPORT = qw(
    is64bit
    remoteIs64bits
    encodeFromRegistry
    KEY_WOW64_64
    KEY_WOW64_32
    getInterfaces
    getRegistryValue
    getRegistryKey
    getWMIObjects
    getLocalCodepage
    runCommand
    FileTimeToSystemTime
    getAgentMemorySize
    FreeAgentMem
    getWMIService
    getFormatedWMIDateTime
    loadUserHive
);

my $_is64bits = undef;
sub is64bit {
    # Cache is64bit() result in a private module variable to avoid a lot of wmi
    # calls and as this value won't change during the service/task lifetime
    return remoteIs64bits() if _remoteWmi();
    return $_is64bits if $_is64bits;
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

sub encodeFromRegistry {
    my ($string) = @_;

    ## no critic (ExplicitReturnUndef)
    return undef unless $string;

    return $string if Encode::is_utf8($string);

    return decode(getLocalCodepage(), $string);
}

sub getWMIObjects {
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

    FusionInventory::Agent::Logger->require();

    my $logthat = "";
    my $logger  = $params{logger} || FusionInventory::Agent::Logger->new();

    my $expiration = getExpirationTime();

    my $WMIService;
    if (_remoteWmi()) {
        $WMIService = getWMIService(
            root => $params{root} || "root\\cimv2",
            @_
        );
        # Support alternate moniker if provided and main failed to open
        if (!defined($WMIService) && $params{altmoniker}) {
            $WMIService = getWMIService( moniker => $params{altmoniker} );
        }
    } else {
        $WMIService = Win32::OLE->GetObject($params{moniker});
        # Support alternate moniker if provided and main failed to open
        if (!defined($WMIService) && $params{altmoniker}) {
            $WMIService = Win32::OLE->GetObject($params{altmoniker});
        }
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
        # FusionInventory::Agent::Task::Inventory::Win32::Users as example to
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

    # Shortcut call in remote wmi case
    if (_remoteWmi()) {
        my $win32_ole_dependent_api = {
            funct => '_getRegistryValueFromWMI',
            args  => [
                key     => "$root/$keyName",
                value   => $valueName
            ]
        };

        return _call_win32_ole_dependent_api($win32_ole_dependent_api);
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
            $ret{$_} = $params{withtype} ? [$key->GetValue($_)] : $key->{"/$_"} ;
        }
        return \%ret;
    } else {
        return $params{withtype} ? [$key->GetValue($valueName)] : $key->{"/$valueName"} ;
    }
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

    # Shortcut call in remote wmi case
    if (_remoteWmi()) {
        my $win32_ole_dependent_api = {
            funct => '_getRegistryKeyFromWMI',
            args  => [
                path    => $root,
                keyName => $keyName,
                wmiopts => $params{wmiopts}
            ]
        };

        return _call_win32_ole_dependent_api($win32_ole_dependent_api);
    }

    return _getRegistryKey(
        logger  => $logger,
        root    => $root,
        keyName => $keyName
    );
}

sub _getRegistryRoot {
    my (%params) = @_;

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

    return unless $params{sid} && $params{file} && -e $params{file};

    return if $_loadedhive && $_loadedhive->{$params{sid}};

    my $rootKey = _getRegistryRoot(root => 'HKEY_USERS')
        or return;

    # Don't load if still found
    return if $rootKey->Open($params{sid});

    return $rootKey->Load( $params{file}, $params{sid}, { Access => KEY_READ } );
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
                    $ret{$sub.$second."/".$_} = $params{withtype} ? [$key->GetValue($_)] : $key->{"/$_"} ;
                }
            } elsif (exists($key->{"/$valueName"})) {
                $ret{$sub.$second."/".$valueName} = $params{withtype} ? [$key->GetValue($valueName)] : $key->{"/$valueName"} ;
            }
        }
    }
    return \%ret;
}

sub _getRegistryKeyFromWMI{
    my (%params) = @_;

    my $keyName = defined $params{keyName} ? $params{keyName} : '';

    my $registry = _getWMIRegistry()
        or return;

    my ($hKey, $subKey) = $params{path} =~ m{^(HKEY_[^/]+)/?(.*)$};
    $subKey = "" unless defined $subKey;
    $subKey .= "/" .$keyName if length $keyName;

    return unless $hKey;

    my %wmiopts = $params{wmiopts} ? %{$params{wmiopts}} : ();

    # subkey path must be win32 conform
    $subKey =~ s|/|\\|g if $subKey;

    Win32::OLE->use('in');

    Win32API::Registry->require();

    Win32::OLE::Variant->require();
    Win32::OLE::Variant->use(qw/VT_BYREF VT_ARRAY VT_VARIANT/);

    # Using a hashref here is just a convenient way for debugging and keep
    # computed values between evals
    my $ret = {
        path   => $subKey,
        result => {}
    };

    eval {
        # Get expected hKey value from registry constants
        $ret->{hKey} = Win32API::Registry::regConstant($hKey);
    };

    return unless $ret->{hKey};

    # We will try to get all the registry tree by default
    if (!exists($wmiopts{subkeys}) || $wmiopts{subkeys}) {
        eval {
            # Uses registry enumeration to list values and their type
            my $type  = VT_BYREF()|VT_ARRAY()|VT_VARIANT();
            my $subs  = Win32::OLE::Variant->new($type,[1,1]);
            $ret->{err} = $registry->EnumKey($ret->{hKey}, $ret->{path}, $subs);

            # Find expected key in the list if some found
            $ret->{keys} = [ in( $subs->Copy->Value() ) ]
                if ($ret->{err} == 0 && $subs->Dim());
        };

        return unless $ret->{err} == 0;
    }

    eval {
        # Uses registry enumeration to list values and their type
        my $type  = VT_BYREF()|VT_ARRAY()|VT_VARIANT();
        my $vars  = Win32::OLE::Variant->new($type,[1,1]);
        my $types = Win32::OLE::Variant->new($type,[1,1]);
        $ret->{err} = $registry->EnumValues($ret->{hKey}, $ret->{path}, $vars, $types);

        # Find expected value in the list and keep its type but skip when
        # no values are found to avoid crashing
        if ($vars->Dim()) {
            my @types = in( $types->Copy->Value() );
            foreach my $value ( in( $vars->Copy->Value() ) ) {
                my $type = shift @types;
                next unless $value && $type;
                next if ($wmiopts{values} && ! first { $_ eq $value } @{$wmiopts{values}});
                $ret->{result}{"/$value"} = _getRegistryKeyValueFromWMI(
                    hKey    => $ret->{hKey},
                    path    => $ret->{path},
                    value   => $value,
                    type    => $type
                );
            }
        }

        # Populate leafs with recurse calling
        foreach my $subkey (@{$ret->{keys}}) {
            $ret->{result}{"$subkey/"} = _getRegistryKeyFromWMI(
                path    => $params{path}."/".$keyName,
                wmiopts => \%wmiopts,
                keyName => $subkey
            );
        }
    };

    return $ret->{result};
}

sub _getRegistryKeyValueFromWMI {
    my (%params) = @_;

    my $registry = _getWMIRegistry()
        or return;

    Win32API::Registry->require();
    Win32API::Registry->use(qw/REG_SZ REG_EXPAND_SZ REG_BINARY REG_DWORD REG_MULTI_SZ/);

    Win32::OLE::Variant->require();
    Win32::OLE::Variant->use(qw/VT_BYREF VT_BSTR VT_I4 VT_ARRAY VT_VARIANT/);

    my $err = 0;
    my $value;
    eval {
        # Retrieve the value for supported types
        if ($params{type} == REG_SZ()) {                         # REG_SZ
            my $type = VT_BYREF()|VT_BSTR();
            my $var  = Win32::OLE::Variant->new($type);
            $err = $registry->GetStringValue($params{hKey}, $params{path}, $params{value}, $var);
            $value = $var->Copy->Value();

        } elsif ($params{type} == REG_EXPAND_SZ()) {             # REG_EXPAND_SZ
            my $type = VT_BYREF()|VT_BSTR();
            my $var  = Win32::OLE::Variant->new($type);
            $err = $registry->GetExpandedStringValue($params{hKey}, $params{path}, $params{value}, $var);
            $value = $var->Copy->Value();

        } elsif ($params{type} == REG_BINARY()) {                # REG_BINARY
            my $type = VT_BYREF()|VT_ARRAY()|VT_VARIANT();
            my $var  = Win32::OLE::Variant->new($type,[1,1]);
            $err = $registry->GetBinaryValue($params{hKey}, $params{path}, $params{value}, $var);
            $value = join('', map { chr } @{$var->Copy->Value()});

        } elsif ($params{type} == REG_DWORD()) {                 # REG_DWORD
            my $type = VT_BYREF()|VT_I4();
            my $var  = Win32::OLE::Variant->new($type,0);
            $err = $registry->GetDWORDValue($params{hKey}, $params{path}, $params{value}, $var);
            $value = $var->Copy->Value();

        } elsif ($params{type} == REG_MULTI_SZ()) {              # REG_MULTI_SZ
            my $type = VT_BYREF()|VT_ARRAY()|VT_VARIANT();
            my $var  = Win32::OLE::Variant->new($type,[1,1]);
            $err = $registry->GetMultiStringValue($params{hKey}, $params{path}, $params{value}, $var);
            $value = $var->Dim() ? $var->Copy->Value() : [];
        }
    };

    return unless $err == 0;

    return $value;
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

    my $provider = lc($FusionInventory::Agent::Version::PROVIDER);
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

sub getInterfaces {
    my (%params) = @_;

    my @configurations;

    foreach my $object (getWMIObjects(
            class      => 'Win32_NetworkAdapterConfiguration',
            properties => [ qw/
                Index InterfaceIndex Description IPEnabled DHCPServer MACAddress MTU
                DefaultIPGateway DNSServerSearchOrder IPAddress IPSubnet
                DNSDomain
                /
            ]
    )) {

        my $configuration = {
            DESCRIPTION => $object->{Description},
            STATUS      => $object->{IPEnabled} ? "Up" : "Down",
            IPDHCP      => $object->{DHCPServer},
            MACADDR     => $object->{MACAddress},
            MTU         => $object->{MTU},
            DNSDomain   => $object->{DNSDomain}
        };

        if ($object->{DefaultIPGateway}) {
            $configuration->{IPGATEWAY} = $object->{DefaultIPGateway}->[0];
        }

        if ($object->{DNSServerSearchOrder}) {
            $configuration->{dns} = $object->{DNSServerSearchOrder}->[0];
        }

        if ($object->{IPAddress}) {
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
        properties => [ qw/InterfaceIndex PnPDeviceID Speed HardwareInterface InterfaceGuid InterfaceDescription/ ]
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
        my $netAdapter = FusionInventory::Agent::Tools::Win32::NetAdapter->new(
            WMI             => $wmiNetAdapter,
            configurations  => \@configurations
        ) or next;

        push @interfaces, $netAdapter->getInterfaces();
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

sub getAgentMemorySize {

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
    return -1 unless (defined($thread));

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
my $wmiService;
my $wmiLocator;
my $wmiRegistry;
my $wmiParams = {};

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
    return defined(FusionInventory::Agent::Logger->new(%params))
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
        if ($error != 0x80004005) {
            $worker_lasterror = [ $error, $known_ole_errors{$error} ];
            my $logger = FusionInventory::Agent::Logger->new();
            $logger->debug("Win32::OLE ERROR: ".($known_ole_errors{$error}||$lasterror));
        }
    } else {
        $worker_lasterror = [];
    }
}

sub _win32_ole_worker {
    # Load Win32::OLE as late as possible in a dedicated worker
    Win32::OLE->require() or return;
    # We re-initialize Win32::OLE to later support Events (needed for remote WMI)
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

sub _remoteWmi {
    return $wmiParams->{host} ? 1 : 0;
}

sub remoteIs64bits {
    return $wmiParams->{is64bits} if $wmiParams->{is64bits};
    # Retrieve and save is64bit result
    return $wmiParams->{is64bits} = any { $_->{AddressWidth} eq 64 }
        getWMIObjects(
            class       => 'Win32_Processor',
            properties  => [ qw/AddressWidth/ ]
        );
}

sub _connectToService {
    my (%params) = @_;

    # Be sure to reset known access params in threaded version so
    # getWMIService won't reset when called from right thread
    foreach my $param (qw( host user pass root)) {
        $wmiParams->{$param} = $params{$param};
    }

    Win32::OLE->require() or return;

    $wmiLocator = Win32::OLE->CreateObject('WbemScripting.SWbemLocator')
        or return;

    # Always use en-US (MS_409) locale to avoid localized response
    $wmiService = $wmiLocator->ConnectServer(
        $params{host}, $params{root},
        $params{user}, $params{pass}, 'MS_409'
    );

    return defined $wmiService;
}

sub _getWMIRegistry {
    my (%params) = @_;

    unless ($wmiRegistry) {
        my $WMIService = getWMIService(root => 'root\\default')
            or return;

        # If missing on a computer, go in C:\Windows\System32\wbem and run "mofcomp regevent.mof"
        $wmiRegistry = $WMIService->Get("StdRegProv");
    }

    return $wmiRegistry;
}

sub getWMIService {
    my (%params) = @_;

    my $host   = $params{host} || $wmiParams->{host} || '127.0.0.1';
    my $user   = $params{user} || $wmiParams->{user} || '';
    my $pass   = $params{pass} || $wmiParams->{pass} || '';
    my $root   = $params{root} || $wmiParams->{root} || 'root\\cimv2';

    # Reset root if found in moniker params
    if ($params{moniker}) {
        $params{moniker} =~ s{/}{\\}g;
        if ($params{moniker} =~ /\\root\\(.*)$/i) {
            $root = "root\\" . lc($1);
        }
    }

    # check if the connection is right otherwise reset it
    if (!$wmiService || $wmiParams && (
                $wmiParams->{host} ne $host ||
                $wmiParams->{user} ne $user ||
                $wmiParams->{pass} ne $pass ||
                $wmiParams->{root} ne $root)) {

        $wmiParams = {
            host    => $host,
            user    => $user,
            pass    => $pass,
            root    => $root
        };

        my $win32_ole_dependent_api = {
            funct => '_connectToService',
            args  => [ %{$wmiParams} ]
        };

        my @connected = _call_win32_ole_dependent_api($win32_ole_dependent_api);

        # Only set $wmiService as connected status in main thread if worker is active
        # If no worker is active, $wmiService still decides if connected as it is
        # set directly in _connectToService()
        $wmiService = shift @connected
            if (defined($worker) && @connected);
    }

    return $wmiService;
}

sub getFormatedWMIDateTime {
    my ($datetime) = @_;

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

FusionInventory::Agent::Tools::Win32 - Windows generic functions

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
