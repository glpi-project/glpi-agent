package GLPI::Agent::XML;

use strict;
use warnings;

use XML::LibXML;

use GLPI::Agent::Logger;

sub new {
    my ($class, %params) = @_;

    my $self = {};
    bless $self, $class;

    $self->string($params{string});
    $self->file($params{file});

    return $self;
}

sub _init_libxml {
    my ($self) = @_;

    $self->{_parser} = XML::LibXML->new();

    # Setup XML::LibXML option
    $self->{_parser}->set_options(
        load_ext_dtd => 0,
        no_network   => 1,
    );
}

sub xml {
    my ($self, $xml) = @_;

    $self->{_xml} = $xml if defined($xml);

    return $self->{_xml};
}

sub string {
    my ($self, $string) = @_;

    return unless defined($string);

    $self->_init_libxml() unless $self->{_parser};

    $self->xml($self->{_parser}->parse_string($string));
}

sub file {
    my ($self, $file) = @_;

    return unless defined($file) && -e $file;

    $self->_init_libxml() unless $self->{_parser};

    $self->xml($self->{_parser}->parse_file($file));
}

sub build_xml {
    my ($self, $hash, $node) = @_;

    my $xml = $self->xml();

    unless ($xml) {
        return unless ref($hash) eq 'HASH' && keys(%{$hash}) == 1;

        $self->_init_libxml() unless $self->{_parser};

        $xml = $self->xml(XML::LibXML::Document->new("1.0", "UTF-8"));

        my ($key) = keys(%{$hash});
        my $root = $xml->createElement($key);
        $xml->setDocumentElement($root);
        if (ref($hash->{$key}) eq 'HASH') {
            $hash = $hash->{$key};
        } elsif (ref($hash->{$key})) {
            die "Unsupported array ref as $key document root\n";
        } else {
            $root->appendTextNode($hash->{$key});
            return 1;
        }
        $node = $root;
    }

    foreach my $key (sort keys(%{$hash})) {
        if ($key =~ /^-(.*)$/) {
            $node->setAttribute($1, $hash->{$key});
        } else {
            my $leaf = $xml->createElement($key);
            $node->appendChild($leaf);
            if (ref($hash->{$key}) eq 'HASH') {
                $self->build_xml($hash->{$key}, $leaf);
            } else {
                my $text = $xml->createTextNode($hash->{$key});
                $leaf->appendChild($text);
            }
        }
    }

    return 1;
}

sub write {
    my ($self, $hash) = @_;

    $self->build_xml($hash)
        or return;

    return $self->xml()->serialize(1);
}

# Recursive API to dump XML::LibXML objects as a hash tree more like XML::TreePP does
sub _dump {
    my ($node) = @_;

    my $type = $node->nodeType;

    my $ret;
    if ($type == XML_ELEMENT_NODE) { # 1
        my $name = $node->nodeName;
        my $count = 1;
        foreach my $leaf (map { _dump($_) } $node->childNodes()) {
            warn "$name(".$count++."): $leaf\n" if $name eq "STORAGE" && $leaf;
            if (ref($leaf) eq 'HASH') {
                foreach my $key (keys(%{$leaf})) {
                    # Transform key in array ref is necessary
                    if (exists($ret->{$name}->{$key})) {
                        $ret->{$name}->{$key} = [ $ret->{$name}->{$key} ]
                            unless ref($ret->{$name}->{$key}) eq 'ARRAY';
                        push @{$ret->{$name}->{$key}}, $leaf->{$key};
                    } else {
                        $ret->{$name}->{$key} = $leaf->{$key};
                    }
                }
            } elsif (!ref($ret->{$name})) {
                $ret->{$name}->{'#text'} .= $leaf;
            } elsif ($leaf) {
                warn "Unsupported value type for $name: '$leaf'".(ref($leaf) ? " (".ref($leaf).")" : "")."\n";
            }
        }
        if ($node->hasAttributes()) {
            foreach my $attribute ($node->attributes()) {
                my $attr = $attribute->nodeName();
                $ret->{$name}->{"-$attr"} = $attribute->getValue();
            }
        }
        if (!defined($ret)) {
            undef $ret->{$name};
        } elsif (defined($ret->{$name}->{'#text'}) && keys(%{$ret->{$name}}) == 1) {
            $ret->{$name} = $ret->{$name}->{'#text'};
        } elsif (!$ret->{$name}->{'#text'}) {
            delete $ret->{$name}->{'#text'};
        }
    } elsif ($type == XML_TEXT_NODE) { # 3
        $ret = $node->textContent;
        # Clean up text being only XML indentation
        $ret =~ s/^\n\s*$//m;
    } else {
        die "Unsupported XML::LibXML node type: $type\n";
    }

    return $ret;
}

# Return a hash tree of the XML::LibXML content
sub dump_as_hash {
    my ($self) = @_;

    my $xml = $self->xml()
        or return;

    return _dump($xml->documentElement());
}

1;
