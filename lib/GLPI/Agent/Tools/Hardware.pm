package GLPI::Agent::Tools::Hardware;

use strict;
use warnings;
use parent 'Exporter';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Network;
use GLPI::Agent::Tools::SNMP;
use GLPI::Agent::SNMP::Device;

our @EXPORT = qw(
    getDeviceInfo
    getDeviceFullInfo
    getManufacturerIDInfo
);

my %types = (
    1 => 'COMPUTER',
    2 => 'NETWORKING',
    3 => 'PRINTER',
    4 => 'STORAGE',
    5 => 'POWER',
    6 => 'PHONE',
    7 => 'VIDEO',
    8 => 'KVM',
);

my %sysobjectid;

my %sysdescr_first_word = (
    '3com'           => { manufacturer => '3Com',            type => 'NETWORKING' },
    'alcatel-lucent' => { manufacturer => 'Alcatel-Lucent',  type => 'NETWORKING' },
    'allied'         => { manufacturer => 'Allied',          type => 'NETWORKING' },
    'alteon'         => { manufacturer => 'Alteon',          type => 'NETWORKING' },
    'apc'            => { manufacturer => 'APC',             type => 'NETWORKING' },
    'apple'          => { manufacturer => 'Apple',                                },
    'avaya'          => { manufacturer => 'Avaya',                                },
    'axis'           => { manufacturer => 'Axis',            type => 'NETWORKING' },
    'baystack'       => { manufacturer => 'Nortel',          type => 'NETWORKING' },
    'broadband'      => { manufacturer => 'Broadband',       type => 'NETWORKING' },
    'brocade'        => { manufacturer => 'Brocade',         type => 'NETWORKING' },
    'brother'        => { manufacturer => 'Brother',         type => 'PRINTER'    },
    'canon'          => { manufacturer => 'Canon',           type => 'PRINTER'    },
    'cisco'          => { manufacturer => 'Cisco',           type => 'NETWORKING' },
    'dell'           => { manufacturer => 'Dell',                                 },
    'designjet'      => { manufacturer => 'Hewlett-Packard', type => 'PRINTER'    },
    'deskjet'        => { manufacturer => 'Hewlett-Packard', type => 'PRINTER'    },
    'd-link'         => { manufacturer => 'D-Link',          type => 'NETWORKING' },
    'eaton'          => { manufacturer => 'Eaton',           type => 'NETWORKING' },
    'emc'            => { manufacturer => 'EMC',             type => 'STORAGE'    },
    'enterasys'      => { manufacturer => 'Enterasys',       type => 'NETWORKING' },
    'epson'          => { manufacturer => 'Epson',           type => 'PRINTER'    },
    'extreme'        => { manufacturer => 'Extreme',         type => 'NETWORKING' },
    'extremexos'     => { manufacturer => 'Extreme',         type => 'NETWORKING' },
    'force10'        => { manufacturer => 'Force10',         type => 'NETWORKING' },
    'foundry'        => { manufacturer => 'Foundry',         type => 'NETWORKING' },
    'fuji'           => { manufacturer => 'Fuji',            type => 'NETWORKING' },
    'h3c'            => { manufacturer => 'H3C',             type => 'NETWORKING' },
    'hp'             => { manufacturer => 'Hewlett-Packard',                      },
    'ibm'            => { manufacturer => 'IBM',             type => 'COMPUTER'   },
    'juniper'        => { manufacturer => 'Juniper',         type => 'NETWORKING' },
    'konica'         => { manufacturer => 'Konica',          type => 'PRINTER'    },
    'kyocera'        => { manufacturer => 'Kyocera',         type => 'PRINTER'    },
    'lancom'         => { manufacturer => 'Lancom',          type => 'NETWORKING' },
    'lexmark'        => { manufacturer => 'Lexmark',         type => 'PRINTER'    },
    'netapp'         => { manufacturer => 'NetApp',          type => 'STORAGE'    },
    'netgear'        => { manufacturer => 'NetGear',         type => 'NETWORKING' },
    'nortel'         => { manufacturer => 'Nortel',          type => 'NETWORKING' },
    'nrg'            => { manufacturer => 'NRG',             type => 'PRINTER'    },
    'officejet'      => { manufacturer => 'Hewlett-Packard', type => 'PRINTER'    },
    'oki'            => { manufacturer => 'OKI',             type => 'PRINTER'    },
    'powerconnect'   => { manufacturer => 'PowerConnect',    type => 'NETWORKING' },
    'procurve'       => { manufacturer => 'Hewlett-Packard', type => 'NETWORKING' },
    'ricoh'          => { manufacturer => 'Ricoh',           type => 'PRINTER'    },
    'sagem'          => { manufacturer => 'Sagem',           type => 'NETWORKING' },
    'samsung'        => { manufacturer => 'Samsung',         type => 'PRINTER'    },
    'sharp'          => { manufacturer => 'Sharp',           type => 'PRINTER'    },
    'toshiba'        => { manufacturer => 'Toshiba',         type => 'PRINTER'    },
    'wyse'           => { manufacturer => 'Wyse',            type => 'COMPUTER'   },
    'xerox'          => { manufacturer => 'Xerox',           type => 'PRINTER'    },
    'xirrus'         => { manufacturer => 'Xirrus',          type => 'NETWORKING' },
    'zebranet'       => { manufacturer => 'Zebranet',        type => 'PRINTER'    },
    'ztc'            => { manufacturer => 'ZTC',             type => 'NETWORKING' },
    'zywall'         => { manufacturer => 'ZyWall',          type => 'NETWORKING' }
);

my @sysdescr_rules = (
    {
        match => qr/Switch/,
        type  => 'NETWORKING',
    },
    {
        match => qr/JETDIRECT/,
        type  => 'PRINTER',
    },
    {
        match  => qr/Linux TS-\d+/,
        type   => 'STORAGE',
        manufacturer => 'Qnap'
    },
);

# common interface variables
my %interface_variables = (
    IFNUMBER         => {
        oid  => '.1.3.6.1.2.1.2.2.1.1',
        type => 'constant'
    },
    IFDESCR          => {
        oid  => '.1.3.6.1.2.1.2.2.1.2',
        type => 'string',
    },
    IFNAME           => {
        oid  => [
            '.1.3.6.1.2.1.31.1.1.1.1',
            '.1.3.6.1.2.1.2.2.1.2',
        ],
        type => 'string',
    },
    IFTYPE           => {
        oid  => '.1.3.6.1.2.1.2.2.1.3',
        type => 'constant',
    },
    IFMTU            => {
        oid  => '.1.3.6.1.2.1.2.2.1.4',
        type => 'count',
    },
    IFSTATUS         => {
        oid  => '.1.3.6.1.2.1.2.2.1.8',
        type => 'constant',
        min  => 1,
        max  => 7,
    },
    IFINTERNALSTATUS => {
        oid  => '.1.3.6.1.2.1.2.2.1.7',
        type => 'constant',
        min  => 1,
        max  => 3,
    },
    IFLASTCHANGE     => {
        oid  => '.1.3.6.1.2.1.2.2.1.9',
        type => 'string'
    },
    IFINOCTETS       => {
        oid  => '.1.3.6.1.2.1.2.2.1.10',
        type => 'count',
    },
    IFOUTOCTETS      => {
        oid  => '.1.3.6.1.2.1.2.2.1.16',
        type => 'count',
    },
    IFINERRORS       => {
        oid  => '.1.3.6.1.2.1.2.2.1.14',
        type => 'count',
    },
    IFOUTERRORS      => {
        oid  => '.1.3.6.1.2.1.2.2.1.20',
        type => 'count',
    },
    MAC              => {
        oid  => '.1.3.6.1.2.1.2.2.1.6',
        type => 'mac',
    },
    IFPORTDUPLEX     => {
        oid  => '.1.3.6.1.2.1.10.7.2.1.19',
        type => 'constant',
        min  => 1,
        max  => 3,
    },
    IFALIAS          => {
        oid  => '.1.3.6.1.2.1.31.1.1.1.18',
        type => 'string',
    },
);

