package GLPI::Agent::XML::Response;

use strict;
use warnings;

use GLPI::Agent::XML;

sub new {
    my ($class, %params) = @_;

    my $xml = GLPI::Agent::XML->new(
        force_array   => [ qw/
            OPTION PARAM MODEL AUTHENTICATION RANGEIP DEVICE GET WALK
        / ],
        attr_prefix   => '',
        text_node_key => 'content',
        string        => $params{content}
    );
    die "content is not an XML message" unless $xml->has_xml;

    my $content = $xml->dump_as_hash();
    die "content is not an expected XML message" unless exists($content->{REPLY});

    my $self = {
        content => $content->{REPLY}
    };

    bless $self, $class;

    return $self;
}

sub getContent {
    my ($self) = @_;

    return $self->{content};
}

sub getOptionsInfoByName {
    my ($self, $name) = @_;

    return unless $self->{content}->{OPTION};

    return
        grep { $_->{NAME} eq $name }
        @{$self->{content}->{OPTION}};
}

1;

__END__

=head1 NAME

GLPI::Agent::XML::Response - Generic server message

=head1 DESCRIPTION

This is a generic message sent by the server to the agent.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use (default: a new stderr logger)

=item I<content>

the raw XML content

=back

=head2 getContent

Get content, as a perl data structure.

=head2 getOptionsInfoByName($name)

Get parameters of a specific option
