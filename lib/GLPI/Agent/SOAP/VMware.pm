package GLPI::Agent::SOAP::VMware;

use strict;
use warnings;

use English qw(-no_match_vars);
use LWP::UserAgent;
use HTTP::Cookies;

use GLPI::Agent;
use GLPI::Agent::XML;
use GLPI::Agent::SOAP::VMware::Host;

sub new {
    my ($class, %params) = @_;

    my $self = {
        url  => $params{url},
        _xml => GLPI::Agent::XML->new(
            force_array => [ qw(returnval propSet) ],
            skip_attr   => 1, # Skip attributes while dumping as hash
        ),
    };
    bless $self, $class;

    # create user agent
    $self->{ua} = LWP::UserAgent->new(
        requests_redirectable => ['POST', 'GET', 'HEAD'],
        agent                 => $GLPI::Agent::AGENT_STRING,
        timeout               => $params{timeout} || 180,
        ssl_opts              => { verify_hostname => 0, SSL_verify_mode => 0 },
        cookie_jar            => HTTP::Cookies->new(ignore_discard => 1),
    );

    return $self;
}

sub _send {
    my ( $self, $action, $xmlToSend ) = @_;

    my $req = HTTP::Request->new( POST => $self->{url} );
    $req->content($xmlToSend);
    $req->{_headers}->{soapaction}       = "\"urn:vim25#" . $action . "\"";
    $req->{_headers}->{accept}           = [ 'text/xml', 'application/soap' ];
    $req->{_headers}->{'content-length'} = length($xmlToSend);
    $req->{_protocol}                    = 'HTTP/1.1';
    $req->content_type('text/xml; charset=utf-8');

    my $res = $self->{ua}->request($req);

    if ( $res->is_success ) {
        return $res->content;
    } else {
        my $err = $res->content;
        my $tmpRef;

        if ($err =~ m{(<faultstring>.*</faultstring>)}sg) {
            $tmpRef = $self->{_xml}->string($1)->dump_as_hash();
        }

        my $errorString = $res->status_line;
        if ( $tmpRef && $tmpRef->{faultstring} ) {
            $errorString .= ": " . $tmpRef->{faultstring};
        }
        $self->{lastError} = $errorString;
        return;
    }

    return 1;
}

sub _parseAnswer {
    my ($self, $answer) = @_;

    return unless $answer;

    my $dump = $self->{_xml}->string($answer)->dump_as_hash()
        or return;

    return unless exists($dump->{'soapenv:Envelope'}->{'soapenv:Body'});

    my $body = $dump->{'soapenv:Envelope'}->{'soapenv:Body'};

    my ($bodyKey) = keys(%{$body});
    return unless exists($body->{$bodyKey}->{'returnval'});

    my $returnval = $body->{$bodyKey}->{'returnval'};
    return unless ref($returnval) eq 'ARRAY';

    my $ref = [];
    foreach my $val (@{$returnval}) {
        if (ref($val->{propSet}) eq 'ARRAY') {
            my %tmp;
            foreach my $p (@{$val->{propSet}}) {
                next unless $p->{name} && defined $p->{val};
                $tmp{$p->{name}} = $p->{val};
            }
            push @{$ref}, \%tmp;
        } else {
            push @{$ref}, $val;
        }
    }

    return $ref;

}

sub connect {
    my ( $self, $user, $password ) = @_;

    unless ($user) {
        $self->{lastError} = "No user".($self->{lastError} ? "" : " and password").
            " provided for ESX connection";
        return;
    }

    unless ($password) {
        $self->{lastError} = "No password provided for ESX connection";
        return;
    }

    my $req = '<?xml version="1.0" encoding="UTF-8"?>
   <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
   <soapenv:Body>
<RetrieveServiceContent xmlns="urn:vim25"><_this type="ServiceInstance">ServiceInstance</_this>
</RetrieveServiceContent></soapenv:Body></soapenv:Envelope>';

    my $answer = $self->_send( 'ServiceInstance', $req );
    return unless $answer;

    my $serviceInstance = $self->_parseAnswer($answer);
    return unless $serviceInstance;

    if ( $serviceInstance->[0]{about}{apiType} eq 'VirtualCenter' ) {
        $self->{vcenter}           = 1;                     # TODO
        $self->{sessionManager}    = "SessionManager";
        $self->{propertyCollector} = "propertyCollector";
    } else {
        $self->{vcenter}           = 0;
        $self->{sessionManager}    = "ha-sessionmgr";
        $self->{propertyCollector} = "ha-property-collector";
    }

    $req = '<?xml version="1.0" encoding="UTF-8"?>
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <soapenv:Body>
        <Login xmlns="urn:vim25"><_this type="SessionManager">%s</_this>
        <userName>%s</userName><password>%s</password></Login></soapenv:Body></soapenv:Envelope>';

    $answer = $self->_send(
        'Login',
        sprintf( $req, $self->{sessionManager}, $user, $password )
    );
    return unless $answer;
    return if $answer =~ /ServerFaultCode/m;

    return $self->_parseAnswer($answer);
}

