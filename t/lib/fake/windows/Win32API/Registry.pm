package Win32API::Registry;

use strict;
use warnings;

my @Types = qw(
    REG_NONE REG_SZ REG_EXPAND_SZ REG_BINARY REG_DWORD REG_DWORD_BIG_ENDIAN
    REG_LINK REG_MULTI_SZ REG_RESOURCE_LIST REG_FULL_RESOURCE_DESCRIPTOR
    REG_RESOURCE_REQUIREMENTS_LIST REG_QWORD
);

my $constant_index = 0 ;
my %constants = map { $_ => $constant_index++ } @Types;

sub constant {
    my ($constant) = @_ ;

    return $constants{$constant} if exists($constants{$constant});
}

sub RegQueryValueExW {}

1;
