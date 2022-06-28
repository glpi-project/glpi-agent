package GLPI::Agent::Inventory;

use strict;
use warnings;

use Config;
use Digest::SHA;
use English qw(-no_match_vars);
use UNIVERSAL::require;

use GLPI::Agent::Logger;
use GLPI::Agent::Tools;
use GLPI::Agent::Version;

use GLPI::Agent::Protocol::Message;

my %fields = (
    BIOS             => [ qw/SMODEL SMANUFACTURER SSN BDATE BVERSION
                             BMANUFACTURER MMANUFACTURER MSN MMODEL ASSETTAG
                             ENCLOSURESERIAL BIOSSERIAL
                             SKUNUMBER/ ],
    HARDWARE         => [ qw/NAME SWAP TYPE WORKGROUP DESCRIPTION MEMORY UUID DNS
                             LASTLOGGEDUSER DATELASTLOGGEDUSER
                             DEFAULTGATEWAY VMSYSTEM WINOWNER WINPRODID
                             WINPRODKEY WINCOMPANY WINLANG CHASSIS_TYPE
                             / ],
    OPERATINGSYSTEM  => [ qw/KERNEL_NAME KERNEL_VERSION NAME VERSION FULL_NAME
                             SERVICE_PACK INSTALL_DATE FQDN DNS_DOMAIN HOSTID
                             SSH_KEY ARCH BOOT_TIME TIMEZONE/ ],
    ACCESSLOG        => [ qw/USERID LOGDATE/ ],

    ANTIVIRUS        => [ qw/COMPANY ENABLED GUID NAME UPTODATE VERSION
                             EXPIRATION BASE_CREATION BASE_VERSION/ ],
    BATTERIES        => [ qw/CAPACITY CHEMISTRY DATE NAME SERIAL MANUFACTURER
                             VOLTAGE REAL_CAPACITY/ ],
    CONTROLLERS      => [ qw/CAPTION DRIVER NAME MANUFACTURER PCICLASS VENDORID
                             SERIAL MODEL
                             PRODUCTID PCISUBSYSTEMID PCISLOT TYPE REV/ ],
    CPUS             => [ qw/CACHE CORE DESCRIPTION MANUFACTURER NAME THREAD
                             SERIAL STEPPING FAMILYNAME FAMILYNUMBER MODEL
                             SPEED ID EXTERNAL_CLOCK ARCH CORECOUNT/ ],
    DATABASES_SERVICES
                     => [ qw/TYPE NAME VERSION MANUFACTURER PORT PATH SIZE
                             IS_ACTIVE IS_ONBACKUP LAST_BOOT_DATE LAST_BACKUP_DATE
                             DATABASES/ ],
    DRIVES           => [ qw/CREATEDATE DESCRIPTION FREE FILESYSTEM LABEL
                             LETTER SERIAL SYSTEMDRIVE TOTAL TYPE VOLUMN
                             ENCRYPT_NAME ENCRYPT_ALGO ENCRYPT_STATUS ENCRYPT_TYPE/ ],
    ENVS             => [ qw/KEY VAL/ ],
    INPUTS           => [ qw/NAME MANUFACTURER CAPTION DESCRIPTION INTERFACE
                             LAYOUT POINTINGTYPE TYPE/ ],
    FIREWALL         => [ qw/PROFILE STATUS DESCRIPTION IPADDRESS IPADDRESS6/ ],
    LICENSEINFOS     => [ qw/NAME FULLNAME KEY COMPONENTS TRIAL UPDATE OEM
                             ACTIVATION_DATE PRODUCTID/ ],
    LOCAL_GROUPS     => [ qw/ID MEMBER NAME/ ],
    LOCAL_USERS      => [ qw/HOME ID LOGIN NAME SHELL/ ],
    LOGICAL_VOLUMES  => [ qw/LV_NAME VG_NAME ATTR SIZE LV_UUID SEG_COUNT
                             VG_UUID/ ],
    MEMORIES         => [ qw/CAPACITY CAPTION FORMFACTOR REMOVABLE PURPOSE
                             SPEED SERIALNUMBER TYPE DESCRIPTION NUMSLOTS
                             MEMORYCORRECTION MANUFACTURER MODEL/ ],
    MODEMS           => [ qw/DESCRIPTION NAME TYPE MODEL/ ],
    MONITORS         => [ qw/BASE64 CAPTION DESCRIPTION MANUFACTURER SERIAL
                             UUENCODE NAME TYPE ALTSERIAL PORT/ ],
    NETWORKS         => [ qw/DESCRIPTION MANUFACTURER MODEL MANAGEMENT TYPE
                             VIRTUALDEV MACADDR WWN DRIVER FIRMWARE PCIID
                             PCISLOT PNPDEVICEID MTU SPEED STATUS SLAVES BASE
                             IPADDRESS IPSUBNET IPMASK IPDHCP IPGATEWAY
                             IPADDRESS6 IPSUBNET6 IPMASK6 WIFI_BSSID WIFI_SSID
                             WIFI_MODE WIFI_VERSION/ ],
    PHYSICAL_VOLUMES => [ qw/DEVICE PV_PE_COUNT PV_UUID FORMAT ATTR
                             SIZE FREE PE_SIZE VG_UUID/ ],
    PORTS            => [ qw/CAPTION DESCRIPTION NAME TYPE/ ],
    POWERSUPPLIES    => [ qw/PARTNUM SERIALNUMBER MANUFACTURER POWER_MAX NAME
                             HOTREPLACEABLE PLUGGED STATUS LOCATION MODEL/ ],
    PRINTERS         => [ qw/COMMENT DESCRIPTION DRIVER NAME NETWORK PORT
                             RESOLUTION SHARED STATUS ERRSTATUS SERVERNAME
                             SHARENAME PRINTPROCESSOR SERIAL/ ],
    PROCESSES        => [ qw/USER PID CPUUSAGE MEM VIRTUALMEMORY TTY STARTED
                             CMD/ ],
    REGISTRY         => [ qw/NAME REGVALUE HIVE/ ],
    REMOTE_MGMT      => [ qw/ID TYPE/ ],
    RUDDER           => [ qw/AGENT UUID HOSTNAME SERVER_ROLES AGENT_CAPABILITIES/ ],
    SLOTS            => [ qw/DESCRIPTION DESIGNATION NAME STATUS/ ],
    SOFTWARES        => [ qw/COMMENTS FILESIZE FOLDER FROM HELPLINK INSTALLDATE
                            NAME NO_REMOVE RELEASE_TYPE PUBLISHER
                            UNINSTALL_STRING URL_INFO_ABOUT VERSION
                            VERSION_MINOR VERSION_MAJOR GUID ARCH USERNAME
                            USERID SYSTEM_CATEGORY/ ],
    SOUNDS           => [ qw/CAPTION DESCRIPTION MANUFACTURER NAME/ ],
    STORAGES         => [ qw/DESCRIPTION DISKSIZE INTERFACE MANUFACTURER MODEL
                            NAME TYPE SERIAL SERIALNUMBER FIRMWARE SCSI_COID
                            SCSI_CHID SCSI_UNID SCSI_LUN WWN
                            ENCRYPT_NAME ENCRYPT_ALGO ENCRYPT_STATUS ENCRYPT_TYPE/ ],
    VIDEOS           => [ qw/CHIPSET MEMORY NAME RESOLUTION PCISLOT PCIID/ ],
    USBDEVICES       => [ qw/VENDORID PRODUCTID MANUFACTURER CAPTION SERIAL
                            CLASS SUBCLASS NAME/ ],
    USERS            => [ qw/LOGIN DOMAIN/ ],
    VIRTUALMACHINES  => [ qw/MEMORY NAME UUID STATUS SUBSYSTEM VMTYPE VCPU
                             MAC COMMENT OWNER SERIAL IMAGE/ ],
    VOLUME_GROUPS    => [ qw/VG_NAME PV_COUNT LV_COUNT ATTR SIZE FREE VG_UUID
                             VG_EXTENT_SIZE/ ],
    VERSIONPROVIDER  => [ qw/NAME VERSION COMMENTS PERL_EXE PERL_VERSION PERL_ARGS
                             PROGRAM PERL_CONFIG PERL_INC PERL_MODULE ETIME/ ]
);