my %consumable_types = (
     3 => 'TONER',
     4 => 'WASTETONER',
     5 => 'CARTRIDGE',
     6 => 'CARTRIDGE',
     8 => 'WASTETONER',
     9 => 'DRUM',
    10 => 'DEVELOPER',
    12 => 'CARTRIDGE',
    15 => 'FUSERKIT',
    18 => 'MAINTENANCEKIT',
    20 => 'TRANSFERKIT',
    21 => 'TONER',
    32 => 'STAPLES',
);

# printer-specific page counter variables
my %printer_pagecounters_variables = (
    TOTAL      => {
        oid   => [
            '.1.3.6.1.4.1.1347.42.10.1.1.12.1.1', #Kyocera specific counter for printers and MF
                                                  # If you were really keen you could calculate misfeed rates
                                                  # based on the difference betwwen this and the default OID
                                                  # value and use it to flag a call out of service techs.
                                                  # Hint: Increasing rate = bald paper pickup roller tyres.
            '.1.3.6.1.2.1.43.10.2.1.4.1.1'        #Default Value
            ]
    },
    BLACK      => {
        oid   => '.1.3.6.1.4.1.1347.42.2.2.1.1.3.1.1' #Kyocera specific non-MFP counter
    },
    COLOR      => {
        oid   => '.1.3.6.1.4.1.1347.42.2.1.1.1.8.1.1' #Kyocera specific non-MFP counter
    },
    RECTOVERSO => { },
    SCANNED    => {
        oid   => [
            '.1.3.6.1.4.1.1347.46.10.1.1.5.3',    #Kyocera MFP specific counter ( total scan counter)
            '.1.3.6.1.4.1.1602.1.11.1.3.1.4.501'  #Canon specific counter
        ]
    },
    PRINTTOTAL => {
        oid   => [
            '.1.3.6.1.4.1.1347.42.3.1.1.1.1.1',   #Kyocera MFP specific counter
            '.1.3.6.1.4.1.1602.1.11.1.3.1.4.301'  #Canon specific counter
        ]
    },
    PRINTBLACK => {
        oid   => '.1.3.6.1.4.1.1347.42.3.1.2.1.1.1.1' #Kyocera MFP specific counter
    },
    PRINTCOLOR => {
        oid   => '.1.3.6.1.4.1.1347.42.3.1.2.1.1.1.3' #Kyocera MFP specific counter
    },
    COPYTOTAL  => {
        oid   => [
            '.1.3.6.1.4.1.1347.42.3.1.1.1.1.2',   #Kyocera MFP specific counter
            '.1.3.6.1.4.1.1602.1.11.1.3.1.4.101'  #Canon specific counter
        ]
    },
    COPYBLACK  => {
        oid   => [
            '.1.3.6.1.4.1.1347.42.3.1.2.1.1.2.1', #Kyocera MFP specific counter
            '.1.3.6.1.4.1.1602.1.11.1.3.1.4.113'  #Canon specific counter
        ]
    },
    COPYBLACK_A3  => {
        oid   => '.1.3.6.1.4.1.1602.1.11.1.3.1.4.112' #Canon specific counter
    },
    COPYCOLOR  => {
        oid   => [
            '.1.3.6.1.4.1.1347.42.3.1.2.1.1.2.3', #Kyocera MFP specific counter
            '.1.3.6.1.4.1.1602.1.11.1.3.1.4.123'  #Canon specific counter
        ]
    },
    COPYCOLOR_A3  => {
        oid   => '.1.3.6.1.4.1.1602.1.11.1.3.1.4.122' #Canon specific counter
    },
    FAXTOTAL   => {
        oid   => '.1.3.6.1.4.1.1347.42.3.1.1.1.1.4'  #Kyocera MFP specific counter
    }
);

sub _getDevice {
    my (%params) = @_;

    my $snmp    = $params{snmp};
    my $datadir = $params{datadir};
    my $logger  = $params{logger};
    my $config  = $params{config};

    my $device = GLPI::Agent::SNMP::Device->new(
        snmp   => $snmp,
        logger => $logger
    );

    # manufacturer, type and model identification attempt, using sysObjectID
    my $sysobjectid = $snmp->get('.1.3.6.1.2.1.1.2.0');
    if ($sysobjectid) {
        my $match = _getSysObjectIDInfo(
            id      => $sysobjectid,
            datadir => $datadir,
            logger  => $logger
        );
        $device->{TYPE}         = $match->{type} if $match->{type};
        $device->{MODEL}        = $match->{model} if $match->{model};
        $device->{MANUFACTURER} = $match->{manufacturer}
            if $match->{manufacturer};
        $device->{EXTMOD}       = $match->{module} if $match->{module};
    }

    # manufacturer and type identification attempt, using sysDescr,
    # if one of them is missing
    my $sysdescr = $snmp->get('.1.3.6.1.2.1.1.1.0');
    if ($sysdescr) {
        $device->{DESCRIPTION} = getCanonicalString($sysdescr);

        if (!exists $device->{MANUFACTURER} || !exists $device->{TYPE}) {
            # first word
            my ($first_word) = $sysdescr =~ /(\S+)/;
            my $result = $sysdescr_first_word{lc($first_word)};

            if ($result) {
                $device->{MANUFACTURER} = $result->{manufacturer} if
                    $result->{manufacturer} && !exists $device->{MANUFACTURER};
                $device->{TYPE}   = $result->{type} if
                    $result->{type}         && !exists $device->{TYPE};
            }

            # whole sysdescr value
            foreach my $rule (@sysdescr_rules) {
                next unless $sysdescr =~ $rule->{match};
                $device->{MANUFACTURER} = $rule->{manufacturer} if
                    $rule->{manufacturer} && !exists $device->{MANUFACTURER};
                $device->{TYPE}   = $rule->{type} if
                    $rule->{type}         && !exists $device->{TYPE};
                last;
            }
        }
    }

    # load supported mibs regarding sysORID list as this list permits to
    # identify device supported MIBs. But mib supported can also be tested
    # regarding sysobjectid in some case, so we pass it as argument
    # $config is required for ConfigurationPlugin MibSupport module
    $device->loadMibSupport($sysobjectid, $config);

    # Set type from MibSupport
    $device->setType();

    # fallback type identification attempt, using type-specific OID presence
    if (!exists $device->{TYPE}) {
         if (
             $snmp->get('.1.3.6.1.2.1.43.11.1.1.6.1.1') ||
             $snmp->get('.1.3.6.1.2.1.25.3.2.1.3.1')
         ) {
            $device->{TYPE} = 'PRINTER'
        }
    }

    # Find and set model and manufacturer
    $device->setModel();
    $device->setManufacturer();

    # Get some common informations like SNMPHOSTNAME, LOCATION, UPTIME and CONTACT
    $device->setBaseInfos();

    # Cleanup some strings from whitespaces
    foreach my $key (qw(MODEL SNMPHOSTNAME LOCATION CONTACT)) {
        next unless defined $device->{$key};
        $device->{$key} = trimWhitespace($device->{$key});
        # Don't keep empty strings
        delete $device->{$key} if $device->{$key} eq '';
    }

    # Name may have to be fixed (as example, Kyocera & Ricoh printers are concerned)
    $device->setSnmpHostname();

    # Find and set Mac address
    $device->setMacAddress();

    # Find device serial number
    $device->setSerial();

    # Find device firmware
    $device->setFirmware();

    # Find ip
    $device->setIp();

    return $device;
}

sub getDeviceInfo {
    my (%params) = @_;

    my $device = _getDevice(%params);

    return $device->getDiscoveryInfo();
}

sub getManufacturerIDInfo {
    my ($manufacturer_id) = @_;

    return unless $manufacturer_id;

    return $sysobjectid{$manufacturer_id};
}

