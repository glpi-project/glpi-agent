package FusionInventory::Agent::HTTP::Server::ToolBox::Results::ArchiveZip;

use strict;
use warnings;

use parent "FusionInventory::Agent::HTTP::Server::ToolBox::Results::Archive";

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

sub format { 'zip' }

sub new_archive {
    my ($self, $file) = @_;

    $self->{_filename} = $file;
    $self->{_zipper}   = Archive::Zip->new();
    $self->{_order}    = 0;
}

sub add_file {
    my ($self, $file) = @_;

    $self->{_zipper}->addFile($file);
}

sub save_archive {
    my ($self) = @_;
    return $self->{_zipper}->writeToFileNamed($self->{_filename}) == AZ_OK;
}

1;
