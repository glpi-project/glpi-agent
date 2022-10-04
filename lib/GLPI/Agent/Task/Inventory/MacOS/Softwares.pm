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

    my $localTimeOffset = detectLocalTimeOffset();
    $infos = getSystemProfilerInfos(
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

        my $soft = {
            NAME      => $name,
            VERSION   => $app->{'Version'},
        };

        $soft->{PUBLISHER} = $app->{'Get Info String'} if $app->{'Get Info String'};
        $soft->{INSTALLDATE} = $app->{'Last Modified'} if $app->{'Last Modified'};
        $soft->{COMMENTS} = '[' . $app->{'Kind'} . ']' if $app->{'Kind'};

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
