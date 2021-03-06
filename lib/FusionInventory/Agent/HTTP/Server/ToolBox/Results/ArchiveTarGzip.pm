package FusionInventory::Agent::HTTP::Server::ToolBox::Results::ArchiveTarGzip;

use strict;
use warnings;

use parent "FusionInventory::Agent::HTTP::Server::ToolBox::Results::Archive";

use FusionInventory::Agent::Tools;

sub new {
    my ($class, %params) = @_;

    return unless canRun("tar") && canRun("gzip");

    my $self = $class->SUPER::new(%params);

    $self->{_order} = 2;

    bless $self, $class;
}

sub format { 'tar.gz' }

sub new_archive {
    my ($self, $file) = @_;

    $self->{_filename} = $file;
    $self->{_files}    = [];
}

sub add_file {
    my ($self, $file) = @_;

    $file =~ s|^\./||;

    push @{$self->{_files}}, $file;
}

sub save_archive {
    my ($self) = @_;

    my $command = "tar czf ".join(" ", $self->{_filename}, @{$self->{_files}});
    $self->debug("Running command: $command");

    return defined(getAllLines( command => $command ));
}

1;
