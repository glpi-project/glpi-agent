package GLPI::Agent::XML;

use strict;
use warnings;

use XML::LibXML;

use GLPI::Agent::Tools;

sub new {
    my ($class, %params) = @_;

    my $self = {};
    bless $self, $class;

    $self->string($params{string});
    $self->file($params{file});

    foreach my $opt (qw(force_array text_node_key attr_prefix)) {
        next unless defined($params{$opt});
        $self->{"_$opt"} = $params{$opt};
    }

    return $self;
}

sub _init_libxml {
    my ($self) = @_;

    $self->{_parser} = XML::LibXML->new();

    # Setup XML::LibXML option
    $self->{_parser}->set_options(
        load_ext_dtd => 0,
        no_network   => 1,
        no_blanks    => 1,
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
            die "GLPI::Agent::XML: Unsupported array ref as $key document root\n";
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
            } elsif (ref($hash->{$key}) eq 'ARRAY') {
                foreach my $element (@{$hash->{$key}}) {
                    # Keep first one and create new ones starting from second loop
                    unless ($leaf) {
                        $leaf = $xml->createElement($key);
                        $node->appendChild($leaf);
                    }
                    if (ref($element)) {
                        $self->build_xml($element, $leaf);
                    } else {
                        my $text = $xml->createTextNode($element);
                        $leaf->appendChild($text);
                    }
                    undef $leaf;
                }
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

    if ($hash) {
        $self->build_xml($hash)
            or return;
    }

    return $self->xml()->serialize(1);
}

sub writefile {
    my ($self, $file, $hash) = @_;

    if ($hash) {
        $self->build_xml($hash)
            or return;
    }

    my $fh;
    if (open($fh, '>', $file)) {
        print $fh $self->xml()->serialize(1);
        close($fh);
    }
}

# Recursive API to dump XML::LibXML objects as a hash tree more like XML::TreePP does
sub dump_as_hash {
    my ($self, $node) = @_;

    unless ($node) {
        my $xml = $self->xml()
            or return;

        $node = $xml->documentElement()
            or return;
    }

    my $type = $node->nodeType;

    my $ret;
    if ($type == XML_ELEMENT_NODE) { # 1
        my $textkey     = $self->{_text_node_key} // '#text';
        my $force_array = $self->{_force_array};
        my $name = $node->nodeName;
        foreach my $leaf (map { $self->dump_as_hash($_) } $node->childNodes()) {
            if (ref($leaf) eq 'HASH') {
                foreach my $key (keys(%{$leaf})) {
                    # Transform key in array ref is necessary
                    if (exists($ret->{$name}->{$key})) {
                        $ret->{$name}->{$key} = [ $ret->{$name}->{$key} ]
                            unless ref($ret->{$name}->{$key}) eq 'ARRAY';
                        push @{$ret->{$name}->{$key}}, $leaf->{$key};
                    } else {
                        my $as_array = ref($force_array) eq 'ARRAY' && any { $key eq $_ } @{$force_array};
                        $ret->{$name}->{$key} = $as_array ? [ $leaf->{$key} ] : $leaf->{$key};
                    }
                }
            } elsif (!ref($ret->{$name})) {
                $ret->{$name}->{$textkey} .= $leaf;
            } elsif ($leaf) {
                warn "GLPI::Agent::XML: Unsupported value type for $name: '$leaf'".(ref($leaf) ? " (".ref($leaf).")" : "")."\n";
            }
        }
        if ($node->hasAttributes()) {
            my $attr_prefix = $self->{_attr_prefix} // "-";
            foreach my $attribute ($node->attributes()) {
                my $attr = $attr_prefix.$attribute->nodeName();
                $ret->{$name}->{$attr} = $attribute->getValue();
            }
        }
        if (!defined($ret)) {
            $ret->{$name} = '';
        } elsif (defined($ret->{$name}->{$textkey}) && keys(%{$ret->{$name}}) == 1) {
            my $as_array = ref($force_array) eq 'ARRAY' && any { $name eq $_ } @{$force_array};
            $ret->{$name} = $as_array ? [ $ret->{$name}->{$textkey} ] : $ret->{$name}->{$textkey};
        } elsif (!defined($ret->{$name}->{$textkey})) {
            delete $ret->{$name}->{$textkey};
        }
    } elsif ($type == XML_TEXT_NODE) { # 3
        $ret = $node->textContent;
    } else {
        warn "GLPI::Agent::XML: Unsupported XML::LibXML node type: $type\n";
    }

    return $ret;
}

1;
