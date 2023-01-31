package GLPI::Agent::Task::Deploy::Datastore::WorkDir;

use strict;
use warnings;

use Compress::Zlib;
use English qw(-no_match_vars);
use File::Spec;
use UNIVERSAL::require;
use Encode qw(encode is_utf8);

use GLPI::Agent::Tools;

sub new {
    my ($class, %params) = @_;

    my $self = {
        path  => $params{path},
        logger => $params{logger},
        files => []
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
    my ($self) = @_;

    my $logger = $self->{logger};

    # Rebuild the complet file from the filepart
    foreach my $file (@{$self->{files}}) {
        $file->{name_local} = $file->{name};

        if ($OSNAME eq 'MSWin32') {
            GLPI::Agent::Tools::Win32->require;
            my $localCodepage = GLPI::Agent::Tools::Win32::getLocalCodepage();
            $file->{name_local} = encode($localCodepage, $file->{name})
                if is_utf8($file->{name});
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
        unless (open($fh, '>', $finalFilePath)) {
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
            if(canRun('7z')) {
                my $tarball;
                foreach (`7z x -o\"$self->{path}\" \"$finalFilePath\"`) {
                    chomp;
                    $logger->debug2("7z: $_");
                    if (/Extracting\s+(.*\.tar)$/) {
                        $tarball = $1;
                    }
                }
                if ($tarball && ($finalFilePath =~ /tgz$/i || $finalFilePath =~ /tar\.(gz|xz|bz2)$/i)) {
                    my $tarballpath = File::Spec->catdir($self->{path}, $tarball);
                    foreach (`7z x -o\"$self->{path}\" \"$tarballpath\"`) {
                        chomp;
                        $logger->debug2("7z: $_");
                    }
                    unlink($tarballpath);
                }
            } else {
                Archive::Extract->require;
                $Archive::Extract::DEBUG=1;
                my $ae = Archive::Extract->new( archive => $finalFilePath );
                if (!$ae) {
                    $logger->info("Failed to create Archive::Extract object");
                } elsif (!$ae->extract( to => $self->{path} )) {
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
