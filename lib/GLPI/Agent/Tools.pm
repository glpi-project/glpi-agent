package GLPI::Agent::Tools;

use strict;
use warnings;
use parent 'Exporter';

use Encode qw(encode);
use English qw(-no_match_vars);
use File::Basename;
use File::Spec;
use File::stat;
use File::Which;
use UNIVERSAL::require;

use GLPI::Agent::Tools::Expiration;

# Keep a copy of @ARGV, only for Provider inventory
BEGIN {
    our $ARGV = [ @ARGV ];
}
our $ARGV;

our @EXPORT = qw(
    first
    getDirectoryHandle
    getFileHandle
    getFormatedLocalTime
    getFormatedGMTTime
    getFormatedDate
    getCanonicalManufacturer
    getCanonicalSpeed
    getCanonicalInterfaceSpeed
    getCanonicalSize
    getCanonicalPower
    getSanitizedString
    getUtf8String
    trimWhitespace
    getFirstLine
    getFirstMatch
    getLastLine
    getAllLines
    getLinesCount
    compareVersion
    canRun
    canRead
    hex2char
    hex2dec
    dec2hex
    any
    all
    none
    uniq
    file2module
    module2file
    runFunction
    setRemoteForTools
    resetRemoteForTools
    OSNAME
    Glob
    has_folder
    has_file
    has_link
    FileStat
    ReadLink
    GetNextUser
    Uname
    month
);

our $remote;

sub setRemoteForTools {
    my $r = shift;

    $remote = $r;
}

sub resetRemoteForTools {
    undef $remote;
}

sub OSNAME {
    return $OSNAME unless $remote;
    return $remote->OSName();
}

sub Uname {
    return getFirstLine(command => "uname @_");
}

sub Glob {
    if (!$remote) {
        my ($glob, $test) = @_;
        my @glob = glob($glob);
        if ($test) {
            return grep { -s $_ } @glob if $test eq "-s";
            return grep { -l $_ } @glob if $test eq "-h";
        }
        return @glob;
    }
    return $remote->remoteGlob(@_);
}

sub has_folder {
    my $d = shift;
    return -d $d unless $remote;
    return $remote->remoteTestFolder($d);
}

sub has_file {
    my $f = shift;
    return -e $f unless $remote;
    return $remote->remoteTestFile($f);
}

sub canRead {
    my $f = shift;
    return -r $f unless $remote;
    return $remote->remoteTestFile($f, 'r');
}

sub has_link {
    my $f = shift;
    return -l $f unless $remote;
    return $remote->remoteTestLink($f);
}

sub FileStat {
    my $f = shift;
    return stat($f) unless $remote;
    # populate() is a File::stat hidden function
    return File::stat::populate($remote->remoteFileStat($f));
}

sub ReadLink {
    my $f = shift;
    return readlink($f) unless $remote;
    return $remote->remoteReadLink($f);
}

sub GetNextUser {
    return $remote->remoteGetNextUser() if $remote;
    my @entry = getpwent()
        or return;
    return {
        name    => $entry[0],
        uid     => $entry[2],
        dir     => $entry[7]
    };
}

# Avoid List::Util dependency re-using 'any' sub as template
sub first (&@) { ## no critic (SubroutinePrototypes)
    my $f = shift;

    ## no critic (ExplicitReturnUndef)

    foreach ( @_ ) {
        return $_ if $f->();
    }
    return undef;
}

sub getFormatedLocalTime {
    my ($time) = @_;

    return unless $time;

    my ($year, $month , $day, $hour, $min, $sec) =
        (localtime ($time))[5, 4, 3, 2, 1, 0];

    return getFormatedDate(
        ($year + 1900), ($month + 1), $day, $hour, $min, $sec
    );
}

sub getFormatedGMTTime {
    my ($time) = @_;

    my ($year, $month , $day, $hour, $min, $sec) =
        (gmtime ($time))[5, 4, 3, 2, 1, 0];

    return getFormatedDate(
        ($year - 70), $month, ($day - 1), $hour, $min, $sec
    );
}

sub getFormatedDate {
    my ($year, $month, $day, $hour, $min, $sec) = @_;

    return sprintf
        "%02d-%02d-%02d %02d:%02d:%02d",
        $year, $month, $day, $hour, $min, $sec;
}

