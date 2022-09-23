#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';
use File::Temp qw(tempdir);
use UNIVERSAL::require;
use Config;

use Test::Exception;
use Test::More;
use Test::MockModule;
use Test::Deep qw(cmp_deeply);

use GLPI::Agent::Logger;
use GLPI::Agent::Config;
use GLPI::Agent::Target::Server;
use GLPI::Agent::HTTP::Client::OCS;
use GLPI::Agent::XML::Query::Prolog;

use GLPI::Agent::Version;
use GLPI::Agent::Task::NetInventory::Version;

our $VERSION = $GLPI::Agent::Version::VERSION;
our $TASKVERSION = GLPI::Agent::Task::NetInventory::Version::VERSION;

# check thread support availability
if (!$Config{usethreads} || $Config{usethreads} ne 'define') {
    plan skip_all => 'thread support required';
}

GLPI::Agent::Task::NetInventory->use();

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

my %responses = (
    # Any protocol common case
    no_netinventory_case => {
        cmp     => {
            jobs    => 0,
            devices => [],
            lastlog => qr/NetInventory task execution not requested/
        },
        PROLOG  =>
'<?xml version="1.0" encoding="UTF-8"?>
<REPLY>
    <OPTION>
        <NAME>NETDISCOVERY</NAME>
        <PARAM THREADS_DISCOVERY="20" TIMEOUT="0" PID="98028"/>
        <RANGEIP ID="7" IPSTART="10.0.0.1" IPEND="10.0.0.100" ENTITY="0"/>
        <AUTHENTICATION ID="3" VERSION="2c" COMMUNITY="toto"/>
   </OPTION>
    <RESPONSE>SEND</RESPONSE>
    <PROLOG_FREQ>12</PROLOG_FREQ>
</REPLY>
'
    },
    netinventory_without_device_case => {
        cmp     => {
            jobs    => 0,
            devices => [],
            lastlog => qr/no valid job found, aborting/
        },
        PROLOG  =>
'<?xml version="1.0" encoding="UTF-8"?>
<REPLY>
    <OPTION>
        <NAME>SNMPQUERY</NAME>
        <PARAM THREADS_DISCOVERY="20" TIMEOUT="0"/>
        <AUTHENTICATION ID="1" VERSION="1" COMMUNITY="public"/>
        <AUTHENTICATION ID="2" VERSION="2c" COMMUNITY="public"/>
        <AUTHENTICATION ID="3" VERSION="2c" COMMUNITY="toto"/>
   </OPTION>
    <RESPONSE>SEND</RESPONSE>
    <PROLOG_FREQ>12</PROLOG_FREQ>
</REPLY>
'
    },
    netinventory_no_ip_device_case => {
        cmp     => {
            jobs    => 0,
            devices => [],
            lastlog => qr/no valid job found, aborting/
        },
        PROLOG  =>
'<?xml version="1.0" encoding="UTF-8"?>
<REPLY>
    <OPTION>
        <NAME>SNMPQUERY</NAME>
        <PARAM THREADS_QUERY="20" TIMEOUT="0"/>
        <DEVICE TYPE="NETWORKING" ID="86" AUTHSNMP_ID="3"/>
        <AUTHENTICATION ID="1" VERSION="1" COMMUNITY="public"/>
    </OPTION>
    <RESPONSE>SEND</RESPONSE>
    <PROLOG_FREQ>12</PROLOG_FREQ>
</REPLY>
'
    },
    # protocol_v2 cases
    normal_v2_case => {
        cmp     => {
            jobs    => 2,
            devices => [ 1, 1 ],
            lastlog => qr/All netinventory threads terminated/
        },
        PROLOG  =>
'<?xml version="1.0" encoding="UTF-8"?>
<REPLY>
    <OPTION>
        <NAME>SNMPQUERY</NAME>
        <PARAM THREADS_QUERY="20" TIMEOUT="0" PID="98030"/>
        <DEVICE TYPE="NETWORKING" ID="86" IP="10.0.0.1" AUTHSNMP_ID="3" FILE="resources/walks/sample1.walk" />
        <AUTHENTICATION ID="1" VERSION="1" COMMUNITY="public"/>
        <AUTHENTICATION ID="2" VERSION="2c" COMMUNITY="public"/>
        <AUTHENTICATION ID="3" VERSION="2c" COMMUNITY="toto"/>
    </OPTION>
    <OPTION>
        <NAME>SNMPQUERY</NAME>
        <PARAM THREADS_QUERY="20" TIMEOUT="0" PID="98031"/>
        <DEVICE TYPE="NETWORKING" ID="84" IP="10.0.0.2" AUTHSNMP_ID="3" FILE="resources/walks/sample2.walk" />
        <AUTHENTICATION ID="1" VERSION="1" COMMUNITY="public"/>
        <AUTHENTICATION ID="2" VERSION="2c" COMMUNITY="public"/>
        <AUTHENTICATION ID="3" VERSION="2c" COMMUNITY="toto"/>
    </OPTION>
    <RESPONSE>SEND</RESPONSE>
    <PROLOG_FREQ>12</PROLOG_FREQ>
</REPLY>
',
        SNMPQUERY   => [
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <AGENT>
      <AGENTVERSION>'.$VERSION.'</AGENTVERSION>
      <START>1</START>
    </AGENT>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98030</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>normal_v2_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
',
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <DEVICE>
      <INFO>
        <ID>86</ID>
        <LOCATION>datacenter</LOCATION>
        <NAME>oyapock CR2</NAME>
        <TYPE>NETWORKING</TYPE>
      </INFO>
    </DEVICE>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98030</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>normal_v2_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
',
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <AGENT>
      <END>1</END>
    </AGENT>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98030</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>normal_v2_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
',
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <AGENT>
      <END>1</END>
    </AGENT>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98030</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>normal_v2_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
',
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <AGENT>
      <AGENTVERSION>'.$VERSION.'</AGENTVERSION>
      <START>1</START>
    </AGENT>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98031</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>normal_v2_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
',
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <DEVICE>
      <INFO>
        <COMMENTS>RICOH Aficio MP 171 1.00.1 / RICOH Network Printer C model / RICOH Network Scanner C model / RICOH Network Facsimile C model</COMMENTS>
        <ID>84</ID>
        <LOCATION>C0172</LOCATION>
        <MANUFACTURER>Ricoh</MANUFACTURER>
        <NAME>Aficio MP 171</NAME>
        <TYPE>NETWORKING</TYPE>
      </INFO>
    </DEVICE>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98031</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>normal_v2_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
',
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <AGENT>
      <END>1</END>
    </AGENT>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98031</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>normal_v2_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
',
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <AGENT>
      <END>1</END>
    </AGENT>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98031</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>normal_v2_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
'
        ]
    },
    error_v2_case => {
        cmp     => {
            jobs    => 1,
            devices => [ 1 ],
            lastlog => qr/All netinventory threads terminated/
        },
        PROLOG  =>
'<?xml version="1.0" encoding="UTF-8"?>
<REPLY>
    <OPTION>
        <NAME>SNMPQUERY</NAME>
        <PARAM THREADS_QUERY="20" TIMEOUT="0" PID="98030"/>
        <DEVICE TYPE="NETWORKING" ID="86" IP="10.0.0.1" AUTHSNMP_ID="3" FILE="xxx" />
        <AUTHENTICATION ID="1" VERSION="1" COMMUNITY="public"/>
    </OPTION>
    <RESPONSE>SEND</RESPONSE>
    <PROLOG_FREQ>12</PROLOG_FREQ>
</REPLY>
',
        SNMPQUERY   => [
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <AGENT>
      <AGENTVERSION>'.$VERSION.'</AGENTVERSION>
      <START>1</START>
    </AGENT>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98030</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>error_v2_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
',
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <DEVICE>
      <ERROR>
        <ID>86</ID>
        <MESSAGE>SNMP emulation error: non-existing file \'xxx\'</MESSAGE>
        <TYPE>NETWORKING</TYPE>
      </ERROR>
    </DEVICE>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98030</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>error_v2_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
',
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <AGENT>
      <END>1</END>
    </AGENT>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98030</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>error_v2_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
',
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <AGENT>
      <END>1</END>
    </AGENT>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98030</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>error_v2_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
'
        ]
    },
    # protocol_v3 cases
    normal_v3_case => {
        cmp     => {
            jobs    => 2,
            devices => [ 2, 1 ],
            lastlog => qr/All netinventory threads terminated/
        },
        PROLOG  =>
'<?xml version="1.0" encoding="UTF-8"?>
<REPLY>
    <OPTION>
        <NAME>SNMPQUERY</NAME>
        <PARAM THREADS_QUERY="1" TIMEOUT="0"/>
        <DEVICE TYPE="NETWORKING" PID="98030" ID="86" IP="10.0.0.1" AUTHSNMP_ID="3" FILE="resources/walks/sample1.walk" />
        <DEVICE TYPE="NETWORKING" PID="98031" ID="84" IP="10.0.0.2" AUTHSNMP_ID="3" FILE="resources/walks/sample2.walk" />
        <AUTHENTICATION ID="1" VERSION="1" COMMUNITY="public"/>
        <AUTHENTICATION ID="2" VERSION="2c" COMMUNITY="public"/>
        <AUTHENTICATION ID="3" VERSION="2c" COMMUNITY="toto"/>
    </OPTION>
    <OPTION>
        <NAME>SNMPQUERY</NAME>
        <PARAM THREADS_QUERY="20" TIMEOUT="0"/>
        <DEVICE TYPE="NETWORKING" PID="98032" ID="84" IP="10.0.10.1" AUTHSNMP_ID="3" FILE="resources/walks/sample3.walk" />
        <AUTHENTICATION ID="1" VERSION="1" COMMUNITY="public"/>
        <AUTHENTICATION ID="2" VERSION="2c" COMMUNITY="public"/>
        <AUTHENTICATION ID="3" VERSION="2c" COMMUNITY="toto"/>
    </OPTION>
    <RESPONSE>SEND</RESPONSE>
    <PROLOG_FREQ>12</PROLOG_FREQ>
</REPLY>
',
        SNMPQUERY   => [
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <DEVICE>
      <INFO>
        <ID>86</ID>
        <LOCATION>datacenter</LOCATION>
        <NAME>oyapock CR2</NAME>
        <TYPE>NETWORKING</TYPE>
      </INFO>
    </DEVICE>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98030</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>normal_v3_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
',
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <DEVICE>
      <INFO>
        <COMMENTS>RICOH Aficio MP 171 1.00.1 / RICOH Network Printer C model / RICOH Network Scanner C model / RICOH Network Facsimile C model</COMMENTS>
        <ID>84</ID>
        <LOCATION>C0172</LOCATION>
        <MANUFACTURER>Ricoh</MANUFACTURER>
        <NAME>Aficio MP 171</NAME>
        <TYPE>NETWORKING</TYPE>
      </INFO>
    </DEVICE>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98031</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>normal_v3_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
',
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <DEVICE>
      <INFO>
        <COMMENTS>EPSON Built-in 10Base-T/100Base-TX Print Server</COMMENTS>
        <ID>84</ID>
        <MANUFACTURER>Epson</MANUFACTURER>
        <NAME>AL-CX11-CF9D9F</NAME>
        <TYPE>NETWORKING</TYPE>
        <UPTIME>11 days, 20:03:20.32</UPTIME>
      </INFO>
      <PORTS>
        <PORT>
          <IFDESCR>AL-CX11 Hard Ver.1.00 Firm Ver.2.30</IFDESCR>
          <IFNAME>AL-CX11 Hard Ver.1.00 Firm Ver.2.30</IFNAME>
          <IFNUMBER>1</IFNUMBER>
        </PORT>
      </PORTS>
    </DEVICE>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98032</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>normal_v3_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
'
        ]
    },
    error_v3_case => {
        cmp     => {
            jobs    => 1,
            devices => [ 1 ],
            lastlog => qr/All netinventory threads terminated/
        },
        PROLOG  =>
'<?xml version="1.0" encoding="UTF-8"?>
<REPLY>
    <OPTION>
        <NAME>SNMPQUERY</NAME>
        <PARAM THREADS_QUERY="20" TIMEOUT="0"/>
        <DEVICE TYPE="NETWORKING" PID="98037" ID="84" IP="10.0.10.1" AUTHSNMP_ID="3" FILE="xxx" />
        <AUTHENTICATION ID="1" VERSION="1" COMMUNITY="public"/>
        <AUTHENTICATION ID="2" VERSION="2c" COMMUNITY="public"/>
        <AUTHENTICATION ID="3" VERSION="2c" COMMUNITY="toto"/>
    </OPTION>
    <RESPONSE>SEND</RESPONSE>
    <PROLOG_FREQ>12</PROLOG_FREQ>
</REPLY>
',
        SNMPQUERY   => [
'<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <DEVICE>
      <ERROR>
        <ID>84</ID>
        <MESSAGE>SNMP emulation error: non-existing file \'xxx\'</MESSAGE>
        <TYPE>NETWORKING</TYPE>
      </ERROR>
    </DEVICE>
    <MODULEVERSION>'.$TASKVERSION.'</MODULEVERSION>
    <PROCESSNUMBER>98037</PROCESSNUMBER>
  </CONTENT>
  <DEVICEID>error_v3_case</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
'
        ]
    },
);

