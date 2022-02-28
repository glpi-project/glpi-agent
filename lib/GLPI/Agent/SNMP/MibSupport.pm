package GLPI::Agent::SNMP::MibSupport;

use strict;
use warnings;

# Extracted from SNMPv2-MIB standard
use constant    sysORID => '.1.3.6.1.2.1.1.9.1.2';

use English qw(-no_match_vars);
use File::Glob;
use UNIVERSAL::require;

use GLPI::Agent::Tools;
use GLPI::Agent::Logger;

sub new {
    my ($class, %params) = @_;

    my $device = $params{device};

    return unless $device;

    my $logger      = $params{logger} || $device->{logger} || GLPI::Agent::Logger->new();
    my $sysobjectid = $params{sysobjectid};
    my $sysorid     = $device->walk(sysORID);

    my $self = {
        _SUPPORT    => {},
        logger      => $logger
    };

    # Load any related sub-module dedicated to MIB support
    my ($sub_modules_path) = $INC{module2file(__PACKAGE__)} =~ /(.*)\.pm/;
    my %available_mib_support = ();
    foreach my $file (File::Glob::bsd_glob("$sub_modules_path/*.pm")) {
        if ($OSNAME eq 'MSWin32') {
            $file =~ s{\\}{/}g;
            $sub_modules_path =~ s{\\}{/}g;
        }
        next unless $file =~ m{$sub_modules_path/(\S+)\.pm$};

        my $module = __PACKAGE__ . "::" . $1;
        $module->require();
        if ($EVAL_ERROR) {
            $logger->debug2("$module require error: $EVAL_ERROR");
            next;
        }
        my $supported_mibs;
        {
            no strict 'refs'; ## no critic (ProhibitNoStrict)
            # Call module initialization
            $module->configure(
                logger => $logger,
                config => $params{config}, # required for ConfigurationPlugin
            );
            $supported_mibs = ${$module . "::mibSupport"};
        }

        if ($supported_mibs && @{$supported_mibs}) {
            foreach my $mib_support (@{$supported_mibs}) {
                # checking first if sysobjectid test is present, this is another
                # advanced way to replace sysobject.ids file EXTMOD feature support
                if ($mib_support->{sysobjectid} && $sysobjectid) {
                    my $mibname = $mib_support->{name}
                        or next;
                    if ($sysobjectid =~ $mib_support->{sysobjectid}) {
                        $logger->debug("sysobjectID match: $mibname mib support enabled") if $logger;
                        $self->{_SUPPORT}->{$module} = $module->new(
                            device      => $device,
                            mibsupport  => $mibname,
                        );
                        next;
                    }
                } elsif ($mib_support->{privateoid}) {
                    my $mibname = $mib_support->{name}
                        or next;
                    my $private = $device->get($mib_support->{privateoid})
                        or next;
                    $logger->debug("PrivateOID match: $mibname mib support enabled") if $logger;
                    $self->{_SUPPORT}->{$module} = $module->new( device => $device );
                    next;
                }
                my $miboid = $mib_support->{oid}
                    or next;
                $mib_support->{module} = $module;
                # Include support for related OID
                $available_mib_support{$miboid} = $mib_support;
            }
        }
    }

    # Keep in _SUPPORT only needed mib support
    foreach my $mibindex (sort keys %{$sysorid}) {
        my $miboid = $sysorid->{$mibindex};
        my $supported = $available_mib_support{$miboid}
            or next;
        my $mibname = $supported->{name}
            or next;
        my $module = $supported->{module};
        $logger->debug2("sysorid: $mibname mib support enabled") if $logger;
        $self->{_SUPPORT}->{$module} = $module->new(
            device      => $device,
            mibsupport  => $mibname,
        );
    }

    # Now sort modules by priority
    my @supported = sort {
        $a->priority() <=> $b->priority()
    } grep { defined } values(%{$self->{_SUPPORT}});
    $self->{_SUPPORT} = \@supported;

    bless $self, $class;

    return $self;
}

sub getMethod {
    my ($self, $method) = @_;

    return unless $method;

    my $value;
    foreach my $mibsupport (@{$self->{_SUPPORT}}) {
        next unless $mibsupport;
        $value = $mibsupport->$method();
        last if defined $value;
    }

    return $value;
}

sub run {
    my ($self, %params) = @_;

    foreach my $mibsupport (@{$self->{_SUPPORT}}) {
        next unless $mibsupport;
        $mibsupport->run();
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::SNMP::MibSupport - GLPI agent SNMP mib support

=head1 DESCRIPTION

Class to help handle vendor-specific mibs support modules

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item logger

=item sysorid_list (mandatory)

=item device (mandatory)

=back