#sub getHostInfo {
#    my ($self) = @_;
#
#
#    my $req =
#        '<?xml version="1.0" encoding="UTF-8"?><soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><RetrieveServiceContent xmlns="urn:vim25"><_this type="ServiceInstance">ServiceInstance</_this></RetrieveServiceContent></soap:Body></soap:Envelope>';
#
#
#    my $answer = $self->_send('RetrieveServiceContent', 'RetrieveServiceContent', $req);
#    my $ref = $self->_parseAnswer($answer);
#
#    return $host;
#}

sub _getVirtualMachineList {
    my ($self) = @_;

    my $req =

      '<?xml version="1.0" encoding="UTF-8"?>
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <soapenv:Body>
        <RetrieveProperties xmlns="urn:vim25"><_this type="PropertyCollector">ha-property-collector</_this>
        <specSet><propSet><type>VirtualMachine</type><all>0</all></propSet><objectSet><obj type="Folder">ha-folder-root</obj>
        <skip>0</skip><selectSet xsi:type="TraversalSpec"><name>folderTraversalSpec</name><type>Folder</type><path>childEntity</path><skip>0</skip><selectSet><name>folderTraversalSpec</name></selectSet><selectSet><name>datacenterHostTraversalSpec</name></selectSet><selectSet><name>datacenterVmTraversalSpec</name></selectSet><selectSet><name>datacenterDatastoreTraversalSpec</name></selectSet><selectSet><name>datacenterNetworkTraversalSpec</name></selectSet><selectSet><name>computeResourceRpTraversalSpec</name></selectSet><selectSet><name>computeResourceHostTraversalSpec</name></selectSet><selectSet><name>hostVmTraversalSpec</name></selectSet><selectSet><name>resourcePoolVmTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>datacenterDatastoreTraversalSpec</name><type>Datacenter</type><path>datastoreFolder</path><skip>0</skip><selectSet><name>folderTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>datacenterNetworkTraversalSpec</name><type>Datacenter</type><path>networkFolder</path><skip>0</skip><selectSet><name>folderTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>datacenterVmTraversalSpec</name><type>Datacenter</type><path>vmFolder</path><skip>0</skip><selectSet><name>folderTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>datacenterHostTraversalSpec</name><type>Datacenter</type><path>hostFolder</path><skip>0</skip><selectSet><name>folderTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>computeResourceHostTraversalSpec</name><type>ComputeResource</type><path>host</path><skip>0</skip></selectSet><selectSet xsi:type="TraversalSpec"><name>computeResourceRpTraversalSpec</name><type>ComputeResource</type><path>resourcePool</path><skip>0</skip><selectSet><name>resourcePoolTraversalSpec</name></selectSet><selectSet><name>resourcePoolVmTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>resourcePoolTraversalSpec</name><type>ResourcePool</type><path>resourcePool</path><skip>0</skip><selectSet><name>resourcePoolTraversalSpec</name></selectSet><selectSet><name>resourcePoolVmTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>hostVmTraversalSpec</name><type>HostSystem</type><path>vm</path><skip>0</skip><selectSet><name>folderTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>resourcePoolVmTraversalSpec</name><type>ResourcePool</type><path>vm</path><skip>0</skip></selectSet></objectSet></specSet></RetrieveProperties></soapenv:Body></soapenv:Envelope>
        ';

    my $answer = $self->_send(
        'RetrievePropertiesVMList',
        $req
    );
    my $ref = $self->_parseAnswer($answer);
    my @list;
    if (ref($ref) eq 'HASH') {
        push @list, $ref;
    }
    elsif (ref($ref) eq 'ARRAY') {
        @list = @{$ref};
    }

    my @ids;
    foreach (@list) {
        push @ids, $_->{obj};
    }

    return \@ids;

}

sub _getVirtualMachineById {
    my ( $self, $id ) = @_;

    my $req = '<?xml version="1.0" encoding="UTF-8"?>
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <soapenv:Body>
        <RetrieveProperties xmlns="urn:vim25"><_this type="PropertyCollector">%s</_this>
        <specSet><propSet><type>VirtualMachine</type><all>1</all></propSet><objectSet><obj type="VirtualMachine">%s</obj>
        </objectSet></specSet></RetrieveProperties></soapenv:Body></soapenv:Envelope>
        ';

    my $answer = $self->_send(
        'RetrieveProperties',
        sprintf( $req, $self->{propertyCollector}, $id )
    );
    return [] unless $answer;

    return $self->_parseAnswer($answer) // [];
}

