package FusionInventory::Agent::Task::Inventory::Generic::Databases::MySQL;

use English qw(-no_match_vars);

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use POSIX qw(strftime);

use FusionInventory::Agent::Tools;
use GLPI::Agent::Inventory::DatabaseService;

sub isEnabled {
    return canRun('mysql');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $dbservices = _getDatabaseService(%params);

    foreach my $dbs (@{$dbservices}) {
        $inventory->addEntry(
            section => 'DATABASES_SERVICES',
            entry   => $dbs->entry(),
        );
    }
}

my $credential;

sub _getDatabaseService {
    my (%params) = @_;

    my @dbs = ();

    my @credentials = (
        {},
    );

    foreach $credential (@credentials) {
        my ($name, $manufacturer) = qw(MySQL Oracle);
        my $version = _runSql("SHOW VARIABLES LIKE 'version'")
            or next;
        $version =~ s/^version\s*//;
        if ($version =~ /mariadb/i) {
            ($name, $manufacturer) = qw(MariaDB MariaDB);
            $version =~ s/-mariadb//i;
        }

        my $dbs_size = 0;
        my ($uptime) = _runSql("SHOW GLOBAL STATUS LIKE 'Uptime'") =~ /^Uptime\s(\d+)$/i;
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

        foreach my $db (_runSql("SHOW DATABASES")) {
            my $size = _runSql("SELECT sum(data_length+index_length) FROM
                information_schema.TABLES WHERE table_schema = '$db'");
            if ($size =~ /^\d+$/) {
                $size = int($size);
                $dbs_size += $size;
            } else {
                undef $size;
            }

            # Find creation date
            my $created = _runSql("SELECT MIN(create_time) FROM
                information_schema.TABLES WHERE table_schema = '$db'");

            # Find update date
            my $updated = _runSql("SELECT MAX(update_time) FROM
                information_schema.TABLES WHERE table_schema = '$db'");

            $dbs->addDatabase(
                name            => $db,
                size            => $size,
                is_active       => 1,
                creation_date   => $created,
                update_date     => $updated,
            );
        }

        $dbs->size($dbs_size);

        push @dbs, $dbs;
    }

    return \@dbs;
}

sub _runSql {
    my ($sql) = @_;

    my $options = "";
    my $command = "mysql $options -q -sN -e \"$sql\"";
    return getAllLines(command => $command);
}

1;
