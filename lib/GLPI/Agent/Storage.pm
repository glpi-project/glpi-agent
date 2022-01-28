package GLPI::Agent::Storage;

use strict;
use warnings;

use Config;
use English qw(-no_match_vars);
use File::Path qw(mkpath);
use File::stat;
use Storable;

use GLPI::Agent::Logger;

sub new {
    my ($class, %params) = @_;

    die "no directory parameter" unless $params{directory};
    if (!-d $params{directory}) {
        # {error => \my $err} is not supported on RHEL 5,
        # we let mkpath call die() itself
        # http://forge.fusioninventory.org/issues/1817
        eval {
            mkpath($params{directory});
        };
        die "Can't create $params{directory}: $EVAL_ERROR" if $EVAL_ERROR;
    }

    if (! -w $params{directory} && !$params{read_only}) {
        die "Can't write in $params{directory}";
    }

    my $self = {
        logger    => $params{logger} ||
                     GLPI::Agent::Logger->new(),
        _mtime    => {},
        directory => $params{directory}
    };

    bless $self, $class;

    return $self;
}

sub getDirectory {
    my ($self) = @_;

    return $self->{directory};
}

sub _getFilePath {
    my ($self, %params) = @_;

    die "no name parameter given" unless $params{name};

    return $self->{directory} . '/' . $params{name} . '.dump';
}

sub has {
    my ($self, %params) = @_;

    my $file = $self->_getFilePath(%params);

    return -f $file;
}

sub _cache_mtime {
    my ($self, $file) = @_;

    my $st = stat($file)
        or return;

    $self->{_mtime}->{$file} = $st->mtime;
}

sub modified {
    my ($self, %params) = @_;

    my $file = $self->_getFilePath(%params);

    return unless $self->{_mtime}->{$file};

    my $st = stat($file);

    return $st && $st->mtime > $self->{_mtime}->{$file} ? 1 : 0;
}

sub save {
    my ($self, %params) = @_;

    my $file = $self->_getFilePath(%params);

    store($params{data}, $file) or warn;

    $self->_cache_mtime($file);
}

sub restore {
    my ($self, %params) = @_;

    my $file = $self->_getFilePath(%params);

    return unless -f $file;

    my $result;
    eval {
        $result = retrieve($file);
    };
    if ($EVAL_ERROR) {
        $self->{logger}->error("Can't read corrupted $file, removing it");
        unlink $file;
    }

    $self->_cache_mtime($file);

    return $result;
}

sub remove {
    my ($self, %params) = @_;

    my $file = $self->_getFilePath(%params);

    unlink $file or $self->{logger}->error("can't unlink $file");

    delete $self->{_mtime}->{$file};
}

1;
__END__

=head1 NAME

GLPI::Agent::Storage - A data serializer/deserializer

=head1 SYNOPSIS

  my $storage = GLPI::Agent::Storage->new(
      directory => '/tmp'
  );
  my $data = $storage->restore(
      name => "foobar"
  );

  $data->{foo} = 'bar';

  $storage->save(
      name => "foobar",
      data => $data
  );

=head1 DESCRIPTION

This is the object used by the agent to ensure data persistancy between
invocations.

The data structure is saved in a dedicated file. The file directory is a
configuration parameter for each object.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use

=item I<directory>

the directory to use for storing data (mandatory)

=back

=head2 getDirectory

Returns the underlying directory for this storage.

=head2 has(%params)

Returns true if a saved data structure exists. The following arguments are
allowed:

=over

=item I<name>

The file name to use for saving the data structure (mandatory).

=back

=head2 save(%params)

Save given data structure. The following parameters are allowed, as keys of the
%params hash:

=over

=item I<name>

The file name to use for saving the data structure (mandatory).

=item I<data>

The data to be saved (mandatory).

=back

=head2 restore(%params)

Restore a saved data structure. The following parameters are allowed, as keys
of the %params hash:

=over

=item I<name>

The file name to use for saving the data structure (mandatory).

=back

=head2 remove(%params)

Delete the file containing a seralized data structure for a given file name. The
following parameters are allowed, as keys of the %params hash:

=over

=item I<name>

The file name used to save the data structure (mandatory).

=back
