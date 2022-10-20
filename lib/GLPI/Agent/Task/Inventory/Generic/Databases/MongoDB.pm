package GLPI::Agent::Task::Inventory::Generic::Databases::MongoDB;

use English qw(-no_match_vars);

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Generic::Databases';

use Cpanel::JSON::XS;
use English qw(-no_match_vars);
use POSIX qw(strftime);
use File::Temp;

use GLPI::Agent::Tools;
use GLPI::Agent::Inventory::DatabaseService;

sub isEnabled {
    return canRun('mongo') || canRun('mongosh');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    # Try to retrieve credentials updating params
    GLPI::Agent::Task::Inventory::Generic::Databases::_credentials(\%params, "mongodb");

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
    my $logger = $params{logger};

    $params{mongosh} = canRun('mongosh') ? 1 : 0
        unless defined($params{mongosh}); # Needed for tests

    foreach my $credential (@{$credentials}) {
        GLPI::Agent::Task::Inventory::Generic::Databases::trying_credentials($params{logger}, $credential);
        my $rcfile = _mongoRcFile($credential);
        $params{rcfile} = $rcfile->filename if $rcfile;

        # Keep port as we need it to set --port option
        $params{port} = $credential->{port} if $credential->{port};

        my ($name, $manufacturer) = qw(MongoDB MongoDB);
        my $version = _runJs(
            sql     => "db.version()",
            script  => "try { print(db.version()) } catch(e) { print('ERR('+e.codeName+'): <'+e.errmsg+'>') }",
            %params
        )
            or next;

        if ($version !~ /^\d/) {
            $logger->error("Connection failure on "._connectUrl($credential).", $version") if $logger;
            next;
        }

        my $dbs_size = 0;
        my $lastbootmilli = _runJs(
            sql     => "ISODate().getTime()-db.serverStatus().uptimeMillis",
            script  => "t = ISODate().getTime();" .
                "try { s = db.serverStatus({ repl: 0,  metrics: 0, locks: 0 }) } " .
                "catch(e) { s = e } " .
                "if (s.ok) { print(t-s.uptimeMillis) } " .
                "else { print('ERR:('+s.codeName+'): '+s.errmsg) }",
            %params
        )
            or next;

        my $lastboot;
        if ($lastbootmilli !~ /^\d+$/) {
            $logger->error("Failed to get last mongodb boot time, $lastbootmilli") if $logger;
        } else {
            $lastboot = strftime("%Y-%m-%d %H:%M:%S", gmtime(int($lastbootmilli/1000)));
        }

        my $dbs = GLPI::Agent::Inventory::DatabaseService->new(
            type            => "mongodb",
            name            => $name,
            version         => $version,
            manufacturer    => $manufacturer,
            port            => $credential->{port} // 27017,
            is_active       => 1,
            last_boot_date  => $lastboot,
        );

        my @databases;
        my $databases = join('', _runJs(
            sql     => "db.adminCommand( { listDatabases: 1 } ).databases",
            script  => "try { l = db.adminCommand( { listDatabases: 1 } ) } " .
                "catch(e) { l = e } " .
                "if (l.ok) { print(".
                ($params{mongosh} ? "EJSON.stringify" : "tojson") . "(l.databases)) } " .
                "else { print('ERR('+l.codeName+'): '+l.errmsg) }",
            %params
        ))
            or next;
        if ($databases =~ /^ERR/) {
            $logger->error("Failed to get database list, $databases") if $logger;
        } else {
            # Cleanup any "Implicit session header"
            $databases =~ s/^Implicit \s+ session: \s+ session \s+ { [^}]+ } \s*//x;
            eval {
                @databases = grep { ref($_) eq 'HASH' } @{ decode_json($databases) };
            };
            if ($EVAL_ERROR) {
                $logger->error("Can't decode database list: $databases".($databases =~ /^\[/ ? "\n".$EVAL_ERROR : ""))
                    if $logger;
            }

            foreach my $dbinfo (@databases) {
                my $db = $dbinfo->{name}
                    or next;
                my $size = $dbinfo->{sizeOnDisk}
                    or next;

                if ($size) {
                    $dbs_size += $size;
                    $size = getCanonicalSize("$size bytes", 1024);
                } else {
                    undef $size;
                }

                my $ping = _runJs(
                    sql     => "db.getSiblingDB('$db').runCommand({'ping': 1}).ok",
                    script  => "try { print(db.getSiblingDB('$db').runCommand({'ping': 1}).ok) } " .
                        "catch(e) { print('ERR('+e.codeName+'): '+e.errmsg) }",
                    %params
                );
                my $status = 0;
                if (!defined($ping) || $ping !~ /^\d+$/) {
                    $logger->error("Failed to get $db database status, ".($ping // "request failure")) if $logger;
                } else {
                    $status = $ping;
                }

                $dbs->addDatabase(
                    name            => $db,
                    size            => $size,
                    is_active       => $status,
                );
            }
        }

        $dbs->size(getCanonicalSize("$dbs_size bytes", 1024));

        push @dbs, $dbs;

        # Always forget rcfile and port
        delete $params{rcfile};
        delete $params{port};
    }

    return \@dbs;
}

sub _date {
    my ($date) = @_
        or return;
    $date =~ /^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})/;
    return $1;
}

