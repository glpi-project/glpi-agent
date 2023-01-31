package GLPI::Agent::Task::Deploy::Datastore;

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Glob;
use File::Spec;
use File::Path qw(make_path);
use UNIVERSAL::require;

use GLPI::Agent::Tools;
use GLPI::Agent::Logger;
use GLPI::Agent::Storage;
use GLPI::Agent::Task::Deploy::Datastore::WorkDir;
use GLPI::Agent::Task::Deploy::DiskFree;

sub new {
    my ($class, %params) = @_;

    die "$class: No path parameter\n" unless $params{path};

    my $self = {
        config => $params{config},
        path   => File::Spec->rel2abs($params{path}),
        logger => $params{logger} ||
                  GLPI::Agent::Logger->new(),
    };

    die("$class: No datastore path\n") unless $self->{path};

    $self->{path} = File::Spec->catdir($self->{path}, "deploy");

    bless $self, $class;

    return $self;
}

sub cleanUp {
    my ($self) = @_;

    return unless -d $self->{path};

    my @storageDirs;
    push @storageDirs, File::Glob::bsd_glob(File::Spec->catdir($self->{path}, "fileparts", "private", "*"));
    push @storageDirs, File::Glob::bsd_glob(File::Spec->catdir($self->{path}, "fileparts", "shared", "*"));

    remove_tree(File::Spec->catdir($self->{path}, "workdir"));

    # Compute diskIsFull after workdir has been cleaned up and before we start to clean up fileparts
    my $diskIsFull = $self->diskIsFull();

    # We will check retention time using a one minute time frame
    my $timeframe = time - time % 60;

    my $remaining = 0;
    foreach my $dir (@storageDirs) {

        unless (-d $dir) {
            unlink $dir;
            next;
        }

        my ($timestamp) = $dir =~ /(\d+)$/
            or next;

        if ($diskIsFull || $timeframe >= $timestamp) {
            remove_tree( $dir );
        } else {
            $remaining ++;
        }
    }

    remove_tree($self->{path}) unless $remaining;

    # Returns remaining file parts so Maintenance event knows if it must be scheduled again
    return $remaining;
}

sub createWorkDir {
    my ($self, $uuid) = @_;

    my $path = File::Spec->catdir($self->{path}, "workdir", $uuid);

    make_path($path);
    return unless -d $path;

    return GLPI::Agent::Task::Deploy::Datastore::WorkDir->new(
        path => $path,
        logger => $self->{logger}
    );
}

sub diskIsFull {
    my ($self) = @_;

    my $logger = $self->{logger};

    return 0 unless -d $self->{path};

    my $freeSpace = getFreeSpace(
        path => $self->{path},
        logger => $logger
    );

    unless (defined($freeSpace)) {
        $logger->debug2('$freeSpace is undef!');
        $freeSpace = 0;
    }

    $logger->debug("Free space on $self->{path}: $freeSpace");
    # 2GB Free, should be set by a config option
    return $freeSpace < 2000 ? 1 : 0;
}

sub getP2PNet {
    my ($self) = @_;

    if (!$self->{p2pnetstorage}) {
        $self->{p2pnetstorage} = GLPI::Agent::Storage->new(
            logger    => $self->{logger},
            directory => $self->{config}->{vardir}
        );
    }

    return unless $self->{p2pnetstorage};

    return $self->{p2pnetstorage}->restore( name => "p2pnet" );
}

sub saveP2PNet {
    my ($self, $peers) = @_;

    return unless $self->{p2pnetstorage};

    # Avoid to save the peers cache too often. This is not even critical if
    # the p2pnet peers cache is not saved after the last updates
    if (!$self->{save_expiration} || time > $self->{save_expiration}) {
        $self->{p2pnetstorage}->save( name => "p2pnet", data => $peers );
        $self->{save_expiration} = time + 60;
    }
}

1;
