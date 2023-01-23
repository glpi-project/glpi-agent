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

    my $vpbs =
      GLPI::Agent::SOAP::VMware->new(url => $url, vcenter => 1 );
    if ( !$vpbs->connect( $params{user}, $params{password} ) ) {
        $self->lastError($vpbs->{lastError});
        return;
    }

    $self->{vpbs} = $vpbs;
}

sub createInventory {
    my ( $self, $id, $tag ) = @_;

    die unless $self->{vpbs};

    my $vpbs = $self->{vpbs};

    my $host = $vpbs->getHostFullInfo($id);

    my $inventory = GLPI::Agent::Inventory->new(
        logger => $self->{logger},
        tag    => $tag
    );

    $inventory->setRemote('esx');

    $inventory->setBios( $host->getBiosInfo() );

    $inventory->setHardware( $host->getHardwareInfo() );

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

sub getHostIds {
    my ($self) = @_;

    return $self->{vpbs}->getHostIds();
}

sub run {
    my ($self) = @_;

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

    my $serverclient;
    if ($self->{target}->isGlpiServer()) {
        GLPI::Agent::HTTP::Client::GLPI->require();
        return $self->{logger}->error("GLPI Protocol library can't be loaded")
            if $EVAL_ERROR;

        $serverclient = GLPI::Agent::HTTP::Client::GLPI->new(
            logger  => $self->{logger},
            config  => $self->{config},
            agentid => uuid_to_string($self->{agentid}),
        );

        return $self->{logger}->error("Can't load GLPI Protocol Inventory library")
            unless GLPI::Agent::Protocol::Inventory->require();
    } else {
        # Deprecated XML based protocol
        GLPI::Agent::HTTP::Client::OCS->require();
        return $self->{logger}->error("OCS Protocol library can't be loaded")
            if $EVAL_ERROR;

        $serverclient = GLPI::Agent::HTTP::Client::OCS->new(
            logger  => $self->{logger},
            config  => $self->{config},
        );

        GLPI::Agent::XML::Query::Inventory->require();
        return $self->{logger}->error("XML::Query::Inventory library can't be loaded")
            if $EVAL_ERROR;
    }

    foreach my $job ( @{ $jobs->{jobs} } ) {

        if ( !$self->connect(
                host     => $job->{host},
                user     => $job->{user},
                password => $job->{password}
        )) {
            $self->{client}->send(
                "url" => $self->{esxRemote},
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

        my $hostIds = $self->getHostIds();
        foreach my $hostId (@$hostIds) {
            my $inventory = $self->createInventory(
                $hostId, $self->{config}->{tag}
            );

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

            $serverclient->send(
                url     => $self->{target}->getUrl(),
                message => $message
            );
        }
        $self->{client}->send(
            "url" => $self->{esxRemote},
            args  => {
                action => 'setLog',
                machineid => $self->{deviceid},
                uuid      => $job->{uuid},
                code      => 'ok'
            }
        );

    }

    return $self;
}

sub lastError {
    my ($self, $error) = @_;

    $self->{lastError} = $error if $error;

    return $self->{lastError} || "n/a";
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
