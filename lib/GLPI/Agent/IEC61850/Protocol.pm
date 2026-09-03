package GLPI::Agent::IEC61850::Protocol;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use GLPI::Agent::Tools;

use constant logger_prefix  => "[iec61850] ";

use constant PhyNamVariables    => [ qw(model hwRev vendor serNum swRev owner location) ];

# Just try to load iec61850 module, if finally not loaded network tasks will detect it
# by checking %INC and won't just not use this library if not seen there
iec61850->require();

my $logged = 0;
sub not_supported {
    my (%params) = @_;

    unless ($logged) {
        $logged = 1;
        if ($params{logger}) {
            $params{logger}->info("Failed to load iec61850 perl library".($params{message} ? ", $params{message}" : ""));
        }
    }
}

sub new {
    my ($class, %params) = @_;

    my $self = {
        glpi    => $params{glpi} // '', # glpi server version if we need to check feature support
        logger  => $params{logger},
        timeout => $params{timeout} // 60, # In second
        ip      => $params{ip},
        port    => $params{port} // 102,
        dump    => $params{dump} // 0,
        file    => $params{file} // '',
        _scan   => {},
    };

    bless $self, $class;

    return $self;
}

sub connect {
    my ($self) = @_;

    # Emulate connect when a dump file is provided
    return -s $self->{file} if $self->{file};

    my $con = iec61850::IedConnection_create();

    # Still keep connection to handle destroying
    $self->{_connection} = $con;

    # Timeout must be set here in millisecond for iec61850 APIs
    my $timeout = $self->{timeout} * 1000;
    iec61850::IedConnection_setConnectTimeout($con, $timeout);

    my $ip   = $self->{ip};
    my $port = $self->{port} || 102;

    my $error = iec61850::IedConnection_connect($con, $ip, $port);
    if ($error != $iec61850::IED_ERROR_OK) {
        $self->{logger}->debug2(logger_prefix."Connection error: ".iec61850::IedClientError_toString($error));
        return 0;
    }

    # Also configure timeout on requests
    iec61850::IedConnection_setRequestTimeout($con, $timeout);

    $self->{logger}->debug2(logger_prefix."Connected to $ip:$port");

    return $con;
}

sub disconnect {
    my ($self) = @_;

    return unless defined($self->{_connection});

    iec61850::IedConnection_close($self->{_connection});
}

sub scan {
    my ($self) = @_;

    return $self->_load() if $self->{file};

    my $maxDevices = 1;

    my $error = iec61850::IedConnection_getDeviceModelFromServer($self->{_connection});
    if ($error != $iec61850::IED_ERROR_OK) {
        $self->{logger}->debug2(logger_prefix."getDeviceModelFromServer error: ".iec61850::IedClientError_toString($error));
        return;
    }

    my $deviceList;
    ($deviceList, $error) = iec61850::IedConnection_getServerDirectory($self->{_connection}, 0);
    if ($error != $iec61850::IED_ERROR_OK) {
        $self->{logger}->debug2(logger_prefix."getServerDirectory error: ".iec61850::IedClientError_toString($error));
        return;
    } elsif (!defined($deviceList)) {
        $self->{logger}->debug2(logger_prefix."No data returned from device");
        return;
    }

    my $device = iec61850::LinkedList_getNext($deviceList);
    while (defined($device)) {
        my $name = iec61850::toCharP($device->swig_data_get);
        $self->{logger}->debug2(logger_prefix."Scanning $name device");
        $self->_getLogicalDeviceDirectory($name);
        last unless --$maxDevices;
        $device = iec61850::LinkedList_getNext($device);
    }

    iec61850::LinkedList_destroy($deviceList);

    $self->_dump() if $self->{dump};
}

sub _getLogicalDeviceDirectory {
    my ($self, $device) = @_;

    # Keep found device as name
    $self->{_scan}->{Name} = $device;

    my ($logicalNodes, $error) = iec61850::IedConnection_getLogicalDeviceDirectory($self->{_connection}, $device);
    if ($error != $iec61850::IED_ERROR_OK) {
        $self->{logger}->debug2(logger_prefix."getLogicalDeviceDirectory error: ".iec61850::IedClientError_toString($error));
        return;
    } elsif (!defined($logicalNodes)) {
        $self->{logger}->debug2(logger_prefix."Failed to get $device logical device");
        return;
    }

    my $logicalNode = iec61850::LinkedList_getNext($logicalNodes);
    while (defined($logicalNode)) {
        my $lnName = iec61850::toCharP($logicalNode->swig_data_get);
        if ($lnName =~ /^LPHD\d+$/) {
            $self->{logger}->debug2(logger_prefix."Scanning $device/$lnName logical node directory");
            $self->_getLogicalNodeDirectory("$device/$lnName");
            # Keep logicalNode as Node for debugging while dumping
            $self->{_scan}->{Node} = $lnName if $self->{dump};
            # No need to continue on next logicalNode as we reached the one with required datas
            last;
        }
        $logicalNode = iec61850::LinkedList_getNext($logicalNode);
    }

    iec61850::LinkedList_destroy($logicalNodes);
}

