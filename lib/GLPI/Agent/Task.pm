package GLPI::Agent::Task;

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Find;

use GLPI::Agent::Tools;
use GLPI::Agent::Logger;

sub new {
    my ($class, %params) = @_;

    die 'no target parameter' unless $params{target};

    my $self = {
        logger       => $params{logger} ||
                        GLPI::Agent::Logger->new(),
        config       => $params{config},
        datadir      => $params{datadir},
        event        => $params{event},
        credentials  => $params{credentials},
        target       => $params{target},
        deviceid     => $params{deviceid},
        agentid      => $params{agentid},
        _cached      => $params{cached_data},
        _keepcache   => defined($params{cached_data}) ? 1 : 0,
    };
    bless $self, $class;

    return $self;
}

sub abort {
    my ($self) = @_;
    $self->{logger}->info("aborting task");
}

sub getModules {
    my ($self, $task) = @_;

    $task = 'Inventory' unless $task;

    # use %INC to retrieve the root directory for this task
    my $file = module2file(__PACKAGE__."::".ucfirst($task));
    my $rootdir = $INC{$file};
    $rootdir =~ s/.pm$//;
    return unless -d $rootdir;

    # find a list of modules from files in this directory
    my $root = $file;
    $root =~ s/.pm$//;
    my @modules;
    File::Find::find(
        {
            wanted   => sub {
                return unless -f $_;
                return unless $File::Find::name =~ m{($root/\S+\.pm)$};
                my $module = file2module($1);
                push(@modules, $module);
            },
            no_chdir => 1,
        },
        $rootdir
    );
    return @modules
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

sub _deepCopy {
    my ($ref) = @_;
    return { map { $_ => _deepCopy($ref->{$_}) } keys(%{$ref}) }
        if ref($ref) eq 'HASH';
    return [ map { _deepCopy($_) } @{$ref} ]
        if ref($ref) eq 'ARRAY';
    return $ref;
}

sub cachedata {
    my ($self, $data) = @_;

    $self->{_cached} = _deepCopy($data) if defined($data);

    return $self->{_cached} if defined($self->{_cached});
}

sub keepcache {
    my ($self, $bool) = @_;

    $self->{_keepcache} = $bool if defined($bool);

    return $self->{_keepcache};
}

sub event {
    my ($self, $event) = @_;

    $self->{event} = $event if defined($event);

    return $self->{event} if defined($self->{event});
}

sub resetEvent {
    my ($self, $event) = @_;

    if (defined($event)) {
        $self->{event} = $event;
    } else {
        return delete $self->{event};
    }
}

sub newEvent {}

1;
__END__

=head1 NAME

GLPI::Agent::Task - Base class for agent task

=head1 DESCRIPTION

This is an abstract class for all task performed by the agent.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use (default: a new stderr logger)

=item I<config>

=item I<target>

=item I<storage>

=item I<prologresp>

=item I<client>

=item I<deviceid>

=back

=head2 isEnabled()

This is a method to be implemented by each subclass.

=head2 run()

This is a method to be implemented by each subclass.

=head2 abort()

Abort running task immediatly.

=head2 getModules($task)

Return a list of modules for the task. All modules installed at the same
location than this package, belonging to __PACKAGE__::$task namespace, will be
returned. If not optional $task is given, base search namespace will be
__PACKAGE__::Inventory instead.

=head2 getRemote()

Method to get the task remote status.

Returns the string set by setRemote() API or an empty string.

=head2 setRemote([$task])

Method to set or reset the task remote status.

Without $task parameter, the API resets the remote status to an empty string.
