package Win32::TieRegistry;

use strict;
use warnings;

use constant REG_SZ    => 0x1;
use constant REG_DWORD => 0x4;

our $Registry;

sub import {
    my $callpkg = caller();
    no strict 'refs';

    *{"$callpkg\::Registry"} = \$Registry;
    *{"$callpkg\::KEY_READ"} = sub {}
        unless ref(\&{"$callpkg\::KEY_READ"}) eq "CODE";
    *{"$callpkg\::REG_SZ"}    = sub { REG_SZ };
    *{"$callpkg\::REG_DWORD"} = sub { REG_DWORD };
}

sub GetValue {
    my ($self, $value ) = @_ ;
    # Subkey case
    if ($value && exists($self->{$value})) {
        return wantarray ? () : undef ;
    }
    # Value case
    $value = '/'.$value;
    return unless ($value && exists($self->{$value}));
    return wantarray ?
        ( $self->{$value}, $self->{$value} =~ /^0x/ ? REG_DWORD : REG_SZ )
        : $self->{$value} ;
}

sub SubKeyNames {
    my ($self, $key) = @_ ;
    my @keys = map { s|/$|| && $_ } grep { m|/$| } keys(%{$self});
    return @keys;
}

sub Information {
    my ($self) = @_ ;
    # Only CntValues is used in Softwares inventory
    return CntValues => scalar(grep { m|^/| } keys(%{$self}));
}

sub Handle {}

sub Open {
    my ($self, $subkey) = @_ ;
    return $self->{"$subkey/"};
}

1;