my $plan_tests_count = 6 * keys(%responses);
foreach my $case (keys(%responses)) {
    $plan_tests_count += scalar(@{$responses{$case}->{SNMPQUERY}})
        if $responses{$case}->{SNMPQUERY};
}

plan tests => $plan_tests_count ;

my $queue = Thread::Queue->new();
my $tid = threads->tid();

my $client_module = Test::MockModule->new('GLPI::Agent::HTTP::Client::OCS');
$client_module->mock('send', sub {
    my ($self, %params) = @_;

    my $case = $params{message}->{h}->{DEVICEID}
        or die "\nNot a supported case\n";

    my $query = $params{message}->{h}->{QUERY}
        or die "\nNot a supported QUERY with $case case\n";

    my $response = $responses{$case}->{$query};
    die "\nNot response to unsupported $query query\n"
        unless defined($response);

    if (ref($response) eq 'ARRAY') {
        my $sent = $params{message}->getContent();
        my $message = shift @{$response}
            or die "\nUnexpected $query sent message:\n$sent\n";

        # Dirty hack: the test was working as messages was ordered thanks to not
        # working multi-threading algorithm. So try to compare messages while they
        # have the same length but we need to handle the case where many responses has
        # the same length and in that case, we better try to find it in the list
        my @matchs = grep { length($sent) == length($_) } @{$response};
        if (@matchs) {
            my $max = @{$response};
            my @others = ();
            while ($max-- && @matchs>1 ? $sent ne $message : length($sent) != length($message)) {
                push @others, $message;
                $message = shift @{$response};
            }
            unshift @{$response}, @others if @others;
        }

        # When received in another thread than test thread, keep %params to be
        # re-used for the same call later from the test thread
        if (threads->tid() != $tid) {
            $queue->enqueue(\%params);
        } else {
            cmp_deeply($sent, $message, "Sent $query message");
        }
    }

    return $query eq 'PROLOG' ?
        GLPI::Agent::XML::Response->new( content => $response ) :
        $response;
});

