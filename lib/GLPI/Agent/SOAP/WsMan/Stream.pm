package GLPI::Agent::SOAP::WsMan::Stream;

use strict;
use warnings;

use GLPI::Agent::SOAP::WsMan::Node;

## no critic (ProhibitMultiplePackages)
package
    Stream;

use parent
    'Node';

use MIME::Base64;

use constant    xmlns   => 'rsp';

sub new {
    my ($class, $streams) = @_;

    $streams = [ $streams ] unless ref($streams) eq 'ARRAY';

    my $self = {};

    foreach my $stream (@{$streams}) {
        next unless ref($stream) eq 'HASH';
        my $cid = $stream->{'-CommandId'}
            or next;
        my $name = $stream->{'-Name'}
            or next;
        next unless $name =~ /^std(out|err)$/;
        my $text = $stream->{'#text'};
        if (defined($text) && length($text)) {
            $self->{$cid}->{$name} .= decode_base64($text);
        }
        $self->{$cid}->{"_end_$name"} = $stream->{'-End'} =~ /^true$/i if $stream->{'-End'};
    }

    bless $self, $class;
    return $self;
}

sub stdout {
    my ($self, $cid) = @_;

    return unless $self->{$cid};

    return $self->{$cid}->{stdout} // '';
}

sub stderr {
    my ($self, $cid) = @_;

    return unless $self->{$cid};

    return $self->{$cid}->{stderr} // '';
}

sub stdout_is_full {
    my ($self, $cid) = @_;

    return unless $self->{$cid};

    return $self->{$cid}->{_end_stdout} // 0;
}

sub stderr_is_full {
    my ($self, $cid) = @_;

    return unless $self->{$cid};

    return $self->{$cid}->{_end_stderr} // 0;
}

1;
