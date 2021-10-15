package GLPI::Agent::Target::Local;

use strict;
use warnings;

use parent 'GLPI::Agent::Target';

my $count = 0;

sub new {
    my ($class, %params) = @_;

    die "no path parameter for local target\n" unless $params{path};

    my $self = $class->SUPER::new(%params);

    $self->{path} = $params{path};

    $self->{format} = $params{json} ? 'json' : $params{html} ? 'html' : 'xml';

    $self->_init(
        id     => 'local' . $count++,
        vardir => $params{basevardir} . '/__LOCAL__',
    );

    return $self;
}

sub reset {
    $count = 0;
}

sub getPath {
    my ($self) = @_;

    return $self->{path};
}

sub getName {
    my ($self) = @_;

    return $self->{path};
}

sub getType {
    my ($self) = @_;

    return 'local';
}

sub plannedTasks {
    my $self = shift @_;

    # Keep only inventory as local task
    if (@_) {
        $self->{tasks} = [ grep { $_ =~ /^(Remote)?Inventory$/i } @_ ];
    }

    return @{$self->{tasks} || []};
}

1;

__END__

=head1 NAME

GLPI::Agent::Target::Local - Local target

=head1 DESCRIPTION

This is a target for storing execution result in a local folder.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, in addition to those
from the base class C<GLPI::Agent::Target>, as keys of the %params
hash:

=over

=item I<path>

the output directory path (mandatory)

=back

=head2 reset()

Reset the local target counter.

=head2 getPath()

Return the local output directory for this target.

=head2 getName()

Return the target name

=head2 getType()

Return the target type

=head2 plannedTasks([@tasks])

Initializes target tasks with supported ones if a list of tasks is provided

Return an array of planned tasks.
