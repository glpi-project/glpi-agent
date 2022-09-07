package GLPI::Agent::SNMP::Live;

use strict;
use warnings;
use parent 'GLPI::Agent::SNMP';

use English qw(-no_match_vars);
use Net::SNMP;
use Net::SNMP qw/SNMP_PORT/;

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

    my $self;

    # shared options
    my %options = (
        -retries  => 0,
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

    ($self->{session}, my $error) = Net::SNMP->session(%options);
    if (!$self->{session}) {
        die "no response from host $params{hostname}\n"
            if $error =~ /^No response from remote host/;
        die "authentication error on host $params{hostname}\n"
            if $error =~ /^Received usmStats(WrongDigests|UnknownUserNames)/;
        die "Crypt::Rijndael perl module needs to be installed\n"
            if $error =~ /Required module Crypt\/Rijndael\.pm not found/;
        die $error . "\n";
    }

    if ($version ne 'snmpv3') {
        my $oid = '.1.3.6.1.2.1.1.1.0';
        my $response = $self->{session}->get_request(
            -varbindlist => [$oid]
        );
        die "no response from host $params{hostname}\n"
            if !$response;
        die "missing response from host $params{hostname}\n"
            unless defined $response->{$oid};
        die "no response from host $params{hostname}\n"
            if $response->{$oid} =~ /No response from remote host/;
    }

    bless $self, $class;

    return $self;
}

sub switch_vlan_context {
    my ($self, $vlan_id) = @_;

    my $version_id = $self->{session}->version();

    my $version =
        $version_id == 0 ? 'snmpv1'  :
        $version_id == 1 ? 'snmpv2c' :
        $version_id == 3 ? 'snmpv3'  :
                             undef   ;

    my $error;
    if ($version eq 'snmpv3') {
        $self->{context} = 'vlan-' . $vlan_id;
    } else {
        # save original session
        $self->{oldsession} = $self->{session} unless $self->{oldsession};
        ($self->{session}, $error) = Net::SNMP->session(
            -timeout   => $self->{session}->timeout(),
            -retries   => 0,
            -version   => $version,
            -hostname  => $self->{session}->hostname(),
            -community => $self->{community} . '@' . $vlan_id
        );
    }

    die $error."\n" unless $self->{session};
}

sub reset_original_context {
    my ($self) = @_;

    my $version_id = $self->{session}->version();

    my $version =
        $version_id == 0 ? 'snmpv1'  :
        $version_id == 1 ? 'snmpv2c' :
        $version_id == 3 ? 'snmpv3'  :
                             undef   ;

    if ($version eq 'snmpv3') {
        delete $self->{context};
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
    $options{'-contextname'} = $self->{context} if $self->{context};

    my $response = $session->get_request(%options);

    return unless $response;

    return if $response->{$oid} =~ /noSuchInstance/;
    return if $response->{$oid} =~ /noSuchObject/;
    return if $response->{$oid} =~ /No response from remote host/;


    my $value = $response->{$oid};

    return $value;
}

sub walk {
    my ($self, $oid) = @_;

    return unless $oid;

    my $session = $self->{session};
    my %options = (-baseoid => $oid);
    $options{'-contextname'}    = $self->{context} if $self->{context};
    $options{'-maxrepetitions'} = 1                if $session->version() != 0;

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
