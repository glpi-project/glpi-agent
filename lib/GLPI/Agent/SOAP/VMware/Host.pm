package GLPI::Agent::SOAP::VMware::Host;

use strict;
use warnings;

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Virtualization;

sub new {
    my ($class, %params) = @_;

    my $self = {
        hash => $params{hash},
        vms  => $params{vms}
    };

    bless $self, $class;

    return $self;
}

sub _asArray {
    my $h = shift;

    return
        ref $h eq 'ARRAY' ? @$h  :
            $h            ? ($h) :
                            ()   ;
}

sub getBootTime {
    my ($self) = @_;

    return $self->{hash}[0]{summary}{runtime}{bootTime};
}

sub getHostname {
    my ($self) = @_;

    return $self->{hash}[0]{name}

}

sub getBiosInfo {
    my ($self) = @_;

    my $hardware   = $self->{hash}[0]{hardware};
    my $biosInfo   = $hardware->{biosInfo};
    my $systemInfo = $hardware->{systemInfo};

    return unless ref($biosInfo) eq 'HASH';

    my $bios = {
        BDATE         => $biosInfo->{releaseDate},
        BVERSION      => $biosInfo->{biosVersion},
        SMODEL        => $systemInfo->{model},
        SMANUFACTURER => $systemInfo->{vendor}
    };

    if (ref($systemInfo->{otherIdentifyingInfo}) eq 'HASH') {
        $bios->{ASSETTAG} = $systemInfo->{otherIdentifyingInfo}->{identifierValue};
    }
    elsif (ref($systemInfo->{otherIdentifyingInfo}) eq 'ARRAY') {
        foreach (@{$systemInfo->{otherIdentifyingInfo}}) {
            if ($_->{identifierType}->{key} eq 'ServiceTag') {
                # In the case we found more than one ServiceTag, assume there will be
                # only two, the first being the chassis S/N, the second the system S/N
                # This cover the case where the second is the lame board S/N
                # This works for ESXi 6.0 but no more for ESXi 6.5. In ESXi 6.5
                # before build-10884925, ServiceTag contains chassis/enclosure S/N
                # for at least Dell PowerEdge M6XX series. Since build-10884925,
                # ServiceTag contains system S/N and appears before EnclosureSerialNumberTag
                # and SerialNumberTag values.
                if ($bios->{SSN}) {
                    $bios->{MSN} = $bios->{SSN};
                }
                $bios->{SSN} = $_->{identifierValue};

            } elsif ($_->{identifierType}->{key} eq 'AssetTag') {
                $bios->{ASSETTAG} = $_->{identifierValue};

            # Since VMware ESXi 6.5, Patch Release ESXi650-201811002 (build-10884925),
            # enclosure and system serial numbers are availables
            } elsif ($_->{identifierType}->{key} eq 'EnclosureSerialNumberTag') {
                $bios->{MSN} = $_->{identifierValue};

            } elsif ($_->{identifierType}->{key} eq 'SerialNumberTag') {
                $bios->{SSN} = $_->{identifierValue};
            }
        }
    }

    return $bios;
}

sub getHardwareInfo {
    my ($self) = @_;

    my $dnsConfig  = $self->{hash}[0]{config}{network}{dnsConfig};
    my $hardware   = $self->{hash}[0]{hardware};
    my $summary    = $self->{hash}[0]{summary};
    my $systemInfo = $hardware->{systemInfo};

    return {
        NAME       => $dnsConfig->{hostName},
        DNS        => join('/', _asArray($dnsConfig->{address})),
        WORKGROUP  => $dnsConfig->{domainName},
        MEMORY     => int($hardware->{memorySize} / (1024 * 1024)),
        UUID       => $summary->{hardware}->{uuid} || $systemInfo->{uuid},
    };
}

sub getOperatingSystemInfo {
    my ($self) = @_;

    my $host = $self->{hash}->[0];

    my $dnsConfig  = $host->{config}->{network}->{dnsConfig};
    my $product    = $host->{summary}->{config}->{product};

    my ($bootdate, $boottime) =
        $host->{summary}->{runtime}->{bootTime} =~ /^([0-9-]+)T([0-9:]+)\./;
    $boottime = "$bootdate $boottime" if $bootdate && $boottime;

    my $os = {
        NAME       => $product->{name},
        VERSION    => $product->{version},
        FULL_NAME  => $product->{fullName},
        FQDN       => $host->{name},
        DNS_DOMAIN => $dnsConfig->{domainName},
        BOOT_TIME  => $boottime,
    };

    my $dtinfo = $host->{config}->{dateTimeInfo};
    if ($dtinfo && $dtinfo->{timeZone}) {
        my $offset = $dtinfo->{timeZone}->{gmtOffset};
        if (defined($offset)) {
            $os->{TIMEZONE}->{NAME} = $dtinfo->{timeZone}->{name};
            $offset /= 3600;
            $os->{TIMEZONE}->{OFFSET} = sprintf("%s%04d", $offset < 0 ? "-" : "+", abs($offset)*100);
        }
    }

    return $os;
}