sub _getSysObjectIDInfo {
    my (%params) = @_;

    return unless $params{id};

    _loadSysObjectIDDatabase(%params) if !%sysobjectid;

    my $logger = $params{logger};
    my $prefix = qr/(?:
        SNMPv2-SMI::enterprises |
        iso\.3\.6\.1\.4\.1      |
        \.1\.3\.6\.1\.4\.1
    )/x;
    my ($manufacturer_id, $device_id) =
        $params{id} =~ /^ $prefix \. (\d+) (?:\. ([\d.]+))? $/x;

    if (!$manufacturer_id) {
        $logger->debug("invalid sysobjectID $params{id}: no manufacturer ID")
            if $logger;
        return;
    }

    if (!$device_id) {
        $logger->debug2("partial sysobjectID $params{id}: only manufacturer ID")
            if $logger;
    }

    my $match;

    # attempt full match first
    if ($device_id) {
        $match = $sysobjectid{$manufacturer_id . '.' . $device_id};
        if ($match) {
            $logger->debug(
                "full match for sysobjectID $params{id} in database"
            ) if $logger;
            return $match;
        }
    }

    # fallback to partial match
    $match = $sysobjectid{$manufacturer_id};
    if ($match) {
        $logger->debug(
            "partial match for sysobjectID $params{id} on manufacturer ID"
        ) if $logger;
        return $match;
    }

    # no match
    $logger->debug(
        "no match for sysobjectID $params{id} in database: " .
        "unknown manufacturer ID"
    ) if $logger;
    return;
}

sub _loadSysObjectIDDatabase {
    my (%params) = @_;

    return unless $params{datadir};

    my @lines = getAllLines(file => "$params{datadir}/sysobject.ids")
        or return;

    foreach my $line (@lines) {
        next if $line =~ /^#/;
        next if $line =~ /^$/;
        my ($id, $manufacturer, $type, $model, $module) = split(/\t/, $line);
        $sysobjectid{$id} = {
            manufacturer => $manufacturer,
            type         => $type,
            model        => $model
        };
        $sysobjectid{$id}->{module} = $module if $module;
    }
}

sub getDeviceFullInfo {
    my (%params) = @_;

    my $snmp   = $params{snmp};
    my $logger = $params{logger};

    # first, let's retrieve basic device informations
    my $device = _getDevice(%params);
    return unless $device;

    my $info = $device->getDiscoveryInfo();

    # description is defined as DESCRIPTION for discovery
    # and COMMENTS for inventory
    if (exists $info->{DESCRIPTION}) {
        $info->{COMMENTS} = $info->{DESCRIPTION};
        delete $info->{DESCRIPTION};
    }

    # host name is defined as SNMPHOSTNAME for discovery
    # and NAME for inventory
    if (exists $info->{SNMPHOSTNAME}) {
        $info->{NAME} = $info->{SNMPHOSTNAME};
        delete $info->{SNMPHOSTNAME};
    }

    # device ID is set from the server request
    $info->{ID} = $params{id};

    # device TYPE is set either:
    # - from the server request,
    # - from initial identification
    $info->{TYPE} = $params{type} || $info->{TYPE};

    # second, use results to build the object
    $device->{INFO} = $info ;

    # Set other requested infos
    $device->setInventoryBaseInfos();

    _setGenericProperties(
        device => $device,
        snmp   => $snmp,
        logger => $logger
    );

    _setPrinterProperties(
        device  => $device,
        snmp    => $snmp,
        logger  => $logger,
        datadir => $params{datadir}
    ) if $info->{TYPE} && $info->{TYPE} eq 'PRINTER';

    _setNetworkingProperties(
        device  => $device,
        snmp    => $snmp,
        logger  => $logger,
        datadir => $params{datadir}
    ) if $info->{TYPE} && $info->{TYPE} eq 'NETWORKING';

    # external processing for the $device
    if ($device->{EXTMOD}) {
        runFunction(
            module   => __PACKAGE__ . "::" . $device->{EXTMOD},
            function => "run",
            logger   => $logger,
            params   => {
                snmp   => $snmp,
                device => $device,
                logger => $logger,
            },
            load     => 1
        );
    }

    # Run any detected mib support
    $device->runMibSupport();

    # convert ports hashref to an arrayref, sorted by interface number
    my $ports = $device->{PORTS}->{PORT};
    if ($ports && %$ports) {
        $device->{PORTS}->{PORT} = [
            map { $ports->{$_} }
            sort { $a <=> $b }
            keys %{$ports}
        ];
    } else {
        delete $device->{PORTS};
    }

    return $device->getInventory();
}

sub _setGenericProperties {
    my (%params) = @_;

    my $device = $params{device};
    my $snmp   = $params{snmp};
    my $logger = $params{logger};

    # ports is a sparse hash of network ports, indexed by interface identifier
    # (ifIndex, or IFNUMBER in agent output)
    my $ports;

    foreach my $key (keys %interface_variables) {
        my $variable = $interface_variables{$key};
        next unless $variable->{oid};

        my $results;
        if (ref $variable->{oid} eq 'ARRAY') {
            foreach my $oid (@{$variable->{oid}}) {
                $results = $snmp->walk($oid);
                last if $results;
            }
        } else {
            $results = $snmp->walk($variable->{oid});
        }
        next unless $results;

        my $type = $variable->{type};
        # each result matches the following scheme:
        # $prefix.$i = $value, with $i as port id
        while (my ($suffix, $raw_value) = each %{$results}) {
            my $value =
                $type eq 'mac'      ? getCanonicalMacAddress($raw_value) :
                $type eq 'constant' ? getCanonicalConstant($raw_value)   :
                $type eq 'string'   ? getCanonicalString($raw_value)     :
                $type eq 'count'    ? getCanonicalCount($raw_value)      :
                                      $raw_value;
            $ports->{$suffix}->{$key} = $value
                if defined $value && $value ne '';

            # Check constraint on constant to remove broken values
            if ($type eq 'constant') {
                my ($min, $max) = ($variable->{min}, $variable->{max});
                delete $ports->{$suffix}->{$key}
                    if defined($min) && $value < $min;
                delete $ports->{$suffix}->{$key}
                    if defined($max) && $value > $max;
            }
        }
    }

    my $highspeed_results = $snmp->walk('.1.3.6.1.2.1.31.1.1.1.15');
    my $speed_results     = $snmp->walk('.1.3.6.1.2.1.2.2.1.5');
    # ifSpeed is expressed in b/s, and available for all interfaces
    # HighSpeed is expressed in Mb/s, available for fast interfaces only
    while (my ($suffix, $speed_value) = each %{$speed_results}) {
        my $highspeed_value = $highspeed_results->{$suffix};
        $ports->{$suffix}->{IFSPEED} = $highspeed_value ?
            $highspeed_value * 1000 * 1000 : $speed_value;
    }

    my $results = $snmp->walk('.1.3.6.1.2.1.4.20.1.2');
    # each result matches the following scheme:
    # $prefix.$i.$j.$k.$l = $value
    # with $i.$j.$k.$l as IP address, and $value as port id
    foreach my $suffix (sort keys %{$results}) {
        my $value = $results->{$suffix};
        next unless $value;
        # safety checks
        if (! exists $ports->{$value}) {
            $logger->debug(
                "unknown interface $value for IP address $suffix, ignoring"
            ) if $logger;
            next;
        }
        if ($suffix !~ /^$ip_address_pattern$/) {
            $logger->debug("invalid IP address $suffix") if $logger;
            next;
        }
        $ports->{$value}->{IP} = $suffix;
        push @{$ports->{$value}->{IPS}->{IP}}, $suffix;
    }

    $device->{PORTS}->{PORT} = $ports;
}

