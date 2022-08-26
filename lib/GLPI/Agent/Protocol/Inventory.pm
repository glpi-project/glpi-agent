package GLPI::Agent::Protocol::Inventory;

use strict;
use warnings;

use parent 'GLPI::Agent::Protocol::Message';

use DateTime;
use English qw(-no_match_vars);
use Cpanel::JSON::XS;

use GLPI::Agent::Tools;

use constant date_qr            => qr/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/;
use constant datetime_qr        => qr/^[0-9]{4}-[0-9]{2}-[0-9]{2}[ |T][0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+|-][0-9]{2}:[0-9]{2}:[0-9]{2})?$/;
use constant dateordatetime_qr  => qr/^[0-9]{4}-[0-9]{2}-[0-9]{2}([ |T][0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+|-][0-9]{2}:[0-9]{2}:[0-9]{2})?)?$/;

# List of value to normalize with integer/string/boolean/date/datetime or
# dateordatetime format before providing content for export
# Other constraints are also checked like lowercase, uppercase or required.
my %normalize = (
    ACCESSLOG        => {
        required        => [ qw/LOGDATE/ ],
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
        required        => [ qw/NAME VERSION/ ],
        integer         => [ qw/PORT SIZE/ ],
        boolean         => [ qw/IS_ACTIVE IS_ONBACKUP/ ],
        datetime        => [ qw/LAST_BOOT_DATE LAST_BACKUP_DATE/ ],
    },
    "DATABASES_SERVICES/DATABASES" => {
        required        => [ qw/NAME/ ],
        integer         => [ qw/SIZE/ ],
        boolean         => [ qw/IS_ACTIVE IS_ONBACKUP/ ],
        datetime        => [ qw/CREATION_DATE UPDATE_DATE LAST_BACKUP_DATE/ ],
    },
    DRIVES           => {
        boolean         => [ qw/SYSTEMDRIVE/ ],
        integer         => [ qw/FREE TOTAL/ ],
    },
    ENVS             => {
        required        => [ qw/KEY VAL/ ],
    },
    FIREWALLS        => {
        required        => [ qw/STATUS/ ],
    },
    HARDWARE         => {
        integer         => [ qw/MEMORY SWAP/ ],
    },
    LOCAL_GROUPS     => {
        required        => [ qw/ID NAME/ ],
    },
    LOCAL_USERS      => {
        required        => [ qw/ID/ ],
    },
    PHYSICAL_VOLUMES => {
        required        => [ qw/DEVICE FORMAT FREE PV_PE_COUNT PV_UUID SIZE/ ],
        integer         => [ qw/FREE PE_SIZE PV_PE_COUNT SIZE/ ],
    },
    VOLUME_GROUPS    => {
        required        => [ qw/FREE LV_COUNT PV_COUNT SIZE VG_EXTENT_SIZE VG_NAME VG_UUID/ ],
        integer         => [ qw/FREE LV_COUNT PV_COUNT SIZE/ ],
    },
    LOGICAL_VOLUMES  => {
        required        => [ qw/LV_NAME LV_UUID SIZE/ ],
        integer         => [ qw/SEG_COUNT SIZE/ ],
    },
    MEMORIES         => {
        integer         => [ qw/CAPACITY NUMSLOTS/ ],
        boolean         => [ qw/REMOVABLE/ ],
    },
    MONITORS         => {
        string          => [ qw/DESCRIPTION SERIAL ALTSERIAL/ ],
    },
    NETWORKS         => {
        required        => [ qw/DESCRIPTION/ ],
        boolean         => [ qw/MANAGEMENT VIRTUALDEV/ ],
        integer         => [ qw/MTU/ ],
        lowercase       => [ qw/STATUS/ ],
        string          => [ qw/SPEED/ ],
    },
    OPERATINGSYSTEM  => {
        datetime        => [ qw/BOOT_TIME INSTALL_DATE/ ],
    },
    "OPERATINGSYSTEM/TIMEZONE"  => {
        required    => [ qw/NAME OFFSET/ ],
    },
    PORTS            => {
        required        => [ qw/TYPE/ ],
    },
    PRINTERS         => {
        required        => [ qw/NAME/ ],
        boolean         => [ qw/NETWORK SHARED/ ],
    },
    PROCESSES        => {
        required        => [ qw/CMD PID USER/ ],
        datetime        => [ qw/STARTED/ ],
        integer         => [ qw/PID VIRTUALMEMORY/ ],
    },
    REMOTE_MGMT      => {
        required        => [ qw/ID TYPE/ ],
        string          => [ qw/ID/ ],
    },
    SLOTS            => {
        required        => [ qw/DESCRIPTION NAME/ ],
    },
    SOFTWARES        => {
        required        => [ qw/NAME/ ],
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
        required        => [ qw/NAME VMTYPE/ ],
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

sub mergeContent {
    my ($self, %params) = @_;

    return unless ref($params{content}) eq 'HASH';

    $self->{_merge_content} = $params{content};
}

sub _setupStandardization {
    my ($self, $version) = @_;

    # Parse version setting default support to 10.0.0
    my ($major, $minor, $rev, $suffix) = (10, 0, 0, '');
    if ($version && $version =~ /^(\d+)\.(\d+)\.(\d+)(?:-(.*))$/) {
        $major = int($1);
        $minor = int($2);
        $rev   = int($3);
        $suffix = $4 if defined($4);
    }

    if ($suffix eq 'dev') {
        $self->{logger}->debug2(
            "inventory format: server is a development version\n" .
            "Be sure to use latest GLPI Agent nightly build being aware your JSON inventory\n" .
            "may be rejected by server, and in that case, you probably just have to update the\n" .
            "server-side 'inventory.schema.json' file manually.\n" .
            "If this is not sufficient, please, can you open an issue on glpi-agent github project ?"
        );
    } elsif ($suffix eq 'beta') {
        $self->{logger}->debug2(
            "inventory format: server is a beta version\n" .
            "Be sure to use latest GLPI Agent nightly build.\n" .
            "If the server rejects the inventory, please, report an issue on glpi-agent github project."
        );
        if ($major == 10 && !$minor && !$rev) {
            # GLPI 10.0.0-beta supported specs
            delete $normalize{MEMORIES}->{boolean};
            $normalize{MEMORIES}->{string} = [ qw/REMOVABLE/ ];
        }
    }
}

sub normalize {
    my ($self, $version) = @_;

    my $content = $self->get("content")
        or return;

    # Fix %normalize structure againt server version
    $self->_setupStandardization($version);

    # Normalize to follow JSON specs
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
            # Be sure to handle "required" after all other constraint to support
            # the case another constraint removes a required one
            my @normalize = grep { $_ ne "required" } keys(%{$normalize{$entrykey}});
            foreach my $norm (@normalize) {
                foreach my $value (@{$normalize{$entrykey}->{$norm}}) {
                    if ($ref eq 'ARRAY') {
                        map { $self->_norm($norm, $_, $value, $entrykey) } @{$entry};
                    } else {
                        $self->_norm($norm, $entry, $value, $entrykey);
                    }
                }
            }
            if ($normalize{$entrykey}->{required}) {
                if ($ref eq 'ARRAY') {
                    # Check validity of each entry
                    if (any { my $e = $_; any { ! defined($e->{$_}) } @{$normalize{$entrykey}->{required}} } @{$entry}) {
                        my ($entryref, $key) = ($content, $entrykey);
                        if ($entrykey =~ /^(\w+)\/(\w+)$/) {
                            if (ref($content->{$1}) eq 'ARRAY') {
                                ($entryref) = grep { $_->{$2} == $entry } @{$content->{$1}};
                                $key = $2;
                            } else {
                                ($entryref, $key) = ($content->{$1}, $2);
                            }
                        }
                        my @entrycontent = ();
                        foreach my $oldentry (@{$entryref->{$key}}) {
                            my @missing = grep { ! defined($oldentry->{$_}) } @{$normalize{$entrykey}->{required}};
                            if (@missing) {
                                if ($self->{logger}) {
                                    my $missing = join(", ", @missing)." value".(@missing>1 ? "s":"");
                                    my $dump = join(",", map { $_.":".$oldentry->{$_} } sort keys(%{$oldentry}));
                                    $self->{logger}->debug("inventory format: Removing $entrykey entry element with required missing $missing: $dump");
                                }
                                next;
                            }
                            push @entrycontent, $oldentry;
                        }
                        if (@entrycontent) {
                            $entryref->{$key} = \@entrycontent;
                        } else {
                            delete $entryref->{$key};
                            $self->{logger}->debug("inventory format: Removed all $entrykey entry elements")
                                if $self->{logger};
                        }
                    }
                } else {
                    my @missing = grep { ! defined($entry->{$_}) } @{$normalize{$entrykey}->{required}};
                    if (@missing) {
                        if ($self->{logger}) {
                            my $missing = join(", ", @missing)." value".(@missing>1 ? "s":"");
                            my $dump = join(",", map { $_.":".$entry->{$_} } sort keys(%{$entry}));
                            $self->{logger}->debug("inventory format: Removing $entrykey entry with required missing $missing: $dump");
                        }
                        if ($entrykey =~ /^(\w+)\/(\w+)$/) {
                            delete $content->{$1}->{$2};
                        } else {
                            delete $content->{$entrykey};
                        }
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

sub converted {
    my ($self) = @_;

    my $message = $self->SUPER::converted()
        or return;

    my $content = $message->{content}
        or return $message;

    # Merge content to support additional-content option
    my $merge = $self->{_merge_content};
    if ($merge) {
        foreach my $key (keys(%{$merge})) {
            if (! $content->{$key} || ref($merge->{$key}) ne 'HASH') {
                $content->{$key} = $merge->{$key};
            } else {
                if (ref($content->{$key}) eq 'HASH') {
                    foreach my $leaf (keys(%{$merge->{$key}})) {
                        $content->{$key}->{$leaf} = $merge->{$key}->{$leaf};
                    }
                } elsif ($self->{logger}) {
                    $self->{logger}->debug("content merge: skipping '$key' due to content type mismatch");
                }
            }
        }
    }

    return $message;
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
        $entry->{$value} = $entry->{$value} ? Cpanel::JSON::XS::true : Cpanel::JSON::XS::false ;
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
        my $dateordatetime = _canonicalDateordatetime($entry->{$value}, $value =~ /^BDATE$/ ? 1 : 0);
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

sub _ymd {
    my ($date) = @_;

    ## no critic (ExplicitReturnUndef)

    return unless $date && $date =~ m{^(\d{4})-(\d{2})-(\d{2})$};

    my $ymd;
    eval {
        my $dt = DateTime->new(
            year    => $1,
            month   => $2,
            day     => $3,
        );
        $ymd = $dt->ymd;
    };
    if ($EVAL_ERROR) {
        # Try inverting day and month in the case the date is malformed
        eval {
            my $dt = DateTime->new(
                year    => $1,
                month   => $3,
                day     => $2,
            );
            $ymd = $dt->ymd;
        };
    }

    return $ymd;
}

sub _canonicalDate {
    my ($date) = @_;
    return unless defined($date);
    return _ymd("$3-$2-$1") if $date =~ /^(\d{2})\/(\d{2})\/(\d{4})/;
    return _ymd($1) if $date =~ /^(\d{4}-\d{2}-\d{2})/;
    return;
}

sub _canonicalDatetime {
    my ($datetime) = @_;
    return unless defined($datetime);
    if ($datetime =~ /^(\d{2})\/(\d{2})\/(\d{4})$/) {
        my $ymd = _ymd("$3-$2-$1");
        return "$ymd 00:00:00" if $ymd;
    } elsif ($datetime =~ /^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2})$/) {
        my $time = "$2:00";
        my $ymd = _ymd($1);
        return "$ymd $time" if $ymd;
    }
    return;
}

sub _canonicalDateordatetime {
    my ($date, $inverted_month_and_day) = @_;
    return unless defined($date);
    if ($date =~ /^(\d{2})\/(\d{2})\/(\d{4})$/) {
        return $inverted_month_and_day ? _ymd("$3-$1-$2") : _ymd("$3-$2-$1");
    }
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
            $self->{logger}->debug2("Replacing $_->{SERIAL} storage serial by $_->{SERIALNUMBER}")
                if exists($_->{SERIAL}) && $_->{SERIAL} ne $_->{SERIALNUMBER};
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
