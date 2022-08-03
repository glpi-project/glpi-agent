package GLPI::Agent::Task::Inventory::Generic::Dmidecode::Psu;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;
use GLPI::Agent::Tools::PartNumber;

use constant    category    => "psu";

sub isEnabled {
    return 1;
}

my %fields = (
    PARTNUM         => 'Model Part Number',
    SERIALNUMBER    => 'Serial Number',
    MANUFACTURER    => 'Manufacturer',
    NAME            => 'Name',
    STATUS          => 'Status',
    PLUGGED         => 'Plugged',
    LOCATION        => 'Location',
    POWER_MAX       => 'Max Power Capacity',
    HOTREPLACEABLE  => 'Hot Replaceable',
);

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $infos = getDmidecodeInfos(%params);

    return unless $infos->{39};

    foreach my $info (@{$infos->{39}}) {
        # Skip battery
        next if $info->{'Type'} && $info->{'Type'} eq 'Battery';

        my $psu;

        # Add available informations but filter out not filled values
        foreach my $key (keys(%fields)) {
            next unless defined($info->{$fields{$key}});
            next if $info->{$fields{$key}} =~ /To Be Filled By O.?E.?M/i;
            next if $info->{$fields{$key}} =~ /OEM Define/i;
            $psu->{$key} = $info->{$fields{$key}};
        }

        # Get canonical manufacturer
        $psu->{'MANUFACTURER'} = getCanonicalManufacturer($psu->{'MANUFACTURER'})
            if $psu->{'MANUFACTURER'};

        # Get canonical max power
        $psu->{'POWER_MAX'} = getCanonicalPower($psu->{'POWER_MAX'})
            if $psu->{'POWER_MAX'};

        # Validate PartNumber, as example, this fixes Dell PartNumbers
        if ($psu->{'PARTNUM'} && $psu->{'MANUFACTURER'}) {
            my $partnumber_factory = GLPI::Agent::Tools::PartNumber->new(
                logger  => $params{logger},
            );
            my $partnumber = $partnumber_factory->match(
                partnumber      => $psu->{'PARTNUM'},
                manufacturer    => $psu->{'MANUFACTURER'},
                category        => "controller",
            );
            $psu->{'PARTNUM'} = $partnumber->get
                if defined($partnumber);
        }

        # Filter out PSU if nothing interesting is found
        next unless $psu;
        next unless ($psu->{'NAME'} || $psu->{'SERIALNUMBER'} || $psu->{'PARTNUM'});

        $inventory->addEntry(
            section => 'POWERSUPPLIES',
            entry   => $psu
        );
    }
}

1;
