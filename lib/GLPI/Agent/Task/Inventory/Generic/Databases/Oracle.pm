package GLPI::Agent::Task::Inventory::Generic::Databases::Oracle;

use English qw(-no_match_vars);

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Generic::Databases';

use XML::TreePP;
use File::Temp;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Unix;
use GLPI::Agent::Inventory::DatabaseService;

sub isEnabled {
    return 1 if canRun('sqlplus');
    my $oracle_home = _oracleHome();
    return unless $oracle_home && first {
        canRun("$_/sqlplus") || canRun("$_/bin/sqlplus")
    } @{$oracle_home};
}

sub _oracleHome {
    my (%params) = @_;

    return $ENV{ORACLE_HOME} if $ENV{ORACLE_HOME} && -d $ENV{ORACLE_HOME}
        && !$params{file}; # $params{file} is only set during tests

    my $inventory_loc = getFirstMatch(
        file    => $params{file} // '/etc/oraInst.loc',
        pattern => qr/^inventory_loc=(.*)$/
    )
        or return;

    return unless -d $inventory_loc;

    my $inventory_xml = $inventory_loc . "/ContentsXML/inventory.xml";
    return unless -e $inventory_xml;

    my $tpp = XML::TreePP->new(
        force_array   => [ qw/HOME/ ],
    );
    my $tree = $tpp->parsefile($inventory_xml);
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

sub _getDatabaseService {
    my (%params) = @_;

    my $credentials = delete $params{credentials};
    return [] unless $credentials && ref($credentials) eq 'ARRAY';

    # Setup sqlplus needed environment but not during test
    my %reset_ENV;
    unless ($params{istest}) {
        my $sqlplus = "sqlplus";
        unless (canRun($sqlplus)) {
            $reset_ENV{ORACLE_HOME} = $ENV{ORACLE_HOME};
            $reset_ENV{ORACLE_SID}  = $ENV{ORACLE_SID};
            my $oracle_home = _oracleHome();
            $ENV{ORACLE_HOME} = first {
                canRun("$_/sqlplus") || canRun("$_/bin/sqlplus")
            } @{$oracle_home};
            unless ($ENV{ORACLE_HOME} && -d $ENV{ORACLE_HOME}) {
                $params{logger}->debug("Can't find ORACLE_HOME") if $params{logger};
                return;
            }
            my ($sqlplus_path) = first { canRun($_."/$sqlplus") } map { $ENV{ORACLE_HOME} . $_ } "", "/bin";
            if ($sqlplus_path) {
                $reset_ENV{PATH} = $ENV{PATH};
                $reset_ENV{LD_LIBRARY_PATH} = $ENV{LD_LIBRARY_PATH};
                $ENV{PATH} .= ":$sqlplus_path";
                $ENV{LD_LIBRARY_PATH} = join(":", map { $ENV{ORACLE_HOME}.$_ } "", "/lib", "/network/lib");
                $sqlplus = "$sqlplus_path/$sqlplus";
            }
        }
        return unless canRun($sqlplus);
    }

    # Get group gid of installation group
    my $group = getFirstMatch(
        file    => '/etc/oraInst.loc',
        pattern => qr/^inst_group=(.*)$/
    );
    $params{gid} = getgrnam($group) if $group;

    my @dbs = ();

    foreach my $credential (@{$credentials}) {
        GLPI::Agent::Task::Inventory::Generic::Databases::trying_credentials($params{logger}, $credential);
        _oracleConnect(\%params, $credential);

        my %SID;
        my @instances;
        if ($params{remote} || ! -e '/etc/oratab') {
            @instances = _getInstances(%params);
        } else {
            my @lines = getAllLines(
                file    => '/etc/oratab',
                logger  => $params{logger}
            );
            foreach my $line (@lines) {
                next unless $line =~ /^([^#*:][^:]*):([^:]+):/;
                next unless -d $2;
                $params{logger}->debug2("Checking $1 SID instance...") if $params{logger};
                my @inst = _getInstances(
                    sid     => $1,
                    %params
                );
                next unless @inst;
                foreach my $name (map { /^([^,]+),/ } @inst) {
                    $SID{$name} = $1;
                }
                push @instances, @inst;
            }
        }

        foreach my $instance (@instances) {
            my ($instance_name, $state, $fullversion, $starttime) = split(',', $instance)
                or next;

            # We will use SID if found in oratab
            $params{sid} = $SID{$instance_name} if $SID{$instance_name};

            my $dbs_size = 0;

            my @database = _runSql(
                sql => "SELECT name, "._datefield("created")." FROM v\$database",
                %params
            );
            if (first { /^(ERROR(?: at line 1)?|Usage):/ } @database) {
                my ($error) = first { /^(ORA|SP2)-/ } @database;
                $params{logger}->debug("Oracle database SELECT error: $error") if $error && $params{logger};
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

                $params{logger}->debug2("Checking $db_name database...") if $params{logger};

                my ($size) = _runSql(
                    sql => "select sum(bytes)/1024/1024 from dba_data_files",
                    %params
                );
                $dbs_size += $size if $size && $size =~/^\d+$/;

                # Find update date
                my $updated = _runSql(
                    sql => "SELECT to_char(timestamp, 'YYYY-MM-DD HH24:MI:SS') FROM dba_tab_modifications ORDER BY timestamp DESC FETCH NEXT 1 ROW ONLY",
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
        }
    }

    # Reset set environment
    foreach my $env (keys(%reset_ENV)) {
        if ($reset_ENV{$env}) {
            $ENV{$env} = $reset_ENV{$env};
        } else {
            delete $ENV{$env};
        }
    }

    return \@dbs;
}

sub _getInstances {
    my (%params) = @_;

    my @test = _runSql(
        sql     => "SHOW release",
        %params
    );
    if (first { /^(ERROR|Usage):/ } @test) {
        my ($error) = first { /^(ORA|SP2)-/ } @test;
        $params{logger}->debug("Oracle CONNECT error: $error") if $error && $params{logger};
        return $params{sid}.",FAILURE,0," if $params{sid};
        return;
    }
    return unless @test || $params{sid};
    return $params{sid}.",STOPPED,0," unless @test;
    my ($release) = $test[0] =~ /release (\d+)/;
    return $params{sid}.",STOPPED,0," if $params{sid} && ! $release;
    return unless $release;

    my @instances = _runSql(
        sql => "SELECT instance_name, database_status, version_full, "._datefield("startup_time")." FROM v\$instance",
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

    $ENV{ORACLE_SID} = $params{sid} if $params{sid};

    $params{logger}->debug2("Running sql command via sqlplus: $sql") if $params{logger};

    my $command = "sqlplus -S -L -F";
    $command .= $params{connect} ? " /nolog" : " / AS SYSDBA";

    # Don't try to create the temporary sql file during unittest
    my $exec;
    unless ($params{istest}) {
        # Temp file will be deleted while leaving the function
        $exec = File::Temp->new(
            DIR         => $params{connect} ? '' : '/tmp/',
            TEMPLATE    => 'oracle-XXXXXX',
            SUFFIX      => '.sql',
        );
        my $sqlfile = $exec->filename();
        $command .= ' @'.$sqlfile;

        my @lines = ();
        push @lines, $params{connect} if $params{connect};
        push @lines,
            "SET HEADING OFF",
            "SET MARKUP CSV ON QUOTE OFF",
            $sql.";",
            "QUIT";

        unless ($params{connect}) {
            my $user = "oracle";
            if ($params{sid}) {
                # Get instance asm_pmon process
                my ($asm_pmon) = grep { $_->{CMD} =~ /^asm_pmon_$params{sid}/ }
                    getProcesses(logger => $params{logger});
                $user = $asm_pmon->{USER} if $asm_pmon;
                $command = "ORACLE_SID=$params{sid} $command";
            }

            $command = sprintf("su - $user -c '%s'", $command);
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
    if ($params{file}) {
        $sql =~ s/[ ()\$]+/-/g;
        $sql =~ s/[^-_0-9A-Za-z]//g;
        $sql =~ s/[-][-]+/-/g;
        $params{file} .= "-" . lc($sql);
        unless ($params{istest}) {
            print STDERR "\nGenerating $params{file} for new MSSQL test case...\n";
            system("$command >$params{file}");
        }
    } else {
        $params{command} = $command;
    }

    if (wantarray) {
        return grep { $_ } map {
            my $line = $_;
            chomp($line);
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