sub _runJs {
    my (%params) = @_;

    my $sql = delete $params{sql}
        or return;
    my $script = delete $params{script}
        or return;

    my $rcfile = delete $params{rcfile};
    my $command = "mongo";
    $command .= "sh" if $params{mongosh};
    $command .= " --quiet";
    $command .= " --nodb --norc $rcfile" if $rcfile;

    my $fh = File::Temp->new(
        TEMPLATE    => 'mongocmd-XXXXXXXX',
        SUFFIX      => '.js',
    );

    # Mongosh must be instructed to output JSON like mongo does before
    $params{logger}->debug("Requesting: $sql") if $params{logger};
    print $fh $script;
    close($fh);
    $command .= " " . $fh->filename;

    # Only to support unittests
    if ($params{file}) {
        $sql =~ s/[ .]+/-/g;
        $sql =~ s/[^-_0-9A-Za-z]//g;
        $sql =~ s/[-][-]+/-/g;
        $params{file} .= "-" . lc($sql);
        unless ($params{istest}) {
            print STDERR "\nGenerating $params{file} for new MongoDB test case...\n";
            system("$command >$params{file}");
        }
    } else {
        $params{command} = $command;
    }

    if (wantarray) {
        return map { chomp; $_ } grep { $_ !~ /^(loading file|connecting to|MongoDB server version):/ } getAllLines(%params);
    } else {
        return getLastLine(%params);
    }
}

sub _connectUrl {
    my ($credential) = @_;

    return $credential->{socket} if $credential->{socket};

    my $conn = $credential->{host} // "localhost";
    $conn .= ":".($credential->{port} // "27017");

    # Always default to connect on "admin" database
    $conn .= "/admin";

    return $conn;
}

sub _mongoRcFile {
    my ($credential) = @_;

    return unless $credential->{type};

    my $fh;
    if ($credential->{type} eq "login_password") {
        $fh = File::Temp->new(
            TEMPLATE    => 'mongorc-XXXXXXXX',
            SUFFIX      => '.js',
        );
        my $conn = _connectUrl($credential);
        if ($credential->{login}) {
            $conn .= "','" . $credential->{login};
            if ($credential->{password}) {
                my $password = $credential->{password};
                $password =~ s/'/\\'/g;
                $conn .= "','" . $password;
            }
        }
        print $fh "try { db = connect('$conn') }\n";
        print $fh "catch(e) { print('ERR('+e.codeName+'): '+e.errmsg); exit(1) }\n";
        close($fh);
    }

    # Temp file must be deleted out of caller scope
    return $fh;
}

1;
