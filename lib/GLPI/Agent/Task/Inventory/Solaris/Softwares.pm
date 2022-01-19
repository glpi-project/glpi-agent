package GLPI::Agent::Task::Inventory::Solaris::Softwares;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use UNIVERSAL::require;

use GLPI::Agent::Tools;

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

    my %month = qw(Jan 1 Feb 2 Mar 3 Apr 4 May 5 Jun 6 Jul 7 Aug 8 Sep 9 Oct 10 Nov 11 Dec 12);

    my @softwares;
    my $software;
    if ($params{command} =~ /pkg info/) {
        while (my $line = <$handle>) {
            if ($line =~ /^\s*$/) {
                push @softwares, $software if $software;
                undef $software;
            } elsif ($line =~ /Name:\s+(.+)/) {
                $software->{NAME} = $1;
            } elsif ($line =~ /Version:\s+(.+)/ ) {
                $software->{VERSION} = $1;
            } elsif ($line =~ /FMRI:\s+.+\@(.+)/ && !$software->{VERSION}) {
                $software->{VERSION} = $1;
            } elsif ($line =~ /Publisher:\s+(.+)/) {
                $software->{PUBLISHER} = $1;
            } elsif ($line =~  /Summary:\s+(.+)/) {
                $software->{COMMENTS} = $1;
            } elsif ($line =~  /Last Install Time:\s+\S+\s+(\S+)\s+(\d+)\s+\S+\s+(\d+)$/) {
                if (DateTime->require) {
                    my $date;
                    eval {
                        $date = DateTime->new(
                            month   => $month{$1},
                            day     => $2,
                            year    => $3,
                        );
                    };
                    $software->{INSTALLDATE} = $date->dmy('/') if $date;
                }
            } elsif ($line =~  /Size:\s+(.+)$/) {
                my $size = getCanonicalSize($1, 1024);
                $software->{FILESIZE} = int($size) if defined($size);
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
            } elsif ($line =~  /INSTDATE:\s+(\S+)\s+(\d+)\s+(\d+)/) {
                if (DateTime->require) {
                    my $date;
                    eval {
                        $date = DateTime->new(
                            month   => $month{$1},
                            day     => $2,
                            year    => $3,
                        );
                    };
                    $software->{INSTALLDATE} = $date->dmy('/') if $date;
                }
            }
        }
    }

    push @softwares, $software if $software;

    close $handle;
    return \@softwares;
}

1;