foreach my $case (keys(%responses)) {

    my $client;

    lives_ok {
        $client = GLPI::Agent::HTTP::Client::OCS->new( logger  => $logger );
    } "$case: HTTP Client object instanciation" ;

    my $response;
    lives_ok {
        $response = $client->send(
            url     => $target->getUrl(),
            message => GLPI::Agent::XML::Query::Prolog->new( deviceid => $case )
        );
    } "$case PROLOG response";

    my $task;

    lives_ok {
        $task = GLPI::Agent::Task::NetInventory->new(
            target      => $target,
            logger      => $logger,
            config      => GLPI::Agent::Config->new(),
            datadir     => tempdir(CLEANUP => 1),
            deviceid    => $case
        );
    } "$case: NetInventory task object instanciation" ;

    $task->run() if $task->isEnabled($response);

    # "Re-send" in test thread calls from other threads, see client send() mock up
    while (my $sent = $queue->dequeue_nb()) {
        $client->send(%{$sent});
    }

    ok(
        @{ $task->{jobs} || [] } == $responses{$case}->{cmp}->{jobs},
        "$case: total jobs"
    );

    my @devices = map { $_->count() } @{$task->{jobs}};
    cmp_deeply(
        \@devices, $responses{$case}->{cmp}->{devices},
        "$case: devices by jobs"
    );

    # Check last log message
    my $message = $logger->{backends}->[0]->{message};
    ok(
        $message =~ $responses{$case}->{cmp}->{lastlog},
        "$case: last log message: $message"
    );
}
