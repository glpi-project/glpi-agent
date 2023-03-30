package GLPI::Agent::Task::Inventory::Generic::Databases::MySQL;

use English qw(-no_match_vars);

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Generic::Databases';

use GLPI::Agent::Tools;
use GLPI::Agent::Inventory::DatabaseService;

sub isEnabled {
    return canRun('mysql');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    # Try to retrieve credentials updating params
    GLPI::Agent::Task::Inventory::Generic::Databases::_credentials(\%params, "mysql");

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

    foreach my $credential (@{$credentials}) {
        GLPI::Agent::Task::Inventory::Generic::Databases::trying_credentials($params{logger}, $credential);
        # Be sure to forget previous credential option between loops
        delete $params{extra};
        my $extra_file = _mysqlOptionsFile($credential);
        $params{extra} = " --defaults-extra-file=".$extra_file->filename
            if $extra_file;

        my ($name, $manufacturer) = qw(MySQL Oracle);
        my $version = _runSql(
            sql     => "SHOW VARIABLES LIKE 'version'",
            %params
        )
            or next;
        $version =~ s/^version\s*//;
        if ($version =~ /mariadb/i) {
            ($name, $manufacturer) = qw(MariaDB MariaDB);
            $version =~ s/-mariadb//i;
        }

        my $dbs_size = 0;
        my $lastboot = _date(_runSql(
            sql => "SELECT DATE_SUB(now(), INTERVAL variable_value SECOND) from information_schema.global_status where variable_name='Uptime'",
            %params
        ));
        $lastboot = _date(_runSql(
            sql => "SELECT DATE_SUB(now(), INTERVAL variable_value SECOND) from performance_schema.global_status where variable_name='Uptime'",
            %params
        )) unless $lastboot;

        my $dbs = GLPI::Agent::Inventory::DatabaseService->new(
            type            => "mysql",
            name            => $name,
            version         => $version,
            manufacturer    => $manufacturer,
            port            => $credential->{port} // "3306",
            is_active       => 1,
            last_boot_date  => $lastboot,
        );

        foreach my $db (_runSql(
            sql => "SHOW DATABASES",
            %params
        )) {
            my $size = _runSql(
                sql => "SELECT sum(data_length+index_length) FROM information_schema.TABLES WHERE table_schema = '$db'",
                %params
            );
            if ($size =~ /^\d+$/) {
                $dbs_size += $size;
                $size = getCanonicalSize("$size bytes", 1024);
            } else {
                undef $size;
            }

            # Find creation date
            my $created = _date(_runSql(
                sql => "SELECT MIN(create_time) FROM information_schema.TABLES WHERE table_schema = '$db'",
                %params
            ));

            # Find update date
            my $updated = _date(_runSql(
                sql => "SELECT MAX(update_time) FROM information_schema.TABLES WHERE table_schema = '$db'",
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

        $dbs->size(getCanonicalSize("$dbs_size bytes", 1024));

        push @dbs, $dbs;
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

    my $command = "mysql";
    $command .= $params{extra} if defined($params{extra});
    $command .= " -q -sN -e \"$sql\"";

    # Only to support unittests
    if ($params{file}) {
        $sql =~ s/\s+/-/g;
        $sql =~ s/[^-_0-9A-Za-z]//g;
        $sql =~ s/[-][-]+/-/g;
        $params{file} .= "-" . lc($sql);
        unless ($params{istest}) {
            print STDERR "\nGenerating $params{file} for new MySQL test case...\n";
            system("$command >$params{file}");
        }
    } else {
        $params{command} = $command;
    }

    if (wantarray) {
        return map { chomp; $_ } getAllLines(%params);
    } else {
        my $result  = getAllLines(%params);
        chomp($result) if defined($result);
        return $result;
    }
}

sub _mysqlOptionsFile {
    my ($credential) = @_;

    return unless $credential->{type};

    my $fh;
    if ($credential->{type} eq "login_password") {
        File::Temp->require();

        $fh = File::Temp->new(
            TEMPLATE    => 'my-XXXXXX',
            SUFFIX      => '.cnf',
        );
        print $fh "[client]\n";
        print $fh "host = $credential->{host}\n" if $credential->{host};
        print $fh "port = $credential->{port}\n" if $credential->{port};
        print $fh "user = $credential->{login}\n" if $credential->{login};
        print $fh "socket = $credential->{socket}\n" if $credential->{socket};
        if ($credential->{password}) {
            my $password = $credential->{password};
            if ($password =~ /[#'"]/) {
                $password =~ s/"/\\"/g;
                $password = '"'.$password.'"'
            }
            print $fh "password = $password\n";
        }
        print $fh "connect-timeout = 30\n";
        close($fh);
    }

    # Temp file must be deleted out of caller scope
    return $fh;
}

1;
