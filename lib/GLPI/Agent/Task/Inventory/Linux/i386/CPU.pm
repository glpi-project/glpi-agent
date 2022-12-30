package GLPI::Agent::Task::Inventory::Linux::i386::CPU;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Linux;
use GLPI::Agent::Tools::Generic;

use constant    category    => "cpu";

sub isEnabled {
    return canRead('/proc/cpuinfo');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $cpu (_getCPUs(logger => $logger)) {
        $inventory->addEntry(
            section => 'CPUS',
            entry   => $cpu
        );
    }
}

sub _getCPUs {
    my (%params) = @_;

    my @dmidecodeInfos = $params{dmidecode} ?
        getCpusFromDmidecode(file => $params{dmidecode}) :
        getCpusFromDmidecode();

    my $count = 0;
    my @cpus;
    my %seen;

    foreach my $logicalCpu (getCPUsFromProc(@_)) {
        my $cpuId = $logicalCpu->{'physical id'};
        my ($core, $thread);
        if (defined $cpuId) {
            next if $seen{$cpuId}++;
            $core   = $logicalCpu->{'cpu cores'};
            $thread = $logicalCpu->{'siblings'};
        } else {
            $cpuId  = $count;
            $core   = 1;
            $thread = 1;
        }

        my $dmidecodeInfo = $dmidecodeInfos[$cpuId];

        my $cpu = {
            ARCH           => 'i386',
            MANUFACTURER   => getCanonicalManufacturer($logicalCpu->{vendor_id}),
            STEPPING       => $logicalCpu->{'stepping'} ||
                              $dmidecodeInfo->{STEPPING},
            FAMILYNUMBER   => $logicalCpu->{'cpu family'} ||
                              $dmidecodeInfo->{FAMILYNUMBER},
            MODEL          => $logicalCpu->{'model'} ||
                              $dmidecodeInfo->{MODEL},
            NAME           => $logicalCpu->{'model name'},
            CORE           => $core   || $dmidecodeInfo->{CORE},
            THREAD         => $thread || $dmidecodeInfo->{THREAD}
        };

        # Import some dmidecode value only when available
        foreach my $key (qw(ID SERIAL EXTERNAL_CLOCK FAMILYNAME CORECOUNT)) {
            $cpu->{$key} = $dmidecodeInfo->{$key} if $dmidecodeInfo->{$key};
        }

        if ($cpu->{NAME} =~ /([\d\.]+)s*(GHZ)/i) {
            $cpu->{SPEED} = {
               ghz => 1000,
               mhz => 1,
            }->{lc($2)} * $1;
        }

        push @cpus, $cpu;
        $count++;
    }

    return @cpus;
}

1;
