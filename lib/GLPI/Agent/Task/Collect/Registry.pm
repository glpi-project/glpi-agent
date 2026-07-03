package GLPI::Agent::Task::Collect::Registry;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Collect::Common';

use UNIVERSAL::require;

use constant    function        => "getFromRegistry";

use constant    OPTIONAL        => 0;
use constant    MANDATORY       => 1;

use constant    MAX_DEPTH       => 10;

use constant    json_validation => {
    path    => MANDATORY,
    timeout => OPTIONAL,
    exists  => OPTIONAL,
    defined => OPTIONAL,
    depth   => OPTIONAL,
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

    return $self->_exists() if $self->{exists};
    return $self->_defined() if $self->{defined};
    return $self->_depth() if defined($self->{depth});

    # Here we need to retrieve values with their type, getRegistryValue API
    # has been modify to support withtype flag as param
    my $values = GLPI::Agent::Tools::Win32::getRegistryValue(
        path     => $self->{path},
        withtype => 1
    );

    return unless $values;

    # Glpi-Inventory plugin >= v1.6.9 supports multiple values submission one by one
    my $updated_plugin = $self->pluginSupport("1.6.9");

    my $results = [];
    my $result = {};
    if (ref($values) eq 'HASH') {
        foreach my $k (keys %$values) {
            # Skip sub keys
            next if ($k =~ m|/$|);
            my ($value, $type) = @{$values->{$k}};
            if ($updated_plugin) {
                $value = _encodeRegistryValueForCollect($value, $type) // "";
                push @{$results}, {
                    _path   => $k,
                    _value  => $value,
                };
                $self->{logger}->debug2("Found".(defined($type) && $type < scalar(@RegistryType) ? " ".$RegistryType[$type] : "")." value for $k: ".$value);
            } else {
                $result->{$k} = _encodeRegistryValueForCollect($value, $type) // "";
                $self->{logger}->debug2("Found".(defined($type) && $type < scalar(@RegistryType) ? " ".$RegistryType[$type] : "")." value for $k: ".$result->{$k});
            }
        }
    } else {
        my ($k) = $self->{path} =~ m|([^/]+)$| ;
        my ($value, $type) = @{$values};
        if (ref($value) eq 'ARRAY') {
            my @values = map { _encodeRegistryValueForCollect($_) } @{$value};
            $result->{$k} = join(",", @values);
            map { $self->{logger}->debug2("Found".(defined($type) && $type < scalar(@RegistryType) ? " ".$RegistryType[$type] : "")." value: $_") } @{$value};
        } else {
            $result->{$k} = _encodeRegistryValueForCollect($value,$type);
            $self->{logger}->debug2("Found".(defined($type) && $type < scalar(@RegistryType) ? " ".$RegistryType[$type] : "")." value: ".$result->{$k});
        }
        push @{$results}, {
            _path   => $k,
            _value  => $result->{$k},
        } if $updated_plugin;
    }

    return $updated_plugin ? $results : [ $result ];
}

sub _exists() {
    my ($self) = @_;

    my $key = GLPI::Agent::Tools::Win32::getRegistryKey(path => $self->{path});

    return [
        {
            _exists => defined($key) ? 1 : 0
        }
    ];
}

sub _defined() {
    my ($self) = @_;

    my $value = GLPI::Agent::Tools::Win32::getRegistryValue(path => $self->{path});

    return [
        {
            _defined => defined($value) ? 1 : 0
        }
    ];
}

sub _depth() {
    my ($self, $depth) = @_;

    return unless $self->{depth} =~ /^\d+$/;

    my $key = GLPI::Agent::Tools::Win32::getRegistryKey(path => $self->{path});

    return unless defined($key);

    $self->{_results} = [];

    $depth = int($self->{depth}) > MAX_DEPTH ? MAX_DEPTH : int($self->{depth});

    $self->_recursive($key, "", $depth);

    return delete $self->{_results};
}

sub _recursive() {
    my ($self, $key, $path, $depth) = @_;

    return unless $key;

    my @subkeys;

    # First handle values in this leaf
    foreach my $k (sort keys(%{$key})) {
        # Skip sub keys by now
        if ($k =~ m|/$|) {
            push @subkeys, $k if $depth > 0;
        } else {
            ($k) = $k =~ m|([^/]+)$|;
            my $info = GLPI::Agent::Tools::Win32::getRegistryKeyValue($key, $k, 1);
            next unless ref($info) eq "ARRAY";
            my ($value, $type) = @{$info};
            $value = _encodeRegistryValueForCollect($value, $type);
            push @{$self->{_results}}, {
                _path   => $path.$k,
                _value  => $value
            };
            $self->{logger}->debug2("Found".(defined($type) && $type < scalar(@RegistryType) ? " ".$RegistryType[$type] : "")." value for $path$k: ".$value);
        }
    }

    # Then handle recursive calls
    foreach my $sk (@subkeys) {
        $self->_recursive($key->{$sk}, $path.$sk, $depth-1);
    }
}

1;
