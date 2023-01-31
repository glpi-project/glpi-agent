package GLPI::Agent::Task::Deploy::File;

use strict;
use warnings;

use Digest::SHA;
use English qw(-no_match_vars);
use File::Basename;
use File::Spec;
use File::Path qw(make_path);
use File::Glob;
use HTTP::Request;

sub new {
    my ($class, %params) = @_;

    die "$class: No datastore parameter\n" unless $params{datastore};
    die "$class: No sha512 parameter\n" unless $params{sha512};

    my $self = {
        p2p                => $params{data}->{p2p},
        retention_duration => $params{data}->{'p2p-retention-duration'},
        prolog_delay       => $params{prolog} || 3600,
        uncompress         => $params{data}->{uncompress},
        mirrors            => $params{data}->{mirrors},
        multiparts         => $params{data}->{multiparts},
        name               => $params{data}->{name},
        sha512             => $params{sha512},
        datastore          => $params{datastore},
        client             => $params{client},
        logger             => $params{logger}
    };

    # p2p-retention-duration has a different meaning if not a p2p file
    if (!$self->{retention_duration}) {
        if ($self->{p2p}) {
            # For p2p file, keep downloaded parts 3 days by default
            $self->{retention_duration} = 60 * 24 * 3;
        } else {
            # For not p2p file, we will keep downloaded parts as long as
            # we need them: 3 times the PROLOG delay to support download
            # restart in case of network failure
            $self->{retention_duration} = 0;
        }
    }

    bless $self, $class;

    return $self;
}

sub normalizedPartFilePath {
    my ($self, $sha512) = @_;

    return unless $sha512 =~ /^(.)(.)(.{6})/;
    my $subFilePath = File::Spec->catdir($1, $2, $3);

    my $filePath = File::Spec->catdir($self->{datastore}->{path}, 'fileparts');
    my $retention_duration;
    if ($self->{p2p}) {
        $filePath = File::Spec->catdir($filePath, 'shared');
        $retention_duration = $self->{retention_duration} * 60;
    } else {
        $filePath = File::Spec->catdir($filePath, 'private');
        $retention_duration = $self->{retention_duration} ?
            $self->{retention_duration} * 60 : $self->{prolog_delay} * 3;
    }

    # Compute a directory name that will be used to know if the file must
    # be purge. We don't want a new directory everytime, so we use a one
    # minute time frame to follow the retention duration unit
    my $expiration    = time + $retention_duration + 60;
    my $retentiontime = $expiration - $expiration % 60 ;
    $filePath = File::Spec->catdir($filePath, $retentiontime, $subFilePath);

    return $filePath;
}

sub _cleanPath {
    my ($path) = @_;
    my @treepath = File::Spec->splitpath($path);
    $treepath[2] = '';
    my $cleanmaxdir = 5;
    while ($cleanmaxdir--) {
        my @folder = File::Spec->splitdir($treepath[1]);
        pop @folder;
        $treepath[1] = File::Spec->catdir(@folder);
        # Will remove tree unless folder is not empty
        last unless rmdir File::Spec->catpath(@treepath);
    }
}

sub cleanup_private {
    my ($self) = @_;

    # Don't cleanup for p2p shared parts
    return if $self->{p2p};

    # Only cleanup if no retention duration has been set
    return if $self->{retention_duration};

    # Cleanup all parts
    foreach my $sha512 (@{$self->{multiparts}}) {
        my $path = $self->getPartFilePath($sha512);
        unlink $path if -f $path;
        _cleanPath($path);
    }
}

sub resetPartFilePaths {
    my ($self) = @_;

    # move all Part files to respect retention duration from now
    my %updates = ();

    foreach my $sha512 (@{$self->{multiparts}}) {
        my $path = $self->getPartFilePath($sha512);
        if (-f $path) {
            my $update = $self->normalizedPartFilePath($sha512);
            next if $path eq $update;
            $updates{$path} = $update ;
        }
    }

    foreach my $path (keys(%updates)) {
        make_path(dirname($updates{$path}));
        rename $path, $updates{$path};
        _cleanPath($path);
    }
}

sub getPartFilePath {
    my ($self, $sha512) = @_;

    return unless $sha512 =~ /^(.)(.)(.{6})/;
    my $subFilePath = File::Spec->catdir($1, $2, $3);

    my @storageDirs = (
        File::Glob::bsd_glob(File::Spec->catdir($self->{datastore}->{path}, 'fileparts', 'shared', '*')),
        File::Glob::bsd_glob(File::Spec->catdir($self->{datastore}->{path}, 'fileparts', 'private', '*'))
    );

    foreach my $dir (@storageDirs) {
        my $filePath = File::Spec->catdir($dir, $subFilePath);
        return $filePath if -f $filePath;
    }

    return $self->normalizedPartFilePath($sha512);
}

