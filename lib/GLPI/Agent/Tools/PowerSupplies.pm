package GLPI::Agent::Tools::PowerSupplies;

use strict;
use warnings;

use parent 'Exporter';

use GLPI::Agent::Inventory;
use GLPI::Agent::Tools;

our @EXPORT = qw(
    powersupplyFields
);

my @fields = ();

sub powersupplyFields {

    unless  (@fields) {
        # Initialize PowerSupplies expected fields from an Inventory object
        my $inventory = GLPI::Agent::Inventory->new();
        @fields = keys(%{$inventory->getFields()->{'POWERSUPPLIES'}});
    }

    return @fields;
}


# Also implement a powersupplies class, but split name on new line to not export it in CPAN
## no critic (ProhibitMultiplePackages)
package
    Inventory::PowerSupplies;

use GLPI::Agent::Logger;

sub new {
    my ($class, %params) = @_;

    my $self = {
        logger  => $params{logger} || GLPI::Agent::Logger->new(),
        list    => {},
    };

    bless $self, $class;

    return $self;
}

sub add {
    my ($self, $ref) = @_;

    my $powersupply = PowerSupply->new($ref);

    my $deviceid = $powersupply->deviceid;

    $self->{logger}->debug(
        "Replacing '$deviceid' powersupply"
    ) if $self->{list}->{$deviceid};

    $self->{list}->{$deviceid} = $powersupply;
}

sub merge {
    my ($self, @powersupplies) = @_;

    # Handle the case where only one powersupply is found and deviceid may not
    # be complete in one case
    if (scalar(keys(%{$self->{list}})) == 1 && scalar(@powersupplies) == 1) {
        my $currentid = [ keys(%{$self->{list}}) ]->[0];
        my $current = $self->{list}->{$currentid};
        my $powersupply = PowerSupply->new($powersupplies[0]);
        if ($currentid ne $powersupply->deviceid
            && scalar($current->serial) eq scalar($powersupply->serial)
        ) {
            # Just rename key to permit the merge if serial match
            $self->{list}->{$powersupply->deviceid} = $current;
            delete $self->{list}->{$currentid};
        }
    }

    foreach my $data (@powersupplies) {
        my $powersupply = PowerSupply->new($data);

        my $deviceid = $powersupply->deviceid;

        # Just add powersupply if it doesn't exist in list
        if ($self->{list}->{$deviceid}) {
            $self->{list}->{$deviceid}->merge($powersupply);
        } else {
            $self->{list}->{$deviceid} = $powersupply;
        }
    }
}

sub list {
    my ($self) = @_;
    return map { $_->dump() } values(%{$self->{list}});
}

# Also implement a powersupply class, but split name on new line to not export it in CPAN
package
    PowerSupply;

use GLPI::Agent::Logger;

sub new {
    my ($class, $powersupply) = @_;

    return $powersupply if (ref($powersupply) eq $class);

    return unless ref($powersupply) eq 'HASH';

    $powersupply->{logger} = GLPI::Agent::Logger->new()
        unless $powersupply->{logger};

    bless $powersupply, $class;

    return $powersupply;
}

sub deviceid {
    my ($self) = @_;
    return $self->vendor.$self->serial;
}

sub serial {
    my ($self) = @_;
    return $self->{SERIALNUMBER} || '0';
}

sub vendor {
    my ($self) = @_;
    return $self->{MANUFACTURER} || '';
}

sub merge {
    my ($self, $powersupply) = @_;
    foreach my $key (GLPI::Agent::Tools::PowerSupplies::powersupplyFields()) {
        next unless $powersupply->{$key};
        # Don't replace value is they are the same, case insensitive check
        next if (defined($self->{$key}) && $powersupply->{$key} =~ /^$self->{$key}$/i);
        $self->{logger}->debug(
            "Replacing $key value '$self->{$key}' by '$powersupply->{$key}' on '".
            $self->deviceid."' powersupply"
        ) if $self->{$key};
        $self->{$key} = $powersupply->{$key};
    }
}

sub dump {
    my ($self) = @_;

    my $dump = {};

    foreach my $key (GLPI::Agent::Tools::PowerSupplies::powersupplyFields()) {
        next unless exists($self->{$key});
        $dump->{$key} = $self->{$key};
    }

    return $dump;
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::PowerSupplies

=head1 DESCRIPTION

This module provides functions to manage powersupplies information

=head1 FUNCTIONS

=head2 powersupplyFields()

Returns the list of supported/expected powersupply fields
