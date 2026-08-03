package GLPI::Agent::SNMP::Live;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP';

use English qw(-no_match_vars);
use UNIVERSAL::require;
use Net::SNMP;
use Net::SNMP qw/SNMP_PORT :snmp/;
use File::Spec;

use GLPI::Agent::Config;
use GLPI::Agent::Tools;

use constant    cfg_file    => "snmp-advanced-support.cfg";

# Fix support for sha(224|256|384|512) authprotocols and aes256c privprotocol if using Net::SNMP v6.0.1
GLPI::Agent::SNMP::Security::USM->require()
    if Net::SNMP->VERSION eq "v6.0.1";

my ($config, $config_load_timeout);

# etc/snmp-advanced-support.cfg configuration file can be use to change GLPI::Agent::SNMP::Live behavior
my $defaults = {
    # oids is a comma-separated list of oids used during session testing. All oids will be requested
    # and only one has to respond to validate session. If none provides any answer, this means there's
    # no device or the device is not reachable
    oids    => '.1.3.6.1.2.1.1.1.0',
    # maxrepetitions is the default value for -maxrepetitions Net::SNMP get_table() parameter during our
    # walk() api call. If set to 0, Net::SNMP will always try to use get-bulk-requests. If a device
    # doesn't support this kind of request, this option must be kept to 1 or it won't be supported.
    maxrepetitions  => 1,
    # By default, we try to discover if a device supports bulk requests but this can be disabled if that
    # check makes trouble.
    "skip-bulk-support-discovery" => 0,
    # By default, we test on mib-2.system if a device supports bulk requests
    "bulk-support-discovery-oid" => '.1.3.6.1.2.1.1',
};

sub new {
    my ($class, %params) = @_;

    die "no hostname parameters\n" unless $params{hostname};

    my $version =
        ! $params{version}       ? 'snmpv1'  :
        $params{version} eq '1'  ? 'snmpv1'  :
        $params{version} eq '2c' ? 'snmpv2c' :
        $params{version} eq '3'  ? 'snmpv3'  :
                                     undef   ;

    die "invalid SNMP version $params{version} parameter\n" unless $version;

    my $self = {
        _hostname => $params{hostname} // "not given",
    };

    # Load snmp-advanced-support.cfg configuration at worst one time by minute
    unless ($self->{_oids} && $config && $config_load_timeout && $config_load_timeout >= time) {
        $config = GLPI::Agent::Config->new(
            defaults => $defaults,
            options  => { config => "none" },
        );

        my $snmp_advanced_support_cfg = File::Spec->catfile($config->confdir(), cfg_file);
        $config->loadFromFile({
            file => $snmp_advanced_support_cfg,
        }) if -f $snmp_advanced_support_cfg;

        # Normalize configuration
        my $oids = $config->{oids};
        my @oids = map { trimWhitespace($_); /^\./ ? $_ : ".$_" } split(/,+/, $oids);
        die "invalid 'oids' configuration in $snmp_advanced_support_cfg\n"
            if $oids ne $defaults->{oids} && scalar(grep { /^\.(?:\d+\.)+\d+$/ } @oids) != scalar(@oids);
        $config->{oids} = \@oids;

        # Check values which must be a positive integer
        foreach my $key (qw(maxrepetitions skip-bulk-support-discovery)) {
            if (empty($config->{$key}) || $config->{$key} !~ /^\d+$/) {
                $config->{$key} = $defaults->{$key};
            } else {
                $config->{$key} = int($config->{$key});
            }
        }

        # Check bulk-support-discovery-oid is an oid if set
        unless (empty($config->{"bulk-support-discovery-oid"})) {
            delete $config->{"bulk-support-discovery-oid"}
                unless $config->{"bulk-support-discovery-oid"} =~ /^\.(?:\d+\.)+\d+$/;
        }

        # Reload config not before one minute
        $config_load_timeout = time + 60;
    }

    # Prepare for get-bulk-request support check
    $self->{bulk_support} = 1
        unless $version eq "snmpv1" || $config->{"skip-bulk-support-discovery"};

    # shared options
    my %options = (
        -retries  => $params{retries} // 0,
        -version  => $version,
        -hostname => $params{hostname},
        -port     => $params{port}      || SNMP_PORT,
        -domain   => $params{domain}    || 'udp/ipv4',
    );
    $options{'-timeout'} = $params{timeout} if $params{timeout};

    # version-specific options
    if ($version eq 'snmpv3') {
        # only username is mandatory
        $options{'-username'}     = $params{username};
        $options{'-authprotocol'} = $params{authprotocol}
            if $params{authprotocol};
        $options{'-authpassword'} = $params{authpassword}
            if $params{authpassword};
        $options{'-privprotocol'} = $params{privprotocol}
            if $params{privprotocol};
        $options{'-privpassword'} = $params{privpassword}
            if $params{privpassword};
        $self->{context}          = $params{contextname}
            if $params{contextname};
    } else { # snmpv2c && snmpv1
        # Save common options if we need them for vlan switching
        $self->{session_options} = { %options };
        $options{'-community'} = $params{community};
        $self->{community} = $params{community};
    }

    ($self->{session}, $self->{_session_error}) = Net::SNMP->session(%options);

    bless $self, $class;

    return $self;
}

