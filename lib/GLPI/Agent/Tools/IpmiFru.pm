
package GLPI::Agent::Tools::IpmiFru;

use strict;
use warnings;

use parent 'Exporter';

use GLPI::Agent::Inventory;
use GLPI::Agent::Tools;
use GLPI::Agent::Tools::PartNumber;

our @EXPORT = qw(
    getIpmiFru
    parseFru
);

my %MAPPING = (
    CAPACITY => {
        src => ['Memory size'],
        sub => \&getCanonicalSize,
    },
    NAME => {
        src => ['Board Product', 'Product Name']
    },
    MODEL => {
        src => ['Board Part Number', 'Product Part Number', 'Part Number']
    },
    PARTNUM => {
        src => ['Board Part Number', 'Product Part Number', 'Part Number']
    },
    SERIAL => {
        src => ['Board Serial', 'Product Serial', 'Serial Number']
    },
    SERIALNUMBER => {
        src => ['Board Serial', 'Product Serial', 'Serial Number']
    },
    MANUFACTURER => {
        src => ['Board Mfg', 'Product Manufacturer', 'Manufacturer'],
        sub => \&getCanonicalManufacturer
    },
    REV => {
        src => ['Product Version']
    },
    POWER_MAX => {
        src => ['Max Power Capacity']
    },
);

my $__fru;


sub getIpmiFru {
    my (%params) = (
        command => 'ipmitool fru print',
        @_
    );

    if ($params{file}) {
        # clear cache if testing
        $__fru = undef;
    } elsif ($__fru) {
        # return if cached
        return $__fru;
    }

    my @lines = getAllLines(%params)
        or return;

    my ($block, $descr);

    foreach my $line (@lines) {

        if ($line =~ /^FRU Device Description : (.*)(?: \(ID (\d+)\))?/) {
            # start of block

            # push previous block in list
            if ($block) {
                $__fru->{$descr} = $block;
                undef $block;
            }

            $descr = $1;

            next;
        }

        next unless defined $descr;
        next unless $line =~ /^\s+([^:]+\w)\s+:\s([[:print:]]+)/;

        $block->{$1} = trimWhitespace($2);
    }

    # push last block in list if still defined
    if ($block) {
        $__fru->{$descr} = $block;
    }

    return $__fru;
}

sub parseFru {
    my ($fru, $fields, $device) = (@_, {});

    for my $attr (keys(%{$fields})) {
        my $val = $MAPPING{$attr} or next;

        for my $src (@{$val->{src}}) {
            next unless defined $fru->{$src};

            $device->{$attr} = defined $val->{sub} ?
                &{$val->{sub}}( $fru->{$src} ) : $fru->{$src};

            last;
        }
    }

    # Fix manufacturer
    $device->{MANUFACTURER} = getCanonicalManufacturer($device->{MANUFACTURER})
        if $device->{MANUFACTURER};

    # Validate PartNumber, as example, this fixes Dell PartNumbers
    my $partnum = $device->{PARTNUM} // $device->{MODEL};
    if ($partnum) {
        my $partnumber_factory = GLPI::Agent::Tools::PartNumber->new();
        my $partnumber = $partnumber_factory->match(
            partnumber      => $partnum,
            manufacturer    => $device->{MANUFACTURER},
            category        => "controller",
        );
        if (defined($partnumber)) {
            $device->{PARTNUM} = $partnumber->get if $fields->{PARTNUM};
            $device->{MODEL}   = $partnumber->get if $fields->{MODEL};
            $device->{REV}     = $partnumber->revision
                if $fields->{REV} && defined($partnumber->revision);
        }
    }

    return $device;
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::ImpiFru

=head1 DESCRIPTION

IPMI FRU functions

=head1 FUNCTIONS

=head2 getIpmiFru()

Returns list of FRU entries

=head2 parseFru()

Returns a formatted FRU section
