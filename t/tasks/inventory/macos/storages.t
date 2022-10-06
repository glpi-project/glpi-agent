#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;
use English;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::MacOS::Storages;
use GLPI::Agent::XML;

my %testsSerialATA = (
    'SPSerialATADataType.xml' => [
        {
            NAME         => 'disk0',
            MANUFACTURER => 'Western Digital',
            INTERFACE    => 'SATA',
            SERIAL       => 'WD-WCARY1264478',
            MODEL        => 'WDC WD2500AAJS-40VWA1',
            FIRMWARE     => '58.01D02',
            DISKSIZE     => 238475,
            TYPE         => 'Disk drive',
            DESCRIPTION  => 'WDC WD2500AAJS-40VWA1'
        }
    ],
    'SPSerialATADataType2.xml' => [
        {
            NAME         => 'disk0',
            MANUFACTURER => 'Apple',
            INTERFACE    => 'SATA',
            SERIAL       => '1435NL400611',
            MODEL        => 'SSD SD0128F',
            FIRMWARE     => 'A222821',
            DISKSIZE     => 115712,
            TYPE         => 'Disk drive',
            DESCRIPTION  => 'APPLE SSD SD0128F'
        }
    ],
    'SPSerialATADataType3.xml' => [
        {
            NAME         => 'VBOX CD-ROM',
            MANUFACTURER => 'VBOX CD-ROM',
            INTERFACE    => 'SATA',
            SERIAL       => 'VB1-1a2b3c4d',
            MODEL        => '',
            FIRMWARE     => '1.0',
            TYPE         => 'Disk drive',
            DESCRIPTION  => 'VBOX CD-ROM'
        },
        {
            NAME         => 'disk0',
            MANUFACTURER => 'VBOX HARDDISK',
            INTERFACE    => 'SATA',
            SERIAL       => 'VB52cb5022-c69e4cc4',
            MODEL        => '',
            FIRMWARE     => '1.0',
            DISKSIZE     => 40000,
            TYPE         => 'Disk drive',
            DESCRIPTION  => 'VBOX HARDDISK'
        }
    ]
);

my %testsDiscBurning = (
    'SPDiscBurningDataType.xml' => [
        {
            NAME         => 'OPTIARC DVD RW AD-5630A',
            MANUFACTURER => 'Sony',
            INTERFACE    => 'ATAPI',
            MODEL        => 'OPTIARC DVD RW AD-5630A',
            FIRMWARE     => '1AHN',
            TYPE         => 'Disk burning'
        }
    ],
    'SPDiscBurningDataType2.xml' => [],
    'SPDiscBurningDataType3.xml' => []
);

my %testsCardReader = (
    'SPCardReaderDataType.xml' => [
        {
            NAME         => 'spcardreader',
            SERIAL       => '000000000820',
            MODEL        => 'spcardreader',
            FIRMWARE     => '3.00',
            MANUFACTURER => '0x05ac',
            TYPE         => 'Card reader',
            DESCRIPTION  => 'spcardreader'
        }
    ],
    'SPCardReaderDataType_with_inserted_card.xml' => [
        {
            NAME         => 'spcardreader',
            DESCRIPTION  => 'spcardreader',
            SERIAL       => '000000000820',
            MODEL        => 'spcardreader',
            FIRMWARE     => '3.00',
            MANUFACTURER => '0x05ac',
            TYPE         => 'Card reader'
        },
        {
            NAME         => 'disk2',
            DESCRIPTION  => 'SDHC Card',
            DISKSIZE     => 15193,
            TYPE         => 'SD Card'
        }
    ],
    'SPCardReaderDataType2.xml' => []
);

