package GLPI::Agent::Task::Inventory::Linux::Storages::Megaraid;

# Authors: Egor Shornikov <se@wbr.su>, Egor Morozov <akrus@flygroup.st>
# License: GPLv2+

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Task::Inventory::Linux::Storages;

sub isEnabled {
    return canRun('megasasctl');
}

sub _parseMegasasctl {
    my (%params) = @_;

    my @lines = getAllLines(
        command => 'megasasctl -v',
        %params
    );
    return unless @lines;

    my @storages;
    foreach my $line (@lines) {
        chomp($line);

        my ($disk_addr, $info, $size) = split(/\s\s+/, $line);
        next unless $disk_addr && $disk_addr =~ /^[a-z]\d[a-z]\d+[a-z]\d+$/;

        my ($vendor, $model) = $info =~ /(\S+)\s(\S+)$/;

        if ($vendor && $vendor eq "ATA") {
            $vendor = getCanonicalManufacturer($model);
            $vendor = "" if $vendor eq $model;
        }

        $size = 0 unless defined($size) && $size =~ /^\d+/;

        my $storage = {
            NAME            => $disk_addr,
            MANUFACTURER    => $vendor // "",
            MODEL           => $model,
            DESCRIPTION     => 'SAS',
            TYPE            => 'disk',
            DISKSIZE        => int(getCanonicalSize($size)),
        };

        push @storages, $storage;
    }

    return @storages;

}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $storage (_parseMegasasctl(@_)) {
        $inventory->addEntry(section => 'STORAGES', entry => $storage);
    }
}

1;
