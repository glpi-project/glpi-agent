package FusionInventory::Agent::Task::Inventory::Generic::Databases::MySQL;

use English qw(-no_match_vars);

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use POSIX qw(strftime);

use FusionInventory::Agent::Tools;
use GLPI::Agent::Inventory::Database;

sub isEnabled {
    return canRun('mysql');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $database (_getDatabases(%params)) {
        $inventory->addEntry(
            section => 'DATABASES',
            entry   => $database->entry(),
        );
    }
}

my $credential;

sub _getDatabases {
    my (%params) = @_;

    my @databases = ();

    my @credentials = (
        {},
    );

    foreach $credential (@credentials) {
        my ($name, $manufacturer) = qw(MySQL Oracle);
        my $version = _runSql("SHOW VARIABLES LIKE 'version'");
        $version =~ s/^version\s*//;
        if ($version =~ /mariadb/i) {
            ($name, $manufacturer) = qw(MariaDB MariaDB);
            $version =~ s/-mariadb//i;
        }

        my $database = GLPI::Agent::Inventory::Database->new(
            type            => "mysql",
            name            => $name,
            version         => $version,
            manufacturer    => $manufacturer,
        );

        my ($uptime) = _runSql("SHOW GLOBAL STATUS LIKE 'Uptime'") =~ /^Uptime\s(\d+)$/i;
        my $lastboot = strftime("%F %T", localtime(time - $uptime));
        foreach my $db (_runSql("SHOW DATABASES")) {
            # Don't reference mysql dedicated databases
            next if $db =~ /^information_schema|mysql|performance_schema$/;

            my $size = _runSql("SELECT sum(data_length+index_length) FROM
                information_schema.TABLES WHERE table_schema = '$db'");
            if ($size =~ /^\d+$/) {
                $size = int($size);
            } else {
                undef $size;
            }

            # Find creation date
            my $created = _runSql("SELECT MIN(create_time) FROM
                information_schema.TABLES WHERE table_schema = '$db'");
            $database->wasCreated($created);

            # Find update date
            my $updated = _runSql("SELECT MAX(update_time) FROM
                information_schema.TABLES WHERE table_schema = '$db'");
            $database->wasUpdated($updated);

            $database->addInstance(
                name            => $db,
                port            => $credential->{port} // "3306",
                size            => $size,
                is_active       => 1,
                last_boot_date  => $lastboot,
            );
        }
        push @databases, $database;
    }

    return @databases;
}

sub _runSql {
    my ($sql) = @_;

    my $options = "";
    my $command = "mysql $options -q -sN -e \"$sql\"";
    return getAllLines(command => $command);
}

1;
