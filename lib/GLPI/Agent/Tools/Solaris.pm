package GLPI::Agent::Tools::Solaris;

use strict;
use warnings;
use parent 'Exporter';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

our @EXPORT = qw(
    getZone
    getPrtconfInfos
    getPrtdiagInfos
    getReleaseInfo
    getSmbios
);

sub getZone {
    return canRun('zonename') ?
        getFirstLine(command => 'zonename') : # actual zone name
        'global';                             # outside zone name
}

sub getPrtconfInfos {
    my (%params) = (
        command => '/usr/sbin/prtconf -vp',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my $info = {};

    # a stack of nodes, as a list of couples [ node, level ]
    my @parents = (
        [ $info, -1 ]
    );

    foreach my $line (@lines) {

        # new node
        if ($line =~ /^(\s*)Node \s 0x[a-f\d]+/x) {
            my $level   = defined $1 ? length($1) : 0;

            my $parent_level = $parents[-1]->[1];

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

            # push a new node on the stack
            push (@parents, [ {}, $level ]);

            next;
        }

        if ($line =~ /^\s* name: \s+ '(\S.*)'$/x) {
            my $node   = $parents[-1]->[0];
            my $parent = $parents[-2]->[0];
            $parent->{$1} = $node;
            next;
        }

        # value
        if ($line =~ /^\s* (\S[^:]+): \s+ (\S.*)$/x) {
            my $key       = $1;
            my $raw_value = $2;
            my $node = $parents[-1]->[0];

            if ($raw_value =~ /^'[^']+'(?: \+ '[^']+')+$/) {
                # list of string values
                $node->{$key} = [
                    map { /^'([^']+)'$/; $1 }
                    split (/ \+ /, $raw_value)
                ];
            } elsif ($raw_value =~ /^'([^']+)'$/) {
                # single string value
                $node->{$key} = $1;
            } else  {
                # other kind of value
                $node->{$key} = $raw_value;
            }
            next;
        }
    }

    return $info;
}

