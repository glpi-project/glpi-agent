package GLPI::Agent::Protocol::Inventory;

use strict;
use warnings;

use parent 'GLPI::Agent::Protocol::Message';

use constant date_qr            => qr/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/;
use constant datetime_qr        => qr/^[0-9]{4}-[0-9]{2}-[0-9]{2}[ |T][0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+|-][0-9]{2}:[0-9]{2}:[0-9]{2})?$/;
use constant dateordatetime_qr  => qr/^[0-9]{4}-[0-9]{2}-[0-9]{2}([ |T][0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+|-][0-9]{2}:[0-9]{2}:[0-9]{2})?)?$/;

# List of value to normalize as integer before providing content for export
my %normalize = (
    ACCESSLOG        => {
        datetime        => [ qw/LOGDATE/ ],
    },
    ANTIVIRUS        => {
        boolean         => [ qw/ENABLED UPTODATE/ ],
        date            => [ qw/EXPIRATION/ ],
    },
    BATTERIES        => {
        date            => [ qw/DATE/ ],
        integer         => [ qw/CAPACITY REAL_CAPACITY VOLTAGE/ ],
    },
    BIOS             => {
        dateordatetime  => [ qw/BDATE/ ],
    },
    CPUS             => {
        integer         => [ qw/CORE CORECOUNT EXTERNAL_CLOCK SPEED STEPPING THREAD/ ],
        string          => [ qw/MODEL FAMILYNUMBER/ ],
    },
    DATABASES_SERVICES => {
        integer         => [ qw/PORT SIZE/ ],
        boolean         => [ qw/IS_ACTIVE IS_ONBACKUP/ ],
        datetime        => [ qw/LAST_BOOT_DATE LAST_BACKUP_DATE/ ],
    },
    "DATABASES_SERVICES/DATABASES" => {
        integer         => [ qw/SIZE/ ],
        boolean         => [ qw/IS_ACTIVE IS_ONBACKUP/ ],
        datetime        => [ qw/CREATION_DATE UPDATE_DATE LAST_BACKUP_DATE/ ],
    },
    DRIVES           => {
        boolean         => [ qw/SYSTEMDRIVE/ ],
        integer         => [ qw/FREE TOTAL/ ],
    },
    HARDWARE         => {
        integer         => [ qw/MEMORY SWAP/ ],
    },
    PHYSICAL_VOLUMES => {
        integer         => [ qw/FREE PE_SIZE PV_PE_COUNT SIZE/ ],
    },
    VOLUME_GROUPS    => {
        integer         => [ qw/FREE LV_COUNT PV_COUNT SIZE/ ],
    },
    LOGICAL_VOLUMES  => {
        integer         => [ qw/SEG_COUNT SIZE/ ],
    },
    MEMORIES         => {
        integer         => [ qw/CAPACITY NUMSLOTS/ ],
    },
    MONITORS         => {
        integer         => [ qw/PORT/ ],
    },
    NETWORKS         => {
        boolean         => [ qw/MANAGEMENT VIRTUALDEV/ ],
        integer         => [ qw/MTU/ ],
        lowercase       => [ qw/STATUS/ ],
        string          => [ qw/SPEED/ ],
    },
    OPERATINGSYSTEM  => {
        datetime        => [ qw/BOOT_TIME INSTALL_DATE/ ],
    },
    PRINTERS         => {
        boolean         => [ qw/NETWORK SHARED/ ],
    },
    PROCESSES        => {
        datetime        => [ qw/STARTED/ ],
        integer         => [ qw/PID VIRTUALMEMORY/ ],
    },
    REMOTE_MGNT      => {
        string          => [ qw/ID/ ],
    },
    SOFTWARES        => {
        boolean         => [ qw/NO_REMOVE/ ],
        dateordatetime  => [ qw/INSTALLDATE/ ],
        integer         => [ qw/FILESIZE/ ],
        string          => [ qw/VERSION_MAJOR VERSION_MINOR/ ],
    },
    STORAGES         => {
        integer         => [ qw/DISKSIZE/ ],
        uppercase       => [ qw/INTERFACE/ ],
    },
    VIDEOS           => {
        integer         => [ qw/MEMORY/ ],
    },
    VIRTUALMACHINES  => {
        integer         => [ qw/MEMORY VCPU/ ],
        lowercase       => [ qw/STATUS VMTYPE/ ],
    },
    LICENSEINFOS     => {
        boolean         => [ qw/TRIAL/ ],
        datetime        => [ qw/ACTIVATION_DATE/ ],
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
        supported_params    => [ qw(deviceid action content itemtype partial) ],
        action              => "inventory",
    );

    delete $self->{partial} unless $params{partial};

    bless $self, $class;

    return $self;
}

