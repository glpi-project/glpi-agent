package GLPI::Agent::XML;

use strict;
use warnings;

use UNIVERSAL::require;

use English qw(-no_match_vars);
use Encode qw(encode decode);

use GLPI::Agent::Tools;

# We need to use a dedicated worker thread to support XML::LibXML on win32 as
# libxml2 DLL is not fully threads-safe if few contexts
my $need_dedicated_thread = $OSNAME eq "MSWin32" ? 1 : 0;
if ($need_dedicated_thread) {
    GLPI::Agent::Tools::Win32->require() or die $@;
    GLPI::Agent::Tools::Win32::start_Win32_OLE_Worker();
}

sub new {
    my ($class, %params) = @_;

    my $self = {};
    bless $self, $class;

    if ($need_dedicated_thread && !$params{threaded}) {
        $self->{_id} = _GLPI_XML_win32_thread_binding(
            api     => "new",
            args    => [ %params, threaded => 1 ]
        );
        return $self;
    }

    $self->string($params{string});
    $self->file($params{file}) unless $self->has_xml();

    # Support library options set as private object attributes
    map { $self->{"_$_"} = $params{$_} } grep { defined($params{$_}) } qw(
        force_array
        text_node_key
        attr_prefix
        skip_attr
        first_out
        no_xml_decl
        xml_format
        is_plist
        tag_compression
    );

    # Support required by GLPI::Agent::Tools::MacOS
    $self->{_force_array} = [ qw(array dict) ] if $self->{_is_plist};

    return $self;
}

sub _init_libxml {
    my ($self) = @_;

    # Load XML::LibXML as late as possible
    XML::LibXML->require()
        or die "Can't load XML::LibXML required library\n";

    $self->{_parser} = XML::LibXML->new();

    # Setup XML::LibXML option
    $self->{_parser}->set_options(
        load_ext_dtd => 0,
        no_network   => 1,
        no_blanks    => 1,
        # Don't report parsing error
        recover      => 2,
    );
}

sub _xml {
    my ($self, $xml) = @_;

    $self->{_xml} = $xml if defined($xml);

    return $self->{_xml};
}

sub empty {
    my ($self) = @_;

    if ($need_dedicated_thread && $self->{_id}) {
        _GLPI_XML_win32_thread_binding(
            _id  => $self->{_id},
            api  => "empty",
            args => []
        );
        return $self;
    }

    delete $self->{_xml};

    return $self;
}

sub has_xml {
    my ($self) = @_;

    if ($need_dedicated_thread && $self->{_id}) {
        return _GLPI_XML_win32_thread_binding(
            _id  => $self->{_id},
            api  => "has_xml",
            args => []
        );
    }

    my $xml = $self->_xml;

    return ref($xml) eq 'XML::LibXML::Document' && $xml->documentElement();
}

sub string {
    my ($self, $string) = @_;

    return $self unless defined($string) && length($string);

    if ($need_dedicated_thread && $self->{_id}) {
        return _GLPI_XML_win32_thread_binding(
            _id  => $self->{_id},
            api  => "string",
            args => [ $string ]
        );
    }

    $self->_init_libxml() unless $self->{_parser};

    $self->empty->_xml($self->{_parser}->parse_string(decode("UTF-8", $string)));

    return $self;
}

sub file {
    my ($self, $file) = @_;

    return $self unless defined($file) && -e $file;

    if ($need_dedicated_thread && $self->{_id}) {
        return _GLPI_XML_win32_thread_binding(
            _id  => $self->{_id},
            api  => "file",
            args => [ $file ]
        );
    }

    $self->_init_libxml() unless $self->{_parser};

    $self->empty->_xml($self->{_parser}->parse_file($file));

    return $self;
}

sub _encode {
    my ($string) = @_;

    return encode("UTF-8", $string);
}

sub _build_xml {
    my ($self, $hash, $node) = @_;

    my $xml = $self->_xml();

    unless ($xml) {
        return unless ref($hash) eq 'HASH' && keys(%{$hash}) == 1;

        $self->_init_libxml() unless $self->{_parser};

        $xml = $self->_xml(XML::LibXML::Document->new("1.0", "UTF-8"));

        my ($key) = keys(%{$hash});
        my $root = $xml->createElement($key);
        $xml->setDocumentElement($root);
        if (ref($hash->{$key}) eq 'HASH') {
            $hash = $hash->{$key};
        } elsif (ref($hash->{$key})) {
            die "GLPI::Agent::XML: Unsupported array ref as $key document root\n";
        } else {
            $root->appendTextNode(_encode($hash->{$key}));
            return 1;
        }
        $node = $root;
    }

    my @keys;
    # Handle first_out option
    if ($self->{_first_out} && any { exists($hash->{$_}) } @{$self->{_first_out}}) {
        my @first_out = sort grep { exists($hash->{$_}) } @{$self->{_first_out}};
        push @keys, @first_out;
        push @keys, sort grep { my $k = $_ ; ! grep { $_ eq $k } @first_out } keys(%{$hash});
    } else {
        @keys = sort keys(%{$hash});
    }

    my $textkey = $self->{_text_node_key} // '#text';

    foreach my $key (@keys) {
        next unless defined($hash->{$key});
        if ($key =~ /^-(.*)$/) {
            $node->setAttribute($1, $hash->{$key});
        } elsif ($key eq $textkey) {
            my $text = $xml->createTextNode(_encode($hash->{$key}));
            $node->appendChild($text);
        } else {
            my $leaf = $xml->createElement($key);
            $node->appendChild($leaf);
            if (ref($hash->{$key}) eq 'HASH') {
                $self->_build_xml($hash->{$key}, $leaf);
            } elsif (ref($hash->{$key}) eq 'ARRAY') {
                foreach my $element (@{$hash->{$key}}) {
                    # Keep first one and create new ones starting from second loop
                    unless ($leaf) {
                        $leaf = $xml->createElement($key);
                        $node->appendChild($leaf);
                    }
                    if (ref($element)) {
                        $self->_build_xml($element, $leaf);
                    } else {
                        my $text = $xml->createTextNode(_encode($element));
                        $leaf->appendChild($text);
                    }
                    undef $leaf;
                }
            } else {
                my $text = $xml->createTextNode(_encode($hash->{$key}));
                $leaf->appendChild($text);
            }
        }
    }

    return 1;
}

