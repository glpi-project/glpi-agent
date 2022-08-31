package GLPI::Agent::Tools::MacOS;

use strict;
use warnings;
use parent 'Exporter';

use Encode;
use English qw(-no_match_vars);
use Memoize;
use POSIX 'strftime';
use Time::Local;
use XML::TreePP;
use UNIVERSAL::require;
use Storable 'dclone';

use GLPI::Agent::Tools;

our @EXPORT = qw(
    getSystemProfilerInfos
    getIODevices
    getBootTime
);

memoize('getSystemProfilerInfos');

use constant {
    KEY_ELEMENT_NAME   => 'key',
    VALUE_ELEMENT_NAME => 'string',
    DATE_ELEMENT_NAME  => 'date',
    ARRAY_ELEMENT_NAME => 'array'
};

my $xmlParser;

sub _initXmlParser {
    my (%params) = @_;

    XML::XPath->require();
    if ($EVAL_ERROR) {
        $params{logger}->debug(
            'XML::XPath unavailable, unable launching _initXmlParser()'
        ) if $params{logger};
        return 0;
    }
    if ($params{xmlString}) {
        $xmlParser = XML::XPath->new(xml => $params{xmlString});
    } elsif ($params{file}) {
        $xmlParser = XML::XPath->new(filename => $params{file});
    }

    # Don't validate XML against DTD, parsing may fail if a proxy is active
    $XML::XPath::ParseParamEnt = 0;

    return $xmlParser;
}

sub _getSystemProfilerInfosXML {
    my (%params) = @_;

    my $command = $params{type} ?
        "/usr/sbin/system_profiler -xml $params{type}" : "/usr/sbin/system_profiler -xml";
    my $xmlStr = getAllLines(command => $command, %params);
    return unless $xmlStr;

    # Decode system_profiler output
    $xmlStr = decode("UTF-8", $xmlStr);

    # As we don't want to use a module platform dependent, we use the XML::TreePP module
    # with an option to keep XML's elements order
    my $info = {};
    if ($params{type} eq 'SPApplicationsDataType') {
        $info->{Applications} = _extractSoftwaresFromXml(
            %params,
            xmlString => $xmlStr
        );
    } elsif (
        $params{type} eq 'SPSerialATADataType'
        || $params{type} eq 'SPDiscBurningDataType'
        || $params{type} eq 'SPCardReaderDataType'
        || $params{type} eq 'SPUSBDataType'
        || $params{type} eq 'SPFireWireDataType'
    ) {
        $info->{storages} = _extractStoragesFromXml(
            %params,
            xmlString => $xmlStr
        );
    } else {
        # not implemented for every data types
    }

    return $info;
}

sub _extractSoftwaresFromXml {
    my (%params) = @_;

    _initXmlParser(%params);

    return unless $xmlParser;

    my $softwaresHash = {};
    my $xPathExpr =  "/plist/array[1]/dict[1]/key[text()='_items']/following-sibling::array[1]/child::dict";
    my $n = $xmlParser->findnodes($xPathExpr);
    my @nl = $n->get_nodelist();
    for my $elem (@nl) {
        $softwaresHash = _mergeHashes($softwaresHash, _extractSoftwareDataFromXmlNode($elem, $params{logger}, $params{localTimeOffset}));
    }

    return $softwaresHash;
}

sub _extractSoftwareDataFromXmlNode {
    my ($xmlNode, $logger, $localTimeOffset) = @_;

    my $soft = _makeHashFromKeyValuesTextNodes($xmlNode);
    next unless $soft->{'_name'};

    $soft = _applySpecialRulesOnApplicationData($soft);
    my $convertedDate = _convertDateFromApplicationDataXml($soft->{lastModified}, $localTimeOffset);
    if (defined $convertedDate) {
        $soft->{lastModified} = $convertedDate;
    } else {
        if (defined $logger) {
            $logger->error("can't parse retrieved dates in 'lastModified' field in XML file");
        }
    }
    my $mappedHash = _mapApplicationDataKeys($soft);

    return $mappedHash;
}

