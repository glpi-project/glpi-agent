package
    Changelog;

use strict;
use warnings;

use lib 'lib';

use FusionInventory::Agent::Tools;

sub new {
    my ($class, %params) = @_;

    die "no valid file parameter\n" unless ($params{file} && -e $params{file});

    my $self = {
        _first_lines    => [],
        _last_lines     => [],
        _file           => $params{file},
    };

    # Parse lines
    my $section;
    my $delimiter = 0;
    foreach my $line (getAllLines(file => $params{file})) {
        if (@{$self->{_last_lines}}) {
            push @{$self->{_last_lines}}, $line;
        } elsif (!defined($section)) {
            $section = "" if $line =~ /not released yet/;
            push @{$self->{_first_lines}}, $line;
        } elsif ($line =~ /^$/) {
            $section = "";
        } elsif ($line =~ /^(\S+):$/) {
            $section = $1;
            push @{$self->{_sections}}, $section;
        } elsif ($section) {
            push @{$self->{$section}}, $line;
        } else {
            # Stack remaining lines
            push @{$self->{_last_lines}}, $line;
        }
    }

    return bless $self, $class;
}

sub add {
    my ($self, %params) = @_;
    foreach my $section (keys(%params)) {
        push @{$self->{_sections}}, $section
            unless grep { /^$section$/ } @{$self->{_sections}};
        push @{$self->{$section}}, "* $params{$section}";
    }
}

sub write {
    my ($self, %params) = @_;
    my $file = $params{file} // $self->{_file};
    my $fh;
    open $fh, ">$file"
        or die "Can't create $file as changelog: $!\n";
    map { print $fh "$_\n" } @{$self->{_first_lines}};
    foreach my $section (@{$self->{_sections}}) {
        next unless $self->{$section};
        print $fh "\n$section:\n";
        map { print $fh "$_\n" } @{$self->{$section}};
    }
    print $fh "\n";
    map { print $fh "$_\n" } @{$self->{_last_lines}};
    close($fh);
}

sub task_version_update {
    my ($self, $task) = @_;
    my @bumps = grep { /Bump $task task version to/ } @{$self->{_last_lines}};
    my ($previous) = @bumps ? $bumps[0] =~ /Bump $task task version to (.*)$/ : "";
    my $latest;

    eval 'require FusionInventory::Agent::Task::'.$task.'::Version';
    eval '$latest = FusionInventory::Agent::Task::'.$task.'::Version::VERSION()';

    return 0 unless $latest;
    return 0 if $previous && $latest eq $previous;

    my $section = $task =~ /^Net(Discovery|Inventory)$/ ? "netdiscovery/netinventory" : lc($task);

    $self->add($section => "Bump $task task version to $latest");

    return 1;
}

1;