sub getPrtdiagInfos {
    my (%params) = (
        command => 'prtdiag',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my $info = {};

    while (1) {
        my $line = shift @lines;
        last unless defined($line);
        next unless $line =~ /^=+ \s ([\w\s]+) \s =+$/x;
        my $section = $1;
        $info->{memories} = _parseMemorySection($section, \@lines)
            if $section =~ /Memory/;
        $info->{slots}  = _parseSlotsSection($section, \@lines)
            if $section =~ /(IO|Slots)/;
    }

    return $info;
}

sub _parseMemorySection {
    my ($section, $lines) = @_;

    my ($offset, $callback);

    SWITCH: {
        if ($section eq 'Physical Memory Configuration') {
            my $i = 0;
            $offset = 5;
            $callback = sub {
                my ($line) = @_;
                return unless $line =~ qr/
                    (\d+ \s [MG]B) \s+
                    \S+
                $/x;
                return {
                    TYPE     => 'DIMM',
                    NUMSLOTS => $i++,
                    CAPACITY => getCanonicalSize($1, 1024)
                };
            };
            last SWITCH;
        }

        if ($section eq 'Memory Configuration') {
            # use next line to determine actual format
            my $next_line = shift @{$lines};

            # Skip next line if empty
            $next_line = shift @{$lines} if defined($next_line) && $next_line =~ /^\s*$/;
            return unless defined($next_line);

            if ($next_line =~ /^Segment Table/) {
                # multi-table format: reach bank table
                while (1) {
                    $next_line = shift @{$lines};
                    return unless defined($next_line);
                    last if $next_line =~ /^Bank Table/;
                }

                # then parse using callback
                my $i = 0;
                $offset = 4;
                $callback = sub {
                    my ($line) = @_;
                    return unless $line =~ qr/
                        \d+         \s+
                        \S+         \s+
                        \S+         \s+
                        (\d+ [MG]B)
                    /x;
                    return {
                        TYPE     => 'DIMM',
                        NUMSLOTS => $i++,
                        CAPACITY => getCanonicalSize($1, 1024)
                    };
                };
            } elsif ($next_line =~ /Memory\s+Available\s+Memory\s+DIMM\s+# of/)  {
                # single-table format: start using callback directly
                my $i = 0;
                $offset = 2;
                $callback = sub {
                    my ($line) = @_;
                    return unless $line =~ qr/
                        \d+ [MG]B \s+
                        \S+         \s+
                        (\d+ [MG]B)   \s+
                        (\d+)         \s+
                    /x;
                    return map { {
                        TYPE     => 'DIMM',
                        NUMSLOTS => $i++,
                        CAPACITY => getCanonicalSize($1, 1024)
                    } } 1..$2;
                };
            } else {
                # single-table format: start using callback directly
                my $i = 0;
                $offset = 3;
                $callback = sub {
                    my ($line) = @_;
                    return unless $line =~ qr/
                        (\d+ [MG]B) \s+
                        \S+         \s+
                        (\d+ [MG]B) \s+
                        \S+         \s+
                    /x;
                    my $dimmsize    = getCanonicalSize($2, 1024);
                    my $logicalsize = getCanonicalSize($1, 1024);
                    # Compute DIMM count from "Logical Bank Size" and "DIMM Size"
                    my $dimmcount = ( $dimmsize && $dimmsize != $logicalsize ) ?
                        int($logicalsize/$dimmsize) : 1 ;
                    return map { {
                        TYPE     => 'DIMM',
                        NUMSLOTS => $i++,
                        CAPACITY => $dimmsize
                    } } 1..$dimmcount;
                };
            }

            last SWITCH;
        }

        if ($section eq 'Memory Device Sockets') {
            my $i = 0;
            $offset = 3;
            $callback = sub {
                my ($line) = @_;
                return unless $line =~ qr/^
                    (\w+)           \s+
                    in \s use       \s+
                    \d              \s+
                    ([A-Za-z]+)\d* (?:\s \w+)*
                /x;
                return {
                    DESCRIPTION => $2,
                    NUMSLOTS => $i++,
                    TYPE     => $1
                };
            };
            last SWITCH;
        }

        return;
    }

    return _parseAnySection($lines, $offset, $callback);
}

sub _parseSlotsSection {
    my ($section, $lines) = @_;

    my ($offset, $callback);

    SWITCH: {
        if ($section eq 'IO Devices') {
            $offset  = 3;
            $callback = sub {
                my ($line) = @_;
                return unless $line =~ /^
                    (\S+)    \s+
                    ([A-Z]+) \s+
                    (\S+)
                /x;
                return {
                    NAME        => $1,
                    DESCRIPTION => $2,
                    DESIGNATION => $3,
                };
            };
            last SWITCH;
        }

        if ($section eq 'IO Cards') {
            $offset  = 7;
            $callback = sub {
                my ($line) = @_;
                return unless $line =~ /^
                    \S+      \s+
                    ([A-Z]+) \s+
                    \S+      \s+
                    \S+      \s+
                    (\d)     \s+
                    \S+      \s+
                    \S+      \s+
                    \S+      \s+
                    \S+      \s+
                    (\S+)
                /x;
                return {
                    NAME        => $2,
                    DESCRIPTION => $1,
                    DESIGNATION => $3,
                };
            };
            last SWITCH;
        }

        if ($section eq 'Upgradeable Slots') {
            $offset  = 3;
            # use a column-based strategy, as most values include spaces
            $callback = sub {
                my ($line) = @_;

                my $name        = substr($line, 0, 1);
                my $status      = substr($line, 4, 9);
                my $description = substr($line, 14, 16);
                my $designation = substr($line, 31, 28);

                $status      =~ s/\s+$//;
                $description =~ s/\s+$//;
                $designation =~ s/\s+$//;

                $status =
                    $status eq 'in use'    ? 'used' :
                    $status eq 'available' ? 'free' :
                                              undef;

                return {
                    NAME        => $name,
                    STATUS      => $status,
                    DESCRIPTION => $description,
                    DESIGNATION => $designation,
                };
            };
            last SWITCH;
        }

        return;
    };

    return _parseAnySection($lines, $offset, $callback);
}

sub _parseAnySection {
    my ($lines, $offset, $callback) = @_;

    # skip headers
    foreach my $i (1 .. $offset) {
        shift @{$lines};
    }

    # parse content
    my @items;
    while (1) {
        my $line = shift @{$lines};
        last if !defined($line) || $line =~ /^$/;
        my @item = $callback->($line);
        push @items, @item if @item;
    }

    return \@items;
}

sub getReleaseInfo {
    my (%params) = (
        file => '/etc/release',
        @_
    );

    my $first_line = getFirstLine(
        file    => $params{file},
        logger  => $params{logger},
    );

    my ($fullname)            =
        $first_line =~ /^ \s+ (.+)/x;
    my ($version, $date, $id, $subversion);
    if ($fullname =~ /Solaris/) {
        ($version, $date, $id) = $fullname =~ /Solaris \s ([\d.]+) \s (?: (\d+\/\d+) \s)? (\S+)/x;
        ($subversion) = $id =~ /_(u\d+)/;
    } elsif ($fullname =~ /OpenIndiana/) {
        ($version) = $fullname =~ /([\d.]+)/;
    }

    return {
        fullname   => $fullname,
        version    => $version,
        subversion => $subversion,
        date       => $date,
        id         => $id
    };
}

sub getSmbios {
    my (%params) = (
        command => '/usr/sbin/smbios',
        @_
    );

    my @lines = getAllLines(%params)
        or return;

    my ($infos, $current);
    foreach my $line (@lines) {
        if ($line =~ /^ \d+ \s+ \d+ \s+ (\S+)/x) {
            $current = $1;
            next;
        }

        if ($line =~ /^ \s* ([^:]+) : \s* (.+) $/x) {
            $infos->{$current}->{$1} = $2;
            next;
        }
    }

    return $infos;
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::Solaris - Solaris generic functions

=head1 DESCRIPTION

This module provides some generic functions for Solaris.

=head1 FUNCTIONS

=head2 getZone()

Returns current zone name, or 'global' if there is no defined zone.

=head2 getModel()

Returns system model, as a string.

=head2 getclass()

Returns system class, as a symbolic constant.

=head2 getPrtconfInfos(%params)

Returns a structured view of prtconf output. Each information block is
turned into a hashref, hierarchically organised.

$info = {
    'System Configuration' => 'Sun Microsystems  sun4u',
    'Memory size' => '32768 Megabytes',
    'SUNW,Sun-Fire-V890' => {
        'banner-name' => 'Sun Fire V890',
        'model' => 'SUNW,501-7199',
        'memory-controller' => {
            'compatible' => [
                'SUNW,UltraSPARC-III,mc',
                'SUNW,mc'
            ],
        }
    }
}
