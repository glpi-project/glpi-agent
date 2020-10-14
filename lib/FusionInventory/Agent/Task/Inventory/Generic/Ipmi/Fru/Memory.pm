package FusionInventory::Agent::Task::Inventory::Generic::Ipmi::Fru::Memory;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::IpmiFru;

our $runAfterIfEnabled = [qw(
    FusionInventory::Agent::Task::Inventory::Generic::Dmidecode::Memory
)];

sub isEnabled {
    my (%params) = @_;
    return 0 if $params{no_category}->{memory};
    return 1;
}

# update MEMORIES section
sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $fru = getIpmiFru(%params)
        or return;

    my @fru_keys = grep { / DIMM\d* / } keys %$fru
        or return;

    my $memories = $inventory->getSection('MEMORIES') || [];
    my @fields = keys %{$inventory->getFields()->{'MEMORIES'}};

    for my $fru_key (@fru_keys) {
        my ($cpu, $dimm) = $fru_key =~ /^CPU\s*(\d+)[\s_]+DIMM\s*(\d+)/
            or next;

        my @mems = grep {
            $_->{CAPTION} =~ /^(PROC|CPU)\s*\Q$cpu\E[\s_]+DIMM\s*$dimm(?:[A-Z])?$/
        } @$memories;

        next unless scalar @mems == 1;

        my $parsed_fru = parseFru($fru->{$fru_key}, \@fields);

        for my $field (@fields) {
            next unless defined $parsed_fru->{$field} &&
                (!defined $mems[0]->{$field}
                    || $mems[0]->{$field} =~ /
                        NOT\s*AVAILABLE |
                        None            |
                        Not\s*Specified |
                        O\.E\.M\.       |
                        Part\s*Num      |
                        Ser\s*Num       |
                        Serial\s*Num    |
                        Unknown
                    /xi);

            $mems[0]->{$field} = $parsed_fru->{$field};
        }
    }
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Task::Inventory::Generic::Ipmi::Fru::Memory - Processes DIMMs reported by `ipmitool fru`

=head1 DESCRIPTION

Updates MEMORIES section with data from `ipmitool fru`. No new records are added