sub _extractStoragesFromXml {
    my (%params) = @_;

    return unless $params{type};

    _initXmlParser(%params);

    return unless $xmlParser;

    my $storagesHash = {};
    my $xPathExpr;
    if ($params{type} eq 'SPSerialATADataType') {
        $xPathExpr =
            "/plist/array[1]/dict[1]/key[text()='_items']/following-sibling::array[1]/child::dict"
                . "/key[text()='_items']/following-sibling::array[1]/child::dict";
    } elsif ($params{type} eq 'SPDiscBurningDataType'
        || $params{type} eq 'SPCardReaderDataType'
        || $params{type} eq 'SPUSBDataType') {
        $xPathExpr = "//key[text()='_items']/following-sibling::array[1]/child::dict";
    } elsif ($params{type} eq 'SPFireWireDataType') {
        $xPathExpr = [
            "//key[text()='_items']/following-sibling::array[1]"
                . "/child::dict[key[text()='_name' and following-sibling::string[1][not(contains(.,'bus'))]]]",
            "./key[text()='units']/following-sibling::array[1]/child::dict",
            "./key[text()='units']/following-sibling::array[1]/child::dict"
        ];
    }

    if (ref($xPathExpr) eq 'ARRAY') {
        # next function call does not return anything
        # it directly appends data to the hashref $storagesHash
        _recursiveParsing({}, $storagesHash, undef, $xPathExpr);
    } else {
        my $n = $xmlParser->findnodes($xPathExpr);
        my @nl = $n->get_nodelist();
        for my $elem (@nl) {
            my $storage = _makeHashFromKeyValuesTextNodes($elem);
            next unless $storage->{_name};
            $storagesHash->{$storage->{_name}} = $storage;
        }
    }
    return $storagesHash;
}

# This function is used to parse ugly XML documents
# It is used to aggregate data from a node and from its descendants

sub _recursiveParsing {
    my (
        # data extracted from ancestors
        $hashFields,
        # hashref to merge data in
        $hashElems,
        # XML context node
        $elemRoot,
        # XPath expressions list to be processed
        $xPathExpr
    ) = @_;

    # we use here dclone because each recursive call must have its own copy of these structure
    my $xPathExprClone = dclone $xPathExpr;

    # next XPath expression is eaten up
    my $expr = shift @$xPathExprClone;

    # XPath expression is processed at context $elemRoot
    my $n = $xmlParser->findnodes($expr, $elemRoot);
    my @nl = $n->get_nodelist();
    if (scalar @nl > 0) {
        for my $elem (@nl) {
            # because of XML document specific format, we must do next call to create the hash
            # in order to have a key-value structure
            my $newHash = _makeHashFromKeyValuesTextNodes($elem);
            next unless $newHash->{_name};

            # we use here dclone because each recursive call must have its own copy of these structure
            my $hashFieldsClone = dclone $hashFields;
            # hashes are merged, existing values are overwritten (that is expected behaviour)
            @$hashFieldsClone{keys %$newHash} = values %$newHash;
            my $extractedElementName = $hashFieldsClone->{_name};

            # if other XPath expressions have to be processed
            if (scalar @$xPathExprClone) {
                # recursive call
                _recursiveParsing($hashFieldsClone, $hashElems, $elem, $xPathExprClone);
            } else {
                # no more XPath expression to process
                # it's time to merge data in main hashref
                $hashElems->{$extractedElementName} = { } unless $hashElems->{$extractedElementName};
                @{$hashElems->{$extractedElementName}}{keys %$hashFieldsClone} = values %$hashFieldsClone;
            }
        }
    } else {
        # no more XML nodes found
        # it's time to merge data in main hashref
        if ($hashFields->{_name}) {
            my $extractedElementName = $hashFields->{_name};
            $hashElems->{$extractedElementName} = { } unless $hashElems->{$extractedElementName};
            @{$hashElems->{$extractedElementName}}{keys %$hashFields} = values %$hashFields;
        }
    }
}

