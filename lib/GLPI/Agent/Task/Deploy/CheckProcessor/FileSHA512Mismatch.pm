package GLPI::Agent::Task::Deploy::CheckProcessor::FileSHA512Mismatch;

use strict;
use warnings;

use Digest::SHA;

use English qw(-no_match_vars);

use parent "GLPI::Agent::Task::Deploy::CheckProcessor";

# This processor could be used to skip file deployment as expected file is found
# So we should only trigger a failure is we can compute sha512 and it is wrong

sub prepare {
}

sub success {
    my ($self) = @_;

    my $path = $self->{path};

    $self->on_success("$path file is missing");
    return 1 unless -f $path;

    $self->on_success("no value provided to check file size against");
    my $expected = $self->{value};
    return 1 unless (defined($expected));

    $self->on_success("sha512 hash computing not supported by agent");
    my $sha = Digest::SHA->new('512');
    return 1 unless (defined($sha));

    my $sha512 = "";
    eval {
        $sha->addfile($path, 'b');
        $sha512 = $sha->hexdigest;
    };
    $self->on_success("$path file sha512 hash computing failed, $EVAL_ERROR");
    return 1 unless (defined($sha512) && $sha512);

    $self->on_failure("got sha512 file hash match for $path");
    $self->on_success("got sha512 file hash mismatch for $path, found $sha512");
    return ( $sha512 ne $expected );
}

1;
