package GLPI::Agent::Task::ESX;

use strict;
use warnings;
use parent 'GLPI::Agent::Task';

use UNIVERSAL::require;
use English qw(-no_match_vars);

use GLPI::Agent::Config;
use GLPI::Agent::HTTP::Client::Fusion;
use GLPI::Agent::Logger;
use GLPI::Agent::Inventory;
use GLPI::Agent::SOAP::VMware;
use GLPI::Agent::Tools;
use GLPI::Agent::Tools::UUID;

use GLPI::Agent::Task::ESX::Version;

our $VERSION = GLPI::Agent::Task::ESX::Version::VERSION;

sub isEnabled {
    my ($self) = @_;

    unless ($self->{target}->isType('server')) {
        $self->{logger}->debug("ESX task only compatible with server target");
        return;
    }

    return 1;
}

sub connect {
    my ( $self, %params ) = @_;

    my $url = 'https://' . $params{host} . '/sdk/vimService';

    my $vpbs = GLPI::Agent::SOAP::VMware->new(
        url     => $url,
        vcenter => 1,
        timeout => $self->timeout(),
    );
    if ( !$vpbs->connect( $params{user}, $params{password} ) ) {
        $self->lastError($vpbs->lastError() || "Connection failure");
        return;
    }

    $self->{vpbs} = $vpbs;
}

sub createInventory {
    my ( $self, $id, $tag, $deviceid ) = @_;

    die unless $self->{vpbs};

    my $vpbs = $self->{vpbs};

    my $host = $vpbs->getHostFullInfo($id);

    # Set known glpi version to enable or disable supported features
    my $glpi_version = $self->{target}->isType('server') ? $self->{target}->getTaskVersion('inventory') : '';
    $glpi_version = $self->{config}->{'glpi-version'} if empty($glpi_version);
    $host->enableFeaturesForGlpiVersion($glpi_version);

    my $inventory = GLPI::Agent::Inventory->new(
        datadir  => $self->{datadir},
        logger   => $self->{logger},
        glpi     => $glpi_version,
        tag      => $tag,
        itemtype => empty($self->{config}->{'esx-itemtype'}) ? "Computer" : $self->{config}->{'esx-itemtype'},
        # deviceid can be set and so reused from previous netscan
        deviceid => $deviceid
    );

    $inventory->setRemote('esx');

    $inventory->setBios( $host->getBiosInfo() );

    $inventory->setHardware( $host->getHardwareInfo() );

    # Add a virtual memory component to report total memory size for system. This remains
    # an extrapolated total size based on the reported available system memory size.
    my $memory = $inventory->getHardware("MEMORY");
    if ($memory) {
        $inventory->addEntry(
            section => 'MEMORIES',
            entry   => _esxTotalMemory($memory),
        );
    }

    $inventory->setOperatingSystem( $host->getOperatingSystemInfo() );

    foreach my $cpu ($host->getCPUs()) {
        $inventory->addEntry(section => 'CPUS', entry => $cpu);
    }

    foreach my $controller ($host->getControllers()) {
        $inventory->addEntry(section => 'CONTROLLERS', entry => $controller);

        if ($controller->{PCICLASS} && $controller->{PCICLASS} eq '300') {
            $inventory->addEntry(
                section => 'VIDEOS',
                entry   => {
                    NAME    => $controller->{NAME},
                    PCISLOT => $controller->{PCISLOT},
                }
            );
        }
    }

    my %ipaddr;
    foreach my $network ($host->getNetworks()) {
        $ipaddr{ $network->{IPADDRESS} } = 1 if $network->{IPADDRESS};
        $inventory->addEntry(section => 'NETWORKS', entry => $network);
    }

    # TODO
    #    foreach (@{$host->[0]{config}{fileSystemVolume}{mountInfo}}) {
    #
    #    }

    foreach my $storage ($host->getStorages()) {
        # TODO
        #        $volumnMapping{$entry->{canonicalName}} = $entry->{deviceName};
        $inventory->addEntry(section => 'STORAGES', entry => $storage);
    }

    foreach my $drive ($host->getDrives()) {
        $inventory->addEntry( section => 'DRIVES', entry => $drive);
    }

    foreach my $machine ($host->getVirtualMachines()) {
        $inventory->addEntry(section => 'VIRTUALMACHINES', entry => $machine);
    }

    return $inventory;

}