sub download {
    my ($self) = @_;

    unless ($self->{mirrors}) {
        $self->{logger}->error("No mirror set on deploy job");
        die;
    }

    my @peers;
    if ($self->{p2p}) {
        GLPI::Agent::Task::Deploy::P2P->require();
        if ($EVAL_ERROR) {
            $self->{logger}->debug("can't enable P2P: $EVAL_ERROR")
        } else {
            my $p2p = GLPI::Agent::Task::Deploy::P2P->new(
                scan_timeout    => 1,
                datastore       => $self->{datastore},
                logger          => $self->{logger}
            );
            eval {
                @peers = $p2p->findPeers(62354);
                $self->{p2pnet} = $p2p;
            };
            $self->{logger}->debug("failed to enable P2P: $EVAL_ERROR")
                if $EVAL_ERROR;
        }
    };

    my $lastPeer;
    my $nextPathUpdate = _getNextPathUpdateTime();
    PART: foreach my $sha512 (@{$self->{multiparts}}) {
        my $path = $self->getPartFilePath($sha512);
        if (-f $path) {
            next PART if $self->_getSha512ByFile($path) eq $sha512;
        }
        make_path(dirname($path));

        # try to download from the same peer as last part, if defined
        if ($lastPeer) {
            my $success = $self->_downloadPeer($lastPeer, $sha512, $path);
            next PART if $success;
        }

        # try to download from peers
        foreach my $peer (@peers) {
            my $success = $self->_downloadPeer($peer, $sha512, $path);
            if ($success) {
                $lastPeer = $peer;
                next PART;
            }
            # Update filepath so retention is kept in the future on long search
            if ( time - $nextPathUpdate > 0 ) {
                $path = $self->normalizedPartFilePath($sha512);
                $nextPathUpdate = _getNextPathUpdateTime();
            }
        }

        # try to download from mirrors
        foreach my $mirror (@{$self->{mirrors}}) {
            my $success = $self->_download($mirror, $sha512, $path);
            next PART if $success;
            # Update filepath so retention is kept in the future on long search
            if ( time - $nextPathUpdate > 0 ) {
                $path = $self->normalizedPartFilePath($sha512);
                $nextPathUpdate = _getNextPathUpdateTime();
            }
        }

        # Here, we missed to download the part
        if (!$lastPeer && !@peers && !@{$self->{mirrors}}) {
            $self->{logger}->debug("can't download part as no mirror is defined");
            $self->{logger}->debug("You probably missed to enable the GLPI option to use GLPI server as a mirror");
            # Don't try to download any other part
            $self->{logger}->error("Aborting download: no mirror");
            last;
        }
    }
}

sub _getNextPathUpdateTime {
    my $time = time;
    return $time + 60 - $time % 60;
}

sub _downloadPeer {
    my ($self, $peer, $sha512, $path) = @_;

    my $source = 'http://'.$peer.':62354/deploy/getFile/';

    return $self->_download($source, $sha512, $path, $peer);
}

sub _download {
    my ($self, $source, $sha512, $path, $peer) = @_;

    unless ($source =~ m|^https?://|i) {
        $self->{logger}->error("Source or mirror is not a valid URL: $source");
        return;
    }

    return unless $sha512 =~ /^(.)(.)/;
    my $sha512dir = $1.'/'.$1.$2.'/';

    # Check source url ends with a slash
    $source .= '/' unless $source =~ m|/$|;

    my $url = $source.$sha512dir.$sha512;

    $self->{logger}->debug("File part URL: $url");

    my $request = HTTP::Request->new(GET => $url);
    # We want to try direct download without proxy if peer if defined and then
    # we also prefer to use really short timeout to disqualify busy peers and
    # also avoid to block for not responding peers while using P2P
    my $timeout = $peer ? 1 : 180 ;
    my $response = $self->{client}->request($request, $path, $peer, $timeout);

    if ($response->code != 200) {
        if ($peer && ($response->code != 404 || $response->status_line() =~ /Nothing found/)) {
            $self->{logger}->debug2("Remote peer $peer is useless, we should forget it out for a while");
            $self->{p2pnet}->forgetPeer($peer) if $self->{p2pnet};
        }
        return;
    }
    return if ! -f $path;

    if ($self->_getSha512ByFile($path) ne $sha512) {
        $self->{logger}->debug("sha512 failure: $sha512");
        unlink($path);
        return;
    }

    return 1;
}

sub filePartsExists {
    my ($self) = @_;

    foreach my $sha512 (@{$self->{multiparts}}) {

        my $filePath  = $self->getPartFilePath($sha512);
        return 0 unless -f $filePath;

    }
    return 1;
}

sub _getSha512ByFile {
    my ($self, $filePath) = @_;

    my $sha = Digest::SHA->new('512');

    my $sha512;
    eval {
        $sha->addfile($filePath, 'b');
        $sha512 = $sha->hexdigest;
    };
    $self->{logger}->debug("SHA512 failure: $@") if $@;

    return $sha512;
}

sub validateFileByPath {
    my ($self, $filePath) = @_;


    if (-f $filePath) {
        if ($self->_getSha512ByFile($filePath) eq $self->{sha512}) {
            return 1;
        }
    }

    return 0;
}


1;
