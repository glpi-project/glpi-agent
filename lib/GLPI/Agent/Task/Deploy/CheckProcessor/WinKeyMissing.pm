package GLPI::Agent::Task::Deploy::CheckProcessor::WinKeyMissing;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use parent "GLPI::Agent::Task::Deploy::CheckProcessor";

sub prepare {
    my ($self) = @_;

    $self->{path} =~ s{\\}{/}g;
    $self->{path} =~ s{/+$}{}g;

    $self->on_success("missing registry key: ".$self->{path}.'/');
}

sub success {
    my ($self) = @_;

    $self->on_failure("check only available on windows");
    return 0 unless $OSNAME eq 'MSWin32';

    GLPI::Agent::Tools::Win32->require();
    if ($EVAL_ERROR) {
        $self->on_failure("failed to load Win32 tools: $EVAL_ERROR");
        return 0;
    }

    # First check parent winkey, okay if still missing
    my ( $parent, $key ) = $self->{path} =~ m|^(.*)/([^/]*)$|;
    $self->on_failure("registry path not supported: ".$self->{path});
    return 0 unless (defined($parent));
    my $parent_key = GLPI::Agent::Tools::Win32::getRegistryKey(
        path => $parent
    );
    return 1 unless (defined($parent_key));

    # Test if path could be seen as a value path
    if (defined($parent_key->{'/'.$key})) {
        $self->on_success("missing registry key, but can be seen as a value: ".$self->{path});
        $self->on_failure("registry key found, also seen as a value: ".$self->{path}.'/');
    } else {
        $self->on_failure("registry key found: ".$self->{path}.'/');
    }

    return ! defined($parent_key->{$key.'/'});
}

1;
