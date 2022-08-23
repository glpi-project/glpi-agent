package GLPI::Agent::Task::Inventory::Generic::Printers;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use UNIVERSAL::require;

use GLPI::Agent::Tools;

use constant    category    => "printer";

sub isEnabled {
    my (%params) = @_;

    # we use system profiler on MacOS
    return 0 if OSNAME eq 'darwin';

    # we use WMI on Windows
    return 0 if OSNAME eq 'MSWin32';

    # Printers inventory not supported remotely
    if ($params{remote}) {
        $params{logger}->debug(
            "printers inventory not supported remotely"
        );
        return 0;
    }

    Net::CUPS->require();
    if ($EVAL_ERROR) {
        $params{logger}->debug(
            "Net::CUPS Perl module not available, unable to retrieve printers"
        );
        return 0;
    }

    if ($Net::CUPS::VERSION < 0.60) {
        $params{logger}->debug(
            "Net::CUPS Perl module too old " .
            "(available: $Net::CUPS::VERSION, required: 0.60), ".
            "unable to retrieve printers"
        );
        return 0;
    }

    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $cups = Net::CUPS->new();
    my @printers = $cups->getDestinations();

    foreach my $printer (@printers) {
        my $uri = $printer->getUri();
        my $name = $uri;
        $name =~ s/^.*\/\/([^\.]*).*$/$1/eg ;
        $name =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
        $inventory->addEntry(
            section => 'PRINTERS',
            entry   => {
                NAME        => $name,
                PORT        => $uri,
                DESCRIPTION => $printer->getDescription(),
                DRIVER      => $printer->getOptionValue(
                                   "printer-make-and-model"
                               ),
            }
        );
    }

}

1;
