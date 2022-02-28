package GLPI::Agent::SNMP::MibSupport::ConfigurationPlugin;

use strict;
use warnings;

use parent qw(
    GLPI::Agent::SNMP::MibSupportTemplate
);

use English qw(-no_match_vars);
use UNIVERSAL::require;

use GLPI::Agent::Config;
use GLPI::Agent::Tools;
use GLPI::Agent::Tools::SNMP;
use GLPI::Agent::Logger;
use GLPI::Agent::HTTP::Server::ToolBox;

our $mibSupport = [];

my ($config, $yaml, $logger);

sub getFirmware {
    my ($self) = @_;

    return $self->_getFirstFromRules('firmware');
}

sub getFirmwareDate {
    my ($self) = @_;

    return $self->_getFirstFromRules('firmwaredate');
}

sub getSerial {
    my ($self) = @_;

    return $self->_getFirstFromRules('serial');
}

sub getMacAddress {
    my ($self) = @_;

    return $self->_getFirstFromRules('mac');
}

sub getIp {
    my ($self) = @_;

    return $self->_getFirstFromRules('ip');
}

sub getModel {
    my ($self) = @_;

    return $self->_getFirstFromRules('model');
}

sub getType {
    my ($self) = @_;

    return $self->_getFirstFromRules('typedef');
}

sub getManufacturer {
    my ($self) = @_;

    return $self->_getFirstFromRules('manufacturer');
}

sub run {
    #my ($self) = @_;

    #my $device = $self->device
    #    or return;

    #my $other_firmware = {
    #    NAME            => 'XXX Device',
    #    DESCRIPTION     => 'XXX ' . $self->get(sectionOID . '.X.D') .' device',
    #    TYPE            => 'Device type',
    #    VERSION         => $self->get(sectionOID . '.X.D'),
    #    MANUFACTURER    => 'XXX'
    #};
    #$device->addFirmware($other_firmware);
}

sub configure {
    my ($agent, %params) = @_;

    $logger = $params{logger} || GLPI::Agent::Logger->new();

    $config = $params{config} || GLPI::Agent::Config->new();

    my $confdir = $config->confdir();

    # Load defaults and plugin configuration
    my $defaults = GLPI::Agent::HTTP::Server::ToolBox::defaults();
    foreach my $param (keys(%{$defaults})) {
        $config->{$param} = $defaults->{$param};
    }
    $config->loadFromFile({
        file        => "$confdir/toolbox-plugin.cfg",
        defaults    => $defaults
    }) if -f "$confdir/toolbox-plugin.cfg";

    my $yamlconfig = $confdir . "/" . $config->{yaml};
    if (! -e $yamlconfig) {
        $logger->debug2("$yamlconfig configuration not found");
        return;
    }

    YAML::Tiny->require();
    if ($EVAL_ERROR) {
        $logger->debug("Cant't load needed YAML::Tiny perl module");
        return;
    }

    my $tiny_yaml = YAML::Tiny->read($yamlconfig);
    unless ($tiny_yaml && @{$tiny_yaml}) {
        $logger->debug("Failed to load $yamlconfig: $EVAL_ERROR");
        return;
    }

    $yaml = $tiny_yaml->[0] || {};
    my $disabled = $yaml->{configuration} && $yaml->{configuration}->{mibsupport_disabled} || 0;
    return unless $disabled =~ /^0|no$/i;

    my $sysobjectid = $yaml->{sysobjectid};
    if ($sysobjectid) {
        foreach my $name (keys(%{$sysobjectid})) {
            next unless $sysobjectid->{$name};
            my $oid = $sysobjectid->{$name}->{oid}
                or next;
            my $match = getRegexpOidMatch(_normalizedOid($oid));
            if ($match) {
                push @{$mibSupport}, {
                    name        => "sysObjectID:".$name,
                    sysobjectid => $match,
                };
            } else {
                $logger->debug("$name sysobjectid: match evaluation failure on ".$oid);
            }
        }
    }

    my $mibsupport = $yaml->{mibsupport};
    if ($mibsupport) {
        foreach my $name (keys(%{$mibsupport})) {
            next unless $mibsupport->{$name};
            if (my $miboid = $mibsupport->{$name}->{oid}) {
                push @{$mibSupport}, {
                    name    => "mibSupport:".$name,
                    oid     => _normalizedOid($miboid),
                };
            }
        }
    }
}

sub _normalizedOid {
    my ($oid, $loop) = @_;

    my $updated = 0;

    $oid =~ s/^enterprises/.1.3.6.1.4.1/;
    $oid =~ s/^private/.1.3.6.1.4/;
    $oid =~ s/^mib-2/.1.3.6.1.2.1/;
    $oid =~ s/^iso/.1/;
    my $aliases = $yaml->{aliases} || {};
    foreach my $alias (keys(%{$aliases})) {
        $updated++ if $oid =~ s/^$alias/$aliases->{$alias}/;
    }
    return $updated && ++$loop < 10 ? _normalizedOid($oid, $loop) : $oid;
}

sub _getFirstFromRules {
    my ($self, $type) = @_;

    my $found;
    foreach my $rule ($self->_getRules($type)) {
        my $type = $rule->{type} || 'get-string';
        $found = $rule->{value} =~ /^\.[0-9.]+\d$/ ? $rule->{value} : _normalizedOid($rule->{value});
        $logger->debug2("Matching rule value: $found") if $logger;
        # Only get from oid if looks like an oid, otherwise we will use raw found value
        if ($type ne 'raw' && $type =~ /^get-/ && $found =~ /^(\.[0-9.]+\d)$/) {
            $found = $2 ? getCanonicalMacAddress($self->get($1)) : $self->get($1);
            if ($type eq 'get-mac') {
                $found = getCanonicalMacAddress($found);
            } elsif ($type eq 'get-serial') {
                $found = getCanonicalSerialNumber($found);
            } else {
                $found = getCanonicalString($found);
            }
        }
        # Accept zero as valid but skip empty string
        if (defined($found) && length($found)) {
            $logger->debug2("Retrieved value: $found") if $logger;
            last;
        }
    }
    return $found;
}

sub _getRules {
    my ($self, $type) = @_;

    my $rules = $yaml->{rules}
        or return;

    my @enabledrules = ();

    my ($support, $name) = $self->support() =~ /^(sysObjectID|mibSupport):(.*)$/;
    if ($support eq "sysObjectID") {
        return unless $yaml->{sysobjectid} && $yaml->{sysobjectid}->{$name};
        push @enabledrules, @{$yaml->{sysobjectid}->{$name}->{rules}}
            if ref($yaml->{sysobjectid}->{$name}->{rules}) eq 'ARRAY';
    } elsif ($support eq "mibSupport") {
        return unless $yaml->{mibsupport} && $yaml->{mibsupport}->{$name};
        push @enabledrules, @{$yaml->{mibsupport}->{$name}->{rules}}
            if ref($yaml->{mibsupport}->{$name}->{rules}) eq 'ARRAY';
    }

    my @oids = ();
    foreach my $rule (@enabledrules) {
        next unless $rules->{$rule};
        next unless $rules->{$rule}->{type};
        next unless $rules->{$rule}->{type} eq $type;
        push @oids, {
            value   => $rules->{$rule}->{value},
            type    => $rules->{$rule}->{valuetype},
        };
        $logger->debug2("Matching rule: $rule") if $logger;
    }

    return @oids;
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport::ConfigurationPlugin - Fully configurable
inventory module

=head1 DESCRIPTION

The module can be used to extend devices support. It reads a YAML file which
contains the descriptions of matching cases and associated rules to apply.