sub _setPrinterProperties {
    my (%params) = @_;

    my $device = $params{device};
    my $snmp   = $params{snmp};
    my $logger = $params{logger};

    # colors
    my $colors = $snmp->walk('.1.3.6.1.2.1.43.12.1.1.4.1');

    # consumable levels
    my $color_ids      = $snmp->walk('.1.3.6.1.2.1.43.11.1.1.3.1');
    my $type_ids       = $snmp->walk('.1.3.6.1.2.1.43.11.1.1.5.1');
    my $descriptions   = $snmp->walk('.1.3.6.1.2.1.43.11.1.1.6.1');
    my $unit_ids       = $snmp->walk('.1.3.6.1.2.1.43.11.1.1.7.1');
    my $max_levels     = $snmp->walk('.1.3.6.1.2.1.43.11.1.1.8.1');
    my $current_levels = $snmp->walk('.1.3.6.1.2.1.43.11.1.1.9.1');

    foreach my $consumable_id (sort keys %$descriptions) {
        my $max         = $max_levels->{$consumable_id};
        my $current     = $current_levels->{$consumable_id};
        next unless defined $max and defined $current;

        # consumable identification
        my $type_id  = $type_ids->{$consumable_id};
        my $color_id = $color_ids->{$consumable_id};

        my $type;
        if ($type_id != 1) {
            $type = $consumable_types{$type_id};
        } else {
            # fallback on description
            my $description = getCanonicalString($descriptions->{$consumable_id});
            $type =
                $description =~ /maintenance/i ? 'MAINTENANCEKIT' :
                $description =~ /fuser/i       ? 'FUSERKIT'       :
                $description =~ /transfer/i    ? 'TRANSFERKIT'    :
                                                 undef            ;
        }

        if (!$type) {
            $logger->debug("unknown consumable type $type_id: " .
                (getCanonicalString($descriptions->{$consumable_id}) || "no description")
            ) if $logger;
            next;
        }

        if ($type eq 'TONER' || $type eq 'DRUM' || $type eq 'CARTRIDGE' || $type eq 'DEVELOPER') {
            my $color;
            if ($colors && $color_id) {
                $color = getCanonicalString($colors->{$color_id});
                if (!$color) {
                    $logger->debug("invalid consumable color ID $color_id for : " .
                        (getCanonicalString($descriptions->{$consumable_id}) || "no description")
                    ) if $logger;
                    next;
                }
                # remove space and following char, XML tag does not accept space
                $color =~ s/\s.*$//;
            } else {
                # fallback on description
                my $description = getCanonicalString($descriptions->{$consumable_id});
                $color =
                    $description =~ /cyan/i           ? 'cyan'    :
                    $description =~ /magenta/i        ? 'magenta' :
                    $description =~ /(yellow|jaune)/i ? 'yellow'  :
                    $description =~ /(black|noir)/i   ? 'black'   :
                                                        'black'   ;
            }
            $type .= uc($color);
        }

        my $value;
        if ($current == -2) {
            # A value of -2 means "unknown" according to the RFC - but this
            # is not NULL - it means "something undetermined between
            # OK and BAD".
            # Several makers seem to have grabbed it as a way of indicating
            # "almost out" for supplies and waste. (Like a vehicle low fuel warning)
            #
            # This was previously set to undef - but that was triggering a bug
            # that caused bad XML to be output and that in turn would block FI4G imports
            # which in turn would make page counters look strange for the days
            # when it was happening (zero pages, then a big spike)
            #
            # Using "WARNING" should allow print monitoring staff to ensure
            # replacement items are in stock before they go "BAD"
            $value = 'WARNING';
        } elsif ($current == -3) {
            # A value of -3 means that the printer knows that there is some
            # supply/remaining space, respectively.
            $value = 'OK';
        } else {
            if ($max != -2) {
                $value = _getPercentValue($max, $current);
            } else {
                # PrtMarkerSuppliesSupplyUnitTC in Printer MIB
                my $unit_id = $unit_ids->{$consumable_id};
                $value =
                    $unit_id == 19 ?  $current                         :
                    $unit_id == 18 ?  $current         . 'items'       :
                    $unit_id == 17 ?  $current         . 'm'           :
                    $unit_id == 16 ?  $current         . 'feet'        :
                    $unit_id == 15 ? ($current / 10)   . 'ml'          :
                    $unit_id == 13 ? ($current / 10)   . 'g'           :
                    $unit_id == 11 ?  $current         . 'hours'       :
                    $unit_id ==  8 ?  $current         . 'sheets'      :
                    $unit_id ==  7 ?  $current         . 'impressions' :
                    $unit_id ==  4 ? ($current / 1000) . 'mm'          :
                                      $current         . '?'           ;
            }
        }

        next unless defined $value;
        $device->{CARTRIDGES}->{$type} = $value;
    }

    # page counters
    foreach my $key (keys %printer_pagecounters_variables) {
        my $variable = $printer_pagecounters_variables{$key};
        my $value;
        if (ref $variable->{oid} eq 'ARRAY') {
            foreach my $oid (@{$variable->{oid}}) {
                $value = $snmp->get($oid);
                last if defined($value) && isInteger($value);
            }
        } else {
            my $oid = $variable->{oid};
            $value = $snmp->get($oid);
        }
        next unless defined $value;
        if (!isInteger($value)) {
            $logger->debug("incorrect counter value $value, check $variable->{mapping} mapping") if $logger;
            next;
        }
        $device->{PAGECOUNTERS}->{$key} = $value;
    }
}

sub _setNetworkingProperties {
    my (%params) = @_;

    my $device = $params{device};
    my $snmp   = $params{snmp};
    my $logger = $params{logger};

    my $ports    = $device->{PORTS}->{PORT};

    _setVlans(
        snmp   => $snmp,
        ports  => $ports,
        logger => $logger
    );

    _setTrunkPorts(
        snmp   => $snmp,
        ports  => $ports,
        logger => $logger
    );

    _setConnectedDevices(
        snmp   => $snmp,
        ports  => $ports,
        logger => $logger,
        vendor => $device->{INFO}->{MANUFACTURER}
    );

    _setKnownMacAddresses(
        snmp         => $snmp,
        ports        => $ports,
        logger       => $logger,
    );

    _setAggregatePorts(
        snmp   => $snmp,
        ports  => $ports,
        logger => $logger
    );

    $device->setComponents();
}

sub _getPercentValue {
    my ($value1, $value2) = @_;

    return unless defined $value1 && isInteger($value1);
    return unless defined $value2 && isInteger($value2);
    return if $value1 == 0;

    return int(
        ( 100 * $value2 ) / $value1
    );
}

sub _getElement {
    my ($oid, $index) = @_;

    my @array = split(/\./, $oid);
    return $array[$index];
}

sub _getElements {
    my ($oid, $first, $last) = @_;

    my @array = split(/\./, $oid);
    return @array[$first .. $last];
}

sub _setKnownMacAddresses {
    my (%params) = @_;

    my $snmp   = $params{snmp};
    my $ports  = $params{ports};
    my $logger = $params{logger};

    # start with mac addresses seen on default VLAN
    my $addresses = _getKnownMacAddresses(
        snmp           => $snmp,
        address2port   => '.1.3.6.1.2.1.17.4.3.1.2', # dot1dTpFdbPort
        port2interface => '.1.3.6.1.2.1.17.1.4.1.2', # dot1dBasePortIfIndex
    );

    if ($addresses) {
        _addKnownMacAddresses(
            ports     => $ports,
            logger    => $logger,
            addresses => $addresses,
        );
    }

    # add additional mac addresses for other VLANs
    $addresses = _getKnownMacAddresses(
        snmp           => $snmp,
        address2port   => '.1.3.6.1.2.1.17.7.1.2.2.1.2', # dot1qTpFdbPort
        port2interface => '.1.3.6.1.2.1.17.1.4.1.2',     # dot1dBasePortIfIndex
    );

    if ($addresses) {
        _addKnownMacAddresses(
            ports     => $ports,
            logger    => $logger,
            addresses => $addresses,
        );
    } else {
        # compute the list of vlans associated with at least one port
        # without CDP/LLDP information
        my @vlans;
        my %seen = ( 1 => 1 );
        foreach my $port (values %$ports) {
            next if
                exists $port->{CONNECTIONS} &&
                exists $port->{CONNECTIONS}->{CDP} &&
                $port->{CONNECTIONS}->{CDP};
            next unless exists $port->{VLANS};
            push @vlans,
                grep { !$seen{$_}++ }
                map { $_->{NUMBER} }
                @{$port->{VLANS}->{VLAN}};
        }

        # get additional associated mac addresses from those vlans
        my @mac_addresses = ();
        foreach my $vlan (@vlans) {
            $logger->debug("switching SNMP context to vlan $vlan") if $logger;
            $snmp->switch_vlan_context($vlan);
            my $mac_addresses = _getKnownMacAddresses(
                snmp           => $snmp,
                address2port   => '.1.3.6.1.2.1.17.4.3.1.2', # dot1dTpFdbPort
                port2interface => '.1.3.6.1.2.1.17.1.4.1.2', # dot1dBasePortIfIndex
            );
            next unless $mac_addresses;

            push @mac_addresses, $mac_addresses;
        }
        $snmp->reset_original_context() if @vlans;

        # Try deprecated OIDs if no additional mac addresse was found on vlans
        unless (@mac_addresses) {
            my $addresses = _getKnownMacAddressesDeprecatedOids(
                snmp              => $snmp,
                address2mac       => '.1.3.6.1.2.1.4.22.1.2', # ipNetToMediaPhysAddress
                address2interface => '.1.3.6.1.2.1.4.22.1.1' # ipNetToMediaIfIndex
            );
            push @mac_addresses, $addresses
                if ($addresses);
        }

        # Finally add found mac addresse
        foreach my $mac_addresses (@mac_addresses) {
            _addKnownMacAddresses(
                ports     => $ports,
                logger    => $logger,
                addresses => $mac_addresses,
            );
        }
    }
}

