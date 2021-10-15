package GLPI::Agent::Logger::File;

use strict;
use warnings;

use parent 'GLPI::Agent::Logger::Backend';

use English qw(-no_match_vars);
use Fcntl qw(:flock);

sub new {
    my ($class, %params) = @_;

    my $self = {
        logfile         => $params{'logfile'},
        logfile_maxsize => $params{'logfile-maxsize'} ?
            $params{'logfile-maxsize'} * 1024 * 1024 : 0
    };
    bless $self, $class;

    return $self;
}

sub addMessage {
    my ($self, %params) = @_;

    my $level = $params{level};
    my $message = $params{message};

    my $handle;
    if ($self->{logfile_maxsize}) {
        if ( -e $self->{logfile} && -s $self->{logfile} > $self->{logfile_maxsize}) {
            if (!open $handle, '>', $self->{logfile}) {
                warn "Can't open $self->{logfile}: $ERRNO";
                return;
            }
        }
    }

    if (!$handle && !open $handle, '>>', $self->{logfile}) {
        warn "can't open $self->{logfile}: $ERRNO";
        return;
    }

    my $locked;
    my $retryTill = time + 60;

    while ($retryTill > time && !$locked) {
        ## no critic (ProhibitBitwise)
        # get an exclusive lock on log file
        $locked = 1 if flock($handle, LOCK_EX|LOCK_NB);
    }

    if (!$locked) {
        die "can't get an exclusive lock on $self->{logfile}: $ERRNO";
    }

    print {$handle}
        "[". localtime() ."]" .
        "[$level]" .
        " $message\n";

    # closing handle release the lock automatically
    close $handle;

}

1;
__END__

=head1 NAME

GLPI::Agent::Logger::File - A file backend for the logger

=head1 DESCRIPTION

This is a file-based backend for the logger. It supports automatic filesize
limitation.