sub getHostFullInfo {
    my ( $self, $id ) = @_;

    $id = 'ha-host' unless $id;

    my $req = '<?xml version="1.0" encoding="UTF-8"?>
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <soapenv:Body>
        <RetrieveProperties xmlns="urn:vim25"><_this type="PropertyCollector">%s</_this>
        <specSet><propSet><type>HostSystem</type><all>1</all></propSet><objectSet><obj type="HostSystem">%s</obj>
        </objectSet></specSet></RetrieveProperties></soapenv:Body></soapenv:Envelope>
        ';

    my $answer = $self->_send(
        'RetrieveProperties',
        sprintf( $req, $self->{propertyCollector}, $id )
    );
    my $ref = $self->_parseAnswer($answer) // [];
    my $vms = [];
    my $machineIdList;
    my $vm = ref($ref) eq 'ARRAY' && @{$ref} && ref($ref->[0]) eq 'HASH' && exists($ref->[0]{vm}) ? $ref->[0]{vm} : "";
    # $vm can be an empty string for vCenter 7
    if (ref($vm) eq 'HASH' && exists($vm->{ManagedObjectReference})) {    # ESX 3.5
        if (ref($vm->{ManagedObjectReference}) eq 'ARRAY') {
            $machineIdList = $vm->{ManagedObjectReference};
        } else {
            push @$machineIdList, $vm->{ManagedObjectReference};
        }
    } else {
        $machineIdList = $self->_getVirtualMachineList();
    }

    foreach my $id (@$machineIdList) {
        push @$vms, $self->_getVirtualMachineById($id);
    }

    my $host = GLPI::Agent::SOAP::VMware::Host->new(
        hash => $ref, vms => $vms
    );
    return $host;
}

sub getHostIds {
    my ($self) = @_;

    if ( !$self->{vcenter} ) {
        return ['ha-host'];
    }

    my $req = '<?xml version="1.0" encoding="UTF-8"?>
   <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
   <soapenv:Body>
<RetrieveProperties xmlns="urn:vim25"><_this type="PropertyCollector">propertyCollector</_this>
<specSet><propSet><type>HostSystem</type><all>0</all></propSet><objectSet><obj type="Folder">group-d1</obj>
<skip>0</skip><selectSet xsi:type="TraversalSpec"><name>folderTraversalSpec</name><type>Folder</type><path>childEntity</path><skip>0</skip><selectSet><name>folderTraversalSpec</name></selectSet><selectSet><name>datacenterHostTraversalSpec</name></selectSet><selectSet><name>datacenterVmTraversalSpec</name></selectSet><selectSet><name>datacenterDatastoreTraversalSpec</name></selectSet><selectSet><name>datacenterNetworkTraversalSpec</name></selectSet><selectSet><name>computeResourceRpTraversalSpec</name></selectSet><selectSet><name>computeResourceHostTraversalSpec</name></selectSet><selectSet><name>hostVmTraversalSpec</name></selectSet><selectSet><name>resourcePoolVmTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>datacenterDatastoreTraversalSpec</name><type>Datacenter</type><path>datastoreFolder</path><skip>0</skip><selectSet><name>folderTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>datacenterNetworkTraversalSpec</name><type>Datacenter</type><path>networkFolder</path><skip>0</skip><selectSet><name>folderTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>datacenterVmTraversalSpec</name><type>Datacenter</type><path>vmFolder</path><skip>0</skip><selectSet><name>folderTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>datacenterHostTraversalSpec</name><type>Datacenter</type><path>hostFolder</path><skip>0</skip><selectSet><name>folderTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>computeResourceHostTraversalSpec</name><type>ComputeResource</type><path>host</path><skip>0</skip></selectSet><selectSet xsi:type="TraversalSpec"><name>computeResourceRpTraversalSpec</name><type>ComputeResource</type><path>resourcePool</path><skip>0</skip><selectSet><name>resourcePoolTraversalSpec</name></selectSet><selectSet><name>resourcePoolVmTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>resourcePoolTraversalSpec</name><type>ResourcePool</type><path>resourcePool</path><skip>0</skip><selectSet><name>resourcePoolTraversalSpec</name></selectSet><selectSet><name>resourcePoolVmTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>hostVmTraversalSpec</name><type>HostSystem</type><path>vm</path><skip>0</skip><selectSet><name>folderTraversalSpec</name></selectSet></selectSet><selectSet xsi:type="TraversalSpec"><name>resourcePoolVmTraversalSpec</name><type>ResourcePool</type><path>vm</path><skip>0</skip></selectSet></objectSet></specSet></RetrieveProperties></soapenv:Body></soapenv:Envelope>';

    my $answer = $self->_send('RetrieveProperties', sprintf($req) );
    my $ref = $self->_parseAnswer($answer) // [];

    my @ids;
    foreach (@$ref) {
        push @ids, $_->{obj};
    }

    return \@ids;
}

1;

__END__

=head1 NAME

GLPI::Agent::SOAP::VMware - Access to VMware hypervisor

=head1 DESCRIPTION

This module allow access to VMware hypervisor using VMware SOAP API
and _WITHOUT_ their Perl library.

=head1 METHODS

=head2 new(%params)

Returns a VMware object.

=head2 connect($user, $password)

Connect the VMware object with the given credentials.

=head2 getHostFullInfo($id)

Returns a large hash structure with the host information.

=head2 getHostIds()

Returns the list of the virtual machine ID in an array reference.
