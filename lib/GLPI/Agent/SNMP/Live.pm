package GLPI::Agent::SNMP::Live;

use strict;
use warnings;

use parent 'GLPI::Agent::SNMP';

use English qw(-no_match_vars);
use UNIVERSAL::require;
use Net::SNMP;
use Net::SNMP qw/SNMP_PORT :snmp/;

use GLPI::Agent::Config;
use GLPI::Agent::Tools;

# Fix support for sha(224|256|384|512) authprotocols and aes256c privprotocol if using Net::SNMP v6.0.1
GLPI::Agent::SNMP::Security::USM->require()
    if Net::SNMP->VERSION eq "v6.0.1";

my ($config, $config_load_timeout);
my $config_file = "snmp-advanced-support.cfg";

# etc/snmp-advanced-support.cfg configuration file can be use to change GLPI::Agent::SNMP::Live behavior
my $defaults = {
    # oids is a comma-separated list of oids used during session testing. All oids will be requested
    # and only one has to respond to validate session. If none provides any answer, this means there's
    # no device or the device is not reachable
    oids    => '.1.3.6.1.2.1.1.1.0',
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

        my $confdir = $config->confdir();
        $config->loadFromFile({
            file => "$confdir/$config_file",
        }) if -f "$confdir/$config_file";

        # Normalize configuration
        my @oids = map { trimWhitespace($_); /^\./ ? $_ : ".$_" } split(/,+/, $config->{oids});
        die "invalid 'oids' configuration in $confdir/$config_file\n"
            if $config->{oids} ne $defaults->{oids} && scalar(grep { /^\.(?:\d+\.)+\d+$/ } @oids) != scalar(@oids);
        $self->{_oids} = \@oids;

        # Reload config not before one minute
        $config_load_timeout = time + 60;
    }

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
    } else { # snmpv2c && snmpv1 #
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

    # No need to test SNMPv3 session as still established
    return if $version_id == SNMP_VERSION_3;

    my $response = $self->{session}->get_request(
        -varbindlist => $self->{_oids},
    );
    die "no response from $host host\n"
        unless $response;
    die "missing response from $host host\n"
        unless first { defined($response->{$_}) } @{$self->{_oids}};
    die "no response from $host host\n"
        if grep { $response->{$_} && $response->{$_} =~ /No response from remote host/ } @{$self->{_oids}} == scalar(@{$self->{_oids}});
}

sub switch_vlan_context {
    my ($self, $vlan_id) = @_;

    my $version_id = $self->{session}->version();

    my $version =
        $version_id == SNMP_VERSION_1  ? 'snmpv1'  :
        $version_id == SNMP_VERSION_2C ? 'snmpv2c' :
        $version_id == SNMP_VERSION_3  ? 'snmpv3'  :
                                          undef;

    my $error;
    if ($version eq 'snmpv3') {
        $self->{context} = 'vlan-' . $vlan_id;
    } else {
        # save original session
        $self->{oldsession} = $self->{session} unless $self->{oldsession};
        ($self->{session}, $error) = Net::SNMP->session(
            -timeout   => $self->{session}->timeout(),
            -retries   => $self->{session}->retries(),
            -version   => $version,
            -hostname  => $self->{session}->hostname(),
            -community => $self->{community} . '@' . $vlan_id
        );
    }

    die $error."\n" unless $self->{session};
}

sub reset_original_context {
    my ($self) = @_;

    if ($self->{session}->version() == SNMP_VERSION_3) {
        $self->{context} = "";
    } else {
        $self->{session} = $self->{oldsession};
        delete $self->{oldsession};
    }
}

sub get {
    my ($self, $oid) = @_;

    return unless $oid;

    my $session = $self->{session};
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
    my ($self, $oid) = @_;

    return unless $oid;

    my $session = $self->{session};
    my %options = (-baseoid => $oid);
    $options{'-contextname'}    = $self->{context} if defined($self->{context});
    $options{'-maxrepetitions'} = 1                if $session->version() != SNMP_VERSION_1;

    my $response = $session->get_table(%options);

    return unless $response;

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