my %checks = (
    BIOS => {
        SECURE_BOOT => qr/^(enabled|disabled|unsupported)$/
    },
    STORAGES => {
        STATUS    => qr/^(up|down)$/,
        INTERFACE => qr/^(SCSI|HDC|IDE|USB|1394|SATA|SAS|ATAPI)$/
    },
    VIRTUALMACHINES => {
        STATUS => qr/^(running|blocked|idle|paused|shutdown|crashed|dying|off)$/
    },
    SLOTS => {
        STATUS => qr/^(free|used)$/
    },
    NETWORKS => {
        TYPE => qr/^(ethernet|wifi|infiniband|aggregate|alias|dialup|loopback|bridge|fibrechannel|bluetooth)$/
    },
    CPUS => {
        ARCH => qr/^(mips|mips64|alpha|sparc|sparc64|m68k|i386|x86_64|powerpc|powerpc64|arm.*|aarch64)$/
    }
);

# convert fields list into fields hashes, for fast lookup
foreach my $section (keys %fields) {
    $fields{$section} = { map { $_ => 1 } @{$fields{$section}} };
}

sub new {
    my ($class, %params) = @_;

    my $self = {
        deviceid       => $params{deviceid},
        logger         => $params{logger} || GLPI::Agent::Logger->new(),
        fields         => \%fields,
        _format        => '',
        content        => {
            HARDWARE => {
                VMSYSTEM => "Physical" # Default value
            },
            VERSIONCLIENT => $GLPI::Agent::AGENT_STRING ||
                $GLPI::Agent::Version::PROVIDER."-Inventory_v".$GLPI::Agent::Version::VERSION
        }
    };
    bless $self, $class;

    $self->setTag($params{tag});
    $self->{last_state_file} = $params{statedir} . '/last_state.json'
        if $params{statedir};

    return $self;
}

