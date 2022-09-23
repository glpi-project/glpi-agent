#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use GLPI::Agent::XML::Query;

# each item is an arrayref of three elements:
# - input data structure
# - expected xml output
# - test explication
my @tests = (
    [
        {
            PORTS => {
                PORT => [
                    {
                        CONNECTIONS => {
                            CONNECTION => {
                                MAC => [
                                    '00:00:74:D2:09:6A',
                                ]
                            }
                        }
                    },
                ]
            }
        },
        <<EOF,
<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <PORTS>
      <PORT>
        <CONNECTIONS>
          <CONNECTION>
            <MAC>00:00:74:D2:09:6A</MAC>
          </CONNECTION>
        </CONNECTIONS>
      </PORT>
    </PORTS>
  </CONTENT>
  <DEVICEID>foobar</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
EOF
        'single mac address'
    ],
    [
        {
            PORTS => {
                PORT => [
                    {
                        CONNECTIONS => {
                            CONNECTION => {
                                MAC => [
                                    '00:00:74:D2:09:6A',
                                    '00:00:74:D2:09:6B'
                                ]
                            }
                        }
                    },
                ]
            }
        },
        <<EOF,
<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <PORTS>
      <PORT>
        <CONNECTIONS>
          <CONNECTION>
            <MAC>00:00:74:D2:09:6A</MAC>
            <MAC>00:00:74:D2:09:6B</MAC>
          </CONNECTION>
        </CONNECTIONS>
      </PORT>
    </PORTS>
  </CONTENT>
  <DEVICEID>foobar</DEVICEID>
  <QUERY>SNMPQUERY</QUERY>
</REQUEST>
EOF
        'multiple mac addresses'
    ],
);

plan tests => scalar @tests;

foreach my $test (@tests) {
    my $message = GLPI::Agent::XML::Query->new(
       deviceid => 'foobar',
       query    => 'SNMPQUERY',
       content  => $test->[0]
    );
    is($message->getContent(), $test->[1], $test->[2]);
}
