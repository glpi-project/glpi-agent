package FusionInventory::Agent::Task::Inventory::Generic::Databases::MySQL;

use English qw(-no_match_vars);

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Generic::Databases';

use POSIX qw(strftime);

use FusionInventory::Agent::Tools;
use GLPI::Agent::Inventory::DatabaseService;

sub isEnabled {
    return canRun('mysql');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    # Try to retrieve credentials
    $params{credentials} = FusionInventory::Agent::Task::Inventory::Generic::Databases::_credentials(\%params, "mysql");

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

    return [] unless $params{credentials};

    my @dbs = ();

    $params{index} = 0;
    foreach my $credential (@{$params{credentials}}) {
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
        my ($uptime) = _runSql(
                sql => "SHOW GLOBAL STATUS LIKE 'Uptime'",
                %params
        ) =~ /^Uptime\s(\d+)$/i;
        my $lastboot = strftime("%F %T", localtime(time - $uptime));

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
            my $created = _runSql(
                sql => "SELECT MIN(create_time) FROM information_schema.TABLES WHERE table_schema = '$db'",
                %params
            );

            # Find update date
            my $updated = _runSql(
                sql => "SELECT MAX(update_time) FROM information_schema.TABLES WHERE table_schema = '$db'",
                %params
            );

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

        # Loop on next credential
        $params{index}++;
    }

    return \@dbs;
}

sub _runSql {
    my (%params) = @_;

    my $sql = delete $params{sql}
        or return;

    my $credential = $params{credentials}->[$params{index}]
        or return;

    my $options = "";
    if ($credential->{type} && $credential->{type} eq "login_password") {
        $options .= " --port=$credential->{port}" if $credential->{port};
        $options .= " --user=$credential->{login}" if $credential->{login};
        $options .= " --password=$credential->{password}" if $credential->{password};
    }
    my $command = "mysql $options -q -sN -e \"$sql\"";

    # Only to support unittests
    if ($params{file}) {
        $sql =~ s/\s+/-/g;
        $sql =~ s/[^-_0-9A-Za-z]//g;
        $sql =~ s/[-][-]+/-/g;
        $params{file} .= "-" . lc($sql);
        unless (-e $params{file}) {
            print STDERR "Generating $params{file} for new MySQL test case...\n";
            system("$command >$params{file}");
        }
    } else {
        my $options = "";
        $params{command} = "mysql $options -q -sN -e \"$sql\""
    }

    if (wantarray) {
        return map { chomp; $_ } getAllLines(%params);
    } else {
        my $result  = getAllLines(%params);
        chomp($result);
        return $result;
    }
}

1;
