package GLPI::Test::Utils;

use strict;
use warnings;
use parent 'Exporter';

use English qw(-no_match_vars);
use IPC::Run qw(run);
use Socket;

use GLPI::Agent::Tools;

our @EXPORT = qw(
    run_executable
    test_port
    mockGetWMIObjects
    mockGetRegistryKey
    unsetProxyEnvVar
    loadRegistryDump
    loadWMIDump
);

sub test_port {
    my ($port) = @_;

    my $iaddr = inet_aton('localhost');
    my $paddr = sockaddr_in($port, $iaddr);
    my $proto = getprotobyname('tcp');
    if (socket(my $socket, PF_INET, SOCK_STREAM, $proto)) {
        if (bind($socket, $paddr)) {
            close $socket;
            return 1;
        }
    }

    return 0;
}

sub mockGetWMIObjects {
    my ($test) = @_;

    return sub {
        my (%params) = @_;

        my $class = $params{class};
        if (!$class) {
            my $query = $params{query};
            $query = shift @{$query} if ref($query) eq 'ARRAY';
            ($class) = $query =~ /FROM\s+(\w+)/i ;
        }
        my $file = "resources/win32/wmi/$test-$class.wmi";
        return loadWMIDump($file, $params{properties});
    };
}

sub loadWMIDump {
    my ($file, $properties) = @_;

    open (my $handle, '<', $file) or return;

    # this is a windows file
    binmode $handle, ':encoding(UTF-16LE)';
    local $INPUT_RECORD_SEPARATOR="\r\n";

    # build a list of desired properties indexes
    my %properties = map { $_ => 1 } @{$properties};

    my @objects;
    my $object;
    while (my $line = <$handle>) {
        chomp $line;
        next if $line =~ /^#/;

        if ($line =~ /^ (\w+) = (.+) $/x) {
            my $key = $1;
            my $value = $2;
            next unless $properties{$key};
            if ($value =~ /{(".*")}/) {
                # values list
                my @values =
                    map { /"([^"]+)"/ }
                    split(/,/, $1);
                $object->{$key} = \@values;
            } else {
                $value =~ s/&amp;/&/g;
                $object->{$key} = $value;
            }
            next;
        }

        if ($line =~ /^$/) {
            push @objects, $object if $object;
            undef $object;
            next;
        }
    }
    close $handle;

    push @objects, $object if $object;

    return @objects;
}

sub mockGetRegistryKey {
    my ($test) = @_;

    return sub {
        my (%params) = @_;

        # We can mock getRegistryKey or better _getRegistryKey to cover getRegistryValue
        my $path = $params{path} || $params{keyName};
        my $last_elt = (split(/\//, $path))[-1];
        my $file = "resources/win32/registry/$test-$last_elt.reg";
        return loadRegistryDump($file);
    };
}

sub loadRegistryDump {
    my ($file) = @_;

    my $root_offset;
    my $root_key = {};
    my $current_key = $root_key;
    my $current_variable;

    open (my $handle, '<', $file) or die "can't open $file: $ERRNO";

    # this is a windows file
    binmode $handle, ':encoding(UTF-16LE)';
    local $INPUT_RECORD_SEPARATOR="\r\n";

    while (my $line = <$handle>) {
        chomp $line;

        if ($line =~ /^ \[ ([^]]+) \] $/x) {
            my $path = $1;
            my @path = split(/\\/, $path);

            if ($root_offset) {
                splice @path, 0, $root_offset;
                $current_key = $root_key;
                foreach my $element (@path) {
                    my $key_path = $element . '/';

                    if (!defined $current_key->{$key_path}) {
                        my $new_key = bless( {}, "Win32::TieRegistry" );
                        $current_key->{$key_path} = $new_key;
                    }

                    $current_key = $current_key->{$key_path};
                }
            } else {
                $root_offset = scalar @path;
            }
            next;
        }

        if ($line =~ /^ " ([^"]+) " = dword:([0-9a-f]+)/x) {
            my ($key, $value) = ($1, $2);
            $current_key->{'/' . $key} = "0x$value";
            next;
        }

        # hex(b) support is for QWORD datas
        if ($line =~ /^ " ([^"]+) " = hex(?:\(b\))?:([a-f0-9,]+)/x) {
            my ($key, $value) = ($1, $2);
            $current_key->{'/' . $key} = _binary($2);
            $current_variable = '/' . $key if $line =~ /\\$/;
            next;
        }

        if ($line =~ /^ " ([^"]+) " = " ([^"]*) "/x) {
            my ($key, $value) = ($1, $2);
            $value =~ s{\\\\}{\\}g;
            $current_key->{'/' . $key} = $value;
            next;
        }

        # Default key value
        if ($line =~ /^ \@ = " ([^"]*) "/x) {
            my $value = $1;
            $value =~ s{\\\\}{\\}g;
            $current_key->{'/'} = $value;
            next;
        }

        if ($line =~ /^ \s \s ([a-f0-9,]+)/x) {
            # continuation line
            next unless $current_variable;
            $current_key->{$current_variable} .= _binary($1);
            $current_variable = undef if $line !~ /\\$/;
        }


    }
    close $handle;

    bless( $root_key, "Win32::TieRegistry" );

    return $root_key;
}

sub _binary {
    my ($string) = @_;
    return pack("C*", map { hex($_) } split (/,/, $string));
}

sub unsetProxyEnvVar {
    foreach my $key (qw(http_proxy https_proxy HTTP_PROXY HTTPS_PROXY)) {
         delete($ENV{$key});
    }
}

sub run_executable {
    my ($executable, $args) = @_;

    my @args = $args ? split(/\s+/, $args) : ();
    run(
        [ $EXECUTABLE_NAME, 'bin/' . $executable, @args ],
        \my ($in, $out, $err)
    );
    return ($out, $err, $CHILD_ERROR >> 8);
}

sub openWin32Registry {

    my $Registry;
    Win32::TieRegistry->require();
    Win32::TieRegistry->import(
        Delimiter   => '/',
        TiedRef     => \$Registry
    );

    my $agentKey = 'GLPI-Agent-unittest';
    my $machKey = $Registry->{'LMachine'};
    die "\nFailed to open HKEY_LOCAL_MACHINE hive, be sure to run this win32 test with Administrator privileges"
        unless $machKey;
    my $settings  = $machKey->Open('SOFTWARE/' . $agentKey, { 'Delimiter' => '/' });
    unless (defined($settings)) {
        # Create test key
        my $softKey = $machKey->Open('SOFTWARE', { 'Delimiter' => '/' });
        $softKey->{$agentKey} = {};

        $settings = $machKey->Open('SOFTWARE/' . $agentKey, { 'Delimiter' => '/' });
        die "\nFailed to create HKEY_LOCAL_MACHINE/SOFTWARE/$agentKey key, be sure to run this win32 test with Administrator privileges"
            unless defined($settings);
    }

    return $settings;
}
