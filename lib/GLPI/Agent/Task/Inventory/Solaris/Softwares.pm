package FusionInventory::Agent::Task::Inventory::Solaris::Softwares;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;

use constant    category    => "software";

sub isEnabled {
    return canRun('pkg') || canRun('pkginfo');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $pkgs = _parse_pkgs(logger => $logger);
    return unless $pkgs;

    foreach my $pkg (@$pkgs) {
        $inventory->addEntry(
            section => 'SOFTWARES',
            entry   =>  $pkg
        );
    }
}

sub _parse_pkgs {
    my (%params) = @_;

    if (!defined $params{command}) {
        if (canRun('pkg')) {
            $params{command} = 'pkg info';
        } else {
            $params{command} = 'pkginfo -l';
        }
    }

    my $handle = getFileHandle(%params);
    return unless $handle;

    my @softwares;
    my $software;
    if ($params{command} =~ /pkg info/) {
        while (my $line = <$handle>) {
            if ($line =~ /^\s*$/) {
                push @softwares, $software if $software;
                undef $software;
            } elsif ($line =~ /Name:\s+(.+)/) {
                $software->{NAME} = $1;
            } elsif ($line =~ /FMRI:\s+.+\@(.+)/) {
                $software->{VERSION} = $1;
            } elsif ($line =~ /Publisher:\s+(.+)/) {
                $software->{PUBLISHER} = $1;
            } elsif ($line =~  /Summary:\s+(.+)/) {
                $software->{COMMENTS} = $1;
            }
        }
    } else {
        while (my $line = <$handle>) {
            if ($line =~ /^\s*$/) {
                push @softwares, $software if $software;
                undef $software;
            } elsif ($line =~ /PKGINST:\s+(.+)/) {
                $software->{NAME} = $1;
            } elsif ($line =~ /VERSION:\s+(.+)/) {
                $software->{VERSION} = $1;
            } elsif ($line =~ /VENDOR:\s+(.+)/) {
                $software->{PUBLISHER} = $1;
            } elsif ($line =~  /DESC:\s+(.+)/) {
                $software->{COMMENTS} = $1;
            }
        }
    }

    push @softwares, $software if $software;

    close $handle;
    return \@softwares;
}

1;
