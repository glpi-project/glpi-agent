package GLPI::Agent::Protocol::Inventory;

use strict;
use warnings;

use parent 'GLPI::Agent::Protocol::Message';

# List of value to normalize as integer before providing content for export
my %normalize = (
    BATTERIES        => [ qw/CAPACITY REAL_CAPACITY VOLTAGE/ ],
    CPUS             => [ qw/CORE CORECOUNT EXTERNAL_CLOCK SPEED STEPPING THREAD/ ],
    DRIVES           => [ qw/FREE TOTAL/ ],
    HARDWARE         => [ qw/MEMORY SWAP/ ],
    PHYSICAL_VOLUMES => [ qw/FREE PE_SIZE PV_PE_COUNT SIZE/ ],
    VOLUME_GROUPS    => [ qw/FREE LV_COUNT PV_COUNT SIZE/ ],
    LOGICAL_VOLUMES  => [ qw/SEG_COUNT SIZE/ ],
    MEMORIES         => [ qw/CAPACITY NUMSLOTS/ ],
    MONITORS         => [ qw/PORT/ ],
    NETWORKS         => [ qw/MTU/ ],
    PROCESSES        => [ qw/PID VIRTUALMEMORY/ ],
    SOFTWARES        => [ qw/FILESIZE/ ],
    STORAGES         => [ qw/DISKSIZE/ ],
    VIDEOS           => [ qw/MEMORY/ ],
    VIRTUALMACHINES  => [ qw/MEMORY VCPU/ ],
    POWERSUPPLIES    => [ qw/POWER_MAX/ ],
    VERSIONPROVIDER  => [ qw/ETIME/ ],
);

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(
        %params,
        supported_params    => [ qw(deviceid action content itemtype) ],
        action              => "inventory",
    );

    bless $self, $class;

    return $self;
}

sub normalize {
    my ($self) = @_;

    my $content = $self->get("content")
        or return;

    # Normalize some integers as string to integers to follow JSON specs
    foreach my $entrykey (keys(%normalize)) {
        my $entry = $content->{$entrykey};
        my $ref = ref($entry)
            or next;
        foreach my $value (@{$normalize{$entrykey}}) {
            if ($ref eq 'ARRAY') {
                map {
                    if (defined($_->{$value})) {
                        if ($_->{$value} =~ /^\d+$/) {
                            # Make sure to use value as integer
                            $_->{$value} += 0;
                        } else {
                        $self->{logger}->debug("inventory format: Removing $entrykey $value value as not an integer but '$_->{$value}'")
                            if $self->{logger};
                            delete $_->{$value};
                        }
                    }
                } @{$entry};
            } elsif (defined($entry->{$value})) {
                if ($entry->{$value} =~ /^\d+$/) {
                    # Make sure to use value as integer
                    $entry->{$value} += 0;
                } else {
                    $self->{logger}->debug("inventory format: Removing $entrykey $value value as not an integer but '$entry->{$value}'")
                        if $self->{logger};
                    delete $entry->{$value};
                }
            }
        }
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::Protocol::Inventory - Inventory GLPI Agent messages

=head1 DESCRIPTION

This is a class to handle Inventory protocol messages.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use

=item I<message>

the message to encode

=back