sub write {
    my ($self, $hash) = @_;

    if ($need_dedicated_thread && $self->{_id}) {
        return _GLPI_XML_win32_thread_binding(
            _id  => $self->{_id},
            api  => "write",
            args => [ $hash ]
        );
    }

    if ($hash) {
        $self->empty->_build_xml($hash)
            or return;
    }

    return '' unless $self->has_xml();

    # Support XML::LibXML setTagCompression option
    $XML::LibXML::setTagCompression = $self->{_tag_compression} ? 1 : 0 ;

    if ($self->{_no_xml_decl}) {
        my $string;
        foreach my $node ($self->_xml()->childNodes()) {
            $string .= $node->toString($self->{_xml_format} // 1);
        }
        return $string;
    }

    return $self->_xml()->toString($self->{_xml_format} // 1);
}

sub writefile {
    my ($self, $file, $hash) = @_;

    my $string = $self->write($hash);
    return unless defined($string) && $self->has_xml();

    my $fh;
    if (open($fh, '>', $file)) {
        print $fh $string;
        close($fh);
    }
}

# Recursive API to dump XML::LibXML objects as a hash tree more like XML::TreePP does
sub dump_as_hash {
    my ($self, $node) = @_;

    if ($need_dedicated_thread && $self->{_id}) {
        return _GLPI_XML_win32_thread_binding(
            _id  => $self->{_id},
            api  => "dump_as_hash",
            args => [ $node ]
        );
    }

    unless ($node) {
        my $xml = $self->_xml()
            or return;

        $node = $xml->documentElement()
            or return;
    }

    my $type = $node->nodeType;

    my $ret;
    if ($type == XML::LibXML::XML_ELEMENT_NODE()) { # 1
        my $textkey     = $self->{_text_node_key} // '#text';
        my $force_array = $self->{_force_array};
        my $skip_attr   = $self->{_skip_attr};
        my $plist       = $self->{_is_plist};
        my $name = $node->nodeName;
        foreach my $leaf (map { $self->dump_as_hash($_) } $node->childNodes()) {
            if (ref($leaf) eq 'HASH') {
                foreach my $key (keys(%{$leaf})) {
                    next if $plist && $key =~ /^key|string|date|integer|real|data|true|false$/;
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
            } elsif ($plist) {
                if ($name eq "key") {
                    $self->{_current_name} = $leaf;
                } elsif ($self->{_current_name}) {
                    $ret->{$self->{_current_name}} = $leaf;
                    delete $self->{_current_name};
                }
            } elsif (!ref($ret->{$name})) {
                $ret->{$name}->{$textkey} .= $leaf;
            } elsif ($leaf) {
                warn "GLPI::Agent::XML: Unsupported value type for $name: '$leaf'".(ref($leaf) ? " (".ref($leaf).")" : "")."\n";
            }
        }
        unless ($skip_attr) {
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
    } elsif ($type == XML::LibXML::XML_TEXT_NODE() || $type == XML::LibXML::XML_CDATA_SECTION_NODE()) { # 3 & 4
        $ret = $node->textContent;
        chomp($ret);
        # Cleanup empty nodes like "<node>\n    </node>"
        $ret = '' if $ret =~ /^\n\s+$/m;
    } else {
        warn "GLPI::Agent::XML: Unsupported XML::LibXML node type: $type\n";
    }

    return $ret;
}

# On win32, we want to cache XML objects in a dedicated thread
my %XMLs;
my $xmlid = 0;
sub _GLPI_XML_win32_binded_thread {
    my (%infos) = @_;

    my $api = $infos{api};
    my $id  = $infos{_id};

    if (defined($id)) {
        if ($infos{destroy}) {
           delete $XMLs{$id};
            return;
        } else {
            # API call on cached object
            return $XMLs{$id}->$api(@{$infos{args}});
        }
    }

    # Keep a cache id as simple integer
    $xmlid = ++$xmlid % 4294967296 ;
    while (exists($XMLs{$xmlid})) { $xmlid++ };

    $XMLs{$xmlid} = GLPI::Agent::XML->new(@{$infos{args}});
    return $xmlid;
}

sub _GLPI_XML_win32_thread_binding {
    my (%params) = @_;

    return GLPI::Agent::Tools::Win32::call_not_thread_safe_api_on_win32({
        module => 'GLPI::Agent::XML',
        funct  => '_GLPI_XML_win32_binded_thread',
        args   => \@_
    });
}

sub DESTROY {
    local($., $@, $!, $^E, $?);
    my ($self) = @_;
    $self->{_id} and _GLPI_XML_win32_thread_binding(
        _id     => $self->{_id},
        destroy => 1
    );
}

1;
