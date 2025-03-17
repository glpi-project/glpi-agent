package GLPI::Agent::Task::Inventory::MacOS::Softwares;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::MacOS;

use constant    category    => "software";

sub isEnabled {
    return
        canRun('/usr/sbin/system_profiler');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $softwares = _getSoftwaresList(logger => $params{logger});
    return unless $softwares;

    foreach my $software (@$softwares) {
        $inventory->addEntry(
            section => 'SOFTWARES',
            entry   => $software
        );
    }
}

sub _getSoftwaresList {
    my (%params) = @_;

    my $infos;

    my $localTimeOffset = detectLocalTimeOffset();
    $infos = getSystemProfilerInfos(
        type            => 'SPApplicationsDataType',
        localTimeOffset => $localTimeOffset,
        format          => 'xml',
        %params
    );

    my $info = $infos->{Applications};

    my @softwares;
    for my $name (sort keys %$info) {
        my $app = $info->{$name};

        # Windows application found by Parallels (issue #716)
        next if
            $app->{'Get Info String'} &&
            $app->{'Get Info String'} =~ /^\S+, [A-Z]:\\/;

        my $version = $app->{'Version'};
        # Cleanup dotted version from spaces
        $version =~ s/ \. /./g unless empty($version);
        my $soft = {
            NAME      => $name,
            VERSION   => $version,
        };

        my $source = $app->{'Obtained from'} // '';
        if ($source eq 'Apple' || ($app->{'Location'} && $app->{'Location'} =~ m{/System/Library/(CoreServices|Frameworks)/})) {
            $soft->{PUBLISHER} = 'Apple';
        } elsif ($source eq 'Identified Developer' && $app->{'Signed by'}) {
            my ($developer) = $app->{'Signed by'} =~ /^Developer ID Application: ([^,]*),?/;
            $developer = $1 if !empty($developer) && $developer =~ /^(.*)\s+\(.*\)$/;
            $developer =~ s/\s*Incorporated.*/ Inc./i unless empty($developer);
            $developer =~ s/\s*Corporation.*//i unless empty($developer);
            $soft->{PUBLISHER} = $developer unless empty($developer);
        }
        # Finally try to guess publisher from copyright found in Get Info String
        unless (defined($soft->{PUBLISHER}) || empty($app->{'Get Info String'})) {
            my @publisher = split(/,\s+/, $app->{'Get Info String'});
            my $publisher;
            if (grep { /\bApple\b/i } @publisher) {
                $publisher = 'Apple';
            } else {
                ($publisher) = grep { /(\(C\)|\x{a9}|Copyright|\x{ef}\x{bf}\x{bd})/i } @publisher;
                unless (empty($publisher)) {
                    $publisher = $1 if $publisher =~ /\sby\s(.*)/i;
                    $publisher =~ s/.*(\(C\)|\x{a9}|Copyright|\x{ef}\x{bf}\x{bd})\s*//gi;
                    $publisher =~ s/\s*All rights reserved\.?\s*//i;
                    $publisher =~ s/\s*Incorporated.*/ Inc./i;
                    $publisher =~ s/\s*Corporation.*//i;
                    $publisher =~ s/\s*\d+(\s*-\s*\d+)?\s*//g;
                    $soft->{PUBLISHER} = $publisher unless empty($publisher);
                }
            }
            $soft->{PUBLISHER} = $publisher unless empty($publisher);
            unless (defined($soft->{PUBLISHER})) {
                my $editor = getCanonicalManufacturer($app->{'Get Info String'});
                $soft->{PUBLISHER} = $editor unless $editor eq $app->{'Get Info String'};
            }
        }
        unless (defined($soft->{PUBLISHER})) {
            my $editor = getCanonicalManufacturer($name);
            $soft->{PUBLISHER} = $editor unless $editor eq $name;
        }

        $soft->{INSTALLDATE} = $app->{'Last Modified'} if $app->{'Last Modified'};
        $soft->{ARCH} = $app->{'Kind'} if $app->{'Kind'};

        my ($category, $username) = _extractSoftwareSystemCategoryAndUserName($app->{'Location'});
        $soft->{SYSTEM_CATEGORY} = $category if $category;
        $soft->{USERNAME} = $username if $username;

        push @softwares, $soft;
    }

    return \@softwares;
}

sub _extractSoftwareSystemCategoryAndUserName {
    my ($str) = @_;

    my $category = '';
    my $userName = '';
    return ($category, $userName) unless $str;

    if ($str =~ /^\/Users\/([^\/]+)\/([^\/]+\/[^\/]+)\//
        || $str =~ /^\/Users\/([^\/]+)\/([^\/]+)\//) {
        $userName = $1;
        $category = $2 if $2 !~ /^Downloads|^Desktop/;
    } elsif ($str =~ /^\/Volumes\/[^\/]+\/([^\/]+\/[^\/]+)\//
        || $str =~ /^\/Volumes\/[^\/]+\/([^\/]+)\//
        || $str =~ /^\/([^\/]+\/[^\/]+)\//
        || $str =~ /^\/([^\/]+)\//) {
        $category = $1;
    }

    return ($category, $userName);
}

1;
