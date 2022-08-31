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
        unless( $line =~ /\s*([a-z]\d[a-z]\d+[a-z]\d+)\s+(\S+)\s+(\S+)\s*(\S+)\s+\S+\s+\S+\s*/ ){ next; }
        my ( $disk_addr, $vendor, $model, $size ) = ( $1, $2, $3, $4 );

        if ( $size =~ /(\d+)GiB/ ){
            $size = $1 * 1024;
        }

        my $storage;
        $storage->{NAME} = $disk_addr;
        $storage->{MANUFACTURER} = $vendor;
        $storage->{MODEL} = $model;
        $storage->{DESCRIPTION} = 'SAS';
        $storage->{TYPE} = 'disk';
        $storage->{DISKSIZE} = $size;

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