sub getRemote {
    my ($self) = @_;

    return $self->{_remote} || '';
}

sub setRemote {
    my ($self, $task) = @_;

    $self->{_remote} = $task || '';

    return $self->{_remote};
}

sub getFormat {
    my ($self) = @_;

    return $self->{_format};
}

sub setFormat {
    my ($self, $format) = @_;

    $self->{_format} = $format // 'json';
}

sub isPartial {
    my ($self, $partial) = @_;

    return $self->{_partial} unless defined($partial);

    $self->{_partial} = $partial;
}

sub getDeviceId {
    my ($self) = @_;

    return $self->{deviceid} if $self->{deviceid};

    # compute an unique agent identifier based on current time and inventory
    # hostnale or provider name
    my $hostname = $self->{content}->{HARDWARE}->{NAME};
    if ($hostname) {
        my $workgroup = $self->{content}->{HARDWARE}->{WORKGROUP};
        $hostname .= "." . $workgroup if $workgroup;
    } else {
        GLPI::Agent::Tools::Hostname->require();

        eval {
            $hostname = GLPI::Agent::Tools::Hostname::getHostname();
        };
    }

    # Fake hostname if no default found
    $hostname = 'device-by-' . lc($GLPI::Agent::Version::PROVIDER) . '-agent'
        unless $hostname;

    my ($year, $month , $day, $hour, $min, $sec) =
        (localtime (time))[5, 4, 3, 2, 1, 0];

    return $self->{deviceid} = sprintf "%s-%02d-%02d-%02d-%02d-%02d-%02d",
        $hostname, $year + 1900, $month + 1, $day, $hour, $min, $sec;
}

sub getFields {
    my ($self) = @_;

    return $self->{fields};
}

