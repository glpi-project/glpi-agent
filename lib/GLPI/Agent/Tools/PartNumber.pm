package GLPI::Agent::Tools::PartNumber;

use strict;
use warnings;

use File::Glob;
use English qw(-no_match_vars);

use GLPI::Agent::Tools;
use GLPI::Agent::Logger;

use constant category       => "";
use constant manufacturer   => "";
use constant mm_id          => "";

# Lower priorities will be checked first
use constant priority   => 50;

my @subclasses;

sub new {
    my ($class, %params) = @_;

    my $logger = $params{logger} || GLPI::Agent::Logger->new();

    unless (@subclasses) {
        my %priority = ();
        my ($_classpath) = $INC{module2file(__PACKAGE__)} =~ /^(.*)\.pm$/;
        $_classpath =~ s{\\}{/}g if $OSNAME eq 'MSWin32';
        my $subclass_path_re = qr/$_classpath\/(\S+)\.pm$/;
        foreach my $file (File::Glob::bsd_glob("$_classpath/*.pm")) {
            $file =~ s{\\}{/}g if $OSNAME eq 'MSWin32';
            my ($class) = $file =~ $subclass_path_re
                or next;
            my $module = "GLPI::Agent::Tools::PartNumber::" . $class;
            $module->require();
            if ($EVAL_ERROR) {
                $logger->debug("Failed to load PartNumber::$class");
                $logger->debug2("$module require error: $EVAL_ERROR");
                next;
            }
            $priority{$module} = $module->priority();
        }
        @subclasses = sort { $priority{$a} <=> $priority{$b} } sort keys(%priority);
    }

    my $self = {
        logger => $logger,
    };

    return bless $self, $class;
}

sub match {
    my ($self, %params) = @_;

    return unless defined($params{partnumber});

    foreach my $subclass (@subclasses) {
        # Filter out by category and eventually by manufacturer
        next if $params{category}     && $subclass->category     ne $params{category};
        # Better check Module Manufacturer ID to select related manufacturer
        if ($params{mm_id} && $subclass->mm_id) {
            next unless $subclass->mm_id eq $params{mm_id};
        } elsif ($params{manufacturer}) {
            next unless $subclass->manufacturer eq $params{manufacturer};
        }
        my @matches;
        if (defined($subclass->match_re)) {
            @matches = $params{partnumber} =~ $subclass->match_re;
            next unless @matches;
        } else {
            # Only support no partnumber regexp if mm_id matched
            next unless $params{mm_id};
        }
        bless $self, $subclass;
        $self->init(@matches);
        last;
    }

    # Only validate Partnumber object if it has a manufacturer
    return unless $self->manufacturer;

    return $self;
}

sub init {}

sub speed {
    my ($self) = @_;
    return $self->{_speed};
}

sub type {
    my ($self) = @_;
    return $self->{_type};
}

sub revision {
    my ($self) = @_;
    return $self->{_revision};
}

sub get {
    my ($self) = @_;
    return $self->{_partnumber};
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::PartNumber - PartNumber class

=head1 DESCRIPTION

This module provides a base class to handle PartNumber specific cases

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use (default: a new stderr logger)

=back

=head2 match(%params)

This is the method checking for supported PartNumber sub-class handling the set
PartNumber. The following parameters are allowed, as keys of the %params hash:

=over

=item I<partnumber>

the partnumber string (mandatory)

=item I<category>

the category to filter out subclasses

=item I<manufacturer>

the manufacturer to select subclass by manufacturer

=back

=head2 init()

This is a method to be implemented by each subclass and to initialize the object.
It can take partnumber matches as arguments when a subclass regexp match.

=head2 match_re()

This is a method to be implemented by each subclass. It could simply return a
 regexp which could applied on partnumber string permitting to select the
subclass in case of matches.

=head2 manufacturer()

This is a method to be implemented by each subclass.
It should simply return a constant string.

=head2 category()

This is a method to be implemented by each subclass.
It should simply return a constant string.

=head2 speed()

This is a method to return memory speed.

=head2 type()

This is a method to return memory type.

=head2 revision()

This is a method to return revision part from the partnumber.

=head2 get()

This is a method to return the partnumber itself in the case it has been fixed during
init() method call.
