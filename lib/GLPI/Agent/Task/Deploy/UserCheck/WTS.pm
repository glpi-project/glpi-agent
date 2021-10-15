package GLPI::Agent::Task::Deploy::UserCheck::WTS;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use GLPI::Agent::Tools::Win32::WTS;

use parent "GLPI::Agent::Task::Deploy::UserCheck";

my %supported_events = (
    &IDOK       => 'ok',
    &IDCANCEL   => 'cancel',
    &IDABORT    => 'abort',
    &IDRETRY    => 'retry',
    &IDIGNORE   => 'ignore',
    &IDYES      => 'yes',
    &IDNO       => 'no',
    &IDTRYAGAIN => 'tryagain',
    &IDCONTINUE => 'continue',
    &IDTIMEOUT  => 'timeout',
    &IDASYNC    => 'async'
);

sub tell_users {
    my ($self) = @_;

    # 1. Get global WTS sessions list
    my @sessions = WTSEnumerateSessions();

    return $self->handle_event("on_nouser", "No WTS session found")
        unless (@sessions);

    # 2. Found active users in WTS sessions list
    my %users = ();
    while (@sessions) {
        my $session = shift @sessions;
        my $name = $session->{name} || '';
        my $user = $session->{user} || '';
        next unless (defined($session->{sid}) && defined($session->{state}));
        my $sessionid = $session->{sid};
        my $state     = $session->{state};
        $self->debug2("Found WTS session: #$sessionid, session '$name' for ".
            ($user?"'$user'":"no user")." (state=$state)"
        );
        next unless ($name && $user);

        # WTS Session state is defined by WTS_CONNECTSTATE_CLASS enumeration
        # See https://msdn.microsoft.com/en-us/library/aa383860(v=vs.85).aspx
        next unless ($state == 0 || $state == 1);

        $users{$sessionid} = $user;
    }

    @sessions = sort keys(%users);
    return $self->handle_event("on_nouser", "No active user session found")
        unless (@sessions);

    return $self->handle_event("on_multiusers", "Multiple user sessions found")
        unless (@sessions == 1 || $self->always_ask_users());

    # 3. Send message to each active user using WTS message
    while (@sessions) {
        my $sid = shift @sessions;
        my %message = (
            title   => $self->{title}   || 'No title',
            text    => $self->{text}    || 'Sorry, message is missing',
            icon    => $self->{icon}    || 'none',
            buttons => $self->{buttons} || 'ok',
            timeout => $self->{timeout},
            wait    => $self->{wait}
        );

        # Keep user for reported event
        $self->setUser( $users{$sid} );

        # Support %u replacement in text and title
        $message{title} =~ s/\%u/$users{$sid}/g;
        $message{text} =~ s/\%u/$users{$sid}/g;

        my $sending = $self->{wait} ? 'Sending' : 'Async' ;
        $self->debug2("WTS session #$sid: $sending message to $users{$sid} with '$message{title}' title");

        # Send message with WTS API
        my $asked = time;
        my $answer = WTSSendMessage($sid, \%message);

        my $support = $supported_events{"$answer"} || 'unknown';
        $self->debug2("WTS session #$sid: Got $answer as $support answer code after ".(time-$asked)." seconds");

        last if $self->handle_event('on_'.$support);
    }
}

1;
