package
    Getopt;

use strict;
use warnings;

BEGIN {
    $INC{"Getopt.pm"} = __FILE__;
}

my @options = (
    'backend-collect-timeout=i',
    'ca-cert-file=s',
    'clean',
    'color',
    'cron=i',
    'debug|d=i',
    'distro=s',
    'no-question|Q',
    'extract=s',
    'force',
    'help|h',
    'install',
    'list',
    'local|l=s',
    'logger=s',
    'logfacility=s',
    'logfile=s',
    'no-httpd',
    'no-ssl-check',
    'no-category=s',
    'no-compression|C',
    'no-task=s',
    'no-p2p',
    'password|p=s',
    'proxy|P=s',
    'httpd-ip=s',
    'httpd-port=s',
    'httpd-trust=s',
    'reinstall',
    'remote=s',
    'remote-workers=i',
    'runnow',
    'scan-homedirs',
    'scan-profiles',
    'server|s=s',
    'service=i',
    'silent|S',
    'skip=s',
    'snap',
    'ssl-fingerprint=s',
    'tag|t=s',
    'tasks=s',
    'type=s',
    'uninstall',
    'unpack',
    'user|u=s',
    'use-current-user-proxy',
    'verbose|v',
    'version',
);

my %options;
foreach my $opt (@options) {
    my ($plus)   = $opt =~ s/\+$//;
    my ($string) = $opt =~ s/=s$//;
    my ($int)    = $opt =~ s/=i$//;
    my ($long, $short) = $opt =~ /^([^|]+)[|]?(.)?$/;
    $options{"--$long"} = [ $plus, $string, $int, $long ];
    $options{"-$short"} = $options{"--$long"} if $short;
}

sub GetOptions {

    my $options = {};

    my ($plus, $string, $int, $long);

    while (@ARGV) {
        my $argv = shift @ARGV;
        if ($argv =~ /^(-[^=]*)=?(.+)?$/) {
            my $opt = $options{$1}
                or return;
            ( $plus, $string, $int, $long) = @{$opt};
            if ($plus) {
                $options->{$long}++;
                undef $long;
            } elsif (defined($2) && $int) {
                $options->{$long} = int($2);
                undef $long;
            } elsif ($string) {
                $options->{$long} = $2;
            } else {
                $options->{$long} = 1;
                undef $long;
            }
        } elsif ($long) {
            if ($int) {
                $options->{$long} = int($argv);
                undef $long;
            } elsif ($string) {
                $options->{$long} .= " " if $options->{$long};
                $options->{$long} .= $argv;
            }
        } else {
            return;
        }
    }

    return $options;
}

sub Help {
    return  <<'HELP';
glpi-agent-linux-installer [options]

  Target definition options:
    -s --server=URI                configure agent GLPI server
    -l --local=PATH                configure local path to store inventories

  Task selection options:
    --no-task=TASK[,TASK]...       configure task to not run
    --tasks=TASK1[,TASK]...[,...]  configure tasks to run in a given order

  Inventory task specific options:
    --no-category=CATEGORY         configure category items to not inventory
    --scan-homedirs                set to scan user home directories (false)
    --scan-profiles                set to scan user profiles (false)
    --backend-collect-timeout=TIME set timeout for inventory modules execution (30)
    -t --tag=TAG                   configure tag to define in inventories

  RemoteInventory specific options:
    --remote=REMOTE[,REMOTE]...    list of remotes for remoteinventory task
    --remote-workers=COUNT         maximum number of workers for remoteinventory task

  Package deployment task specific options:
    --no-p2p                       set to not use peer to peer to download
                                   deploy task packages

  Network options:
    -P --proxy=PROXY               proxy address
    --use-current-user-proxy       Configure proxy address from current user environment (false)
                                   and only if --proxy option is not used
    --ca-cert-file=FILE            CA certificates file
    --no-ssl-check                 do not check server SSL certificate (false)
    -C --no-compression            do not compress communication with server (false)
    --ssl-fingerprint=FINGERPRINT  Trust server certificate if its SSL fingerprint
                                   matches the given one
    -u --user=USER                 user name for server authentication
    -p --password=PASSWORD         password for server authentication

  Web interface options:
    --no-httpd                     disable embedded web server (false)
    --httpd-ip=IP                  set network interface to listen to (all)
    --httpd-port=PORT              set network port to listen to (62354)
    --httpd-trust=IP               list of IPs to trust (GLPI server only by default)

  Logging options:
    --logger=BACKEND               configure logger backend (stderr)
    --logfile=FILE                 configure log file path
    --logfacility=FACILITY         syslog facility (LOG_USER)
    --color                        use color in the console (false)
    --debug=DEBUG                  configure debug level (0)

  Execution mode options:
    --service                      setup the agent as service (true)
    --cron                         setup the agent as cron task running hourly (false)

  Installer options:
    --install                      install the agent (true)
    --uninstall                    uninstall the agent (false)
    --clean                        clean everything when uninstalling or before
                                   installing (false)
    --reinstall                    uninstall and then reinstall the agent (false)
    --list                         list embedded packages
    --extract=WHAT                 don't install but extract packages (nothing)
                                     - "nothing": still install but don't keep extracted packages
                                     - "keep": still install but keep extracted packages
                                     - "all": don't install but extract all packages
                                     - "rpm": don't install but extract all rpm packages
                                     - "deb": don't install but extract all deb packages
                                     - "snap": don't install but extract snap package
    --runnow                       run agent tasks on installation (false)
    --type=INSTALL_TYPE            select type of installation (typical)
                                     - "typical" to only install inventory task
                                     - "network" to install glpi-agent and network related tasks
                                     - "all" to install all tasks
                                     - or tasks to install in a comma-separated list
    -v --verbose                   make verbose install (false)
    --version                      print the installer version and exit
    -S --silent                    make installer silent (false)
    -Q --no-question               don't ask for configuration on prompt (false)
    --force                        try to force installation
    --distro                       force distro name when --force option is used
    --snap                         install snap package instead of using system packaging
    --skip=PKG_LIST                don't try to install listed packages
    -h --help                      print this help
HELP
}

1;