sub _makeHashFromKeyValuesTextNodes {
    my ($node) = @_;

    next unless $xmlParser;

    my $hash;
    my $currentKey;
    my $n = $xmlParser->findnodes('*', $node);
    my @nl = $n->get_nodelist();
    for my $elem (@nl) {
        if ($elem->getName() eq KEY_ELEMENT_NAME) {
            $currentKey = $elem->string_value();
        } elsif ($currentKey && $elem->getName() ne ARRAY_ELEMENT_NAME) {
            $hash->{$currentKey} = $elem->string_value();
            $currentKey = undef;
        }
    }
    return $hash;
}

sub _convertDateFromApplicationDataXml {
    my ($dateStrFromDataXml, $localtimeOffset) = @_;

    my $date;
    if ($dateStrFromDataXml =~ /^(\d{4})[^0-9](\d{2})[^0-9](\d{2})[^0-9](\d{2}):(\d{2}):(\d{2})[^0-9]$/) {
        $date = _convertDateToLocalDate($6, $5, $4, $3, $2 - 1, $1, $localtimeOffset);
    }

    return $date;
}

sub _convertDateToLocalDate {
    my ($sec,$min,$hour,$mday,$mon,$year, $localtimeOffset) = @_;

    my $epoch = timegm ($sec, $min, $hour, $mday, $mon, $year);

    my $newEpoch = $epoch + $localtimeOffset;

    return strftime("%d/%m/%Y", gmtime($newEpoch));
}

sub detectLocalTimeOffset {
    my @gmTime = localtime;
    return -(timelocal(@gmTime) - timegm(@gmTime));
}

sub _applySpecialRulesOnApplicationData {
    my ($hash) = @_;

    if (defined($hash->{has64BitIntelCode})) {
        $hash->{has64BitIntelCode} = ucfirst $hash->{has64BitIntelCode};
    }
    if (defined($hash->{runtime_environment})) {
        if ($hash->{runtime_environment} eq 'arch_x86') {
            $hash->{runtime_environment} = 'Intel';
        }
        $hash->{runtime_environment} = ucfirst $hash->{runtime_environment};
    }

    return $hash;
}

sub _mergeHashes {
    my ($hash1, $hash2) = @_;

    for my $key (keys %$hash2) {
        my $newKey = $key;
        if (defined($hash1->{$key})) {
            my $i = 0;
            $newKey = $key . '_' . $i;
            while (defined($hash1->{$newKey})) {
                $newKey = $key . '_' . $i++;
            }
        }
        $hash1->{$newKey} = $hash2->{$key};
    }

    return $hash1;
}

sub _mapApplicationDataKeys {
    my ($hash) = @_;

    my $mapping = {
        'version' => 'Version',
        'has64BitIntelCode' => '64-Bit (Intel)',
        'lastModified' => 'Last Modified',
        'path' => 'Location',
        'runtime_environment' => 'Kind',
        'info' => 'Get Info String'
    };
    my %hashMapped = map { ($mapping->{$_} || 'unMapped') => $hash->{$_} } keys %$hash;
    delete $hashMapped{unMapped};

    # to merge two hashes
    # @hash1{keys %hash2} = values %hash2

    return { $hash->{'_name'} => \%hashMapped };
}

sub getSystemProfilerInfos {
    my (%params) = @_;

    my $info;
    if ($params{format} && $params{format} eq 'xml') {
        $info = _getSystemProfilerInfosXML(%params);
    } else {
        $info = _getSystemProfilerInfosText(%params);
    }

    return $info;
}

