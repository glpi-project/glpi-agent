package GLPI::Agent::Task::Inventory::Linux::Storages::MegacliWithSmartctl;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use File::Basename qw(basename);
use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Linux qw(getInfoFromSmartctl);

use constant RE => qr/^([^:]+?)\s*:\s*(.*\S)/;

sub isEnabled {
    return canRun('megacli') && canRun('smartctl');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $count = getFirstMatch(
        command => "megacli -adpCount",
        pattern => qr/Controller Count: (\d+)/
    );
    return unless $count;

    for (my $adp = 0; $adp < $count; $adp++) {
        my $adpinfo = _getAdpPciInfo(adp => $adp);
        my $block = _adpInfoToBlock($adpinfo);
        my $pdlist = _getPDlist(adp => $adp);
        my $ldinfo = _getLDinfo(adp => $adp);

        while (my ($id, $pd) = each %$pdlist) {
            # JBOD and Non-RAID are processed by the parent module, skip.
            next if (
                (defined $pd->{__diskgroup} &&
                 defined $ldinfo->{ $pd->{__diskgroup} } &&
                 defined $ldinfo->{ $pd->{__diskgroup} }->{'Number Of Drives'} &&
                 defined $ldinfo->{ $pd->{__diskgroup} }->{'Name'} &&
                 $ldinfo->{ $pd->{__diskgroup} }->{'Number Of Drives'} eq '1' &&
                 $ldinfo->{ $pd->{__diskgroup} }->{'Name'} =~ /Non\s*\-*RAID/i)
                    ||
                $pd->{'Firmware state'} =~ /JBOD/i
            );

            my $storage = getInfoFromSmartctl(
                device => '/dev/' . $block,
                extra  => '-d megaraid,' . $id);

            $inventory->addEntry(
                section => 'STORAGES',
                entry   => $storage,
            );
        }
    }
}

sub _getPDlist {
    my (%params) = @_;

    $params{command} = defined $params{adp} ? "megacli -pdlist -a$params{adp} -NoLog" : undef;

    my %pdlist;
    my $src = {};

    foreach my $line (getAllLines(%params)) {
        my ($key, $val) = $line =~ RE
            or next;

        if ($key eq 'Enclosure Device ID') {
            $pdlist{ $src->{'Device Id'} } = $src if defined $src->{'Device Id'};
            $src = {};
        } elsif ($key eq 'Drive\'s position') {
            ($src->{__diskgroup}, $src->{__span}, $src->{__arm}) =
                ($val =~ /DiskGroup: (\d+), Span: (\d+), Arm: (\d+)/);
        }

        $src->{$key} = $val;
    }
    $pdlist{ $src->{'Device Id'} } = $src if defined $src->{'Device Id'};

    return \%pdlist;
}

sub _getLDinfo {
    my (%params) = @_;

    $params{command} = defined $params{adp} ? "megacli -ldinfo -lAll -a$params{adp} -NoLog" : undef;

    my %ldinfo;
    my $n = -1;

    foreach my $line (getAllLines(%params)) {
        my ($key, $val) = $line =~ RE
            or next;

        if ($key eq 'Virtual Drive') {
            ($n) = ($val =~ /^\s*(\d+)/);
        }

        $ldinfo{$n}->{$key} = $val;
    }

    return \%ldinfo;
}

sub _getAdpPciInfo {
    my (%params) = @_;

    $params{command} = defined $params{adp} ? "megacli -AdpGetPciInfo -a$params{adp} -NoLog" : undef;

    my %adpinfo;
    foreach my $line (getAllLines(%params)) {
        next unless $line =~ RE;
        $adpinfo{$1} = $2;
    }

    return \%adpinfo;
}

sub _adpInfoToBlock {
    my ($adpinfo) = @_;

    my $pciid = sprintf "0000:%02s:%02s.%01s",
        $adpinfo->{'Bus Number'}, $adpinfo->{'Device Number'}, $adpinfo->{'Function Number'};

    my @blocks = Glob("/sys/bus/pci/devices/$pciid/host*/target*/*/block/*");

    # return first block device name
    return basename(shift @blocks);
}

1;
__END__

=head1 NAME

GLPI::Agent::Task::Inventory::Linux::Storages::MegacliWithSmartctl - LSI Megaraid inventory

=head1 DESCRIPTION

Provides inventory of megaraid controllers using megacli and smartctl
