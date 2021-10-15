package FusionInventory::Agent::Task::Inventory::Linux::Storages::Megaraid;

# Authors: Egor Shornikov <se@wbr.su>, Egor Morozov <akrus@flygroup.st>
# License: GPLv2+

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Task::Inventory::Linux::Storages;

sub isEnabled {
    return canRun('megasasctl');
}

sub _parseMegasasctl {
    my $handle = getFileHandle(
        command => 'megasasctl -v',
        @_
    );
    return unless $handle;

    my @storages;
    while (my $line = <$handle>) {
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
    close $handle;

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