sub _addKnownMacAddresses {
    my (%params) = @_;

    my $ports         = $params{ports};
    my $logger        = $params{logger};
    my $mac_addresses = $params{addresses};

    foreach my $port_id (keys %$mac_addresses) {
        # safety check
        if (! exists $ports->{$port_id}) {
            $logger->debug(
                "invalid interface ID $port_id while setting known mac " .
                "addresses, aborting"
            ) if $logger;
            next;
        }

        my $port = $ports->{$port_id};

        # connected device has already been identified through CDP/LLDP
        next if
            exists $port->{CONNECTIONS} &&
            exists $port->{CONNECTIONS}->{CDP} &&
            $port->{CONNECTIONS}->{CDP};

        # get at list of already associated addresses, if any
        # as well as the port own mac address, if known
        my @known;
        push @known, $port->{MAC} if $port->{MAC};
        push @known, @{$port->{CONNECTIONS}->{CONNECTION}->{MAC}} if
            exists $port->{CONNECTIONS} &&
            exists $port->{CONNECTIONS}->{CONNECTION} &&
            exists $port->{CONNECTIONS}->{CONNECTION}->{MAC};

        # filter out those addresses from the additional ones
        my %known = map { $_ => 1 } @known;
        my @adresses = grep { !$known{$_} } @{$mac_addresses->{$port_id}};
        next unless @adresses;

        # add remaining ones
        push @{$port->{CONNECTIONS}->{CONNECTION}->{MAC}}, @adresses;
        @{$port->{CONNECTIONS}->{CONNECTION}->{MAC}} = uniq(@{$port->{CONNECTIONS}->{CONNECTION}->{MAC}});
    }
}

sub _getKnownMacAddresses {
    my (%params) = @_;

    my $snmp   = $params{snmp};

    my $results;
    my $address2port   = $snmp->walk($params{address2port});
    my $port2interface = $snmp->walk($params{port2interface});

    # dot1dTpFdbPort values matches the following scheme:
    # $prefix.a.b.c.d.e.f = $port

    # dot1qTpFdbPort values matches the following scheme:
    # $prefix.$vlan.a.b.c.d.e.f = $port

    # in both case, the last 6 elements of the OID constitutes
    # the mac address in decimal format
    foreach my $suffix (sort keys %{$address2port}) {
        my $port_id      = $address2port->{$suffix};
        my $interface_id = $port2interface->{$port_id};
        next unless defined $interface_id;

        my @bytes = split(/\./, $suffix);
        shift @bytes while @bytes > 6;

        push @{$results->{$interface_id}},
            sprintf "%02x:%02x:%02x:%02x:%02x:%02x", @bytes;
    }

    return $results;
}

sub _getKnownMacAddressesDeprecatedOids {
    my (%params) = @_;

    my $snmp   = $params{snmp};

    my $results;
    my $address2mac   = $snmp->walk($params{address2mac});
    my $address2interface = $snmp->walk($params{address2interface});

    foreach my $suffix (sort keys %{$address2mac}) {
        my $interface_id = $address2interface->{$suffix};
        next unless defined $interface_id;

        push @{$results->{$interface_id}},
            getCanonicalMacAddress($address2mac->{$suffix});
    }

    return $results;
}

sub _setConnectedDevices {
    my (%params) = @_;

    my $logger = $params{logger};
    my $ports  = $params{ports};

    my $lldp_info = _getLLDPInfo(%params);
    if ($lldp_info) {
        foreach my $interface_id (keys %$lldp_info) {
            # safety check
            if (! exists $ports->{$interface_id}) {
                $logger->debug(
                    "LLDP support: unknown interface $interface_id in LLDP info, ignoring"
                ) if $logger;
                next;
            }

            my $port            = $ports->{$interface_id};
            my $lldp_connection = $lldp_info->{$interface_id};

            $port->{CONNECTIONS} = {
                CDP        => 1,
                CONNECTION => $lldp_connection
            };
        }
    }

    my $cdp_info = _getCDPInfo(%params);
    if ($cdp_info) {
        foreach my $interface_id (keys %$cdp_info) {
            # safety check
            if (! exists $ports->{$interface_id}) {
                $logger->debug(
                    "CDP support: unknown interface $interface_id in CDP info, ignoring"
                ) if $logger;
                next;
            }

            my $port            = $ports->{$interface_id};
            my $lldp_connection = $port->{CONNECTIONS}->{CONNECTION};
            my $cdp_connection  = $cdp_info->{$interface_id};

            if ($lldp_connection) {
                my $match = 0;

                # Try different case to find LLDP/CDP connection match
                if ($lldp_connection->{SYSDESCR} && $cdp_connection->{SYSDESCR} eq $lldp_connection->{SYSDESCR}) {
                    $match ++;
                } elsif ($lldp_connection->{SYSNAME} && $cdp_connection->{SYSNAME}) {
                    my $cdp_test = getCanonicalMacAddress($cdp_connection->{SYSNAME});
                    if ($cdp_connection->{SYSNAME} eq $lldp_connection->{SYSNAME}) {
                        $match ++;
                    } elsif ($lldp_connection->{SYSMAC} && $cdp_test && $lldp_connection->{SYSMAC} eq $cdp_test) {
                        $match ++;
                    }
                }

                if ($match) {
                    # same device, everything OK
                    foreach my $key (qw/IP MODEL/) {
                        $lldp_connection->{$key} = $cdp_connection->{$key};
                    }
                } else {
                    # undecidable situation
                    $logger->debug(
                        "CDP support: multiple neighbors found by LLDP and CDP for " .
                        "interface $interface_id, ignoring"
                    );
                    delete $port->{CONNECTIONS};
                }
            } else {
                $port->{CONNECTIONS} = {
                    CDP        => 1,
                    CONNECTION => $cdp_connection
                };
            }
        }
    }

    my $edp_info = _getEDPInfo(%params);
    if ($edp_info) {
        foreach my $interface_id (keys %$edp_info) {
            # safety check
            if (! exists $ports->{$interface_id}) {
                $logger->debug(
                    "EDP support: unknown interface $interface_id in EDP info, ignoring"
                ) if $logger;
                next;
            }

            my $port            = $ports->{$interface_id};
            my $lldp_connection = $port->{CONNECTIONS}->{CONNECTION};
            my $edp_connection  = $edp_info->{$interface_id};

            if ($lldp_connection) {
                # Also check if SYSMAC is the same
                if (
                    first {
                        defined($edp_connection->{$_}) && defined($lldp_connection->{$_}) && lc($edp_connection->{$_}) eq lc($lldp_connection->{$_})
                    } qw(SYSDESCR SYSMAC)
                ) {
                    # same device, everything OK
                    foreach my $key (qw/IP/) {
                        $lldp_connection->{$key} = $edp_connection->{$key};
                    }
                } else {
                    # undecidable situation
                    $logger->debug(
                        "EDP support: multiple neighbors found by LLDP and EDP for " .
                        "interface $interface_id, ignoring"
                    );
                    delete $port->{CONNECTIONS};
                }
            } else {
                $port->{CONNECTIONS} = {
                    CDP        => 1,
                    CONNECTION => $edp_connection
                };
            }
        }
    }
}

sub _sortChassisIdSuffix {
    my ($a, $b) = @_;
    my @a = split('\.', $a);
    my @b = split('\.', $b);
    return (
            defined($a[2]) && defined($b[2]) && $a[2] <=> $b[2]
        ) || (
            defined($a[1]) && defined($b[1]) && $a[1] <=> $b[1]
        ) || $a[0] <=> $b[0];
}

