package GLPI::Agent::Task::Collect::Registry;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Collect::Common';

use UNIVERSAL::require;

use constant    function        => "getFromRegistry";

use constant    OPTIONAL        => 0;
use constant    MANDATORY       => 1;

use constant    json_validation => {
    path    => MANDATORY,
    timeout => OPTIONAL,
};

sub _encodeRegistryValueForCollect {
    my ($value, $type) = @_ ;

    # Dump REG_BINARY/REG_RESOURCE_LIST/REG_FULL_RESOURCE_DESCRIPTOR as hex strings
    if (defined($type) && ($type == 3 || $type >= 8)) {
        $value = join(" ", map { sprintf "%02x", ord } split(//, $value));
    }

    return $value;
}

my @RegistryType = qw{
    REG_NONE
    REG_SZ
    REG_EXPAND_SZ
    REG_BINARY
    REG_DWORD
    REG_DWORD_BIG_ENDIAN
    REG_LINK
    REG_MULTI_SZ
    REG_RESOURCE_LIST
    REG_FULL_RESOURCE_DESCRIPTOR
    REG_RESOURCE_REQUIREMENTS_LIST
    REG_QWORD
};

sub results {
    my ($self) = @_;

    return unless GLPI::Agent::Tools::Win32->require();

    $self->{logger}->debug("Looking for '$self->{path}' registry key...");

    # Here we need to retrieve values with their type, getRegistryValue API
    # has been modify to support withtype flag as param
    my $values = GLPI::Agent::Tools::Win32::getRegistryValue(
        path     => $self->{path},
        withtype => 1
    );

    return unless $values;

    my $result = {};
    if (ref($values) eq 'HASH') {
        foreach my $k (keys %$values) {
            # Skip sub keys
            next if ($k =~ m|/$|);
            my ($value, $type) = @{$values->{$k}};
            $result->{$k} = _encodeRegistryValueForCollect($value, $type);
            $self->{logger}->debug2("Found $RegistryType[$type] value: ".$result->{$k});
        }
    } else {
        my ($k) = $self->{path} =~ m|([^/]+)$| ;
        my ($value,$type) = @{$values};
        if (ref($value) eq 'ARRAY') {
            my @values = map { _encodeRegistryValueForCollect($_) } @{$value};
            $result->{$k} = join(",", @values);
            map { $self->{logger}->debug2("Found $RegistryType[$type] value: $_") } @{$value};
        } else {
            $result->{$k} = _encodeRegistryValueForCollect($value,$type);
            $self->{logger}->debug2("Found $RegistryType[$type] value: ".$result->{$k});
        }
    }

    return [ $result ];
}

1;
