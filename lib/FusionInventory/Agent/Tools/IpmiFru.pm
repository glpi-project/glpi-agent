
package FusionInventory::Agent::Tools::IpmiFru;

use strict;
use warnings;

use parent 'Exporter';

use FusionInventory::Agent::Inventory;
use FusionInventory::Agent::Tools;

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

    my $handle = getFileHandle(%params);
    return unless $handle;

    my ($block, $descr);

    while (my $line = <$handle>) {
        chomp $line;

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

    close $handle;

    # push last block in list if still defined
    if ($block) {
        $__fru->{$descr} = $block;
    }

    return $__fru;
}

sub parseFru {
    my ($fru, $fields, $device) = (@_, {});

    for my $attr (@$fields) {
        my $val = $MAPPING{$attr} or next;

        for my $src (@{$val->{src}}) {
            next unless defined $fru->{$src};

            $device->{$attr} = defined $val->{sub} ?
                &{$val->{sub}}( $fru->{$src} ) : $fru->{$src};

            last;
        }
    }

    _postprocess($device, $fields);

    return $device;
}

sub _postprocess {
    my ($device, $fields) = @_;

    # Dell: remove revision suffix from the p/n
    if (defined $device->{MANUFACTURER} && $device->{MANUFACTURER} =~ /dell/i) {
        for my $k ('MODEL', 'PARTNUM') {
            next unless defined $device->{$k}
                && $device->{$k} =~ /^([0-9A-Z]{6})([A-B]\d{2})$/;

            $device->{$k}  = $1;
            $device->{REV} = $2 if any { $_ eq 'REV' } @$fields;
        }
    }
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Tools::ImpiFru

=head1 DESCRIPTION

IPMI FRU functions

=head1 FUNCTIONS

=head2 getIpmiFru()

Returns list of FRU entries

=head2 parseFru()

Returns a formatted FRU section