sub getContent {
    my ($self, %params) = @_;

    if ($self->{_format} eq 'json') {
        die "Can't load GLPI Protocol Inventory library\n"
            unless GLPI::Agent::Protocol::Inventory->require();

        my $content = GLPI::Agent::Protocol::Inventory->new(
            logger      => $self->{logger},
            deviceid    => $self->getDeviceId(),
            content     => $self->{content},
            partial     => $self->isPartial(),
            itemtype    => "Computer",
        );

        # Support json file on additional-content with json output
        $content->mergeContent(content => delete $self->{_json_merge})
            if $self->{_json_merge};

        # Normalize content to follow inventory format specs from https://github.com/glpi-project/inventory_format
        $content->normalize($params{server_version});

        return $content;

    } elsif ($self->{_format} eq 'xml') {
        # Fix inventory for deprecated XML format
        if ($self->{content}->{VERSIONPROVIDER} && defined($self->{content}->{VERSIONPROVIDER}->{ETIME})) {
            $self->{content}->{HARDWARE}->{ETIME} = delete $self->{content}->{VERSIONPROVIDER}->{ETIME};
        }
    }

    return $self->{content};
}

sub getSection {
    my ($self, $section) = @_;
    ## no critic (ExplicitReturnUndef)
    my $content = $self->{content} or return undef;
    return exists($content->{$section}) ? $content->{$section} : undef ;
}

sub getField {
    my ($self, $section, $field) = @_;
    ## no critic (ExplicitReturnUndef)
    $section = $self->getSection($section) or return undef;
    return exists($section->{$field}) ? $section->{$field} : undef ;
}

sub mergeContent {
    my ($self, $content) = @_;

    die "no content to merge\n" unless $content;

    if ($self->getFormat() eq 'json') {
        $self->{_json_merge} = $content;
        return;
    }

    foreach my $section (keys %$content) {
        if (ref $content->{$section} eq 'ARRAY') {
            # a list of entry
            foreach my $entry (@{$content->{$section}}) {
                $self->addEntry(section => $section, entry => $entry);
            }
        } else {
            # single entry
            SWITCH: {
                if ($section eq 'HARDWARE') {
                    $self->setHardware($content->{$section});
                    last SWITCH;
                }
                if ($section eq 'OPERATINGSYSTEM') {
                    $self->setOperatingSystem($content->{$section});
                    last SWITCH;
                }
                if ($section eq 'BIOS') {
                    $self->setBios($content->{$section});
                    last SWITCH;
                }
                if ($section eq 'ACCESSLOG') {
                    $self->setAccessLog($content->{$section});
                    last SWITCH;
                }
                $self->addEntry(
                    section => $section, entry => $content->{$section}
                );
            }
        }
    }
}

sub addEntry {
    my ($self, %params) = @_;

    my $entry = $params{entry};
    die "no entry" unless $entry;

    my $section = $params{section};
    my $fields = $fields{$section};
    my $checks = $checks{$section};
    die "unknown section $section" unless $fields;

    foreach my $field (keys %$entry) {
        if (!$fields->{$field}) {
            # unvalid field, log error and remove
            $self->{logger}->debug("unknown field $field for section $section");
            delete $entry->{$field};
            next;
        }
        if (!defined $entry->{$field}) {
            # undefined value, remove
            delete $entry->{$field};
            next;
        }
        # sanitize value
        my $value = getSanitizedString($entry->{$field});
        # check value if appliable
        if ($checks->{$field}) {
            $self->{logger}->debug(
                "invalid value $value for field $field for section $section"
            ) unless $value =~ $checks->{$field};
        }
        $entry->{$field} = $value;
    }

    if ($section eq 'STORAGES') {
        $entry->{SERIALNUMBER} = $entry->{SERIAL} if !$entry->{SERIALNUMBER}
    }

    push @{$self->{content}{$section}}, $entry;
}

sub setEntry {
    my ($self, %params) = @_;
    $self->addEntry(%params);
    my $section = $params{section};
    my $entry = shift @{$self->{content}->{$section}};
    $self->{content}->{$section} = $entry;
}

sub getHardware {
    my ($self, $field) = @_;
    return $self->getField('HARDWARE', $field);
}

sub setHardware {
    my ($self, $args) = @_;

    foreach my $field (keys %$args) {
        if (!$fields{HARDWARE}->{$field}) {
            $self->{logger}->debug("unknown field $field for section HARDWARE");
            next
        }

        # Do not overwrite existing value with undef or empty
        next unless defined($args->{$field}) && length($args->{$field});

        $self->{content}->{HARDWARE}->{$field} =
            getSanitizedString($args->{$field});
    }
}