sub _getSystemProfilerInfosText {
    my (%params) = @_;

    $params{command} = $params{type} ?
        "/usr/sbin/system_profiler $params{type}" : "/usr/sbin/system_profiler";
    my @lines = getAllLines(%params)
        or return;

    my $info = {};

    my @parents = (
        [ $info, -1 ]
    );
    foreach my $line (@lines) {
        $line = decode("UTF-8", $line);

        next unless $line =~ /^(\s*)(\S[^:]*):(?: (.*\S))?/;
        my $level = defined $1 ? length($1) : 0;
        my $key = $2;
        my $value = $3;

        my $parent = $parents[-1];
        my $parent_level = $parent->[1];
        my $parent_node  = $parent->[0];

        if (defined $value) {
            # check indentation level against parent node
            if ($level <= $parent_level) {

                if (keys %$parent_node == 0) {
                    # discard just created node, and fix its parent
                    my $parent_key = $parent->[2];
                    $parents[-2]->[0]->{$parent_key} = undef;
                }

                # unstack nodes until a suitable parent is found
                while ($level <= $parents[-1]->[1]) {
                    pop @parents;
                }
                $parent_node = $parents[-1]->[0];
            }

            # add the value to the current node
            $parent_node->{$key} = $value;
        } else {
            # compare level with parent
            if ($level > $parent_level) {
                # down the tree: no change
            } elsif ($level < $parent_level) {
                # up the tree: unstack nodes until a suitable parent is found
                while ($level <= $parents[-1]->[1]) {
                    pop @parents;
                }
            } else {
                # same level: unstack last node
                pop @parents;
            }

            # create a new node, and push it to the stack
            my $parent_node = $parents[-1]->[0];

            my $i;
            my $keyL = $key;
            while (defined($parent_node->{$key})) {
                $key = $keyL . '_' . $i++;
            }

            $parent_node->{$key} = {};
            push (@parents, [ $parent_node->{$key}, $level, $key ]);
        }
    }

    return $info;
}

sub getIODevices {
    my (%params) = @_;

    # passing expected class to the command ensure only instance of this class
    # are present in the output, reducing the size of the content to be parsed,
    # but still requires some manual filtering to avoid subclasses instances
    $params{command} = $params{class} ? "ioreg -c $params{class}" : "ioreg -l";
    my $filter = $params{class} || '[^,]+';

    $params{command} .= " $params{options}" if $params{options};

    my @lines = getAllLines(%params)
        or return;

    my @devices;
    my $device;

    foreach my $line (@lines) {
        if ($line =~ /<class $filter,/) {
            # new device block
            $device = {};
            next;
        }

        next unless $device;

        if ($line =~ /\| }/) {
            # end of device block
            push @devices, $device;
            undef $device;
            next;
        }

        if ($line =~ /"([^"]+)" \s = \s <? (?: "([^"]+)" | ([0-9a-f]+)) >?/ix) {
            # string or numeric property
            $device->{$1} = $2 || $3;
            next;
        }
    }

    # Always include last device
    push @devices, $device if $device;

    return @devices;
}

sub getBootTime {
    my (%params) = @_;
    if (!$params{string} && !$params{command}) {
        $params{command} = 'sysctl -n kern.boottime';
    }
    my $boottime = getFirstMatch(
        pattern => qr/(?: sec = (\d+)|(\d+)$)/,
        %params
    );

    return $boottime;
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::MacOS - MacOS generic functions

=head1 DESCRIPTION

This module provides some generic functions for MacOS.

=head1 FUNCTIONS

=head2 getSystemProfilerInfos(%params)

Returns a structured view of system_profiler output. Each information block is
turned into a hashref, hierarchically organised.

$info = {
    'Hardware' => {
        'Hardware Overview' => {
            'SMC Version (system)' => '1.21f4',
            'Model Identifier' => 'iMac7,1',
            ...
        }
    }
}

=over

=item logger a logger object

=item command the exact command to use (default: /usr/sbin/system_profiler)

=item file the file to use, as an alternative to the command

=back

=head2 getIODevices(%params)

Returns a flat list of devices as a list of hashref, by parsing ioreg output.
Relationships are not extracted.

=over

=item logger a logger object

=item class the class of devices wanted

=item file the file to use, as an alternative to the command

=back
