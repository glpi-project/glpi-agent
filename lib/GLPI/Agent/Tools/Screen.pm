package GLPI::Agent::Tools::Screen;

use strict;
use warnings;

use English qw(-no_match_vars);

use GLPI::Agent::Logger;
use GLPI::Agent::Tools::Generic;

sub new {
    my ($class, %params) = @_;

    my $self = {
        logger        => $params{logger} ||
                         GLPI::Agent::Logger->new(),
        edid          => $params{edid},
    };
    bless $self, $class;

    # There are two different serial numbers in EDID
    # - a mandatory 4 bytes numeric value
    # - an optional 13 bytes ASCII value
    # We use the ASCII value if present, the numeric value as an hex string
    # unless for a few list of known exceptions deserving specific handling
    # References:
    # http://forge.fusioninventory.org/issues/1607
    # http://forge.fusioninventory.org/issues/1614
    if ($self->{edid}->{serial_number2} && $self->{edid}->{serial_number2}->[0]) {
        $self->{_serial} = $self->{edid}->{serial_number2}->[0];
    } else {
        $self->{_serial} = sprintf("%08x", $self->{edid}->{serial_number});
    }

    # Setup manufacturer
    $self->manufacturer(getEDIDVendor(
                        id      => $self->{edid}->{manufacturer_name},
                        datadir => $params{datadir}
                        ) || $self->{edid}->{manufacturer_name});

    # Try to overload the class with manufacturer dedicated subclass
    return $self->_overloaded($class);
}

# Overload if screen manufacturer is a well-know case
my %EDID_MANUFACTURER_TO_SUBCLASS = (
    ACR => 'Acer',
    AIC => 'Neovo',
    ENC => 'Eizo',
    GSM => 'Goldstar',
    PHL => 'Philips',
    SAM => 'Samsung'
);

sub _overloaded {
    my ($self, $class) = @_;

    my $edidname = $self->{edid}->{manufacturer_name};
    return $self unless $edidname;

    my $manufacturer = $EDID_MANUFACTURER_TO_SUBCLASS{$edidname};
    if ($manufacturer) {
        my $subclass = $class."::".$manufacturer;
        $subclass->require();
        bless $self, $subclass unless ($EVAL_ERROR);
    }
    return $self;
}

sub eisa_id {
    my ($self) = @_;
    return $self->{edid}->{EISA_ID};
}

sub serial {
    my ($self) = @_;
    return $self->{_serial};
}

sub altserial {
    undef;
}

sub week_year_manufacture {
    my ($self) = @_;
    # We should skip week if set to 255 (see specs)
    return $self->{edid}->{week} == 255 ? $self->{edid}->{year}
        : $self->{edid}->{week} . "/" . $self->{edid}->{year};
}

sub caption {
    my ($self) = @_;
    $self->{_caption} = $self->{edid}->{monitor_name};
    unless ($self->{_caption}) {
        my $monitor_text = $self->{edid}->{monitor_text};
        if ($monitor_text && @{$monitor_text}) {
            $self->{_caption} = join(' ', @{$monitor_text});
        }
    }
    return unless $self->{_caption};
    return if ($self->{_caption} =~ /^\s*$/);
    # Clean-up
    $self->{_caption} =~ s/[^ -~].*$// ;
    return $self->{_caption};
}

sub manufacturer {
    my ($self, $manufacturer) = @_;
    $self->{_manufacturer} = $manufacturer if $manufacturer;
    return $self->{_manufacturer};
}

1;
__END__

=head1 NAME

GLPI::Agent::Screen - Base class for screen object

=head1 DESCRIPTION

This is an abstract class for screen objects

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use (default: a new stderr logger)

=item I<edid>

the reference to a hash returned by Parse::EDID::parse_edid()

=back

=head2 serial()

This is a method to be implemented by each subclass. It returns the standard
serial while not overloaded.

=head2 altserial()

This is a method to be implemented by each subclass.

=head2 week_year_manufacture()

The week of screen manufacture

=head2 caption()

Monitor name or computed monitor text as caption

=head2 manufacturer()

Screen manufacturer accessor

=head2 eisa_id()

EISA_ID accessor