# Return a total size memory component with capacity rounded to the upper multiple of
# 1GB if size is lower than 16GB, 4GB for greater size but lower than 100GB and 16GB
# for even larger values. With $size given in MB.
sub _esxTotalMemory {
    my ($size) = @_;

    return unless $size && $size =~ /^\d+$/;

    my $base = $size < 16384 ? 1024 : $size >= 102400 ? 16384 : 4096;
    my $capacity = (int(int($size)/$base)+1) * $base;

    return {
        CAPACITY     => $capacity,
        CAPTION      => "ESX Guessed Total Memory",
        DESCRIPTION  => "ESX Memory",
        TYPE         => "Total",
        MANUFACTURER => "VMware",
        NUMSLOTS     => "0",
    };
}

sub getHostIds {
    my ($self) = @_;

    return $self->{vpbs}->getHostIds();
}

sub run {
    my ($self) = @_;

    # Just reset event if run as an event to not trigger another one
    $self->resetEvent();

    $self->{client} = GLPI::Agent::HTTP::Client::Fusion->new(
        logger  => $self->{logger},
        config  => $self->{config},
    );
    die unless $self->{client};

    my $globalRemoteConfig = $self->{client}->send(
        "url" => $self->{target}->{url},
        args  => {
            action    => "getConfig",
            machineid => $self->{deviceid},
            task      => { ESX => $VERSION },
        }
    );

    my $id = $self->{target}->id();
    if (!$globalRemoteConfig) {
        $self->{logger}->info("ESX task not supported by $id");
        return;
    }
    if (!$globalRemoteConfig->{schedule}) {
        $self->{logger}->info("No job schedule returned by $id");
        return;
    }
    if (ref( $globalRemoteConfig->{schedule} ) ne 'ARRAY') {
        $self->{logger}->info("Malformed schedule from server by $id");
        return;
    }
    if ( !@{$globalRemoteConfig->{schedule}} ) {
        $self->{logger}->info("No ESX job enabled or ESX support disabled server side.");
        return;
    }

    foreach my $job ( @{ $globalRemoteConfig->{schedule} } ) {
        next unless $job->{task} eq "ESX";
        $self->{esxRemote} = $job->{remote};
    }
    if ( !$self->{esxRemote} ) {
        $self->{logger}->info("No ESX job found in server jobs list.");
        return;
    }

    my $jobs = $self->{client}->send(
        "url" => $self->{esxRemote},
        args  => {
            action    => "getJobs",
            machineid => $self->{deviceid}
        }
    );

    return unless $jobs;
    return unless ref( $jobs->{jobs} ) eq 'ARRAY';
    my $plural = @{$jobs->{jobs}} > 1 ? "s" : "";
    $self->{logger}->info("Having to contact ".scalar(@{$jobs->{jobs}})." remote ESX server".$plural);

    foreach my $job ( @{ $jobs->{jobs} } ) {

        if ( !$self->connect(
                host     => $job->{host},
                user     => $job->{user},
                password => $job->{password}
        )) {
            $self->{client}->send(
                url   => $self->{esxRemote},
                args  => {
                    action => 'setLog',
                    machineid => $self->{deviceid},
                    part      => 'login',
                    uuid      => $job->{uuid},
                    msg       => $self->lastError(),
                    code      => 'ko'
                }
            );

            next;
        }

        $self->serverInventory();

        $self->{client}->send(
            url   => $self->{esxRemote},
            args  => $self->lastError ? {
                action => 'setLog',
                machineid => $self->{deviceid},
                part      => 'inventory',
                uuid      => $job->{uuid},
                msg       => $self->lastError(),
                code      => 'ko'
            } : {
                action => 'setLog',
                machineid => $self->{deviceid},
                uuid      => $job->{uuid},
                code      => 'ok'
            }
        );
    }

    return $self;
}