sub setOperatingSystem {
    my ($self, $args) = @_;

    foreach my $field (keys %$args) {
        if (!$fields{OPERATINGSYSTEM}->{$field}) {
            $self->{logger}->debug(
                "unknown field $field for section OPERATINGSYSTEM"
            );
            next
        }
        $self->{content}->{OPERATINGSYSTEM}->{$field} =
            getSanitizedString($args->{$field});
    }
}

sub getBios {
    my ($self, $field) = @_;
    return $self->getField('BIOS', $field);
}

sub setBios {
    my ($self, $args) = @_;

    foreach my $field (keys %$args) {
        if (!$fields{BIOS}->{$field}) {
            $self->{logger}->debug("unknown field $field for section BIOS");
            next
        }

        $self->{content}->{BIOS}->{$field} =
            getSanitizedString($args->{$field});
    }
}

sub setAccessLog {
    my ($self, $args) = @_;

    foreach my $field (keys %$args) {
        if (!$fields{ACCESSLOG}->{$field}) {
            $self->{logger}->debug(
                "unknown field $field for section ACCESSLOG"
            );
            next
        }

        $self->{content}->{ACCESSLOG}->{$field} =
            getSanitizedString($args->{$field});
    }
}

sub setTag {
    my ($self, $tag) = @_;

    return unless $tag;

    $self->{content}{ACCOUNTINFO} = [{
        KEYNAME  => "TAG",
        KEYVALUE => $tag
    }];

}

my @checked_sections = sort qw(
    HARDWARE    BIOS        MEMORIES    SLOTS       REGISTRY    CONTROLLERS
    MONITORS    PORTS       STORAGES    DRIVES      INPUTS      MODEMS
    NETWORKS    PRINTERS    SOUNDS      SOFTWARES   VIDEOS      CPUS
    ANTIVIRUS   BATTERIES   FIREWALL    OPERATINGSYSTEM         LICENSEINFOS
    VIRTUALMACHINES
);

sub _checksum {
    my ($key, $ref, $sha, $len) = @_;

    unless (defined($sha)) {
        $sha = Digest::SHA->new(256);
        $len = 0;
    }

    if (ref($ref) eq 'HASH') {
        foreach my $subkey (sort keys(%{$ref})) {
            ($sha, $len) = _checksum($subkey, $ref->{$subkey}, $sha, $len);
        }
    } elsif (ref($ref) eq 'ARRAY') {
        map { ($sha, $len) = _checksum($key, $_, $sha, $len) } @{$ref};
    } elsif (defined($ref)) {
        my $string = "$key:$ref.";
        my $strlen = length($string);
        $len += $strlen;
        $sha->add_bits($string, $strlen*8);
    }

    return $sha, $len;
}

sub computeChecksum {
    my ($self) = @_;

    my $logger = $self->{logger};

    my $last_state;
    if ($self->{last_state_file} && !$self->{last_state_content}) {
        if (-f $self->{last_state_file}) {
            eval {
                $last_state = GLPI::Agent::Protocol::Message->new(
                    file    => $self->{last_state_file},
                );
            };
            if (ref($self->{last_state_content}) ne 'HASH') {
                $self->{last_state_content} = {};
            }
        } else {
            $logger->debug(
                "last state file '$self->{last_state_file}' doesn't exist"
            );
        }
    } else {
        $last_state = $self->{last_state_content};
    }
    $last_state = GLPI::Agent::Protocol::Message->new() unless $last_state;

    my $save_state = 0;
    foreach my $section (@checked_sections) {
        my ($sha, $len) = _checksum($section, $self->{content}->{$section});
        my $state = $last_state->get($section);
        unless ($len) {
            if (defined($state)) {
                $logger->debug("Section $section has disappeared since last inventory");
                $last_state->delete($section);
                $save_state++;
            }
            next;
        }
        my $digest = $sha->hexdigest;

        # check if the section did change since the last run
        next if ref($state) eq 'HASH' &&
            defined($state->{len}) && $state->{len} == $len &&
            defined($state->{digest}) && $state->{digest} eq $digest;

        $logger->debug("Section $section has changed since last inventory");

        # store the new value.
        $last_state->merge(
            $section    => {
                digest => $digest,
                len    => $len,
            }
        );
        $save_state++;
    }

    $self->{last_state_content} = $last_state;

    $self->_saveLastState() if $save_state;
}

