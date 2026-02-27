package GLPI::Agent::Task::Inventory::Generic::Databases::PostgreSQL;

use English qw(-no_match_vars);

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Generic::Databases';

use version;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Unix;
use GLPI::Agent::Inventory::DatabaseService;

sub isEnabled {
    return canRun('psql');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    # Try to retrieve credentials updating params
    GLPI::Agent::Task::Inventory::Generic::Databases::_credentials(\%params, "postgresql");

    my $dbservices = _getDatabaseService(%params);

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

    # Still cleanup PG environment
    delete $ENV{PGPASSFILE};

    # List of instance to loop on when using default credentials
    my @instances;

    my ($uid, $cansudo);

    foreach my $credential (@{$credentials}) {
        unless (@instances) {
            GLPI::Agent::Task::Inventory::Generic::Databases::trying_credentials($params{logger}, $credential);
            my $passfile = _psqlPgpassFile($credential);
            $ENV{PGPASSFILE} = $passfile->filename if $passfile;
        }

        delete $params{sudo};

        $params{options} = "";
        $params{options} .= " -h \"$credential->{host}\""  unless empty($credential->{host});
        $params{options} .= " -p $credential->{port}"      if $credential->{port} && $credential->{port} =~ /^\d+$/;
        $params{options} .= " -U \"$credential->{login}\"" unless empty($credential->{login});

        unless ($params{options}) {

            # List postgresql processes and analyze parameters
            unless (@instances) {
                @instances = getProcesses(
                    filter    => qr/(?:postgres|postmaster)\s/,
                    checkexe  => qr/(?:postgres|postmaster)$/,
                    namespace => "same",
                    logger    => $params{logger}
                );
            }

            my $user = "postgres";
            my $cmd;
            if (@instances) {
                my $instance = shift @instances;
                # Filter out possible command injection try
                if ($instance->{CMD} && $instance->{CMD} !~ /[;"&|`\$<>[:cntrl:]]/) {
                    $user = $instance->{USER};
                    $cmd = $instance->{CMD};
                    unless (defined($uid)) {
                        $uid = getFirstLine(command => "id -u");
                        if (canRun("sudo")) {
                            my $sudo = getFirstLine(command => "sudo -nu $user echo true");
                            $cansudo = $sudo && $sudo eq "true";
                        }
                    }
                }
            }

            if (defined($uid) && $uid eq "0") {
                $params{sudo} = 'su '.$user.' -c "%s"';
            } elsif ($cansudo) {
                $params{sudo} = 'sudo -nu '.$user.' %s';
            }

            if ($cmd && $params{sudo}) {
                my $request = sprintf($params{sudo}, "$cmd -C unix_socket_directories");
                my $unix_socket_directories = getFirstLine(command => $request, logger => $params{logger});
                $params{options} = " -h \"$unix_socket_directories\""
                    unless empty($unix_socket_directories);
            }
        }

        my ($name, $manufacturer) = qw(PostgreSQL PostgreSQL);
        my $server_version = _runSql(
            sql     => "SHOW server_version",
            %params
        )
            or next;

        my ($version) = $server_version =~ /^([0-9.]+)/
            or next;

        # name should be set to cluster name
        unless (version->parse($version =~ /^\d/ ? "v$version" : $version) < version->parse("v9.5")) {
            my $clustername = _runSql(
                sql     => "SHOW cluster_name",
                %params
            );
            $name = $clustername unless empty($clustername);
        }

        my $dbs_size = 0;
        my $lastboot = _date(_runSql(
            sql => "SELECT pg_postmaster_start_time()",
            %params
        ));

        my $dbs = GLPI::Agent::Inventory::DatabaseService->new(
            type            => "postgresql",
            name            => $name,
            version         => $version,
            manufacturer    => $manufacturer,
            port            => $credential->{port} // 5432,
            is_active       => 1,
            last_boot_date  => $lastboot,
        );

        foreach my $dbinfo (_runSql(
            sql => "SELECT datname,oid FROM pg_database",
            %params
        )) {
            my ($db, $oid) = split(",",$dbinfo);
            my $size = _runSql(
                sql => "SELECT pg_size_pretty(pg_database_size('$db'))",
                %params
            );
            if ($size) {
                $size = getCanonicalSize($size, 1024);
                $dbs_size += $size;
            } else {
                undef $size;
            }

            # Find creation date
            my $created = _date(_runSql(
                sql => "SELECT (pg_stat_file('base/$oid/PG_VERSION')).modification FROM pg_database",
                %params
            ));

            # Find update date
            my $updated = _date(_runSql(
                sql => "SELECT (pg_stat_file('base/$oid')).modification FROM pg_database",
                %params
            ));

            $dbs->addDatabase(
                name            => $db,
                size            => $size,
                is_active       => 1,
                creation_date   => $created,
                update_date     => $updated,
            );
        }

        $dbs->size($dbs_size) if $dbs_size;

        push @dbs, $dbs;

        # Cleanup PG environment
        delete $ENV{PGPASSFILE};

        redo if @instances;
    }

    return \@dbs;
}

sub _date {
    my ($date) = @_
        or return;
    $date =~ /^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})/;
    return $1;
}

sub _runSql {
    my (%params) = @_;

    my $sql = delete $params{sql}
        or return;

    my $options = delete $params{options};
    my $command = "psql".$options;
    $command .= " -Anqtw -F, -c \"$sql\" connect_timeout=30";
    if ($params{sudo}) {
        my $sudo = delete $params{sudo};
        $command =~ s/"/\\"/g if $sudo =~ /^su /;
        $command = sprintf($sudo, $command);
    }

    # Only to support unittests
    if ($params{file}) {
        $sql =~ s/\s+/-/g;
        $sql =~ s/[^-_0-9A-Za-z]//g;
        $sql =~ s/[-][-]+/-/g;
        $params{file} .= "-" . lc($sql);
        unless ($params{istest}) {
            print STDERR "\nGenerating $params{file} for new PostgreSQL test case...\n";
            system("$command >$params{file}");
        }
    } else {
        $params{command} = $command;
    }

    if (wantarray) {
        return map { chomp; $_ } getAllLines(%params);
    } else {
        my $result  = getFirstLine(%params);
        return unless defined($result);
        chomp($result);
        return $result;
    }
}

sub _psqlPgpassFile {
    my ($credential) = @_;

    return unless $credential->{type};

    my $fh;
    if ($credential->{type} eq "login_password" && $credential->{password}) {
        File::Temp->require();

        $fh = File::Temp->new(
            TEMPLATE    => 'pgpass-XXXXXX',
            SUFFIX      => '.conf',
            PERMS       => 0600, ## no critic
        );
        print $fh join(":",
            $credential->{host} || "*",
            $credential->{port} || "*",
            "*",
            $credential->{login} || "*",
            $credential->{password}
        ), "\n";
        close($fh);
    }

    # Temp file must be deleted out of caller scope
    return $fh;
}

1;