sub _getLLDPInfo {
    my (%params) = @_;

    my $snmp   = $params{snmp};
    my $logger = $params{logger};

    my $results;
    my $ChassisIdSubType = $snmp->walk('.1.0.8802.1.1.2.1.4.1.1.4');
    my $lldpRemChassisId = $snmp->walk('.1.0.8802.1.1.2.1.4.1.1.5');
    my $lldpRemPortIdSubtype = $snmp->walk('.1.0.8802.1.1.2.1.4.1.1.6');
    my $lldpRemPortId    = $snmp->walk('.1.0.8802.1.1.2.1.4.1.1.7');
    my $lldpRemPortDesc  = $snmp->walk('.1.0.8802.1.1.2.1.4.1.1.8');
    my $lldpRemSysName   = $snmp->walk('.1.0.8802.1.1.2.1.4.1.1.9');
    my $lldpRemSysDesc   = $snmp->walk('.1.0.8802.1.1.2.1.4.1.1.10');

    # port to interface mapping
    my $port2interface =
        $snmp->walk('.1.3.6.1.4.1.9.5.1.4.1.1.11.1') || # Cisco portIfIndex
        $snmp->walk('.1.3.6.1.2.1.17.1.4.1.2');         # dot1dBasePortIfIndex

    # each lldp variable matches the following scheme:
    # $prefix.x.y.z = $value
    # whereas y is either a port or an interface id

    # See LldpChassisIdSubtype textual convention in lldp.mib RFC
    # We only report macAddress='4' at the moment
    my %not_supported_subtype = (
        '1' => "chassis component",
        '2' => "interface alias",
        '3' => "port component",
        '5' => "network address",
        '6' => "interface name",
        '7' => "local"
    );

    # Always parse LLDP infos in the same order
    foreach my $suffix (sort { _sortChassisIdSuffix($a, $b) } keys(%{$lldpRemChassisId})) {
        my $mac = $lldpRemChassisId->{$suffix};
        my $sysdescr = getCanonicalString($lldpRemSysDesc->{$suffix});
        my $sysname = getCanonicalString($lldpRemSysName->{$suffix});
        next unless ($sysdescr || $sysname);

        # Skip unexpected suffix format (seen at least on mikrotik devices)
        if ($suffix =~ /^\d+$/) {
            $logger->debug2("LLDP support: skipping unsupported suffix interface $suffix")
                if ($logger);
            next;
        }

        # Skip unsupported LldpChassisIdSubtype
        my $subtype = $ChassisIdSubType->{$suffix} || "n/a";
        unless ($subtype eq '4') {
            if ($logger) {
                my $info = ($sysname || "no name") . ", " .
                    (getCanonicalString($mac) || "no chassis id") . ", " .
                    ($sysdescr || "no description");
                if ($not_supported_subtype{$subtype}) {
                    $logger->debug("LLDP support: skipping $not_supported_subtype{$subtype}: $info");
                } else {
                    $logger->debug("LLDP support: ChassisId subtype $subtype not supported for <$info>, please report this issue");
                }
            }
            next;
        }

        my $connection = {
            SYSMAC => lc(alt2canonical($mac)) || lc(alt2canonical(getCanonicalString($mac)))
        };
        $connection->{SYSDESCR} = $sysdescr if $sysdescr;
        $connection->{SYSNAME} = $sysname if $sysname;

        # portId is either a port number or a port mac address, duplicating chassisId
        my $PortIdSubtype = "";
        $PortIdSubtype = getCanonicalString($lldpRemPortIdSubtype->{suffix}) || ""
            if $lldpRemPortIdSubtype && $lldpRemPortIdSubtype->{suffix};
        my $portId = $lldpRemPortId->{$suffix};
        # As before we need to guess portId type if not set
        if (!$PortIdSubtype) {
            if ($portId =~ /^0x[0-9a-f]{12}$/i) {
                my $thismac = lc(alt2canonical($portId));
                push @{$connection->{MAC}}, $thismac unless $thismac eq $connection->{SYSMAC};
            } else {
                $portId = getCanonicalString($portId);
                if ($portId =~ /^\d+$/) {
                    $connection->{IFNUMBER} = $portId;
                } else {
                    my $maybe_mac = lc(alt2canonical($portId));
                    if ($maybe_mac) {
                        push @{$connection->{MAC}}, $maybe_mac unless $maybe_mac eq $connection->{SYSMAC};
                    } else {
                        $connection->{IFDESCR} = $portId;
                    }
                }
            }
        } elsif ($PortIdSubtype eq '3') { # Mac address
            push @{$connection->{MAC}}, lc(alt2canonical($portId));
        } elsif ($PortIdSubtype eq '7') { # "local" should be the remote IFNUMBER
            $portId = getCanonicalString($portId);
            if ($portId =~ /^\d+$/) {
                $connection->{IFNUMBER} = $portId;
            } else {
                $connection->{IFDESCR} = $portId;
            }
        }

        my $ifdescr = getCanonicalString($lldpRemPortDesc->{$suffix});
        if (defined($ifdescr)) {
            # Sometime ifnumber is indeed set as ifdescr
            if ($ifdescr =~ /^\d+$/ && !defined($connection->{IFNUMBER})) {
                $connection->{IFNUMBER} = $ifdescr;
            } elsif (!$connection->{IFDESCR}) {
                $connection->{IFDESCR} = $ifdescr;
            }
        } else {
            $logger->debug("LLDP support: skipping portId $portId ($PortIdSubtype)")
                if $PortIdSubtype;
        }

        my $id           = _getElement($suffix, -2);
        my $interface_id =
            ! exists $port2interface->{$id} ? $id                   :
            $params{vendor} eq 'Juniper'    ? $id                   :
                                              $port2interface->{$id};

        $results->{$interface_id} = $connection;
    }

    return $results;
}

sub _getCDPInfo {
    my (%params) = @_;

    my $snmp   = $params{snmp};
    my $logger = $params{logger};

    my ($results, $blacklist);
    my $cdpCacheAddress    = $snmp->walk('.1.3.6.1.4.1.9.9.23.1.2.1.1.4');
    my $cdpCacheVersion    = $snmp->walk('.1.3.6.1.4.1.9.9.23.1.2.1.1.5');
    my $cdpCacheDeviceId   = $snmp->walk('.1.3.6.1.4.1.9.9.23.1.2.1.1.6');
    my $cdpCacheDevicePort = $snmp->walk('.1.3.6.1.4.1.9.9.23.1.2.1.1.7');
    my $cdpCachePlatform   = $snmp->walk('.1.3.6.1.4.1.9.9.23.1.2.1.1.8');
    my $cdpCacheSysName    = $snmp->walk('.1.3.6.1.4.1.9.9.23.1.2.1.1.17');

    # each cdp variable matches the following scheme:
    # $prefix.x.y = $value
    # whereas x is the port number

    while (my ($suffix, $ip) = each %{$cdpCacheAddress}) {
        my $interface_id = _getElement($suffix, -2);
        $ip = hex2canonical($ip);
        next if (!defined($ip) || $ip eq '0.0.0.0');

        my $sysdescr = getCanonicalString($cdpCacheVersion->{$suffix});
        my $model    = getCanonicalString($cdpCachePlatform->{$suffix});
        next unless $sysdescr && $model;

        my $connection = {
            IP       => $ip,
            SYSDESCR => $sysdescr,
            MODEL    => $model,
        };

        # cdpCacheDevicePort is either a port number or a port description
        my $devicePort = $cdpCacheDevicePort->{$suffix};
        if ($devicePort =~ /^\d+$/) {
            $connection->{IFNUMBER} = $devicePort;
        } else {
            $connection->{IFDESCR} = getCanonicalString($devicePort);
        }

        my $sysname = getCanonicalString($cdpCacheSysName->{$suffix});
        $connection->{SYSNAME} = $sysname
            if $sysname;

        # cdpCacheDeviceId is either remote host name, either remote mac address
        my $deviceId = $cdpCacheDeviceId->{$suffix};
        if ($deviceId =~ /^0x/) {
            if (length($deviceId) == 14) {
                # let's assume it is a mac address if the length is 6 bytes
                $connection->{SYSMAC} = lc(alt2canonical($deviceId));
            } else {
                # otherwise it's may be an hex-encode hostname
                $deviceId = getCanonicalString($deviceId);
                if ($deviceId =~ /^[0-9A-Fa-f]{12}$/) {
                    # let's assume it is a mac address if the length is 12 chars
                    $connection->{SYSMAC} = lc(alt2canonical($deviceId));
                } elsif (!$connection->{SYSNAME}) {
                    $connection->{SYSNAME} = $deviceId;
                }
            }
        } elsif (!$connection->{SYSNAME}) {
            $connection->{SYSNAME} = getCanonicalString($deviceId);
        }

        if ($connection->{SYSNAME} &&
            $connection->{SYSNAME} =~ /^SIP([A-F0-9a-f]*)$/) {
            $connection->{SYSMAC} = lc(alt2canonical("0x".$1));
        } elsif ($connection->{SYSNAME} &&
            $connection->{SYSNAME} =~ /^SIP-(.*)$/ &&
            $deviceId =~ /^$1([0-9A-Fa-f]{12})$/) {
            $connection->{SYSMAC} = lc(alt2canonical("0x".$1));
        }

        # warning: multiple neighbors announcement for the same interface
        # usually means a non-CDP aware intermediate equipement
        if ($results->{$interface_id}) {
            $logger->debug(
                "CDP support: multiple neighbors found by CDP for interface $interface_id," .
                " ignoring"
            );
            $blacklist->{$interface_id} = 1;
        } else {
            $results->{$interface_id} = $connection;
        }
    }

    # remove blacklisted results
    delete $results->{$_} foreach keys %$blacklist;

    return $results;
}