sub _getLogicalNodeDirectory {
    my ($self, $logicalNode) = @_;

    my ($dataObjects, $error) = iec61850::IedConnection_getLogicalNodeDirectory($self->{_connection}, $logicalNode, $iec61850::ACSI_CLASS_DATA_OBJECT);
    if ($error != $iec61850::IED_ERROR_OK) {
        $self->{logger}->debug2(logger_prefix."getLogicalNodeDirectory error: ".iec61850::IedClientError_toString($error));
        return;
    } elsif (!defined($dataObjects)) {
        $self->{logger}->debug2(logger_prefix."Failed to get $logicalNode logical node");
        return;
    }

    my $dataObject = iec61850::LinkedList_getNext($dataObjects);
    while (defined($dataObject)) {
        my $dataObjectName = iec61850::toCharP($dataObject->swig_data_get);
        if ($dataObjectName eq "PhyNam") {
            $self->_getVariables($logicalNode, $dataObjectName, PhyNamVariables);
            # No need to continue on next dataObject as we reached the one with required datas
            last;
        }
        $dataObject = iec61850::LinkedList_getNext($dataObject);
    }

    iec61850::LinkedList_destroy($dataObjects);
}

sub _getVariables {
    my ($self, $logicalNode, $dataObject, $variables) = @_;

    my $dataObjectVariables = $logicalNode.".".$dataObject;

    foreach my $var (@{$variables}) {
        my $ref = $dataObjectVariables.".".$var;
        my ($value, $error) = iec61850::IedConnection_readStringValue($self->{_connection}, $ref, $iec61850::IEC61850_FC_DC);
        if ($error != $iec61850::IED_ERROR_OK) {
            $self->{logger}->debug2(logger_prefix."readStringValue error for $ref: ".iec61850::IedClientError_toString($error));
            next;
        } elsif (empty($value)) {
            # Just skip eventually not defined or empty values
            next;
        }
        $self->{_scan}->{$dataObject}->{$var} = $value;
    }
}

sub _load {
    my ($self) = @_;

    return unless $self->{file} && -s $self->{file};

    my $count = 0;
    foreach my $line (getAllLines(file => $self->{file})) {
        $count++;
        if ($line =~ /^(.+)\.([^.]+): (.*)$/) {
            $self->{_scan}->{$1}->{$2} = $3;
        } elsif ($line =~ /^(.+): (.*)$/) {
            $self->{_scan}->{$1} = $2;
        } else {
            $count--;
        }
    }

    $self->{logger}->debug2(logger_prefix."Loaded $count data lines from $self->{file}");
}

sub _dump {
    my ($self) = @_;

    my $file = ($self->{_scan}->{Name} ? $self->{_scan}->{Name}."-" : "").$self->{ip}.".iec-dump";

    my $count = 0;
    if (open my $fh, '>', $file) {
        foreach my $key (sort keys(%{$self->{_scan}})) {
            next unless defined($self->{_scan}->{$key});
            if (ref($self->{_scan}->{$key}) eq "HASH") {
                foreach my $subkey (sort keys(%{$self->{_scan}->{$key}})) {
                    next unless defined($self->{_scan}->{$key}->{$subkey});
                    print $fh "$key.$subkey: $self->{_scan}->{$key}->{$subkey}\n";
                    $count++;
                }
            } else {
                print $fh "$key: $self->{_scan}->{$key}\n";
                $count++;
            }
        }
        close $fh;
        $self->{logger}->info(logger_prefix."Dumped $count iec61850 inventory datas in $file");
    } else {
        $self->{logger}->error(logger_prefix."Failed to open $file for writing: $!");
    }
}

sub getVariable {
    my ($self, $dataObject, $variable) = @_;

    return if empty($dataObject);

    return $self->{_scan}->{$dataObject} unless ref($self->{_scan}->{$dataObject}) eq "HASH" && !empty($variable);

    return $self->{_scan}->{$dataObject}->{$variable};
}

sub DESTROY {
    my ($self) = @_;

    return unless defined($self->{_connection});

    iec61850::IedConnection_destroy($self->{_connection});
}

1;

__END__

=head1 NAME

GLPI::Agent::IEC61850::Device - GLPI Agent IEC61850 device

=head1 DESCRIPTION

Class to help handle general methods to apply on a IEC61850 device
