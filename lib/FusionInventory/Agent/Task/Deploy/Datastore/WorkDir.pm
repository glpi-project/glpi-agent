package FusionInventory::Agent::Task::Deploy::Datastore::WorkDir;

use strict;
use warnings;

use Data::Dumper;
use File::Path qw(make_path);
use Archive::Extract;
use Compress::Zlib;

sub new {
    my (undef, $params) = @_;

    my $self = {};

    $self->{path} = $params->{path};
    $self->{files} = [];

    bless $self;
}

sub addFile {
    my ($self, $file) = @_;

    push @{$self->{files}}, $file;



}

sub prepare {
    my ($self) = @_;

    foreach my $file (@{$self->{files}}) {
        my $finalFilePath = $self->{path}.'/'.$file->{name};

        #print "Building finale file: `$finalFilePath'\n";

        my $fh;
        if (!open($fh, ">$finalFilePath")) {
            print "Failed to open ".$finalFilePath.": $!\n";
            return;
        }
        binmode($fh);
        foreach my $part (@{$file->{multiparts}}) {
            my ($filename, $sha512) = %$part;

            my $partFilePath = $file->getBaseDir().'/'.$filename;
            if (! -f $partFilePath) {
                print "Missing multipart element: `$partFilePath'\n";
            }

            my $part;
            my $buf;
            if ($filename =~ /\.gz$/ && ($part = gzopen($file->getBaseDir().'/'.$filename, 'rb'))) {
                while ($part->gzread($buf, 1024)) {
                    print $fh $buf;
                }
                $part->gzclose;
            } elsif (open($part, "<$partFilePath")) {
                binmode($part);
                while(read($part, $buf, 1024)) {
                    print $fh $buf;
                }
                close $part;
            } else {
                print "Failed to open: `$partFilePath'\n";
                }
        }
        close($fh);

        if (!$file->validateFileByPath($finalFilePath)) {
            print "Failed to construct the final file.\n";
            return;
        }

    }


    foreach my $file (@{$self->{files}}) {
        my $finalFilePath = $self->{path}.'/'.$file->{name};

        $Archive::Extract::DEBUG=1;
        if ($file->{uncompress}) {
            my $ae = Archive::Extract->new( archive => $finalFilePath );
            $ae->type("tgz");
            if (!$ae->extract( to => $self->{path} )) {
                print "Failed to extract `$finalFilePath'\n";
                return;
            }

            unlink($finalFilePath);
        }
    }

}

1;
