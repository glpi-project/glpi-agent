package FusionInventory::Agent::Inventory;

use strict;
use warnings;

use Config;
use Data::Dumper;
use Digest::MD5 qw(md5_base64);
use English qw(-no_match_vars);
use UNIVERSAL::require;
use XML::TreePP;

use FusionInventory::Agent::Logger;
use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Version;

# Always sort keys in Dumper while computing checksum on HASH
$Data::Dumper::Sortkeys = 1;

my %fields = (
    BIOS             => [ qw/SMODEL SMANUFACTURER SSN BDATE BVERSION
                             BMANUFACTURER MMANUFACTURER MSN MMODEL ASSETTAG
                             ENCLOSURESERIAL BIOSSERIAL
                             TYPE SKUNUMBER/ ],
    HARDWARE         => [ qw/USERID OSVERSION PROCESSORN OSCOMMENTS CHECKSUM
                             PROCESSORT NAME PROCESSORS SWAP ETIME TYPE OSNAME
                             IPADDR WORKGROUP DESCRIPTION MEMORY UUID DNS
                             LASTLOGGEDUSER USERDOMAIN DATELASTLOGGEDUSER
                             DEFAULTGATEWAY VMSYSTEM WINOWNER WINPRODID
                             WINPRODKEY WINCOMPANY WINLANG CHASSIS_TYPE
                             VMNAME VMHOSTSERIAL/ ],
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
                             PROGRAM PERL_CONFIG PERL_INC PERL_MODULE/ ]
);

