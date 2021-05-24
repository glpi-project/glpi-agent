package
    Archive;

use strict;
use warnings;

BEGIN {
    $INC{"Archive.pm"} = __FILE__;
}

use IO::Handle;

my @files;

sub new {
    my ($class) = @_;

    my $self = {
        _files  => [],
        _len    => {},
    };

    if (main::DATA->opened) {
        binmode(main::DATA);

        foreach my $file (@files) {
            my ($name, $length) = @{$file};
            push @{$self->{_files}}, $name;
            my $buffer;
            my $read = read(main::DATA, $buffer, $length);
            die "Failed to read archive: $!\n" unless $read == $length;
            $self->{_len}->{$name}   = $length;
            $self->{_datas}->{$name} = $buffer;
        }

        close(main::DATA);
    }

    bless $self, $class;

    return $self;
}

sub files {
    my ($self) = @_;
    return @{$self->{_files}};
}

sub list {
    my ($self) = @_;
    foreach my $file (@files) {
        my ($name, $length) = @{$file};
        print sprintf("%-60s    %8d bytes\n", $name, $length);
    }
    exit(0);
}

sub content {
    my ($self, $file) = @_;
    return $self->{_datas}->{$file} if $self->{_datas};
}

sub extract {
    my ($self, $file, $dest) = @_;

    die "No embedded archive\n" unless $self->{_datas};
    die "No such $file file in archive\n" unless $self->{_datas}->{$file};

    my $name;
    if ($dest) {
        $name = $dest;
    } else {
        ($name) = $file =~ m|/([^/]+)$|
            or die "Can't extract name from $file\n";
    }

    unlink $name if -e $name;

    open my $out, ">:raw", $name
        or die "Can't open $name for writing: $!\n";

    binmode($out);

    print $out $self->{_datas}->{$file};

    close($out);

    return -s $name == $self->{_len}->{$file};
}

1;
