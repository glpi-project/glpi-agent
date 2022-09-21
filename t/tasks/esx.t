#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use English qw(-no_match_vars);
use File::Temp qw(tempdir);
use LWP::UserAgent;

use Test::More;
use Test::Deep;
use Test::Exception;
use Test::MockObject::Extends;
use Test::MockModule;

use GLPI::Agent::Logger;
use GLPI::Agent::Inventory;
use GLPI::Agent::XML;
use GLPI::Agent::Target::Server;
use GLPI::Agent::Task::ESX;
use GLPI::Agent::Tools::Virtualization;

my %tests = (
    'esx-4.1.0-1' => {
        # same as json "versionclient" property to avoid false error testing as agent version evolves
        client      => "GLPI-Agent_v1.1",
        # deviceid matching the expected one
        deviceid    => "esx-test.teclib.local-2022-01-10-11-13-28"
    },
);

plan tests => (scalar keys %tests) * 7;

# Setup a target with a Test logger and debug
my $logger = GLPI::Agent::Logger->new(
    logger  => [ 'Test' ],
    debug   => 1
);

my $target = GLPI::Agent::Target::Server->new(
    url    => 'http://localhost/glpi-any',
    logger => $logger,
    basevardir => tempdir(CLEANUP => 1)
);

my $module   = Test::MockModule->new('LWP::UserAgent');
my $invlib   = Test::MockModule->new('GLPI::Agent::Inventory');

foreach my $test (keys %tests) {
    my $resource = "resources/esx/$test";

    # Clean log
    map { delete $_->{level}; delete $_->{message} } @{$logger->{backends}};

    # create mock user agent like in t/agent/soap.t
    my $ua   = LWP::UserAgent->new();
    my $mock = Test::MockObject::Extends->new($ua);
    $mock->mock(
        'request',
        sub {
            my ($self, $request) = @_;

            # compute SOAP dump file name
            my ($action) =
                $request->header('soapaction') =~ /"urn:vim25#(\S+)"/;

            my $tree = GLPI::Agent::XML->new(string => $request->content())->dump_as_hash();
            my $body = $tree->{'soapenv:Envelope'}->{'soapenv:Body'};
            my $obj  = $body->{RetrieveProperties}->{specSet}->{objectSet}->{obj};
            if ($obj->{'-type'} && $obj->{'-type'} eq 'VirtualMachine') {
                $action .= "-VM-$obj->{'#text'}";
            }
            my $file = $resource . "/" . $action . ".soap";

            local $INPUT_RECORD_SEPARATOR; # Set input to "slurp" mode.
            open(my $handle, '<', $file) or die "failed to open $file";
            my $content = <$handle>;
            close $handle;

            return HTTP::Response->new(
                200, 'OK', undef, $content
            );
        }
    );

    # ensure a calll to LWP::UserAgent->new() return our mock agent
    $module->mock(new => sub { return $mock; });

    # Mock deviceid to fix inventory with the expected one
    $invlib->mock(getDeviceId => sub { return $tests{$test}->{deviceid}; });

    # Tests start from here
    my $esx;
    lives_ok {
        $esx = GLPI::Agent::Task::ESX->new(
            logger  => $logger,
            target  => $target,
            config      => {},
            datadir     => tempdir(CLEANUP => 1),
            deviceid    => $test
        );
    } "$test: create esx task";

    lives_ok {
        $esx->connect(
                host     => $test,
                user     => 'foo',
                password => 'bar'
        )
    } "$test: connect esx";

    my $inventory;
    lives_ok {
        $inventory = $esx->createInventory(
            deviceid => $test,
            tag      => 'test'
        );
    } "$test: create inventory";

    lives_ok {
        $inventory->setFormat('json');
    } "$test: set json format";

    # Fix version client with the test one to avoid false positive while agent version is evolving
    $inventory->mergeContent({
        versionclient => $tests{$test}->{client}
    });

    my $content;
    lives_ok {
        $content = $inventory->getContent();
    } "$test: inventory get content";

    # No log expected while getting inventory content
    my ($log) = map { $_->{message} } @{$logger->{backends}};
    my ($level) = map { $_->{level} } @{$logger->{backends}};
    die "$test, $level log: $log\n" if $level;

    my $json;
    lives_ok {
        $json = $content->getContent();
    } "$test: inventory get json";

    # We can update expected json by setting DUMP_JSON environment variable in the
    # case format has evolved
    if ($ENV{DUMP_JSON}) {
        if (open my $fh, ">", "$resource.json") {
            print STDERR "Writing json into $resource.json...\n";
            print $fh $json;
            close($fh);
        }
    }

    die "$resource.json missing\n" unless -e "$resource.json";
    my $expected = GLPI::Agent::Protocol::Message->new(
        logger  => $logger,
        file    => "$resource.json"
    );

    cmp_deeply($content->get, $expected->get, "$test: expected message");
}