my %testsUSBStorage = (
    'SPUSBDataType.xml' => [
        {
            NAME         => 'disk1',
            SERIAL       => '20150123045944',
            MODEL        => 'External USB 3.0',
            FIRMWARE     => '1.07',
            MANUFACTURER => 'Toshiba',
            DESCRIPTION  => 'External USB 3.0',
            TYPE         => 'Disk drive',
            INTERFACE    => 'USB',
            DISKSIZE     => 476940,
        }
    ],
    'SPUSBDataType_without_inserted_dvd.xml' => [
        {
            NAME         => 'Optical USB 2.0',
            SERIAL       => 'DEF109C77CF6',
            MODEL        => 'Optical USB 2.0',
            FIRMWARE     => '0.01',
            MANUFACTURER => 'Iomega',
            DESCRIPTION  => 'Optical USB 2.0',
            TYPE         => 'Disk drive',
            INTERFACE    => 'USB',
        }
    ],
    'SPUSBDataType_with_inserted_dvd.xml' => [
        {
            NAME         => 'disk3',
            SERIAL       => 'DEF109C77CF6',
            MODEL        => 'Optical USB 2.0',
            FIRMWARE     => '0.01',
            MANUFACTURER => 'Iomega',
            DESCRIPTION  => 'Optical USB 2.0',
            TYPE         => 'Disk drive',
            INTERFACE    => 'USB',
            DISKSIZE     => 374,
        }
    ],
    'SPUSBDataType2.xml' => [
        {
            NAME         => 'disk1',
            SERIAL       => 'AASOP1QMSZ0XG051',
            MODEL        => 'JumpDrive',
            FIRMWARE     => '11.00',
            MANUFACTURER => 'Lexar',
            DESCRIPTION  => 'JumpDrive',
            TYPE         => 'Disk drive',
            INTERFACE    => 'USB',
            DISKSIZE     => 7516.16,
        },
        {
            NAME         => 'disk3',
            SERIAL       => '20150123045944',
            MODEL        => 'External USB 3.0',
            FIRMWARE     => '1.07',
            MANUFACTURER => 'Toshiba',
            DESCRIPTION  => 'External USB 3.0',
            TYPE         => 'Disk drive',
            INTERFACE    => 'USB',
            DISKSIZE     => 476938.24,
        },
        {
            NAME         => 'disk2',
            SERIAL       => '1311141504461042257807',
            MODEL        => 'UDisk 2.0',
            FIRMWARE     => '1.00',
            MANUFACTURER => 'General',
            DESCRIPTION  => 'UDisk 2.0',
            TYPE         => 'Disk drive',
            INTERFACE    => 'USB',
            DISKSIZE     => 1925.12,
        }
    ],
    'SPUSBDataType3.xml' => [
        {
            NAME         => 'disk3',
            SERIAL       => '20150123045944',
            MODEL        => 'External USB 3.0',
            FIRMWARE     => '1.07',
            MANUFACTURER => 'Toshiba',
            DESCRIPTION  => 'External USB 3.0',
            TYPE         => 'Disk drive',
            INTERFACE    => 'USB',
            DISKSIZE     => 476938.24,
        },
        {
            NAME         => 'disk1',
            SERIAL       => '1311141504461042257807',
            MODEL        => 'UDisk 2.0',
            FIRMWARE     => '1.00',
            MANUFACTURER => 'General',
            DESCRIPTION  => 'UDisk 2.0',
            TYPE         => 'Disk drive',
            INTERFACE    => 'USB',
            DISKSIZE     => 1925.12,
        },
        {
            NAME         => 'disk6',
            SERIAL       => 'AASOP1QMSZ0XG051',
            MODEL        => 'JumpDrive',
            FIRMWARE     => '11.00',
            MANUFACTURER => 'Lexar',
            DESCRIPTION  => 'JumpDrive',
            TYPE         => 'Disk drive',
            INTERFACE    => 'USB',
            DISKSIZE     => 7516.16,
        },
        {
            NAME         => 'disk5',
            SERIAL       => '8CA13C74',
            MODEL        => 'Mass Storage',
            FIRMWARE     => '1.03',
            MANUFACTURER => 'Generic',
            DESCRIPTION  => 'Mass Storage',
            TYPE         => 'Disk drive',
            INTERFACE    => 'USB',
            DISKSIZE     => 3932.16,
        },
        {
            NAME         => 'disk4',
            SERIAL       => '024279000000034C',
            MODEL        => 'USB Flash Disk',
            FIRMWARE     => '1.00',
            MANUFACTURER => 'General',
            DESCRIPTION  => 'USB Flash Disk',
            TYPE         => 'Disk drive',
            INTERFACE    => 'USB',
            DISKSIZE     => 3819.52,
        }
    ],
    'SPUSBDataType4.xml' => []
);