sub getCanonicalManufacturer {
    my ($manufacturer) = @_;

    return unless $manufacturer;

    my %manufacturers = (
        GenuineIntel => 'Intel',
        AuthenticAMD => 'AMD',
        TMx86        => 'Transmeta',
        TransmetaCPU => 'Transmeta',
        CyrixInstead => 'Cyrix',
        CentaurHauls => 'VIA',
        HygonGenuine => 'Hygon'
    );

    my %regexp = (
        "Apple"           => qr/^APPLE/i,
        "Hewlett-Packard" => qr/^(hp|HPE?|(?i)hewlett[ -]packard)/,
        "Hitachi"         => qr/^(HD|IC|HU|HGST)/,
        "Seagate"         => qr/^(ST|(?i)seagate)/,
        "Sony"            => qr/^OPTIARC/i,
        "Western Digital" => qr/^(WDC|(?i)western)/,
    );

    if (exists $manufacturers{$manufacturer}) {
        $manufacturer = $manufacturers{$manufacturer};
    } elsif ($manufacturer =~ /(
        \blg\b     |
        broadcom   |
        compaq     |
        dell       |
        fujitsu    |
        hitachi    |
        ibm        |
        intel      |
        matshita   |
        maxtor     |
        nvidia     |
        \bnec\b    |
        pioneer    |
        samsung    |
        sony       |
        supermicro |
        toshiba    |
        transcend
    )/xi) {
        $manufacturer = ucfirst(lc($1));
    } else {
        my $match = first { $manufacturer =~ $regexp{$_} } keys %regexp;
        $manufacturer = $match if $match;
    }

    return $manufacturer;
}

sub getCanonicalSpeed {
    my ($speed) = @_;

    ## no critic (ExplicitReturnUndef)

    return undef unless $speed;

    return $speed if $speed =~ /^([,.\d]+)$/;

    return 400 if $speed =~ /^PC3200U/;

    return undef unless $speed =~ /^([,.\d]+) \s? (\S+)/x;
    my $value = $1;
    my $unit = lc($2);

    # Remark: we need to return speed in MHz. Even if MT/s is not accurately
    # equivalent to MHz, we nned to return the value so server can extract it
    return
        $unit eq 'ghz'  ? $value * 1000 :
        $unit eq 'mhz'  ? $value        :
        $unit eq 'mt/s' ? $value        :
                          undef         ;
}

sub getCanonicalInterfaceSpeed {
    # Expected unit is Mb/s as specified in inventory protocol
    my ($speed) = @_;

    ## no critic (ExplicitReturnUndef)

    return undef unless $speed;

    return undef unless $speed =~ /^([,.\d]+) \s? (\S\S)\S*$/x;
    my $value = $1;
    my $unit = lc($2);

    return
        $unit eq 'gb' ? $value * 1000         :
        $unit eq 'mb' ? $value                :
        $unit eq 'kb' ? int($value / 1000)    :
                        undef                 ;
}

sub getCanonicalSize {
    my ($size, $base) = @_;
    $base ||= 1000;

    ## no critic (ExplicitReturnUndef)

    return undef unless $size;

    return $size if $size =~ /^\d+$/;

    $size =~ s/ //g;

    return undef unless $size =~ /^([,.\d]+) (\S+)$/x;
    my $value = $1;
    my $unit = lc($2);

    # check if the number has groups separated by commas or spaces
    if ($value =~ /^(0|[1-9](\d*|\d{0,2}([, ]\d{3})+))(\.\d+)?$/) {
        $value =~ s/,| //g;
    } else {
        $value =~ s/,/\./;
    }

    return
        $unit eq 'tb'    ? $value * $base * $base        :
        $unit eq 'gb'    ? $value * $base                :
        $unit eq 'mb'    ? $value                        :
        $unit eq 'kb'    ? int($value / ($base))         :
        $unit eq 'bytes' ? int($value / ($base * $base)) :
                           undef                         ;
}

sub getCanonicalPower {
    my ($power) = @_;

    ## no critic (ExplicitReturnUndef)

    return undef unless $power;

    my ($value, $unit) = $power =~ /([\d]+) \s? (\S*)\S*$/x
        or return undef;

    return $value unless $unit;

    return
        $unit eq 'kW' ? $value * 1000      :
        $unit eq 'W'  ? $value             :
        $unit eq 'mW' ? int($value / 1000) :
                        undef              ;
}

sub compareVersion {
    my ($major, $minor, $min_major, $min_minor) = @_;

    $major = 0 unless $major;
    $minor = 0 unless $minor;
    $min_major = 0 unless $min_major;
    $min_minor = 0 unless $min_minor;

    return
        $major > $min_major
        ||
        (
            $major == $min_major
            &&
            $minor >= $min_minor
        );
}

