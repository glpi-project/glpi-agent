#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use Test::Deep qw(cmp_deeply);
use Test::Exception;
use Test::More;
use Test::NoWarnings;
use File::Find;
use File::Temp qw(tempdir);
use UNIVERSAL::require;
use Encode qw(decode);

use GLPI::Agent::XML;
use GLPI::Agent::Tools;

my %xmls = (
    empty => {
        content => qq{},
        has_xml => 0,
        dump    => undef,
        xmltpp  => ''
    },
    invalid1 => {
        content => qq{<>},
        has_xml => 0,
        dump    => undef,
        xmltpp  => ''
    },
    invalid2 => {
        content => qq{          },
        has_xml => 0,
        dump    => undef,
        xmltpp  => ''
    },
    invalid3 => {
        content => qq{loremipsum},
        has_xml => 0,
        dump    => undef,
        xmltpp  => ''
    },
    invalid4 => {
        content => qq/{ "this_is_a_json": 1 }/,
        has_xml => 0,
        dump    => undef,
        xmltpp  => ''
    },
    root => {
        options => { no_xml_decl => 1, xml_format => 0 },
        content => qq{<rOOt/>},
        dump    => { rOOt => '' }
    },
    root2 => {
        options => { no_xml_decl => 1, xml_format => 0 },
        content => qq{<rOOt></rOOt>},
        dump    => { rOOt => '' },
        tag_compression => 1 # To set XML::LibXML::Parser serializer option
    },
    root3 => {
        options => { xml_format => 0 },
        content => qq{<?xml version="1.0" encoding="UTF-8"?>
<rOOt/>
},
        dump    => { rOOt => '' }
    },
    root4 => {
        options => { format => 0 },
        content => qq{<?xml version="1.0" encoding="UTF-8"?>
<rOOt></rOOt>
},
        dump    => { rOOt => '' },
        tag_compression => 1 # To set XML::LibXML::Parser serializer option
    },
    basic => {
        content => qq{<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <SOFTWARES>
      <NAME>foo</NAME>
      <VERSION>bàré</VERSION>
    </SOFTWARES>
  </CONTENT>
</REQUEST>
},
        dump => { REQUEST => { CONTENT => { SOFTWARES => { NAME => "foo", VERSION => "b\xe0r\xe9" } } } }
    },
    cdata => {
        options => { no_xml_decl => 1, xml_format => 0 },
        content => qq{<Condition Action="enable"><![CDATA[_EXECMODE_RADIO_BUTTON <> "1"]]></Condition>},
        dump    => {
            Condition => {
                '-Action'   => "enable",
                '#text'     => qq{_EXECMODE_RADIO_BUTTON <> "1"}
            }
        },
        write   => qq{<Condition Action="enable">_EXECMODE_RADIO_BUTTON &lt;&gt; "1"</Condition>},
    },
    array => {
        content => qq{<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <SOFTWARES>
      <NAME>foo</NAME>
      <VERSION>1.0</VERSION>
    </SOFTWARES>
    <SOFTWARES>
      <NAME>bar</NAME>
      <VERSION>2.0</VERSION>
    </SOFTWARES>
  </CONTENT>
</REQUEST>
},
        dump => { REQUEST => { CONTENT => { SOFTWARES => [
            { NAME => "foo", VERSION => "1.0" }, { NAME => "bar", VERSION => "2.0" }
        ] } } }
    },
    forced_array => {
        options => { force_array => [ qw(SOFTWARES) ] },
        content => qq{<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <SOFTWARES>
      <NAME>foo</NAME>
      <VERSION>bàré</VERSION>
    </SOFTWARES>
  </CONTENT>
</REQUEST>
},
        dump => { REQUEST => { CONTENT => { SOFTWARES => [ { NAME => "foo", VERSION => "b\xe0r\xe9" } ] } } },
    },
    forced_with_an_empty_array => {
        options => {
            force_array => [ qw(OPTION PARAM DEVICE AUTHENTICATION) ]
        },
        content => qq{<?xml version="1.0" encoding="UTF-8"?>
<REPLY>
  <OPTION comment="This is a wrong query as DEVICE is empty">
    <AUTHENTICATION COMMUNITY="public" ID="1" VERSION="1"/>
    <DEVICE></DEVICE>
    <NAME>SNMPQUERY</NAME>
    <PARAM CORE_QUERY="1" PID="1" THREADS_QUERY="1"/>
  </OPTION>
  <PROCESSNUMBER>1</PROCESSNUMBER>
</REPLY>
},
        dump => {
            REPLY => {
                PROCESSNUMBER => '1',
                OPTION => [
                    {
                        '-comment' => 'This is a wrong query as DEVICE is empty',
                        NAME => "SNMPQUERY",
                        PARAM => [
                            {
                                '-CORE_QUERY' => '1',
                                '-THREADS_QUERY' => '1',
                                '-PID' => '1'
                            }
                        ],
                        DEVICE => [ "" ], # This is an error in the related protocol
                        AUTHENTICATION => [
                            {
                                '-ID' => '1',
                                '-COMMUNITY' => 'public',
                                '-VERSION' => '1'
                            }
                        ]
                    }
                ]
            }
        }
    },
    attributes => {
        options => { force_array => [ qw(OPTION AUTHENTICATION) ], xml_format => 0 },
        content => qq{<?xml version="1.0"?>
<REPLY><PROLOG_FREQ>24</PROLOG_FREQ><RESPONSE>SEND</RESPONSE><OPTION><NAME>NETDISCOVERY</NAME><PARAM THREADS_DISCOVERY="20" TIMEOUT="1" PID="18"/><RANGEIP ID="1" IPSTART="192.168.1.1" IPEND="192.168.1.254" ENTITY="0"/><AUTHENTICATION><ID>1</ID><VERSION>1</VERSION><COMMUNITY>public</COMMUNITY></AUTHENTICATION><AUTHENTICATION><ID>2</ID><VERSION>2c</VERSION><COMMUNITY>public</COMMUNITY></AUTHENTICATION></OPTION></REPLY>
},
        dump => {
            REPLY => {
                OPTION => [
                    {
                        NAME => "NETDISCOVERY",
                        PARAM => {
                            '-THREADS_DISCOVERY' => "20",
                            '-TIMEOUT' => "1",
                            '-PID' => "18"
                        },
                        RANGEIP => {
                            '-ID' => "1",
                            '-IPSTART' => "192.168.1.1",
                            '-IPEND' => "192.168.1.254",
                            '-ENTITY' => "0"
                        },
                        AUTHENTICATION => [
                            {
                                ID => "1",
                                VERSION => "1",
                                COMMUNITY => "public"
                            }, {
                                ID => "2",
                                VERSION => "2c",
                                COMMUNITY => "public"
                            }
                        ]
                    }
                ],
                RESPONSE => "SEND",
                PROLOG_FREQ => "24"
            }
        },
        write => qq{<?xml version="1.0" encoding="UTF-8"?>
<REPLY><OPTION><AUTHENTICATION><COMMUNITY>public</COMMUNITY><ID>1</ID><VERSION>1</VERSION></AUTHENTICATION><AUTHENTICATION><COMMUNITY>public</COMMUNITY><ID>2</ID><VERSION>2c</VERSION></AUTHENTICATION><NAME>NETDISCOVERY</NAME><PARAM PID="18" THREADS_DISCOVERY="20" TIMEOUT="1"/><RANGEIP ENTITY="0" ID="1" IPEND="192.168.1.254" IPSTART="192.168.1.1"/></OPTION><PROLOG_FREQ>24</PROLOG_FREQ><RESPONSE>SEND</RESPONSE></REPLY>
}
    },
    attributes_as_node => {
        options => {
            force_array => [ qw(OPTION AUTHENTICATION) ],
            attr_prefix   => '',
            xml_format => 0,
            first_out => [ qw(RESPONSE) ],
        },
        content => qq{<?xml version="1.0"?>
<REPLY><PROLOG_FREQ>24</PROLOG_FREQ><RESPONSE>SEND</RESPONSE><OPTION><NAME>NETDISCOVERY</NAME><PARAM THREADS_DISCOVERY="20" TIMEOUT="1" PID="18"/><RANGEIP ID="1" IPSTART="192.168.1.1" IPEND="192.168.1.254" ENTITY="0"/><AUTHENTICATION><ID>1</ID><VERSION>1</VERSION><COMMUNITY>public</COMMUNITY></AUTHENTICATION><AUTHENTICATION><ID>2</ID><VERSION>2c</VERSION><COMMUNITY>public</COMMUNITY></AUTHENTICATION></OPTION></REPLY>
},
        dump => {
            REPLY => {
                OPTION => [
                    {
                        NAME => "NETDISCOVERY",
                        PARAM => {
                            'THREADS_DISCOVERY' => "20",
                            'TIMEOUT' => "1",
                            'PID' => "18"
                        },
                        RANGEIP => {
                            'ID' => "1",
                            'IPSTART' => "192.168.1.1",
                            'IPEND' => "192.168.1.254",
                            'ENTITY' => "0"
                        },
                        AUTHENTICATION => [
                            {
                                ID => "1",
                                VERSION => "1",
                                COMMUNITY => "public"
                            }, {
                                ID => "2",
                                VERSION => "2c",
                                COMMUNITY => "public"
                            }
                        ]
                    }
                ],
                RESPONSE => "SEND",
                PROLOG_FREQ => "24"
            }
        },
        write => qq{<?xml version="1.0" encoding="UTF-8"?>
<REPLY><RESPONSE>SEND</RESPONSE><OPTION><AUTHENTICATION><COMMUNITY>public</COMMUNITY><ID>1</ID><VERSION>1</VERSION></AUTHENTICATION><AUTHENTICATION><COMMUNITY>public</COMMUNITY><ID>2</ID><VERSION>2c</VERSION></AUTHENTICATION><NAME>NETDISCOVERY</NAME><PARAM><PID>18</PID><THREADS_DISCOVERY>20</THREADS_DISCOVERY><TIMEOUT>1</TIMEOUT></PARAM><RANGEIP><ENTITY>0</ENTITY><ID>1</ID><IPEND>192.168.1.254</IPEND><IPSTART>192.168.1.1</IPSTART></RANGEIP></OPTION><PROLOG_FREQ>24</PROLOG_FREQ></REPLY>
}
    },
    skip_attributes => {
        options => {
            force_array => [ qw(OPTION AUTHENTICATION) ],
            attr_prefix => '',
            skip_attr   => 1,
            xml_format => 0,
        },
        skip_tpp_check => 1,
        content => qq{<?xml version="1.0"?>
<REPLY><PROLOG_FREQ>24</PROLOG_FREQ><RESPONSE>SEND</RESPONSE><OPTION><NAME>NETDISCOVERY</NAME><PARAM THREADS_DISCOVERY="20" TIMEOUT="1" PID="18"/><RANGEIP ID="1" IPSTART="192.168.1.1" IPEND="192.168.1.254" ENTITY="0"/><AUTHENTICATION><ID>1</ID><VERSION>1</VERSION><COMMUNITY>public</COMMUNITY></AUTHENTICATION><AUTHENTICATION><ID>2</ID><VERSION>2c</VERSION><COMMUNITY>public</COMMUNITY></AUTHENTICATION></OPTION></REPLY>
},
        dump => {
            REPLY => {
                OPTION => [
                    {
                        NAME => "NETDISCOVERY",
                        PARAM => '',
                        RANGEIP => '',
                        AUTHENTICATION => [
                            {
                                ID => "1",
                                VERSION => "1",
                                COMMUNITY => "public"
                            }, {
                                ID => "2",
                                VERSION => "2c",
                                COMMUNITY => "public"
                            }
                        ]
                    }
                ],
                RESPONSE => "SEND",
                PROLOG_FREQ => "24"
            }
        },
        write => qq{<?xml version="1.0" encoding="UTF-8"?>
<REPLY><OPTION><AUTHENTICATION><COMMUNITY>public</COMMUNITY><ID>1</ID><VERSION>1</VERSION></AUTHENTICATION><AUTHENTICATION><COMMUNITY>public</COMMUNITY><ID>2</ID><VERSION>2c</VERSION></AUTHENTICATION><NAME>NETDISCOVERY</NAME><PARAM></PARAM><RANGEIP></RANGEIP></OPTION><PROLOG_FREQ>24</PROLOG_FREQ><RESPONSE>SEND</RESPONSE></REPLY>
}
    },
    text_node_key => {
        options => { text_node_key => 'string' },
        content => qq{<?xml version="1.0" encoding="UTF-8"?>
<REQUEST>
  <CONTENT>
    <SOFTWARES>
      <NAME>foo</NAME>
      <VERSION from="web">bàré</VERSION>
    </SOFTWARES>
  </CONTENT>
</REQUEST>
},
        dump => { REQUEST => { CONTENT => { SOFTWARES => { NAME => "foo", VERSION => { '-from' => "web", 'string' => "b\xe0r\xe9" } } } } },
    },
);

