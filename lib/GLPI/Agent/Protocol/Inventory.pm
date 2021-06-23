package GLPI::Agent::Protocol::Inventory;

use strict;
use warnings;

use parent 'GLPI::Agent::Protocol::Message';

# List of value to normalize as integer before providing content for export
my %normalize = (
    ANTIVIRUS        => {
        boolean => [ qw/ENABLED UPTODATE/ ],
    },
    BATTERIES        => {
        integer => [ qw/CAPACITY REAL_CAPACITY VOLTAGE/ ],
    },
    CPUS             => {
        integer => [ qw/CORE CORECOUNT EXTERNAL_CLOCK SPEED STEPPING THREAD/ ],
    },
    DRIVES           => {
        boolean => [ qw/SYSTEMDRIVE/ ],
        integer => [ qw/FREE TOTAL/ ],
    },
    HARDWARE         => {
        integer => [ qw/MEMORY SWAP/ ],
    },
    PHYSICAL_VOLUMES => {
        integer => [ qw/FREE PE_SIZE PV_PE_COUNT SIZE/ ],
    },
    VOLUME_GROUPS    => {
        integer => [ qw/FREE LV_COUNT PV_COUNT SIZE/ ],
    },
    LOGICAL_VOLUMES  => {
        integer => [ qw/SEG_COUNT SIZE/ ],
    },
    MEMORIES         => {
        integer => [ qw/CAPACITY NUMSLOTS/ ],
    },
    MONITORS         => {
        integer => [ qw/PORT/ ],
    },
    NETWORKS         => {
        boolean => [ qw/MANAGEMENT VIRTUALDEV/ ],
        integer => [ qw/MTU/ ],
    },
    PRINTERS         => {
        boolean => [ qw/NETWORK SHARED/ ],
    },
    PROCESSES        => {
        integer => [ qw/PID VIRTUALMEMORY/ ],
    },
    SOFTWARES        => {
        boolean => [ qw/NO_REMOVE/ ],
        integer => [ qw/FILESIZE/ ],
    },
    STORAGES         => {
        integer => [ qw/DISKSIZE/ ],
    },
    VIDEOS           => {
        integer => [ qw/MEMORY/ ],
    },
    VIRTUALMACHINES  => {
        integer => [ qw/MEMORY VCPU/ ],
    },
    LICENSEINFOS     => {
        boolean => [ qw/TRIAL/ ],
    },
    POWERSUPPLIES    => {
        boolean => [ qw/HOTREPLACEABLE PLUGGED/ ],
        integer => [ qw/POWER_MAX/ ],
    },
    VERSIONPROVIDER  => {
        integer => [ qw/ETIME/ ],
    },
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

    # Normalize some integers and booleans set as string to follow JSON specs
    foreach my $entrykey (keys(%normalize)) {
        my $entry = $content->{$entrykey};
        my $ref = ref($entry)
            or next;
        foreach my $norm (keys(%{$normalize{$entrykey}})) {
            foreach my $value (@{$normalize{$entrykey}->{$norm}}) {
                if ($ref eq 'ARRAY') {
                    map {
                        if (defined($_->{$value})) {
                            if ($norm eq "integer" && $_->{$value} =~ /^\d+$/) {
                                # Make sure to use value as integer
                                $_->{$value} += 0;
                            } elsif ($norm eq "boolean") {
                                $_->{$value} = $_->{$value} ? JSON::true : JSON::false ;
                            } else {
                            $self->{logger}->debug("inventory format: Removing $entrykey $value value as not of '$norm' type but '$_->{$value}'")
                                if $self->{logger};
                                delete $_->{$value};
                            }
                        }
                    } @{$entry};
                } elsif (defined($entry->{$value})) {
                    if ($norm eq "integer" && $entry->{$value} =~ /^\d+$/) {
                        # Make sure to use value as integer
                        $entry->{$value} += 0;
                    } elsif ($norm eq "boolean") {
                        $entry->{$value} = $entry->{$value} ? JSON::true : JSON::false ;
                    } else {
                        $self->{logger}->debug("inventory format: Removing $entrykey $value value as as not of '$norm' type but '$_->{$value}'")
                            if $self->{logger};
                        delete $entry->{$value};
                    }
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