sub testSession {
    my ($self) = @_;

    my $error = delete $self->{_session_error};
    my $host = delete $self->{_hostname};
    unless ($self->{session}) {
        die "failed to open snmp session\n" if empty($error);
        die "no response from $host host\n"
            if $error =~ /^No response from remote host/;
        die "authentication error on $host host\n"
            if $error =~ /^Received usmStats(WrongDigests|UnknownUserNames)/;
        die "Crypt::Rijndael perl module needs to be installed\n"
            if $error =~ /Required module Crypt\/Rijndael\.pm not found/;
        die $error . "\n";
    }

    my $version_id = $self->{session}->version();
    die "no version set on snmp session\n" unless defined($version_id);

    # Test if get-bulk-request is supported to enhance walk() api performance.
    # But we need to run the test only if maxrepetitions is set to 1 which is the default.
    # Also if we get an answer if means the session is established so we can return earlier.
    if ($version_id != SNMP_VERSION_1 && $self->{bulk_support} && $config->{maxrepetitions} == 1) {
        # Try to get 2 entries using walk api on configured oid or on mib-2.system
        my $test = $self->walk($config->{"bulk-support-discovery-oid"} // $defaults->{"bulk-support-discovery-oid"}, 5);
        # Bulk support and session are validated if we got expected entries;
        return if $test;
        # Finally disable bulk support for this device if test failed
        delete $self->{bulk_support};
    }

    # No need to test SNMPv3 session as still established
    return if $version_id == SNMP_VERSION_3;

    my $oids = $config->{oids} || $defaults->{oids};
    my $response = $self->{session}->get_request(
        -varbindlist => $oids,
    );
    die "no response from $host host\n"
        unless $response;
    die "missing response from $host host\n"
        unless first { defined($response->{$_}) } @{$oids};
    die "no response from $host host\n"
        if scalar(grep { $response->{$_} && $response->{$_} =~ /No response from remote host/ } @{$config->{oids}}) == scalar(@{$oids});
}

sub switch_vlan_context {
    my ($self, $vlan_id) = @_;

    if ($self->{session}->version() == &SNMP_VERSION_3) {
        $self->{_original_context} = $self->{context} // ""
            unless defined($self->{_original_context});
        $self->{context} = 'vlan-' . $vlan_id;
    } else {
        my $error;

        # create dedicated vlan_session
        $self->{vlan_session}->close() if $self->{vlan_session};
        ($self->{vlan_session}, $error) = Net::SNMP->session(
            %{$self->{session_options}},
            -community => $self->{community} . '@' . $vlan_id
        );

        die $error."\n" unless $self->{vlan_session};
    }
}

sub reset_original_context {
    my ($self) = @_;

    if ($self->{session}->version() == SNMP_VERSION_3) {
        my $original_context = delete $self->{_original_context};
        if (empty($original_context)) {
            delete $self->{context};
        } else {
            $self->{context} = $original_context;
        }
    } elsif ($self->{vlan_session}) {
        $self->{vlan_session}->close();
        delete $self->{vlan_session};
    }
}

sub get {
    my ($self, $oid) = @_;

    return unless $oid;

    my $session = $self->{vlan_session} // $self->{session};
    my %options = (-varbindlist => [$oid]);
    $options{'-contextname'} = $self->{context} if defined($self->{context});

    my $response = $session->get_request(%options);

    return unless $response;

    unless (empty($response->{$oid})) {
        return if $response->{$oid} =~ /noSuchInstance/;
        return if $response->{$oid} =~ /noSuchObject/;
        return if $response->{$oid} =~ /No response from remote host/;
    }

    my $value = $response->{$oid};

    return $value;
}

sub walk {
    my ($self, $oid, $check) = @_;

    return unless $oid;

    my $maxrepetitions = $check // $config->{maxrepetitions};

    my $session = $self->{vlan_session} // $self->{session};
    my %options = (-baseoid => $oid);
    $options{'-contextname'}    = $self->{context} if defined($self->{context});
    $options{'-maxrepetitions'} = $maxrepetitions
        if $session->version() != SNMP_VERSION_1 && $maxrepetitions &&
            # But set maxrepetitions only if forced or if test on the device failed
            ($maxrepetitions > 1 || !$self->{bulk_support});

    my $response = $session->get_table(%options);

    return unless ref($response) eq 'HASH';

    # Still return quickly when only testing if get-bulk-request is supported
    return scalar(keys(%{$response})) > 1 ? 1 : 0
        if $check;

    my $values;
    my $offset = length($oid) + 1;

    foreach my $oid (keys %{$response}) {
        my $value = $response->{$oid};
        $values->{substr($oid, $offset)} = $value;
    }

    return $values;
}

sub peer_address {
    my ($self) = @_;

    # transport() API is not documented in Net::SNMP
    my $transport = $self->{session}->transport()
        or return;

    return $transport->peer_address();
}

sub DESTROY {
    my ($self) = @_;

    $self->{vlan_session}->close() if $self->{vlan_session};
    $self->{session}->close() if $self->{session};
}

1;
__END__

=head1 NAME

GLPI::Agent::SNMP::Live - Live SNMP client

=head1 DESCRIPTION

This is the object used by the agent to perform SNMP queries on live host.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item version (mandatory)

Can be one of:

=over

=item '1'

=item '2c'

=item '3'

=back

=item timeout

The transport layer timeout

=item hostname (mandatory)

=item port

=item domain

Can be one of:

=over

=item 'udp/ipv4' (default)

=item 'udp/ipv6'

=item 'tcp/ipv4'

=item 'tcp/ipv6'

=back

=item community

=item username

=item authpassword

=item authprotocol

=item privpassword

=item privprotocol

=back
