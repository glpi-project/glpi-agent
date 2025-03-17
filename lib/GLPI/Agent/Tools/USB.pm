package GLPI::Agent::Tools::USB;

use strict;
use warnings;

use English qw(-no_match_vars);

use GLPI::Agent::Logger;
use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Generic;

my %loaded;

sub new {
    my ($class, %params) = @_;

    my $self = {
        logger      => $params{logger} || GLPI::Agent::Logger->new(),
        _vendorid   => $params{vendorid},
        _productid  => $params{productid},
        _caption    => $params{caption},
        _name       => $params{name},
        _serial     => $params{serial},
    };

    # Load any related sub-module
    my ($sub_modules_path) = $INC{module2file(__PACKAGE__)} =~ /(.*)\.pm/;
    $sub_modules_path =~ s{\\}{/}g if $OSNAME eq 'MSWin32';
    my ($sub_path_check) = module2file(__PACKAGE__) =~ /(.*)\.pm/;
    $sub_path_check =~ s{\\}{/}g if $OSNAME eq 'MSWin32';

    foreach my $file (File::Glob::bsd_glob("$sub_modules_path/*.pm")) {
        if ($OSNAME eq 'MSWin32') {
            $file =~ s{\\}{/}g;
        }
        next unless $file =~ m{$sub_path_check/(\S+)\.pm$};

        my $module = __PACKAGE__ . "::" . $1;
        # reload can be set by unittests
        unless (defined($loaded{$module}) && !$params{reload}) {
            $loaded{$module} = 0;
            $module->require();
            if ($EVAL_ERROR) {
                $self->{logger}->info("$module require error: $EVAL_ERROR");
                next;
            }
            # Still disable module if module check fails
            $loaded{$module} = $module->enabled() ? 1 : 0;
        }

        next unless $loaded{$module};

        bless $self, $module;
        return $self if $self->supported();
    }

    # Reset to USB device without support
    return bless $self, $class;
}

# Method to implement in subclass if required to disable module on not supported environment
sub enabled {
    return 1;
}

# Method to implement in subclass to detect a subclass applies to an usb device
sub supported {}

# Method to implement in subclass which should update usb device
sub update {}

sub update_by_ids {
    my ($self) = @_;

    # Update device by checking usb.ids
    unless (empty($self->{_vendorid})) {
        my $vendor = getUSBDeviceVendor(
            logger  => $self->{logger},
            id      => lc($self->{_vendorid})
        );
        if ($vendor) {
            $self->{_manufacturer} = $vendor->{name}
                unless empty($vendor->{name});

            unless (empty($self->{_productid})) {
                my $entry = $vendor->{devices}->{lc($self->{_productid})};
                if ($entry && !empty($entry->{name})) {
                    $self->{_caption} = $entry->{name};
                    $self->{_name}    = $entry->{name};
                }
            }
        }
    }
}

sub vendorid {
    my ($self) = @_;
    return $self->{_vendorid} // "";
}

sub productid {
    my ($self) = @_;
    return $self->{_productid} // "";
}

sub serial {
    my ($self, $serial) = @_;

    # Support setter mode
    $self->{_serial} = $serial if defined($serial);

    return $self->{_serial} // "";
}

sub delete_serial {
    my ($self) = @_;

    delete $self->{_serial};
}

sub skip {
    my ($self) = @_;

    # Skip for invalid vendorid
    return empty($self->{_vendorid}) || $self->{_vendorid} =~ /^0+$/ ? 1 : 0;
}

my %keymap = map { my ($key) = /^_(.+)$/; $_ => uc($key) } qw/
    _caption _name _vendorid _productid _serial _manufacturer
/;

sub dump {
    my ($self) = @_;

    my $dump = {};

    foreach my $key (keys(%keymap)) {
        next if empty($self->{$key});
        $dump->{$keymap{$key}} = $self->{$key};
    }

    return $dump;
}

1;

__END__

=head1 NAME

GLPI::Agent::Tools::USB - Base class for usb device object

=head1 DESCRIPTION

This is an abstract class for usb device objects

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use (default: a new stderr logger)

=item I<vendorid>

discovered vendorid

=item I<productid>

discovered productid

=back

=head2 check()

Module API to by-pass module when usage context is wrong. Return true by default.

=head2 supported()

Method API to trigger support for a loaded class

=head2 skip()

Method API to tell USB device should be skipped

=head2 update_by_ids()

Method API to update USB device checking usb.ids database

=head2 update()

Method API to update USB device from subclass

=head2 vendorid()

USB device vendorid accessor.

=head2 productid()

USB device productid accessor.

=head2 serial()

USB device serialnumber accessor.

=head2 dump()

Method to dump datas to be inserted in inventory
