package FusionInventory::Agent::Task::Inventory::BSD::i386;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use Config;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Generic;

use constant    other_categories => qw(cpu);

sub isEnabled {
    return $Config{archname} =~ /^(i\d86|x86_64)/;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # sysctl infos
    my $bios = {
        SMODEL => getFirstLine(command => 'sysctl -n hw.model')
    };
    my $cpu = {
        NAME  => getFirstLine(command => 'sysctl -n hw.machine'),
        SPEED => (getCanonicalSpeed(split(/\s+/, $bios->{SMODEL})))[-1]
    };
    my $count = getFirstLine(command => 'sysctl -n hw.ncpu');

    $inventory->setBios($bios);

    # don't deal with CPUs if information can be computed from dmidecode
    my $infos = getDmidecodeInfos(logger => $logger);
    return if $infos->{4};

    return if $params{no_category}->{cpu};

    while ($count--) {
        $inventory->addEntry(
            section => 'CPUS',
            entry   => $cpu
        );
    }

}

1;