sub serverInventory {
    # $host_callback can be used to dump datas retrieved from ESX server as done by glpi-esx
    # and is only used for local target
    my ($self, $path, $host_callback, $deviceids) = @_;

    # Initialize GLPI server submission if required
    if ($self->{target}->isType('server') && !$self->{serverclient}) {
        if ($self->{target}->isGlpiServer()) {
            GLPI::Agent::HTTP::Client::GLPI->require();
            if ($EVAL_ERROR) {
                $self->lastError("GLPI Protocol library can't be loaded");
                return;
            }

            $self->{serverclient} = GLPI::Agent::HTTP::Client::GLPI->new(
                logger  => $self->{logger},
                config  => $self->{config},
                agentid => uuid_to_string($self->{agentid}),
            );

            GLPI::Agent::Protocol::Inventory->require();
            if ($EVAL_ERROR) {
                $self->lastError("Can't load GLPI Protocol Inventory library");
                return;
            }
        } else {
            # Deprecated XML based protocol
            GLPI::Agent::HTTP::Client::OCS->require();
            if ($EVAL_ERROR) {
                $self->lastError("OCS Protocol library can't be loaded");
                return;
            }

            $self->{serverclient} = GLPI::Agent::HTTP::Client::OCS->new(
                logger  => $self->{logger},
                config  => $self->{config},
            );

            GLPI::Agent::XML::Query::Inventory->require();
            if ($EVAL_ERROR) {
                $$self->lastError("XML::Query::Inventory library can't be loaded");
                return;
            }
        }
    }

    my $hostIds = $self->getHostIds();
    foreach my $hostId (@$hostIds) {
        my $deviceid;
        $deviceid = $deviceids->{$hostId} if ref($deviceids) eq 'HASH';
        my $inventory = $self->createInventory(
            $hostId, $self->{config}->{tag}, $deviceid
        );

        if ($self->{target}->isType('server')) {
            my $message;
            if ($self->{target}->isGlpiServer()) {
                $inventory->setFormat('json');
                $message = $inventory->getContent(
                    server_version => $self->{target}->getTaskVersion('inventory')
                );
            } else {
                # Deprecated XML based protocol
                $inventory->setFormat('xml');
                $message = GLPI::Agent::XML::Query::Inventory->new(
                    deviceid => $self->{deviceid},
                    content  => $inventory->getContent()
                );
            }

            $self->{serverclient}->send(
                url     => $self->{target}->getUrl(),
                message => $message
            );
        } elsif ($self->{target}->isType('local')) {
            $inventory->setFormat($self->{config}->{json} ? 'json' : 'xml');
            my $file = $inventory->save($path // $self->{target}->getPath());
            if ($file eq '-') {
                $self->{logger}->debug("Inventory dumped");
            } elsif (-e $file) {
                $self->{logger}->info("Inventory saved in $file");
            } else {
                $self->{logger}->error("Failed to save inventory in $file, aborting");
                $self->lastError("Can't save inventory file");
                last;
            }
            if (ref($host_callback) eq 'CODE') {
                # $devices is set when called by netscan to keep esx deviceid consistent
                # and don't duplicate inventory file when storing them
                if ($deviceids) {
                    &{$host_callback}($inventory, $hostId);
                } else {
                    &{$host_callback}($hostId, $file);
                }
            }
        }
    }
}

sub lastError {
    my ($self, $error) = @_;

    $self->{lastError} = $self->{esx}->lastError()
        if $self->{esx};

    $self->{lastError} = $error if $error;

    return $self->{lastError};
}

sub timeout {
    my ($self, $timeout) = @_;

    $self->{_timeout} = $timeout if defined($timeout);

    # Set http client timeout if required
    $self->{vpbs}->timeout($timeout) if $timeout && $self->{vpbs};

    return $self->{_timeout} || $self->{config}->{"backend-collect-timeout"} // 60;
}

1;

__END__

=head1 NAME

GLPI::Agent::SOAP::VMware - Access to VMware hypervisor

=head1 DESCRIPTION

This module allow access to VMware hypervisor using VMware SOAP API
and _WITHOUT_ their Perl library.

=head1 FUNCTIONS

=head2 connect ( $self, %params )

Connect the task to the VMware ESX, ESXi or vCenter.

=head2 createInventory ( $self, $id, $tag )

Returns an GLPI::Agent::Inventory object for a given
host id.

=head2 getHostIds

Returns the list of the host id.