my %testsFireWireStorage = (
    'SPFireWireDataType.xml' => [
        {
            NAME         => 'disk2',
            DESCRIPTION  => 'Target Disk Mode SBP-LUN',
            DISKSIZE     => 305244.16,
            INTERFACE    => '1394',
            TYPE         => 'Disk drive'
        }
    ],
    'SPFireWireDataType2.xml' => []
);

my $nbTests = scalar (keys %testsSerialATA)
    + scalar (keys %testsDiscBurning)
    + scalar (keys %testsCardReader)
    + scalar (keys %testsUSBStorage)
    + scalar (keys %testsFireWireStorage);

plan tests => 2 * $nbTests + 1;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %testsSerialATA) {
    my $file = "resources/macos/system_profiler/$test";
    my @storages = GLPI::Agent::Task::Inventory::MacOS::Storages::_getSerialATAStorages(file => $file);
    cmp_deeply(
        [ sort { compare() } @storages ],
        [ sort { compare() } @{$testsSerialATA{$test}} ],
        "testsSerialATA $test: parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'STORAGES', entry => $_)
            foreach @storages;
    } "$test: registering";
}

foreach my $test (keys %testsDiscBurning) {
    my $file = "resources/macos/system_profiler/$test";
    my @storages = GLPI::Agent::Task::Inventory::MacOS::Storages::_getDiscBurningStorages(file => $file);
    cmp_deeply(
        [ sort { compare() } @storages ],
        [ sort { compare() } @{$testsDiscBurning{$test}} ],
        "testsDiscBurning $test: parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'STORAGES', entry => $_)
            foreach @storages;
    } "$test: registering";
}

foreach my $test (keys %testsCardReader) {
    my $file = "resources/macos/system_profiler/$test";
    my @storages = GLPI::Agent::Task::Inventory::MacOS::Storages::_getCardReaderStorages(file => $file);
    cmp_deeply(
        [ sort { compare() } @storages ],
        [ sort { compare() } @{$testsCardReader{$test}} ],
        "testsDiscBurning $test: parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'STORAGES', entry => $_)
            foreach @storages;
    } "$test: registering";
}

foreach my $test (keys %testsUSBStorage) {
    my $file = "resources/macos/system_profiler/$test";
    my @storages = GLPI::Agent::Task::Inventory::MacOS::Storages::_getUSBStorages(file => $file);
    cmp_deeply(
        [ sort { compare() } @storages ],
        [ sort { compare() } @{$testsUSBStorage{$test}} ],
        "testsUSBStorage $test: parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'STORAGES', entry => $_)
            foreach @storages;
    } "$test: registering";
}

foreach my $test (keys %testsFireWireStorage) {
    my $file = "resources/macos/system_profiler/$test";
    my @storages = GLPI::Agent::Task::Inventory::MacOS::Storages::_getFireWireStorages(file => $file);
    cmp_deeply(
        [ sort { compare() } @storages ],
        [ sort { compare() } @{$testsFireWireStorage{$test}} ],
        "testsFireWireStorage $test: parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'STORAGES', entry => $_)
            foreach @storages;
    } "$test: registering";
}

sub compare {
    return
        $a->{NAME}  cmp $b->{NAME} ||
        $a->{MODEL} cmp $b->{MODEL};
}
