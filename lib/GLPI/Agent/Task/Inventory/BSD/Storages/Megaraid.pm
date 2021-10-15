package FusionInventory::Agent::Task::Inventory::BSD::Storages::Megaraid;

# Authors: Egor Shornikov <se@wbr.su>, Egor Morozov <akrus@flygroup.st>
# License: GPLv2+

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Task::Inventory::BSD::Storages;

sub isEnabled {
    return canRun('mfiutil');
}

sub _parseMfiutil {
    my $handle = getFileHandle(@_);

    my @storages;
    while (my $line = <$handle>) {
        unless ( $line =~ m/^[^(]*\(\s+(\d+\w+)\)\s+\S+\s+<(\S+)\s+(\S+)\s+\S+\s+serial=(\S+)>\s+(\S+)\s+.*$/ ) { next; }
        my ( $size, $vendor, $model, $serial, $type ) = ( $1, $2, $3, $4, $5 );

        if ( $size =~ /(\d+)G/ ){
            $size = $1 * 1024;
        } elsif( $size =~ /(\d+)T/ ){
            $size = $1 * 1024 * 1024;
        }

        my $storage;
        $storage->{NAME} = "$vendor $model";
        $storage->{DESCRIPTION} = $type;
        $storage->{TYPE} = 'disk';
        $storage->{DISKSIZE} = $size;
        $storage->{SERIALNUMBER} = $serial;

        push @storages, $storage;
    }
    close $handle;

    return @storages;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $storage (_parseMfiutil(
                logger => $params{logger},
                command => 'mfiutil show drives')) {
        $inventory->addEntry(section => 'STORAGES', entry => $storage);
    }
}

1;
