package GLPI::Agent::Task::Inventory::AIX::CPU;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "cpu";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $cpu (_getCPUs(
        command => 'lsdev -Cc processor -F name',
        logger  => $logger
    )) {
        $inventory->addEntry(
            section => 'CPUS',
            entry   => $cpu
        );
    }
}

sub _getCPUs {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my $aixversion = Uname("-v");

    my @cpus;
    foreach my $line (@lines) {
        my $device = $line;

        my $format = $aixversion >= 5 ?
            'type:frequency:frequency' : 'type';

        my @lsattr = getAllLines(
            command => "lsattr -EOl $device -a '$format'",
        );

        my $cpu = {
            THREAD => 1
        };

        my $smt_threads = getFirstLine(command => "lsattr -EOl $device -a 'state:type:smt_threads'");
        if ($smt_threads && $smt_threads =~ /:(\d+)$/) {
            $cpu->{THREAD} = $1;
        }


        # drop headers
        shift @lsattr;

        # use first line to compute name, frequency and number of threads
        my @infos = split(/:/, $lsattr[0]);

        $cpu->{NAME} = $infos[0];
        $cpu->{NAME} =~ s/_/ /;

        if ($aixversion >= 5) {
            $cpu->{SPEED} = ($infos[1] % 1000000) >= 50000 ?
                int($infos[1] / 1000000) + 1 : int($infos[1] / 1000000);
        } else {
            # On older models, frequency is based on cpu model and uname
            SWITCH: {
                if (
                    $infos[0] eq "PowerPC"     or
                    $infos[0] eq "PowerPC_601" or
                    $infos[0] eq "PowerPC_604"
                ) {
                    my $uname = Uname("-m");
                    $cpu->{SPEED} =
                        $uname =~ /E1D|EAD|C1D|R04|C4D|R4D/ ?  12.2 :
                        $uname =~ /34M/                     ? 133   :
                        $uname =~ /N4D/                     ? 150   :
                        $uname =~ /X4M|X4D/                 ? 200   :
                        $uname =~ /N4E|K04|K44/             ? 225   :
                        $uname =~ /N4F/                     ? 320   :
                        $uname =~ /K45/                     ? 360   :
                                                              undef ;
                    last SWITCH;
                }

                if ($infos[0] eq "PowerPC_RS64_III") {
                    $cpu->{SPEED} = 400;
                    last SWITCH;
                }

                if ($infos[0] eq "PowerPC_620") {
                    $cpu->{SPEED} = 172;
                    last SWITCH;
                }

                $cpu->{SPEED} = 225;
            }
        }

        # compute core number from lines number
        $cpu->{CORE} = scalar @lsattr;

        push @cpus, $cpu;
    }

    return @cpus;
}

1;