sub normalize {
    my ($self) = @_;

    my $content = $self->get("content")
        or return;

    # Normalize some integers and booleans set as string to follow JSON specs
    foreach my $entrykey (keys(%normalize)) {
        my @entries = ($content->{$entrykey});
        if (!defined($entries[0]) && $entrykey =~ /^(\w+)\/(\w+)$/ && defined($content->{$1})) {
            if (ref($content->{$1}) eq 'ARRAY') {
                @entries = map { $_->{$2} } @{$content->{$1}};
            } else {
                @entries = ($content->{$1}->{$2});
            }
        }
        foreach my $entry (@entries) {
            my $ref = ref($entry)
                or next;
            foreach my $norm (keys(%{$normalize{$entrykey}})) {
                foreach my $value (@{$normalize{$entrykey}->{$norm}}) {
                    if ($ref eq 'ARRAY') {
                        map { $self->_norm($norm, $_, $value, $entrykey) } @{$entry};
                    } else {
                        $self->_norm($norm, $entry, $value, $entrykey);
                    }
                }
            }
        }
    }

    # Parse content and remove any not defined value
    _recursive_not_defined_cleanup($content);

    # Normalize main PARTIAL status
    $self->_norm('boolean', $self->get, "partial", "main");

    # Handle tag as a root property
    if ($content->{ACCOUNTINFO}) {
        my $infos = delete $content->{ACCOUNTINFO};
        if (ref($infos) eq 'ARRAY') {
            my ($tag) = map { $_->{KEYVALUE} } grep { $_->{KEYNAME} eq "TAG" } @{$infos};
            $self->merge(tag => $tag) if defined($tag) && length($tag);
        }
    }

    # Transform content to inventory_format
    $self->_transform();
}

sub _recursive_not_defined_cleanup {
    my ($entry) = @_;

    my $ref = ref($entry)
        or return;

    if ($ref eq 'HASH') {
        foreach my $key (keys(%{$entry})) {
            if (defined($entry->{$key})) {
                _recursive_not_defined_cleanup($entry->{$key});
            } else {
                delete $entry->{$key};
            }
        }
    } elsif ($ref eq 'ARRAY') {
        map { _recursive_not_defined_cleanup($_) } @{$entry};
    }
}

sub _norm {
    my ($self, $norm, $entry, $value, $entrykey) = @_;

    return unless defined($entry->{$value});

    if ($norm eq "integer" && $entry->{$value} =~ /^\d+$/) {
        # Make sure to use value as integer
        $entry->{$value} += 0;
    } elsif ($norm eq "string") {
        $entry->{$value} .= "" ;
    } elsif ($norm eq "boolean") {
        $entry->{$value} = $entry->{$value} ? JSON::true : JSON::false ;
    } elsif ($norm eq "lowercase") {
        $entry->{$value} = lc($entry->{$value});
    } elsif ($norm eq "uppercase") {
        $entry->{$value} = uc($entry->{$value});
    } elsif ($norm eq "date" && $entry->{$value} !~ date_qr) {
        my $date = _canonicalDate($entry->{$value});
        if (defined($date)) {
            $entry->{$value} = $date;
        } else {
            $self->{logger}->debug("inventory format: Removing $entrykey $value value as not of $norm type: '$entry->{$value}'")
                if $self->{logger};
            delete $entry->{$value};
        }
    } elsif ($norm eq "datetime" && $entry->{$value} !~ datetime_qr) {
        my $datetime = _canonicalDatetime($entry->{$value});
        if (defined($datetime)) {
            $entry->{$value} = $datetime;
        } else {
            $self->{logger}->debug("inventory format: Removing $entrykey $value value as not of $norm type: '$entry->{$value}'")
                if $self->{logger};
            delete $entry->{$value};
        }
    } elsif ($norm eq "dateordatetime" && $entry->{$value} !~ dateordatetime_qr) {
        my $dateordatetime = _canonicalDateordatetime($entry->{$value});
        if (defined($dateordatetime)) {
            $entry->{$value} = $dateordatetime;
        } else {
            $self->{logger}->debug("inventory format: Removing $entrykey $value value as not of $norm type: '$entry->{$value}'")
                if $self->{logger};
            delete $entry->{$value};
        }
    } elsif ($norm =~ /^integer$/) {
        $self->{logger}->debug("inventory format: Removing $entrykey $value value as not of $norm type: '$entry->{$value}'")
            if $self->{logger};
        delete $entry->{$value};
    }
}