sub getCPUs {
    my ($self) = @_;

    my %cpuManufacturor = (
        amd   => 'AMD',
        intel => 'Intel',
    );

    my $hardware    = $self->{hash}[0]{hardware};
    my $totalCore   = $hardware->{cpuInfo}{numCpuCores};
    my $totalThread = $hardware->{cpuInfo}{numCpuThreads};
    my $cpuEntries  = $hardware->{cpuPkg};
    my $cpuPackages = $hardware->{cpuInfo}{numCpuPackages} ||
        scalar(_asArray($cpuEntries));

    my @cpus;
    foreach (_asArray($cpuEntries)) {
        push @cpus,
          {
            CORE         => eval { $totalCore / $cpuPackages },
            MANUFACTURER => $cpuManufacturor{ $_->{vendor} } || $_->{vendor},
            NAME         => $_->{description},
            SPEED        => int( $_->{hz} / ( 1000 * 1000 ) ),
            THREAD       => eval { $totalThread / $totalCore }
          };
    }

    return @cpus;
}

sub getControllers {
    my ($self) = @_;

    my @controllers;

    foreach my $device ( @{ $self->{hash}[0]{hardware}{pciDevice} } ) {

        my $controller = {
            NAME           => $device->{deviceName},
            MANUFACTURER   => $device->{vendorName},
            PCICLASS       => substr(sprintf("%04x", $device->{classId}), -4),
            VENDORID       => substr(sprintf("%04x", $device->{vendorId}), -4),
            PRODUCTID      => substr(sprintf("%04x", $device->{deviceId}), -4),
            PCISLOT        => $device->{id},
        };

        if ($device->{subVendorId} || $device->{subDeviceId}) {
            $controller->{PCISUBSYSTEMID} = substr(sprintf("%04x", $device->{subVendorId}), -4).
                ":".substr(sprintf("%04x", $device->{subDeviceId}), -4);
        }

        push @controllers, $controller;
    }

    return @controllers;
}

sub _getNic {
    my ($ref, $isVirtual) = @_;

    my $nic = {
        DESCRIPTION => $ref->{device},
        DRIVER      => $ref->{driver},
        IPADDRESS   => $ref->{spec}{ip}{ipAddress},
        IPMASK      => $ref->{spec}{ip}{subnetMask},
        MACADDR     => $ref->{mac} || $ref->{spec}{mac},
        MTU         => $ref->{spec}{mtu},
        PCISLOT     => $ref->{pci},
        STATUS      => $ref->{spec}{ip}{ipAddress} ? 'Up' : 'Down',
        VIRTUALDEV  => $isVirtual,
        SPEED       => $ref->{spec}{linkSpeed}{speedMb},
    };

    # Clean up if not set
    map {
        delete $nic->{$_} unless $nic->{$_}
    } qw/IPADDRESS IPMASK/;

    return $nic;
}

sub getNetworks {
    my ($self) = @_;

    my @networks;

    my $seen = {};

    foreach my $nicType (qw/vnic pnic consoleVnic/)  {
        foreach (_asArray($self->{hash}[0]{config}{network}{$nicType}))
        {

            next if $seen->{$_->{device}}++;
            my $isVirtual = $nicType eq 'vnic'?1:0;
            push @networks, _getNic($_, $isVirtual);
        }
    }

    my @vnic;
    push @vnic, $self->{hash}[0]{config}{network}{consoleVnic}
        if $self->{hash}[0]{config}{network}{consoleVnic};
    push @vnic, $self->{hash}[0]{config}{vmotion}{netConfig}{candidateVnic}
        if $self->{hash}[0]{config}{vmotion}{netConfig}{candidateVnic};
    foreach my $entry (@vnic) {
        foreach (_asArray($entry)) {
            next if $seen->{$_->{device}}++;

            push @networks, _getNic($_, 1);
        }
    }

    return @networks;
}

sub getStorages {
    my ($self) = @_;

    my @storages;
    foreach my $entry (
        _asArray($self->{hash}[0]{config}{storageDevice}{scsiLun}))
    {
        my $serialnumber;
        my $size;

        # TODO
        #$volumnMapping{$entry->{canonicalName}} = $entry->{deviceName};

        foreach my $altName (_asArray($entry->{alternateName})) {
            next unless ref($altName) eq 'HASH';
            next unless $altName->{namespace};
            next unless $altName->{data};
            if ( $altName->{namespace} eq 'SERIALNUM' ) {
                $serialnumber .= $_ foreach ( @{ $altName->{data} } );
            }
        }
        if ( $entry->{capacity}{blockSize} && $entry->{capacity}{block} ) {
            $size = int(($entry->{capacity}{blockSize} *$entry->{capacity}{block})/1024/1024);
        }
        my $manufacturer;
        if ( $entry->{vendor} && ( $entry->{vendor} !~ /^\s*ATA\s*$/ ) ) {
            $manufacturer = $entry->{vendor};
        } else {
            $manufacturer = getCanonicalManufacturer( $entry->{model} );
        }

        $manufacturer =~ s/\s*(\S.*\S)\s*/$1/;

        my $model = $entry->{model};
        $model =~ s/\s*(\S.*\S)\s*/$1/;

        push @storages, {
            DESCRIPTION => $entry->{displayName},
            DISKSIZE    => $size,

            #        INTERFACE
            MANUFACTURER => $manufacturer,
            MODEL        => $model,
            NAME         => $entry->{deviceName},
            TYPE         => $entry->{deviceType},
            SERIAL       => $serialnumber,
            FIRMWARE     => $entry->{revision},

            #        SCSI_COID
            #        SCSI_CHID
            #        SCSI_UNID
            #        SCSI_LUN
        };

    }

    return @storages;

}

