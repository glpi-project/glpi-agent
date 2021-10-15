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

my %tests = (
    '10.4-powerpc' => [
        {
            NAME         => 'HL-DT-ST DVD-RW GWA-4165B',
            FIRMWARE     => 'C006',
            TYPE         => 'ATA',
            SERIAL       => 'B6FD7234EC63',
            DISKSIZE     => undef,
            MANUFACTURER => 'HL-DT-ST DVD-RW GWA-4165B',
            MODEL        => '',
            DESCRIPTION  => 'CD-ROM Drive'
        }
    ],
    '10.5-powerpc' => [
        {
            NAME         => 'HL-DT-ST DVD-RW GWA-4165B',
            FIRMWARE     => 'C006',
            TYPE         => 'ATA',
            SERIAL       => 'B6FD7234EC63',
            DISKSIZE     => undef,
            MANUFACTURER => 'HL-DT-ST DVD-RW GWA-4165B',
            MODEL        => '',
            DESCRIPTION  => 'CD-ROM Drive'
        },
        {
            NAME         => 'Flash Disk',
            FIRMWARE     => undef,
            TYPE         => 'USB',
            SERIAL       => '110074973765',
            DISKSIZE     => 1960000,
            MANUFACTURER => 'Flash Disk',
            MODEL        => undef,
            DESCRIPTION  => 'Disk drive'
        },
        {
            NAME         => 'DataTraveler 2.0',
            FIRMWARE     => undef,
            TYPE         => 'USB',
            SERIAL       => '89980116200801151425097A',
            DISKSIZE     => 3760000,
            MANUFACTURER => 'DataTraveler 2.0',
            MODEL        => undef,
            DESCRIPTION  => 'Disk drive'
        }
    ],
    '10.6-intel' => [
        {
            NAME         => 'MATSHITADVD-R   UJ-875',
            FIRMWARE     => 'DB09',
            TYPE         => 'ATA',
            SERIAL       => '            fG424F9E',
            DISKSIZE     => undef,
            MANUFACTURER => 'Matshita',
            MODEL        => 'DVD-R   UJ-875',
            DESCRIPTION  => 'CD-ROM Drive'
        },
        {
            NAME         => 'Flash Disk      ',
            FIRMWARE     => undef,
            TYPE         => 'USB',
            SERIAL       => '110074973765',
            DISKSIZE     => 2110000,
            MANUFACTURER => 'Flash Disk      ',
            MODEL        => undef,
            DESCRIPTION  => 'Disk drive'
        }
    ],
    '10.6.6-intel' => [
        {
            NAME         => 'MATSHITACD-RW  CW-8221',
            FIRMWARE     => 'GA0J',
            TYPE         => 'ATA',
            SERIAL       => undef,
            DISKSIZE     => undef,
            MANUFACTURER => 'Matshita',
            MODEL        => 'CD-RW  CW-8221',
            DESCRIPTION  => 'CD-ROM Drive'
        }
    ],
    'fiberchannel' => [
        {
            NAME         => 'SCSI Logical Unit @ 0',
            FIRMWARE     => 'R001',
            TYPE         => 'Fibre Channel',
            SERIAL       => undef,
            DISKSIZE     => 20010000,
            MANUFACTURER => 'SCSI Logical Unit @ 0',
            MODEL        => 'Production Backu',
            DESCRIPTION  => 'Disk drive'
        },
        {
            NAME         => 'SCSI Logical Unit @ 0',
            FIRMWARE     => '1.0.',
            TYPE         => 'Fibre Channel',
            SERIAL       => undef,
            DISKSIZE     => 20010000,
            MANUFACTURER => 'SCSI Logical Unit @ 0',
            MODEL        => 'UltraStorRS16FS',
            DESCRIPTION  => 'Disk drive'
        }
    ]
);

my %testsSerialATA = (
    'SPSerialATADataType.xml' => [
        {
            NAME         => 'disk0',
            MANUFACTURER => 'Western Digital',
            INTERFACE    => 'SERIAL-ATA',
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
            INTERFACE    => 'SERIAL-ATA',
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
            INTERFACE    => 'FireWire',
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

plan tests => (2 * scalar (keys %tests))
        + 1
        + scalar (keys %testsSerialATA)
        + scalar (keys %testsDiscBurning)
        + scalar (keys %testsCardReader)
        + scalar (keys %testsUSBStorage)
        + scalar (keys %testsFireWireStorage)
        + scalar (keys %testsRecursiveParsing)
;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/macos/system_profiler/$test";
    my @storages = GLPI::Agent::Task::Inventory::MacOS::Storages::_getStorages(file => $file);
    cmp_deeply(
        [ sort { compare() } @storages ],
        [ sort { compare() } @{$tests{$test}} ],
        "$test: parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'STORAGES', entry => $_)
            foreach @storages;
    } "$test: registering";
}

XML::XPath->require();
my $checkXmlXPath = $EVAL_ERROR ? 0 : 1;
my $nbTests = scalar (keys %testsSerialATA)
    + scalar (keys %testsDiscBurning)
    + scalar (keys %testsCardReader)
    + scalar (keys %testsUSBStorage)
    + scalar (keys %testsFireWireStorage)
    + scalar (keys %testsRecursiveParsing);
SKIP: {
    skip "test only if module XML::XPath available", $nbTests unless $checkXmlXPath;

    foreach my $test (keys %testsSerialATA) {
        my $file = "resources/macos/system_profiler/$test";
        my @storages = GLPI::Agent::Task::Inventory::MacOS::Storages::_getSerialATAStorages(file => $file);
        cmp_deeply(
            [ sort { compare() } @storages ],
            [ sort { compare() } @{$testsSerialATA{$test}} ],
            "testsSerialATA $test: parsing"
        );
    }

    foreach my $test (keys %testsDiscBurning) {
        my $file = "resources/macos/system_profiler/$test";
        my @storages = GLPI::Agent::Task::Inventory::MacOS::Storages::_getDiscBurningStorages(file => $file);
        cmp_deeply(
            [ sort { compare() } @storages ],
            [ sort { compare() } @{$testsDiscBurning{$test}} ],
            "testsDiscBurning $test: parsing"
        );
    }

    foreach my $test (keys %testsCardReader) {
        my $file = "resources/macos/system_profiler/$test";
        my @storages = GLPI::Agent::Task::Inventory::MacOS::Storages::_getCardReaderStorages(file => $file);
        cmp_deeply(
            [ sort { compare() } @storages ],
            [ sort { compare() } @{$testsCardReader{$test}} ],
            "testsDiscBurning $test: parsing"
        );
    }

    foreach my $test (keys %testsUSBStorage) {
        my $file = "resources/macos/system_profiler/$test";
        my @storages = GLPI::Agent::Task::Inventory::MacOS::Storages::_getUSBStorages(file => $file);
        cmp_deeply(
            [ sort { compare() } @storages ],
            [ sort { compare() } @{$testsUSBStorage{$test}} ],
            "testsUSBStorage $test: parsing"
        );
    }

    foreach my $test (keys %testsFireWireStorage) {
        my $file = "resources/macos/system_profiler/$test";
        my @storages = GLPI::Agent::Task::Inventory::MacOS::Storages::_getFireWireStorages(file => $file);
        cmp_deeply(
            [ sort { compare() } @storages ],
            [ sort { compare() } @{$testsFireWireStorage{$test}} ],
            "testsFireWireStorage $test: parsing"
        );
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
