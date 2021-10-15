package GLPI::Agent::Target::Listener;

use strict;
use warnings;

use parent 'GLPI::Agent::Target';

use GLPI::Agent::HTTP::Session;

use constant STORE_SESSION_TIMEOUT => 10;

# Only one listener needed by agent instance
my $listener;

sub new {
    my ($class, %params) = @_;

    return $listener if $listener;

    $listener = $class->SUPER::new(%params);

    $listener->_init(
        id     => 'listener',
        vardir => $params{basevardir} . '/__LISTENER__',
    );

    # Timeout after which we want the session store to be written on disk
    $listener->{_storing_session_timer} = time + STORE_SESSION_TIMEOUT;

    return $listener;
}

sub getName {
    return 'listener';
}

sub getType {
    return 'listener';
}

# No task planned as the only purpose is to answer HTTP API
sub plannedTasks {
    return ();
}

sub inventory_xml {
    my ($self, $inventory) = @_;

    if ($inventory) {
        $self->{_inventory} = $inventory;
    } else {
        # Don't keep inventory in memory when retrieved
        return delete $self->{_inventory};
    }
}

sub session {
    my ($self, %params) = @_;

    my $sessions = $self->{sessions} || $self->_restore_sessions();

    my $session;

    my $remoteid = $params{remoteid};

    $self->{_touched_sessions} ++;

    if ($remoteid && $sessions->{$remoteid}) {
        $session = $sessions->{$remoteid};
        return $session unless $session->expired();
        delete $sessions->{$remoteid};
        delete $params{remoteid};
    }

    $session = GLPI::Agent::HTTP::Session->new(
        logger  => $self->{logger},
        timeout => $params{timeout},
        sid     => $params{remoteid},
    );

    $sessions->{$remoteid} = $session;

    return $session;
}

sub clean_session {
    my ($self, $session) = @_;

    return unless $session;

    my $sid = $session->sid()
        or return;

    my $sessions = $self->{sessions} || $self->_restore_sessions();

    if ($sessions && $sessions->{$sid}) {
        delete $sessions->{$sid};
        $self->{_touched_sessions} ++;
    }
}

sub _store_sessions {
    my ($self) = @_;

    return unless $self->{_touched_sessions} &&
        $self->{_storing_session_timer} && time >= $self->{_storing_session_timer};

    my $sessions = $self->{sessions} || $self->_restore_sessions();

    my $datas = {};

    foreach my $remoteid (keys(%{$sessions})) {
        $datas->{$remoteid} = $sessions->{$remoteid}->dump()
            unless $sessions->{$remoteid}->expired();
    }

    my $storage = $self->getStorage();
    $storage->save( name => 'Sessions', data => $datas );

    $self->{_storing_session_timer} = time + STORE_SESSION_TIMEOUT;
    $self->{_touched_sessions} = 0;
}

sub _restore_sessions {
    my ($self) = @_;

    my $sessions = {};

    my $storage = $self->getStorage();
    my $datas = $storage->restore( name => 'Sessions' );

    $datas = {} unless ref($datas) eq 'HASH';

    foreach my $remoteid (keys(%{$datas})) {
        my $data = $datas->{$remoteid};
        next unless $remoteid && ref($data) eq 'HASH';
        my %datas = map { $_ => $data->{$_} } grep { /^_/ } keys(%{$data});
        $sessions->{$remoteid} = GLPI::Agent::HTTP::Session->new(
            logger => $self->{logger},
            timer  => $data->{timer},
            nonce  => $data->{nonce},
            sid    => $remoteid,
            infos  => $data->{infos},
            %datas,
        );
        delete $sessions->{$remoteid}
            if $sessions->{$remoteid}->expired();
    }

    return $self->{sessions} = $sessions;
}

sub keep_sessions {
    my ($self) = @_;

    my $sessions = $self->{sessions} || $self->_restore_sessions();

    foreach my $session (values(%{$sessions})) {
        next unless $session->expired();
        $self->clean_session($session);
    }

    $self->_store_sessions();

    return $self->{_storing_session_timer};
}

sub sessions {
    my ($self) = @_;

    my $sessions = $self->{sessions} || $self->_restore_sessions();

    return unless keys(%{$sessions});

    return $sessions;
}

sub END {
    # Make sure to store touched sessions
    if ($listener) {
        $listener->{_storing_session_timer} = STORE_SESSION_TIMEOUT;
        $listener->_store_sessions();
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::Target::Listen - Listen target

=head1 DESCRIPTION

This is a target to serve execution result on a listening port.

=head1 METHODS

=head2 new(%params)

The constructor. The allowed parameters are the ones from the base class
C<GLPI::Agent::Target>.

=head2 getName()

Return the target name

=head2 getType()

Return the target type

=head2 plannedTasks([@tasks])

Initializes target tasks with supported ones if a list of tasks is provided

Return an array of planned tasks.

=head2 inventory_xml([$xml])

Set or retrieve an inventory XML to be used by an HTTP plugin

=head2 session(%params)

Create or retrieve a GLPI::Agent::HTTP::Session object keeping it
stored in a local storage.

Supported parameters:

=over

=item I<remoteid>

a session id used to index stored sessions

=item I<timeout>

the session timeout to use in seconds (default: 600)

=back

=head2 clean_session($session)

Remove a no more used session from the stored sessions.
