package FusionInventory::Agent::Task::Deploy::DiskFree;

use strict;
use warnings;
use parent 'Exporter';

use English qw(-no_match_vars);
use FusionInventory::Agent::Tools;

use UNIVERSAL::require;

our @EXPORT = qw(
    getFreeSpace
);

sub getFreeSpace {
    my $freeSpace =
        $OSNAME eq 'MSWin32' ? _getFreeSpaceWindows(@_) :
        $OSNAME eq 'solaris' ? _getFreeSpaceSolaris(@_) :
        _getFreeSpace(@_);

    return $freeSpace;
}

sub _getFreeSpaceWindows {
    my (%params) = @_;

    my $logger = $params{logger};


    FusionInventory::Agent::Tools::Win32->require();
    if ($EVAL_ERROR) {
        $logger->error(
            "Failed to load FusionInventory::Agent::Tools::Win32: $EVAL_ERROR"
        );
        return;
    }

    my $letter;
    if ($params{path} !~ /^(\w):/) {
        $logger->error("Path parse error: ".$params{path});
        return;
    }
    $letter = $1.':';

    my $freeSpace;
    foreach my $object (FusionInventory::Agent::Tools::Win32::getWMIObjects(
        moniker    => 'winmgmts:{impersonationLevel=impersonate,(security)}!//./',
        class      => 'Win32_LogicalDisk',
        properties => [ qw/Caption FreeSpace/ ]
    )) {
        next unless lc($object->{Caption}) eq lc($letter);
        my $t = $object->{FreeSpace};
        if ($t && $t =~ /(\d+)\d{6}$/) {
            $freeSpace = $1;
        }
    }

    return $freeSpace;
}

sub _getFreeSpaceSolaris {
    my (%params) = @_;

    return unless -d $params{path};

    return getFirstMatch(
        command => "df -b $params{path}",
        pattern => qr/^\S+\s+(\d+)\d{3}[^\d]/,
        logger  => $params{logger}
    );
}

sub _getFreeSpace {
    my (%params) = @_;

    return unless -d $params{path};

    return getFirstMatch(
        command => "df -Pk $params{path}",
        pattern => qr/^\S+\s+\S+\s+\S+\s+(\d+)\d{3}[^\d]/,
        logger  => $params{logger}
    );
}

1;
