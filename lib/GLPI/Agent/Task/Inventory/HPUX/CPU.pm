package GLPI::Agent::Task::Inventory::HPUX::CPU;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::HPUX;

use constant    category    => "cpu";

sub isEnabled  {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # http://forge.fusioninventory.org/issues/755
    if (canRun('/opt/propplus/bin/cprop') && !isHPVMGuest()) {
        foreach my $cpu (_parseCprop(
            command => '/opt/propplus/bin/cprop -summary -c Processors',
            logger  => $logger
        )) {
            $inventory->addEntry(
                section => 'CPUS',
                entry   => $cpu
            );
        }
        return;
    }

    my $CPUinfo;
    if (canRun('/usr/contrib/bin/machinfo')) {
        $CPUinfo = _parseMachinInfo(
            command => '/usr/contrib/bin/machinfo',
            logger  => $logger
        );
    } else {
        # old HpUX without machinfo
        my %cpuInfos = (
            "D200" => { TYPE => "7100LC", SPEED => 75  },
            "D210" => { TYPE => "7100LC", SPEED => 100 },
            "D220" => { TYPE => "7300LC", SPEED => 132 },
            "D230" => { TYPE => "7300LC", SPEED => 160 },
            "D250" => { TYPE => "7200",   SPEED => 100 },
            "D260" => { TYPE => "7200",   SPEED => 120 },
            "D270" => { TYPE => "8000",   SPEED => 160 },
            "D280" => { TYPE => "8000",   SPEED => 180 },
            "D310" => { TYPE => "7100LC", SPEED => 100 },
            "D320" => { TYPE => "7300LC", SPEED => 132 },
            "D330" => { TYPE => "7300LC", SPEED => 160 },
            "D350" => { TYPE => "7200",   SPEED => 100 },
            "D360" => { TYPE => "7200",   SPEED => 120 },
            "D370" => { TYPE => "8000",   SPEED => 160 },
            "D380" => { TYPE => "8000",   SPEED => 180 },
            "D390" => { TYPE => "8200",   SPEED => 240 },
            "K360" => { TYPE => "8000",   SPEED => 180 },
            "K370" => { TYPE => "8200",   SPEED => 200 },
            "K380" => { TYPE => "8200",   SPEED => 240 },
            "K400" => { TYPE => "7200",   SPEED => 140 },
            "K410" => { TYPE => "7200",   SPEED => 120 },
            "K420" => { TYPE => "7200",   SPEED => 120 },
            "K460" => { TYPE => "8000",   SPEED => 180 },
            "K570" => { TYPE => "8200",   SPEED => 200 },
            "K580" => { TYPE => "8200",   SPEED => 240 },
            "L1000-36" => { TYPE => "8500", SPEED => 360 },
            "L1500-7x" => { TYPE => "8700", SPEED => 750 },
            "L3000-7x" => { TYPE => "8700", SPEED => 750 },
            "N4000-44" => { TYPE => "8500", SPEED => 440 },
            "ia64 hp server rx1620" => { TYPE => "itanium", SPEED => 1600 }
        );

        my $device = getFirstLine(command => 'model |cut -f 3- -d/');
        if ($cpuInfos{$device}) {
            $CPUinfo = $cpuInfos{$device};
        } else {
            $CPUinfo->{TYPE} = getFirstMatch(
                command => "echo 'sc product cpu;il' | /usr/sbin/cstm",
                logger  => $logger,
                pattern => qr/(\S+)\s+CPU\s+Module/,
            );
            $CPUinfo->{SPEED} = getFirstMatch(
                command => "echo 'itick_per_usec/D' | adb -k /stand/vmunix /dev/kmem",
                logger  => $logger,
                pattern => qr/tick_per_usec:\s+(\d+)/
            );
        }
        # NBR CPU
        $CPUinfo->{CPUcount} = getLinesCount(
            command => 'ioscan -Fk -C processor'
        );
    }

    my $serie = Uname("-m");
    if ( $CPUinfo->{TYPE} eq 'unknow' and $serie =~ /ia64/) {
        $CPUinfo->{TYPE} = "Itanium"
    }
    if ( $serie =~ /9000/) {
        $CPUinfo->{TYPE} = "PA" . $CPUinfo->{TYPE};
    }

    foreach ( 1..$CPUinfo->{CPUcount} ) {
        $inventory->addEntry(
            section => 'CPUS',
            entry   => $CPUinfo
        );
    }
}

sub _parseMachinInfo {
    my $info = getInfoFromMachinfo(@_);
    return unless $info;

    my $result;
    my $cpu_info = $info->{'CPU info'};
    if (ref $cpu_info eq 'HASH') {
        # HPUX 11.23
        $result->{CPUcount} = $cpu_info->{'number of cpus'};

        if ($cpu_info->{'clock speed'} =~ /(\d+) MHz/) {
            $result->{SPEED} = $1;
        }

        if ($cpu_info->{'processor model'} =~ /Intel/) {
            $result->{MANUFACTURER} = 'Intel';
        }

        if ($cpu_info->{'processor model'} =~ /Itanium/) {
            $result->{NAME} = 'Itanium';
        }
    } else {
        # HPUX 11.31
        if ($cpu_info =~ /^(\d+) /) {
            $result->{CPUcount} = $1;
        }
        if ($cpu_info =~ /([\d.]+) GHz/) {
            $result->{SPEED} = $1 * 1000;
        }
        if ($cpu_info =~ /Intel/) {
            $result->{MANUFACTURER} = 'Intel';
        }
        if ($cpu_info =~ /Itanium/) {
            $result->{NAME} = 'Itanium';
        }
        if ($cpu_info =~ /(\d+) logical processors/ ) {
            $result->{CORE} = $1 / $result->{CPUcount};
        }
    }

    return $result;
}

sub _parseCprop {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    my @cpus;
    my $instance;

    foreach my $line (@lines) {
        if ($line =~ /^\[Instance\]: \d+/) {
            # new block
            $instance = {};
            next;
        }

        if ($line =~ /^ \s+ \[ ([^\]]+) \]: \s (.+)/x) {
            $instance->{$1} = $2;
            next;
        }

        if ($line =~ /^\*+/) {
            next unless keys %$instance;

            my $name = $instance->{'Processor Type'} =~ /Itanium/ ?
                'Itanium' : undef;
            my $manufacturer = $instance->{'Processor Type'} =~ /Intel/ ?
                'Intel' : undef;
            my $cpu = {
                SPEED        => $instance->{'Processor Speed'},
                ID           => $instance->{'Tag'},
                NAME         => $name,
                MANUFACTURER => $manufacturer
            };

            if ($instance->{'Location'} =~ /Cell Slot Number (\d+)\b/i) {
                # this is a single core from a multi-core cpu
                my $slotId = $1;
                if ($cpus[$slotId]) {
                    $cpus[$slotId]->{CORE}++;
                } else {
                    $cpus[$slotId] = $cpu;
                    $cpus[$slotId]->{CORE}=1;
                }
            } else {
                push @cpus, $cpu;
            }
        }
    }

    # filter missing cpus
    @cpus = grep { $_ } @cpus;

    return @cpus;
}
1;