sub getUtf8String {
    my ($string) = @_;

    return unless defined $string;

    # encode to utf-8 if needed
    if (!Encode::is_utf8($string) && $string !~ m/\A(
          [\x09\x0A\x0D\x20-\x7E]           # ASCII
        | [\xC2-\xDF][\x80-\xBF]            # non-overlong 2-byte
        | \xE0[\xA0-\xBF][\x80-\xBF]        # excluding overlongs
        | [\xE1-\xEC\xEE\xEF][\x80-\xBF]{2} # straight 3-byte
        | \xED[\x80-\x9F][\x80-\xBF]        # excluding surrogates
        | \xF0[\x90-\xBF][\x80-\xBF]{2}     # planes 1-3
        | [\xF1-\xF3][\x80-\xBF]{3}         # planes 4-15
        | \xF4[\x80-\x8F][\x80-\xBF]{2}     # plane 16
        )*\z/x) {
        $string = encode("UTF-8", $string);
    };

    return $string;
}

sub getSanitizedString {
    my ($string) = @_;

    return unless defined $string;

    # clean control caracters
    $string =~ s/[[:cntrl:]]//g;

    return getUtf8String($string);
}

sub trimWhitespace {
    my ($value) = @_;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    $value =~ s/\s+/ /g;
    return $value;
}

sub getDirectoryHandle {
    my (%params) = @_;

    die "no directory parameter given" unless $params{directory};

    my $handle;

    if (!opendir $handle, $params{directory}) {
        $params{logger}->error("Can't open directory $params{directory}: $ERRNO")
            if $params{logger};
        return;
    }

    return $handle;
}

my $cmdtemplate = $OSNAME eq 'MSWin32' ? "%s 2>nul" : "exec %s 2>/dev/null";
sub getFileHandle {
    my (%params) = @_;

    my $handle;

    SWITCH: {
        if ($remote && !$params{local} && ($params{file} || $params{command})) {
            $handle = $remote->getRemoteFileHandle(%params);
            last SWITCH;
        }
        if ($params{file}) {
            my $mode = $params{mode} // '<';
            if (!open $handle, $mode, $params{file}) {
                $params{logger}->error(
                    "Can't open file $params{file}: $ERRNO"
                ) if $params{logger} && !$params{no_error_log};
                return;
            }
            last SWITCH;
        }
        if ($params{command}) {
            # limit log command size if too large like for powershell commands
            my $logcommand = $params{command};
            while (length($logcommand)>120 && $logcommand =~ /\w\s+\w/) {
                ($logcommand) = $logcommand =~ /^(.*\w)\s+\w+/;
                $logcommand .= " ...";
            }
            # FIXME: 'Bad file descriptor' error message on Windows
            $params{logger}->debug2("executing $logcommand")
                if $params{logger} && $params{logger}->debug_level();
            # Turn off localised output for commands
            local $ENV{LC_ALL} = 'C';
            local $ENV{LANG} = 'C';
            # Delete LD_LIBRARY_PATH && LD_PRELOAD env when run from AppImage
            # to always run system binaries with system libraries
            delete @ENV{qw/LD_LIBRARY_PATH LD_PRELOAD/}
                if $ENV{LD_LIBRARY_PATH} && $ENV{APPRUN_STARTUP_APPIMAGE_UUID} && $ENV{APPDIR};
            # Ignore 'Broken Pipe' warnings on Solaris
            local $SIG{PIPE} = 'IGNORE' if $OSNAME eq 'solaris';
            my $command = sprintf($cmdtemplate, $params{command});
            my $cmdpid  = open($handle, '-|', $command);
            if (!$cmdpid) {
                $params{logger}->error(
                    "Can't run command $logcommand: $ERRNO"
                ) if $params{logger} && !$params{no_error_log};
                return;
            }
            # Kill command if a timeout was set
            $SIG{ALRM} = sub { kill 'KILL', $cmdpid ; die "alarm\n"; } if $SIG{ALRM};
            last SWITCH;
        }
        if ($params{string}) {
            open $handle, "<", \$params{string} or die;
            last SWITCH;
        }
        die "neither command, file or string parameter given";
    }

    return $handle;
}

sub getFirstLine {
    my (%params) = @_;

    my $handle = getFileHandle(%params);
    return unless $handle;

    my $result = <$handle>;
    close $handle;

    chomp $result if defined $result;
    return $result;
}