sub _getEDPInfo {
    my (%params) = @_;

    my $snmp   = $params{snmp};
    my $logger = $params{logger};

    my ($results, $blacklist);
    my $edpNeighborVlanIpAddress = $snmp->walk('.1.3.6.1.4.1.1916.1.13.3.1.3');
    my $edpNeighborName          = $snmp->walk('.1.3.6.1.4.1.1916.1.13.2.1.3');
    my $edpNeighborPort          = $snmp->walk('.1.3.6.1.4.1.1916.1.13.2.1.6');

    # each entry from extremeEdpTable matches the following scheme:
    # $prefix.x.0.0.y1.y2.y3.y4.y5.y6 = $value
    # - x: the interface id
    # - y1.y2.y3.y4.y5.y6: the remote mac address

    # each entry from extremeEdpNeighborTable matches the following scheme:
    # $prefix.x.0.0.y1.y2.y3.y4.y5.y6.z1.z2...zz = $value
    # - x: the interface id,
    # - y1.y2.y3.y4.y5.y6: the remote mac address
    # - z1.z2...zz: the vlan name in ASCII

    while (my ($suffix, $ip) = each %{$edpNeighborVlanIpAddress}) {
        next if (!defined($ip) || $ip eq '0.0.0.0');

        my $interface_id = _getElement($suffix, 0);
        my @mac_elements = _getElements($suffix, 3, 8);
        my $short_suffix = join('.', $interface_id, 0, 0, @mac_elements);

        my $connection = {
            IP       => $ip,
            IFDESCR  => getCanonicalString($edpNeighborPort->{$short_suffix}),
            SYSNAME  => getCanonicalString($edpNeighborName->{$short_suffix}),
            SYSMAC   => sprintf "%02x:%02x:%02x:%02x:%02x:%02x", @mac_elements
        };

        # warning: multiple neighbors announcement for the same interface
        # usually means a non-EDP aware intermediate equipement
        if ($results->{$interface_id}) {
            $logger->debug(
                "EDP support: multiple neighbors found by EDP for interface $interface_id," .
                " ignoring"
            );
            $blacklist->{$interface_id} = 1;
        } else {
            $results->{$interface_id} = $connection;
        }
    }

    # remove blacklisted results
    delete $results->{$_} foreach keys %$blacklist;

    return $results;
}

sub _setVlans {
    my (%params) = @_;

    my $vlans = _getVlans(
        snmp  => $params{snmp},
        ports => $params{ports}
    );
    return unless $vlans;

    my $ports  = $params{ports};
    my $logger = $params{logger};

    foreach my $port_id (keys %$vlans) {
        # safety check
        if (! exists $ports->{$port_id}) {
            $logger->debug(
                "invalid interface ID $port_id while setting vlans, skipping"
            ) if $logger;
            next;
        }
        $ports->{$port_id}->{VLANS}->{VLAN} = $vlans->{$port_id};
    }
}

