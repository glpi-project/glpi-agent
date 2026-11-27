package GLPI::Agent::Task::Deploy::Datastore::WorkDir;

use strict;
use warnings;

use Compress::Zlib;
use English qw(-no_match_vars);
use File::Spec;
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use UNIVERSAL::require;
use Encode qw(encode is_utf8);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Archive;
use GLPI::Agent::Task::Deploy::Signature;

sub new {
    my ($class, %params) = @_;

    my $self = {
        path   => $params{path},
        logger => $params{logger},
        files  => []
    };

    die "$class: Path '".$self->{path}."' doesn't exit\n"
        unless -d $self->{path};

    bless $self, $class;
}

sub path {
    my ($self) = @_;
    return $self->{path};
}

sub addFile {
    my ($self, $file) = @_;

    push @{$self->{files}}, $file;

}

sub prepare {
    my ($self, %params) = @_;

    my $logger = $self->{logger};

    my $signing;
    if ($params{signed}) {
        $signing = GLPI::Agent::Task::Deploy::Signature->new(logger => $logger);
        my $existing = $signing->payloadFiles($self->{path}) or return;
        if (@$existing) {
            $logger->error('Security check error: signed staging directory is not empty');
            return;
        }
        my %seen;
        foreach my $file (@{$self->{files}}) {
            if ($file->{uncompress}) {
                $logger->error('Security check error: automatic extraction is disabled for signed deployments');
                return;
            }
            unless ($signing->validFilename($file->{name}) && !$seen{lc($file->{name})}++) {
                $logger->error('Security check error: unsafe or duplicate payload filename');
                return;
            }
        }
    }

    # Rebuild the complet file from the filepart
    foreach my $file (@{$self->{files}}) {
        $file->{name_local} = $file->{name};

        if ($OSNAME eq 'MSWin32') {
            GLPI::Agent::Tools::Win32->require;
            my $localCodepage = GLPI::Agent::Tools::Win32::getLocalCodepage();
            if (is_utf8($file->{name})) {
                $file->{name_local} = encode($localCodepage, $file->{name});
                # Codepage conversion can introduce path separators.
                if ($signing && !$signing->validFilename($file->{name_local})) {
                    $logger->error('Security check error: unsafe encoded payload filename');
                    return;
                }
            }
        }

        # If the file will be extracted, we simplify its name to avoid problem during
        # the extraction process
        if ($file->{uncompress}) {
            my $shortsha512 = substr($file->{sha512}, 0, 6);
            $file->{name_local} =~ s/.*\.(tar\.gz)/$shortsha512.$1/i;
            if (!$1) {
                $file->{name_local} =~ s/.*\.(tar|gz|7z|bz2)/$shortsha512.$1/i
            }
        }


        my $finalFilePath = File::Spec->catdir($self->{path}, $file->{name_local});

        my $fh;
        my $opened = $params{signed}
            ? sysopen($fh, $finalFilePath, O_WRONLY | O_CREAT | O_EXCL, 0600)
            : open($fh, '>', $finalFilePath);
        unless ($opened) {
            $logger->debug("Failed to open '$finalFilePath': $ERRNO");
            return;
        }
        binmode($fh);
        foreach my $sha512 (@{$file->{multiparts}}) {
            my $partFilePath = $file->getPartFilePath($sha512);
            $logger->debug("Missing multipart element '$partFilePath'")
                unless -f $partFilePath;

            my ($part, $buf);
            if ($part = gzopen($partFilePath, 'rb')) {
                $logger->debug("reading $sha512");
                while ($part->gzread($buf, 1024) > 0) {
                    print $fh $buf;
                }
                $part->gzclose;
            } else {
                $logger->info("Failed to open '$partFilePath'");
            }
        }
        close($fh);

        unless ($file->validateFileByPath($finalFilePath)) {
            $logger->info("Failed to construct the final file.: $finalFilePath");
            return;
        }

    }

    # Now uncompress
    foreach my $file (@{$self->{files}}) {
        my $finalFilePath = File::Spec->catdir($self->{path}, $file->{name_local});

        if ($file->{uncompress}) {
            if (canRun('7z')) {
                my $tarball;
                foreach (getAllLines(
                    command => [ "7z", "x", "-o$self->{path}", $finalFilePath ],
                    logger  => $logger,
                )) {
                    $logger->debug2("7z: $_");
                    if (/Extracting\s+(.*\.tar)$/) {
                        $tarball = $1;
                    }
                }
                if ($tarball && ($finalFilePath =~ /tgz$/i || $finalFilePath =~ /tar\.(gz|xz|bz2)$/i)) {
                    my $tarballpath = File::Spec->catdir($self->{path}, $tarball);
                    foreach (getAllLines(
                        command => [ "7z", "x", "-o$self->{path}", $tarballpath ],
                        logger  => $logger,
                    )) {
                        $logger->debug2("7z: $_");
                    }
                    unlink($tarballpath);
                }
            } else {
                my $archive = GLPI::Agent::Tools::Archive->new( archive => $finalFilePath );
                if (!$archive) {
                    $logger->info("Failed to create Archive object");
                } elsif (!$archive->extract( to => $self->{path} )) {
                    $logger->debug("Failed to extract '$finalFilePath'");
                }
                # We ignore failure here because one my have activated the
                # extract flag on common file and this should be harmless
            }
            unlink($finalFilePath);
        }
    }

    return 1;
}

1;