sub getLastLine {
    my (%params) = @_;

    my $handle = getFileHandle(%params);
    return unless $handle;

    my $result;
    while (my $line = <$handle>) {
        $result = $line;
    }
    close $handle;

    chomp $result if defined $result;
    return $result;
}

sub getFirstMatch {
    my (%params) = @_;

    return unless $params{pattern};

    my @lines = getAllLines(%params)
        or return;

    my @results;
    foreach my $line (@lines) {
        @results = $line =~ $params{pattern};
        last if @results;
    }

    return wantarray ? @results : first { defined $_ } @results;
}

sub getAllLines {
    my (%params) = @_;

    my $handle = getFileHandle(%params);
    return unless $handle;

    if (wantarray) {
        my @lines = map { chomp; $_ } <$handle>;
        close $handle;
        return @lines;
    } else {
        local $RS;
        my $lines = <$handle>;
        close $handle;
        return $lines;
    }
}

sub getLinesCount {
    my (%params) = @_;

    my @lines = getAllLines(%params)
        or return;

    return scalar(@lines);
}

sub canRun {
    my ($binary) = @_;

    return $remote->remoteCanRun($binary) if $remote;

    return $binary =~ m{^/} ?
        -x $binary :            # full path
        scalar(which($binary)); # executable name
}

sub hex2char {
    my ($value) = @_;

    ## no critic (ExplicitReturnUndef)
    return undef unless defined $value;
    return $value unless $value =~ /^0x/;

    $value =~ s/^0x//; # drop hex prefix
    return pack('H*', $value);
}

sub hex2dec {
    my ($value) = @_;

    ## no critic (ExplicitReturnUndef)
    return undef unless defined $value;
    return $value unless $value =~ /^0x/;

    return oct($value);
}

sub dec2hex {
    my ($value) = @_;

    ## no critic (ExplicitReturnUndef)
    return undef unless defined $value;
    return $value if $value =~ /^0x/;

    return sprintf("0x%x", $value);
}

# shamelessly imported from List::MoreUtils to avoid a dependency
sub any (&@) { ## no critic (SubroutinePrototypes)
    my $f = shift;
    foreach ( @_ ) {
        return 1 if $f->();
    }
    return 0;
}

sub all (&@) { ## no critic (SubroutinePrototypes)
    my $f = shift;
    foreach ( @_ ) {
        return 0 unless $f->();
    }
    return 1;
}

sub none (&@) { ## no critic (SubroutinePrototypes)
    my $f = shift;
    foreach ( @_ ) {
        return 0 if $f->();
    }
    return 1;
}

sub uniq (@) { ## no critic (SubroutinePrototypes)
    my %seen = ();
    grep { not $seen{$_}++ } @_;
}

sub file2module {
    my ($file) = @_;
    $file =~ s{.pm$}{};
    $file =~ s{/}{::}g;
    return $file;
}

sub module2file {
    my ($module) = @_;
    $module .= '.pm';
    $module =~ s{::}{/}g;
    return $module;
}

sub runFunction {
    my (%params) = @_;

    my $logger = $params{logger};

    # ensure module is loaded
    if ($params{load}) {
        $params{module}->require();
        if ($EVAL_ERROR) {
            $logger->debug("Failed to load $params{module}: $EVAL_ERROR")
                if $logger;
            return;
        }
    }

    my $result;
    eval {
        local $SIG{ALRM} = sub { die "alarm\n" };

        # set a timeout if needed
        if ($params{timeout}) {
            alarm $params{timeout};
            setExpirationTime(timeout => $params{timeout});
        }

        no strict 'refs'; ## no critic (ProhibitNoStrict)
        $result = &{$params{module} . '::' . $params{function}}(
            ref $params{params} eq 'HASH'  ? %{$params{params}} :
            ref $params{params} eq 'ARRAY' ? @{$params{params}} :
                                               $params{params}
        );

        # Reset timeout
        alarm 0;
        setExpirationTime();
    };

    if ($EVAL_ERROR) {
        my $message = $EVAL_ERROR eq "alarm\n" ?
            "$params{module} killed by a timeout"             :
            "unexpected error in $params{module}: $EVAL_ERROR";
        $logger->debug($message) if $logger;
    }

    return $result;
}