sub _getVlans {
    my (%params) = @_;

    my $snmp = $params{snmp};
    my $ports = $params{ports};

    my $results;
    my $vtpVlanName  = $snmp->walk('.1.3.6.1.4.1.9.9.46.1.3.1.1.4.1');
    my $vmPortStatus = $snmp->walk('.1.3.6.1.4.1.9.9.68.1.2.2.1.2');

    # each result matches either of the following schemes:
    # $prefix.$i.$j = $value, with $j as port id, and $value as vlan id
    # $prefix.$i    = $value, with $i as port id, and $value as vlan id
    # work with Cisco and Juniper switches
    if($vtpVlanName and $vmPortStatus){
        foreach my $suffix (sort keys %{$vmPortStatus}) {
            my $port_id = _getElement($suffix, -1);
            my $vlan_id = $vmPortStatus->{$suffix};
            my $name    = getCanonicalString($vtpVlanName->{$vlan_id});

            push @{$results->{$port_id}}, {
                NUMBER => $vlan_id,
                NAME   => $name
            };
        }
    }

    # For Switch with dot1qVlanStaticEntry and dot1qVlanCurrent Present
    my $dot1qVlanStaticName = $snmp->walk('.1.3.6.1.2.1.17.7.1.4.3.1.1');
    my $dot1qVlanStaticEgressPorts = $snmp->walk('.1.3.6.1.2.1.17.7.1.4.3.1.2');
    my $dot1qVlanStaticUntaggedPorts = $snmp->walk('.1.3.6.1.2.1.17.7.1.4.3.1.4');
    my $dot1qVlanStaticRowStatus = $snmp->walk('.1.3.6.1.2.1.17.7.1.4.3.1.5');
    # each result matches either of the following schemes :
    # $prefix.$i    = $value with $i as vlan_id, and each bit of $value represent the Egress (or Untagged) is present (1st bit = ifnumber 1, 2nd bit => ifnumber 2, etc...)
    my $dot1qVlanCurrentEgressPorts = $snmp->walk('.1.3.6.1.2.1.17.7.1.4.2.1.4');
    my $dot1qVlanCurrentUntaggedPorts = $snmp->walk('.1.3.6.1.2.1.17.7.1.4.2.1.5');

    if ($dot1qVlanStaticName && $dot1qVlanStaticRowStatus) {
        foreach my $vlan_id (sort keys %{$dot1qVlanStaticRowStatus}) {
            if ($dot1qVlanStaticRowStatus->{$vlan_id} eq 1) {
                my $name = getCanonicalString($dot1qVlanStaticName->{$vlan_id});

                my ($suffix, $EgressPorts);
                if ($dot1qVlanCurrentEgressPorts) {
                    $suffix = defined($dot1qVlanCurrentEgressPorts->{$vlan_id}) ? $vlan_id : "0.".$vlan_id;
                    # Suffix may not start by "0." for other vendors
                    unless (defined($dot1qVlanCurrentEgressPorts->{$suffix})) {
                        ($suffix) = grep { /\.$vlan_id$/ } keys(%{$dot1qVlanCurrentEgressPorts});
                    }
                    if ($suffix && defined($dot1qVlanCurrentEgressPorts->{$suffix})) {
                        $EgressPorts = $dot1qVlanCurrentEgressPorts->{$suffix};
                    }
                }
                if (!defined($EgressPorts)) {
                    if ($dot1qVlanStaticEgressPorts && defined($dot1qVlanStaticEgressPorts->{$vlan_id})) {
                        $EgressPorts = $dot1qVlanStaticEgressPorts->{$vlan_id};
                    } else {
                        next;
                    }
                }

                # Tagged & Untagged VLAN
                my $bEgress = unpack("B*", hex2char($EgressPorts));
                my @bEgress = split(//,$bEgress);
                next unless @bEgress;

                my $UntaggedPorts;
                if ($suffix && $dot1qVlanCurrentUntaggedPorts && defined($dot1qVlanCurrentUntaggedPorts->{$suffix})) {
                    $UntaggedPorts = $dot1qVlanCurrentUntaggedPorts->{$suffix};
                } elsif ($dot1qVlanStaticUntaggedPorts && defined($dot1qVlanStaticUntaggedPorts->{$vlan_id})) {
                    $UntaggedPorts = $dot1qVlanStaticUntaggedPorts->{$vlan_id};
                } else {
                    next;
                }

                # Untagged VLAN
                my $bUntagged = unpack("B*", hex2char($UntaggedPorts));
                my @bUntagged = split(//,$bUntagged);
                next unless @bUntagged;

                foreach my $port_id (keys %{$ports}) {
                    next if $port_id > @bEgress || $port_id > @bUntagged;
                    my $port_index = $port_id - 1;
                    my $isUntagged = $bUntagged[$port_index];
                    my $isTagged   = $isUntagged eq '0' ? $bEgress[$port_index] : '0';
                    push @{$results->{$port_id}}, {
                        NUMBER  => $vlan_id,
                        NAME    => $name // '',
                        TAGGED  => $isTagged
                    } if $isTagged || $isUntagged;
                }
            }
        }
    }

    unless ($results) {
        # For other switches, we use another methods
        # used for Alcatel-Lucent and ExtremNetworks (and perhaps others)
        my $vlanIdName = $snmp->walk('.1.0.8802.1.1.2.1.5.32962.1.2.3.1.2');
        my $portLink = $snmp->walk('.1.0.8802.1.1.2.1.3.7.1.3');
        if ($vlanIdName && $portLink) {
            foreach my $suffix (sort keys %{$vlanIdName}) {
                my ($port, $vlan) = split(/\./, $suffix);
                if ($portLink->{$port}) {
                    # case generic where $portLink = port number
                    my $portnumber = $portLink->{$port};
                    # case Cisco where $portLink = port name
                    unless ($portLink->{$port} =~ /^[0-9]+$/) {
                        $portnumber = $port;
                    }
                    push @{$results->{$portnumber}}, {
                        NUMBER => $vlan,
                        NAME   => getCanonicalString($vlanIdName->{$suffix})
                    };
                }
            }
        } else {
            # A last method
            my $vlanId = $snmp->walk('.1.0.8802.1.1.2.1.5.32962.1.2.1.1.1');
            if ($vlanId) {
                foreach my $port (sort keys %{$vlanId}) {
                    push @{$results->{$port}}, {
                        NUMBER => $vlanId->{$port},
                        NAME   => "VLAN " . $vlanId->{$port}
                    };
                }
            }
        }
    }

    return $results;
}

sub _setTrunkPorts {
    my (%params) = @_;

    my $trunk_ports = _getTrunkPorts(
        snmp  => $params{snmp},
    );
    return unless $trunk_ports;

    my $ports  = $params{ports};
    my $logger = $params{logger};

    foreach my $port_id (keys %$trunk_ports) {
        # safety check
        if (! exists $ports->{$port_id}) {
            $logger->debug(
                "invalid interface ID $port_id while setting trunk flag, " .
                "aborting"
            ) if $logger;
            next;
        }
        $ports->{$port_id}->{TRUNK} = $trunk_ports->{$port_id};
    }
}

sub _getTrunkPorts {
    my (%params) = @_;

    my $snmp   = $params{snmp};

    my $results;

    # cisco use vlanTrunkPortDynamicStatus, using the following schema:
    # prefix.x = value
    # x is the interface id
    # value is 1 for trunk, 2 for access
    my $vlanStatus = $snmp->walk('.1.3.6.1.4.1.9.9.46.1.6.1.1.14');
    if ($vlanStatus) {
        while (my ($interface_id, $value) = each %{$vlanStatus}) {
            $results->{$interface_id} = $value == 1 ? 1 : 0;
        }
        return $results;
    }

    # juniper use jnxExVlanPortAccessMode, using the following schema:
    # prefix.x.y = value
    # x is the vlan id
    # y is the port id
    # value is 1 for access, 2 for trunk
    my $accessMode = $snmp->walk('.1.3.6.1.4.1.2636.3.40.1.5.1.7.1.5');
    if ($accessMode) {
        my $port2interface = $snmp->walk('.1.3.6.1.2.1.17.1.4.1.2');
        while (my ($suffix, $value) = each %{$accessMode}) {
            my $port_id = _getElement($suffix, -1);
            next unless defined($port_id);
            my $interface_id = $port2interface->{$port_id};
            next unless defined($interface_id);
            $results->{$interface_id} = $value == 2 ? 1 : 0;
        }
        return $results;
    }


    # others use lldpXdot1LocPortVlanId
    # prefix.x = value
    # x is either an interface or a port id
    # value is the vlan id, 0 for trunk
    my $vlanId = $snmp->walk('.1.0.8802.1.1.2.1.5.32962.1.2.1.1.1');
    if ($vlanId) {
        my $port2interface = $snmp->walk('.1.3.6.1.2.1.17.1.4.1.2');
        while (my ($id, $value) = each %{$vlanId}) {
            my $interface_id =
                ! exists $port2interface->{$id} ? $id                   :
                                                  $port2interface->{$id};
            $results->{$interface_id} = $value == 0 ? 1 : 0;
        }
        return $results;
    }

    return;
}

sub _setAggregatePorts {
    my (%params) = @_;

    my $ports  = $params{ports};
    my $logger = $params{logger};

    my $lacp_info = _getLACPInfo(%params);
    if ($lacp_info) {
        foreach my $interface_id (keys %$lacp_info) {
            # safety check
            if (!$ports->{$interface_id}) {
                $logger->debug(
                    "unknown interface $interface_id in LACP info, ignoring"
                ) if $logger;
                next;
            }
            $ports->{$interface_id}->{AGGREGATE}->{PORT} = $lacp_info->{$interface_id};
        }
    }

    my $pagp_info = _getPAGPInfo(%params);
    if ($pagp_info) {
        foreach my $interface_id (keys %$pagp_info) {
            # safety check
            if (!$ports->{$interface_id}) {
                $logger->debug(
                    "unknown interface $interface_id in PAGP info, ignoring"
                ) if $logger;
                next;
            }
            $ports->{$interface_id}->{AGGREGATE}->{PORT} = $pagp_info->{$interface_id};
        }
    }
}

sub _getLACPInfo {
    my (%params) = @_;

    my $snmp = $params{snmp};

    my $results;
    my $aggPortAttachedAggID = $snmp->walk('.1.2.840.10006.300.43.1.2.1.1.13');

    foreach my $interface_id (sort keys %$aggPortAttachedAggID) {
        my $aggregator_id = $aggPortAttachedAggID->{$interface_id};
        next if $aggregator_id == 0;
        next if $aggregator_id == $interface_id;
        push @{$results->{$aggregator_id}}, $interface_id;
    }

    return $results;
}

sub _getPAGPInfo {
    my (%params) = @_;

    my $snmp = $params{snmp};

    my $results;
    my $pagpPorts = $snmp->walk('.1.3.6.1.4.1.9.9.98.1.1.1.1.5');

    foreach my $port_id (sort keys %$pagpPorts) {
        my $portShortNum = $pagpPorts->{$port_id};
        next unless $portShortNum > 0;
        my $aggregatePort_id = $portShortNum + 5000;
        push @{$results->{$aggregatePort_id}}, $port_id;
    }

    return $results;
}

1;
__END__

=head1 NAME

GLPI::Agent::Tools::Hardware - Hardware-related functions

=head1 DESCRIPTION

This module provides some hardware-related functions.

=head1 FUNCTIONS

=head2 getDeviceInfo(%params)

return a limited set of information for a device through SNMP.

=head2 getDeviceFullInfo(%params)

return a full set of information for a device through SNMP.