# Use found xmls file in resources as examples
my @xml_files = qw(
    resources/linux/rhn-systemid/ID-1232324425
    resources/walks/sample4.result
    resources/walks/sample6.result
    contrib/windows/GLPI-Agent.adml
    resources/virtualization/virsh/dumpxml1
    resources/virtualization/virsh/dumpxml2
    resources/virtualization/virsh/dumpxml3
    resources/virtualization/virsh/dumpxml4
    resources/virtualization/virsh/dumpxml5_lxc
);
File::Find::find({
    no_chdir => 1,
    wanted   => sub {
            push @xml_files, $_ if /\.(xml|soap)$/i;
        }
    },
    'resources'
);

# Skip files wrongly handled by XML::TreePP in specific case we don't care about
my @skip_treepp_test = qw(
    resources/esx/esx-4.1.0-1/RetrieveProperties.soap
);

my %file_cases = (
    "resources/xml/response/message1.xml" => {
        options => {
            text_node_key => '<==text==>',
            attr_prefix   => '~~',
        },
        dump => {
            'REPLY' => {
                'RESPONSE' => 'SEND',
                'OPTION' => [
                    {
                        'NAME' => 'REGISTRY',
                        'PARAM' => {
                            '~~REGKEY' => 'SOFTWARE/Mozilla',
                            '~~REGTREE' => '0',
                            '~~NAME' => 'blablabla',
                            '<==text==>' => '*'
                        }
                    },
                    {
                        'NAME' => 'DOWNLOAD',
                        'PARAM' => {
                            '~~PERIOD_LATENCY' => '1',
                            '~~CYCLE_LATENCY' => '6',
                            '~~PERIOD_LENGTH' => '10',
                            '~~FRAG_LATENCY' => '10',
                            '~~ON' => '1',
                            '~~TYPE' => 'CONF',
                            '~~TIMEOUT' => '30'
                        }
                    }
                ],
                'PROLOG_FREQ' => '1'
            }
        },
    },
);

