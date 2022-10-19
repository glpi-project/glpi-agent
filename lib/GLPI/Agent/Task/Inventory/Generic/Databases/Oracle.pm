package GLPI::Agent::Task::Inventory::Generic::Databases::Oracle;

use English qw(-no_match_vars);

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Generic::Databases';

use File::Temp;

use GLPI::Agent::Tools;
use GLPI::Agent::XML;
use GLPI::Agent::Tools::Unix;
use GLPI::Agent::Inventory::DatabaseService;

sub isEnabled {
    return 1 if canRun('sqlplus');
    my $oracle_home = _oracleHome()
        or return;
    return 1 if first { canRun($_."/sqlplus") || canRun($_.'/bin/sqlplus') } @{$oracle_home};
    return 0;
}

sub _oracleHome {
    my (%params) = @_;

    return [$ENV{ORACLE_HOME}] if $ENV{ORACLE_HOME} && -d $ENV{ORACLE_HOME}
        && !$params{file}; # $params{file} is only set during tests

    my $inventory_loc = getFirstMatch(
        file    => $params{file} // '/etc/oraInst.loc',
        pattern => qr/^inventory_loc=(.*)$/
    )
        or return;

    return unless -d $inventory_loc;

    my $inventory_xml = $inventory_loc . "/ContentsXML/inventory.xml";
    return unless -e $inventory_xml;

    my $xml = GLPI::Agent::XML->new(
        force_array => [ qw/HOME/ ],
        file        => $inventory_xml
    );
    my $tree = $xml->dump_as_hash();
    return unless $tree && $tree->{INVENTORY} && $tree->{INVENTORY}->{HOME_LIST}
        && $tree->{INVENTORY}->{HOME_LIST}->{HOME};
    return [
        map { $_->{"-LOC"} } grep {
            ! $_->{"-REMOVED"}
        } @{$tree->{INVENTORY}->{HOME_LIST}->{HOME}}
    ];
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    # Try to retrieve credentials updating params
    GLPI::Agent::Task::Inventory::Generic::Databases::_credentials(\%params, "oracle");

    my $dbservices = _getDatabaseService(
        logger      => $params{logger},
        credentials => $params{credentials},
    );

    foreach my $dbs (@{$dbservices}) {
        $inventory->addEntry(
            section => 'DATABASES_SERVICES',
            entry   => $dbs->entry(),
        );
    }
}

my %ORACLE_ENV;
my %reset_ENV;

sub _setEnv {
    my (%params) = @_;

    my $home = $params{home}
        or return;

    my $sqlplus_path = $ORACLE_ENV{$home}
        or return;

    my $sid = $params{sid};
    if ($params{logger}) {
        if ($sid) {
            $params{logger}->debug2("Setting up environment for $sid SID instance: ORACLE_HOME=$home $sqlplus_path/sqlplus");
        } else {
            $params{logger}->debug2("Setting up environment: ORACLE_HOME=$home $sqlplus_path/sqlplus");
        }
    }

    # Find ORACLE_BASE for latest Oracle versions
    my $oraclebase;
    if (has_file("$home/install/orabasetab")) {
        ($oraclebase) = getFirstMatch(
            file    => "$home/install/orabasetab",
            pattern => qr/^$home:([^:]+):/
        );
    }

    # Setup environment for sqlplus
    $ENV{ORACLE_SID}  = $sid if $sid;
    $ENV{ORACLE_HOME} = $home;
    $ENV{ORACLE_BASE} = $oraclebase if $oraclebase;
    $ENV{LD_LIBRARY_PATH} = join(":", map { $home.$_ } "", "/lib", "/network/lib");
}

sub _resetEnv {
    # Reset set environment
    foreach my $env (keys(%reset_ENV)) {
        if ($reset_ENV{$env}) {
            $ENV{$env} = $reset_ENV{$env};
        } else {
            delete $ENV{$env};
        }
    }
}

