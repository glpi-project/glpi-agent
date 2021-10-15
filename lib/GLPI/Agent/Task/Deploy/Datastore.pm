package FusionInventory::Agent::Task::Deploy::Datastore;

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Glob;
use File::Spec;
use File::Path qw(mkpath rmtree);
use UNIVERSAL::require;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Logger;
use FusionInventory::Agent::Storage;
use FusionInventory::Agent::Task::Deploy::Datastore::WorkDir;
use FusionInventory::Agent::Task::Deploy::DiskFree;

sub new {
    my ($class, %params) = @_;

    die "no path parameter" unless $params{path};

    my $self = {
        config => $params{config},
        path   => File::Spec->rel2abs($params{path}),
        logger => $params{logger} ||
                  FusionInventory::Agent::Logger->new(),
    };

    if (!$self->{path}) {
      die("No datastore path");
    }

    bless $self, $class;

    return $self;
}

sub cleanUp {
    my ($self, %params) = @_;

    return unless -d $self->{path};

    my @storageDirs;
    push @storageDirs, File::Glob::bsd_glob($self->{path}.'/fileparts/private/*');
    push @storageDirs, File::Glob::bsd_glob($self->{path}.'/fileparts/shared/*');

    if (-d $self->{path}.'/workdir/') {
        remove_tree( $self->{path}.'/workdir/', {error => \my $err} );
    }

    my $remaining = 0;
    foreach my $dir (@storageDirs) {

        if (!-d $dir) {
            unlink $dir;
            next;
        }

        next unless $dir =~ /(\d+)$/;

        # Check retention time using a one minute time frame
        my $timeframe = time - time % 60 ;
        if ($timeframe >= $1 || $params{force}) {
            remove_tree( $dir, {error => \my $err} );
        } else {
            $remaining ++;
        }
    }

    return $remaining;
}

sub createWorkDir {
    my ($self, $uuid) = @_;

    my $path = $self->{path}.'/workdir/'.$uuid;

    mkpath($path);
    return unless -d $path;

    return FusionInventory::Agent::Task::Deploy::Datastore::WorkDir->new(
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

    if (!defined($freeSpace)) {
        $logger->debug2('$freeSpace is undef!');
        $freeSpace = 0;
    }

    $logger->debug("Free space on $self->{path}: $freeSpace");
    # 400MB Free, should be set by a config option
    return ($freeSpace < 2000);
}

sub getP2PNet {
    my ($self) = @_;

    if (!$self->{p2pnetstorage}) {
        $self->{p2pnetstorage} = FusionInventory::Agent::Storage->new(
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

# imported from File-Path-2.09
sub remove_tree {
    push @_, {} unless @_ and UNIVERSAL::isa($_[-1],'HASH');
    goto &rmtree;
}

1;