sub month {
    my ($month) = @_;

    my %months = (
        jan => 1,
        feb => 2,
        mar => 3,
        apr => 4,
        may => 5,
        jun => 6,
        jul => 7,
        aug => 8,
        sep => 9,
        oct => 10,
        nov => 11,
        dec => 12,
    );

    return $months{lc($month)};
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools - OS-independent generic functions

=head1 DESCRIPTION

This module provides some OS-independent generic functions.

=head1 FUNCTIONS

=head2 getFormatedLocalTime($time)

Returns a formated date from given Unix timestamp.

=head2 getFormatedGMTTime($time)

Returns a formated date from given Unix timestamp.

=head2 getFormatedDate($year, $month, $day, $hour, $min, $sec)

Returns a formated date from given date elements.

=head2 getCanonicalManufacturer($manufacturer)

Returns a normalized manufacturer value for given one.

=head2 getCanonicalSpeed($speed)

Returns a normalized speed value (in Mhz) for given one.

=head2 getCanonicalInterfaceSpeed($speed)

Returns a normalized network interface speed value (in Mb/s) for given one.

=head2 getCanonicalSize($size, $base)

Returns a normalized size value (in Mb) for given one.

=head2 getSanitizedString($string)

Returns the input stripped from any control character, properly encoded in
UTF-8.

=head2 getUtf8String($string)

Returns the input properly encoded in UTF-8.

=head2 trimWhitespace($string)

Remove leading and trailing whitespace, and fold multiple whitespace
characters into a single one.

=head2 compareVersion($major, $minor, $min_major, $min_minor)

Returns true if software with given major and minor version meet minimal
version requirements.

=head2 getDirectoryHandle(%params)

Returns an open file handle on either a command output, or a file.

=over

=item logger a logger object

=item directory the directory to use

=back

=head2 getFileHandle(%params)

Returns an open file handle on either a command output, a file, or a string.

=over

=item logger a logger object

=item command the command to use

=item file the file to use, as an alternative to the command

=item string the string to use, as an alternative to the command

=back

=head2 getFirstLine(%params)

Returns the first line of given command output or given file content, with end
of line removed.

=over

=item logger a logger object

=item command the exact command to use

=item file the file to use, as an alternative to the command

=back

=head2 getAllLines(%params)

Returns all the lines of given command output or given file content, as a list
of strings with end of line removed in list context, as a single string
otherwise.

=over

=item logger a logger object

=item command the exact command to use

=item file the file to use, as an alternative to the command

=back

=head2 getFirstMatch(%params)

Returns the result of applying given pattern on the first matching line of
given command output or given file content.

=over

=item pattern a regexp

=item logger a logger object

=item command the exact command to use

=item file the file to use, as an alternative to the command

=back

=head2 getLastLine(%params)

Returns the last line of given command output or given file content.

=over

=item logger a logger object

=item command the exact command to use

=item file the file to use, as an alternative to the command

=back

=head2 getLinesCount(%params)

Returns the number of lines of given command output or given file content.

=over

=item logger a logger object

=item command the exact command to use

=item file the file to use, as an alternative to the command

=back

=head2 canRun($binary)

Returns true if given binary can be executed.

=head2 canRead($file)

Returns true if given file can be read.

=head2 hex2char($value)

Returns the value converted to a character if it starts with hexadecimal
prefix, the unconverted value otherwise. Eg. 0x41 -> A, 41 -> 41.

=head2 hex2dec($value)

Returns the value converted to a decimal if it starts with hexadecimal prefix,
the unconverted value otherwise. Eg. 0x41 -> 65, 41 -> 41.

=head2 dec2hex($value)

Returns the value converted to an hexadecimal if it doesn't start with
hexadecimal prefix, the unconverted value otherwise. Eg. 65 -> 0x41, 0x41 ->
0x41.

=head2 any BLOCK LIST

Returns a true value if any item in LIST meets the criterion given through
BLOCK.

=head2 first BLOCK LIST

Returns the first value from LIST meeting the criterion given through BLOCK or
undef.

=head2 all BLOCK LIST

Returns a true value if all items in LIST meet the criterion given through
BLOCK.

=head2 none BLOCK LIST

Returns a true value if no item in LIST meets the criterion given through BLOCK.

=head2 uniq BLOCK LIST

Returns a new list by stripping duplicate values in LIST.

=head2 file2module($string)

Converts a perl file name to a perl module name (Foo/Bar.pm -> Foo::Bar)

=head2 module2file($string)

Converts a perl module name to a perl file name ( Foo::Bar -> Foo/Bar.pm)

=head2 runFunction(%params)

Run a function whose name is computed at runtime and return its result.

=over

=item logger a logger object

=item module the function namespace

=item function the function name

=item timeout timeout for function execution

=item load enforce module loading first

=back

=head2 slurp($file)

Return the content of a given file.

=head2 month($month)

Return the month number of the given short month name.
