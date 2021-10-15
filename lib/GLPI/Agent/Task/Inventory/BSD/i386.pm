package GLPI::Agent::Task::Inventory::BSD::i386;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Config;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;

use constant    category    => "bios";
use constant    other_categories => qw(cpu);

sub isEnabled {
    my (%params) = @_;

    return Uname("-m") =~ /^(i\d86|x86_64|amd64)/ if $params{remote};
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
