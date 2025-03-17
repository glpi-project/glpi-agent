package GLPI::Agent::Target::Server;

use strict;
use warnings;

use parent 'GLPI::Agent::Target';

use English qw(-no_match_vars);
use URI;

use GLPI::Agent::Tools;

my $count = 0;

sub new {
    my ($class, %params) = @_;

    die "no url parameter for server target\n" unless $params{url};

    my $self = $class->SUPER::new(%params);

    $self->{url} = _getCanonicalURL($params{url});

    # compute storage subdirectory from url
    my $url = ref($self->{url}) eq "URI" ? $self->{url}->clone : URI->new($self->{url});
    $url->userinfo(undef);
    my $subdir = $url->as_string;
    $subdir =~ s/\//_/g;
    $subdir =~ s/:/../g if $OSNAME eq 'MSWin32';
    # Remove any trailing underscore
    $subdir =~ s/_+$//;

    # Provide oldvardir to eventually migrate it to newer clean version
    my $oldvardir = ref($self->{url}) eq "URI" ? $self->{url}->as_string : $self->{url};
    $oldvardir =~ s/\//_/g;
    $oldvardir =~ s/:/../g if $OSNAME eq 'MSWin32';
    # But leave it empty if not changed
    $oldvardir = "" if $subdir eq $oldvardir;

    $self->_init(
        id        => 'server' . $count++,
        vardir    => $params{basevardir} . '/' . $subdir,
        oldvardir => $oldvardir ? $params{basevardir} . '/' . $oldvardir : ""
    );

    return $self;
}

sub reset {
    $count = 0;
}

sub _getCanonicalURL {
    my ($string) = @_;

    my $url = URI->new($string);

    my $scheme = $url->scheme();
    if (!$scheme) {
        # this is likely a bare hostname
        # as parsing relies on scheme, host and path have to be set explicitely
        $url->scheme('http');
        # Eventually split on a slash to get host and path
        if ($string =~ m{^([^/]+)[/](.*)$}) {
            my ($host, $path) = ($1, $2);
            $url->host($host);
            $url->path($path // '');
        } else {
            $url->host($string);
            $url->path('');
        }
    } else {
        die "invalid protocol for URL: $string\n"
            if $scheme ne 'http' && $scheme ne 'https';
    }

    return $url;
}

sub getUrl {
    my ($self) = @_;

    return $self->{url};
}

sub getName {
    my ($self) = @_;

    my $url = ref($self->{url}) eq "URI" ? $self->{url}->clone : URI->new($self->{url});
    $url->userinfo(undef);

    return $url->as_string;
}

sub getType {
    my ($self) = @_;

    return 'server';
}

sub isGlpiServer {
    my ($self, $bool) = @_;

    if (defined($bool)) {
        if ($bool =~ /^1|true|yes$/i) {
            $self->{_is_glpi_server} = 1;
        } else {
            delete $self->{_is_glpi_server};
        }
    }

    return $self->{_is_glpi_server} // 0;
}

sub plannedTasks {
    my $self = shift @_;

    # Server can trigger any task
    if (@_) {
        $self->{tasks} = [ @_ ];
    }

    return @{$self->{tasks} || []};
}

sub setServerTaskSupport {
    my ($self, $task, $support) = @_;

    return unless $task && ref($support) eq 'HASH';
    return unless $support->{server} && $support->{version};

    $self->{_server_task_support}->{lc($task)} = $support;
}

sub doProlog {
    my $self = shift @_;

    # Always do PROLOG if target is not supporting native inventory
    # or doesn't report supported tasks as in 10.0.0-beta
    my $task_support = $self->{_server_task_support}
        or return 1;

    return any { $task_support->{$_}->{server} eq 'glpiinventory' } keys(%{$task_support});
}

sub getTaskServer {
    my ($self, $task) = @_;

    $task = lc($task);

    return unless $task && $self->{_server_task_support} && $self->{_server_task_support}->{$task};
    return $self->{_server_task_support}->{$task}->{server};
}

sub getTaskVersion {
    my ($self, $task) = @_;

    $task = lc($task);

    return $self->{_glpi} unless $task && $self->{_server_task_support} && $self->{_server_task_support}->{$task};
    return $self->{_server_task_support}->{$task}->{version} // $self->{_glpi} // '';
}

1;

__END__

=head1 NAME

GLPI::Agent::Target::Server - Server target

=head1 DESCRIPTION

This is a target for sending execution result to a server.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, in addition to those
from the base class C<GLPI::Agent::Target>, as keys of the %params
hash:

=over

=item I<url>

the server URL (mandatory)

=back

=head2 reset()

Reset the server target counter.

=head2 getUrl()

Return the server URL for this target.

=head2 getName()

Return the target name

=head2 getType()

Return the target type

=head2 plannedTasks([@tasks])

Initializes target tasks with supported ones if a list of tasks is provided

Return an array of planned tasks.

=head2 setServerTaskSupport($task, $support)

Store given task support where $support is a hash with at least "server" and "version" keys.

Return $support or undef.

=head2 doProlog()

Check if any server supported task requires us to request a PROLOG to server.

Return true or false.

=head2 getTaskServer($task)

Return server name of supported task or undef.

=head2 getTaskVersion($task)

Return version of supported task or an empty string.
