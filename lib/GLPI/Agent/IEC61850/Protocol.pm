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

sub new {
    my ($class, %params) = @_;

    my $self = {
        glpi    => $params{glpi} // '', # glpi server version if we need to check feature support
        logger  => $params{logger},
        timeout => $params{timeout} // 60, # In second
        ip      => $params{ip},
    };

    bless $self, $class;

    return $self;
}

sub connect {
    my ($self, $host, $port) = @_;

    my $con = iec61850::IedConnection_create();

    # Timeout must be set here in millisecond for iec61850 APIs
    my $timeout = $self->{timeout} * 1000;
    iec61850::IedConnection_setConnectTimeout($con, $timeout);

    my $error = iec61850::IedConnection_connect($con, $host, $port || 102);
    if ($error != $iec61850::IED_ERROR_OK) {
        $self->{logger}->debug(logger_prefix."Connection error: ".iec61850::IedClientError_toString($error));
        return 0;
    }

    # Also configure timeout on requests
    iec61850::IedConnection_setRequestTimeout($con, $timeout);

    $self->{logger}->debug2(logger_prefix."Connected to $host:".($port || 102));

    return $self->{_connection} = $con;
}

sub disconnect {
    my ($self) = @_;

    iec61850::IedConnection_close(delete $self->{_connection})
        if defined($self->{_connection});
}

sub scan {
    my ($self) = @_;

    my $maxDevices = 1;

    my $error = iec61850::IedConnection_getDeviceModelFromServer($self->{_connection});
    if ($error != $iec61850::IED_ERROR_OK) {
        $self->{logger}->debug(logger_prefix."getDeviceModelFromServer error: ".iec61850::IedClientError_toString($error));
        return;
    }

    my $deviceList;
    ($deviceList, $error) = iec61850::IedConnection_getServerDirectory($self->{_connection}, 0);
    if ($error != $iec61850::IED_ERROR_OK) {
        $self->{logger}->debug(logger_prefix."getServerDirectory error: ".iec61850::IedClientError_toString($error));
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
}

sub _getLogicalDeviceDirectory {
    my ($self, $device) = @_;

    # Keep found device as name
    $self->{Name} = $device;

    my ($logicalNodes, $error) = iec61850::IedConnection_getLogicalDeviceDirectory($self->{_connection}, $device);
    if ($error != $iec61850::IED_ERROR_OK) {
        $self->{logger}->debug(logger_prefix."getLogicalDeviceDirectory error: ".iec61850::IedClientError_toString($error));
        return;
    } elsif (!defined($logicalNodes)) {
        $self->{logger}->debug(logger_prefix."Failed to get $device logical device");
        return;
    }

    my $logicalNode = iec61850::LinkedList_getNext($logicalNodes);
    while (defined($logicalNode)) {
        my $lnName = iec61850::toCharP($logicalNode->swig_data_get);
        if ($lnName =~ /^LPHD\d+$/) {
            $self->{logger}->debug2(logger_prefix."Scanning $device/$lnName logical node directory");
            $self->_getLogicalNodeDirectory("$device/$lnName");
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
        $self->{logger}->debug(logger_prefix."getLogicalNodeDirectory error: ".iec61850::IedClientError_toString($error));
        return;
    } elsif (!defined($dataObjects)) {
        $self->{logger}->debug(logger_prefix."Failed to get $logicalNode logical node");
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
            $self->{logger}->debug(logger_prefix."readStringValue error for $ref: ".iec61850::IedClientError_toString($error));
            next;
        } elsif (empty($value)) {
            # Just skip eventually not defined or empty values
            next;
        }
        $self->{$dataObject}->{$var} = $value;
    }
}

sub getVariable {
    my ($self, $dataObject, $variable) = @_;

    return if empty($dataObject);

    return $self->{$dataObject} unless ref($self->{$dataObject}) eq "HASH" && !empty($variable);

    return $self->{$dataObject}->{$variable};
}

sub DESTROY {
    my ($self) = @_;

    iec61850::IedConnection_close($self->{_connection})
        if defined($self->{_connection});
}

1;

__END__

=head1 NAME

GLPI::Agent::IEC61850::Device - GLPI Agent IEC61850 device

=head1 DESCRIPTION

Class to help handle general methods to apply on a IEC61850 device
