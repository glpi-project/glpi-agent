package GLPI::Agent::SNMP::Mock;

use strict;
use warnings;
use parent 'GLPI::Agent::SNMP';

use GLPI::Agent::Tools;

my %prefixes = (
    'iso'                               => '.1',
    'SNMPv2-MIB::sysDescr'              => '.1.3.6.1.2.1.1.1',
    'SNMPv2-MIB::sysObjectID'           => '.1.3.6.1.2.1.1.2',
    'SNMPv2-MIB::sysUpTime'             => '.1.3.6.1.2.1.1.3',
    'SNMPv2-MIB::sysContact'            => '.1.3.6.1.2.1.1.4',
    'SNMPv2-MIB::sysName'               => '.1.3.6.1.2.1.1.5',
    'SNMPv2-MIB::sysLocation'           => '.1.3.6.1.2.1.1.6',
    'SNMPv2-MIB::sysORID'               => '.1.3.6.1.2.1.1.9.1.2',
    'SNMPv2-SMI::mib-2'                 => '.1.3.6.1.2.1',
    'SNMPv2-SMI::enterprises'           => '.1.3.6.1.4.1',
    'IF-MIB::ifIndex'                   => '.1.3.6.1.2.1.2.2.1.1',
    'IF-MIB::ifDescr'                   => '.1.3.6.1.2.1.2.2.1.2',
    'IF-MIB::ifType'                    => '.1.3.6.1.2.1.2.2.1.3',
    'IF-MIB::ifMtu'                     => '.1.3.6.1.2.1.2.2.1.4',
    'IF-MIB::ifSpeed'                   => '.1.3.6.1.2.1.2.2.1.5',
    'IF-MIB::ifPhysAddress'             => '.1.3.6.1.2.1.2.2.1.6',
    'IF-MIB::ifLastChange'              => '.1.3.6.1.2.1.2.2.1.9',
    'IF-MIB::ifInOctets'                => '.1.3.6.1.2.1.2.2.1.10',
    'IF-MIB::ifInErrors'                => '.1.3.6.1.2.1.2.2.1.14',
    'IF-MIB::ifOutOctets'               => '.1.3.6.1.2.1.2.2.1.16',
    'IF-MIB::ifOutErrors'               => '.1.3.6.1.2.1.2.2.1.20',
    'IF-MIB::ifName'                    => '.1.3.6.1.2.1.31.1.1.1.1',
    'HOST-RESOURCES-MIB::hrDeviceDescr' => '.1.3.6.1.2.1.25.3.2.1.3',
    'NET-SNMP-MIB::netSnmpAgentOIDs'    => '.1.3.6.1.4.1.8072.3.2',
    'ENTITY-MIB::entPhysicalIndex'       => '.1.3.6.1.2.1.47.1.1.1.1.1',
    'ENTITY-MIB::entPhysicalDescr'       => '.1.3.6.1.2.1.47.1.1.1.1.2',
    'ENTITY-MIB::entPhysicalContainedIn' => '.1.3.6.1.2.1.47.1.1.1.1.4',
    'ENTITY-MIB::entPhysicalClass'       => '.1.3.6.1.2.1.47.1.1.1.1.5',
    'ENTITY-MIB::entPhysicalName'        => '.1.3.6.1.2.1.47.1.1.1.1.7',
    'ENTITY-MIB::entPhysicalHardwareRev' => '.1.3.6.1.2.1.47.1.1.1.1.8',
    'ENTITY-MIB::entPhysicalFirmwareRev' => '.1.3.6.1.2.1.47.1.1.1.1.9',
    'ENTITY-MIB::entPhysicalSoftwareRev' => '.1.3.6.1.2.1.47.1.1.1.1.10',
    'ENTITY-MIB::entPhysicalSerialNum'   => '.1.3.6.1.2.1.47.1.1.1.1.11',
    'ENTITY-MIB::entPhysicalMfgName'     => '.1.3.6.1.2.1.47.1.1.1.1.12',
    'ENTITY-MIB::entPhysicalModelName'   => '.1.3.6.1.2.1.47.1.1.1.1.13',
    'ENTITY-MIB::entPhysicalIsFRU'       => '.1.3.6.1.2.1.47.1.1.1.1.16',
);