my $textkey = '#text';
my $xmldir  = tempdir();

# We want to eventually compare with XML::TreePP result
my $tpp;
if (XML::TreePP->require()) {
    $tpp = XML::TreePP->new();
}

plan tests =>
    (scalar keys %xmls) * 10 +
    2 * ($tpp ? 1 : 0) * ((scalar keys %xmls) - grep { $xmls{$_}->{skip_tpp_check} } keys %xmls) +
    (scalar @xml_files) * 2 +
    (scalar keys %file_cases) +
    2 * ($tpp ? 1 : 0) * (scalar(@xml_files) - @skip_treepp_test) +
    1;

foreach my $test (sort keys %xmls) {
    my ($xml, $dump);
    my $options = $xmls{$test}->{options} // {};
    lives_ok {
        # API expects an UTF-8 encoded string
        $xml = GLPI::Agent::XML->new(string => $xmls{$test}->{content}, %{$options});
    } "<$test> xml object instanciation with string parsing";

    isa_ok($xml, "GLPI::Agent::XML");

    ok($xmls{$test}->{has_xml} // 1 ? $xml->has_xml : !$xml->has_xml, "<$test> xml object has xml");

    lives_ok {
        $dump = $xml->dump_as_hash();
    } "<$test> xml object dump as hash";

    cmp_deeply(
        $dump,
        $xmls{$test}->{dump},
        "<$test> expected hash"
    );

    lives_ok {
        # string() API requires an UTF-8 encoded string
        $dump = $xml->string($xmls{$test}->{content})->dump_as_hash();
    } "<$test> xml object dump as hash after update";

    cmp_deeply(
        $dump,
        $xmls{$test}->{dump},
        "<$test> expected hash after update"
    );

    local $XML::LibXML::setTagCompression = $xmls{$test}->{tag_compression} // 0;
    is(
        $xml->empty->write($dump),
        $xmls{$test}->{has_xml} // 1 ? $xmls{$test}->{write} // $xmls{$test}->{content} : '',
        "<$test> xml as string"
    );

    lives_ok {
        $xml->writefile("$xmldir/$test.xml");
    } "<$test> write xml file";

    ok($xmls{$test}->{has_xml} // 1 ? -e "$xmldir/$test.xml" : ! -e "$xmldir/$test.xml", "<$test> xml file written");

    if ($tpp && !$xmls{$test}->{skip_tpp_check}) {
        my $xmltpp;

        # Set required options
        foreach my $opt (keys(%{$options})) {
            $tpp->set($opt => $options->{$opt});
            $textkey = $options->{$opt} if $opt eq "text_key";
        }

        lives_ok {
            $xmltpp = _normalize_xmltreepp($tpp->parse(decode("UTF-8", $xmls{$test}->{content})));
        } "<$test> xml content parsing with XML::TreePP";

        # Reset options
        foreach my $opt (keys(%{$options})) {
            $tpp->set($opt => undef);
        }
        $textkey = '#text';

        cmp_deeply(
            $xmls{$test}->{xmltpp} // $dump,
            $xmltpp,
            "<$test> comparing with XML::TreePP parsing"
        );
    }
}

foreach my $file (sort @xml_files) {
    my ($xml, $dump);

    my %options = $file_cases{$file} ? %{$file_cases{$file}->{options} // {}} : ();

    lives_ok {
        $xml = GLPI::Agent::XML->new(file => $file, %options);
    } "<$file> xml object instanciation with file parsing";

    lives_ok {
        $dump = $xml->dump_as_hash();
    } "<$file> xml object dump as hash";

    if (exists($file_cases{$file})) {
        cmp_deeply(
            $dump,
            $file_cases{$file}->{dump},
            "<$file> file expected hash"
        );
    }

    if ($tpp && !grep { $_ eq $file } @skip_treepp_test) {
        my $xmltpp;
        if (%options) {
            foreach my $opt (keys(%options)) {
                $tpp->set($opt => $options{$opt});
                $textkey = $options{$opt} if $opt eq "text_key";
            }
        }
        my $content = getAllLines(file => $file);
        # Cleanup BOM if set
        $content =~ s/^\xEF\xBB\xBF//;
        lives_ok {
            $xmltpp = _normalize_xmltreepp($tpp->parse(decode("UTF-8", $content)));
        } "<$file> xml file parsing with XML::TreePP";

        # Reset options
        if (%options) {
            foreach my $opt (keys(%options)) {
                $tpp->set($opt => undef);
            }
            $textkey = '#text';
        }

        cmp_deeply(
            $dump,
            $xmltpp,
            "<$file> comparing with XML::TreePP parsing"
        );
    }
}

# Replace any not defined value with empty string to match new API preference
sub _normalize_xmltreepp {
    my ($ref) = @_;
    if (ref($ref) eq 'HASH') {
        # Delete empty textkey content
        delete $ref->{$textkey} if defined($ref->{$textkey}) && !length($ref->{$textkey});
        foreach my $key (keys(%{$ref})) {
            $ref->{$key} = _normalize_xmltreepp($ref->{$key});
        }
    } elsif (ref($ref) eq 'ARRAY') {
        $ref = [ map { _normalize_xmltreepp($_) } @{$ref} ];
    } elsif (!defined($ref)) {
        # Keep not defined nodes as empty string
        $ref = '';
    }
    return $ref;
}
