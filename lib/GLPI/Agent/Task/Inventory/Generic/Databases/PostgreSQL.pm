package GLPI::Agent::Task::Inventory::Generic::Databases::PostgreSQL;

use English qw(-no_match_vars);

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Generic::Databases';

use GLPI::Agent::Tools;
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

    foreach my $credential (@{$credentials}) {
        GLPI::Agent::Task::Inventory::Generic::Databases::trying_credentials($params{logger}, $credential);
        my $passfile = _psqlPgpassFile($credential);
        $ENV{PGPASSFILE} = $passfile->filename if $passfile;

        delete $params{sudo};

        $params{options} = "";
        $params{options} .= " -h '$credential->{host}'"  if $credential->{host};
        $params{options} .= " -p $credential->{port}"    if $credential->{port};
        $params{options} .= " -U '$credential->{login}'" if $credential->{login};

        unless ($params{options}) {
            my $id = getFirstLine(command => "id -u");
            if (defined($id) && $id eq "0") {
                $params{sudo} = 'su postgres -c "%s"';
            } elsif (canRun("sudo")) {
                my $sudo = getFirstLine(command => "sudo -nu postgres echo true");
                if ($sudo && $sudo eq "true") {
                    $params{sudo} = 'sudo -nu postgres %s';
                }
            }
        }

        my ($name, $manufacturer) = qw(PostgreSQL PostgreSQL);
        my $version = _runSql(
            sql     => "SHOW server_version",
            %params
        )
            or next;

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
    if (!$options) {
        my $sudo = delete $params{sudo};
        $command =~ s/"/\\"/g if $sudo && $sudo =~ /^su /;
        $command = sprintf($sudo, $command) if $sudo;
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