sub new {
    my ($class, %params) = @_;

    my $self = {
        _ip => $params{ip}
    };
    bless $self, $class;

    SWITCH: {
        if ($params{file}) {
            die "non-existing file '$params{file}'\n"
                unless -f $params{file};
            die "unreadable file '$params{file}'\n"
                unless -r $params{file};
            $self->{_file} = $params{file};
            $self->_setIndexedValues();
            last SWITCH;
        }

        if ($params{hash}) {
            $self->{_walk} = {};
            foreach my $oid (keys(%{$params{hash}})) {
                $self->_setValue($oid, $params{hash}->{$oid});
            }
            last SWITCH;
        }
    }

    return $self;
}

sub switch_vlan_context {
    my ($self, $vlan_id) = @_;

    $self->{_oldwalk} = $self->{_walk} unless $self->{_oldwalk};

    my $file = $self->{_file} . '@' . $vlan_id;
    if (-r $file && -f $file) {
        $self->_setIndexedValues($file);
    } else {
        delete $self->{_walk};
    }
}

sub reset_original_context {
    my ($self) = @_;

    $self->{_walk} = $self->{_oldwalk} if $self->{_oldwalk};
    delete $self->{_oldwalk};
}

sub _setIndexedValues {
    my ($self, $file) = @_;

    my @lines = getAllLines(file => $file || $self->{_file});

    # check first line for safety
    die "invalid file format\n" unless $lines[0] =~ /^(\S+) = .*/;

    my $numerical = substr($lines[0], 0, 1) eq '.' ? 1 : 0 ;
    my $last_value;

    $self->{_walk} = {};

    foreach my $line (@lines) {

        # Use different regex if walk contains numerical or symbolic oids
        if ($numerical) {
            if ($line =~ /^
               (\S+) \s
               = \s
               (?:Wrong \s Type \s \(should \s be \s [^:]+\): \s)?
               ([^:]+): \s
               (.*)
               /x
            ) {
                my ($oid, $type, $value) = ($1, $2, $3);
                $last_value = [ $type, $value ];
                $self->_setValue($oid, $last_value);
                next;
            }
        } else {
            if ($line =~ /^
               ([^.]+) \. ([\d.]+) \s
               = \s
               (?:Wrong \s Type \s \(should \s be \s [^:]+\): \s)?
               ([^:]+): \s
               (.*)
               /x
            ) {
                my ($mib, $suffix, $type, $value) = ($1, $2, $3, $4);

                if ($prefixes{$mib}) {
                    my $oid = $prefixes{$mib} . '.' . $suffix;
                    $last_value = [ $type, $value ];
                    $self->_setValue($oid, $last_value);
                } else {
                    # irrelevant OID
                    $last_value = undef;
                }

                next;
            }
        }

        # Don't merge end of walk delimiter in last value
        last if $line =~ /No more variables left in this MIB View/;
        last if $line =~ /^End of MIB$/;

        # potential continuation
        if ($line !~ /^$/ && $line !~ /= ""$/ && $line !~ /= STRING:$/ && $last_value) {
            if ($last_value->[0] eq 'STRING' &&
                $last_value->[1] !~ /"$/
            ) {
                $last_value->[1] .= "\n" . $line;
                next;
            } elsif ($last_value->[0] eq 'Hex-STRING') {
                $last_value->[1] .= $line;
                next;
            }
        }

        $last_value = undef;
    }
}

