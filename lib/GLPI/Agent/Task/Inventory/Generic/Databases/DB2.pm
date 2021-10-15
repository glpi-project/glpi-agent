package GLPI::Agent::Task::Inventory::Generic::Databases::DB2;

use English qw(-no_match_vars);

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Generic::Databases';

use File::Temp;

use GLPI::Agent::Tools;
use GLPI::Agent::Inventory::DatabaseService;

sub isEnabled {
    return canRun('db2ls');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    # Try to retrieve credentials updating params
    GLPI::Agent::Task::Inventory::Generic::Databases::_credentials(\%params, "db2");

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

    my @dbs = ();
    my %command = ( command => 'db2ls -c' );
    if ($params{file}) {
        my $file = $params{file}.'-db2ls-c';
        system($command{command}." >$file") unless $params{istest};
        %command = ( file => $file );
    }
    my ($db2install, $db2level) = getFirstMatch(
        pattern => qr/^([^#:][^:]+):([^:]+):/,
        %params,
        %command
    )
        or return [];

    # Setup db2 needed environment but not during test
    my %reset_ENV;
    unless ($params{istest}) {
        map { $reset_ENV{$_} = $ENV{$_} } qw(DB2INSTANCE PATH);
        $ENV{PATH} .= ":$db2install/bin";
    }

    my %instuser;
    foreach my $credential (@{$credentials}) {
        GLPI::Agent::Task::Inventory::Generic::Databases::trying_credentials($params{logger}, $credential);
        $params{connect} = _db2Connect($credential) // "";

        # Search for instance users if required
        unless ($params{connect} || keys(%instuser)) {
            my @ent;
            while (@ent = getpwent()) {
                next unless -d $ent[7] && -e $ent[7]."/sqllib/db2profile";
                my $user = $ent[0];
                my $instance = _getUserInstance(
                    runuser => $user,
                    %params
                );
                $instuser{$instance} = $user if $user;
            }
            endpwent();
        }

        my %command = ( command => 'db2ilist' );
        if ($params{file}) {
            my $file = $params{file}.'-db2ilist';
            system($command{command}." >$file") unless $params{istest};
            %command = ( file => $file );
        }
        my @instances = getAllLines(
            %params,
            %command
        );

        foreach my $instance (@instances) {
            my $dbs_size = 0;
            $ENV{DB2INSTANCE} = $instance;

            my $starttime = _getStartTime(
                runuser => $instuser{$instance},
                %params
            );

            my $dbs = GLPI::Agent::Inventory::DatabaseService->new(
                type            => "db2",
                name            => $instance,
                version         => $db2level,
                manufacturer    => "IBM",
                port            => $credential->{port} // "50000",
                is_active       => 1,
                last_boot_date  => $starttime,
            );

            my @databases = _getDatabases(
                sql     => "list db directory",
                %params
            );

            foreach my $name (@databases) {

                my $size = _getDBSize(
                    db      => $name,
                    runuser => $instuser{$instance},
                    %params
                );
                $dbs_size += $size;
                $size = getCanonicalSize("$size bytes", 1024);

                # Find created date
                my $created = _getString(
                    db      => $name,
                    runuser => $instuser{$instance},
                    sql     => "SELECT "._datefield("min(create_time)")." FROM syscat.tables",
                    %params
                );

                # Find update date
                my $updated = _getString(
                    db      => $name,
                    runuser => $instuser{$instance},
                    sql     => "SELECT "._datefield("max(alter_time)")." FROM syscat.tables",
                    %params
                );

                $dbs->addDatabase(
                    name            => $name,
                    size            => $size,
                    is_active       => 1,
                    creation_date   => $created,
                    update_date     => $updated,
                );
            }

            $dbs->size(getCanonicalSize("$dbs_size bytes", 1024));

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

sub _getUserInstance {
    my (%params) = @_;

    my @results = _runSql(
        sql     => "get instance",
        %params
    );

    while (@results) {
        my $line = shift @results;
        if ($line =~ /^SQL\d+N/) {
            $params{logger}->debug2(join("\n","SQLERROR: $line", @results)) if $params{logger};
            last;
        } elsif ($line =~ /The current database manager instance is\s*:\s+(\S+)/) {
            return $1;
        }
    }

    return "";
}

sub _getStartTime {
    my (%params) = @_;

    my @results = _runSql(
        sql     => "get snapshot for dbm",
        %params
    );

    while (@results) {
        my $line = shift @results;
        if ($line =~ /^SQL\d+N/) {
            $params{logger}->debug2(join("\n", "SQLERROR: $line", @results)) if $params{logger};
            last;
        } elsif ($line =~ /^Start Database Manager timestamp\s+=\s+(\d{2})\/(\d{2})\/(\d{4})\s(\d{2}:\d{2}:\d{2})/) {
            return "$3-$2-$1 $4";
        }
    }
    return "";
}

sub _getDatabases {
    my (%params) = @_;

    my @results = _runSql(
        sql     => "list db directory",
        %params
    );

    my @dbs;
    my $id;
    while (@results) {
        my $line = shift @results;
        if ($line =~ /^SQL\d+N/) {
            $params{logger}->debug2(join("\n", "SQLERROR: $line", @results)) if $params{logger};
            last;
        } elsif ($line =~ /^Database (\d+) entry:$/) {
            $id = int($1);
        } elsif ($id && $line =~ /^\sDatabase name\s+=\s+(\S+)$/) {
            push @dbs, $1;
        }
    }
    return @dbs;
}

sub _getDBSize {
    my (%params) = @_;

    my @results = _runSql(
        sql     => "call get_dbsize_info(?,?,?,-1)",
        %params
    );

    my $name;
    while (@results) {
        my $line = shift @results;
        if ($line =~ /^SQL\d+N/) {
            $params{logger}->debug2(join("\n", "SQLERROR: $line", @results)) if $params{logger};
            last;
        } elsif ($line =~ /^\s*Value of output parameters$/) {
            $name = "";
        } elsif (defined($name)) {
            if ($line =~ /^\s+Parameter Name\s+:\s+(\S+)$/) {
                $name = $1;
            } elsif ($line =~ /^\s+Parameter Value\s+:\s+(\d+)$/ && $name eq "DATABASESIZE") {
                return int($1);
            }
        }
    }
    return 0;
}

sub _getString {
    my (%params) = @_;

    my @results = _runSql(%params);

    while (@results) {
        my $line = shift @results;
        next if length($line) == 0 || $line =~ /^\s/;
        if ($line =~ /^SQL\d+N/) {
            $params{logger}->debug2(join("\n", "SQLERROR: $line", @results)) if $params{logger};
            last;
        }
        return trimWhitespace($line);
    }
    return "";
}

sub _datefield {
    my $field = shift;
    return "varchar_format($field, 'YYYY-MM-DD HH24:MI:SS')";
}

sub _runSql {
    my (%params) = @_;

    my $sql = delete $params{sql}
        or return;

    $params{logger}->debug2("Running sql command via db2: $sql") if $params{logger};

    my $command = "db2 -x ";

    # Don't try to create the temporary sql file during unittest
    my $exec;
    unless ($params{istest}) {
        # Temp file will be deleted while leaving the function
        $exec = File::Temp->new(
            DIR         => $params{connect} ? '' : '/tmp/',
            TEMPLATE    => 'db2-XXXXXX',
            SUFFIX      => '.sql',
        );
        my $sqlfile = $exec->filename();
        $command .=  "-f ".$sqlfile;

        my $db = delete $params{db};

        my @lines = ();
        push @lines, $params{connect} if $params{connect};
        push @lines, "CONNECT TO $db" if !$params{connect} && $db;
        push @lines, "$sql";

        if ($params{runuser} && !$params{connect}) {
            $command = sprintf("su - $params{runuser} -c '%s'", $command);
            # Make temp file readable by user
            chmod 0644, $sqlfile;
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
            print STDERR "\nGenerating $params{file} for new DB2 test case...\n";
            system("$command >$params{file}");
        }
    } else {
        $params{command} = $command;
    }

    if (wantarray) {
        return map {
            my $line = $_;
            chomp($line);
            $line =~ s/\r$//g;
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

sub _db2Connect {
    my ($credential) = @_;

    return unless $credential->{type};

    my $connect = "";
    if ($credential->{type} eq "login_password" && $credential->{login} && $credential->{socket} && $credential->{password}) {
        $connect  = "CONNECT TO ".$credential->{socket};
        $connect .= " USER ".$credential->{login};
        $connect .= " USING ".$credential->{password};
    }

    return $connect;
}

1;