sub getDrives {
    my ($self) = @_;

    my @drives;

    foreach (
        _asArray($self->{hash}[0]{config}{fileSystemVolume}{mountInfo}))
    {
        my $volumn;
        if ( $_->{volume}{type} && ( $_->{volume}{type} =~ /NFS/i ) ) {
            $volumn = $_->{volume}{remoteHost} . ':' . $_->{volume}{remotePath};

# TODO
#        } else {
#            $volumn = $volumnMapping{$_->{volume}{extent}{diskName}}." ".$_->{volume}{extent}{partition};
        }
        push @drives,
          {
            SERIAL => $_->{volume}{uuid},
            TOTAL  => int( ( $_->{volume}{capacity} || 0 ) / ( 1000 * 1000 ) ),
            TYPE   => $_->{mountInfo}{path},
            VOLUMN => $volumn,
            LABEL  => $_->{volume}{name},
            FILESYSTEM => lc( $_->{volume}{type} )
          };
    }

    return @drives;
}

sub getVirtualMachines {
    my ($self) = @_;

    my @virtualMachines;

    foreach my $vm (@{$self->{vms}}) {
        my $machine = $vm->[0];
        my $status =
            $machine->{summary}{runtime}{powerState} eq 'poweredOn'  ? STATUS_RUNNING :
            $machine->{summary}{runtime}{powerState} eq 'poweredOff' ? STATUS_OFF     :
            $machine->{summary}{runtime}{powerState} eq 'suspended'  ? STATUS_PAUSED  :
                                                                       undef ;
        print "Unknown status (".$machine->{summary}{runtime}{powerState}.")\n" if !$status;

        my @mac;
        foreach my $device (_asArray($machine->{config}{hardware}{device})) {
            push @mac, $device->{macAddress} if $device->{macAddress};
        }

        my $comment = $machine->{config}{annotation};

        # hack to preserve  annotation / comment formating
        $comment =~ s/\n/&#10;/gm if $comment;

        if (
            defined($_->[0]{summary}{config}{template})
            &&
            $_->[0]{summary}{config}{template} eq 'true'
            ) {
            next;
        }

        # Compute serialnumber set in bios by ESX
        my @uuid_parts = unpack("A2A2A2A2xA2A2xA2A2xA2A2xA2A2A2A2A2A2", $machine->{summary}{config}{uuid});
        my $serial = "VMware-".join(' ', @uuid_parts[0..7]).'-'.join(' ', @uuid_parts[8..15]);

        push @virtualMachines,
          {
            NAME    => $machine->{name},
            STATUS  => $status,
            UUID    => $machine->{summary}{config}{uuid},
            SERIAL  => $serial,
            MEMORY  => $machine->{summary}{config}{memorySizeMB},
            VMTYPE  => 'VMware',
            VCPU    => $machine->{summary}{config}{numCpu},
            MAC     => join( '/', @mac ),
            COMMENT => $comment
          };
    }

    return @virtualMachines;
}

1;

__END__

=head1 NAME

GLPI::Agent::SOAP::VMware::Host - VMware Host abstraction layer

=head1 DESCRIPTION

The module is an abstraction layer to access the VMware host.

=head1 FUNCTIONS

=head2 new($class, %params)

Returns an object.

=head2 getBootTime( $self )

Returns the date in the following format: 2012-12-31T12:59:59

=head2 getHostname( $self )

Returns the host name.

=head2 getBiosInfo( $self )

Returns the BIOS (BDATE, BVERSION, SMODEL, SMANUFACTURER, ASSETTAG, SSN)
information in an HASH reference.

=head2 getHardwareInfo( $self )

Returns hardware information in a hash reference.

=head2 getCPUs( $self )

Returns CPU information (hash ref) in an array.

=head2 getControllers( $self )

Returns PCI controller information (hash ref) in an
array.

=head2 getNetworks( $self )

Returns the networks configuration in an array.


=head2 getStorages( $self )

Returns the storage devices in an array.

=head2 getDrives( $self )

Returns the hard drive partitions in an array.

=head2 getVirtualMachines( $self )

Retuns the Virtual Machines in an array.
