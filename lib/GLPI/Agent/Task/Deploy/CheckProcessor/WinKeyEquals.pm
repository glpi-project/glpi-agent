package GLPI::Agent::Task::Deploy::CheckProcessor::WinKeyEquals;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use parent "GLPI::Agent::Task::Deploy::CheckProcessor";

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

    $self->on_failure("no value provided to check registry value against");
    my $expected = $self->{value};
    return 0 unless (defined($expected));

    Win32::TieRegistry->require();
    if ($EVAL_ERROR) {
        $self->on_failure("failed to load Win32::TieRegistry: $EVAL_ERROR");
        return 0;
    }
    Win32::TieRegistry->import(qw(REG_DWORD));

    GLPI::Agent::Tools::Win32->require();
    if ($EVAL_ERROR) {
        $self->on_failure("failed to load Win32 tools: $EVAL_ERROR");
        return 0;
    }

    # First check parent winkey
    my ( $parent, $key ) = $self->{path} =~ m|^(.*)/([^/]*)$|;
    $self->on_failure("registry path not supported: ".$self->{path});
    return 0 unless (defined($parent));
    $self->on_failure("missing parent registry key: ".$parent);
    my $parent_key = GLPI::Agent::Tools::Win32::getRegistryKey(
        path => $parent
    );
    return 0 unless (defined($parent_key));

    my @regValue = $parent_key->GetValue($key);

    if ($key && defined($parent_key->{$key.'/'})) {
        $self->on_failure("seen as a registry key: ".$self->{path}.'/');
    } else {
        $self->on_failure("missing registry value: ".$self->{path});
    }
    return 0 unless (@regValue);

    # We need to convert values as string while checking a DWORD value
    my ($regValue, $regType ) = @regValue;
    if ($regType == REG_DWORD()) {
        $regValue = hex($regValue) if ($regValue =~ /^0x/);
        $expected = hex($expected) if ($expected =~ /^0x/);
        $expected = int($expected) if ($expected =~ /^0\d+$/);
    }

    $self->on_success("found expected registry value: $expected in ".$self->{path});
    $self->on_failure("bad registry value: found $regValue vs $expected in ".$self->{path});
    return ( $regValue eq $expected );
}

1;
