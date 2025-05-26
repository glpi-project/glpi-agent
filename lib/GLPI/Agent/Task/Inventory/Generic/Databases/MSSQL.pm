package GLPI::Agent::Task::Inventory::Generic::Databases::MSSQL;

use English qw(-no_match_vars);

use strict;
use warnings;

use UNIVERSAL::require;

use parent 'GLPI::Agent::Task::Inventory::Generic::Databases';

use GLPI::Agent::Tools;
use GLPI::Agent::Inventory::DatabaseService;

sub isEnabled {
    return canRun('sqlcmd') ||
        canRun('/opt/mssql-tools/bin/sqlcmd');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    # Try to retrieve credentials updating params
    GLPI::Agent::Task::Inventory::Generic::Databases::_credentials(\%params, "mssql");

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

    # Handle default credentials case
    if (@{$credentials} == 1 && !keys(%{$credentials->[0]})) {
        # On windows, we can discover instance names in registry
        if (OSNAME eq 'MSWin32') {
            GLPI::Agent::Tools::Win32->require();
            my $instances = GLPI::Agent::Tools::Win32::getRegistryKey(
                path => 'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Microsoft SQL Server/Instance Names/SQL',
            );
            foreach my $key (%{$instances}) {
                # Only consider valuename keys
                my ($instance) = $key =~ m{^/(.+)$}
                    or next;
                # Default credentials will still match MSSQLSERVER instance
                next if $instance eq 'MSSQLSERVER';
                push @{$credentials}, {
                    type        => "_discovered_instance",
                    instance    => $instance,
                };
            }
        }
        # Add SQLExpress default credential when trying default credential
        push @{$credentials}, {
            type    => "login_password",
            socket  => "localhost\\SQLExpress",
        };
    }

    my @dbs = ();

    # Support sqlcmd on linux with standard full path for command from mssql-tools package
    $params{sqlcmd} = '/opt/mssql-tools/bin/sqlcmd'
        unless canRun('sqlcmd');

    foreach my $credential (@{$credentials}) {
        GLPI::Agent::Task::Inventory::Generic::Databases::trying_credentials($params{logger}, $credential);
        $params{options} = _mssqlOptions($credential) // "-l 5";

        my $productversion = _runSql(
            sql     => "SELECT SERVERPROPERTY('productversion')",
            %params
        )
            or next;

        my $name =_runSql(
            sql     => "SELECT \@\@servicename",
            %params
        )
            or next;

        my $version =_runSql(
            sql     => "SELECT \@\@version",
            %params
        )
            or next;
        my ($manufacturer) = $version =~ /^
            (Microsoft) \s+
            SQL \s+ Server \s+ \d+
        /xi
            or next;

        my $dbs_size = 0;
        my $starttime = _runSql(
            sql => "SELECT sqlserver_start_time FROM sys.dm_os_sys_info",
            %params
        );
        $starttime =~ s/\..*$//;

        my $dbs = GLPI::Agent::Inventory::DatabaseService->new(
            type            => "mssql",
            name            => $name,
            version         => $productversion,
            manufacturer    => $manufacturer,
            port            => $credential->{port} // "1433",
            is_active       => 1,
            last_boot_date  => $starttime,
        );

        foreach my $db (_runSql(
            sql => "SELECT name,create_date,state FROM sys.databases",
            %params
        )) {
            my ($db_name, $db_create, $state) = $db =~ /^(\S+);([^.]*)\.\d+;(\d+)$/
                or next;

            my ($size) = _runSql(
                sql => "USE [$db_name] ; EXEC sp_spaceused",
                %params
            ) =~ /^$db_name;([0-9.]+\s*\S+);/;
            if ($size) {
                $size = getCanonicalSize($size, 1024);
                $dbs_size += $size;
            } else {
                undef $size;
            }

            # Find update date
            my ($updated) = _runSql(
                sql => "USE [$db_name] ; SELECT TOP(1) modify_date FROM sys.objects ORDER BY modify_date DESC",
                %params
            ) =~ /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/;

            $dbs->addDatabase(
                name            => $db_name,
                size            => int($size),
                is_active       => int($state) == 0 ? 1 : 0,
                creation_date   => $db_create,
                update_date     => $updated,
            );
        }

        $dbs->size(int($dbs_size));

        push @dbs, $dbs;
    }

    return \@dbs;
}

sub _runSql {
    my (%params) = @_;

    my $sql = delete $params{sql}
        or return;

    my $command = $params{sqlcmd} // "sqlcmd";
    $command .= " ".$params{options} if defined($params{options});
    $command .= " -X1 -t 30 -K ReadOnly -r1 -W -h -1 -s \";\" -Q \"$sql\"";

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

sub _mssqlOptions {
    my ($credential) = @_;

    return unless $credential->{type};

    my $options = "-l 5";
    if ($credential->{type} eq "login_password") {
        if ($credential->{host}) {
            $options  = "-l 30";
            $options .= " -S $credential->{host}" ;
            $options .= ",$credential->{port}" if $credential->{port};
        }
        $options .= " -U $credential->{login}" if $credential->{login};
        $options .= " -S $credential->{socket}" if ! $credential->{host} && $credential->{socket};
        if ($credential->{password}) {
            $credential->{password} =~ s/"/\\"/g;
            $options .= ' -P "'.$credential->{password}.'"' ;
        }
    } elsif ($credential->{type} eq "_discovered_instance" && $credential->{instance}) {
        $options .= " -S .\\$credential->{instance}" ;
    }

    return $options;
}

1;
