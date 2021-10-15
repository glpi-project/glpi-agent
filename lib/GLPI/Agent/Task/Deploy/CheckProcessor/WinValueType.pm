package GLPI::Agent::Task::Deploy::CheckProcessor::WinValueType;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use parent "GLPI::Agent::Task::Deploy::CheckProcessor";

# No perl Win32API returns the string type from the value, here is the
# official ordered list interpreted from winnt.h
my @Types = qw(
    REG_NONE REG_SZ REG_EXPAND_SZ REG_BINARY REG_DWORD REG_DWORD_BIG_ENDIAN
    REG_LINK REG_MULTI_SZ REG_RESOURCE_LIST REG_FULL_RESOURCE_DESCRIPTOR
    REG_RESOURCE_REQUIREMENTS_LIST REG_QWORD
);

sub prepare {
    my ($self) = @_;

    $self->{path} =~ s{\\}{/}g;
    # We will look for default regkey value while path ends with / ou \
    $self->{path} =~ s{/+$}{/}g;
}

sub success {
    my ($self) = @_;

    $self->on_failure("check only available on windows");
    return 0 unless $OSNAME eq 'MSWin32';

    $self->on_failure("no value type provided to check registry value type against");
    my $expected = $self->{value};
    return 0 unless (defined($expected));

    $self->on_failure("wrong $expected type provided to check registry value type against");
    return 0 unless ($expected =~ /^REG_[_A-Z]+$/);

    $self->on_success("found $expected registry value type: ".$self->{path});

    Win32API::Registry->require();
    if ($EVAL_ERROR) {
        $self->on_failure("failed to load Win32API::Registry: $EVAL_ERROR");
        return 0;
    }
    eval {
        $expected = Win32API::Registry::constant($expected);
    };
    return 0 unless (defined($expected));

    GLPI::Agent::Tools::Win32->require();
    if ($EVAL_ERROR) {
        $self->on_failure("failed to load Win32 tools: $EVAL_ERROR");
        return 0;
    }

    # First check parent winkey
    my ( $parent, $key ) = $self->{path} =~ m|^(.*)/([^/]*)$|;
    $self->on_failure("registry path not supported: ".$self->{path});
    return 0 unless (defined($parent));
    $self->on_failure("missing registry key: ".$parent);
    my $parent_key = GLPI::Agent::Tools::Win32::getRegistryKey(
        path => $parent
    );
    return 0 unless (defined($parent_key));

    my @regValue = $parent_key->GetValue($key);

    if ($key && defined($parent_key->{$key.'/'})) {
        $self->on_failure("missing but seen path as a registry key: ".$self->{path}.'/');
    } else {
        $self->on_failure("missing registry value: ".$self->{path});
    }
    return 0 unless (@regValue);

    my ($regValue, $regType ) = @regValue;
    my ($sType, $sExpected ) = (
        $Types[$regType] || "unsupported", $Types[$expected] || "unsupported"
    );
    $self->on_failure("bad registry value type: found $sType vs expected $sExpected in ".$self->{path});
    return ( $regType == $expected );
}

1;