sub _setValue {
    my ($self, $oid, $value) = @_;

    # Optimization: use 6 first oid digits as tree root key as they don't often change
    my ($root, $nextoidpart) = $oid =~ /^(\.\d+\.\d+\.\d+\.\d+\.\d+\.\d+)(.*)$/
        or return;
    # Prepare walk tree roots with empty node while not exist
    # 1st value node will contain sub-nodes
    # 2nd value will be the numder index
    # 3rd value will be a hash of sub-index -> sub-node ref in 1st values
    # 4th value will be a SNMP value array ref like [ TYPE, VALUE ] when
    #     a value should be stored
    $self->{_walk}->{$root} = [ [], undef, {}, undef ] unless exists($self->{_walk}->{$root});
    $oid = $nextoidpart;

    my $base = $self->{_walk}->{$root};
    foreach my $num (split(/\./, substr($oid,1))) {
        # Get subnode ref if indexed
        if ($base->[2] && $base->[2]->{$num}) {
            $base = $base->[2]->{$num};
        # Otherwise initialize a new subnode
        } else {
            my $ref = [undef, $num, {}];
            # Initialize an array ref as subnode if necessary
            $base->[0] = [] unless $base->[0];
            # Push new sub-node in list
            push @{$base->[0]}, $ref;
            # Index sub-node
            $base->[2]->{$num} = $ref;
            # New subnode becomes the base node
            $base = $ref;
        }
    }
    # Keep value in leaf
    $base->[2] = undef;
    $base->[3] = $value;
}

sub _getValue {
    my ($self, $oid, $walk) = @_;

    my ($root, $nextoidpart) = $oid =~ /^(\.\d+\.\d+\.\d+\.\d+\.\d+\.\d+)(.*)$/
        or return;
    return unless exists($self->{_walk}->{$root});
    $oid = $nextoidpart;

    my $base = $self->{_walk}->{$root};

    return $base unless $oid;

    foreach my $num (split(/\./, substr($oid,1))) {
        # No value if no subnode indexed
        # Also no value if requested subnode is not indexed
        return unless $base->[2] && $base->[2]->{$num};
        $base = $base->[2]->{$num};
    }

    return $walk ? $base : $base->[3];
}

sub get {
    my ($self, $oid) = @_;

    return unless $oid;
    my $value = $self->_getValue($oid)
        or return;

    return _getSanitizedValue(
        $value->[0],
        $value->[1],
    );
}

sub _deepwalk {
    my ($base) = @_;

    my $hash = {};

    # Lookup all current base subnodes
    foreach my $ref (@{$base->[0]}) {
        # We need the subnode key as hash key
        my $key = $ref->[1];
        # Keep the value if one is available
        if (defined($ref->[3])) {
            $hash->{$key} = _getSanitizedValue(@{$ref->[3]});
        }
        # walk subnodes subnode
        if ($ref->[0]) {
            my $subkeys = _deepwalk($ref);
            foreach my $subkey (keys(%{$subkeys})) {
                # Keep subkey values
                $hash->{$key.".".$subkey} = $subkeys->{$subkey};
            }
        }
    }

    return $hash;
}

sub walk {
    my ($self, $oid) = @_;

    return unless $oid;

    my $base = $self->_getValue($oid, 1)
        or return;

    # Don't walk unless subnodes exist
    return unless $base->[0];

    return _deepwalk($base);
}

sub _getSanitizedValue {
    my ($format, $value) = @_;

    if ($format eq 'Hex-STRING') {
        $value =~ s/\s//g;
        $value = "0x".$value;
    } elsif ($format eq 'STRING') {
        $value =~ s/^(?<!\\)"//;
        $value =~ s/(?<!\\)"$//;
    } elsif ($format eq 'OID') {
        if ($value =~ /^ ([^.]+) (\.[\d.]+)? $/x) {
            my $prefix = $1;
            my $suffix = $2 || '';
            $value = $prefixes{$prefix} ?
                $prefixes{$prefix} . $suffix :
                $prefix . $suffix;
        }
    } elsif ($format =~ /timeticks/i) {
        # Keep only string part as return by SNMP get API
        $value = $1 if ($value =~ /^\s*\([\d.]+\)\s*(.*)$/x);
    }

    return $value;
}

sub peer_address {
    my ($self) = @_;

    return $self->{_ip};
}

1;
__END__

=head1 NAME

GLPI::Agent::SNMP::Mock - Mock SNMP client

=head1 DESCRIPTION

This is the object used by the agent to replay SNMP queries on snmpwalk files.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item file (mandatory)

=back