sub _canonicalDate {
    my ($date) = @_;
    return unless defined($date);
    return "$3-$2-$1" if $date =~ /^(\d{2})\/(\d{2})\/(\d{4})/;
    return $1 if $date =~ /^(\d{4}-\d{2}-\d{2})/;
    return;
}

sub _canonicalDatetime {
    my ($datetime) = @_;
    return unless defined($datetime);
    return "$3-$2-$1 00:00:00" if $datetime =~ /^(\d{2})\/(\d{2})\/(\d{4})$/;
    return "$datetime:00" if $datetime =~ /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$/;
    return;
}

sub _canonicalDateordatetime {
    my ($date) = @_;
    return unless defined($date);
    return "$3-$2-$1" if $date =~ /^(\d{2})\/(\d{2})\/(\d{4})$/;
    return;
}

sub _transform {
    my ($self) = @_;

    my $content = $self->get("content")
        or return;

    # Member property of local_groups has been renamed to members
    my $groups = $content->{LOCAL_GROUPS};
    if (ref($groups) eq 'ARRAY') {
        map {
            $_->{MEMBERS} = delete $_->{MEMBER}
        } grep { exists($_->{MEMBER}) } @{$groups};
    }

    # Installdate property of softwares has been renamed to install_date
    my $softwares = $content->{SOFTWARES};
    if (ref($softwares) eq 'ARRAY') {
        map {
            $_->{INSTALL_DATE} = delete $_->{INSTALLDATE}
        } grep { exists($_->{INSTALLDATE}) } @{$softwares};
    }

    # Serialnumber property of storages has been renamed to serial
    my $storages = $content->{STORAGES};
    if (ref($storages) eq 'ARRAY') {
        map {
            $_->{SERIAL} = delete $_->{SERIALNUMBER}
        } grep { exists($_->{SERIALNUMBER}) } @{$storages};
    }

    # Firewall has been renamed to firewalls
    my $firewalls = delete $content->{FIREWALL};
    if (ref($firewalls) eq 'ARRAY') {
        $content->{FIREWALLS} = $firewalls;
    }

    # Macaddr property of networks has been renamed to mac
    my $networks = $content->{NETWORKS};
    if (ref($networks) eq 'ARRAY') {
        map {
            $_->{MAC} = delete $_->{MACADDR}
        } grep { exists($_->{MACADDR}) } @{$networks};
    }

    # Cleanup GLPI unsupported values
    my $licenseinfos = $content->{LICENSEINFOS};
    if (ref($licenseinfos) eq 'ARRAY') {
        map { delete $_->{OEM} } grep { exists($_->{OEM}) } @{$licenseinfos};
    }

    my $videos = $content->{VIDEOS};
    if (ref($videos) eq 'ARRAY') {
        map { delete $_->{PCIID} } grep { exists($_->{PCIID}) } @{$videos};
    }

    delete $content->{RUDDER};
    delete $content->{REGISTRY};
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

=head2 normalize()

Parse content to normalize the inventory and prepare it for the expected json format.
