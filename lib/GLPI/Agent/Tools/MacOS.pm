package GLPI::Agent::Tools::MacOS;

use strict;
use warnings;
use parent 'Exporter';

use Encode;
use English qw(-no_match_vars);
use POSIX 'strftime';
use Time::Local;
use UNIVERSAL::require;

use GLPI::Agent::Tools;
use GLPI::Agent::XML;

our @EXPORT = qw(
    getSystemProfilerInfos
    getIODevices
    getBootTime
    detectLocalTimeOffset
);

sub _getSystemProfilerInfosXML {
    my (%params) = @_;

    my $command = $params{type} ?
        "/usr/sbin/system_profiler -xml $params{type}" : "/usr/sbin/system_profiler -xml";
    my $xmlStr = getAllLines(command => $command, %params);
    return unless $xmlStr;

    my $info = {};
    if ($params{type} eq 'SPApplicationsDataType') {
        $info->{Applications} = _extractSoftwaresFromXml(
            string => $xmlStr,
            %params
        );
    } elsif ($params{type} =~ /^SP(SerialATA|DiscBurning|CardReader|USB|FireWire)DataType$/) {
        $info->{storages} = _extractStoragesFromXml(
            string => $xmlStr,
            logger => $params{logger}
        );
    } else {
        # not implemented for every data types
    }

    return $info;
}

sub _getDict {
    my (%params) = @_;

    my $xml = GLPI::Agent::XML->new(
        is_plist => 1,
        %params
    )->dump_as_hash();

    return unless $xml && ref($xml->{plist}->{array}[0]->{dict}[0]->{array}) eq 'ARRAY';

    my $node = first { ref($_) eq 'HASH' && exists($_->{dict}) } @{$xml->{plist}->{array}[0]->{dict}[0]->{array}};

    return $node->{dict};
}

sub _recSubStorage {
    my ($list) = @_;

    my @nodes;
    foreach my $node (@{$list}) {
        next unless ref($node) eq 'HASH';
        if (ref($node->{array}[0]) eq 'HASH' && exists($node->{array}[0]->{dict})) {
            push @nodes, map { _recSubStorage($_->{dict}) }
                grep { ref($_) eq 'HASH' && exists($_->{dict}) } @{$node->{array}};
        }
        if ($node->{_name}) {
            # Always cleanup from subnodes
            delete $node->{array};
            push @nodes, $node;
        }
    }

    return @nodes;
}

sub _extractStoragesFromXml {
    my (%params) = @_;

    my $dict = _getDict(%params)
        or return;

    my $storages = {};

    foreach my $storage (_recSubStorage($dict)) {
        my $name = $storage->{_name}
            or next;
        $storages->{$name} = $storage;
    }

    return $storages;
}

sub _getOffsetDate {
    my ($lastmod, $localtimeOffset) = @_;

    return unless $lastmod && $lastmod =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z$/;
    my $date = timegm($6, $5, $4, $3, $2 - 1, $1) + $localtimeOffset;
    return strftime("%d/%m/%Y", gmtime($date));
}

sub detectLocalTimeOffset {
    my @gmTime = localtime;
    return -(timelocal(@gmTime) - timegm(@gmTime));
}

sub _formatDate {
    my ($dateStr) = @_;

    my @date = $dateStr =~ /^\s*(\d{1,2})\/(\d{1,2})\/(\d{2})\s*/;
    return @date == 3 ?
        sprintf("%02d/%02d/%d", $date[1], $date[0], 2000+$date[2])
        :
        $dateStr;
}

sub _extractSoftwaresFromXml {
    my (%params) = @_;

    my $softlist = _getDict(%params)
        or return;

    my $softwares = {};

    foreach my $soft (@{$softlist}) {

        my $name = $soft->{_name}
            or next;

        my $entry = {};

        # Normalize has64BitIntelCode & runtime_environment values
        my $bits = delete $soft->{has64BitIntelCode};
        $entry->{'64-Bit (Intel)'} = ucfirst($bits)
            if defined($bits);

        my $env = delete $soft->{runtime_environment};
        if (defined($env)) {
            if ($env eq 'arch_x86') {
                $entry->{Kind} = 'Intel';
            } else {
                $entry->{Kind} = ucfirst($env);
            }
        }

        # Convert lastModified
        my $lastmod = delete $soft->{lastModified};
        $entry->{'Last Modified'} = _getOffsetDate($lastmod, $params{localTimeOffset})
            if defined($lastmod);

        my %mapping = (
            version => 'Version',
            path    => 'Location',
            info    => 'Get Info String'
        );

        foreach my $key (keys(%mapping)) {
            next unless exists($soft->{$key});
            $entry->{$mapping{$key}} = $soft->{$key};
        }

        # Merge hash
        if (exists($softwares->{$name})) {
            my $index = 0;
            while (exists($softwares->{$name."_$index"})) {
                $index++;
            }
            $name = $name."_$index";
        }
        $softwares->{$name} = $entry;
    }

    return $softwares;
}

sub getSystemProfilerInfos {
    my (%params) = @_;

    return _getSystemProfilerInfosXML(%params)
        if defined($params{format}) && $params{format} eq 'xml';

    my @lines = getAllLines(
        command => $params{type} ?
            "/usr/sbin/system_profiler $params{type}" : "/usr/sbin/system_profiler",
        %params
    );
    return unless @lines;

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

            # Handle 'Last Modified' case
            $value = _formatDate($value) if $key eq 'Last Modified';

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