sub _saveLastState {
    my ($self) = @_;

    return unless $self->{last_state_content};

    my $logger = $self->{logger};

    if ($self->{last_state_file}) {
        my $fh;
        if (open($fh, ">", $self->{last_state_file})) {
            print $fh $self->{last_state_content}->getRawContent();
            close($fh);
        } else {
            $logger->debug("can't create last state file, last state not saved: $!");
        }
    } else {
        $logger->debug("last state file is not defined, last state not saved");
    }
}

sub credentials {
    my ($self, $credentials) = @_;

    return $self->{_credentials}
        unless ref($credentials) eq "ARRAY";

    my $index = 0;
    foreach my $definition (@{$credentials}) {
        my $hash = {};
        my $string = $definition;
        my ($key,$value);
        while ($string) {
            ($key, $string) = $string =~ /^(\w+):(.*)$/;
            next unless $key;
            if (defined($string) && length($string)) {
                if ($string =~ /^(['"])/) {
                    my $quote = $1;
                    my $replace = ',' x ord($quote);
                    $string =~ s/\\$quote/\\$replace/g;
                    ($value, $string) = $string =~ /^[$quote]([^$quote]+)[$quote](.*)$/;
                    $value  =~ s/\\$replace/$quote/g;
                    $string =~ s/\\$replace/\\$quote/g;
                } else {
                    ($value, $string) = $string =~ /^([^,]+)(.*)$/;
                }
                $hash->{$key} = $value;
                undef $value;
                if (length($string)) {
                    # Invalidate credential if not on a comma
                    unless ($string =~ /^,+/) {
                        $hash = {};
                        last;
                    }
                    $string =~ s/^,+//;
                }
            }
        }
        unless (keys(%{$hash})) {
            $self->{logger}->debug("Invalid credential definition: $definition");
            next;
        }
        unless (exists($hash->{params_id})) {
            $hash->{params_id} = $index;
        }
        $index++;
        push @{$self->{_credentials}}, $hash;
    }
}

1;
__END__

=head1 NAME

GLPI::Agent::Inventory - Inventory data structure

=head1 DESCRIPTION

This is a data structure corresponding to an hardware and software inventory.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the
%params hash:

=over

=item I<logger>

a logger object

=item I<statedir>

a path to a writable directory containing the last serialized inventory

=item I<tag>

an arbitrary label, used for server-side filtering

=back

=head2 getContent()

Get content attribute.

=head2 getSection($section)

Get full machine inventory section.

=head2 getField($section,$field)

Get a field from a full machine inventory section.

=head2 mergeContent($content)

Merge content to the inventory.

=head2 addEntry(%params)

Add a new entry to the inventory. The following parameters are allowed, as keys
of the %params hash:

=over

=item I<section>

the entry section (mandatory)

=item I<entry>

the entry (mandatory)

=back

=head2 setTag($tag)

Set inventory tag, an arbitrary label used for filtering on server side.

=head2 getHardware($field)

Get machine global information from known machine inventory.

=head2 setHardware()

Save global information regarding the machine.

=head2 setOperatingSystem()

Operating System information.

=head2 getBios($field)

Get BIOS information from known inventory.

=head2 setBios()

Set BIOS information.

=head2 setAccessLog()

What is that for? :)

=head2 computeChecksum()

Compute the inventory checksum. This information is used by the server to
know which parts of the inventory have changed since the last one.

=head2 getRemote()

Method to get the parent task remote status.

Returns the string set by setRemote() API or an empty string.

=head2 setRemote([$task])

Method to set or reset the parent task remote status.

Without $task parameter, the API resets the parent remote status to an empty string.
