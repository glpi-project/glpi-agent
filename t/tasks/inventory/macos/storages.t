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
use GLPI::Agent::Tools 'getCanonicalSize';

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
    'SPDiscBurningDataType2.xml' => []
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
    ]
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
    ]
);

my %testsFireWireStorage = (
    'SPFireWireDataType.xml' => [
        {
            NAME         => 'disk2',
            DESCRIPTION  => 'Target Disk Mode SBP-LUN',
            DISKSIZE     => 305244.16,
            FIRMWARE     => '',
            INTERFACE    => '1394',
            MANUFACTURER => 'AAPL',
            MODEL        => '',
            SERIAL       => '',
            TYPE         => 'Disk drive'
        }
    ]
);

my %testsRecursiveParsing = (
    'sample1.xml' => {
        'ELEM_NAME1.1.1' => {
            _name => 'ELEM_NAME1.1.1',
            key1  => 'value1',
            key2  => 'alternate value2',
            key3  => 'value3',
            key4  => 'value4',
            key5  => 'value5',
            key6  => 'value6',
            key7  => 'value7',
        },
        'ELEM_NAME1.1.2' => {
            _name => 'ELEM_NAME1.1.2',
            key1  => 'value1',
            key2  => 'alternate value2',
            key3  => 'value3',
            key4  => 'value4',
            key5  => 'value5',
            key6  => 'value6',
            key7  => 'other value7',
        },
        'ELEM_NAME1.2' => {
            _name => 'ELEM_NAME1.2',
            key1  => 'value1',
            key2  => 'value2',
            key3  => 'value3',
            key4  => 'value4',
            key5  => 'other value5',
            key6  => 'value6',
        }
    }
);

my $nbTests = scalar (keys %testsSerialATA)
    + scalar (keys %testsDiscBurning)
    + scalar (keys %testsCardReader)
    + scalar (keys %testsUSBStorage)
    + scalar (keys %testsFireWireStorage)
    + scalar (keys %testsRecursiveParsing);

plan tests => 2 * $nbTests;

my $inventory = GLPI::Test::Inventory->new();

XML::XPath->require();
my $checkXmlXPath = $EVAL_ERROR ? 0 : 1;
SKIP: {
    skip "test only if module XML::XPath available", 2*$nbTests unless $checkXmlXPath;

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

    foreach my $test (keys %testsRecursiveParsing) {
        my $file = "resources/macos/storages/$test";
        my $xPathExpressions = [
            "/root/elem",
            "./key[text()='units']/following-sibling::array[1]/child::elem",
            "./key[text()='units']/following-sibling::array[1]/child::elem"
        ];
        my $hash = {};
        GLPI::Agent::Tools::MacOS::_initXmlParser(
            file => $file
        );
        GLPI::Agent::Tools::MacOS::_recursiveParsing({}, $hash, undef, $xPathExpressions);
        cmp_deeply(
            $hash,
            $testsRecursiveParsing{$test},
            "testsRecursiveParsing $test: parsing"
        );
    }
}

sub compare {
    return
        $a->{NAME}  cmp $b->{NAME} ||
        $a->{MODEL} cmp $b->{MODEL};
}
