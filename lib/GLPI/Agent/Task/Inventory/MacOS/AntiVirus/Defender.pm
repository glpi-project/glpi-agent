package GLPI::Agent::Task::Inventory::MacOS::AntiVirus::Defender;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Cpanel::JSON::XS;

use GLPI::Agent::Tools;

sub isEnabled {
    return canRun('/usr/local/bin/mdatp');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $antivirus = _getMSDefender(logger => $logger);
    if ($antivirus) {
        $inventory->addEntry(
            section => 'ANTIVIRUS',
            entry   => $antivirus
        );

        $logger->debug2("Added $antivirus->{NAME}".($antivirus->{VERSION}? " v$antivirus->{VERSION}":""))
            if $logger;
    }
}

sub _getMSDefender {
    my (%params) =  (
        command => '/usr/local/bin/mdatp health --output json',
        @_
    );

    my $antivirus = {
        COMPANY     => "Microsoft",
        NAME        => "Microsoft Defender",
        ENABLED     => 0,
        UPTODATE    => 0,
    };

    # Support file case for unittests if basefile is provided
    $params{file} = $params{basefile}.".json"
        if exists($params{basefile});

    my $output = getAllLines(%params)
        or return;

    my $infos = decode_json($output);
    return unless ref($infos) eq 'HASH' && $infos->{healthy};

    $antivirus->{VERSION} = $infos->{appVersion}
        if $infos->{appVersion};
    $antivirus->{BASE_VERSION} = $infos->{definitionsVersion}
        if $infos->{definitionsVersion};
    $antivirus->{UPTODATE} = $infos->{definitionsStatus}->{'$type'} && $infos->{definitionsStatus}->{'$type'} eq 'upToDate' ? 1 : 0
        if $infos->{definitionsStatus};
    $antivirus->{ENABLED} = $infos->{realTimeProtectionEnabled}->{value} == Cpanel::JSON::XS::true() ? 1 : 0
        if $infos->{realTimeProtectionEnabled} && $infos->{realTimeProtectionEnabled}->{value};
    if ($infos->{productExpiration} && $infos->{productExpiration} =~ /^\d+$/) {
        my @date = localtime(int($infos->{productExpiration})/1000);
        $antivirus->{EXPIRATION} = sprintf("%04d-%02d-%02d", $date[5]+1900, $date[4]+1, $date[3]);
    }
    if ($infos->{definitionsUpdated} && $infos->{definitionsUpdated} =~ /^\d+$/) {
        my @date = localtime(int($infos->{definitionsUpdated})/1000);
        $antivirus->{BASE_CREATION} = sprintf("%04d-%02d-%02d", $date[5]+1900, $date[4]+1, $date[3]);
    }

    return $antivirus;
}

1;