sub _getDatabaseService {
    my (%params) = @_;

    my $credentials = delete $params{credentials};
    return [] unless $credentials && ref($credentials) eq 'ARRAY';

    my $logger = $params{logger};

    # Setup sqlplus needed environment but not during test
    unless ($params{istest}) {
        my $oracle_home = _oracleHome();
        if ($oracle_home && @{$oracle_home}) {
            map { $reset_ENV{$_} = $ENV{$_} } qw/ORACLE_HOME ORACLE_BASE ORACLE_SID LD_LIBRARY_PATH/;
            foreach my $home (@{$oracle_home}) {
                next unless -d $home;
                my ($sqlplus_path) = first { ! -d "$_/sqlplus" && canRun("$_/sqlplus") } $home, $home."/bin";
                unless ($sqlplus_path) {
                    $logger->debug2("sqlplus not find in '$home' ORACLE_HOME") if $logger;
                    next;
                }
                $ORACLE_ENV{$home} = $sqlplus_path;
            }
        }

        unless (keys(%ORACLE_ENV) || canRun("sqlplus")) {
            $logger->debug("Can't find valid ORACLE_HOME") if $logger;
            return;
        }

        # Get group gid of installation group
        my $group = getFirstMatch(
            file    => '/etc/oraInst.loc',
            pattern => qr/^inst_group=(.*)$/
        );
        $params{gid} = getgrnam($group) if $group;
    }

    my @dbs = ();

    foreach my $credential (@{$credentials}) {
        GLPI::Agent::Task::Inventory::Generic::Databases::trying_credentials($logger, $credential);
        _oracleConnect(\%params, $credential);

        my %SID;
        my @instances;
        if ($params{remote} || ! -e '/etc/oratab') {
            # Use any sqlplus found environment
            unless ($ENV{ORACLE_HOME} || !keys(%ORACLE_ENV)) {
                _setEnv(
                    home    => (keys(%ORACLE_ENV))[0],
                    logger  => $logger
                );
            }
            @instances = _getInstances(%params);
            _resetEnv();
        } else {
            my @lines = getAllLines(
                file    => '/etc/oratab',
                logger  => $logger
            );
            foreach my $line (@lines) {
                my ($sid, $home) = $line =~ /^([^#*:][^:]*):([^:]+):/;
                next unless $sid && $home;
                next unless -d $home;
                _setEnv(
                    sid     => $sid,
                    home    => $home,
                    logger  => $logger
                );
                $logger->debug2("Checking $sid SID instance...") if $logger;
                my @inst = _getInstances(%params);
                _resetEnv();
                next unless @inst;
                foreach my $name (map { /^([^,]+),/ } @inst) {
                    $SID{$name} = {
                        sid     => $sid,
                        home    => $home
                    };
                }
                push @instances, @inst;
            }
        }

        foreach my $instance (@instances) {
            my ($instance_name, $state, $fullversion, $starttime) = split(',', $instance)
                or next;

            # We will use SID if found in oratab
            _setEnv(
                %{$SID{$instance_name}},
                logger  => $logger
            )
                if $SID{$instance_name};

            my $dbs_size = 0;

            my @database = _runSql(
                name => "select-name-from-database",
                sql  => "SELECT name, "._datefield("created")." FROM v\$database",
                %params
            );
            if (first { /^(ERROR(?: at line 1)?|Usage):/ } @database) {
                my ($error) = first { /^(ORA|SP2)-/ } @database;
                $logger->debug("Oracle database SELECT error: $error") if $error && $logger;
                @database = ();
                $state = "ERROR";
            }

            my $dbs = GLPI::Agent::Inventory::DatabaseService->new(
                type            => "oracle",
                name            => $instance_name,
                version         => $fullversion,
                manufacturer    => "Oracle",
                port            => $credential->{port} // "1521",
                is_active       => $state && $state =~ /^ACTIVE$/i ? 1 : 0,
                last_boot_date  => $starttime,
            );

            foreach my $db (@database) {
                my ($db_name, $created) = split(',', $db)
                    or next;

                $logger->debug2("Checking $db_name database...") if $logger;

                my ($size) = _runSql(
                    name => "select-bytes-from-dba_data_files",
                    sql  => "select sum(bytes)/1024/1024 from dba_data_files",
                    %params
                );
                $dbs_size += $size if $size && $size =~/^\d+$/;

                # Find update date
                my $updated = _runSql(
                    name => "select-timestamp-from-dba_tab_modifications",
                    sql => "SELECT "._datefield("timestamp")." FROM dba_tab_modifications ORDER BY timestamp DESC FETCH NEXT 1 ROW ONLY",
                    %params
                );

                $dbs->addDatabase(
                    name            => $db_name,
                    size            => int($size // 0),
                    is_active       => $state && $state =~ /^ACTIVE$/i ? 1 : 0,
                    creation_date   => $created,
                    update_date     => $updated,
                );
            }

            $dbs->size(int($dbs_size));

            push @dbs, $dbs;

            # Reset environment before trying next instance or leave
            _resetEnv();
        }
    }

    return \@dbs;
}

sub _getInstances {
    my (%params) = @_;

    my @test = _runSql(
        name    => "show-release",
        sql     => "SHOW release",
        %params
    );
    if (first { /^(ERROR|Usage):/ } @test) {
        my ($error) = first { /^(ORA|SP2)-/ } @test;
        $params{logger}->debug("Oracle CONNECT error: $error") if $error && $params{logger};
        return $ENV{ORACLE_SID}.",FAILURE,0," if $ENV{ORACLE_SID};
        return;
    }
    return unless @test || $ENV{ORACLE_SID};
    return $ENV{ORACLE_SID}.",STOPPED,0," unless @test;
    my ($release) = $test[0] =~ /release (\d+)/;
    return $ENV{ORACLE_SID}.",STOPPED,0," if $ENV{ORACLE_SID} && ! $release;
    return unless $release;

    # version_full column is only available since Oracle 18c
    my @version = $release =~ /(\d+)(\d{2})(\d{2})(\d{2})(\d{2})$/;
    my $version_statement = $version[0] && int($version[0]) >= 18 ? "version_full" : "version";

    my @instances = _runSql(
        name => "select-instance_name-from-instances",
        sql  => "SELECT instance_name, database_status, $version_statement, "._datefield("startup_time")." FROM v\$instance",
        %params
    );
    if (first { /^(ERROR(?: at line 1)?|Usage):/ } @instances) {
        my ($error) = first { /^(ORA|SP2)-/ } @instances;
        $params{logger}->debug("Oracle instance SELECT error: $error") if $error && $params{logger};
        return;
    }

    return @instances;
}

sub _datefield {
    my $field = shift;
    return "to_char($field,'YYYY-MM-DD HH24:MI:SS')";
}

sub _runSql {
    my (%params) = @_;

    my $sql = delete $params{sql}
        or return;

    $params{logger}->debug2("Running sql command via sqlplus: $sql") if $params{logger};

    # Include sqlplus path if known
    my $command = ($ENV{ORACLE_HOME} && $ORACLE_ENV{$ENV{ORACLE_HOME}}) ?
        $ORACLE_ENV{$ENV{ORACLE_HOME}}."/" : "";
    $command .= "sqlplus -S -L";
    $command .= $params{connect} ? " /nolog" : " / AS SYSDBA";

    # Don't try to create the temporary sql file during unittest
    my $exec;
    unless ($params{istest}) {
        # Temp file will be deleted while leaving the function
        $exec = File::Temp->new(
            TEMPLATE    => 'oracle-XXXXXX',
            SUFFIX      => '.sql',
            TMPDIR      => 1,
        );
        my $sqlfile = $exec->filename();
        $command .= ' @"'.$sqlfile.'"';

        # Update sql command to emulate csv output as "SET MARKUP CSV ON QUOTE OFF" is only supported since Oracle 12.2
        $sql =~ s/, / ||','|| /g;

        my @lines = ();
        push @lines, $params{connect} if $params{connect};
        push @lines,
            "SET HEADING OFF",
            "SET LINESIZE 4096 TRIMSPOOL ON PAGESIZE 0 FEEDBACK OFF FLUSH OFF",
            $sql.";",
            "QUIT";

        unless ($params{connect}) {
            my $user = "oracle";
            my $env = "";
            if ($ENV{ORACLE_SID}) {
                # Get instance asm_pmon process
                my ($asm_pmon) = grep { $_->{CMD} =~ /^asm_pmon_$ENV{ORACLE_SID}/ }
                    getProcesses(logger => $params{logger});
                $user = $asm_pmon->{USER} if $asm_pmon;
                $env = "ORACLE_SID=$ENV{ORACLE_SID}";
            }
            foreach my $key (qw(ORACLE_HOME ORACLE_BASE LD_LIBRARY_PATH)) {
                next unless $ENV{$key};
                $env .= " " if $env;
                $env .= "$key='$ENV{$key}'";
            }
            if ($env) {
                $command = sprintf("su $user -c '%s %s'", $env, $command);
            } else {
                $command = sprintf("su $user -c '%s'", $command);
            }
            # Make temp file readable by oracle
            if ($params{gid}) {
                chown -1, $params{gid}, $sqlfile;
                chmod 0640, $sqlfile;
            } else {
                chmod 0644, $sqlfile;
            }
        }

        # Write temp SQL file
        print $exec map { "$_\n" } @lines;
        close($exec);
    }

    # Only to support unittests
    if ($params{filebase}) {
        $params{file} = delete $params{filebase};
        $params{file} .= "-";
        $params{file} .= delete $params{name};
        unless ($params{istest}) {
            print STDERR "\nGenerating $params{file} for new Oracle test case...\n";
            system("$command >$params{file}");
        }
    } else {
        $params{command} = $command;
    }

    if (wantarray) {
        return grep { defined($_) && length($_) } map {
            my $line = $_;
            $line =~ s/\r$//;
            $line
        } getAllLines(%params);
    } else {
        my $result = getFirstLine(%params);
        if (defined($result)) {
            chomp($result);
            $result =~ s/\r$//;
        }
        return $result;
    }
}

sub _oracleConnect {
    my ($params, $credential) = @_;

    delete $params->{connect};

    return unless $credential->{type};

    if ($credential->{type} eq "login_password" && $credential->{login} && $credential->{password}) {

        my ($login, $as) = $credential->{login} =~ /^(\S+)(?:\s+AS\s+(\S+))?$/i;

        $as = "SYSDBA" if !$as && $login =~ /^SYS/i;

        my $options = "CONNECT $login";
        $options .= "/".$credential->{password};

        $params->{remote} = 0;
        if ($credential->{socket} && $credential->{socket} =~ /^connect:(.*)$/) {
            $options .= "\@$1";
            $params->{remote} = 1;
        } elsif ($credential->{host}) {
            $options .= "\@$credential->{host}";
            $options .= ":$credential->{port}" if $credential->{port};
            $params->{remote} = 1;
        }
        $options .= " AS $as" if $as;
        $params->{connect} = $options;

    } elsif (!$credential->{type}) {
        $params->{logger}->debug("No type set on oracle credential") if $params->{logger};

    } else {
        my $creds = "type:".$credential->{type};
        $creds .= ";login:".$credential->{login} if $credential->{login};
        if ($credential->{socket}) {
            $creds .= ";socket:".$credential->{socket};
        } elsif ($credential->{host}) {
            $creds .= ";host:".$credential->{host};
            $creds .= ";port:".$credential->{port} if $credential->{port};
        }
        $params->{logger}->debug("Unsupported oracle credential: $creds")
            if $params->{logger};
    }
}

1;
