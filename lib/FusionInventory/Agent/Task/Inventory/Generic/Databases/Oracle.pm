package FusionInventory::Agent::Task::Inventory::Generic::Databases::Oracle;

use English qw(-no_match_vars);

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Generic::Databases';

use XML::TreePP;
use File::Temp;

use FusionInventory::Agent::Tools;
use GLPI::Agent::Inventory::DatabaseService;

sub isEnabled {
    return 1 if canRun('sqlplus');
    my $oracle_home = _oracleHome();
    return unless $oracle_home && (canRun($oracle_home.'/sqlplus') || canRun($oracle_home.'/bin/sqlplus'));
}

sub _oracleHome {
    my $inventory_loc = getFirstMatch(
        file    => '/etc/oraInst.loc',
        pattern => qr/^inventory_loc=(.*)$/
    )
        or return;

    return unless -d $inventory_loc;

    my $inventory_xml = $inventory_loc . "/ContentsXML/inventory.xml";
    return unless -e $inventory_xml;

    my $tpp = XML::TreePP->new();
    my $tree = $tpp->parsefile($inventory_xml);
    return unless $tree && $tree->{INVENTORY} && $tree->{INVENTORY}->{HOME_LIST}
        && $tree->{INVENTORY}->{HOME_LIST}->{HOME};
    return $tree->{INVENTORY}->{HOME_LIST}->{HOME}->{"-LOC"};
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    # Try to retrieve credentials updating params
    FusionInventory::Agent::Task::Inventory::Generic::Databases::_credentials(\%params, "oracle");

    # Setup sqlplus needed environment
    unless (canRun("sqlplus")) {
        $ENV{ORACLE_HOME} = _oracleHome();
        $ENV{PATH} .= ":".$ENV{ORACLE_HOME}.(canRun($ENV{ORACLE_HOME}."/bin/sqlplus")?"/bin":"");
        $ENV{LD_LIBRARY_PATH} = join(":", map { $ENV{ORACLE_HOME}."/$_" } qw(. lib network/lib));
    }
    return unless canRun("sqlplus");

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

    # Get group gid of installation group
    my $group = getFirstMatch(
        file    => '/etc/oraInst.loc',
        pattern => qr/^inst_group=(.*)$/
    );
    $params{gid} = getgrnam($group) if $group;

    my @dbs = ();

    foreach my $credential (@{$credentials}) {
        $params{connect} = _oracleConnect($credential) // "";

        next unless _runSql(
            sql     => "SHOW release",
            %params
        );

        foreach my $instance (_runSql(
            sql => "SELECT instance_name, database_status, version_full, "._datefield("startup_time")." FROM v\$instance",
            %params
        )) {
            my ($instance_name, $state, $fullversion, $starttime) = split(',', $instance)
                or next;
            next unless $fullversion;

            my $dbs_size = 0;

            my $dbs = GLPI::Agent::Inventory::DatabaseService->new(
                type            => "oracle",
                name            => $instance_name,
                version         => $fullversion,
                manufacturer    => "Oracle",
                port            => $credential->{port} // "1521",
                is_active       => $state && $state =~ /^ACTIVE$/i ? 1 : 0,
                last_boot_date  => $starttime,
            );

            foreach my $db (_runSql(
                sql => "SELECT name, "._datefield("created")." FROM v\$database",
                %params
            )) {
                my ($db_name, $created) = split(',', $db)
                    or next;

                my ($size) = _runSql(
                    sql => "select sum(bytes)/1024/1024 from dba_data_files",
                    %params
                );
                $dbs_size += $size if $size;

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

    return \@dbs;
}

sub _datefield {
    my $field = shift;
    return "to_char($field,'YYYY-MM-DD HH24:MI:SS')";
}

sub _runSql {
    my (%params) = @_;

    my $sql = delete $params{sql}
        or return;

    my $command .= "sqlplus -S -L -F";
    $command .= $params{connect} ? " /nolog" : " / AS SYSDBA";

    my $exec = File::Temp->new(
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
        $command = sprintf("su oracle -c '%s'", $command);
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

    # Only to support unittests
    if ($params{file}) {
        $sql =~ s/\s+/-/g;
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
        return map {
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
    my ($credential) = @_;

    return unless $credential->{type};

    my $options = "";
    if ($credential->{type} eq "login_password" && $credential->{login}) {

        my ($login, $as) = $credential->{login} =~ /^(.*)(?:\s+AS\s+(.*))?$/i;

        $options  = "CONNECT $login";
        $options .= "/".$credential->{password} if $credential->{password};
        $options .= "\@$credential->{host}" if $credential->{host};
        $options .= ":$credential->{port}" if $credential->{host} && $credential->{port};
        $options .= "AS $as" if $as;
    }

    return $options;
}

1;
