package GLPI::Agent::Task::Deploy::CheckProcessor::FileSHA512;

use strict;
use warnings;

use Digest::SHA;

use English qw(-no_match_vars);

use parent "GLPI::Agent::Task::Deploy::CheckProcessor";

sub prepare {
    my ($self) = @_;

    $self->on_success("got expected sha512 file hash for " . $self->{path});
}

sub success {
    my ($self) = @_;

    $self->on_failure($self->{path} . " file is missing");
    return 0 unless -f $self->{path};

    $self->on_failure("no value provided to check file size against");
    my $expected = $self->{value};
    return 0 unless (defined($expected));

    $self->on_failure("sha512 hash computing not supported by agent");
    my $sha = Digest::SHA->new('512');
    return 0 unless (defined($sha));

    my $sha512 = "";
    eval {
        $sha->addfile($self->{path}, 'b');
        $sha512 = $sha->hexdigest;
    };
    $self->on_failure($self->{path} . " file sha512 hash computing failed, $EVAL_ERROR");
    return 0 unless (defined($sha512) && $sha512);

    $self->on_failure($self->{path} . " has wrong sha512 file hash, found $sha512");
    return ( $sha512 eq $expected );
}

1;
