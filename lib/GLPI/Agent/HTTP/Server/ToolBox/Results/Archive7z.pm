package GLPI::Agent::HTTP::Server::ToolBox::Results::Archive7z;

use strict;
use warnings;

use parent "GLPI::Agent::HTTP::Server::ToolBox::Results::Archive";

use GLPI::Agent::Tools;

sub new {
    my ($class, %params) = @_;

    my $command = first { canRun($_) } qw(7z 7za 7zip);
    return unless $command;

    my $self = $class->SUPER::new(%params);

    $self->{_command} = $command;

    bless $self, $class;
}

sub format { '7z' }

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

    my $command = $self->{_command}." a -bb0 -bd -spf ".join(" ", $self->{_filename}, @{$self->{_files}});
    $self->debug("Running command: $command");

    return defined(getAllLines( command => $command ));
}

1;
