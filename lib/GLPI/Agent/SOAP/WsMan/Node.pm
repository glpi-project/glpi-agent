package GLPI::Agent::SOAP::WsMan::Node;

use strict;
use warnings;

BEGIN {
    $INC{'Node.pm'} = __FILE__;
}

## no critic (ProhibitMultiplePackages)
package
    Node;

use constant    xmlns   => "";
use constant    xsd     => "";

use constant    dump_as_string => 0;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use GLPI::Agent::Tools;

my ($wsman_classes_path) = $INC{'Node.pm'} =~ m|(.*)/[^/]*\.pm$|;

sub new {
    my ($class, @nodes) = @_;

    my $self = {};

    # List of class names supported by this node
    my $supported = $class->support() // {};

    while (@nodes) {
        my $node = shift @nodes;
        my $ref = ref($node);
        if ($ref eq 'Attribute') {
            push @{$self->{_attributes}}, $node;
        } elsif ($ref eq 'Namespace') {
            push @{$self->{_attributes}}, $node->attributes;
        } elsif (!$ref && defined($node)) {
            if ($node eq '__nodeclass__' && @nodes) {
                $class = _load_class(shift @nodes, get_namespace($self));
            } elsif (ref($self->{_text})) {
                push @{$self->{_text}}, $ref ? @{$node} : $node;
            } elsif (defined($self->{_text})) {
                $self->{_text} = [ $self->{_text}, $ref ? @{$node} : $node ];
            } elsif (defined($node)) {
                $self->{_text} = $node;
            }
        } elsif ($ref eq 'ARRAY') {
            foreach my $object (@{$node}) {
                my $this = Node->new($object);
                push @{$self->{_nodes}}, $this;
            }
        } elsif ($ref eq 'HASH') {
            foreach my $key (keys(%{$node})) {
                if ($key =~ /^-(.+)$/) {
                    push @{$self->{_attributes}}, Attribute->new( $1 => $node->{$key} );
                    $class = _load_class($1) if $1 eq 'xsi:type' && $node->{$key} =~ /^p:(.+)$/;
                } elsif ($key eq '#text') {
                    $self->{_text} = $node->{$key} if defined($node->{$key});
                    $self->{_text} = $1 if $self->{_text} && $self->{_text} =~ /^#textuuid:(.*)$/;
                } else {
                    my $support = first { $supported->{$_} eq $key } keys(%{$supported});
                    ($support) = $key =~ /^(?:\w+:)?(\w+)$/ unless $support;
                    # Try to load class if still not loaded nor known
                    _load_class($support);
                    push @{$self->{_nodes}}, $support->new( $node->{$key} );
                }
            }
        } else {
            push @{$self->{_nodes}}, $node;
        }
    }

    bless $self, $class;
    return $self;
}

sub _load_class {
    my ($class, $namespace) = @_;

    unless ($INC{"$class.pm"}) {
        if (-e "$wsman_classes_path/$class.pm") {
            my $module = "GLPI::Agent::SOAP::WsMan::$class";
            $module->require();
            warn "Failure while loading $class: $EVAL_ERROR\n"
                if $EVAL_ERROR;
            $INC{"$class.pm"} = $INC{module2file($module)};
        } else {
            # If a class is not known just create one with Node as template
            no strict 'refs'; ## no critic (ProhibitNoStrict)
            if ($namespace) {
                *{"${class}::xmlns"} = sub () { "$namespace" };
            }
            push @{"$class\::ISA"}, 'Node';
            $INC{"$class.pm"} = $INC{'Node.pm'};
        }
    }

    return $class;
}

sub namespace {
    my ($self) = @_;

    return "xmlns:".$self->xmlns() => $self->xsd();
}

sub get_namespace {
    my ($self) = @_;

    my $name = first { /^xmlns:./ } map { keys(%{$_}) } @{$self->{_attributes}}
        or return;

    return $name =~ /^xmlns:(\w+)$/;
}

sub set_namespace {
    my ($self) = @_;

    return if grep { /^xmlns:/ } map { keys(%{$_}) } @{$self->{_attributes}};

    $self->push( Attribute->new($self->namespace) );
}

sub reset_namespace {
    my ($self, @attributes) = @_;

    return delete $self->{_attributes} unless @attributes;

    $self->{_attributes} = \@attributes;
}

sub support {}

sub values {}

sub get {
    my ($self, $leaf) = @_;

    if ($leaf) {
        my ($leafnode) = grep { ref($_) eq $leaf } @{$self->{_nodes}};
        return $leafnode;
    }

    my %nodes;
    foreach my $node (@{$self->{_attributes}}, @{$self->{_nodes}}) {
        my $insert = $node->get();
        if (ref($insert) eq 'HASH') {
            foreach my $key (keys(%{$insert})) {
                if ($nodes{$key}) {
                    $nodes{$key} = [ $nodes{$key} ]
                        unless ref($nodes{$key}) eq 'ARRAY';
                    push @{$nodes{$key}}, $insert->{$key};
                } else {
                    $nodes{$key} = $insert->{$key};
                }
            }
        } elsif (ref($insert) eq 'ARRAY') {
            while (@{$insert}) {
                my $key = shift @{$insert};
                my $value = shift @{$insert};
                if ($nodes{$key}) {
                    $nodes{$key} = [ $nodes{$key} ]
                        unless ref($nodes{$key}) eq 'ARRAY';
                    push @{$nodes{$key}}, $value;
                } else {
                    $nodes{$key} = $value;
                }
            }
        } elsif (ref($insert)) {
            $nodes{ref($insert)} = $insert;
        }
    }
    $nodes{'#text'} = $self->{_text} if defined($self->{_text});

    return { $self->xmlns.":".ref($self) => \%nodes };
}

sub delete {
    my ($self, $node) = @_;

    return unless $node && $self->nodes($node);

    my @nodes = grep { ref($_) ne $node } @{$self->{_nodes}};

    $self->{_nodes} = \@nodes;
}

sub nodes {
    my ($self, $filter) = @_;

    return unless defined($self->{_nodes});

    return grep { ref($_) eq $filter } @{$self->{_nodes}}
        if $filter;

    return @{$self->{_nodes}};
}

sub push {
    my ($self, @nodes) = @_;

    return unless @nodes;

    foreach my $node (@nodes) {
        if (ref($node) eq 'Attribute') {
            push @{$self->{_attributes}}, $node;
        } else {
            push @{$self->{_nodes}}, $node;
        }
    }
}

sub attribute {
    my ($self, $key) = @_;

    my ($attribute) = $self->attributes($key);

    return unless $attribute;

    return $attribute->get($key);
}

sub attributes {
    my ($self, $key) = @_;

    return unless defined($self->{_attributes});

    return grep { $_->get($key) } @{$self->{_attributes}} if $key;

    return @{$self->{_attributes}};
}

sub string {
    my ($self, $string) = @_;

    return $self->{_text} = $string
        if $string;

    my @nodes = $self->nodes();
    if (!defined($self->{_text}) && scalar(@nodes) == 1) {
        my ($substring) = $self->nodes();
        return $substring->string();
    }

    return $self->{_text} // '';
}

sub reset {
    my ($self, @nodes) = @_;

    $self->{_nodes} = [];

    $self->push(@nodes);
}

1;
