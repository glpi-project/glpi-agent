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
    # on OpenBSD amd64 perl archname is "amd64-<os>"
    return $Config{archname} =~ /^(i\d86|x86_64|amd64)/;
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

    # OpenBSD: without kern.allowkmem, dmidecode can't read /dev/mem
    # but system identification and cpu details are still available via sysctl
    if (OSNAME eq 'openbsd') {
        my %hw = map { $_ => getFirstLine(command => "sysctl -n hw.$_") }
            qw/vendor product serialno uuid cpuspeed/;
        $bios->{SMANUFACTURER} = $hw{vendor}   if $hw{vendor};
        $bios->{SMODEL}        = $hw{product}  if $hw{product};
        $bios->{SSN}           = $hw{serialno} if $hw{serialno};
        $inventory->setHardware({ UUID => uc($hw{uuid}) }) if $hw{uuid};

        my $model = getFirstLine(command => 'sysctl -n hw.model');
        if ($model) {
            $cpu->{NAME} = $model;
            $cpu->{MANUFACTURER} = 'Intel' if $model =~ /intel/i;
            $cpu->{MANUFACTURER} = 'AMD'   if $model =~ /\bamd\b/i;
        }
        $cpu->{SPEED} = $hw{cpuspeed} if $hw{cpuspeed} && $hw{cpuspeed} =~ /^\d+$/;
        $cpu->{CORE}   = 1;
        $cpu->{THREAD} = 1;
    }

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
