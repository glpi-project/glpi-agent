package FusionInventory::Agent::Task::Inventory::MacOS::Softwares;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::MacOS;

use constant    category    => "software";

sub isEnabled {
    return
        canRun('/usr/sbin/system_profiler');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $softwares = _getSoftwaresList(logger => $params{logger}, format => 'xml');
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
    my $datesAlreadyFormatted = 1;
    # when format used is 'text', dates are not formatted
    # they have to be formatted so we use this variable to format dates if needed
    if (!$params{format} || $params{format} eq 'text') {
        $datesAlreadyFormatted = 0;
    }
    my $localTimeOffset = FusionInventory::Agent::Tools::MacOS::detectLocalTimeOffset();
    $infos = FusionInventory::Agent::Tools::MacOS::getSystemProfilerInfos(
        %params,
        type            => 'SPApplicationsDataType',
        localTimeOffset => $localTimeOffset
    );

    my $info = $infos->{Applications};

    my @softwares;
    for my $name (keys %$info) {
        my $app = $info->{$name};

        # Windows application found by Parallels (issue #716)
        next if
            $app->{'Get Info String'} &&
            $app->{'Get Info String'} =~ /^\S+, [A-Z]:\\/;

        my $formattedDate = $app->{'Last Modified'};
        if (!$datesAlreadyFormatted) {
            $formattedDate = _formatDate($formattedDate);
        }

        my ($category, $userName) = _extractSoftwareSystemCategoryAndUserName($app->{'Location'});
        push @softwares, {
            NAME      => $name,
            VERSION   => $app->{'Version'},
            COMMENTS  => $app->{'Kind'} ? '[' . $app->{'Kind'} . ']' : undef,
            PUBLISHER => $app->{'Get Info String'},
            # extract date's data and format these data
            INSTALLDATE => $formattedDate,
            SYSTEM_CATEGORY => $category,
            USERNAME => $userName
        };
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

sub _formatDate {
    my ($dateStr) = @_;

    my @date = $dateStr =~ /^\s*(\d{1,2})\/(\d{1,2})\/(\d{2})\s*/;
    return @date == 3 ?
        sprintf("%02d/%02d/%d", $date[1], $date[0], 2000+$date[2])
        :
        $dateStr;
}

1;