my %checks = (
    STORAGES => {
        INTERFACE => qr/^(SCSI|HDC|IDE|USB|1394|Serial-ATA|SAS|SATA)$/
    },
    VIRTUALMACHINES => {
        STATUS => qr/^(running|blocked|idle|paused|shutdown|crashed|dying|off)$/
    },
    SLOTS => {
        STATUS => qr/^(free|used)$/
    },
    NETWORKS => {
        TYPE => qr/^(ethernet|wifi|infiniband|aggregate|alias|dialup|loopback|bridge|fibrechannel)$/
    },
    CPUS => {
        ARCH => qr/^(MIPS|MIPS64|Alpha|SPARC|SPARC64|m68k|i386|x86_64|PowerPC|PowerPC64|ARM|AArch64)$/
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
        logger         => $params{logger} || FusionInventory::Agent::Logger->new(),
        fields         => \%fields,
        content        => {
            HARDWARE => {
                VMSYSTEM => "Physical" # Default value
            },
            VERSIONCLIENT => $FusionInventory::Agent::AGENT_STRING ||
                $FusionInventory::Agent::Version::PROVIDER."-Inventory_v".$FusionInventory::Agent::Version::VERSION
        }
    };
    bless $self, $class;

    $self->setTag($params{tag});
    $self->{last_state_file} = $params{statedir} . '/last_state'
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

sub getDeviceId {
    my ($self) = @_;

    return $self->{deviceid} if $self->{deviceid};

    # compute an unique agent identifier based on current time and inventory
    # hostnale or provider name
    my $hostname = $self->getHardware('NAME');
    if ($hostname) {
        my $workgroup = $self->getHardware('WORKGROUP');
        $hostname .= "." . $workgroup if $workgroup;
    } else {
        FusionInventory::Agent::Tools::Hostname->require();

        eval {
            $hostname = FusionInventory::Agent::Tools::Hostname::getHostname();
        };
    }

    # Fake hostname if no default found
    $hostname = 'device-by-' . lc($FusionInventory::Agent::Version::PROVIDER) . '-agent'
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
    my ($self) = @_;

    return $self->{content};
}

sub getSection {
    my ($self, $section) = @_;
    ## no critic (ExplicitReturnUndef)
    my $content = $self->getContent() or return undef;
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

    die "no content" unless $content;

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

    # avoid duplicate entries
    if ($params{noDuplicated}) {
        my $md5 = md5_base64(Dumper($entry));
        return if $self->{seen}->{$section}->{$md5};
        $self->{seen}->{$section}->{$md5} = 1;
    }

    if ($section eq 'STORAGES') {
        $entry->{SERIALNUMBER} = $entry->{SERIAL} if !$entry->{SERIALNUMBER}
    }

    push @{$self->{content}{$section}}, $entry;
}

sub computeLegacyValues {
    my ($self) = @_;

    # CPU-related values
    my $cpus = $self->{content}->{CPUS};
    if ($cpus) {
        my $cpu = $cpus->[0];

        $self->setHardware({
            PROCESSORN => scalar @$cpus,
            PROCESSORS => $cpu->{SPEED},
            PROCESSORT => $cpu->{NAME},
        });
    }

    # network related values
    my $interfaces = $self->{content}->{NETWORKS};
    if ($interfaces) {
        my @ip_addresses =
            grep { ! /^127/ }
            grep { $_ }
            map { $_->{IPADDRESS} }
            @$interfaces;

        $self->setHardware({
            IPADDR => join('/', @ip_addresses),
        });
    }

    # user-related values
    my $users = $self->{content}->{USERS};
    if ($users) {
        my $user = $users->[-1];

        my ($domain, $id);
        if ($user->{LOGIN} =~ /(\S+)\\(\S+)/) {
            # Windows fully qualified username: domain\user
            $domain = $1;
            $id = $2;
        } else {
            # simple username: user
            $id = $user->{LOGIN};
        }

        $self->setHardware({
            USERID     => $id,
            USERDOMAIN => $domain,
        });
    }
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

        # Do not overwrite existing value with undef
        next unless $args->{$field};

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

sub computeChecksum {
    my ($self) = @_;

    my $logger = $self->{logger};

    # to apply to $checksum with an OR
    my %mask = (
        HARDWARE      => 1,
        BIOS          => 2,
        MEMORIES      => 4,
        SLOTS         => 8,
        REGISTRY      => 16,
        CONTROLLERS   => 32,
        MONITORS      => 64,
        PORTS         => 128,
        STORAGES      => 256,
        DRIVES        => 512,
        INPUT         => 1024,
        MODEMS        => 2048,
        NETWORKS      => 4096,
        PRINTERS      => 8192,
        SOUNDS        => 16384,
        VIDEOS        => 32768,
        SOFTWARES     => 65536,
    );
    # TODO CPUS is not in the list

    if ($self->{last_state_file}) {
        if (-f $self->{last_state_file}) {
            eval {
                $self->{last_state_content} = XML::TreePP->new()->parsefile(
                    $self->{last_state_file}
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
    }

    my $checksum = 0;
    foreach my $section (keys %mask) {
        my $hash =
            md5_base64(Dumper($self->{content}->{$section}));

        # check if the section did change since the last run
        next if
            $self->{last_state_content}->{$section} &&
            $self->{last_state_content}->{$section} eq $hash;

        $logger->debug("Section $section has changed since last inventory");

        # add the mask of the current section to the checksum
        $checksum |= $mask{$section}; ## no critic (ProhibitBitwise)

        # store the new value.
        $self->{last_state_content}->{$section} = $hash;
    }


    $self->setHardware({CHECKSUM => $checksum});
}

sub saveLastState {
    my ($self) = @_;

    my $logger = $self->{logger};

    if (!defined($self->{last_state_content})) {
        $self->computeChecksum();
    }
    if ($self->{last_state_file}) {
        eval {
            XML::TreePP->new()->writefile(
                $self->{last_state_file}, $self->{last_state_content}
            );
        }
    } else {
        $logger->debug(
            "last state file is not defined, last state not saved"
        );
    }

    my $tpp = XML::TreePP->new();
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Inventory - Inventory data structure

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

=item I<noDuplicated>

ignore entry if already present

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

=head2 computeLegacyValues()

Compute the inventory global values, meaning values in hardware section such as
CPU number, speed and model, computed from other values, but needed for OCS
compatibility.

=head2 saveLastState()

At the end of the process IF the inventory was saved
correctly, the last_state is saved.

=head2 getRemote()

Method to get the parent task remote status.

Returns the string set by setRemote() API or an empty string.

=head2 setRemote([$task])

Method to set or reset the parent task remote status.

Without $task parameter, the API resets the parent remote status to an empty string.
