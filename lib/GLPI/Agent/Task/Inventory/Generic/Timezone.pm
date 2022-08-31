package GLPI::Agent::Task::Inventory::Generic::Timezone;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use UNIVERSAL::require;

use POSIX;
use Time::Local;

use GLPI::Agent::Tools;

use constant    category    => "os";

sub isEnabled {

    # No specific dependencies necessary
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # Compute a timezone offset like '+0200' using the difference between UTC and local time
    # Might require merging with detectLocalTimeOffset (macOS inventory) in the future

    ## Get the local time
    my @t = localtime(time);

    ## Compute the time offset in seconds between local and UTC time (relative and absolute)
    my $utc_offset_seconds     = timegm(@t) - timelocal(@t);
    my $utc_offset_seconds_abs = abs($utc_offset_seconds);

    ## Offset sign is minus if $utc_offset_seconds is negative, plus otherwise.
    my $offset_sign = $utc_offset_seconds < 0 ? '-' : '+';

    ## Format the offset string: sign + H (XX) + M (XX)
    my $tz_offset =
      strftime( $offset_sign . "\%H\%M", gmtime($utc_offset_seconds_abs) );

    # Assume by default that the offset is empty (safe default in case something goes wrong below)
    my $tz_name = '';

    # Timezone name extraction will use one of the following sources:
    # * DateTime::TimeZone and DateTime::TimeZone::Local::{Win32,Unix} => 'Europe/Paris'
    # * tzutil (Win 7+, Win 2008+) => 'Romance Standard Time'
    # * strftime '%Z' => 'CEST'
    #
    # strftime will not be used on Windows, as it returns unpredictable localized TZ names. It means
    # that if reliable timezone name extraction is wanted, DateTime::TimeZone MUST be used.
    if (
        ( DateTime::TimeZone->require() )
        && ( OSNAME eq 'MSWin32'
            ? DateTime::TimeZone::Local::Win32->require()
            : DateTime::TimeZone::Local::Unix->require() )
      )
    {
        $logger->debug("Using DateTime::TimeZone to get the timezone name");
        $tz_name = DateTime::TimeZone->new( name => 'local' )->name();
    }
    elsif ( ( OSNAME eq 'MSWin32' ) || ( canRun('tzutil') ) ) {

        $logger->debug("Using tzutil to get the timezone name");

        my @lines = getAllLines(
            logger  => $logger,
            command => 'tzutil /g',
        );

        foreach my $line (@lines) {
            $tz_name = $line;
        }

    }
    elsif ( OSNAME ne 'MSWin32' ) {
        $logger->debug("Using strftime to get the timezone name");
        $tz_name = strftime( "%Z", localtime() );
    }

    $inventory->setOperatingSystem(
        {
            TIMEZONE => {
                NAME   => $tz_name,
                OFFSET => $tz_offset,
            }
        }
    );

}

1;
