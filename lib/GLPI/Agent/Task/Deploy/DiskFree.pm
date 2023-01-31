package GLPI::Agent::Task::Deploy::DiskFree;

use strict;
use warnings;
use parent 'Exporter';

use English qw(-no_match_vars);
use UNIVERSAL::require;
use File::Find;

use GLPI::Agent::Tools;

our @EXPORT = qw(
    getFreeSpace
    remove_tree
);

sub getFreeSpace {
    my $freeSpace =
        $OSNAME eq 'MSWin32' ? _getFreeSpaceWindows(@_) :
        $OSNAME eq 'solaris' ? _getFreeSpaceSolaris(@_) :
        _getFreeSpace(@_);

    return $freeSpace;
}

sub remove_tree {
    my ($folder) = @_;

    no warnings 'File::Find';

    finddepth(
        {
            no_chdir => 1,
            wanted   => sub {
                # Unlink files not not current folder
                unlink $File::Find::name unless $File::Find::name eq $File::Find::dir;
            },
            postprocess => sub {
                # Finally try to remove folder when folder should be empty
                rmdir $File::Find::dir;
            }
        },
        $folder
    );

    return -d $folder || -e $folder ? 0 : 1;
}

sub _getFreeSpaceWindows {
    my (%params) = @_;

    my $logger = $params{logger};


    GLPI::Agent::Tools::Win32->require();
    if ($EVAL_ERROR) {
        $logger->error(
            "Failed to load GLPI::Agent::Tools::Win32: $EVAL_ERROR"
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
    foreach my $object (GLPI::Agent::Tools::Win32::getWMIObjects(
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
